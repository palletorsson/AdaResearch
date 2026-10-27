extends "res://tools/probes/zoetrope_playback.gd"
func drag_wheel(control: Node3D,degrees: float) -> void:
	var rim: StaticBody3D = control.rotor.get_children().filter(func(n):return n is StaticBody3D)[0]
	var p: Vector3 = control.to_global(Vector3(.46,0,.05))
	rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,pointer,rim,p,p))
	for i in range(1,37):
		var a := deg_to_rad(degrees)*i/36;var next: Vector3 = control.to_global(Vector3(cos(a)*.46,sin(a)*.46,.05))
		rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.MOVED,pointer,rim,next,p));p=next
	rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,pointer,rim,p,p))
func xr_turn(control: Node3D) -> bool:
	var origin := XROrigin3D.new();scene.add_child(origin)
	var controller := XRController3D.new();origin.add_child(controller)
	var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_transform = control.grip.global_transform;control.grip.pick_up(pickup);await tick(3)
	var start: float = control.get_angle_degrees()
	for i in range(1,19):
		var a := i*PI/36;controller.global_position = control.to_global(Vector3(cos(a)*.48,sin(a)*.48,.29));await tick(2)
	var ok: bool = control.grip.is_picked_up() and absf(control.get_angle_degrees()-start)>60
	control.grip.let_go(pickup,Vector3.ZERO,Vector3.ZERO);origin.queue_free();await tick(2);return ok
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	Source.use_main_tower = true
	scene = Node3D.new();root.add_child(scene);current_scene = scene;root.size = Vector2i(1440,900)
	var building: Node3D = load("res://commons/void/architecture.gd").new();building.stream_content = true;scene.add_child(building)
	var draft: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("draft-rooms.json")))
	var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("before-rooms.json")))
	building.content.data.floors[59] = draft.floors[59];building.content.load_floor(59)
	var shown: Array[int] = [59];building.show_floor_window(shown);level_y = building.spec.levels[59]
	var env := WorldEnvironment.new();env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR;env.environment.background_color = Color("302e38")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color = Color("e8dfe6")
	env.environment.ambient_light_energy = .5;env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC;scene.add_child(env)
	var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-38,-28,0);light.light_energy = .8;light.shadow_enabled = true;scene.add_child(light)
	camera = Camera3D.new();camera.fov = 57;scene.add_child(camera);camera.make_current();await tick(12)
	work = building.content.exhibits["59/two-wheel-belt-drive"].get_node("Artifact")
	var preserved: bool = draft.floors[59].construction==before.floors[59].construction and draft.floors[59].props==before.floors[59].props
	for item in before.floors[59].artifacts:preserved = preserved and draft.floors[59].artifacts.has(item)
	check("one additive mechanism preserves every existing placement",preserved and draft.floors[59].artifacts.size()==before.floors[59].artifacts.size()+1)
	var start: float = work.angle_degrees;await tick(10)
	check("starts still for hand exploration",not work.auto_run and is_equal_approx(start,work.angle_degrees))
	work.set_process(false);pointer = Node3D.new();scene.add_child(pointer)
	work.wheel.set_angle_degrees(360)
	check("one large turn produces exactly two small turns in the same direction",absf(work.secondary.get_angle_degrees()-720)<.001)
	work.secondary.set_angle_degrees(-180)
	check("small wheel back-drives the large wheel at the inverse ratio",absf(work.wheel.get_angle_degrees()+90)<.001)
	work.wheel.set_angle_degrees(0);drag_wheel(work.wheel,90)
	check("real desktop drag on large wheel drives small wheel",absf(work.angle_degrees-90)<.01 and absf(work.secondary.get_angle_degrees()-180)<.01)
	work.wheel.set_angle_degrees(0);drag_wheel(work.secondary,180)
	check("real desktop drag on small wheel drives large wheel",absf(work.angle_degrees-90)<.01 and absf(work.secondary.get_angle_degrees()-180)<.01)
	work.wheel.set_angle_degrees(0)
	check("scaled large wheel accepts a supplied XR grip",await xr_turn(work.wheel))
	work.wheel.set_angle_degrees(0)
	check("scaled small wheel accepts a supplied XR grip and keeps ratio",await xr_turn(work.secondary) and absf(work.secondary.get_angle_degrees()-work.angle_degrees*2)<.01)
	work.wheel.set_angle_degrees(0);work.manual_cooldown = 0;work.motor_phase = 0
	slide(0,.5);press(0);work.manual_cooldown = 0
	for i in 60:work.advance_motion(1.0/60)
	check("shared15RPM motor turns large90deg and small180deg per second",absf(work.angle_degrees-90)<.02 and absf(work.secondary.get_angle_degrees()-180)<.02)
	press(1);work.advance_motion(.1)
	check("reverse changes both directions together",work.reverse and absf(work.angle_degrees-81)<.02 and absf(work.secondary.get_angle_degrees()-162)<.02)
	work.auto_run = false;work.wheel.set_angle_degrees(0)
	var old: Vector3 = work.belt_marks[0].position
	work.wheel.set_angle_degrees(30)
	var on_loop := true
	for mark in work.belt_marks:
		var nearest := 100.0
		for p in work.belt_points:nearest = minf(nearest,mark.position.distance_to(p))
		on_loop = on_loop and nearest<.28
	check("belt witnesses actually travel continuously with the shared wheel input",old.distance_to(work.belt_marks[0].position)>.4 and on_loop and work.belt_points[0].is_equal_approx(work.belt_points[-1]))
	# Local belt lengths equal straight external tangents plus unequal-circle wraps.
	var alpha := acos(.55/3.2)
	var expected := 2*sqrt(3.2*3.2-.55*.55)+.55*2*alpha+1.1*(TAU-2*alpha)
	check("belt follows the actual unequal-radius tangent loop",absf(work.belt_length-expected)<.003)
	observations.ratio = 2;observations.belt_length = work.belt_length
	# Copying only a panel must not leave its missing drive running.
	var panel: Node3D = load("res://commons/artifacts/belt_drive/belt_drive.tscn").instantiate();scene.add_child(panel)
	panel.apply_grid_config({"only_parts":["PlaybackControls"]});panel._process(.1);panel._on_parameter(1,.5)
	check("independently copied control panel loads without its mechanism",panel.part_defaults.size()==1)
	panel.queue_free();await tick(2)
	var walker: CharacterBody3D = load("res://commons/void/walker.gd").new();scene.add_child(walker)
	walker.set_process_unhandled_input(false);walker.desktop_pointer.enabled = false;walker.desktop_pointer.set_process_input(false);walker.scripted_input = true
	walker.position = at(-1.35,.06,2.1);await tick(8)
	var clear := true
	for target in [at(.65,0,2.1),at(2.7,0,2.1)]:
		var reached := false
		for i in 300:
			var delta: Vector3 = target-walker.position;delta.y = 0
			if delta.length()<.15:reached = true;break
			walker.drive = Vector2(delta.x,delta.z).normalized()*.5;await tick()
		clear = clear and reached
	walker.drive = Vector2.ZERO;walker.queue_free();await tick(2)
	check("real visitor capsule passes across the front with original objects intact",clear)
	work.wheel.set_angle_degrees(30);work.refresh_controls()
	await photo("01-two-wheels-one-belt",work.to_global(Vector3(4.5,3.9,6.4)),work.to_global(Vector3(-.55,1.4,.3)))
	camera.fov = 64
	await photo("02-belt-drive-on-floor59",at(9.5,8.4,10.5),at(1,1.2,-.5))
	var report := {"passed":failed.is_empty(),"checks":checks,"failed":failed,"observations":observations,"scope":"Actual floor59 draft, desktop input on both wheels, supplied XR grips at both physical scales, inverse coupling, shared motor, tangent belt and real capsule access. Ideal kinematics; no physical-headset or belt-traction claim."}
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("BELT_DRIVE_RESULT ",checks.size()," failures:",failed);quit(0 if failed.is_empty() else 1)
