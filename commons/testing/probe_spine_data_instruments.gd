extends "res://commons/testing/probe_physical_console_halls.gd"
## Render the actual authored halls with a reproducible, explicitly supplied stroke.
func run() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	folder = spec.run
	report.room = spec.room
	report.scope = "Actual museum hall; supplied stroke; desktop images and layout measurements. No headset test."
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
	var script_path: String = "res://commons/primitives/point/draw_dot.gd" if spec.case == "trace" else "res://commons/primitives/line/grid_lines.gd"
	for entry in museum.get("_edit_records"):
		if entry.get("seg") == hall and entry.get("token") == spec.token and entry.node.get_script() == load(script_path):
			artifact = entry.node; break
	check(is_instance_valid(artifact), "Authored artifact found, rather than its plinth")
	if not is_instance_valid(artifact): finish(); return
	walker = museum.get("_player")
	if walker: walker.set_physics_process(false)
	artifact.set_process(false)
	var stroke_origin: Vector3 = artifact.get_node("GrabPoint").global_position if spec.case == "trace" else artifact.to_global(Vector3(0,1.30,0))
	var points: Array[Vector3] = []
	for i in 24:
		points.append(stroke_origin + artifact.global_basis * Vector3(-.30+i*.025, sin(i*.26)*.14, -.08+cos(i*.26)*.16))
	if spec.case == "trace":
		# Exercise the real sampling gate with controlled positions, not a mocked text.
		artifact.set("record_only_when_grabbed", false)
		artifact.set("data_table_update_interval", 0.0)
		for point in points:
			artifact.get_node("GrabPoint").global_position = point
			artifact.call("_process", .2)
	else:
		root.get_node("TraceData").add_trace(points)
	var panel: Node3D = artifact.get("_data_panel")
	check(panel != null, "Readout assembled in the hall")
	if panel == null: finish(); return
	var front := artifact.global_basis.z.normalized()
	feet = panel.global_position + front * .70
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
	check(museum.get_world_3d().direct_space_state.intersect_shape(query).is_empty(), "Standing capsule fits at reading position")
	query.transform.origin += front
	query.motion = -front
	var motion := museum.get_world_3d().direct_space_state.cast_motion(query)
	check(motion[0] > .99, "Final metre of approach is unobstructed")
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
	camera.global_position = feet + front*2 + Vector3.UP*1.65
	camera.fov = 80
	camera.look_at(artifact.to_global(Vector3(1.1,1.0,0)))
	await capture("encounter")
	if artifact.has_method("set_archive_auto"):
		for button in artifact.get("_page_buttons"):
			var shape: CollisionShape3D = button.get_node("InteractableAreaButton/CollisionShape3D")
			inspect_target(button, shape.global_position, str(button.name), button)
	finish()
