extends "res://tools/probes/sine_yoke.gd"
class FixtureHand extends Node3D:
	var picked_up_ranged := false

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	Source.use_main_tower = true;scene = Node3D.new();root.add_child(scene);current_scene = scene;root.size = Vector2i(1440,900)
	var building: Node3D = load("res://commons/void/architecture.gd").new();building.stream_content = true;scene.add_child(building);building.content.load_floor(46);var visible: Array[int] = [46];building.show_floor_window(visible);await tick(240)
	for key in building.content.exhibits:building.content.exhibits[key].visible = str(key).begins_with("46/")
	for layer in root.find_children("*","CanvasLayer",true,false):layer.hide()
	var env := Environment.new();env.background_mode = Environment.BG_COLOR;env.background_color = Color("33323a");env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color = Color("fff1df");env.ambient_light_energy = .35;env.tonemap_mode = Environment.TONE_MAPPER_FILMIC;env.tonemap_exposure = .45
	var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-42,-30,0);light.light_energy = .5;light.shadow_enabled = true;scene.add_child(light);camera = Camera3D.new();camera.fov = 48;camera.environment = env;scene.add_child(camera)
	var work: Node3D = building.content.exhibits["46/matter-leaning-together"].get_node("Artifact")
	var state: Dictionary = work.observations();check("actual floor supports the two leaning planks and both loose chocks",state.contacts.has("LeftPlank + RightPlank") and state.contacts.has("LeftPlank + LeftWedge") and state.contacts.has("RightPlank + RightWedge"))
	await photo("leaning-together",work.to_global(Vector3(2.6,2.4,4.5)),work.to_global(Vector3(0,.85,0)))
	var hand := FixtureHand.new();scene.add_child(hand);hand.global_transform = work.bodies.LeftWedge.global_transform;work.bodies.LeftWedge.pick_up(hand);hand.global_position += work.global_basis.x*-.7+Vector3.UP*.35;await tick(180)
	work.bodies.LeftWedge.let_go(hand,Vector3.ZERO,Vector3.ZERO);await tick(120)
	check("withdrawing the foot chock changes the actual floor posture",work.observations().angles.RightPlank<30)
	await photo("leaning-withdrawn",work.to_global(Vector3(2.6,2.4,4.5)),work.to_global(Vector3(0,.85,0)))
	work.reset_take();await tick(150);hand.global_transform = work.bodies.Cube.global_transform;work.bodies.Cube.pick_up(hand)
	hand.global_position = work.to_global(Vector3(0,1.97,-.12));await tick(20);work.bodies.Cube.let_go(hand,Vector3.ZERO,Vector3.ZERO);await tick(100)
	check("the cube is released as a genuine live load",not work.bodies.Cube.freeze and work.bodies.Cube.global_position.y<work.to_global(Vector3(0,1.97,0)).y-.1)
	await photo("leaning-load",work.to_global(Vector3(2.6,2.4,4.5)),work.to_global(Vector3(0,.85,0)))
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Native main-floor geometry. Inspection camera hides neighbouring storeys. Chock withdrawal and cube release use an explicit native fixture hand, not a captured user gesture; actual desktop/synthetic-XR input has a separate receipt."}
	FileAccess.open(out.path_join("leaning-capture-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));building.queue_free();await tick(5);print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
