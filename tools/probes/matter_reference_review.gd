extends "res://tools/probes/sine_yoke.gd"
var Ref: PackedScene
var capture := false
func pointer(button: Node3D) -> void:
	var host := Node3D.new();scene.add_child(host)
	var target := button.get_node("PushButton/InteractableAreaButton")
	target.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,host,target,target.global_position,target.global_position))
	target.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,host,target,target.global_position,target.global_position));host.queue_free()
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
		if arg=="--capture":capture = true
	scene = Node3D.new();root.add_child(scene);current_scene = scene;root.size = Vector2i(1440,900)
	Ref = load("res://commons/artifacts/matter_reference/matter_reference.tscn")
	if not capture:
		var ground := StaticBody3D.new();ground.position.y = -24.1;scene.add_child(ground);var c := CollisionShape3D.new();c.shape = BoxShape3D.new();c.shape.size = Vector3(50,.2,40);ground.add_child(c)
		for kind in ["and","nand"]:
			var work: Node3D = Ref.instantiate();work.apply_grid_config({"kind":kind});work.position = Vector3(4,-24,-3);work.rotation.y = .6;scene.add_child(work);await tick(4)
			var id: String = work.graph.output;var original: Vector3 = work.bodies[id].position
			work.apply_poses({"parts":{id:{"position":work.arr(original+Vector3(.01,0,0))}}});work.reset_take()
			check(kind+" edited member survives reset",work.bodies[id].position.distance_to(original+Vector3(.01,0,0))<.0001)
			pointer(work.buttons.X);check(kind+" production pointer toggles X",not work.inputs.X);pointer(work.buttons.X)
			pointer(work.buttons.RELEASE);check(kind+" production release starts physical bodies",work.running)
			for n in range(1050):
				if work.result>=0:break
				await tick()
			check(kind+" moved rotated negative-floor real physical result",work.result==(1 if kind=="and" else 0))
			pointer(work.buttons.RESET);check(kind+" reset restores edited member and clears result",work.result==-1 and work.bodies[id].position.distance_to(original+Vector3(.01,0,0))<.0001)
			work.queue_free();await tick(5)
	else:
		var building: Node3D = load("res://commons/void/architecture.gd").new();building.stream_content = true;scene.add_child(building)
		var env := WorldEnvironment.new();env.environment = Environment.new();env.environment.background_mode = Environment.BG_COLOR;env.environment.background_color = Color("35333a");env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color = Color("fff0dd");env.environment.ambient_light_energy = .6;scene.add_child(env)
		env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC;env.environment.tonemap_exposure = .45
		var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-45,-30,0);light.light_energy = .6;light.shadow_enabled = true;scene.add_child(light)
		camera = Camera3D.new();camera.fov = 43;camera.environment = env.environment;scene.add_child(camera)
		for i in range(1,13):
			building.content.load_floor(i);var shown: Array[int] = [i];building.show_floor_window(shown);await tick(6)
			var kind: String = (["and","or","xor","not","nor","nand"][i-1] if i<7 else "marble-"+["and","or","xor","not","half","count"][i-7])
			var work: Node3D = building.content.exhibits[str(i)+"/"+kind].get_node("Artifact")
			var center: float = work.graph.get("frame",{}).get("x",0)
			if i<7:await photo("gate-"+kind,work.to_global(Vector3(center+2.4,4.5,10.5 if kind!="xor" else 7.5)),work.to_global(Vector3(center,.7,0)))
			else:await photo(kind,work.to_global(Vector3(1.4,3.3,7.8)),work.to_global(Vector3(0,2.1,0)))
			check(kind+" all source bodies are individually editable",work.part_defaults.size()>=work.bodies.size())
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Production pointer controls, edited part reset, negative-floor moved/rotated Jolt outcomes; captures are actual registered trial geometry."}
	FileAccess.open(out.path_join("capture-checks.json" if capture else "review-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
