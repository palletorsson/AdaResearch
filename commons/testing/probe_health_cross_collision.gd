extends SceneTree

## DOES health_cross's PAD ACTUALLY OVERLAP THE THREE BODIES IT CLAIMS TO?
##
## The artifact's header says "IT MASKS LAYER 1 AS WELL AS LAYER 20, AND THAT IS
## THE WHOLE TRICK." This probe checks the trick rather than the comment: it walks
## four physics-shaped bodies over four separate crosses and reports, per body,
## whether the Area3D published an overlap, how many physics frames it took, and
## whether health actually moved.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_health_cross_collision.gd

const CROSS := "res://commons/artifacts/health_cross/health_cross.tscn"
const REPORT := "res://ada_run/health_cross_collision_probe.txt"

var _lines: Array[String] = []
var _fails: Array[String] = []
var _root: Node3D
var _gm: Node
var _seen: Dictionary = {}      # cross index -> Array of body names entered
var _took: Dictionary = {}      # cross index -> delivered
var _declined: Dictionary = {}  # cross index -> why


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_root = Node3D.new()
	_root.name = "Field"
	get_root().add_child(_root)

	# The provider. In a SceneTree probe the real autoload may or may not be up;
	# either way health_cross reaches it by the runtime path /root/GameManager.
	_gm = get_root().get_node_or_null("GameManager")
	if _gm == null:
		var gms: Script = load("res://commons/managers/GameManager.gd")
		if gms != null:
			_gm = (gms as GDScript).new()
			_gm.name = "GameManager"
			get_root().add_child(_gm)
			_lines.append("provider: built a GameManager (no autoload in this lane)")
	else:
		_lines.append("provider: the real /root/GameManager autoload is up")
	await physics_frame
	await physics_frame

	# ── the four bodies, each built to its real recipe ────────────────────────
	# 0 museum Walker      endless_museum.gd:3386-3400  layer default(1), group em_walker, capsule r.32 h1.5 @ .75
	# 1 desktop player     desktop_player.tscn:11       layer default(1), group player_body, capsule r.30 h1.8 @ .90
	# 2 VR PlayerBody      player_body.tscn:5-8         layer 524288,     group player_body, capsule r.30 h1.8 @ .90
	# 3 negative imposter                               layer 4 (unmasked), no groups
	var cases: Array = [
		{"name": "museum Walker", "layer": 1, "group": "em_walker", "r": 0.32, "h": 1.5, "cy": 0.75, "expect": true},
		{"name": "desktop player", "layer": 1, "group": "player_body", "r": 0.30, "h": 1.8, "cy": 0.90, "expect": true},
		{"name": "VR PlayerBody", "layer": 524288, "group": "player_body", "r": 0.30, "h": 1.8, "cy": 0.90, "expect": true},
		{"name": "unmasked imposter", "layer": 4, "group": "", "r": 0.32, "h": 1.5, "cy": 0.75, "expect": false},
	]

	for i in range(cases.size()):
		await _case(i, cases[i], 0.0)

	# THE TRANS_PRE GEOMETRY: token "health_cross:0:1" seats the artifact 1.0 m
	# above the surface the body stands on. Same bodies, cross lifted.
	_lines.append("")
	_lines.append("── the Trans_Pre lift: artifact origin 1.0 m above the body's feet ──")
	for i in range(3):
		await _case(100 + i, cases[i], 1.0)

	_finish()


func _case(idx: int, spec: Dictionary, lift: float) -> void:
	var at := Vector3(float(idx) * 40.0, 0.0, 0.0)
	var cross: Node3D = _stand(at + Vector3(0, lift, 0), idx)
	if cross == null:
		return
	if _gm != null:
		_gm.set("player_health", 10.0)

	var b := CharacterBody3D.new()
	b.name = "B%d" % idx
	b.collision_layer = int(spec["layer"])
	b.collision_mask = 0
	if String(spec["group"]) != "":
		b.add_to_group(String(spec["group"]))
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = float(spec["r"])
	cap.height = float(spec["h"])
	cs.shape = cap
	cs.position = Vector3(0, float(spec["cy"]), 0)
	b.add_child(cs)
	_root.add_child(b)
	b.global_position = at + Vector3(6.0, 0, 0)     # off the pad to start
	await physics_frame
	await physics_frame

	# step onto the pad and count the frames until the overlap is published
	b.global_position = at
	var frames := -1
	var pad: Area3D = cross.get_node_or_null("Pad") as Area3D
	for f in range(20):
		await physics_frame
		if pad != null and pad.get_overlapping_bodies().has(b):
			frames = f
			break
	# let any signal land
	await physics_frame
	await physics_frame

	var pad_ok: bool = pad != null
	var mask: int = pad.collision_mask if pad_ok else -1
	var monitoring: bool = pad.monitoring if pad_ok else false
	var overlapped: bool = pad_ok and pad.get_overlapping_bodies().has(b)
	var entered: bool = _seen.has(idx) and (_seen[idx] as Array).has(b.name)
	var delivered: float = float(_took.get(idx, 0.0))
	var why: String = String(_declined.get(idx, ""))
	var health: float = float(_gm.get("player_health")) if _gm != null else -1.0
	var expect: bool = bool(spec["expect"])

	_lines.append("%-18s lift %.1f | pad=%s mask=%d monitoring=%s | overlap=%s (after %d physics frame(s)) | body_entered=%s | delivered=%.1f%s | health now %.1f" % [
		String(spec["name"]), lift, str(pad_ok), mask, str(monitoring), str(overlapped),
		frames, str(entered), delivered, (" declined:" + why) if why != "" else "", health])

	if expect:
		if not overlapped:
			_fails.append("%s (lift %.1f): the pad NEVER overlapped it" % [String(spec["name"]), lift])
		if not entered:
			_fails.append("%s (lift %.1f): body_entered never fired" % [String(spec["name"]), lift])
		if delivered <= 0.0:
			_fails.append("%s (lift %.1f): no health delivered (%s)" % [String(spec["name"]), lift, why])
	else:
		if overlapped or entered:
			_fails.append("%s: an UNMASKED body tripped the pad" % String(spec["name"]))

	b.queue_free()
	cross.queue_free()
	await physics_frame


func _stand(at: Vector3, idx: int) -> Node3D:
	var ps: PackedScene = load(CROSS) as PackedScene
	if ps == null:
		_fails.append("health_cross.tscn will not load")
		return null
	var n: Node3D = ps.instantiate() as Node3D
	if n == null:
		_fails.append("health_cross root is not a Node3D")
		return null
	_root.add_child(n)
	n.global_position = at
	n.connect("taken", func(d: float): _took[idx] = d)
	n.connect("declined", func(w: String): _declined[idx] = w)
	var pad: Area3D = n.get_node_or_null("Pad") as Area3D
	if pad != null:
		pad.body_entered.connect(func(b: Node3D):
			if not _seen.has(idx):
				_seen[idx] = []
			(_seen[idx] as Array).append(b.name))
	return n


func _finish() -> void:
	var out: Array[String] = []
	out.append("health_cross — DOES THE PAD OVERLAP? (probe_health_cross_collision)")
	out.append("")
	out.append_array(_lines)
	out.append("")
	if _fails.is_empty():
		out.append("VERDICT: PASS — every masked body was seen, the unmasked one was not.")
	else:
		out.append("VERDICT: FAIL")
		for f in _fails:
			out.append("  - " + f)
	var text := "\n".join(out) + "\n"
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()
	print(text)
	quit(0 if _fails.is_empty() else 1)
