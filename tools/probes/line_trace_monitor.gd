extends SceneTree
## Exercises the new artifact only. Optionally films it in an unchanged museum hall.
const Monitor = preload("res://commons/artifacts/concept_monitor/concept_monitor.tscn")
const PointerEvent = preload("res://addons/godot-xr-tools/events/pointer_event.gd")
var failures: Array[String] = []
var report := {"checks": [], "scope": "Godot desktop runtime and synthetic XR pointer events; no headset acceptance."}
var out := "res://doc/book/iterations/2026-10-04-line-trace-monitor/"

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, title: String) -> void:
	report.checks.append({"test": title, "passed": condition})
	if not condition: failures.append(title)

func press(monitor: Node3D, key: String, pointer: Node3D) -> void:
	var button: Node3D = monitor.get("buttons")[key]
	var from := button.global_position + monitor.global_basis.z * 1.0
	var query := PhysicsRayQueryParameters3D.create(from, button.global_position - monitor.global_basis.z * 0.1, 1 | (1 << 20))
	query.collide_with_areas = true
	var hit := monitor.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and hit.collider == button, key + " control reachable by front ray")
	PointerEvent.pressed(pointer, button, button.global_position)
	PointerEvent.released(pointer, button, button.global_position)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var host := Node3D.new()
	root.add_child(host)
	var monitor: Node3D = Monitor.instantiate()
	host.add_child(monitor)
	monitor.set_process(false)
	var stage: Node3D = monitor.get("stage")
	var viewport: SubViewport = monitor.get("viewport")
	await process_frame
	await physics_frame
	check(viewport.find_world_3d().scenario != host.get_world_3d().scenario, "Illustration has a separate rendering world")
	check(viewport.find_world_3d().space != host.get_world_3d().space, "Illustration has a separate physics world")
	var pointer := Node3D.new()
	host.add_child(pointer)
	var lengths: Array[float] = []
	for kind in range(3):
		stage.call("set_route", kind)
		stage.call("show_sample", 32)
		var points: Array = stage.get("points")
		check(points[0].is_equal_approx(Vector3(-2, -0.16, 0)) and points[-1].is_equal_approx(Vector3(2, -0.16, 0)), "Route %d keeps endpoints" % kind)
		var length: float = stage.call("retained_length")
		lengths.append(length)
		check(length > 4.0, "Route %d trace exceeds straight distance" % kind)
	report["completed_trace_metres"] = lengths
	stage.call("set_route", 0)
	stage.call("advance", 0.50)
	check(int(stage.get("sample_index")) == 3, "Elapsed time retains three further positions")
	press(monitor, "pause", pointer)
	stage.call("advance", 2.0)
	check(not bool(stage.get("running")) and int(stage.get("sample_index")) == 3, "Pause pointer freezes the record")
	press(monitor, "step", pointer)
	check(int(stage.get("sample_index")) == 4 and not bool(stage.get("running")), "Step pointer advances exactly one sample")
	press(monitor, "replay", pointer)
	check(int(stage.get("sample_index")) == 0 and not bool(stage.get("running")), "Replay resets only this illustration and preserves pause")
	press(monitor, "route", pointer)
	check(int(stage.get("route")) == 1 and int(stage.get("sample_index")) == 0, "Next-route pointer changes path and resets its record")
	press(monitor, "pause", pointer)
	check(bool(stage.get("running")), "Play pointer resumes")
	var child_count := stage.get_child_count()
	for i in range(40):
		stage.call("set_route", i % 3)
		stage.call("show_sample", 32)
		stage.call("advance", 3.0)
	check(stage.get_child_count() == child_count, "Repeated journeys reuse bounded geometry")
	if DisplayServer.get_name() != "headless":
		await capture(monitor, stage, viewport)
	report["passed"] = failures.is_empty()
	report["failures"] = failures
	var file := FileAccess.open(out + "report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("LINE TRACE MONITOR ", "PASS" if failures.is_empty() else "FAIL", " ", failures)
	quit(0 if failures.is_empty() else 1)

func settle(viewport: SubViewport) -> void:
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw

func capture(monitor: Node3D, stage: Node3D, viewport: SubViewport) -> void:
	root.size = Vector2i(1440, 1000)
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
		var folder: String = spec.run
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
		var walker_camera: Camera3D = museum.get("_cam")
		if walker_camera != null:
			for timer in walker_camera.find_children("*", "Timer", true, false): timer.stop()
		var hall: Node3D
		for child in museum.get_children():
			if child is Node3D and str(child.get_meta("em_map", "")) == "Point_Trace": hall = child
		check(hall != null, "Real Point Trace museum hall loads")
		if hall == null: return
		var origin := hall.global_position + Vector3(0, 0, 4)
		monitor.global_position = origin + Vector3(12.2, 0, 8.9)
		monitor.rotation.y = PI
		var camera := Camera3D.new()
		root.add_child(camera)
		camera.global_position = origin + Vector3(10.3, 1.7, 5.0)
		camera.look_at(monitor.global_position + Vector3(0, 1.6, 0))
		camera.fov = 68
		camera.make_current()
		stage.set("running", false)
		stage.call("set_route", 0)
		stage.call("show_sample", 32)
		await settle(viewport)
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		check(root.get_camera_3d() == camera, "Museum capture uses the inspection camera")
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(out + "museum.png"))
		camera.global_position = origin + Vector3(12.2, 1.68, 5.4)
		camera.look_at(monitor.global_position + Vector3(0, 1.54, 0))
		camera.fov = 54
		camera.make_current()
		await settle(viewport)
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(out + "monitor.png"))
		monitor.set_process(true)
		monitor.set("force_active", false)
		await create_timer(0.3).timeout
		check(viewport.render_target_update_mode != SubViewport.UPDATE_DISABLED, "Nearby visible monitor updates")
		camera.global_position += Vector3(0, 0, -40)
		await create_timer(0.3).timeout
		check(viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "Distant monitor suspends rendering")
		monitor.set_process(false)
		museum.queue_free()
		await process_frame
	stage.set("running", false)
	stage.call("set_route", 0)
	stage.call("show_sample", 32)
	await settle(viewport)
	var filmed_camera: Camera3D = viewport.get_camera_3d()
	report["feed_environment"] = {"camera": str(filmed_camera.get_path()), "color": str(filmed_camera.environment.background_color), "mode": filmed_camera.environment.background_mode, "world_color": str(viewport.find_world_3d().environment.background_color)}
	viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path(out + "illustration.png"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out + "frames/"))
	var frame := 0
	for route in range(3):
		stage.call("set_route", route)
		stage.set("running", true)
		for sample in range(33):
			stage.call("show_sample", sample)
			await settle(viewport)
			viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path(out + "frames/%03d.png" % frame))
			frame += 1
	report["rendered_animation_frames"] = frame
