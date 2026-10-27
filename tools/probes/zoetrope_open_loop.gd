extends "res://tools/probes/scale_zoetrope.gd"

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
	env.environment.ambient_light_color = Color("d9e2e8");env.environment.ambient_light_energy = .38;scene.add_child(env)
	var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-40,-30,0);light.light_energy = .8;scene.add_child(light)
	camera = Camera3D.new();camera.fov = 60;scene.add_child(camera);camera.make_current()
	await tick(15)
	work = building.content.exhibits["59/hand-scale-zoetrope"].get_node("Artifact")
	check("automatic drive still loops with front shutter off",work.auto_run and not work.shutter.visible)
	# The rotating disk contains exactly its platter, 12 cubes and 12 markers.
	check("no central drum or radial partitions remain",work.cubes.size()==12 and work.disk.get_child_count()==25 and not work.disk.has_node("InnerFrameBackdrop"))
	work.set_process(false);work.wheel.set_angle_degrees(0);work.motor_phase = 0;work.manual_cooldown = 0
	work.reverse = false;work.set_sample_hz(0);work.set_rpm(60)
	var poses: Array = [];var sizes: Array = []
	for cube in work.cubes:poses.append(cube.transform);sizes.append(cube.mesh.get_aabb().size)
	var fixed := true;var wrapped := false;var previous := 0.0
	for frame in 240:
		work.advance_motion(1.0/120)
		if work.angle_degrees<previous:wrapped = true
		previous = work.angle_degrees
		for i in 12:fixed = fixed and work.cubes[i].transform==poses[i] and work.cubes[i].mesh.get_aabb().size==sizes[i]
	check("two automatic revolutions preserve every cube size and disk-local pose",fixed and wrapped and absf(work.angle_degrees)<.001)
	check("four independently editable groups remain",work.part_defaults.size()==4)
	work.auto_run = false;work.refresh_controls();work.wheel.set_angle_degrees(15)
	await photo("01-open-gaps",work.to_global(Vector3(0,1.45,3.3)),work.to_global(Vector3(0,1.2,1.25)))
	work.set_service_open(true,true);camera.fov = 60
	await photo("02-fixed-cubes-on-loop",work.to_global(Vector3(3.4,2.7,.65)),work.to_global(Vector3(.1,1.2,0)))
	work.set_service_open(false,true);work.wheel.set_angle_degrees(0);camera.fov = 62
	await photo("03-slit-and-controls",work.to_global(Vector3(.85,1.8,3.8)),work.to_global(Vector3(.5,1.62,2.1)))
	var report := {"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual floor59; divider-free geometry, two automatic disk revolutions, fixed individual cube meshes/local poses, four editable groups. Existing input code unchanged; not a new headset acceptance test."}
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("ZOETROPE_OPEN_LOOP_RESULT ",checks.size()," failures:",failed)
	quit(0 if failed.is_empty() else 1)
