extends Node3D

## Do the silhouettes draw, walk the grid one metre at a time, wait without
## gliding, land a touch, and stop when shot? (2026-08-29; extended the same day
## for the Giacometti rule, the standing patrol and the touch.)
##
## Every claim here is of the kind that fails silently. A procedural sprite can
## come out as an empty texture and still be "built"; a stepping body can drift
## by a collider's thickness per step and still look like it moved; a body that
## is placed rather than slid reports no slide collisions, so the base contact
## damage never fires and nobody notices; and the first version of this probe
## forced every figure into CHASE, so it never saw that an unalerted one GLIDES
## round the base patrol rectangle. So: six seeds to disk as PNGs, then, on a
## floor, with a fake player that counts what hits it:
##
##   foes 1, 2   start 7-8 m off in PATROL, detection radius 14 -> DETECT -> CHASE.
##               Every move is EXACTLY one metre on one axis; they close in; and,
##               standing on the player's cell, they land hits.
##   foe 0       is SHOT at 1.5 s. Afterwards it never moves, carries a Plinth
##               child in its own drawn value, has no contact damage, and is in
##               group "statue" and out of "enemy".
##   foe 3       stands 30 m off, beyond detection. It may shuffle (one-metre
##               snaps) but never glides and never leaves two cells of its origin.
##
## A SCENE, run windowed or headless (physics runs either way):
##   godot --path . --headless --xr-mode off res://commons/testing/probe_silhouettes.tscn

const FOE := preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")
const Sprite := preload("res://commons/hazards/catalyst_foe/silhouette_sprite.gd")
const FakePlayer := preload("res://commons/testing/probe_fake_player.gd")

const SHOT_AT := 1.5
const END_AT := 4.5

var _foes: Array[Node3D] = []
var _last: Array[Vector3] = []
var _origin: Array[Vector3] = []
var _steps: Array[int] = [0, 0, 0, 0]
var _bad: int = 0
var _centrings: Dictionary = {}
var _player: Node3D = null
var _t: float = 0.0
var _shot: bool = false
var _statue_pos: Vector3 = Vector3.ZERO
var _statue_moves: int = 0
var _fails: Array[String] = []


func _ready() -> void:
	# ── 1. six figures to disk ─────────────────────────────────────────
	DirAccess.make_dir_recursive_absolute("user://silhouettes")
	var opaque: Array = []
	for s in [1, 2, 3, 4, 5, 6]:
		var img: Image = Sprite.make_image(s * 7919)
		var n := 0
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				if img.get_pixel(x, y).a > 0.5:
					n += 1
		opaque.append(n)
		img.save_png("user://silhouettes/seed_%d.png" % s)
	print("[probe] six figures written; opaque pixels per seed: %s" % str(opaque))
	var empty: int = 0
	for n in opaque:
		if int(n) < 400:
			empty += 1
	_check(empty == 0, "figures with fewer than 400 opaque px: %d" % empty, "an empty sprite")
	var same := opaque.count(opaque[0]) == opaque.size()
	_check(not same, "all six identical: %s" % str(same), "seed ignored")

	# ── 2. a floor on layer 1, a fake player that counts, four silhouettes ──
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 0.2, 80)
	cs.shape = box
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.1, 0)
	add_child(floor_body)

	_player = Node3D.new()
	_player.name = "FakePlayer"
	_player.set_script(FakePlayer)
	_player.position = Vector3(0.5, 0.0, 0.5)
	add_child(_player)

	var starts := [Vector3(6.5, 0.0, 4.5), Vector3(7.5, 0.0, 2.5), Vector3(8.5, 0.0, 0.5), Vector3(30.5, 0.0, 0.5)]
	for i in range(4):
		var f: Node3D = FOE.instantiate() as Node3D
		f.set("body", "silhouette")
		f.set("silhouette_seed", 100 + i)
		f.set("silhouette_step_s", 0.3)
		f.set("phase", "foe")
		f.set("detection_radius", 14.0)
		f.set("disengage_radius", 20.0)
		f.position = starts[i]
		add_child(f)
		_foes.append(f)
	await get_tree().physics_frame
	await get_tree().physics_frame
	for f in _foes:
		_last.append(f.global_position)
		_origin.append(f.global_position)
	var before: float = _mean_dist()
	print("[probe] four silhouettes standing; chasers' mean distance to player %.2f m" % before)
	set_meta("before", before)


func _physics_process(delta: float) -> void:
	if _foes.is_empty() or _last.is_empty():
		return
	_t += delta
	# the shot
	if not _shot and _t >= SHOT_AT:
		_shot = true
		var f0 := _foes[0]
		var moved_before: int = _steps[0]
		f0.call("hit_by_projectile", Color(1.0, 0.24, 0.66))
		_statue_pos = f0.global_position
		_last[0] = _statue_pos
		print("[probe] foe 0 shot at %.2f s after %d step(s); it stands at %s" % [_t, moved_before, str(_statue_pos)])
	for i in range(_foes.size()):
		var f := _foes[i]
		if not is_instance_valid(f):
			continue
		var p: Vector3 = f.global_position
		if i == 0 and _shot:
			if (p - _statue_pos).length() > 0.001:
				_statue_moves += 1
				_statue_pos = p
			continue
		var d: Vector3 = p - _last[i]
		if d.length() > 0.001 and d.length() < 0.5:
			# a CENTRING, not a step: the body settling onto its cell before its
			# first walk. Allowed once per foe, and counted apart so it cannot hide
			# among the walks or be hidden by them.
			_centrings[i] = int(_centrings.get(i, 0)) + 1
			_last[i] = p
			continue
		if d.length() > 0.001:
			_steps[i] += 1
			var one_axis: bool = (absf(d.x) > 0.001) != (absf(d.z) > 0.001)
			var one_metre: bool = absf(absf(d.x) + absf(d.z) - 1.0) < 0.01
			var level: bool = absf(d.y) < 0.02
			if not (one_axis and one_metre and level):
				_bad += 1
				print("[probe]   BAD move on foe %d: %s" % [i, str(d)])
			_last[i] = p
	if _t >= END_AT:
		_finish()


func _finish() -> void:
	set_physics_process(false)
	var after: float = _mean_dist()
	var before: float = float(get_meta("before", 0.0))
	var chase_steps: int = _steps[1] + _steps[2]
	_check(chase_steps >= 6 and _bad == 0,
		"%d chaser step(s) in %.1f s, %d move(s) not exactly one metre on one axis (all foes)" % [chase_steps, END_AT, _bad],
		"a glide or a drift")
	_check(after < before - 1.5, "chasers' mean distance to player %.2f m -> %.2f m" % [before, after], "did not approach")
	var over: int = 0
	for k in _centrings:
		if int(_centrings[k]) > 1:
			over += 1
	_check(over == 0, "centrings: %s" % str(_centrings), "a body re-centred: it is drifting")
	# the touch
	var hits: int = int(_player.get("hits"))
	_check(hits >= 1, "the fake player took %d hit(s), %.0f damage" % [hits, float(_player.get("total"))],
		"nobody landed a touch: the placed body reports no slide collisions")
	# the statue
	var f0 := _foes[0]
	var plinth: Node = f0.get_node_or_null("Plinth")
	_check(_statue_moves == 0, "the statue moved %d time(s) after the shot" % _statue_moves, "a statue walked")
	_check(plinth is MeshInstance3D, "plinth child: %s" % ("present" if plinth != null else "MISSING"), "no plinth")
	if plinth is MeshInstance3D:
		var m: Material = (plinth as MeshInstance3D).material_override
		var want: float = float(f0.get("_sil_value"))
		var got: float = (m as StandardMaterial3D).albedo_color.r if m is StandardMaterial3D else -1.0
		_check(absf(got - want) < 0.02, "plinth value %.3f vs the drawing's %.3f" % [got, want], "the plinth is not the figure's colour")
	_check(float(f0.get("contact_damage")) == 0.0 and f0.is_in_group("statue") and not f0.is_in_group("enemy"),
		"statue: contact_damage %.0f, groups statue=%s enemy=%s" % [float(f0.get("contact_damage")),
			str(f0.is_in_group("statue")), str(f0.is_in_group("enemy"))], "a statue that still bites")
	# the far one
	var f3 := _foes[3]
	var drift: float = Vector2(f3.global_position.x - _origin[3].x, f3.global_position.z - _origin[3].z).length()
	_check(drift <= 2.5, "far figure: %d shuffle(s), %.2f m from its origin, never chased" % [_steps[3], drift],
		"an unalerted figure went somewhere")
	var ok: bool = _fails.is_empty()
	print("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + ", ".join(_fails)])
	get_tree().quit(0 if ok else 1)


func _check(ok: bool, line: String, why: String) -> void:
	print("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)


func _mean_dist() -> float:
	var s := 0.0
	var n := 0
	for i in [1, 2]:
		var f := _foes[i]
		if is_instance_valid(f):
			var a: Vector3 = f.global_position
			var b: Vector3 = _player.global_position
			s += Vector2(a.x - b.x, a.z - b.z).length()
			n += 1
	return s / maxf(1.0, float(n))
