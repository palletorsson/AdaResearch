extends "res://tools/probes/sine_yoke.gd"
## Isolated-floor inspection, not a curated six-floor route.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	Source.use_main_tower = false;scene = Node3D.new();root.add_child(scene);current_scene = scene;root.size = Vector2i(1440,900)
	var building: Node3D = load("res://commons/void/architecture.gd").new();building.stream_content = true;scene.add_child(building)
	var env := Environment.new();env.background_mode = Environment.BG_COLOR;env.background_color = Color("33323a");env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color = Color("fff1df");env.ambient_light_energy = .35;env.tonemap_mode = Environment.TONE_MAPPER_FILMIC;env.tonemap_exposure = .45
	var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-42,-30,0);light.light_energy = .5;light.shadow_enabled = true;scene.add_child(light)
	camera = Camera3D.new();camera.fov = 48;camera.environment = env;scene.add_child(camera)
	for level in range(27,33):
		building.content.load_floor(level);var visible: Array[int] = [level];building.show_floor_window(visible);await tick(5)
		for key in building.content.exhibits:building.content.exhibits[key].visible = str(key).begins_with(str(level)+"/")
		for layer in root.find_children("*","CanvasLayer",true,false):layer.hide()
		var item: Dictionary = building.content.data.floors[level].artifacts[0];var work: Node3D = building.content.exhibits[str(level)+"/"+str(item.id)].get_node("Artifact")
		work.release_take()
		if level==29:
			for n in 1800:
				if work.feed_ready:break
				await tick()
			work.request_grain()
			await tick(3)
			for n in 1800:
				if work.feed_ready or not work.running:break
				await tick()
			await photo("threshold-just-five",work.to_global(Vector3(2,2.7,5.7)),work.to_global(Vector3(.1,1.25,.5)))
			work.request_grain()
		for n in 2500:
			if not work.running:break
			await tick()
		check("threshold "+str(level)+" photographed with a native reading",work.result>=0 and not work.reading.is_empty())
		await photo("collection-f"+str(level).pad_zeros(2),work.to_global(Vector3(2,3.7,8)),work.to_global(Vector3(.3,1.1,.2)))
		if level==28:await photo("threshold-almost-measured",work.to_global(Vector3(2.3,2.5,5.6)),work.to_global(Vector3(.7,1.05,.6)))
		if level==29:await photo("threshold-just-tipped",work.to_global(Vector3(2,2.7,5.7)),work.to_global(Vector3(.1,1.25,.5)))
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Actual registered threshold studies after real Jolt observations. One floor visible at a time; Just shows five grains below and six above its counterweight. No composed trajectories or physical headset acceptance."}
	FileAccess.open(out.path_join("threshold-workshop-capture-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));building.queue_free();await tick(5);print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
