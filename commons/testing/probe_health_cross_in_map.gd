extends SceneTree

## THE CROSS AS THE GRID ACTUALLY PLACES IT — not on a bench.
##
## The bench probe proves the Area3D masks the right layers. This one builds the
## two real maps that place health_cross, finds every instance, raycasts down to
## the floor the player would actually stand on, and drives a desktop-player-shaped
## body across at that height. It reports the standing window: which feet heights
## trip the pad and which do not.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_health_cross_in_map.gd

const GRID := "res://commons/grid/grid_system.tscn"
const REPORT := "res://ada_run/health_cross_in_map_probe.txt"
const MAPS := ["Point_Lines", "Trans_Pre"]

var _lines: Array[String] = []
var _fails: Array[String] = []
var _hits: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for m in MAPS:
		await _map(String(m))
	_finish()


func _map(map_name: String) -> void:
	_lines.append("")
	_lines.append("═══ %s ═══" % map_name)
	var ps: PackedScene = load(GRID) as PackedScene
	var gs: Node3D = ps.instantiate() as Node3D
	gs.name = "Grid_%s" % map_name
	gs.set("map_name", map_name)
	gs.set("bare_world", true)
	gs.set("skip_player_spawn", true)
	gs.set("interactable_place_budget_ms", 0.0)
	var done := [false]
	if gs.has_signal("build_finished"):
		gs.connect("build_finished", func(): done[0] = true, CONNECT_ONE_SHOT)
	get_root().add_child(gs)
	for i in range(600):
		await physics_frame
		if done[0] and i > 30:
			break
	# procedural bodies keep building past _ready
	for i in range(30):
		await physics_frame

	var found: Array = []
	for n in gs.find_children("*", "Node3D", true, false):
		var sc: Script = n.get_script()
		if sc != null and str(sc.resource_path).contains("health_cross"):
			found.append(n)
	_lines.append("instances found: %d" % found.size())
	if found.is_empty():
		_fails.append("%s: the grid built NO health_cross node" % map_name)
		gs.queue_free()
		await physics_frame
		return

	var space := gs.get_world_3d().direct_space_state
	for cross_v in found:
		var cross: Node3D = cross_v
		var pad: Area3D = null
		for c in cross.get_children():
			if c is Area3D:
				pad = c
				break
		if pad == null:
			_fails.append("%s: %s has no Area3D child at all" % [map_name, cross.name])
			continue
		# where is the floor under it?
		var org: Vector3 = cross.global_position
		var q := PhysicsRayQueryParameters3D.create(org + Vector3(0, 2.5, 0), org + Vector3(0, -8.0, 0))
		q.collision_mask = 0xFFFFFFFF
		var hit: Dictionary = space.intersect_ray(q)
		var floor_y: float = float(hit["position"].y) if hit.has("position") else NAN
		var pad_box: AABB = AABB()
		for pc in pad.get_children():
			if pc is CollisionShape3D and (pc as CollisionShape3D).shape != null:
				var dm: Mesh = (pc as CollisionShape3D).shape.get_debug_mesh()
				if dm != null:
					pad_box = (pc as CollisionShape3D).global_transform * dm.get_aabb()
		_lines.append("%s '%s' origin y=%.2f | pad name '%s' mask=%d monitoring=%s | pad world y %.2f..%.2f | floor under it: %s" % [
			map_name, cross.name, org.y, pad.name, pad.collision_mask, str(pad.monitoring),
			pad_box.position.y, pad_box.position.y + pad_box.size.y,
			("%.2f" % floor_y) if hit.has("position") else "NO FLOOR HIT"])

		# drive a desktop-player-shaped body across at a sweep of standing heights
		var window: Array[String] = []
		var fired_at_floor := false
		var heights: Array = []
		if hit.has("position"):
			heights.append(floor_y)
		for step in range(-6, 9):
			heights.append(org.y + float(step) * 0.25)
		var seen: Dictionary = {}
		for hy_v in heights:
			var hy: float = float(hy_v)
			var key := "%.2f" % hy
			if seen.has(key):
				continue
			seen[key] = true
			var fired: bool = await _walk(cross, pad, org, hy)
			if fired:
				window.append(key)
				if hit.has("position") and absf(hy - floor_y) < 0.01:
					fired_at_floor = true
		_lines.append("   feet heights that trip it: %s" % (", ".join(window) if not window.is_empty() else "NONE"))
		if hit.has("position"):
			_lines.append("   standing on the floor under it (%.2f): %s" % [floor_y, "TRIPS" if fired_at_floor else "DOES NOT TRIP"])
			if not fired_at_floor:
				_fails.append("%s / %s: a body standing on the floor beneath the cross does NOT trip it" % [map_name, cross.name])
		else:
			_fails.append("%s / %s: no floor collider under the cross at all" % [map_name, cross.name])

	gs.queue_free()
	await physics_frame
	await physics_frame


## one pass of a desktop-player-shaped body, feet at `feet_y`. Returns whether the
## pad published an overlap. Detection only — the body walks through everything.
func _walk(cross: Node3D, pad: Area3D, org: Vector3, feet_y: float) -> bool:
	var b := CharacterBody3D.new()
	b.name = "Probe"
	b.collision_layer = 1              # desktop player & museum walker both default here
	b.collision_mask = 0
	b.add_to_group("player_body")
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.30
	cap.height = 1.8
	cs.shape = cap
	cs.position = Vector3(0, 0.9, 0)
	b.add_child(cs)
	get_root().add_child(b)
	b.global_position = Vector3(org.x, feet_y, org.z)
	var fired := false
	for f in range(8):
		await physics_frame
		if pad.get_overlapping_bodies().has(b):
			fired = true
			break
	b.queue_free()
	await physics_frame
	return fired


func _finish() -> void:
	var out: Array[String] = []
	out.append("health_cross IN THE REAL MAPS (probe_health_cross_in_map)")
	out.append_array(_lines)
	out.append("")
	if _fails.is_empty():
		out.append("VERDICT: PASS")
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
