extends "res://tools/probes/sine_yoke.gd"
var work: Node3D
func green_count() -> int:
	await tick(2);await RenderingServer.frame_post_draw
	var pixels := root.get_texture().get_image();var count := 0
	for y in range(0,pixels.get_height(),2):
		for x in range(0,pixels.get_width(),2):
			var color := pixels.get_pixel(x,y)
			if color.g>.6 and color.g>color.r*2 and color.g>color.b*2:count+=1
	return count
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	Source.use_main_tower = true
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	var building: Node3D = load("res://commons/void/architecture.gd").new()
	building.stream_content = true;scene.add_child(building)
	var draft: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("draft-rooms.json")))
	building.content.data.floors[59] = draft.floors[59]
	building.content.load_floor(59)
	var shown: Array[int] = [59];building.show_floor_window(shown)
	level_y = building.spec.levels[59];root.size = Vector2i(1440,900)
	var env := WorldEnvironment.new();env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR;env.environment.background_color = Color("30383f")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("d9e2e8");env.environment.ambient_light_energy = .38
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC;scene.add_child(env)
	var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-40,-30,0)
	light.light_energy = .9;light.shadow_enabled = true;scene.add_child(light)
	camera = Camera3D.new();camera.fov = 52;scene.add_child(camera)
	await tick(30)
	work = building.content.exhibits["59/hand-scale-zoetrope"].get_node("Artifact")
	# This older geometric/manual probe deliberately pauses the new motor.
	work.auto_run = false;work.set_shutter(true);work.wheel.set_angle_degrees(0)
	var wheel: Node3D = work.wheel
	check("one additive study on standard floor, original22 and27 modules retained",draft.floors[59].artifacts.size()==23 and draft.floors[59].construction.size()==27 and building.spec.width==42)
	var phases: Array = [];var shapes: Array = []
	for cube in work.cubes:phases.append(cube.transform);shapes.append(cube.mesh.get_aabb().size)
	var owner := Node3D.new();scene.add_child(owner)
	var rim: StaticBody3D = wheel.rotor.get_children().filter(func(n):return n is StaticBody3D)[0]
	var old: Vector3 = wheel.to_global(Vector3(.46,0,.05))
	rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,owner,rim,old,old))
	var coupled := true;var fixed := true
	for i in range(1,145):
		var angle := i*TAU/72
		var next: Vector3 = wheel.to_global(Vector3(cos(angle)*.46,sin(angle)*.46,.05))
		rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.MOVED,owner,rim,next,old));old = next
		coupled = coupled and absf(work.disk.rotation.y-deg_to_rad(work.angle_degrees))<.0001 and absf(work.shutter.rotation.z+deg_to_rad(work.angle_degrees*12))<.0001
		for j in 12:fixed = fixed and work.cubes[j].transform==phases[j] and work.cubes[j].mesh.get_aabb().size==shapes[j]
	rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,owner,rim,old,old))
	check("production desktop rim drag turns disk twice",absf(work.angle_degrees-720)<.01)
	check("physical sector shutter geared12 to1 to hand angle",coupled)
	check("all12 cubes retain fixed individual mesh sizes and local poses",fixed and work.frame_edges.min()<.161 and work.frame_edges.max()>.499)
	var shaft_clear := true
	for id in ["InputShaftFront","InputShaftDrop","UnderDeckAxle","UnderDeckDrive"]:
		var shaft: MeshInstance3D = work.drive.get_node(id)
		var bounds: AABB = work.drive.global_transform.affine_inverse()*shaft.global_transform*shaft.get_aabb()
		var x := clampf(0,bounds.position.x,bounds.end.x);var z := clampf(0,bounds.position.z,bounds.end.z)
		shaft_clear = shaft_clear and (bounds.end.y<.95 or Vector2(x,z).length()>1.65)
	check("input transmission stays below or outside all cube swept space",shaft_clear)
	var still: float = work.angle_degrees;await tick(30)
	check("release holds phase with automatic drive paused",is_equal_approx(still,work.angle_degrees) and wheel._pointer==null)
	wheel.set_angle_degrees(0)
	old = wheel.to_global(Vector3(.46,0,.05))
	rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,owner,rim,old,old))
	for i in range(1,19):
		var angle := -i*PI/36
		var next: Vector3 = wheel.to_global(Vector3(cos(angle)*.46,sin(angle)*.46,.05))
		rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.MOVED,owner,rim,next,old));old = next
	rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,owner,rim,old,old))
	check("reverse hand motion reverses disk",absf(work.angle_degrees+90)<.01)
	wheel.set_angle_degrees(0)
	var origin := XROrigin3D.new();scene.add_child(origin)
	var controller := XRController3D.new();origin.add_child(controller)
	var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate()
	controller.add_child(pickup);controller.global_transform = wheel.grip.global_transform
	wheel.grip.pick_up(pickup);await tick(2)
	check("native XRTools pickup owns crank",wheel.grip.is_picked_up())
	for i in range(1,19):
		var angle := i*PI/36
		controller.global_position = wheel.to_global(Vector3(cos(angle)*.48,sin(angle)*.48,.29));await tick(2)
	check("supplied XR hand rotates the disk",work.angle_degrees>80 and wheel.grip.is_picked_up())
	wheel.grip.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick(2)
	check("XR release restores handle",not wheel.grip.is_picked_up() and (wheel.grip.collision_layer&(1<<18))!=0)
	origin.queue_free()
	var shell_pose: Transform3D = work.shell.global_transform
	work.service_handle.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,owner,work.service_handle,work.service_handle.global_position,work.service_handle.global_position))
	await tick(45)
	check("real side latch opens collision leaf, fixed room stays put",work.service_open and absf(work.panel_leaf.rotation_degrees.y-95)<.01 and work.shell.global_transform==shell_pose and work.panel_leaf.get_children().any(func(c):return c is CollisionShape3D))
	work.set_service_open(false,true)
	var pose: Transform3D = work.transform
	work.position+=Vector3(.2,.3,.1);work.rotation_degrees.y = 73;wheel.set_angle_degrees(42)
	check("negative-floor moved rotated assembly retains local coupling",absf(work.disk.rotation_degrees.y-42)<.001 and absf(work.shutter.rotation_degrees.z+504)<.001)
	work.transform = pose
	var spare: Node3D = load("res://commons/artifacts/scale_zoetrope/scale_zoetrope.tscn").instantiate()
	spare.position = at(4,0,5);scene.add_child(spare)
	spare.apply_grid_config({"auto_run":false,"only_parts":["DiskAndCrank"],"parts":{"DiskAndCrank":{"position":[.2,.3,-.1],"rotation":[0,51,0]}}})
	spare.wheel.set_angle_degrees(-60)
	check("isolated editable disk keeps coupling and removes shell colliders",spare.part_defaults.keys()==["DiskAndCrank"] and not spare.has_node("RoomShell") and absf(spare.disk.rotation_degrees.y+60)<.001)
	spare.queue_free();await tick(2)
	# Actual capsule approach, from floor centre to crank and service latch.
	var visitor: CharacterBody3D = load("res://commons/void/walker.gd").new();scene.add_child(visitor)
	visitor.set_process_unhandled_input(false);visitor.desktop_pointer.enabled = false;visitor.desktop_pointer.set_process_input(false);visitor.scripted_input = true
	visitor.position = at(1.3,.06,-2.1);await tick(8)
	var clear := true
	for target in [at(1.3,0,-2.92),at(4.1,0,-2.92),at(4.1,0,-4.3),at(4.1,0,-8.2),at(-1.7,0,-8.2),at(-1.7,0,-2.92),at(1.3,0,-2.92)]:
		var reached := false
		for i in 350:
			var diff: Vector3 = target-visitor.global_position;diff.y = 0
			if diff.length()<.13:reached = true;break
			visitor.drive = Vector2(diff.x,diff.z).normalized()*.55;await tick()
		if not reached:clear = false;break
	check("desktop capsule reaches front and service side",clear)
	observations.visitor_final = [visitor.position.x,visitor.position.y,visitor.position.z]
	visitor.queue_free();await tick(2)
	check("closed enclosure stays behind shaft openings and below ceiling",work.global_position.z+2.1<-3.0 and work.global_position.y+4.0<level_y+6 and work.global_position.x-2.1>-7.5 and work.global_position.x+4.2<7.5)
	# Pixel evidence: colour one physical cube at a time, never hide geometry.
	camera.make_current();camera.fov = 36
	camera.global_position = work.to_global(Vector3(0,1.45,3.3));camera.look_at(work.to_global(Vector3(0,1.20,1.25)))
	var ink := StandardMaterial3D.new();ink.albedo_color = Color.BLACK;ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var green := ink.duplicate() as StandardMaterial3D;green.albedo_color = Color.GREEN
	for cube in work.cubes:cube.material_override = ink
	var views: Array = []
	for frame in [0,3,6]:
		wheel.set_angle_degrees(-frame*30.0);var counts: Array = []
		for i in 12:
			work.cubes[i].material_override = green
			counts.append(await green_count());work.cubes[i].material_override = ink
		# The open disk deliberately allows neighbouring/opposite cubes now.
		check("slit exposes front frame%d on the open disk"%frame,counts[frame]>20)
		views.append({"frame":frame,"green_pixel_samples":counts})
	wheel.set_angle_degrees(15)
	for cube in work.cubes:cube.material_override = green
	var closed: int = await green_count()
	check("physical shutter blocks every cube between frames",closed==0)
	observations.optical = {"aligned":views,"shutter_closed_samples":closed,"method":"One cube at a time green in actual rendered view; all other geometry retained. Every second pixel sampled."}
	camera.global_position = work.to_global(Vector3(3.7,2.2,.6));camera.look_at(work.to_global(Vector3(.5,1.3,0)))
	work.set_service_open(true,true)
	var service_visible: int = await green_count()
	work.set_service_open(false,true)
	var service_closed: int = await green_count()
	check("service panel really reveals interior, closed leaf conceals it",service_visible>100 and service_closed==0)
	observations.service_view = {"open_green_samples":service_visible,"closed_green_samples":service_closed}
	for cube in work.cubes:cube.material_override = work.wood
	wheel.set_angle_degrees(0)
	await photo("01-fixed-room-and-hand-crank",at(5.6,3.4,-1.9),at(1.2,1.9,-5.1))
	camera.fov = 36
	await photo("02-slit-small-cube",work.to_global(Vector3(0,1.45,3.3)),work.to_global(Vector3(0,1.2,1.25)))
	wheel.set_angle_degrees(-180)
	await photo("03-slit-large-cube",work.to_global(Vector3(0,1.45,3.3)),work.to_global(Vector3(0,1.2,1.25)))
	work.set_service_open(true,true);wheel.set_angle_degrees(-45);camera.fov = 55
	await photo("04-service-panel-open",work.to_global(Vector3(3.7,2.2,.6)),work.to_global(Vector3(.5,1.3,0)))
	# Inspection only: separate shell group lifted, not saved as the playing pose.
	work.shell.visible = false;work.panel.visible = false
	await photo("05-twelve-fixed-cubes-inspection",at(3.8,4.4,-2.5),at(1,1.2,-5.4))
	work.shell.visible = true;work.panel.visible = true;work.set_service_open(false,true);wheel.set_angle_degrees(0)
	owner.queue_free()
	var report := {"passed":failed.is_empty(),"checks":checks,"failed":failed,"observations":observations,"scope":"Native main floor59; production pointer, supplied-pose XRTools grip, physical panel, fixed frame geometry, actual optical isolation renders, moved/rotated editable assembly, desktop capsule access. Ideal gearing; physical headset and perceptual smoothness are not accepted by these tests."}
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("SCALE_ZOETROPE_RESULT ",checks.size()," failures:",failed)
	quit(0 if failed.is_empty() else 1)
