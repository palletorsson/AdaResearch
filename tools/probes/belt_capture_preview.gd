extends "res://tools/probes/zoetrope_playback.gd"
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	Source.use_main_tower = true
	scene = Node3D.new();root.add_child(scene);current_scene = scene;root.size = Vector2i(1440,900)
	var building: Node3D = load("res://commons/void/architecture.gd").new();building.stream_content = true;scene.add_child(building)
	var draft: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("draft-rooms.json")))
	var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("before-rooms.json")))
	building.content.data.floors[59] = draft.floors[59];building.content.load_floor(59)
	var shown: Array[int] = [59];building.show_floor_window(shown);level_y = building.spec.levels[59]
	var env := WorldEnvironment.new();env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR;env.environment.background_color = Color("302e38")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color = Color("e8dfe6")
	env.environment.ambient_light_energy = .5;env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC;scene.add_child(env)
	var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-38,-28,0);light.light_energy = .8;light.shadow_enabled = true;scene.add_child(light)
	camera = Camera3D.new();camera.fov = 57;scene.add_child(camera);camera.make_current();await tick(12)
	work = building.content.exhibits["59/two-wheel-belt-drive"].get_node("Artifact")
	work.set_process(false);work.auto_run = false;work.wheel.set_angle_degrees(30);work.refresh_controls()
	camera.fov = 50
	await photo("03-belt-ratio-front",work.to_global(Vector3(-.4,2.8,6.7)),work.to_global(Vector3(-.4,1.55,0)))
	print("BELT_CAPTURE_READY");quit()
