extends SceneTree
## Local review probe; executes the production lesson in its actual museum hall.
const BASE := "res://doc/book/iterations/2026-09-19-change-review/flow/"
var out := BASE + "runtime/"
var replay_before := false
var capture_images := false
var artifact_only := false
var originals: Array[Resource] = []
var checks: Array[Dictionary] = []
var observations: Dictionary = {}
var painter: Node3D
var lesson: Node3D
var camera: Camera3D
var museum: Node3D
var player: CharacterBody3D

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	replay_before = "--replay-before" in OS.get_cmdline_user_args()
	capture_images = "--capture" in OS.get_cmdline_user_args()
	artifact_only = "--artifact-only" in OS.get_cmdline_user_args()
	if replay_before:
		for source in ["commons/artifacts/flow_field_painter/flow_field_painter.gd"]:
			var original := GDScript.new()
			original.source_code = FileAccess.get_file_as_string(BASE + "before/" + source).replace("class_name FlowFieldPainter", "")
			# Preload the unchanged baseline lesson from its real snapshot path.
			# A transient script taking over that path cannot be resolved by preload.
			original.source_code = original.source_code.replace("res://commons/artifacts/flow_field_painter/shared_field_lesson.gd", BASE + "before/commons/artifacts/flow_field_painter/shared_field_lesson.gd")
			check(original.reload() == OK, "before snapshot compiles: " + source)
			original.take_over_path("res://" + source)
			originals.append(original)
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks.append({"ok": ok, "message": message})
	print("[flow-review] ", "PASS " if ok else "FAIL ", message)

func press(area: Area3D) -> void:
	XRToolsPointerEvent.pressed(camera, area, area.global_position)
	XRToolsPointerEvent.released(camera, area, area.global_position)

func lesson_press(id: String) -> void:
	press(lesson.buttons[id].get_node("InteractableAreaButton"))

func run() -> void:
	if artifact_only:
		var world := Node3D.new()
		root.add_child(world); current_scene = world
		painter = load("res://commons/artifacts/flow_field_painter/flow_field_painter.tscn").instantiate()
		painter.set_meta("config_lesson", "shared_field")
		world.add_child(painter)
		camera = Camera3D.new(); world.add_child(camera)
	else:
		await load_museum()
	if not painter:
		finish(); return
	lesson = painter.get("field_lesson")
	check(lesson != null, "shared-field lesson loads")
	if not lesson:
		finish(); return
	painter.set_process(false); lesson.set_process(false)
	await controls_and_sampler()
	if capture_images and not artifact_only:
		await captures()
	finish()

func load_museum() -> void:
	museum = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var control := out + "museum-control.json"
	var f := FileAccess.open(control, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "change", "dollhouse": 0, "grid_pack": 1})); f.close()
	museum.set("EM_CONTROL", control); museum.set("_overrides_path", control + ".unused")
	museum.set("_hand_path", control + ".unused-hand")
	museum.set("start_chapter", "change"); museum.set("start_map", "Flow_Field")
	root.add_child(museum); current_scene = museum
	await create_timer(1).timeout
	museum.set_process(false); museum.set_physics_process(false); museum.call("flush_stamps")
	var segment: Node3D
	for rec: Dictionary in museum.get("_segments"):
		if rec.node.get_meta("em_map", "") == "Flow_Field": segment = rec.node; break
	check(segment != null, "actual museum contains Flow_Field segment")
	if not segment: return
	check(not segment.has_node("SimGrid_Flow_Field"), "ordinary authored museum transplant, without simulation-grid substitution")
	for i in 30: await process_frame
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/Flow_Field/map_data.json"))
	var found: Dictionary = {}
	for n in segment.find_children("*", "Node3D", true, false):
		if n.has_meta("artifact_lookup_name"):
			var parent = n.get_parent()
			var nested := false
			while parent and parent != segment:
				if parent.has_meta("artifact_lookup_name"): nested = true; break
				parent = parent.get_parent()
			if nested: continue
			var key := str(n.get_meta("artifact_lookup_name"))
			found[key] = int(found.get(key, 0)) + 1
			if key == "flow_field_painter": painter = n
	for key in ["flow_field_painter", "vector_field_visualizer", "vector_field_grid", "particle_flow_swarm", "noc_5_04_flow_field", "grand_zoetrope"]:
		check(found.get(key, 0) == 1, "authored primary/secondary remains placed once: " + key)
	for row in source.layers.interactables:
		for raw in row:
			var key := str(raw).split(":")[0].split("#")[0].strip_edges()
			if not key.is_empty(): check(found.get(key, 0) == 1, "runtime placement matches authored token: " + key)
	observations["placed_artifacts"] = found
	player = museum.get("_player"); player.set_physics_process(false)
	museum.get("_feel").set_process(false)
	var wardrobe = museum.get("_wardrobe")
	wardrobe.appearance_save_path = ""; wardrobe.costume.visible = false
	camera = museum.get("_cam")
	if painter:
		var standing := painter.to_global(Vector3(0, 0, 0.88)); standing.y = 1.65
		player.global_position += standing - camera.global_position
		camera.look_at(painter.global_position)
		for i in 20:
			museum.call("_cull_artifacts")
			await process_frame
		check(painter.is_visible_in_tree(), "painter remains visible from standing approach")
		observations["painter_world_position"] = vec(painter.global_position)
		observations["painter_world_scale"] = vec(painter.global_basis.get_scale())

func controls_and_sampler() -> void:
	check(painter._particles.size() == 80, "authored lesson retains eighty particles")
	check(not painter.field_evolving and not lesson.arrows.visible, "field initially held and arrows hidden")
	lesson.refresh()
	observations["initial_status"] = lesson.status.text
	check(lesson.status.text.contains("ARROWS = PARTICLE SAMPLER") if replay_before else lesson.status.text.ends_with("ARROWS HIDDEN"), "initial display matches snapshotted or repaired reveal timing")
	check(painter._canvas_mesh.rotation_degrees.x == 0, "canvas and trails share XZ plane")
	check(painter._info_label.visible if replay_before else not painter._info_label.visible, "lesson preserves original overlap or hides duplicate title after repair")
	var tabletop_y: float = painter.to_global(Vector3(0, -0.075, 0)).y
	var lower_tags: Array[float] = []
	for child in painter._control_panel.get_children():
		if child is MeshInstance3D and child.mesh is QuadMesh and child.position.y < -0.07:
			var bounds: AABB = child.global_transform * child.get_aabb()
			lower_tags.append(bounds.position.y - tabletop_y)
	check(lower_tags.size() == 2, "RESET/SEED label quads are identified geometrically")
	check(lower_tags.all(func(y): return y < 0.0) if replay_before else lower_tags.all(func(y): return y > 0.0), "baseline label burial or repaired tabletop clearance is measurable")
	observations["reset_seed_label_clearance_metres"] = lower_tags
	for area in [painter._reset_area, painter._seed_area]:
		var shape: CollisionShape3D = area.get_node("CollisionShape3D")
		var box: AABB = shape.global_transform * shape.shape.get_debug_mesh().get_aabb()
		if not replay_before: check(box.position.y > tabletop_y, "button interaction volume clears lesson tabletop: " + str(area.get_parent().name))
	var point := Vector2(0.03, 0.02)
	var direction: Vector2 = painter.field_direction(point)
	check(is_equal_approx(direction.length(), 1.0), "noise-to-angle returns a unit direction")
	painter._particles[0].x = point.x; painter._particles[0].y = point.y
	var held_time: float = painter._time
	painter._process(0.01)
	check(Vector2(painter._particles[0].x, painter._particles[0].y).is_equal_approx(point + direction * painter.particle_speed * 0.01), "particle displacement follows direction times speed times delta")
	check(painter._time == held_time, "held field clock stays fixed during particle movement")
	lesson_press("ARROWS")
	check(lesson.arrows.visible, "ARROWS pointer event reveals arrow mesh")
	var vertices: PackedVector3Array = lesson.arrows.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(vertices.size() == 144, "24 glyphs each have shaft and two arrowhead strokes")
	var max_error := 0.0
	for i in 24:
		var start := Vector2(vertices[i * 6].x, vertices[i * 6].z)
		var end := Vector2(vertices[i * 6 + 1].x, vertices[i * 6 + 1].z)
		max_error = maxf(max_error, (end - start).normalized().distance_to(painter.field_direction(start)))
	check(max_error < 0.00001, "all drawn arrow directions agree with particle sampler at their own addresses")
	check(lesson.status.text.contains("PARTICLE SAMPLER") if replay_before else lesson.status.text.ends_with("ARROWS SHOWN"), "revealed display reports correct state")
	lesson_press("FIELD TIME"); painter._process(0.1)
	check(painter.field_evolving and painter._time > held_time, "FIELD TIME pointer event advances field clock")
	lesson_press("FIELD TIME")
	held_time = painter._time; painter._process(0.1)
	check(not painter.field_evolving and painter._time == held_time, "FIELD TIME pointer event holds current time without rewinding")
	var seed_before: int = painter._noise.seed
	var position_before := Vector2(painter._particles[0].x, painter._particles[0].y)
	press(painter._reset_area)
	check(painter._particles.all(func(p): return p.trail.is_empty()), "RESET pointer event clears every trail")
	check(not position_before.is_equal_approx(Vector2(painter._particles[0].x, painter._particles[0].y)), "RESET scatters particle positions")
	check(painter._noise.seed == seed_before and painter._time == held_time, "RESET retains noise seed and current field time")
	press(painter._seed_area)
	check(painter._noise.seed != seed_before and painter._time == held_time, "SEED pointer event changes noise seed without rewinding field time")
	check(painter._particles.all(func(p): return p.trail.is_empty()), "SEED also clears trails")
	painter._speed_slider.set_normalized_value(0.5)
	painter._speed_slider.slider_moved.emit(0.5)
	check(is_equal_approx(painter.particle_speed, 0.16), "SPEED slider signal reaches prescribed speed")
	painter._scale_slider.set_normalized_value(0.5)
	painter._scale_slider.slider_moved.emit(0.5)
	check(is_equal_approx(painter.noise_scale, 5.25) and is_equal_approx(painter._noise.frequency, 0.0525), "SCALE slider changes lesson noise frequency once")
	var a: Vector2 = painter.field_direction(Vector2(-0.3, -0.17))
	var b: Vector2 = painter.field_direction(Vector2(0.3, -0.17))
	observations["opposite_edge_direction_distance"] = a.distance_to(b)
	check(a.distance_to(b) > 0.001, "opposite wrapped addresses need not share a direction")
	# Force one observed boundary return while retaining the production wrap/mesh code.
	painter._noise.seed = 43; painter.noise_scale = 3.0; painter._time = 0.0
	var wrap_start := Vector2(0.2999, 0.0)
	if painter.field_direction(wrap_start).x <= 0.0: wrap_start.x = -0.2999
	var crossed := false
	for j in 30:
		wrap_start.y = -0.19 + j * 0.38 / 29.0
		if painter.field_direction(wrap_start).x * signf(wrap_start.x) > 0.1: crossed = true; break
	check(crossed, "probe finds outward-pointing sample near boundary")
	if crossed:
		painter._particles[0].x = wrap_start.x; painter._particles[0].y = wrap_start.y
		painter._particles[0].trail = PackedVector2Array([wrap_start])
		painter._process(0.01)
		var wrap_end := Vector2(painter._particles[0].x, painter._particles[0].y)
		observations["wrap_jump_local_metres"] = wrap_start.distance_to(wrap_end)
		check(wrap_start.distance_to(wrap_end) > 0.5, "coordinate return retains cross-canvas adjacent trail samples")
		var trail_vertices: PackedVector3Array = painter._im.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		check(trail_vertices[0].distance_to(trail_vertices[1]) > 0.5, "production renderer preserves the long seam stroke")
	if not replay_before:
		var legacy: Node3D = load("res://commons/artifacts/flow_field_painter/flow_field_painter.tscn").instantiate()
		legacy.position = Vector3(1000, 0, 0)
		root.add_child(legacy)
		check(legacy.field_lesson == null and legacy._info_label.visible, "unconfigured painter retains its base title")
		check(is_equal_approx(legacy._control_panel.position.y, -0.05) and is_equal_approx(legacy._control_panel.rotation_degrees.x, -30.0), "unconfigured painter retains original control placement")
		legacy.queue_free()
		await process_frame

func deterministic_picture() -> void:
	seed(43019)
	painter._noise.seed = 43; painter._time = 0.0; painter.noise_scale = 3.0
	painter.particle_speed = 0.1; painter.field_evolving = false
	painter._scale_slider.set_normalized_value((painter.noise_scale - 0.5) / 9.5)
	painter._speed_slider.set_normalized_value((painter.particle_speed - 0.02) / 0.28)
	painter._create_particles()
	for i in 120: painter._process(1.0 / 60.0)
	lesson.arrows.hide(); lesson.refresh()

func captures() -> void:
	deterministic_picture()
	var trace: Array = []
	for particle in painter._particles:
		var positions: Array = []
		for p in particle.trail: positions.append([p.x, p.y])
		trace.append({"position": [particle.x, particle.y], "trail": positions})
	var trace_file := FileAccess.open(out + "capture-particles.json", FileAccess.WRITE)
	trace_file.store_string(JSON.stringify(trace)); trace_file.close()
	var standing := painter.to_global(Vector3(0, 0, 1.1)); standing.y = 1.65
	await shot(standing, painter.to_global(Vector3(0, -0.02, 0.15)), "standing-hidden")
	lesson_press("ARROWS")
	await shot(standing, painter.to_global(Vector3(0, -0.02, 0.15)), "standing-shown")
	var near := painter.to_global(Vector3(0, 0, 0.70)); near.y = 1.65
	await shot(near, painter.to_global(Vector3(0, 0.015, -0.04)), "near-arrows-trails")
	observations["capture_state"] = {"random_seed": 43019, "field_seed": 43, "time": 0, "steps": 120, "delta": 1.0 / 60.0, "particles": painter._particles.size(), "trail_length": painter.trail_length, "noise_scale": painter.noise_scale, "speed": painter.particle_speed}

func vec(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

func shot(pos: Vector3, target: Vector3, label: String) -> void:
	player.global_position += pos - camera.global_position
	camera.global_position = pos; camera.look_at(target); camera.fov = 60
	for i in 20:
		museum.call("_cull_artifacts")
		camera.make_current()
		await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(out + label + ".png") == OK, "capture saved: " + label)
	var f := FileAccess.open(out + label + "-camera.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"position": vec(camera.global_position), "target": vec(target), "fov": camera.fov, "viewport": [root.size.x, root.size.y], "camera_height": camera.global_position.y, "painter_visible": painter.is_visible_in_tree(), "status": lesson.status.text}, "  ")); f.close()

func finish() -> void:
	var failed := checks.filter(func(c): return not c.ok)
	var f := FileAccess.open(out + "checks.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks": checks, "failures": failed, "observations": observations, "headset_tested": false, "learner_verified": false, "replay_before": replay_before, "artifact_only": artifact_only}, "  ")); f.close()
	print("FLOW_REVIEW ", checks.size(), " checks / ", failed.size(), " failures")
	quit(0 if failed.is_empty() else 1)
