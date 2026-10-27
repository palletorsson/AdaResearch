extends "res://tools/probes/zoetrope_playback.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	Source.use_main_tower = true
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	var building: Node3D = load("res://commons/void/architecture.gd").new()
	building.stream_content = true;scene.add_child(building)
	var draft: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("draft-rooms.json")))
	building.content.data.floors[59] = draft.floors[59];building.content.load_floor(59)
	var shown: Array[int] = [59];building.show_floor_window(shown)
	level_y = building.spec.levels[59];root.size = Vector2i(1440,900)
	var env := WorldEnvironment.new();env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR;env.environment.background_color = Color("30383f")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("d9e2e8");env.environment.ambient_light_energy = .7;scene.add_child(env)
	var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-40,-30,0);light.light_energy = .9;scene.add_child(light)
	camera = Camera3D.new();camera.fov = 58;scene.add_child(camera);camera.make_current()
	await tick(15)
	var single: Node3D = building.content.exhibits["59/hand-single-turntable"].get_node("Artifact")
	var large: Node3D = building.content.exhibits["59/hand-scale-zoetrope"].get_node("Artifact")
	var yoke: Node3D = building.content.exhibits["59/hand-sine-yoke"].get_node("Artifact")
	work = single;pointer = Node3D.new();scene.add_child(pointer)
	var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("before-rooms.json")))
	var all_kept := true
	for a in before.floors[59].artifacts:
		all_kept = all_kept and draft.floors[59].artifacts.any(func(b):return a.id==b.id and a.artifact==b.artifact and a.get("config",{})==b.get("config",{}))
	check("all23 original occurrences kept and one turntable added",all_kept and draft.floors[59].artifacts.size()==24)
	check("cube-wedge modules remain individually authored",draft.floors[59].construction.filter(func(c):return str(c.id).begins_with("wave-path-")).size()==31)
	check("one real cube fixed to one rotating platform",single.cubes.size()==1 and single.cubes[0].get_parent()==single.disk and single.part_defaults.size()==2 and not single.has_node("RoomShell"))
	check("large24-frame disk retains original size and speed",large.cubes.size()==24 and large.plate_radius==2.5 and large.deck_y==2 and large.motor_rpm==60 and large.sample_hz==12)
	single.set_process(false);single.auto_run = true;single.manual_cooldown = 0
	var pose: Transform3D = single.cubes[0].transform
	var dimensions: Vector3 = single.cubes[0].mesh.get_aabb().size
	var carried := true;var old: Vector3 = single.cubes[0].global_position
	var old_basis: Basis = single.cubes[0].global_basis
	single.wheel.set_angle_degrees(0);single.motor_phase = 0
	for i in 120:
		single.advance_motion(1.0/60)
		carried = carried and single.cubes[0].transform==pose and single.cubes[0].mesh.get_aabb().size==dimensions
		var radial: Vector3 = single.disk.to_local(single.cubes[0].global_position)
		carried = carried and Vector2(radial.x,radial.z).length()<.001
	check("centered cube turns in place with the compact plate",carried and single.cubes[0].global_position.distance_to(old)<.001 and not single.cubes[0].global_basis.is_equal_approx(old_basis) and is_equal_approx(single.plate_radius,.55))
	slide(0,.5);check("real speed fader reaches15RPM",absf(single.motor_rpm-15)<.02)
	slide(1,.25);check("real ANGLE fader places90degrees and pauses",absf(single.angle_degrees-90)<.15 and not single.auto_run)
	press(0);press(1);single.manual_cooldown = 0;single.advance_motion(.1)
	check("RUN and REVERSE operate the platform",single.auto_run and single.reverse and single.angle_degrees<90)
	single.auto_run = false
	var rim: StaticBody3D = single.wheel.rotor.get_children().filter(func(n):return n is StaticBody3D)[0]
	var p: Vector3 = single.wheel.to_global(Vector3(.46,0,.05))
	single.wheel.set_angle_degrees(0)
	rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,pointer,rim,p,p))
	for i in range(1,19):
		var a := i*PI/36;var next: Vector3 = single.wheel.to_global(Vector3(cos(a)*.46,sin(a)*.46,.05))
		rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.MOVED,pointer,rim,next,p));p=next
	rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,pointer,rim,p,p))
	check("desktop hand wheel rotates plate and attached cube",absf(single.angle_degrees-90)<.01)
	# Production XRTools handle at supplied poses, including the90-degree map placement.
	var origin := XROrigin3D.new();scene.add_child(origin)
	var controller := XRController3D.new();origin.add_child(controller)
	var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	single.wheel.set_angle_degrees(0);controller.global_transform = single.wheel.grip.global_transform
	single.wheel.grip.pick_up(pickup);await tick(3)
	var initial: float = single.angle_degrees
	for i in range(1,19):
		var a := i*PI/36;controller.global_position = single.wheel.to_global(Vector3(cos(a)*.48,sin(a)*.48,.29));await tick(2)
	check("supplied XR hand turns the yawed one-cube machine",single.wheel.grip.is_picked_up() and absf(single.angle_degrees-initial)>60)
	single.wheel.grip.let_go(pickup,Vector3.ZERO,Vector3.ZERO);origin.queue_free();await tick(3)
	check("X/Y rack and follower occupy the side study",building.content.exhibits["59/monitor"].position.x< -4 and building.content.exhibits["59/driven"].position.x< -4 and building.content.exhibits["59/clock"].position.x< -14)
	# Walk the intended path with the real capsule, gravity, slope rules and all
	# authored collisions. No teleports, jumping, removed blockers or flight.
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("plan.json")))
	var visitor: CharacterBody3D = load("res://commons/void/walker.gd").new();scene.add_child(visitor)
	visitor.set_process_unhandled_input(false);visitor.desktop_pointer.enabled = false
	visitor.desktop_pointer.set_process_input(false);visitor.scripted_input = true
	visitor.position = at(-1.6,.06,7.2);await tick(10)
	var walk: Array = [];var clear := true
	for item in plan.route_feet:
		var target: Vector3 = at(item[0],item[1],item[2]);var reached := false
		for i in 380:
			var difference: Vector3 = target-visitor.global_position;difference.y = 0
			if difference.length()<.13 and absf(visitor.global_position.y-target.y)<.20:reached = true;break
			visitor.drive = Vector2(difference.x,difference.z).normalized()*.55;await tick()
		walk.append({"target":item,"reached":reached,"feet":[visitor.position.x,visitor.position.y-level_y,visitor.position.z]})
		if not reached:clear = false;break
	visitor.drive = Vector2.ZERO
	check("player walks yoke to one-cube station and up/down the disk viewpoint",clear)
	observations.walk = walk
	visitor.queue_free();await tick(3);camera.make_current()
	large.auto_run = false;single.auto_run = false
	large.wheel.set_angle_degrees(0);single.wheel.set_angle_degrees(35)
	large.refresh_controls();single.refresh_controls()
	camera.fov = 64
	await photo("01-tutorial-path",at(12.2,10.8,12.0),at(1.5,1.0,1.2))
	camera.fov = 54
	await photo("02-one-cube-turntable",at(8.1,3.2,5.4),single.to_global(Vector3(.25,1.15,.5)))
	await photo("03-yoke-entry",at(-.5,2.5,8.6),yoke.to_global(Vector3(.45,1.0,0)))
	camera.fov = 70
	await photo("04-raised-disk-view",at(5.1,2.6,-3.5),large.to_global(Vector3(.2,2.25,0)))
	var report := {"passed":failed.is_empty(),"checks":checks,"failed":failed,"observations":observations,"scope":"Actual floor59 draft and original collisions; complete capsule route, production pointer controls and supplied-pose XR turntable grab. No physical-headset acceptance. Original artifacts retained; rack moved aside."}
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("WAVE_PATH_RESULT ",checks.size()," failures:",failed)
	quit(0 if failed.is_empty() else 1)
