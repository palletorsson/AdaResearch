extends "res://commons/testing/probe_physical_console_halls.gd"
## Actual two-builder hall: placement, native button input and comparison independence.
var pointer: Node3D

func press(button: Node3D) -> void:
	var area: Node3D = button.get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(pointer, area, area.global_position)
	XRToolsPointerEvent.released(pointer, area, area.global_position)

func complete(cube: Node3D) -> void:
	for i in 45: cube.call("_process", .51)

func run() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	folder = spec.run
	report.room = spec.room
	report.scope = "Actual museum hall, standing capsule, native pointer buttons, world control dimensions. Desktop evidence; headset comfort not tested."
	museum = load(folder+"museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL", folder+"control.json")
	museum.set("_hand_path", folder+"necklace_hand.json")
	museum.set("_overrides_path", folder+"em_overrides.json")
	museum.set("start_chapter", spec.sequence)
	museum.set("start_map", spec.room)
	museum.set("plan_file", folder+"em_plan.json")
	root.add_child(museum)
	var started := Time.get_ticks_msec()
	while not museum.get("_museum_core_ready") and Time.get_ticks_msec()-started < 60000: await process_frame
	museum.set("_lazy_pending", 0)
	museum.set_process(false)
	museum.set_physics_process(false)
	museum.call("flush_stamps")
	await create_timer(1).timeout
	var hall: Node3D
	for child in museum.get_children():
		if child is Node3D and child.get_meta("em_map", "") == spec.room: hall = child; break
	check(hall != null, "Requested hall built")
	if hall == null: finish(); return
	origin = hall.global_position
	walker = museum.get("_player")
	if walker: walker.set_physics_process(false)
	pointer = Node3D.new()
	root.add_child(pointer)
	camera = Camera3D.new()
	root.add_child(camera)
	camera.current = true
	var cubes: Array[Node3D] = []
	for entry in museum.get("_edit_records"):
		if entry.get("seg") == hall and entry.get("token") == spec.token: cubes.append(entry.node)
	check(cubes.size() == 2, "Both authored builders remain for comparison")
	report.builders = []
	for index in cubes.size():
		artifact = cubes[index]
		var panel: Node3D = artifact.get_node("ExperimentPanel")
		var front := artifact.global_basis.z.normalized()
		front.y = 0
		front = front.normalized()
		feet = panel.global_position + front*.48
		var floor_hit := floor_at(feet)
		check(not floor_hit.is_empty(), "Builder %d operating pose has floor" % index)
		if floor_hit.is_empty(): continue
		feet.y = floor_hit.position.y
		if walker: walker.global_position = feet
		museum.call("_cull_artifacts")
		artifact.set_process(false)
		complete(artifact)
		panel.update_readout()
		await process_frame
		await physics_frame
		report.builders.append({"index":index, "artifact":arr(artifact.global_position-origin), "panel":arr(panel.global_position-origin), "feet":arr(feet-origin)})
		var capsule := CapsuleShape3D.new()
		capsule.radius = .22
		capsule.height = 1.7
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.collision_mask = 1
		query.transform.origin = feet+Vector3.UP*.87
		if walker: query.exclude = [walker.get_rid()]
		check(museum.get_world_3d().direct_space_state.intersect_shape(query).is_empty(), "Builder %d standing capsule clears geometry" % index)
		for name in ["ReplayButton","PauseButton","RestoreButton","DiagonalButton"]:
			var button: Node3D = panel.get_node(name)
			inspect_target(button, button.get_node("InteractableAreaButton/CollisionShape3D").global_position, "%d %s" % [index,name], button)
		camera.global_position = artifact.global_position+front*2.7+Vector3.UP*.7
		camera.look_at(artifact.global_position+Vector3.UP*.05)
		camera.fov = 70
		await capture("builder-%d-encounter" % index)
		camera.global_position = feet+Vector3.UP*1.65
		camera.look_at(panel.global_position)
		camera.fov = 72
		await capture("builder-%d-controls" % index)
		press(panel.get_node("ReplayButton"))
		artifact.call("_process", .51)
		press(panel.get_node("PauseButton"))
		var step: int = artifact.animation_step
		artifact.call("_process", 4.0)
		check(artifact.animation_step == step and artifact.discovery_paused, "Builder %d pause stops its assembly" % index)
		press(panel.get_node("PauseButton"))
		complete(artifact)
		check(artifact.get_current_phase() == "complete" and artifact.handle_nodes[6].enabled, "Builder %d resume reveals usable corners" % index)
		press(panel.get_node("DiagonalButton"))
		check(artifact._diagonal_lines.all(func(line): return line.visible), "Builder %d diagonal button reveals all six source diagonals" % index)
		press(panel.get_node("RestoreButton"))
		check(artifact.vertices == artifact._initial_vertices, "Builder %d restore retains initial cube" % index)
	finish()
