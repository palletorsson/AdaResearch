extends "res://tools/probes/scale_zoetrope.gd"
var pointer: Node3D
func press(index: int) -> void:
	var area: Area3D = work.console.buttons[index].get_node("InteractableAreaButton")
	var p: Vector3 = area.global_position
	area.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,pointer,area,p,p))
	area.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,pointer,area,p,p))
func slide(index: int,value: float) -> void:
	var slider: Node3D = work.console.sliders[index]
	slider.set_normalized_value(0)
	var p: Vector3 = slider.to_global(Vector3.ZERO)
	var end: Vector3 = slider.to_global(Vector3(0,value*.18,0))
	slider.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,pointer,slider,p,p))
	slider.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.MOVED,pointer,slider,end,p))
	slider.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,pointer,slider,end,end))
func reset_motion(rate: float=60,clock: float=0) -> void:
	work.wheel.set_angle_degrees(0);work.motor_phase = 0;work.manual_cooldown = 0
	work.auto_run = true;work.reverse = false;work.set_rpm(rate);work.set_sample_hz(clock)
func pixels() -> Dictionary:
	await tick(2);await RenderingServer.frame_post_draw
	var im := root.get_texture().get_image();var count := 0;var sum_x := 0.0;var min_x := 10000;var max_x := -1
	for y in range(0,im.get_height(),2):
		for x in range(0,im.get_width(),2):
			var c := im.get_pixel(x,y)
			if c.g>.6 and c.g>c.r*2 and c.g>c.b*2:
				count+=1;sum_x+=x;min_x=mini(min_x,x);max_x=maxi(max_x,x)
	return {"count":count,"centre_x":sum_x/maxi(1,count),"width":maxi(0,max_x-min_x)}
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
	env.environment.ambient_light_color = Color("d9e2e8");env.environment.ambient_light_energy = .38
	scene.add_child(env)
	var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-40,-30,0);light.light_energy = .8;scene.add_child(light)
	camera = Camera3D.new();camera.fov = 60;scene.add_child(camera);camera.make_current()
	work = building.content.exhibits["59/hand-scale-zoetrope"].get_node("Artifact")
	pointer = Node3D.new();scene.add_child(pointer)
	var start: float = work.angle_degrees;await tick(15)
	check("default motor advances without a hand and blind starts off",work.auto_run and not work.shutter.visible and absf(work.angle_degrees-start)>5)
	work.set_process(false)
	var rates: Array = []
	for fps in [30,60,120]:
		reset_motion(10)
		for i in fps:work.advance_motion(1.0/fps)
		rates.append(work.angle_degrees)
	check("RPM uses elapsed time, same60deg at30/60/120Hz",rates.all(func(v):return absf(v-60)<.001))
	observations.delta_rates = rates
	reset_motion(60)
	var wheel: Node3D = work.wheel
	var rim: StaticBody3D = wheel.rotor.get_children().filter(func(n):return n is StaticBody3D)[0]
	var p: Vector3 = wheel.to_global(Vector3(.46,0,.05))
	rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,pointer,rim,p,p))
	for i in 30:work.advance_motion(1.0/30)
	check("desktop ownership blocks automatic drive while held",is_zero_approx(work.angle_degrees))
	for i in range(1,19):
		var a := i*PI/36;var next: Vector3 = wheel.to_global(Vector3(cos(a)*.46,sin(a)*.46,.05))
		rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.MOVED,pointer,rim,next,p));p=next
		work.advance_motion(1.0/60)
	check("hand still controls wheel directly while auto is enabled",absf(work.angle_degrees-90)<.01)
	rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,pointer,rim,p,p))
	work.advance_motion(.3);var held: float=work.angle_degrees;work.advance_motion(.36);work.advance_motion(.01)
	check("motor resumes after release delay without phase jump",absf(held-90)<.01 and absf(work.angle_degrees-93.6)<.01)
	press(0);check("real RUN button pauses and latches",not work.auto_run and not work.console.buttons[0].is_selected())
	slide(0,.5);observations.rpm_fader_value = work.motor_rpm
	check("production RPM fader controls quadratic0..3600 range",absf(work.motor_rpm-900)<.3)
	work.set_rpm(1200);check("speed range permits one cube per sample at240FPS",is_equal_approx(work.motor_rpm,1200))
	slide(1,3.0/7);check("production clock selector reaches24Hz",is_equal_approx(work.sample_hz,24))
	press(2);check("MATCH sets one cube per local sample and starts motor",work.auto_run and absf(work.motor_rpm-120)<.01 and is_zero_approx(fposmod(work.angle_degrees,30)))
	press(1);check("SHUTTER button enables real opaque mesh",work.shutter.visible and work.shutter_enabled)
	press(1);check("SHUTTER button removes blind for open comparison",not work.shutter.visible and not work.shutter_enabled)
	reset_motion(60,12);press(3);work.advance_motion(1.0/12)
	check("REVERSE changes motor direction",work.reverse and absf(work.angle_degrees-330)<.01)
	# Match at12Hz: every presented state advances one physical cube.
	reset_motion(60,12)
	var mesh_sizes: Array = [];var local_poses: Array = []
	for cube in work.cubes:mesh_sizes.append(cube.mesh.get_aabb().size);local_poses.append(cube.transform)
	var fixed := true;var aligned := true
	for i in 120:
		work.advance_motion(1.0/120)
		aligned = aligned and absf(wrapf(deg_to_rad(work.angle_degrees*12),-PI,PI))<.001
		for j in 12:fixed = fixed and work.cubes[j].mesh.get_aabb().size==mesh_sizes[j] and work.cubes[j].transform==local_poses[j]
	check("matched12Hz steps stay aligned and all cubes keep their own size",fixed and aligned)
	# Actual rendered front-frame widths, not a replacement scale animation.
	camera.fov = 36;camera.global_position = work.to_global(Vector3(0,1.45,3.3));camera.look_at(work.to_global(Vector3(0,1.2,1.25)))
	var ink := StandardMaterial3D.new();ink.albedo_color = Color.BLACK;ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var green := ink.duplicate() as StandardMaterial3D;green.albedo_color = Color.GREEN
	for cube in work.cubes:cube.material_override = ink
	reset_motion(60,12);var frames: Array = []
	for i in 12:
		var index := (12-i)%12;work.cubes[index].material_override = green
		frames.append(await pixels());work.cubes[index].material_override = ink
		work.advance_motion(1.0/12)
	var widths: Array = frames.map(func(f):return f.width)
	var centres: Array = frames.map(func(f):return f.centre_x)
	check("without blind,12 rendered sizes hold the same horizontal position",frames.all(func(f):return f.count>50) and centres.max()-centres.min()<4 and widths.max()>widths.min()*2.5)
	observations.open_matched_frames = frames
	# The same aperture with the physical shutter enabled still exposes frames.
	work.set_shutter(true);reset_motion(60,12);work.cubes[0].material_override = green
	var open_stats := await pixels();work.advance_motion(1.0/24)
	var before_step: float = work.angle_degrees;work.set_sample_hz(0);work.advance_motion(1.0/24)
	var blind_stats := await pixels()
	check("optional blind exposes aligned frame and occludes a half-frame",open_stats.count>50 and before_step==0 and blind_stats.count==0)
	for cube in work.cubes:cube.material_override = work.wood
	work.set_shutter(false)
	# Real render loops at requested caps. Report observed rates honestly.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var old_cap := Engine.max_fps;var render_runs: Array = []
	for cap in [30,60]:
		Engine.max_fps = cap;reset_motion(60);work.set_process(true);await tick(12)
		var previous: float = work.angle_degrees;var distance := 0.0;var time_start := Time.get_ticks_usec()
		for i in cap:
			await process_frame
			distance+=rad_to_deg(wrapf(deg_to_rad(work.angle_degrees-previous),-PI,PI));previous = work.angle_degrees
		var duration := float(Time.get_ticks_usec()-time_start)/1000000
		work.set_process(false)
		var observed := distance/duration
		render_runs.append({"requested_fps":cap,"observed_fps":float(cap)/duration,"degrees_per_second":observed,"duration":duration})
		check("real render loop%d cap keeps time-based360deg/s"%cap,absf(observed-360)<45)
	Engine.max_fps = old_cap;observations.render_runs = render_runs
	# Native XRTools grip must also suspend and release the motor.
	reset_motion(60);work.set_process(true)
	var origin := XROrigin3D.new();scene.add_child(origin)
	var controller := XRController3D.new();origin.add_child(controller)
	var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_transform = wheel.grip.global_transform;wheel.grip.pick_up(pickup);await tick(3)
	var xr_start: float = work.angle_degrees;await tick(12)
	check("XR grip ownership also suspends motor",wheel.grip.is_picked_up() and absf(work.angle_degrees-xr_start)<.01)
	for i in range(1,19):
		var a := i*PI/36;controller.global_position = wheel.to_global(Vector3(cos(a)*.48,sin(a)*.48,.29));await tick(2)
	check("XR hand turns the automatically driven disk",wheel.grip.is_picked_up() and absf(work.angle_degrees-xr_start)>70)
	wheel.grip.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick(6)
	check("XR release returns ownership cleanly",not wheel.grip.is_picked_up() and wheel.hinge.grabbed_handles.is_empty())
	origin.queue_free();work.set_process(false)
	# Saved part poses and configs remain independent; live auto groups can copy.
	check("four independently editable source groups include controls",work.part_defaults.size()==4 and work.part_defaults.has("PlaybackControls"))
	var spare: Node3D = load("res://commons/artifacts/scale_zoetrope/scale_zoetrope.tscn").instantiate();spare.position=at(4,0,5);scene.add_child(spare)
	spare.apply_grid_config({"only_parts":["DiskAndCrank","PlaybackControls"],"auto_run":true,"motor_rpm":120,"sample_hz":24,"shutter_enabled":false,"parts":{"DiskAndCrank":{"position":[.2,.3,-.1],"rotation":[0,51,0]}}})
	spare.set_process(false);spare.manual_cooldown=0;spare.advance_motion(1.0/24)
	check("copied moved/rotated mechanism retains playback settings",not spare.has_node("RoomShell") and spare.part_defaults.size()==2 and absf(spare.angle_degrees-30)<.01 and not spare.shutter.visible)
	spare.queue_free();await tick(2)
	reset_motion(60,12);work.match_clock();work.auto_run = false;work.refresh_controls();camera.fov = 62
	await photo("01-speed-and-clock-controls",work.to_global(Vector3(.85,1.8,3.8)),work.to_global(Vector3(.5,1.62,2.1)))
	camera.fov=36
	await photo("02-open-view-small",work.to_global(Vector3(0,1.45,3.3)),work.to_global(Vector3(0,1.2,1.25)))
	work.wheel.set_angle_degrees(180)
	await photo("03-open-view-large",work.to_global(Vector3(0,1.45,3.3)),work.to_global(Vector3(0,1.2,1.25)))
	work.set_shutter(true);work.wheel.set_angle_degrees(15)
	await photo("04-shutter-between-frames",work.to_global(Vector3(0,1.45,3.3)),work.to_global(Vector3(0,1.2,1.25)))
	work.set_shutter(false);reset_motion(60,24);work.match_clock();work.refresh_controls();camera.fov=44
	await photo("05-matched-clock-reading",work.to_global(Vector3(1.03,2.0,3.55)),work.console.global_position)
	var report := {"passed":failed.is_empty(),"checks":checks,"failed":failed,"observations":observations,"scope":"Actual floor59 source, production pointer buttons/faders, manual override and release, supplied-pose XR grip, time-based motion, local sample clocks, native rendered cube widths with shutter off/on, real measured render loops, copied part configuration. No physical-headset or subjective smoothness acceptance."}
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("ZOETROPE_PLAYBACK_RESULT ",checks.size()," failures:",failed)
	quit(0 if failed.is_empty() else 1)
