extends SceneTree
const Preview = preload("res://commons/artifacts/concept_monitor/construction_preview.tscn")
const PointerEvent = preload("res://addons/godot-xr-tools/events/pointer_event.gd")
const OUT := "res://doc/book/iterations/2026-10-04-construction-revealed/"
var failures: Array[String] = []
var checks: Array[Dictionary] = []
var normal_error := 0.0

func _initialize() -> void:
	call_deferred("run")

func check(passed: bool, title: String) -> void:
	checks.append({"test": title, "passed": passed})
	if not passed: failures.append(title)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "frames/"))
	var preview: Node3D = Preview.instantiate()
	root.add_child(preview)
	root.size = Vector2i(1440, 1000)
	var monitor: Node3D = preview.get("monitor")
	monitor.set_process(false)
	var stage: Node3D = monitor.get("stage")
	var viewport: SubViewport = monitor.get("viewport")
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await physics_frame
	var source: Node3D = stage.get("source")
	var original: ArrayMesh = source.get("column_mesh")
	check(original.get_surface_count() == 9, "Uses nine surfaces from the existing generator")
	check(int(stage.get("total_triangles")) == int(source.get("triangle_count")), "Triangle count agrees with the source")
	stage.call("show_progress", 2, 1.0)
	var growing: MeshInstance3D = stage.get("growing")
	var rebuilt := growing.mesh as ArrayMesh
	var exact := rebuilt.get_surface_count() == original.get_surface_count()
	for i in range(original.get_surface_count()):
		exact = exact and rebuilt.surface_get_arrays(i)[Mesh.ARRAY_VERTEX] == original.surface_get_arrays(i)[Mesh.ARRAY_VERTEX]
		var original_normals: PackedVector3Array = original.surface_get_arrays(i)[Mesh.ARRAY_NORMAL]
		var revealed_normals: PackedVector3Array = rebuilt.surface_get_arrays(i)[Mesh.ARRAY_NORMAL]
		for j in range(original_normals.size()): normal_error = maxf(normal_error, original_normals[j].distance_to(revealed_normals[j]))
	check(exact, "Completed reveal preserves source vertices exactly")
	check(normal_error < 0.001, "Re-uploaded normals stay within 0.001 packing tolerance")
	stage.call("show_progress", 2, 0.32)
	check(int(stage.get("shown_triangles")) > 0 and int(stage.get("shown_triangles")) < int(stage.get("total_triangles")), "Face growth exposes a proper subset")
	stage.call("show_progress", 3, 0.5)
	var parts: Array = stage.get("parts")
	check(parts.size() == 9 and parts[-1].position.y > parts[0].position.y, "Sections separate spatially")
	stage.call("show_progress", 4, 1.0)
	var copies: Array = stage.get("copies")
	var shared := copies.size() == 6
	var places := {}
	for copy in copies:
		shared = shared and copy.visible and copy.mesh == original
		places[copy.position] = true
	check(shared and places.size() == 6, "Array shares the source mesh at six distinct positions")
	stage.call("show_progress", 5, 1.0)
	var beams: Array = stage.get("beams")
	check(beams.size() == 2 and beams[0].visible and is_equal_approx(beams[0].scale.x, 1.0), "Colonnade has two completed beams")
	var camera: Camera3D = stage.get("camera")
	var before := camera.position
	stage.call("orbit", 0.3)
	check(camera.position.distance_to(before) > 0.5, "Camera can orbit the three-dimensional construction")
	var button: Node3D = monitor.get("buttons")["pause"]
	PointerEvent.pressed(preview, button, button.global_position)
	PointerEvent.released(preview, button, button.global_position)
	var stopped: float = stage.get("elapsed")
	stage.call("advance", 1.0)
	check(not bool(stage.get("running")) and is_equal_approx(stopped, float(stage.get("elapsed"))), "Pause freezes construction and camera time")
	monitor.call("activate", "step")
	check(int(stage.get("phase")) == 0 and not bool(stage.get("running")), "Step wraps to the next operation while paused")
	for kind in range(5):
		stage.call("build_profile", kind)
		await process_frame
		stage.call("show_progress", 2, 1.0)
		var model: Node3D = stage.get("source")
		var model_mesh: ArrayMesh = model.get("column_mesh")
		var revealed: MeshInstance3D = stage.get("growing")
		check(revealed.mesh.get_surface_count() == model_mesh.get_surface_count(), "Profile %d reveals all source surfaces" % kind)
	stage.call("build_profile", 0)
	stage.set("running", false)
	stage.set("camera_angle", 0.40)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if DisplayServer.get_name() != "headless":
		for phase in range(6):
			stage.call("show_progress", phase, 0.85)
			await settle()
			viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "phase-%d.png" % phase))
		stage.call("show_progress", 5, 1.0)
		monitor.get("pause_label").text = "PLAY"
		await settle()
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "monitor.png"))
		stage.set("running", true)
		for frame in range(120):
			var phase := frame / 20
			var fraction := float(frame % 20) / 19.0
			stage.set("camera_angle", 0.40 + float(frame) * 0.003)
			stage.call("show_progress", phase, fraction)
			await settle()
			viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "frames/%03d.png" % frame))
	var report := {"passed": failures.is_empty(), "failures": failures, "checks": checks, "max_normal_error": normal_error,
		"source": "commons/artifacts/resolution_colonnade/resolution_totem.gd",
		"scope": "Actual source mesh reused and compared; separate filmed study. No changes to museum map or source generator. Headset test not performed."}
	var file := FileAccess.open(OUT + "report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("CONSTRUCTION MONITOR ", "PASS" if failures.is_empty() else "FAIL", failures)
	quit(0 if failures.is_empty() else 1)

func settle() -> void:
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
