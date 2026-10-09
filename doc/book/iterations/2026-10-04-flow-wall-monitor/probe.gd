extends SceneTree
## Current-source real hall capture; run paths are supplied by the isolated helper.
var checks: Array = []
var observations: Dictionary = {}
var out := ""
var phase := "before"
var museum: Node3D
var painter: Node3D
var lesson: Node3D
var camera: Camera3D

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks.append({"ok": ok, "label": label})
	print("[flow-wall] ", "PASS " if ok else "FAIL ", label)

func array3(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

func press(area: Area3D) -> void:
	XRToolsPointerEvent.pressed(camera, area, area.global_position)
	XRToolsPointerEvent.released(camera, area, area.global_position)

func button(key: String) -> void:
	press(lesson.buttons[key].get_node("InteractableAreaButton"))

func run() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	out = spec.output
	phase = spec.phase
	var folder: String = spec.run
	root.size = Vector2i(1600, 1000)
	museum = load(folder + "museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL", folder + "control.json")
	museum.set("_hand_path", folder + "necklace_hand.json")
	museum.set("_overrides_path", folder + "em_overrides.json")
	museum.set("start_chapter", "change")
	museum.set("start_map", "Flow_Field")
	museum.set("plan_file", folder + "plan.json")
	root.add_child(museum)
	current_scene = museum
	var started := Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec() - started < 65000:
		await process_frame
	check(bool(museum.get("_museum_core_ready")), "museum core ready")
	museum.set("_lazy_pending", 0)
	museum.set_process(false)
	museum.set_physics_process(false)
	museum.call("flush_stamps")
	await create_timer(1.0).timeout
	var hall: Node3D
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map", "")) == "Flow_Field": hall = child
	check(hall != null, "actual Flow_Field hall loaded")
	if hall == null: finish(); return
	var found: Dictionary = {}
	for n in hall.find_children("*", "Node3D", true, false):
		if not n.has_meta("artifact_lookup_name"): continue
		var parent := n.get_parent()
		var nested := false
		while parent and parent != hall:
			if parent.has_meta("artifact_lookup_name"): nested = true; break
			parent = parent.get_parent()
		if nested: continue
		var key: String = str(n.get_meta("artifact_lookup_name"))
		found[key] = int(found.get(key, 0)) + 1
		if key == "flow_field_painter": painter = n
	for key in ["flow_field_painter", "vector_field_visualizer", "vector_field_grid", "particle_flow_swarm", "noc_5_04_flow_field", "grand_zoetrope"]:
		check(found.get(key, 0) == 1, "retained placement: " + key)
	observations["placed_artifacts"] = found
	if painter == null: finish(); return
	lesson = painter.get("field_lesson")
	check(lesson != null, "shared field host present")
	if lesson == null: finish(); return
	var player: Node3D = museum.get("_player")
	if player != null:
		player.set_physics_process(false)
		player.hide()
	var feel = museum.get("_feel")
	if feel != null: feel.set_process(false)
	var wardrobe = museum.get("_wardrobe")
	if wardrobe != null:
		wardrobe.appearance_save_path = ""
		wardrobe.costume.visible = false
	for timer in museum.find_children("*", "Timer", true, false): timer.stop()
	for overlay in root.find_children("*", "CanvasLayer", true, false): overlay.hide()
	camera = Camera3D.new()
	root.add_child(camera)
	museum.set("_cam", camera)
	camera.make_current()
	painter.set_process(false)
	lesson.set_process(false)
	observations["painter_position"] = array3(painter.global_position)
	observations["painter_scale"] = array3(painter.global_basis.get_scale())
	check(painter._particles.size() == 80, "eighty particles preserved")
	if phase == "after": await interaction_checks()
	seed(43019)
	painter._noise.seed = 43
	painter._time = 0.0
	painter.noise_scale = 3.0
	painter._update_noise()
	painter.particle_speed = 0.1
	painter.field_evolving = false
	painter._create_particles()
	for i in 120: painter._process(1.0 / 60.0)
	lesson.arrows.show()
	lesson.refresh()
	var records: Array = []
	for p in painter._particles:
		var trail: Array = []
		for q in p.trail: trail.append([q.x, q.y])
		records.append({"position": [p.x, p.y], "trail": trail})
	write_json(out + "particles.json", records)
	var eye: Vector3
	var target: Vector3
	if phase == "before":
		eye = painter.to_global(Vector3(0, 0, 1.1))
		eye.y = 1.65
		target = painter.to_global(Vector3(0, -0.02, 0.15))
	else:
		eye = painter.to_global(Vector3(0, 1.65, 5.8))
		target = painter.to_global(Vector3(0, 2.0, -0.05))
	await shot(eye, target, "standing")
	if phase == "after":
		await shot(painter.to_global(Vector3(0, 1.65, 3.5)), painter.to_global(Vector3(0, 1.9, -0.05)), "near")
	observations["capture_state"] = {"seed": 43019, "field_seed": 43, "field_time": 0, "speed": 0.1, "noise_scale": 3, "steps": 120, "delta": 1.0 / 60.0}
	finish()

func interaction_checks() -> void:
	check(not painter.field_evolving, "field initially held")
	var point := Vector2(0.03, 0.02)
	var direction: Vector2 = painter.field_direction(point)
	check(is_equal_approx(direction.length(), 1.0), "sampler returns unit direction")
	painter._particles[0].x = point.x
	painter._particles[0].y = point.y
	var held: float = painter._time
	painter._process(0.01)
	check(Vector2(painter._particles[0].x, painter._particles[0].y).is_equal_approx(point + direction * painter.particle_speed * 0.01), "update unchanged: direction times speed times seconds")
	check(painter._time == held, "held field clock remains still while particle advances")
	lesson.arrows.hide()
	button("ARROWS")
	check(lesson.arrows.visible, "ARROWS pointer event reveals field")
	var vertices: PackedVector3Array = lesson.arrows.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(vertices.size() == 144, "twenty-four field glyphs preserved")
	var arrow_error := 0.0
	for i in 24:
		var start := Vector2(vertices[i * 6].x, vertices[i * 6].z)
		var end := Vector2(vertices[i * 6 + 1].x, vertices[i * 6 + 1].z)
		arrow_error = maxf(arrow_error, (end - start).normalized().distance_to(painter.field_direction(start)))
	check(arrow_error < 0.00001, "arrow directions still match the particle sampler")
	button("ARROWS")
	check(not lesson.arrows.visible, "ARROWS pointer event hides field")
	button("FIELD TIME")
	painter._process(0.1)
	check(painter.field_evolving and painter._time > held, "FIELD TIME pointer event advances clock")
	button("FIELD TIME")
	held = painter._time
	painter._process(0.1)
	check(not painter.field_evolving and painter._time == held, "FIELD TIME holds current time")
	var seed_before: int = painter._noise.seed
	press(painter._reset_area)
	check(painter._particles.all(func(p): return p.trail.is_empty()), "RESET pointer event clears trails")
	check(painter._noise.seed == seed_before and painter._time == held, "RESET preserves field seed and time")
	press(painter._seed_area)
	check(painter._noise.seed != seed_before, "SEED pointer event changes field")
	painter._speed_slider.set_normalized_value(0.5)
	painter._speed_slider.slider_moved.emit(0.5)
	check(is_equal_approx(painter.particle_speed, 0.16), "SPEED callback reaches existing update")
	painter._scale_slider.set_normalized_value(0.5)
	painter._scale_slider.slider_moved.emit(0.5)
	check(is_equal_approx(painter.noise_scale, 5.25) and is_equal_approx(painter._noise.frequency, 0.0525), "SCALE callback changes sampler once")
	var monitor: Node3D = lesson.get("monitor")
	check(monitor != null, "wall monitor host exists")
	if monitor != null:
		check(painter._canvas_mesh.get_parent() == monitor and painter._trail_mesh.get_parent() == monitor and lesson.arrows.get_parent() == monitor, "canvas trails and arrows share one monitor transform")
		var corners: Array = []
		for x in [-painter.canvas_size.x * 0.5, painter.canvas_size.x * 0.5]:
			for z in [-painter.canvas_size.y * 0.5, painter.canvas_size.y * 0.5]:
				corners.append(monitor.to_global(Vector3(x, 0, z)))
		var low := INF
		var high := -INF
		for q in corners: low = minf(low, q.y); high = maxf(high, q.y)
		check(is_equal_approx(low, 0.6) and is_equal_approx(high, 3.8), "screen occupies wall height 0.6 to 3.8 metres")
		check(absf(monitor.global_basis.y.normalized().dot(Vector3.UP)) < 0.001, "screen is vertical")
		observations["screen_y"] = [low, high]
	var controls: Dictionary = {"ARROWS": lesson.buttons["ARROWS"], "FIELD TIME": lesson.buttons["FIELD TIME"], "RESET": painter._reset_area, "SEED": painter._seed_area, "SPEED": painter._speed_slider, "SCALE": painter._scale_slider}
	var heights: Dictionary = {}
	for key in controls:
		var y: float = controls[key].global_position.y
		heights[key] = y
		check(y >= 0.8 and y <= 1.5, "reachable standing control height: " + key)
	observations["control_heights"] = heights
	await physics_frame
	var eye: Vector3 = painter.to_global(Vector3(0, 1.65, 2.6))
	var button_areas: Dictionary = {"ARROWS": lesson.buttons["ARROWS"].get_node("InteractableAreaButton"), "FIELD TIME": lesson.buttons["FIELD TIME"].get_node("InteractableAreaButton"), "RESET": painter._reset_area, "SEED": painter._seed_area}
	for key in button_areas:
		var area: Area3D = button_areas[key]
		var query := PhysicsRayQueryParameters3D.create(eye, area.global_position)
		query.collision_mask = 1 | area.collision_layer
		query.collide_with_areas = true
		var hit: Dictionary = painter.get_world_3d().direct_space_state.intersect_ray(query)
		observations["pointer_ray_" + key] = {"eye": array3(eye), "target": array3(area.global_position), "mask": query.collision_mask, "hit": str(hit.get("collider", "none"))}
		check(not hit.is_empty() and hit.collider == area, "unobstructed standing pointer ray: " + key)

func shot(eye: Vector3, target: Vector3, label: String) -> void:
	camera.global_position = eye
	camera.look_at(target)
	camera.fov = 60
	for i in 20:
		museum.call("_cull_artifacts")
		camera.make_current()
		await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_camera_3d() == camera, "inspection camera retained: " + label)
	check(painter.is_visible_in_tree(), "painter visible: " + label)
	check(root.get_texture().get_image().save_png(out + label + ".png") == OK, "capture saved: " + label)
	write_json(out + label + "-camera.json", {"eye": array3(eye), "target": array3(target), "fov": camera.fov, "viewport": [root.size.x, root.size.y]})

func write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "  "))
	file.close()

func finish() -> void:
	var failures: Array = checks.filter(func(c): return not c.ok)
	var result := {"phase": phase, "checks": checks, "failures": failures, "observations": observations, "headset_tested": false, "learner_verified": false}
	write_json(out + "checks.json", result)
	if not OS.get_cmdline_user_args().is_empty():
		var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
		write_json(str(spec.run) + "report.json", result)
	print("FLOW_WALL ", checks.size(), " checks / ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
