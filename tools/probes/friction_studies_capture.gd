extends "res://tools/probes/sine_yoke.gd"
## Actual registered scenes, final physical takes; one-floor inspection views.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	Source.use_main_tower = true;scene = Node3D.new();root.add_child(scene);current_scene = scene;root.size = Vector2i(1440,900)
	var building: Node3D = load("res://commons/void/architecture.gd").new();building.stream_content = true;scene.add_child(building);building.content.load_floor(46);var visible: Array[int] = [46];building.show_floor_window(visible);await tick(10)
	for key in building.content.exhibits:building.content.exhibits[key].visible = str(key).begins_with("46/")
	for layer in root.find_children("*","CanvasLayer",true,false):layer.hide()
	var env := Environment.new();env.background_mode = Environment.BG_COLOR;env.background_color = Color("33323a");env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color = Color("fff1df");env.ambient_light_energy = .35;env.tonemap_mode = Environment.TONE_MAPPER_FILMIC;env.tonemap_exposure = .45
	var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-42,-30,0);light.light_energy = .5;light.shadow_enabled = true;scene.add_child(light);camera = Camera3D.new();camera.fov = 54;camera.environment = env;scene.add_child(camera)
	var y: float = building.spec.levels[46]
	await photo("friction-layout",Vector3(1,y+13,-30),Vector3(0,y+1,0))
	for kind in ["ramp","coast","pull"]:
		var work: Node3D = building.content.exhibits["46/matter-friction-"+kind].get_node("Artifact")
		if kind=="ramp":
			for n in 8:work.command("MORE");await tick(3)
		if kind=="pull":
			for n in 7:work.command("MORE");await tick(3)
		work.release_take()
		for n in 700:
			if not work.running:break
			await tick()
		check(kind+" final native take is photographed",work.history.size()==1 and not work.reading.is_empty())
		var eye := Vector3(2.7,2.9,5.8);var target := Vector3(.5,.85,.4)
		if kind=="pull":eye = Vector3(3.6,2.6,5.5);target = Vector3(.6,.65,0)
		await photo("friction-"+kind,work.to_global(eye),work.to_global(target))
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Actual main-floor native geometry and physical readings. Inspection cameras show one storey with neighbours hidden; original floor-46 exhibits remain. Separate real-player receipts cover controls and approaches."}
	FileAccess.open(out.path_join("friction-capture-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));building.queue_free();await tick(5);print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
