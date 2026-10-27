extends "res://tools/probes/sine_yoke.gd"
var selected: Array[int] = []
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
		if arg.begins_with("--floors="):
			for value in arg.trim_prefix("--floors=").split(","):selected.append(int(value))
	Source.use_main_tower = false;scene = Node3D.new();root.add_child(scene);current_scene = scene;root.size = Vector2i(1440,900)
	var building: Node3D = load("res://commons/void/architecture.gd").new();building.stream_content = true;scene.add_child(building)
	var env := Environment.new();env.background_mode = Environment.BG_COLOR;env.background_color = Color("33323a");env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color = Color("fff1df");env.ambient_light_energy = .35;env.tonemap_mode = Environment.TONE_MAPPER_FILMIC;env.tonemap_exposure = .45
	var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-42,-30,0);light.light_energy = .5;light.shadow_enabled = true;scene.add_child(light)
	camera = Camera3D.new();camera.fov = 48;camera.environment = env;scene.add_child(camera)
	for level in [1,7,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36]:
		if not selected.is_empty() and level not in selected:continue
		building.content.load_floor(level);var visible: Array[int] = [level];building.show_floor_window(visible);await tick(5)
		# Isolated floor inspection, matching the editor's selected-floor view.
		# Tall neighboring studies would otherwise obscure the photographed work.
		for key in building.content.exhibits:building.content.exhibits[key].visible = str(key).begins_with(str(level)+"/")
		for layer in root.find_children("*","CanvasLayer",true,false):layer.hide()
		var item: Dictionary = building.content.data.floors[level].artifacts[0];var work: Node3D = building.content.exhibits[str(level)+"/"+str(item.id)].get_node("Artifact")
		check("floor "+str(level)+" has editable source parts",work.part_defaults.size()>0)
		var eye := Vector3(2,4.5,10);var target := Vector3(0,1,0)
		if level==7:eye = Vector3(1.4,3.5,7.5);target = Vector3(0,2,0)
		if level==13:eye = Vector3(0,4,12);target = Vector3(-1.5,.7,0)
		if level==14:
			for value in ["monitor","cone"]:work.insert("stack",value);work.insert("queue",value);await tick(120)
			eye = Vector3(2.5,4.7,11);target = Vector3(0,2,0)
		if level in [15,16,17,18]:
			work.command("RUN")
			for n in range(800):
				if work.outputs.size()>=2:break
				await tick()
			work.running = false;eye = Vector3(4,5.5,14);target = Vector3(0,.8,0)
		if level in [19,20,21,22]:target = Vector3(0,1.3,0);eye = Vector3(3,4.5,10)
		if level in [23,24,25,26]:eye = Vector3(3,4,9);target = Vector3(0,1.1,0)
		if level>=27 and level<=32:eye = Vector3(2,3.7,8);target = Vector3(0,1.1,0)
		if level==33:work.finish_computed();eye = Vector3(9,4.8,14);target = Vector3(3.8,1,0)
		if level==34:work.finish_computed();eye = Vector3(1,4.3,14);target = Vector3(0,0,0)
		if level==35:work.command("FINISH");eye = Vector3(14,9,18);target = Vector3(5,1.4,-2.8)
		if level==36:eye = Vector3(.5,3.5,14);target = Vector3(.5,1.7,0)
		await photo("collection-f"+str(level).pad_zeros(2),work.to_global(eye),work.to_global(target))
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Actual registered trial geometry, one floor visible at a time with neighboring exhibits hidden for inspection. Stack/call/loop screenshots show native runtime state; knitted previews use the explicitly labelled source COMPUTE/FINISH mode. These views do not establish multi-floor clearance."};FileAccess.open(out.path_join("collection-capture-checks.json" if selected.is_empty() else "collection-capture-focus-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));building.queue_free();await tick(5);print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
