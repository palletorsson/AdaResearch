extends SceneTree
const Preview = preload("res://commons/artifacts/concept_monitor/construction_preview.tscn")
const OUT := "res://doc/book/iterations/2026-10-04-construction-revealed/"
var checks: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, title: String) -> void:
	checks.append({"test": title, "passed": value})
	print("PASS " if value else "FAIL ", title)

func run() -> void:
	var preview: Node3D = Preview.instantiate()
	root.add_child(preview)
	root.size = Vector2i(1440, 1000)
	var monitor: Node3D = preview.get("monitor")
	monitor.set_process(false)
	monitor.set_physics_process(false)
	var stage: Node3D = monitor.get("stage")
	var camera: Camera3D = preview.get("camera")
	var screen: MeshInstance3D = monitor.get("screen")
	var feed: SubViewport = monitor.get("viewport")
	await physics_frame
	await physics_frame
	check(root.get_camera_3d() == camera, "Viewer uses outer camera, not private filmed camera")
	check(monitor.call("is_looking_at_screen", camera), "Looking at the screen qualifies")
	monitor.call("_physics_process", 0.05)
	monitor.call("_process", 0.1)
	check(not monitor.get("gaze_active") and float(stage.get("elapsed")) == 0.0, "Brief glance does not start construction")
	monitor.call("_physics_process", 0.2)
	monitor.call("_process", 0.1)
	check(monitor.get("gaze_active") and float(stage.get("elapsed")) > 0.0, "Dwell starts playback")
	var stopped: float = stage.get("elapsed")
	camera.look_at(Vector3(8, 1.7, 0))
	monitor.call("_physics_process", 0.1)
	monitor.call("_process", 5.0)
	check(not monitor.get("gaze_active") and float(stage.get("elapsed")) == stopped, "Looking away freezes timeline without catching up")
	check(feed.render_target_update_mode == SubViewport.UPDATE_DISABLED, "Unwatched feed stops rendering")
	camera.look_at(screen.global_position)
	monitor.call("_physics_process", 0.2)
	monitor.call("_process", 0.1)
	check(is_equal_approx(float(stage.get("elapsed")), stopped + 0.1), "Looking back resumes from the held moment")
	monitor.call("activate", "pause")
	stopped = stage.get("elapsed")
	camera.look_at(Vector3(8, 1.7, 0))
	monitor.call("_physics_process", 0.3)
	camera.look_at(screen.global_position)
	monitor.call("_physics_process", 0.3)
	monitor.call("_process", 0.5)
	check(not stage.get("running") and float(stage.get("elapsed")) == stopped, "Looking back respects manual pause")
	check(feed.render_target_update_mode == SubViewport.UPDATE_ONCE, "Manual changes get a frame even while paused")
	monitor.call("_process", 0.1)
	check(feed.render_target_update_mode == SubViewport.UPDATE_DISABLED, "Paused feed stops after its requested refresh")
	camera.look_at(Vector3(0, 3.2, 0))
	check(not monitor.call("is_looking_at_screen", camera), "Looking above the screen does not qualify")
	camera.position = Vector3(0, 1.72, -4)
	camera.look_at(screen.global_position)
	check(not monitor.call("is_looking_at_screen", camera), "Rear of monitor cannot trigger it")
	camera.position = Vector3(0, 1.72, 18)
	camera.look_at(screen.global_position)
	check(not monitor.call("is_looking_at_screen", camera), "Distant screen does not trigger it")
	camera.position = Vector3(3, 1.72, 4)
	camera.look_at(screen.global_position)
	check(monitor.call("is_looking_at_screen", camera), "Screen can be watched from an oblique angle")
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(8, 5, 0.15)
	collision.shape = shape
	wall.add_child(collision)
	preview.add_child(wall)
	wall.position = Vector3(0, 2, 2)
	await physics_frame
	await physics_frame
	check(not monitor.call("is_looking_at_screen", camera), "A solid wall blocks gaze activation")
	wall.queue_free()
	await physics_frame
	await physics_frame
	check(monitor.call("is_looking_at_screen", camera), "Removing obstruction allows viewing again")
	monitor.hide()
	check(not monitor.call("is_looking_at_screen", camera), "Hidden monitor cannot activate")
	monitor.show()
	monitor.rotation.y = 0.65
	monitor.position = Vector3(2, 0, -1)
	camera.global_position = screen.global_position + screen.global_basis.z * 4
	camera.look_at(screen.global_position)
	check(monitor.call("is_looking_at_screen", camera), "Moved and rotated monitors use their actual screen plane")
	var xr := XRCamera3D.new()
	preview.add_child(xr)
	xr.global_transform = camera.global_transform
	xr.make_current()
	check(root.get_camera_3d() == xr and monitor.call("is_looking_at_screen", xr), "Synthetic XR camera is selected and can trigger the screen")
	xr.rotate_y(PI * 0.5)
	check(not monitor.call("is_looking_at_screen", xr), "Synthetic headset turn leaves the screen")
	xr.queue_free()
	camera.make_current()
	monitor.call("activate", "pause")
	# Exercise the actual callbacks over frames as well as deterministic edge cases.
	monitor.set_process(true)
	monitor.set_physics_process(true)
	await create_timer(0.4).timeout
	stopped = stage.get("elapsed")
	check(monitor.get("gaze_active") and stopped > 0.0, "Live callbacks run while watched")
	camera.rotate_y(PI * 0.5)
	await create_timer(0.1).timeout
	stopped = stage.get("elapsed")
	await create_timer(0.25).timeout
	check(float(stage.get("elapsed")) == stopped, "Live callbacks freeze during a sustained look away")
	if DisplayServer.get_name() != "headless":
		var held_pixels := feed.get_texture().get_image().get_data()
		await create_timer(0.15).timeout
		check(held_pixels == feed.get_texture().get_image().get_data(), "Rendered screen holds exactly the same pixels while unwatched")
		monitor.rotation = Vector3.ZERO
		monitor.position = Vector3.ZERO
		camera.position = Vector3(0, 1.62, 4.4)
		camera.look_at(screen.global_position)
		stage.call("show_progress", 2, 0.6)
		await create_timer(0.35).timeout
		await RenderingServer.frame_post_draw
		check(held_pixels != feed.get_texture().get_image().get_data(), "Rendered feed refreshes after returning to look")
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "gaze-monitor.png"))
	var passed := true
	for item in checks: passed = passed and bool(item.passed)
	var file := FileAccess.open(OUT + "gaze-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "checks": checks,
		"scope": "Desktop runtime and synthetic XRCamera3D; physical headset not tested."}, "\t"))
	file.close()
	print("GAZE MONITOR ", "PASS" if passed else "FAIL")
	quit(0 if passed else 1)
