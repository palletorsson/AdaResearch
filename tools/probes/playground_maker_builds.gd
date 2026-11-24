extends SceneTree
## Floor Trans_Playground: what does the playground maker (construction_robot, row kit-playground-maker) do when
## its BUILD / HOLD button is pressed? For a writer: what the worker looks like at rest, what its console says, and
## what stands on the deck after ten, thirty and sixty seconds of building, and after HOLD.
##
##   python tools/run_floor_probe.py Trans_Playground playground_maker_builds.gd maker.json <folder> --no-opening --opera-quiet

var folder := "res://ada_run/playground_maker"
var eye: Camera3D
var content: Node3D
var floor_y := 0.0


func _initialize() -> void:
	run.call_deferred()


func _picture(file: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(file))


func _look(from: Vector3, at: Vector3) -> void:
	eye.global_position = from
	eye.look_at(at, Vector3.UP)


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	var game: Node = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	if game.body.get("scripted_input") != null:
		game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var index := int(game.checkpoint)
	var result := {"floor": index, "checks": [], "passed": false, "log": []}
	for i in 900: await physics_frame
	eye = root.get_camera_3d()
	var arrival := eye.global_position
	content = game.building.content.roots[index] as Node3D
	var ground := eye.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(arrival, arrival + Vector3.DOWN * 4.0, 1))
	floor_y = float(ground.position.y) if not ground.is_empty() else arrival.y - 1.6
	game.body.set_physics_process(false)
	game.body.set_process(false)
	var mount := game.building.content.exhibits.get("%d/kit-playground-maker" % index) as Node3D
	var maker := mount.get_node_or_null("Artifact") as Node3D if is_instance_valid(mount) else null
	if maker == null:
		(result.checks as Array).append({"check": "the playground maker stands on the floor", "ok": false})
		_done(result); return
	var walker := maker.get("walker") as Node3D
	var control := maker.get("control") as Node3D
	var here := walker.global_position
	result["worker_on_floor"] = [snappedf(content.to_local(here).x, 0.01), snappedf(here.y - floor_y, 0.01), snappedf(content.to_local(here).z, 0.01)]
	result["console_on_floor"] = [snappedf(content.to_local(control.global_position).x, 0.01), snappedf(control.global_position.y - floor_y, 0.01), snappedf(content.to_local(control.global_position).z, 0.01)]
	result["readout_at_rest"] = str((maker.get("readout") as Label3D).text)
	result["kit_label"] = str((maker.get("kit_label") as Label3D).text)
	# the worker at rest, from two sides, and its console
	_look(Vector3(here.x + 1.9, floor_y + 1.2, here.z + 1.9), Vector3(here.x, floor_y + 0.45, here.z))
	await _picture("1_worker_at_rest.png")
	_look(Vector3(here.x - 1.6, floor_y + 0.8, here.z + 1.2), Vector3(here.x, floor_y + 0.4, here.z))
	await _picture("2_worker_low.png")
	var c := control.global_position
	_look(c + maker.global_basis.z * 1.7 + Vector3.UP * 0.35, c)
	await _picture("3_console.png")
	# press BUILD
	maker.call("toggle_build")
	(result.log as Array).append({"t": 0, "readout": str((maker.get("readout") as Label3D).text), "placed": maker.get("placed"), "phase": maker.get("phase"), "jobs": (maker.get("jobs") as Array).size()})
	var overview_from := Vector3(here.x + 5.5, floor_y + 3.4, here.z + 6.5)
	for t in [10, 30, 60, 100]:
		var until := Time.get_ticks_msec() + 0
		var frames := int((t - (0 if (result.log as Array).size() == 1 else int((result.log as Array)[-1].t))) * 60)
		for i in frames: await process_frame
		var at := walker.global_position
		_look(Vector3(at.x + 2.2, floor_y + 1.5, at.z + 2.4), Vector3(at.x, floor_y + 0.6, at.z))
		await _picture("4_building_%03ds_worker.png" % t)
		_look(overview_from, Vector3(here.x + 1.0, floor_y + 0.4, here.z + 1.5))
		await _picture("5_building_%03ds_deck.png" % t)
		(result.log as Array).append({"t": t, "readout": str((maker.get("readout") as Label3D).text), "placed": maker.get("placed"), "phase": maker.get("phase"), "complete": maker.get("complete"),
			"worker": [snappedf(content.to_local(at).x, 0.01), snappedf(content.to_local(at).z, 0.01)]})
	# HOLD
	maker.call("toggle_build")
	for i in 30: await process_frame
	(result.log as Array).append({"t": "held", "readout": str((maker.get("readout") as Label3D).text), "placed": maker.get("placed"), "active": maker.get("active")})
	_look(c + maker.global_basis.z * 1.7 + Vector3.UP * 0.35, c)
	await _picture("6_console_held.png")
	(result.checks as Array).append({"check": "the worker waits until BUILD is pressed, then seats parts", "ok": str(result.readout_at_rest).contains("READY") and int(maker.get("placed")) > 0, "seated": maker.get("placed")})
	_done(result)


func _done(result: Dictionary) -> void:
	result.passed = (result.checks as Array).all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("maker.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit()
