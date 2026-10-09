extends SceneTree
## Boots the real museum and measures its embedded source grid.
## --headless --xr-mode off --audio-driver Dummy --script this-file -- --map=Trans_Pre
## Run again with --map=Trans_Introduction. No headset input is simulated.

var checks: Array = []
var failures: Array = []
var map_name := "Trans_Pre"
var measurements: Dictionary = {}

func _initialize() -> void:
	_run.call_deferred()

func check(label: String, passed: bool, value: Variant = null) -> void:
	checks.append({"name": label, "passed": passed, "value": value})
	if not passed: failures.append(label)
	print("[opening] ", "PASS " if passed else "FAIL ", label, " ", value)

func tick() -> void:
	await physics_frame
	await process_frame

func by_script(parent: Node, suffix: String) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for n in parent.find_children("*", "Node3D", true, false):
		if n.get_script() != null and n.get_script().resource_path.ends_with(suffix): result.append(n)
	return result

func collider_bounds(node: Node3D) -> AABB:
	var shape: CollisionShape3D = node.collision_shape
	return shape.global_transform * shape.shape.get_debug_mesh().get_aabb()

func mesh_bounds(node: Node3D) -> AABB:
	return node.mesh_instance.global_transform * node.mesh_instance.get_aabb()

func floor_y(grid: Node3D, x: float, z: float) -> float:
	var p := grid.to_global(Vector3(x, 0.5, z))
	var query := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.2, p - Vector3.UP * 0.4, 1)
	var hit := grid.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position.y if not hit.is_empty() else -999.0

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="): map_name = arg.trim_prefix("--map=")
	var museum: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var prefix := "res://doc/book/iterations/2026-09-19-transformation-review/evidence/late/_trial_opening_" + map_name
	var control := FileAccess.open(prefix + "_control.json", FileAccess.WRITE)
	control.store_string(JSON.stringify({"first_chapter": "transformation", "first_map": map_name, "dollhouse": 0, "grid_pack": 1}))
	control.close()
	museum.set("EM_CONTROL", prefix + "_control.json")
	museum.set("_overrides_path", prefix + "_overrides.json")
	museum.set("_hand_path", prefix + "_hand.json")
	museum.set("start_chapter", "transformation")
	museum.set("start_map", map_name)
	root.add_child(museum)
	current_scene = museum
	var grid: Node3D
	for i in 900:
		await process_frame
		grid = museum.find_child("SimGrid_" + map_name, true, false)
		if grid != null: break
	check("actual museum embeds requested grid", grid != null)
	if grid == null:
		finish()
		return
	# Keep this audit in one built hall; streaming another while its deferred
	# grid is entering the tree would introduce unrelated teardown callbacks.
	museum.set_process(false)
	# Let asynchronous interactables and the museum's post-build pass complete.
	for i in 180: await tick()
	check("museum grid remains full scale", grid.global_basis.get_scale().is_equal_approx(Vector3.ONE))
	measurements["grid_origin"] = str(grid.global_position)
	if map_name == "Trans_Pre": await check_pickup(grid)
	else: await check_crossings(grid)
	finish()

func check_pickup(grid: Node3D) -> void:
	var cubes := by_script(grid, "/pick_up_cube.gd")
	cubes.sort_custom(func(a: Node3D, b: Node3D): return a.global_position.z < b.global_position.z)
	check("eight authored pickup stages present", cubes.size() == 8, cubes.size())
	if cubes.is_empty(): return
	var first = cubes[0]
	check("first stage stays visually still", first.motion == "still" and is_zero_approx(first.rotation_speed) and is_zero_approx(first.bob_height))
	check("first stage collection enabled", first.hold == "collect" and first.get_node("DetectionArea").monitoring)
	var demo_count := 0
	for cube in cubes:
		if cube.hold == "demo": demo_count += 1
	check("three later moving demonstrations retained", demo_count == 3)
	var origin := XROrigin3D.new()
	origin.name = "ProbeOrigin"
	origin.position = Vector3(first.global_position.x, grid.global_position.y + 0.51, first.global_position.z - 1.0)
	var camera := XRCamera3D.new()
	camera.name = "Camera"
	camera.position.y = 1.7
	origin.add_child(camera)
	var body = load("res://addons/godot-xr-tools/player/player_body.tscn").instantiate()
	body.player_calibrate_height = false
	body.eye_forward_offset = 0.0
	origin.add_child(body)
	root.add_child(origin)
	for i in 15: await tick()
	var score_before: int = root.get_node("GameManager").get_score()
	var first_ref: WeakRef = weakref(first)
	# Actual XR collision body approaches through physics movement. No call to collect().
	for i in 70:
		await physics_frame
		body.move_player(Vector3(0.0, 0.0, 1.0))
		await process_frame
	for i in 15: await tick()
	check("real XR body collected still stage through overlap", first_ref.get_ref() == null)
	check("collection awarded exactly one point", root.get_node("GameManager").get_score() == score_before + 1)
	measurements["score_before"] = score_before
	measurements["score_after"] = root.get_node("GameManager").get_score()
	origin.queue_free()

func check_crossings(grid: Node3D) -> void:
	var scales := by_script(grid, "/scale_cube.gd")
	var rotations := by_script(grid, "/rotation_cube.gd")
	check("scale and rotation crossings instantiated", scales.size() == 1 and rotations.size() == 1)
	if scales.size() != 1 or rotations.size() != 1: return
	var sc = scales[0]
	var rc = rotations[0]
	sc.set_process(false)
	rc.set_process(false)
	var deck := floor_y(grid, 3.0, 12.0)
	check("source floor ray agrees with museum deck", absf(deck - (grid.global_position.y + 0.5)) < 0.002, deck)
	sc.current_scale = sc.max_scale
	sc.apply_scale()
	var full := collider_bounds(sc)
	check("scale collider flush at maximum", absf(full.end.y - deck) < 0.002, full.end.y - deck)
	check("scale mesh matches physical box", mesh_bounds(sc).is_equal_approx(full))
	sc.current_scale = sc.min_scale
	sc.apply_scale()
	check("small scale cube withdraws below deck", collider_bounds(sc).end.y < deck - 1.2)
	sc.current_scale = sc.max_scale
	sc.apply_scale()
	rc.mesh_instance.rotation_degrees = Vector3.ZERO
	rc.static_body.transform = rc.mesh_instance.transform
	var crosswise := collider_bounds(rc)
	check("plank is elongated 3.6 by 1 metres", (rc.body_size() as Vector3).is_equal_approx(Vector3(3.6, 0.2, 1.0)), rc.body_size())
	check("crosswise plank leaves a gap to both forward banks", crosswise.position.z > grid.to_global(Vector3(5,0,15.5)).z and crosswise.end.z < grid.to_global(Vector3(5,0,18.5)).z)
	check("crosswise plank top flush", absf(crosswise.end.y - deck) < 0.002)
	rc.mesh_instance.rotation_degrees = Vector3(0,90,0)
	rc.static_body.transform = rc.mesh_instance.transform
	rc.static_body.force_update_transform()
	var aligned := collider_bounds(rc)
	check("quarter-turned plank top flush", absf(aligned.end.y - deck) < 0.002, aligned.end.y - deck)
	check("quarter-turned plank overlaps both banks by 0.3m", aligned.position.z <= grid.to_global(Vector3(5,0,15.2)).z + 0.002 and aligned.end.z >= grid.to_global(Vector3(5,0,18.8)).z - 0.002)
	check("rotation mesh matches physical box", mesh_bounds(rc).is_equal_approx(aligned))
	measurements["scale_full_collision"] = str(full)
	measurements["plank_crosswise_collision"] = str(crosswise)
	measurements["plank_aligned_collision"] = str(aligned)
	var walker := CharacterBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.6
	capsule.radius = 0.22
	shape.shape = capsule
	shape.position.y = 0.8
	walker.add_child(shape)
	walker.floor_snap_length = 0.15
	root.add_child(walker)
	for row in [10.0,15.0]:
		walker.global_position = grid.to_global(Vector3(5.0,0.52,row))
		walker.velocity = Vector3.ZERO
		var lowest: float = walker.global_position.y
		for i in 135:
			await physics_frame
			walker.velocity = Vector3(0,walker.velocity.y-9.8/60.0,2)
			walker.move_and_slide()
			lowest = minf(lowest,walker.global_position.y)
			await process_frame
		check("capsule walks across held crossing at row " + str(row), grid.to_local(walker.global_position).z > row + 4.0 and lowest > deck - 0.02, str(grid.to_local(walker.global_position)))
	walker.queue_free()

func finish() -> void:
	var output := "res://doc/book/iterations/2026-09-19-transformation-review/evidence/late/transformation-opening-" + map_name + ".json"
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify({"map":map_name,"checks":checks,"failures":failures,"measurements":measurements,"actual_endless_museum":true,"headset_tested":false}, "  "))
	file.close()
	print("[opening] ", checks.size() - failures.size(), "/", checks.size(), " passed; ", output)
	quit(0 if failures.is_empty() else 1)
