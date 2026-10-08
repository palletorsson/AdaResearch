extends SceneTree
## Supplied hand/head/body transforms in real scenes, not human tracking evidence.
var checks: Array[Dictionary] = []
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(label: String, passed: bool) -> void:
	checks.append({"check": label, "passed": passed})
	if not passed: failures.append(label)
	print(("PASS: " if passed else "FAIL: ") + label)

func drive_pen(pen: Node3D, at: Vector3) -> void:
	pen._grab_point.global_position += at - pen._draw_sphere.global_position
	pen._process(0.2)

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	for scene_name in ["draw_dot", "draw_stick"]:
		var pen = load("res://commons/primitives/point/" + scene_name + ".tscn").instantiate()
		world.add_child(pen)
		pen.set_process(false)
		pen.record_only_when_grabbed = false
		pen.data_table_update_interval = 0.0
		drive_pen(pen, Vector3(0.006, 0, 0))
		drive_pen(pen, Vector3(0.012, 0, 0))
		check(scene_name + ": distinct 6 mm positions stay distinct in metre table", pen._data_table_label.text.contains("0.006") and pen._data_table_label.text.contains("0.012"))
		check(scene_name + ": table states frame and units", pen._data_table_label.text.contains("WORLD POSITIONS (m)"))
		var count: int = pen._trail_points.size()
		pen._process(3.0)
		check(scene_name + ": pause adds no position", pen._trail_points.size() == count)
		pen._on_grab_point_dropped(pen._grab_point)
		pen.record_only_when_grabbed = true
		pen._process(0.2)
		check(scene_name + ": released table remains readable", pen._data_table_label.visible)
		pen.clear_trail()
		check(scene_name + ": clear hides obsolete data", not pen._data_table_label.visible)
		pen.record_only_when_grabbed = false
		pen.apply_grid_config({"resolution": "80"})
		drive_pen(pen, Vector3(0.081, 0, 0))
		drive_pen(pen, Vector3(0.092, 0, 0))
		check(scene_name + ": coarse grid still merges qualifying movements", pen._trail_points.size() == 1)
		pen.auto_clear_on_drop = true
		pen._on_grab_point_dropped(pen._grab_point)
		check(scene_name + ": configured auto-clear leaves no stale table", pen._trail_points.is_empty() and not pen._data_table_label.visible)
		pen.queue_free()
	await process_frame
	# Desktop selection must follow the visitor camera, not a hidden staging rig.
	var staging := XROrigin3D.new()
	world.add_child(staging)
	var walker := CharacterBody3D.new()
	walker.add_to_group("em_walker")
	world.add_child(walker)
	var view := Camera3D.new()
	walker.add_child(view)
	view.make_current()
	var recorder = load("res://commons/primitives/point/player_trace.tscn").instantiate()
	world.add_child(recorder)
	recorder.set_process(false)
	recorder.apply_grid_config({"seam_grid": "1.0", "show_discarded": "1"})
	check("desktop recorder chooses active walker over staging rig", recorder._xr_origin == walker)
	recorder.clear_trail()
	walker.position.x = 0.1
	recorder._process(0.1)
	walker.position.x = 0.2
	recorder._process(0.1)
	check("fine reference moves while one-metre address holds", recorder._truth_points.size() == 2 and recorder.get_point_count() == 1)
	walker.position.x = 0.6
	recorder._process(0.1)
	check("crossing rounding boundary adds next metre node", recorder.get_point_count() == 2 and is_equal_approx(recorder._trail_points[-1].x, 1.0))
	# Real XROrigin/XRCamera classes with supplied transforms: physical stepping
	# and leaning must be observable even though the rig origin remains fixed.
	view.clear_current(false)
	var rig := XROrigin3D.new()
	world.add_child(rig)
	rig.position = Vector3(4, 2, 3)
	var head := XRCamera3D.new()
	head.name = "XRCamera3D"
	rig.add_child(head)
	head.position = Vector3(0, 1.7, 0)
	head.make_current()
	staging.queue_free()
	await process_frame
	recorder._process(0.6)
	check("camera switch selects live XR rig", recorder._xr_origin == rig)
	check("switch clears old coarse and fine paths", recorder.get_point_count() == 0 and recorder._truth_points.size() <= 1)
	check("switch resets old quantization statistics", is_zero_approx(recorder.space_discard_max()))
	head.position.x = 0.2
	recorder._process(0.1)
	check("physical headset movement changes sample with fixed origin", recorder.get_point_count() == 1 and recorder._tracked_position().is_equal_approx(Vector3(4.2, 2, 3)))
	check("reference uses rig floor height plus display offset", is_equal_approx(recorder._truth_points[-1].y, 2.05))
	var previous: int = recorder._truth_points.size()
	head.position.y = 1.1
	recorder._process(0.1)
	check("crouching alone does not invent a floor path", recorder._truth_points.size() == previous)
	head.position.x = 0.7
	recorder._process(0.1)
	check("room-scale crossing reaches next coarse node", recorder._trail_points[-1].is_equal_approx(Vector3(5, 2.05, 3)))
	rig.position.x += 1.0
	recorder._process(0.1)
	check("rig locomotion and physical offset combine", recorder._tracked_position().is_equal_approx(Vector3(5.7, 2, 3)))
	view.make_current()
	recorder._process(0.6)
	check("late desktop camera replaces cached XR source", recorder._xr_origin == walker)
	check("return to desktop clears old XR path", recorder.get_point_count() == 0)
	# Explicit non-XR targets retain their full supplied position.
	recorder._xr_origin = walker
	check("explicit plain body retains its original position contract", recorder._tracked_position().is_equal_approx(walker.global_position))
	var out := "res://ada_run/trace_grid_discovery.json"
	var file := FileAccess.open(out, FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Actual scenes with supplied transforms and camera selection; headset input, room access and reading distance remain unverified."}, "  "))
	print("REPORT: " + out)
	quit(0 if failures.is_empty() else 1)
