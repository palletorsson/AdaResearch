extends SceneTree
## Isolated production target with the current Void configuration.
## Tests lifetime and re-entry, not player input or perceptual appearance.
var output := ""
var checks: Array = []
var events := 0

func _initialize() -> void:
	run.call_deferred()

func check(label: String, result: bool) -> void:
	checks.append({"check": label, "passed": result})
	print("PASS " if result else "FAIL ", label)

func settle() -> void:
	await process_frame
	await process_frame
	await create_timer(0.0).timeout

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			output = arg.trim_prefix("--out=")
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var point := Node3D.new()
	point.position = Vector3(20, -10, 0)
	point.add_to_group("ada_coordinate_point")
	world.add_child(point)
	var floor_body := StaticBody3D.new()
	floor_body.position = Vector3(4, -12.2, -1)
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(14, .4, 14)
	collider.shape = box
	floor_body.add_child(collider)
	world.add_child(floor_body)
	var rooms: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/rooms.json"))
	var record: Dictionary = {}
	for item in rooms.floors[2].artifacts:
		if item.artifact == "drag_point_target":
			record = item
	check("Point Coordinates target is placed", not record.is_empty())
	if record.is_empty():
		quit(1)
		return
	var target: Node3D = load("res://commons/artifacts/drag_point_target/drag_point_target.gd").new()
	target.apply_grid_config(record.config)
	target.position = Vector3(record.position[0], -12.0 + record.height, record.position[1])
	world.add_child(target)
	target.balls_dropped.connect(func(_count): events += 1)
	await settle()
	check("Seven balls; original 26-second minimum lifetime; one decimal world labels",
		target.ball_count == 7 and target.ball_life == 26.0 and target.label_decimals == 1 and target.label_space == "world")
	var centre: Vector3 = target.global_position + Vector3(0, target.catch_height, 0)
	point.global_position = centre
	await settle()
	check("Registered point arrival creates seven balls once", events == 1 and target._tags.size() == 7)
	var original_ids: Array[int] = []
	var labels_match := true
	var no_grab := true
	for entry in target._tags:
		original_ids.append(entry.body.get_instance_id())
		no_grab = no_grab and not entry.body.has_method("pick_up")
		var p: Vector3 = entry.body.global_position
		labels_match = labels_match and entry.tag.text == "%.1f, %.1f, %.1f" % [p.x, p.y, p.z]
	check("Falling-ball labels report their own world positions", labels_match)
	check("White balls have no pickup method", no_grab)
	await create_timer(25.5).timeout
	await settle()
	check("All seven remain before their original timers expire", target._tags.size() == 7)
	await create_timer(3.0).timeout
	await settle()
	check("All original bodies and their labels are removed", target._tags.is_empty() and target._balls.get_child_count() == 0)
	check("Remaining in the target does not replace the missing balls", events == 1)
	point.global_position = centre + Vector3(2, 0, 0)
	await settle()
	var visitor := Node3D.new()
	world.add_child(visitor)
	visitor.global_position = centre
	await settle()
	check("Unregistered visitor at arrow does not cause a fall", events == 1)
	point.global_position = centre
	await settle()
	var fresh: bool = target._tags.size() == 7
	for entry in target._tags:
		fresh = fresh and entry.body.get_instance_id() not in original_ids
	check("Returning the registered point creates seven new bodies", events == 2 and fresh)
	var passed := true
	for entry in checks:
		passed = passed and entry.passed
	DirAccess.make_dir_recursive_absolute(output)
	FileAccess.open(output.path_join("runtime-checks.json"), FileAccess.WRITE).store_string(JSON.stringify({
		"passed": passed,
		"scope": "Headless Godot production target, saved floor-2 configuration, synthetic registered point and simple collision slab. Unmodified lifetime. No player input, appearance, audio or headset verification.",
		"checks": checks,
		"target_record": record
	}, "\t"))
	print("RESIDUE_PROBE_COMPLETE ", passed)
	quit(0 if passed else 1)
