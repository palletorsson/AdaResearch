extends SceneTree
const PREVIEW_PATH := "res://commons/artifacts/concept_monitor/trace_sampling_preview.tscn"
const Record = preload("res://commons/artifacts/concept_monitor/trace_sampling_record.gd")
const OUT := "res://doc/book/iterations/2026-10-04-trace-sampling-monitor/"
var checks: Array[Dictionary] = []
var preview: Node3D
var monitor: Node3D
var dot: Node3D
var pen: Node3D
var stage: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(passed: bool, title: String) -> void:
	checks.append({"test": title, "passed": passed})
	print("PASS " if passed else "FAIL ", title)

func gesture(t: float) -> Vector3:
	return Vector3(-1.8 + 0.7 * t, 1.2 + 0.24 * sin(t * TAU * 2), 0.7 + 0.2 * sin(t * TAU))

func record_fixture() -> void:
	pen.set("desktop_held", false)
	monitor.call("observe", 0.01)
	pen.global_position = gesture(0)
	dot.call("clear_trail")
	pen.set("desktop_held", true)
	monitor.call("observe", 0.01)
	for i in range(1, 241):
		pen.global_position = gesture(float(i) / 240.0)
		dot.call("_process", 0.025)
		monitor.call("observe", 0.025)
	pen.set("desktop_held", false)
	monitor.call("observe", 0.01)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size = Vector2i(1440, 1000)
	preview = load(PREVIEW_PATH).instantiate()
	root.add_child(preview)
	preview.set_process(false)
	monitor = preview.get("monitor")
	monitor.set_process(false)
	monitor.set_physics_process(false)
	dot = preview.get("dot")
	dot.set_process(false)
	dot.set_physics_process(false)
	pen = preview.get("pen")
	stage = monitor.get("stage")
	await physics_frame
	await physics_frame
	monitor.call("discover_sources")
	check(monitor.get("sources").size() == 1, "Finds the existing DrawDot scene")
	monitor.call("observe", 0.1)
	check(stage.record.positions.is_empty(), "Idle pen does not manufacture a gesture")
	var trace_data := root.get_node("TraceData")
	var saved_before: Array = trace_data.get("saved_traces").duplicate(true)
	for mode in range(2):
		for lane in range(3):
			dot.set("min_segment_distance", Record.GRAINS[lane] if mode == 0 else 0.005)
			dot.set("resolution_mm", 0.0 if mode == 0 else Record.GRIDS[lane] * 1000.0)
			record_fixture()
			var original := PackedVector3Array(dot.get("_trail_points"))
			var sampled: PackedVector3Array = stage.record.samples(100, mode, lane)
			var equal := original.size() == sampled.size()
			for i in range(mini(original.size(), sampled.size())):
				equal = equal and original[i].is_equal_approx(sampled[i])
			check(equal, "Mode %d lane %d agrees with actual DrawDot pipeline (%d points)" % [mode, lane, original.size()])
	check(trace_data.get("saved_traces") == saved_before, "Observer never writes the saved TraceData")
	check(stage.record.positions.size() == 241 and is_equal_approx(stage.record.elapsed, 6.0), "Record preserves all observed positions and timing")
	var raw: PackedVector3Array = stage.record.positions.duplicate()
	var real_trace: Array = dot.get("_trail_points").duplicate()
	var grain_before: float = dot.get("min_segment_distance")
	var grid_before: float = dot.get("resolution_mm")
	monitor.call("activate", "route")
	monitor.call("activate", "replay")
	monitor.call("activate", "step")
	check(stage.record.positions == raw and dot.get("_trail_points") == real_trace, "Replay, mode and step leave original records intact")
	check(float(dot.get("min_segment_distance")) == grain_before and float(dot.get("resolution_mm")) == grid_before, "Monitor controls never change the real pen settings")
	check(not stage.get("running") and float(stage.get("playhead")) > 0.0, "Step advances one observed position and pauses")
	# Compare world and rotated-board shaping to the artifact's own implementation.
	var board := Node3D.new()
	var board_script := GDScript.new()
	board_script.source_code = "extends Node3D\nfunc write_surfaces() -> Array:\n\treturn [{\"origin\":Vector3(0,1,0), \"normal\":Vector3.RIGHT, \"u\":Vector3.BACK, \"v\":Vector3.UP, \"half_w\":0.5, \"half_h\":0.5}]\n"
	board_script.reload()
	board.set_script(board_script)
	root.add_child(board)
	board.add_to_group("ada_writable_board")
	var test_position := Vector3(0.01, 1.137, 0.217)
	var surface: Dictionary = dot.call("_nearest_board_face", test_position)
	check(not surface.is_empty(), "Board fixture is discovered through DrawDot's surface contract")
	check(Record.shape_sample(test_position, 0.08, surface).is_equal_approx(dot.call("_shape_sample", test_position)), "Rotated-board projection and snapping agree with DrawDot")
	board.queue_free()
	await process_frame
	# Pauses in hand movement do not manufacture accepted samples.
	var still := Record.new()
	still.begin(Vector3.ONE, {}, 0.005, "still")
	for i in range(10): still.append(Vector3.ONE, 0.02, {})
	check(still.samples(10, 0, 0).is_empty(), "Stationary hand adds no retained points")
	for i in range(Record.LIMIT + 20): still.append(Vector3(float(i), 0, 0), 0.01, {})
	check(still.positions.size() == Record.LIMIT and still.times.size() == Record.LIMIT, "Private observation has a bounded, aligned buffer")
	# A fresh held gesture starts a new monitor record, not a bridge through space.
	pen.global_position = Vector3(4, 1, 0)
	pen.set("desktop_held", true)
	monitor.call("observe", 0.1)
	check(stage.record.positions.size() == 1, "Next pickup starts a separate comparison")
	pen.set("desktop_held", false)
	monitor.call("observe", 0.1)
	dot.set("min_segment_distance", 0.005)
	dot.set("resolution_mm", 0)
	record_fixture()
	stage.record.source_name = "TEST GESTURE"
	var count0: int = stage.record.samples(100, 0, 0).size()
	var count1: int = stage.record.samples(100, 0, 1).size()
	var count2: int = stage.record.samples(100, 0, 2).size()
	check(count0 > count1 and count1 > count2, "One gesture visibly separates fine, medium and coarse sampling")
	if DisplayServer.get_name() != "headless":
		var feed: SubViewport = monitor.get("viewport")
		for mode in range(2):
			stage.set("mode", mode)
			stage.set("playhead", stage.record.elapsed)
			stage.call("refresh")
			await settle(feed)
			feed.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + ("grain.png" if mode == 0 else "grid.png")))
		stage.set("mode", 0)
		stage.call("refresh")
		await settle(feed)
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "preview.png"))
		await museum_capture()
	var passed := true
	for item in checks: passed = passed and bool(item.passed)
	var report := {"passed": passed, "checks": checks, "spacing_counts": [count0, count1, count2],
		"capture_provenance": "Known 3D test trajectory driven through the actual DrawDot pen; not a human headset recording."}
	var file := FileAccess.open(OUT + "report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("TRACE SAMPLING ", "PASS" if passed else "FAIL")
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
	museum.set("start_map", "Point_Trace")
	museum.set("plan_file", folder + "plan.json")
	root.add_child(museum)
	var started := Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec() - started < 65000: await process_frame
	museum.set("_lazy_pending", 0)
	museum.set_process(false)
	museum.set_physics_process(false)
	museum.call("flush_stamps")
	await create_timer(1.0).timeout
	var hall: Node3D
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map", "")) == "Point_Trace": hall = child
	check(hall != null, "Actual Point Trace museum hall loads")
	if hall == null: return
	var placed: Node3D
	for child in hall.find_children("*", "Node3D", true, false):
		var script: Script = child.get_script()
		if script != null and script.resource_path.ends_with("/trace_sampling_monitor.gd"): placed = child
	check(placed != null, "Registered monitor appears from the actual map token")
	if placed == null: return
	placed.call("discover_sources")
	check(placed.get("sources").size() == 3, "Monitor discovers the three existing hall pens")
	placed.set_process(false)
	placed.set_physics_process(false)
	var filmed: Node3D = placed.get("stage")
	filmed.set("record", stage.get("record"))
	filmed.set("playhead", stage.record.elapsed)
	filmed.set("running", false)
	filmed.call("refresh")
	var eye := Camera3D.new()
	root.add_child(eye)
	var target: Vector3 = placed.get("screen").global_position
	eye.global_position = target + placed.global_basis.z * 3.7 + placed.global_basis.x * 2.0
	eye.look_at(target)
	eye.fov = 67
	eye.make_current()
	await physics_frame
	check(placed.call("is_looking_at_screen", eye), "Monitor screen has an unobstructed viewing position in the hall")
	for key in ["pause", "replay", "step", "route"]:
		var button: Node3D = placed.get("buttons")[key]
		var from := button.global_position + placed.global_basis.z
		var ray := PhysicsRayQueryParameters3D.create(from, button.global_position - placed.global_basis.z * 0.05, 1 | (1 << 20))
		ray.collide_with_areas = true
		var hit := placed.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and hit.collider == button, "Hall control is reachable: " + key)
	await settle(placed.get("viewport"))
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "museum.png"))
	var locations := {"monitor": str(placed.global_position), "pens": []}
	for source in placed.get("sources"): locations.pens.append(str(source.global_position))
	var file := FileAccess.open(OUT + "placement.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(locations, "\t"))
	file.close()
