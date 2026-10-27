extends "res://tools/probes/sine_yoke.gd"
## Inspection views of the actual registered floor, before and after one tap.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out=" ):out = arg.trim_prefix("--out=")
	Source.use_main_tower = true;scene = Node3D.new();root.add_child(scene);current_scene = scene;root.size = Vector2i(1440,900)
	var building: Node3D = load("res://commons/void/architecture.gd").new();building.stream_content = true;scene.add_child(building);building.content.load_floor(46);var visible: Array[int] = [46];building.show_floor_window(visible);await tick(900)
	for key in building.content.exhibits:building.content.exhibits[key].visible = str(key).begins_with("46/")
	for layer in root.find_children("*","CanvasLayer",true,false):layer.hide()
	var env := Environment.new();env.background_mode = Environment.BG_COLOR;env.background_color = Color("33323a");env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color = Color("fff1df");env.ambient_light_energy = .35;env.tonemap_mode = Environment.TONE_MAPPER_FILMIC;env.tonemap_exposure = .45
	var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-42,-30,0);light.light_energy = .5;light.shadow_enabled = true;scene.add_child(light);camera = Camera3D.new();camera.fov = 48;camera.environment = env;scene.add_child(camera)
	var work: Node3D = building.content.exhibits["46/matter-leaning-together"].get_node("Artifact")
	check("actual floor holds the narrow-edge frame and elevated cube untouched",work.observations().angles.LeftPlank>45 and work.observations().angles.RightPlank>45 and work.bodies.Cube.position.y>1.6)
	var eye: Vector3 = work.to_global(Vector3(2.6,2.7,5));var target: Vector3 = work.to_global(Vector3(0,1.1,0))
	await photo("leaning-brittle-before",eye,target)
	var plank: Node3D = work.bodies.LeftPlank;var pointer := Node3D.new();scene.add_child(pointer);pointer.global_position = plank.global_position+work.global_basis.z*2+Vector3.UP*.15
	var ray := PhysicsRayQueryParameters3D.create(pointer.global_position,plank.global_position,1<<20);var hit := scene.get_world_3d().direct_space_state.intersect_ray(ray)
	check("inspection tap reaches the actual plank surface",not hit.is_empty() and hit.collider==plank)
	if not hit.is_empty() and hit.collider==plank:plank.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,pointer,plank,hit.position,hit.position))
	await tick(18);await photo("leaning-brittle-moving",eye,target);await tick(480)
	check("one finite tap dismantles the photographed frame",work.observations().angles.LeftPlank<25 and work.observations().angles.RightPlank<25 and work.bodies.Cube.position.y<1.3)
	await photo("leaning-brittle-after",eye,target)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Native main floor inspection views after 15 seconds untouched, then one mass-scaled finite tap from an explicit probe pointer. Actual desktop/synthetic XR input has a separate receipt. Neighbouring storeys are hidden for inspection."}
	FileAccess.open(out.path_join("leaning-brittle-capture-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));building.queue_free();await tick(5);print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
