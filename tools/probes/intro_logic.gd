extends "res://tools/probes/sine_yoke.gd"
var pointer: Node3D
func press(work: Node3D,id: String) -> void:
	var area: Area3D = work.buttons[id].get_node("PushButton/InteractableAreaButton")
	var p := area.global_position
	area.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,pointer,area,p,p))
	area.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,pointer,area,p,p))
	await tick(3)
func attempt(work: Node3D,bits: String) -> Dictionary:
	await press(work,"RESET")
	if bits[0]=="1":await press(work,"X")
	if bits.length()>1 and bits[1]=="1":await press(work,"Y")
	await tick(45)
	var held_speed := 0.0
	for ball in work.launcher.balls:held_speed = maxf(held_speed,ball.linear_velocity.length())
	var armed: bool = work.launcher.armed
	await press(work,"RELEASE")
	for i in 1200:
		if work.outcome>=0 or work.outcome==-2:break
		await tick()
	var cube_poses: Array = []
	for cube in work.cubes:cube_poses.append(work.to_local(cube.global_position))
	await tick(20)
	var dynamic_inputs := true
	for i in work.cubes.size():
		if bits[i]=="1" and work.cubes[i].freeze:dynamic_inputs = false
	var result := {"operator":work.operator,"inputs":bits,"outcome":work.outcome,"armed":armed,"held_speed":held_speed,"elapsed":work.elapsed,"label":work.result_label.text,"samples":work.run_samples.duplicate(true),"piston":work.launcher.displacement,"cube_poses":cube_poses,"dynamic_inputs":dynamic_inputs,"target_angle":work.target.rotation.z}
	print("INTRO_ATTEMPT ",JSON.stringify({"operator":work.operator,"inputs":bits,"outcome":work.outcome,"elapsed":work.elapsed,"label":work.result_label.text,"piston":work.launcher.displacement}))
	FileAccess.open(out.path_join("last-"+work.operator+"-"+bits+".json"),FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	return result
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	Source.use_main_tower = true
	OS.set_environment("VOID_INVENTORY_PATH",out.path_join("inventory-"+str(Time.get_ticks_usec())+".json"))
	check("native engine is Jolt Physics",ProjectSettings.get_setting("physics/3d/physics_engine")=="Jolt Physics")
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	var building: Node3D = load("res://commons/void/architecture.gd").new()
	building.stream_content = true;scene.add_child(building)
	var draft: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("draft-rooms.json")))
	building.content.data.floors[14] = draft.floors[14];building.content.load_floor(14)
	var shown: Array[int] = [14];building.show_floor_window(shown)
	level_y = building.spec.levels[14];root.size = Vector2i(1440,900)
	var env := WorldEnvironment.new();env.environment = Environment.new();env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("30383f");env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("d9e2e8");env.environment.ambient_light_energy = .55;scene.add_child(env)
	var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-45,-30,0);light.light_energy = .9;light.shadow_enabled = true;scene.add_child(light)
	camera = Camera3D.new();camera.fov = 56;scene.add_child(camera);camera.make_current();camera.position = at(0,2,8);camera.look_at(at(0,1,3.6))
	pointer = Node3D.new();scene.add_child(pointer)
	var inventory: Node = load("res://commons/void/prefab_inventory.gd").new();scene.add_child(inventory);inventory.bind_lesson(building.content,"")
	await tick(30)
	var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("before-rooms.json")))
	check("floor7 AND and floor59 machines preserved",before.floors[7]==draft.floors[7] and before.floors[59]==draft.floors[59])
	check("standard floor and raised crossing retained",building.spec.width==42 and draft.floors[14].construction==before.floors[14].construction and draft.floors[14].artifacts[0]==before.floors[14].artifacts[0])
	var runs: Array = []
	for op in ["AND","OR","NOT"]:
		var work: Node3D = building.content.exhibits["14/logic-spring-"+op.to_lower()].get_node("Artifact")
		check(op+" double-size parts at reachable height",is_equal_approx(work.UNIT,.24) and is_equal_approx(work.TABLE_HEIGHT,.84) and work.scale==Vector3.ONE)
		check(op+" no spring and genuine Jolt guides",work.launcher.get_script().resource_path.ends_with("gravity_launcher.gd") and work.input_joints.size()==work.cubes.size() and not work.target.freeze and not work.has_method("cock_spring"))
		for bits in work.required_observations:
			var result: Dictionary = await attempt(work,bits);runs.append(result)
			check(op+" "+bits+" held at stop then physically observed",result.armed and result.held_speed<.05 and result.dynamic_inputs and result.outcome==work.required_observations[bits])
			if result.outcome==1:check(op+" "+bits+" physical impact tips hinged target",absf(result.target_angle)>.015)
			if result.outcome!=work.required_observations[bits]:
				FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":false,"checks":checks,"failures":failed,"observations":{"runs":runs}},"  "))
				print("INTRO_LOGIC_RESULT failed physical case ",op," ",bits);quit(1);return
		check(op+" completed truth table earns shared catalogue prefab",work.lesson_complete and inventory.unlocked("matter_spring_"+op.to_lower()))
		await press(work,"RESET")
		if DisplayServer.get_name()!="headless":await photo("02-"+op.to_lower(),work.to_global(Vector3(2.9,2.7,3.3)),work.to_global(Vector3(0,1,0)))
	observations.runs = runs
	inventory.reload();check("earned recipes reload from isolated save",inventory.unlocked("matter_spring_and") and inventory.unlocked("matter_spring_or") and inventory.unlocked("matter_spring_not"))
	var work: Node3D = building.content.exhibits["14/logic-spring-and"].get_node("Artifact")
	var pose: Transform3D = work.transform;work.position += Vector3(.1,.15,0);work.rotation.y = deg_to_rad(23);work._sync_bodies(work)
	var moved := await attempt(work,"11");observations.moved = moved
	check("negative-floor moved rotated Jolt guides preserve physical result",moved.outcome==1 and moved.dynamic_inputs)
	work.transform = pose;work._sync_bodies(work);await press(work,"RESET")
	var origin := XROrigin3D.new();scene.add_child(origin);var controller := XRController3D.new();origin.add_child(controller)
	var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	var launcher: Node3D = work.launcher;controller.global_transform = launcher.handle.global_transform
	launcher.handle.pick_up(pickup);await tick(2)
	for i in range(1,13):controller.global_position = launcher.to_global(Vector3(-.1,.34+.015*i,.29));await tick(2)
	check("supplied XR hand lifts stop and releases gravity ball",launcher.handle.is_picked_up() and launcher.active and launcher.displacement>.1)
	launcher.handle.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick(3)
	check("XR release leaves gravity stop open",launcher.active and work.running)
	origin.queue_free();await press(work,"RESET")
	var visitor: CharacterBody3D = load("res://commons/void/walker.gd").new();scene.add_child(visitor)
	visitor.set_process_unhandled_input(false);visitor.desktop_pointer.enabled = false;visitor.desktop_pointer.set_process_input(false);visitor.scripted_input = true
	visitor.position = at(-7,.06,5.7);await tick(10)
	var clear := true
	for goal in [at(-4.8,0,5.15),at(-2.4,0,5.15),at(-2.4,0,2.4),at(-2.4,0,5.7),at(0,0,5.15),at(4.8,0,5.15),at(7,0,5.7)]:
		var reached := false
		for i in 300:
			var diff: Vector3 = goal-visitor.global_position;diff.y = 0
			if diff.length()<.12:reached = true;break
			visitor.drive = Vector2(diff.x,diff.z).normalized()*.7;await tick()
		if not reached:clear = false;break
	check("desktop capsule reaches three fronts and passes between assemblies",clear)
	visitor.queue_free();await tick(2)
	if DisplayServer.get_name()!="headless":
		await photo("01-playground",at(9,4.8,10),at(-.4,1.7,2.8))
		await photo("03-front",at(-4.8,1.75,6.6),at(-4.8,1.15,3.6))
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"observations":observations,"scope":"Jolt rigid balls, vertical slider joints and motor-free target hinges. Production pointer-event controls, supplied XRTools hand pose and capsule circulation. No physical headset acceptance."}
	var f := FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
	print("INTRO_LOGIC_RESULT ",JSON.stringify({"passed":failed.is_empty(),"failures":failed}));quit(0 if failed.is_empty() else 1)
