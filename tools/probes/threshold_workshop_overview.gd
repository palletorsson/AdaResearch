extends "res://tools/probes/sine_yoke.gd"
## Final main-floor inspection photographs; only this storey is shown.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	Source.use_main_tower = true;scene = Node3D.new();root.add_child(scene);current_scene = scene;root.size = Vector2i(1440,900)
	var building: Node3D = load("res://commons/void/architecture.gd").new();building.stream_content = true;scene.add_child(building);building.content.load_floor(14);var visible: Array[int] = [14];building.show_floor_window(visible);await tick(6)
	for key in building.content.exhibits:building.content.exhibits[key].visible = str(key).begins_with("14/")
	for layer in root.find_children("*","CanvasLayer",true,false):layer.hide()
	var env := Environment.new();env.background_mode = Environment.BG_COLOR;env.background_color = Color("33323a");env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color = Color("fff1df");env.ambient_light_energy = .35;env.tonemap_mode = Environment.TONE_MAPPER_FILMIC;env.tonemap_exposure = .45
	var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-42,-30,0);light.light_energy = .5;light.shadow_enabled = true;scene.add_child(light)
	camera = Camera3D.new();camera.fov = 57;camera.environment = env;scene.add_child(camera)
	await photo("threshold-main-overview",Vector3(0,-73,-31),Vector3(0,-83,-1))
	camera.fov = 75
	await photo("threshold-main-east-bay",Vector3(15.2,-82.4,4.25),Vector3(18,-82.9,4.4));camera.fov = 57
	if "--layout-only" in OS.get_cmdline_user_args():
		building.queue_free();await tick(5);print("MATTER_REFERENCE_RESULT ",JSON.stringify({"passed":true,"scope":"Recaptured layout camera views only; no mechanism checks repeated."}));quit(0);return
	for kind in ["almost","just"]:
		var work: Node3D = building.content.exhibits["14/threshold-workshop-"+kind].get_node("Artifact");work.release_take()
		if kind=="just":
			for grain in 2:
				for n in 1800:
					if work.feed_ready:break
					await tick()
				work.request_grain();await tick(3)
		for n in 2500:
			if not work.running:break
			await tick()
		check(kind+" final native state photographed",work.result>=0 and not work.reading.is_empty())
		await photo("threshold-main-"+kind+"-detail",work.to_global(Vector3(1.6,2.6,5.1)),work.to_global(Vector3(.65,1.1,.55)))
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Final main floor-14 inspection views, one storey visible. Actual Jolt readings in Almost/Just close-ups. Neighbouring floors/exhibits hidden for photographs; separate real-player receipts verify the walk and controls."}
	FileAccess.open(out.path_join("threshold-main-capture-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));building.queue_free();await tick(5);print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
