extends "res://tools/probes/zoetrope_playback.gd"
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	Source.use_main_tower = true
	scene = Node3D.new();root.add_child(scene);current_scene = scene;root.size = Vector2i(1440,900)
	var building: Node3D = load("res://commons/void/architecture.gd").new()
	building.stream_content = true;scene.add_child(building)
	var draft: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("draft-rooms.json")))
	var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("before-rooms.json")))
	building.content.data.floors[59] = draft.floors[59];building.content.load_floor(59)
	var shown: Array[int] = [59];building.show_floor_window(shown);level_y = building.spec.levels[59]
	var env := WorldEnvironment.new();env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR;env.environment.background_color = Color("343039")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color = Color("e8dde6")
	env.environment.ambient_light_energy = .65;scene.add_child(env)
	var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-38,-28,0);light.light_energy = 1.1;light.shadow_enabled = true;scene.add_child(light)
	camera = Camera3D.new();camera.fov = 56;scene.add_child(camera);camera.make_current();await tick(12)
	work = building.content.exhibits["59/torus-crank-study"].get_node("Artifact")
	var sleeve: Node3D = building.content.exhibits["59/barber-pillar-south"].get_node("Artifact")
	var other: Node3D = building.content.exhibits["59/barber-pillar-north"].get_node("Artifact")
	var unchanged: bool = draft.floors[59].construction==before.floors[59].construction and draft.floors[59].props==before.floors[59].props
	for a in before.floors[59].artifacts:unchanged = unchanged and draft.floors[59].artifacts.has(a)
	check("all visitor placements and construction preserved; only three occurrences added",unchanged and draft.floors[59].artifacts.size()==before.floors[59].artifacts.size()+3)
	var start: float = work.angle_degrees;await tick(12)
	check("shared motor advances exposed mechanism",absf(work.angle_degrees-start)>1)
	work.set_process(false);work.auto_run = false
	var coupled := true;var min_stroke := 100.0;var max_stroke := -100.0
	for a in range(0,361,5):
		work.wheel.set_angle_degrees(a)
		min_stroke = minf(min_stroke,work.stroke);max_stroke = maxf(max_stroke,work.stroke)
		coupled = coupled and absf(work.connecting_rod.mesh.height-2.3)<.001 and absf(work.cylinder_carriage.position.y-1.85)<.001 and absf(work.cylinder_carriage.position.z)<.001 and absf(work.flywheel.rotation.z-deg_to_rad(a))<.001
	check("visible pin and finite rod produce 1.60m straight stroke with no second oscillator",coupled and absf(min_stroke)<.001 and absf(max_stroke-1.6)<.001)
	observations.stroke = [min_stroke,max_stroke]
	pointer = Node3D.new();scene.add_child(pointer)
	slide(0,.5);slide(1,.25)
	check("production RPM and phase controls operate the mechanism",absf(work.motor_rpm-15)<.03 and absf(work.angle_degrees-90)<.1 and not work.auto_run)
	var rim: StaticBody3D = work.wheel.rotor.get_children().filter(func(n):return n is StaticBody3D)[0]
	work.wheel.set_angle_degrees(0)
	var p: Vector3 = work.wheel.to_global(Vector3(.46,0,.05))
	rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,pointer,rim,p,p))
	for i in range(1,19):
		var a := i*PI/36;var next: Vector3 = work.wheel.to_global(Vector3(cos(a)*.46,sin(a)*.46,.05))
		rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.MOVED,pointer,rim,next,p));p=next
	rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,pointer,rim,p,p))
	check("desktop wheel drag drives the exposed crank",absf(work.angle_degrees-90)<.01)
	var origin := XROrigin3D.new();scene.add_child(origin)
	var controller := XRController3D.new();origin.add_child(controller)
	var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	work.wheel.set_angle_degrees(0);controller.global_transform = work.wheel.grip.global_transform
	work.wheel.grip.pick_up(pickup);await tick(3)
	for i in range(1,19):
		var a := i*PI/36;controller.global_position = work.wheel.to_global(Vector3(cos(a)*.48,sin(a)*.48,.29));await tick(2)
	check("supplied XR hand drives the same crank and rod",work.wheel.grip.is_picked_up() and absf(work.angle_degrees)>60)
	work.wheel.grip.let_go(pickup,Vector3.ZERO,Vector3.ZERO);origin.queue_free()
	sleeve.set_process(false);other.set_process(false);sleeve.phase = 0;other.phase = 0
	sleeve._process(1);other._process(1)
	check("pillar sleeves physically rotate in opposing directions without translating",sleeve.rotor.rotation.y>0 and other.rotor.rotation.y>PI and sleeve.rotor.position==Vector3.ZERO and sleeve._stripe_mat.uv1_offset==Vector3.ZERO)
	check("pink red white stripe image and two independently editable groups",sleeve._stripe_mat.albedo_texture!=null and sleeve.stripe_color_a==Color("d52b54") and sleeve.stripe_color_b==Color("ed8fba") and sleeve.part_defaults.size()==2 and work.part_defaults.size()==2)
	# Full crank sweep stays on the east slab, outside both shafts. Sleeves are
	# intentionally centered on existing pillars, not new collision obstacles.
	var b: AABB = work.global_transform*AABB(Vector3(-3.4,0,-.62),Vector3(6.7,3.25,2.65))
	check("whole crank sweep fits east bay with walking clearance from shaft",b.position.x>13.3 and b.end.x<20.2 and b.position.z> -5.5 and b.end.z<.2)
	# A real capsule approaches the crank and passes in front without removing
	# the original pickup-ramp, floor, shaft or pillar collisions.
	var visitor: CharacterBody3D = load("res://commons/void/walker.gd").new();scene.add_child(visitor)
	visitor.set_process_unhandled_input(false);visitor.desktop_pointer.enabled = false;visitor.desktop_pointer.set_process_input(false);visitor.scripted_input = true
	visitor.position = at(13.2,.06,.65);await tick(8)
	var clear := true
	for target in [at(14.8,0,.65),at(18.5,0,.65),at(20.2,0,.65)]:
		var reached := false
		for i in 300:
			var delta: Vector3 = target-visitor.position;delta.y = 0
			if delta.length()<.15:reached = true;break
			visitor.drive = Vector2(delta.x,delta.z).normalized()*.5;await tick()
		clear = clear and reached
	visitor.drive = Vector2.ZERO;visitor.queue_free();await tick(3)
	check("visitor can approach wheel and walk across the entire front",clear)
	# A copied group must also load when its companion is omitted in the editor.
	var controls_only: Node3D = load("res://commons/artifacts/torus_piston/torus_piston.tscn").instantiate();scene.add_child(controls_only)
	controls_only.apply_grid_config({"only_parts":["PlaybackControls"]});controls_only._process(.2);controls_only._on_parameter(1,.5)
	var mounts_only: Node3D = load("res://commons/artifacts/pillar_barber_roll/pillar_barber_roll.tscn").instantiate();scene.add_child(mounts_only)
	mounts_only.apply_grid_config({"only_parts":["PillarMount"]});mounts_only._process(.2)
	check("separately copied control panel and pillar mount load without their moving group",controls_only.part_defaults.size()==1 and mounts_only.part_defaults.size()==1)
	controls_only.queue_free();mounts_only.queue_free();await tick(2)
	work.wheel.set_angle_degrees(35);work.refresh_controls()
	await photo("01-wheel-cylinder-torus",at(20.5,4.6,5.4),work.to_global(Vector3(-.4,1.55,.15)))
	camera.fov = 60
	await photo("02-pillar-barber-rolls",at(20,5.1,9),at(14,2.8,0))
	await photo("03-east-bay-studies",at(20.5,9.8,12),at(14.5,1.5,-1))
	var report := {"passed":failed.is_empty(),"checks":checks,"failed":failed,"observations":observations,"scope":"Existing floor59 draft, finite-rod geometry, actual desktop controls, supplied XR poses, and real walking capsule. No physical headset or force solver claim."}
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("SPINNING_STUDIES_RESULT ",checks.size()," failures:",failed);quit(0 if failed.is_empty() else 1)
