extends "res://commons/testing/probe_physical_console_halls.gd"
## Render the actual authored halls with a reproducible, explicitly supplied stroke.
func run() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	folder = spec.run
	report.room = spec.room
	report.scope = "Actual triangle hall; supplied endpoint/drawing positions; desktop images and layout measurements. No headset test."
	museum = load(folder + "museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL", folder + "control.json")
	museum.set("_hand_path", folder + "necklace_hand.json")
	museum.set("_overrides_path", folder + "em_overrides.json")
	museum.set("start_chapter", spec.sequence)
	museum.set("start_map", spec.room)
	museum.set("plan_file", folder + "em_plan.json")
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
	var script_path: String = "res://commons/primitives/line/puzzles/triangle_line_puzzle.gd" if spec.case == "puzzle" else "res://commons/primitives/point/draw_triangle_faces.gd"
	for entry in museum.get("_edit_records"):
		if entry.get("seg") == hall and entry.get("token") == spec.token and entry.node.get_script() == load(script_path):
			artifact = entry.node; break
	check(is_instance_valid(artifact), "Authored triangle artifact found")
	if not is_instance_valid(artifact): finish(); return
	walker = museum.get("_player")
	if walker: walker.set_physics_process(false)
	artifact.set_process(false)
	if spec.case == "puzzle":
		var targets: Array = artifact.get("target_positions")
		for i in 3:
			var line: Node3D = artifact.get("snap_lines")[i]
			line.endpoint_a.global_position = artifact.to_global(targets[i])
			line.endpoint_b.global_position = artifact.to_global(targets[(i+1)%3])
			line._update_line_geometry()
			line.endpoints_changed.emit(line.endpoint_a.global_position,line.endpoint_b.global_position)
		artifact.call("toggle_discovery_face")
	else:
		var handle: RigidBody3D = artifact.get_node("GrabPoint")
		handle.freeze = true
		var tip: Node3D = artifact.get("_draw_sphere")
		var boundary: Array[Vector2] = [Vector2(0,0),Vector2(1.2,0),Vector2(1.2,.4),Vector2(.4,.4),Vector2(.4,1.2),Vector2(0,1.2),Vector2(0,0)]
		artifact.call("_on_grab_point_picked_up",handle)
		for point in boundary:
			tip.global_position = artifact.to_global(Vector3(point.x-.6,0,point.y-.6))
			artifact.call("_process",1.01)
		artifact.call("_on_grab_point_dropped",handle)
	var panel: Node3D = artifact.get_node("ExperimentPanel")
	panel.call("update_readout")
	check(panel != null, "Experiment panel assembled")
	var front := panel.global_basis.z.normalized()
	front.y = 0
	front = front.normalized()
	feet = panel.global_position + front * .55
	# Museum deck is one metre above the sunken grid. Start the ray above both.
	var ray := PhysicsRayQueryParameters3D.create(feet+Vector3.UP*2, feet-Vector3.UP*5, 1)
	if walker: ray.exclude = [walker.get_rid()]
	var hit := museum.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty(), "Reading position has floor")
	if not hit.is_empty(): feet.y = hit.position.y
	var capsule := CapsuleShape3D.new()
	capsule.radius = .22
	capsule.height = 1.7
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.transform.origin = feet + Vector3.UP*.87
	if walker: query.exclude = [walker.get_rid()]
	var obstacles := museum.get_world_3d().direct_space_state.intersect_shape(query)
	report.standing_obstacles = obstacles.map(func(o): return str(o.collider.get_path()))
	check(obstacles.is_empty(),"Standing capsule fits at reading position")
	var approach_found := false
	var clear_approach := Vector3.ZERO
	report.approaches = []
	for direction in [front,front.rotated(Vector3.UP,PI/2),front.rotated(Vector3.UP,-PI/2)]:
		query.transform.origin = feet + direction + Vector3.UP*.87
		query.motion = -direction
		var clear_start := museum.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
		var motion := museum.get_world_3d().direct_space_state.cast_motion(query)
		var supported := true
		for step in 6:
			var at: Vector3 = feet + direction*float(step)/5
			var floor_ray := PhysicsRayQueryParameters3D.create(at+Vector3.UP*.2,at-Vector3.UP*.25,1)
			if walker: floor_ray.exclude = [walker.get_rid()]
			var floor_hit := museum.get_world_3d().direct_space_state.intersect_ray(floor_ray)
			supported = supported and not floor_hit.is_empty() and absf(floor_hit.get("position",Vector3(0,-999,0)).y-feet.y)<.05
		var valid: bool = clear_start and motion[0]>.99 and supported
		if valid and not approach_found: clear_approach = direction
		approach_found = approach_found or valid
		report.approaches.append({"direction":arr(direction),"clear_start":clear_start,"clear_motion":motion[0],"supported":supported,"passed":valid})
	check(approach_found,"A supported final metre reaches the operating pose")
	report.panel = {"position":arr(panel.global_position-origin),"height_above_floor":panel.global_position.y-feet.y}
	if walker: walker.global_position = feet
	museum.call("_cull_artifacts")
	artifact.set_process(false)
	camera = Camera3D.new()
	root.add_child(camera)
	camera.current = true
	camera.global_position = feet + Vector3.UP*1.65
	camera.fov = 75
	camera.look_at(panel.global_position)
	await capture("reading")
	camera.global_position = feet + clear_approach*.8 + Vector3.UP*1.65
	camera.fov = 80
	camera.look_at(artifact.global_position + Vector3.UP*.05)
	await capture("encounter")
	var buttons: Array[Node3D] = [panel.get_node("FillButton")]
	if spec.case == "drawing":
		buttons.append(panel.get_node("ShiftStartButton"))
		buttons.append(panel.get_node("NewOutlineButton") if panel.has_node("NewOutlineButton") else artifact.get_node("NewOutlineButton"))
	for button in buttons:
		var shape: CollisionShape3D = button.get_node("InteractableAreaButton/CollisionShape3D")
		inspect_target(button, shape.global_position, str(button.name), button)
	finish()
