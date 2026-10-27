extends SceneTree
const Source = preload("res://commons/void/room_source.gd")
var out := ""
var checks: Array = []
var failed: Array = []
var observations: Dictionary = {}
var camera: Camera3D
var scene: Node3D
var level_y := -354.0
func _initialize() -> void:run.call_deferred()
func check(label: String, ok: bool) -> void:
	checks.append({"name":label,"passed":ok});print("YOKE_CHECK ",label," ",ok)
	if not ok:failed.append(label)
func tick(n := 1) -> void:
	for i in n:await physics_frame;await process_frame
func at(x: float,y: float,z: float) -> Vector3:return Vector3(x,level_y+y,z)
func photo(id: String,eye: Vector3,target: Vector3) -> void:
	camera.make_current();camera.global_position = eye;camera.look_at(target)
	await tick(3);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(id+".png"))
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
	level_y = building.spec.levels[59]
	root.size = Vector2i(1440,900)
	var env := WorldEnvironment.new();env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR;env.environment.background_color = Color("30383f")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("d9e2e8");env.environment.ambient_light_energy = .38
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC;scene.add_child(env)
	var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-40,-30,0)
	light.light_energy = .9;light.shadow_enabled = true;scene.add_child(light)
	camera = Camera3D.new();camera.fov = 52;scene.add_child(camera)
	await tick(30)
	var work: Node3D = building.content.exhibits["59/hand-sine-yoke"].get_node("Artifact")
	var wheel: Node3D = work.wheel
	check("standard floor and all21 originals plus one converter",building.spec.width == 42 and building.spec.shafts.size() == 2 and draft.floors[59].artifacts.size() == 22)
	check("wheel exposes native XRTools crank grip",wheel.grip.is_xr_class("XRToolsInteractableHandle") and wheel.hinge.grabbed_handles.is_empty())
	var still: float = work.yoke.position.y;await tick(60)
	check("no clock or motor moves an untouched wheel",is_equal_approx(work.yoke.position.y,still) and is_equal_approx(work.angle_degrees,-25))
	var owner := Node3D.new();scene.add_child(owner)
	var old: Vector3 = wheel.to_global(Vector3(.46,0,.05))
	wheel.set_angle_degrees(0)
	# Real production pointer forwarding from a wheel-rim collider.
	var rim: StaticBody3D = wheel.rotor.get_children().filter(func(n):return n is StaticBody3D)[0]
	rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,owner,rim,old,old))
	var maximum_error := 0.0;var low := INF;var high := -INF
	for i in range(1,145):
		var angle := i*TAU/72
		var next: Vector3 = wheel.to_global(Vector3(cos(angle)*.46,sin(angle)*.46,.05))
		rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.MOVED,owner,rim,next,old))
		old = next
		maximum_error = maxf(maximum_error,absf(work.yoke.position.y-work.crank_radius*sin(angle)))
		low = minf(low,work.yoke.position.y);high = maxf(high,work.yoke.position.y)
	rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,owner,rim,old,old))
	check("desktop rim drag makes two complete continuous turns",absf(work.angle_degrees-720)<.01)
	check("visible pin constrains exact sine projection over two turns",maximum_error<.0001)
	check("cube travels .76m with the yoke",absf(high-low-.76)<.0001 and work.cube.get_parent()==work.yoke)
	check("cube clears upper and lower support through full stroke",1.25+low-work.cube_edge*.5>.65 and 1.25+high+work.cube_edge*.5<1.85)
	check("pointer release relinquishes ownership",wheel._pointer == null and not wheel.is_processing())
	# Reverse through an atan seam rather than teleport the output.
	old = wheel.to_global(Vector3(.46,0,.05))
	rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,owner,rim,old,old))
	for i in range(1,19):
		var angle := -i*PI/36
		var next: Vector3 = wheel.to_global(Vector3(cos(angle)*.46,sin(angle)*.46,.05))
		rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.MOVED,owner,rim,next,old));old = next
	rim.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,owner,rim,old,old))
	check("reverse hand motion lowers cube to bottom of stroke",absf(work.yoke.position.y+.38)<.0001)
	still = work.yoke.position.y;await tick(30)
	check("release holds the chosen phase",is_equal_approx(still,work.yoke.position.y))
	observations.projection = {"max_error_metres":maximum_error,"stroke_metres":high-low,"pointer_turns":2}
	owner.queue_free()
	# Use actual XRTools pickup and a supplied controller pose, without headset.
	wheel.set_angle_degrees(0)
	var origin := XROrigin3D.new();scene.add_child(origin)
	var controller := XRController3D.new();origin.add_child(controller)
	var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate()
	controller.add_child(pickup);controller.global_transform = wheel.grip.global_transform
	wheel.grip.pick_up(pickup);await tick(2)
	check("XRTools pickup owns the crank handle",wheel.grip.is_picked_up() and wheel.hinge.grabbed_handles.size()==1)
	# Small supplied movements stay within the real snap-distance contract.
	for i in range(1,19):
		var angle := i*PI/36
		controller.global_position = wheel.to_global(Vector3(cos(angle)*.48,sin(angle)*.48,.29))
		await tick(2)
	check("supplied XR hand turns wheel and raises cube",work.yoke.position.y>.36 and wheel.grip.is_picked_up())
	wheel.grip.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick(2)
	check("XR release holds cube and restores grab layer",not wheel.grip.is_picked_up() and (wheel.grip.collision_layer&(1<<18))!=0)
	origin.queue_free()
	var pose: Transform3D = work.transform
	work.position += Vector3(1.2,.3,-.5);work.rotation_degrees.y = 73
	wheel.set_angle_degrees(42)
	var cube_local: Vector3 = work.mechanism.to_local(work.cube.global_position)
	check("moved rotated artifact keeps local coupling at negative floor",absf(cube_local.y-.38*sin(deg_to_rad(42)))<.0001)
	work.transform = pose
	check("support and mechanism are independently editable groups",work.part_defaults.keys().size()==2 and work.part_defaults.has("Support") and work.part_defaults.has("Mechanism"))
	var spare: Node3D = load("res://commons/artifacts/sine_yoke/sine_yoke.tscn").instantiate()
	spare.position = at(4,0,5);scene.add_child(spare)
	spare.apply_grid_config({"only_parts":["Mechanism"],"parts":{"Mechanism":{"position":[.2,1.4,-.3],"rotation":[0,51,0]}}})
	await tick(3);spare.wheel.set_angle_degrees(45)
	var moved_pin: Vector3 = spare.mechanism.to_local(spare.pin.global_position)
	check("copied moved rotated mechanism retains pin slot alignment",absf(moved_pin.y-spare.yoke.position.y)<.0001)
	check("isolated mechanism has no invisible support or colliders",not spare.has_node("Support") and spare.part_defaults.keys()==["Mechanism"])
	spare.queue_free();await tick(2)
	# Front approach and a complete bypass around the occupied foot box.
	var visitor: CharacterBody3D = load("res://commons/void/walker.gd").new();scene.add_child(visitor)
	visitor.set_process_unhandled_input(false);visitor.desktop_pointer.enabled = false
	visitor.desktop_pointer.set_process_input(false);visitor.scripted_input = true
	visitor.position = at(-3.8,.06,7.3);await tick(10)
	var clear := true
	for target in [at(-1.8,0,7.3),at(-.65,0,7.1),at(-.65,0,4.8),at(-3.6,0,4.8),at(-3.6,0,7.3)]:
		var reached := false
		for i in 260:
			var diff: Vector3 = target-visitor.global_position;diff.y = 0
			if diff.length()<.12:reached = true;break
			visitor.drive = Vector2(diff.x,diff.z).normalized()*.6;await tick()
		if not reached:clear = false;break
	check("desktop body reaches front and walks around converter",clear)
	visitor.queue_free();await tick(2)
	wheel.set_angle_degrees(-25)
	await photo("01-hand-wheel-in-the-bay",at(-1.9,1.8,8.5),at(-1.9,1.05,5.9))
	camera.fov = 44
	await photo("02-visible-pin-and-slot",at(-1.65,1.65,7.85),at(-1.95,1.27,6.05))
	wheel.set_angle_degrees(90)
	await photo("03-cube-at-top-of-stroke",at(-1.65,1.65,7.85),at(-1.95,1.27,6.05))
	var report := {"passed":failed.is_empty(),"checks":checks,"failed":failed,"observations":observations,"scope":"Actual main-floor59, production rim pointer events, native XRTools pickup with supplied controller poses, negative-floor moved/rotated coupling and desktop capsule circulation. Ideal kinematic constraint; no force dynamics or physical-headset acceptance."}
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("SINE_YOKE_RESULT ",checks.size()," failures:",failed)
	quit(0 if failed.is_empty() else 1)
