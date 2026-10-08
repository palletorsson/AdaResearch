extends SceneTree
const PointerEvent = preload("res://addons/godot-xr-tools/events/pointer_event.gd")
var checks: Array[Dictionary] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks.append({"passed":ok,"test":message})
	print("PASS " if ok else "FAIL ", message)

func run() -> void:
	create_timer(150).timeout.connect(func(): quit(99))
	root.size = Vector2i(1280,900)
	var catalog: Array = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/spine_films/catalog.json"))
	var results: Array = []
	for item: Dictionary in catalog:
		if item.get("collection", "") != "foundation": continue
		checks = []
		var monitor: Node3D = load(item.monitor_scene).instantiate()
		root.add_child(monitor)
		monitor.set_process(false)
		monitor.set_physics_process(false)
		var stage: Node3D = monitor.get("stage")
		var eye := Camera3D.new()
		root.add_child(eye)
		eye.position = Vector3(0,1.62,4.4)
		eye.look_at(Vector3(0,1.5,0))
		eye.current = true
		await physics_frame
		await physics_frame
		check(stage.get_viewport() != root and stage.get_world_3d() != monitor.get_world_3d(), "Private illustration world")
		check(monitor.call("is_looking_at_screen",eye), "Front viewing position qualifies")
		monitor.call("_physics_process",.2)
		monitor.call("_process",.1)
		check(float(stage.get("playhead")) > 0, "Gaze advances demo")
		var frozen: float = stage.get("playhead")
		eye.rotate_y(PI)
		monitor.call("_physics_process",.2)
		monitor.call("_process",1.0)
		check(float(stage.get("playhead")) == frozen, "Look away holds demo")
		eye.look_at(Vector3(0,1.72,0))
		var controls: Array = stage.call("experiment_controls")
		check(controls.size() >= 2 and controls.size() <= 4, "Focused experiment controls")
		var actions: Array = []
		for control: Dictionary in controls:
			monitor.call("activate","replay")
			var key := "try_"+str(control.key)
			var area: Node3D = monitor.get("buttons")[key]
			var query := PhysicsRayQueryParameters3D.create(eye.position,area.global_position,1|(1<<20))
			query.collide_with_areas = true
			var hit := monitor.get_world_3d().direct_space_state.intersect_ray(query)
			check(not hit.is_empty() and hit.collider == area, "Pointer reaches "+key)
			PointerEvent.pressed(eye,area,area.global_position)
			await process_frame
			PointerEvent.released(eye,area,area.global_position)
			var snapshot: Dictionary = stage.call("experiment_snapshot")
			check(bool(monitor.get("_trying")) and not bool(stage.get("running")), "Actual button enters held experiment: "+key)
			monitor.call("_physics_process",.2)
			monitor.call("_process",1.0)
			stage.call("refresh")
			check(snapshot == stage.call("experiment_snapshot"), "Gaze and redraw retain learner state: "+key)
			monitor.call("activate","route")
			check(snapshot == stage.call("experiment_snapshot"), "Turning camera retains learner state: "+key)
			check(monitor.get("pause_label").text == "DEMO", "Clear return-to-demo label: "+key)
			actions.append({"key":key,"snapshot":snapshot})
			monitor.call("activate","pause")
			check(not bool(monitor.get("_trying")) and bool(stage.get("running")) and stage.get("playhead") == 0, "DEMO restarts the demonstration: "+key)
			monitor.call("activate","pause")
			monitor.call("_physics_process",.2)
			monitor.call("_process",1.0)
			check(not bool(stage.get("running")) and stage.get("playhead") == 0, "Manual pause remains paused: "+key)
		var passed := true
		for row in checks: passed = passed and bool(row.passed)
		results.append({"id":item.id,"passed":passed,"checks":checks.duplicate(true),"actions":actions})
		monitor.queue_free()
		eye.queue_free()
		await process_frame
		await process_frame
	var all_passed := results.size() == 6
	for row in results: all_passed = all_passed and bool(row.passed)
	var output := FileAccess.open("res://ada_run/foundation_monitors/controls-report.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"passed":all_passed,"monitors":results,"scope":"Desktop runtime and XRTools pointer events; physical headset untested."},"\t"))
	output.close()
	quit(0 if all_passed else 1)
