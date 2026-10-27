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
	work = building.content.exhibits["59/hand-scale-zoetrope"].get_node("Artifact")
	pointer = Node3D.new();scene.add_child(pointer)
	check("room walls, ceiling, floor and service leaf removed",not work.has_node("RoomShell") and not work.has_node("ServicePanel"))
	check("disk and control stand remain separate editable groups",work.part_defaults.size()==2 and work.part_defaults.has("DiskAndCrank") and work.part_defaults.has("PlaybackControls"))
	var platter: MeshInstance3D = work.disk.get_node("TimberDisk")
	var top: float = (platter.global_transform*platter.get_aabb()).end.y-level_y
	check("disk top is two metres above the floor",absf(top-2)<.001)
	check("crank remains at1.18m and controls at1.98m",absf(work.wheel.global_position.y-level_y-1.18)<.001 and absf(work.controls.global_position.y-level_y-1.98)<.001)
	var foot: MeshInstance3D = work.controls.get_node("ControlStandFoot")
	check("controls stand on a grounded foot",absf((foot.global_transform*foot.get_aabb()).position.y-level_y)<.001)
	check("screenshot setting preserved60RPM and12Hz with shutter off",work.motor_rpm==60 and work.sample_hz==12 and work.auto_run and not work.shutter.visible)
	work.set_process(false);reset_motion(60,12)
	var poses: Array = [];var sizes: Array = []
	for cube in work.cubes:poses.append(cube.transform);sizes.append(cube.mesh.get_aabb().size)
	var fixed := true
	for frame in 240:
		work.advance_motion(1.0/120)
		for i in 12:fixed = fixed and work.cubes[i].transform==poses[i] and work.cubes[i].mesh.get_aabb().size==sizes[i]
	check("two repeating turns keep every cube fixed on the disk",fixed and absf(work.angle_degrees)<.001 and work.disk.get_child_count()==25)
	var rim: StaticBody3D = work.wheel.rotor.get_children().filter(func(n):return n is StaticBody3D)[0]
	var p: Vector3 = work.wheel.to_global(Vector3(.46,0,.05))
	rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,pointer,rim,p,p))
	for i in range(1,19):
		var a := i*PI/36;var next: Vector3 = work.wheel.to_global(Vector3(cos(a)*.46,sin(a)*.46,.05))
		rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.MOVED,pointer,rim,next,p));p=next;work.advance_motion(1.0/60)
	check("reachable crank still manually overrides automatic motion",absf(work.angle_degrees-90)<.01)
	rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,pointer,rim,p,p))
	work.advance_motion(.66);work.advance_motion(1.0/12)
	check("automatic loop resumes after letting go",absf(work.angle_degrees-120)<.01)
	press(0);check("RUN control pauses the open disk",not work.auto_run)
	work.wheel.set_angle_degrees(0);work.refresh_controls()
	await photo("01-open-stand",work.to_global(Vector3(3.9,3.6,5.3)),work.to_global(Vector3(.2,1.45,.25)))
	camera.fov = 64
	await photo("02-floor-eye-view",work.to_global(Vector3(.2,1.65,3.55)),work.to_global(Vector3(.4,1.9,.3)))
	var report := {"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual floor59 draft: no enclosure,2m platter surface,grounded reachable controls,60RPM/12Hz,two fixed-cube loops,production desktop wheel override/release/RUN. No new physical-headset acceptance."}
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("ZOETROPE_RAISED_RESULT ",checks.size()," failures:",failed)
	quit(0 if failed.is_empty() else 1)
