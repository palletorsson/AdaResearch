extends "res://commons/testing/capture_artifact_shot.gd"
## Read-only photography of existing scenes. No production files are changed.
func _run_capture() -> void:
	root.size = Vector2i(1440, 960)
	var info: Dictionary = _find_artifact(_artifact_name)
	if _artifact_name == "simple_ant_v2":
		info = {"scene": "res://algorithms/swarmintelligence/ants_v2/SimpleAnt.tscn"}
	if info.is_empty():
		quit(1)
		return
	var stage := Node3D.new()
	root.add_child(stage)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(.10, .115, .15)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(.8, .85, 1)
	env.ambient_light_energy = .7
	var world := WorldEnvironment.new()
	world.environment = env
	stage.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -25, 0)
	sun.light_energy = 1.1
	stage.add_child(sun)
	var packed: PackedScene = load(info.scene)
	var artifact: Node3D = packed.instantiate()
	var started := Time.get_ticks_msec()
	var setup := "Scene defaults; live simulation"
	if _artifact_name == "grid2d_langtons_ant":
		artifact.set("algorithm", 9) # Declared LANGTONS_ANT enum in Grid2DSubstrate.
		setup = "Grid2D with LANGTONS_ANT cartridge selected before entering tree"
	if _artifact_name == "simple_ant_v2":
		artifact.process_mode = Node.PROCESS_MODE_DISABLED
		setup = "Static component portrait; requires colony grid to run"
	stage.add_child(artifact)
	await create_timer(_wait_seconds).timeout
	var bounds := AABB()
	var found := false
	for n in artifact.find_children("*", "VisualInstance3D", true, false):
		if n is Label3D or not n.is_visible_in_tree() or n.get_world_3d() != artifact.get_world_3d():
			continue
		var b: AABB = n.global_transform * n.get_aabb()
		if b.size.length_squared() < .00001:
			continue
		bounds = bounds.merge(b) if found else b
		found = true
	var cam := Camera3D.new()
	stage.add_child(cam)
	var target: Vector3 = bounds.get_center() if found else artifact.global_position
	var span: float = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z)) if found else 3.0
	var direction := Vector3(.2, .48, 1).normalized()
	if _artifact_name in ["grid2d_langtons_ant", "stigmergy_room", "stigmergy_toy", "langton_toy"]:
		direction = Vector3(.15, 1.2, 1).normalized()
	var distance := maxf(.5, span * 1.45)
	if _artifact_name in ["langton_bench", "stigmergy_bench"]:
		target.y += .12
		distance = span * 1.7
	if _artifact_name == "stigmergy_toy":
		target.y += .10
		distance = .95
	cam.position = target + direction * distance
	cam.look_at(target)
	cam.fov = 55
	cam.make_current()
	await process_frame
	await RenderingServer.frame_post_draw
	var err: int = root.get_texture().get_image().save_png(_output_path)
	var receipt := {"artifact": _artifact_name, "scene": info.scene, "setup": setup,
		"wait_seconds": _wait_seconds, "bounds": str(bounds), "camera": str(cam.position),
		"geometry_found": found, "image_saved": err == OK, "camera_retained": root.get_camera_3d() == cam}
	var file := FileAccess.open(_output_path.get_basename() + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(receipt, "\t"))
	file.close()
	print("ANT GALLERY ", JSON.stringify(receipt))
	if "--long-run" in OS.get_cmdline_user_args():
		var frames: Array = []
		for seconds in [5, 30, 90]:
			var remaining := float(seconds) - float(Time.get_ticks_msec() - started) / 1000.0
			if remaining > 0:
				await create_timer(remaining).timeout
			cam.make_current()
			await process_frame
			await RenderingServer.frame_post_draw
			var path := _output_path.get_basename() + "-%d.png" % seconds
			var saved := root.get_texture().get_image().save_png(path) == OK
			var state := _observed_state(artifact)
			frames.append({"seconds": seconds, "wall_seconds": (Time.get_ticks_msec()-started)/1000.0,
				"image": path.get_file(), "saved": saved, "state": state})
			print("LONG ANT ", _artifact_name, " / ", seconds, " / ", state)
		receipt["timeline"] = frames
		FileAccess.open(_output_path.get_basename()+".json", FileAccess.WRITE).store_string(JSON.stringify(receipt,"\t"))
	quit(0 if err == OK and found and root.get_camera_3d() == cam else 1)

func _observed_state(artifact: Node) -> Dictionary:
	var result := {}
	for property in artifact.get_property_list():
		var key: String = property.name
		if key in ["_state", "_field", "_pheromone", "_grid", "_ants", "_agents", "walkers", "model", "colony"]:
			var value = artifact.get(key)
			if value is Array or value is PackedFloat32Array or value is PackedInt32Array:
				result[key] = {"count": value.size(), "digest": var_to_str(value).sha256_text()}
			elif value is Object:
				for nested in value.get_property_list():
					if nested.name in ["steps", "delivered", "num_agents", "num_ants"]:
						result[key+"."+nested.name] = value.get(nested.name)
	result["child_count"] = artifact.get_child_count()
	return result
