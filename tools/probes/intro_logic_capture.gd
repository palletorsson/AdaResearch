extends "res://tools/probes/sine_yoke.gd"
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	Source.use_main_tower = true
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	var building: Node3D = load("res://commons/void/architecture.gd").new();building.stream_content = true;scene.add_child(building)
	building.content.load_floor(14);var shown: Array[int] = [14];building.show_floor_window(shown);level_y = building.spec.levels[14]
	root.size = Vector2i(1440,900)
	var env := WorldEnvironment.new();env.environment = Environment.new();env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("30383f");env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("d9e2e8");env.environment.ambient_light_energy = .25;env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC;scene.add_child(env)
	var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-45,-30,0);light.light_energy = .6;light.shadow_enabled = true;scene.add_child(light)
	camera = Camera3D.new();camera.fov = 60;scene.add_child(camera);camera.make_current();camera.position = at(0,2,8);camera.look_at(at(0,1,3.6))
	await tick(30)
	for op in ["and","or","not"]:
		var work: Node3D = building.content.exhibits["14/logic-spring-"+op].get_node("Artifact")
		await photo("02-"+op,work.to_global(Vector3(2.6,2.6,3.2)),work.to_global(Vector3(0,1.05,0)))
	camera.fov = 65
	await photo("01-playground",at(0,3.4,12),at(0,1.4,3.6))
	await photo("03-front",at(-4.8,1.75,6.6),at(-4.8,1.15,3.6))
	var gate: Node3D = building.content.exhibits["14/logic-spring-and"].get_node("Artifact")
	gate.set_input(0,true);gate.set_input(1,true);await tick(45)
	camera.fov = 52
	await photo("05-and-ready",gate.to_global(Vector3(2.6,2.6,3.2)),gate.to_global(Vector3(0,1.05,0)))
	gate.release_balls()
	for i in 900:
		if gate.outcome>=0 or gate.outcome==-2:break
		await tick()
	await tick(20)
	await photo("06-physical-impact",gate.to_global(Vector3(2.6,2.6,3.2)),gate.to_global(Vector3(0,1.05,0)))
	FileAccess.open(out.path_join("capture-observation.json"),FileAccess.WRITE).store_string(JSON.stringify({"outcome":gate.outcome,"target_angle_radians":gate.target.rotation.z,"target_is_dynamic":not gate.target.freeze},"  "))
	if gate.outcome!=1:push_error("Gravity capture did not reach target");quit(1);return
	print("INTRO_CAPTURE_RESULT saved five native views");quit()
