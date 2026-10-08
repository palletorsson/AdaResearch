extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-04-triangle-reveal-monitor/"
var checks: Array[Dictionary] = []
var preview: Node3D
var monitor: Node3D
var stage: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(passed: bool, title: String) -> void:
	checks.append({"test": title, "passed": passed})
	print("PASS " if passed else "FAIL ", title)

func run() -> void:
	root.size = Vector2i(1440, 1000)
	preview = load("res://commons/artifacts/concept_monitor/triangle_reveal_preview.tscn").instantiate()
	root.add_child(preview)
	monitor = preview.get("monitor")
	stage = monitor.get("stage")
	monitor.set_process(false)
	monitor.set_physics_process(false)
	var source: Node3D = preview.get("drawing")
	await physics_frame
	await physics_frame
	check(monitor.get("source") == source, "Monitor discovers the real drawing tool")
	check(stage.record.points.size() == 3 and stage.faces.size() == 1, "Triangle supplies three corners and one six-vertex face")
	var points: Array = source.get("placed_points").duplicate()
	var state: Dictionary = source.call("get_experiment_state")
	for key in ["route", "step", "replay", "pause", "pause"]: monitor.call("activate", key)
	check(source.get("placed_points") == points and source.call("get_experiment_state") == state, "All monitor controls leave the drawing unchanged")
	stage.set("camera_angle", 0.0)
	stage.set("running", true)
	monitor.call("_physics_process", 0.2)
	check(monitor.get("gaze_active"), "Looking at the physical screen starts the feed")
	var before: float = stage.playhead
	monitor.call("_process", 0.1)
	check(stage.playhead > before, "Visible film advances")
	var eye: Camera3D = preview.get("camera")
	eye.rotation.y += PI
	monitor.call("_physics_process", 0.2)
	before = stage.playhead
	monitor.call("_process", 0.1)
	check(not monitor.get("gaze_active") and stage.playhead == before, "Looking away freezes the construction")
	eye.look_at(Vector3(0, 1.5, 0))
	monitor.call("activate", "pause")
	monitor.call("_physics_process", 0.2)
	monitor.call("_process", 0.1)
	check(stage.playhead == before, "Returning gaze respects manual pause")
	preview.call("set_example", 3)
	check(not stage.record.closed and stage.faces.is_empty() and stage.boundaries.size() == 3, "Open four-corner drawing stays open with three edges")
	preview.call("set_example", 2)
	check(stage.faces.size() == 4, "Six-corner drawing preserves the source's four fan triangles")
	stage.set("playhead", 11.0)
	stage.call("refresh")
	check(stage.faces[0].position.length() > 0.1, "Face separation takes place in the filmed 3D world")
	stage.set("playhead", 16.0)
	stage.call("refresh")
	var joined := true
	for face in stage.faces: joined = joined and face.position.is_zero_approx()
	check(joined, "Separated faces return exactly to their copied positions")
	var feed: SubViewport = monitor.get("viewport")
	if DisplayServer.get_name() != "headless":
		for item in [[0,1.7,"positions"],[0,4.3,"boundary"],[0,7.5,"triangle"],[1,7.5,"fan"],[2,11.0,"apart"],[2,16.0,"together"],[3,7.5,"open"]]:
			preview.call("set_example", item[0])
			stage.set("playhead", item[1])
			stage.call("refresh")
			await settle(feed)
			feed.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + item[2] + ".png"))
		preview.call("set_example", 1)
		stage.set("playhead", 10.5)
		stage.call("refresh")
		await settle(feed)
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "preview.png"))
		# A short rendered loop is evidence of the real 3D stage, not a mock-up.
		for i in range(34):
			stage.set("playhead", float(i) * 0.5)
			stage.call("refresh")
			await settle(feed)
			feed.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "frame-%02d.png" % i))
		await museum_capture()
	var passed := true
	for item in checks: passed = passed and bool(item.passed)
	var file := FileAccess.open(OUT + "report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "checks": checks}, "\t"))
	file.close()
	print("TRIANGLE REVEAL ", "PASS" if passed else "FAIL")
	quit(0 if passed else 1)

func settle(feed: SubViewport) -> void:
	feed.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw

func museum_capture() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty(): return
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var folder: String = spec.run
	preview.hide()
	for child in preview.get_children():
		if child is Label: child.hide()
	var museum: Node3D = load(folder + "museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL", folder + "control.json")
	museum.set("_hand_path", folder + "necklace_hand.json")
	museum.set("_overrides_path", folder + "em_overrides.json")
	museum.set("start_chapter", "primitives")
	museum.set("start_map", "Point_Triangle_Context")
	museum.set("plan_file", folder + "plan.json")
	root.add_child(museum)
	var started := Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec() - started < 65000: await process_frame
	museum.set("_lazy_pending", 0)
	museum.set_process(false)
	museum.set_physics_process(false)
	museum.call("flush_stamps")
	await create_timer(1.5).timeout
	var hall: Node3D
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map", "")) == "Point_Triangle_Context": hall = child
	check(hall != null, "Actual Triangle museum hall loads")
	if hall == null: return
	var placed: Node3D
	for child in hall.find_children("*", "Node3D", true, false):
		var script: Script = child.get_script()
		if script != null and script.resource_path.ends_with("/triangle_reveal_monitor.gd"): placed = child
	check(placed != null, "Registered monitor appears in the actual hall")
	if placed == null: return
	placed.set_process(false)
	placed.set_physics_process(false)
	placed.call("discover_source")
	placed.call("observe", 0.25)
	check(placed.get("source") != null, "Hall monitor finds the existing Triangle creator")
	var filmed: Node3D = placed.get("stage")
	check(filmed.record.points.size() >= 3 and filmed.faces.size() >= 1, "Hall's actual drawing supplies the filmed surface")
	filmed.set("playhead", 7.5)
	filmed.set("running", false)
	filmed.call("refresh")
	var eye := Camera3D.new()
	root.add_child(eye)
	var target: Vector3 = placed.get("screen").global_position
	eye.global_position = target + placed.global_basis.z * 4.0 - placed.global_basis.x * 0.8
	eye.look_at(target)
	eye.fov = 68
	eye.make_current()
	await physics_frame
	check(placed.call("is_looking_at_screen", eye), "Screen has an unobstructed viewing position inside the museum")
	for key in ["pause", "replay", "step", "route"]:
		var button: Node3D = placed.get("buttons")[key]
		var from := button.global_position + placed.global_basis.z
		var ray := PhysicsRayQueryParameters3D.create(from, button.global_position - placed.global_basis.z * 0.05, 1 | (1 << 20))
		ray.collide_with_areas = true
		var hit := placed.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and hit.collider == button, "Hall control reachable: " + key)
	await settle(placed.get("viewport"))
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "museum.png"))
	placed.get("viewport").get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "museum-feed.png"))
	var file := FileAccess.open(OUT + "placement.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"monitor": str(placed.global_position), "source": str(placed.get("source").global_position), "record_points": filmed.record.points.size()}, "\t"))
	file.close()
