extends SceneTree
## Exercise the shared 2D controls through actual 3D hit -> viewport GUI dispatch.
const OUT := "res://doc/reports/interfaces-2026-09-20/rack-wrapper-pilot/module-regression/"
var failures: Array[String] = []
var checks := 0
var events: Array[float] = []
var pointer: Node3D
var reference: Node3D
var camera: Camera3D

func _initialize() -> void: run.call_deferred()
func check(ok: bool, description: String) -> void:
	checks += 1
	print("RACK_INPUT ", "PASS " if ok else "FAIL ", description)
	if not ok: failures.append(description)

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(.06, .08, .10)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(.9, .93, 1)
	env.environment.ambient_light_energy = .8
	world.add_child(env)
	var lamp := DirectionalLight3D.new()
	lamp.rotation_degrees = Vector3(-35, -25, 0)
	lamp.light_energy = 1.3
	world.add_child(lamp)
	var demo: Node3D = load("res://commons/interactables/interactable_release_demo.tscn").instantiate()
	world.add_child(demo)
	reference = demo.get_node("ReleaseReference")
	pointer = Node3D.new()
	world.add_child(pointer)
	camera = Camera3D.new()
	world.add_child(camera)
	camera.current = true
	camera.fov = 40
	camera.position = Vector3(.42, 1.65, 1.40)
	camera.look_at(Vector3(0, 1.30, -.07))
	root.msaa_3d = Viewport.MSAA_4X
	for frame in 8: await process_frame
	var face: Node3D = reference.face
	var stepped: Control = face.get_2d_control("choice")
	var spring: Control = face.get_2d_control("return")
	var retained: Control = face.get_2d_control("hold")
	check(stepped.size.is_equal_approx(Vector2(108, 240)), "Configured control dimensions survive ready")
	check(stepped.steps == 5, "Factory preserves number of choices")
	check(spring.return_to_center and not retained.return_to_center, "Factory distinguishes signed range from return behaviour")
	stepped.value_changed.connect(func(v): events.append(v))
	stepped.set_normalized_value(.37)
	check(is_equal_approx(stepped.normalized_value, .25), "Setter emits an actual discrete value")
	check(events == [.25], "Receiver sees the same snapped value as the handle")
	stepped.normalized_value = .26
	check(events == [.25], "Property assignment quantizes without duplicate change events")
	stepped.steps = 3
	check(is_equal_approx(stepped.normalized_value, .5), "Changing step count requantizes the existing value")
	stepped.steps = 0
	check(stepped.steps == 2, "At least two valid endpoints")
	stepped.steps = 5
	stepped.set_normalized_value(-5)
	check(is_zero_approx(stepped.normalized_value), "Programmatic values clamp low")
	stepped.set_normalized_value(5)
	check(is_equal_approx(stepped.normalized_value, 1), "Programmatic values clamp high")
	# All choices through the real collider forwarding and GUI hit test.
	for i in 5:
		var value := i / 4.0
		await send(face, stepped, XRToolsPointerEvent.Type.PRESSED, value)
		check(is_equal_approx(stepped.normalized_value, value), "3D pointer reaches choice %d" % (i + 1))
		await send(face, stepped, XRToolsPointerEvent.Type.RELEASED, value)
		check(is_equal_approx(stepped.normalized_value, value), "Choice %d persists on release" % (i + 1))
	await send(face, retained, XRToolsPointerEvent.Type.PRESSED, .25)
	await send(face, retained, XRToolsPointerEvent.Type.RELEASED, .25)
	await send(face, spring, XRToolsPointerEvent.Type.PRESSED, .5)
	await send(face, spring, XRToolsPointerEvent.Type.MOVED, 1)
	check(is_equal_approx(spring.get_signed_value(), 1), "Upward drag gives +1 through the 3D viewport")
	check(is_equal_approx(reference.receivers[1].position.y, 1.67), "Command signal moves its visible receiver")
	var first_pointer := pointer
	pointer = Node3D.new()
	world.add_child(pointer)
	await send(face, spring, XRToolsPointerEvent.Type.MOVED, 0)
	await send(face, spring, XRToolsPointerEvent.Type.RELEASED, 0)
	await send(face, spring, XRToolsPointerEvent.Type.EXITED, 0)
	check(is_equal_approx(spring.get_signed_value(), 1), "A second pointer cannot move, release or cancel the active drag")
	pointer.queue_free()
	pointer = first_pointer
	await capture("held")
	await send(face, spring, XRToolsPointerEvent.Type.RELEASED, 1)
	check(is_zero_approx(spring.get_signed_value()), "Release sends zero to the receiver")
	check(is_equal_approx(reference.receivers[1].position.y, 1.54), "Release centres the visible marker")
	await send(face, spring, XRToolsPointerEvent.Type.PRESSED, 0)
	check(is_equal_approx(spring.get_signed_value(), -1), "Downward limit gives -1")
	await send(face, spring, XRToolsPointerEvent.Type.EXITED, 0)
	check(is_zero_approx(spring.get_signed_value()) and not spring._is_dragging, "Leaving the panel cancels the command")
	await send(face, spring, XRToolsPointerEvent.Type.MOVED, .8)
	check(is_zero_approx(spring.get_signed_value()), "Movement without a press cannot restart the command")
	await send(face, stepped, XRToolsPointerEvent.Type.PRESSED, .8)
	check(is_equal_approx(stepped.normalized_value, .75), "Pointer between notches emits the nearest discrete value")
	await send(face, stepped, XRToolsPointerEvent.Type.EXITED, .8)
	check(is_equal_approx(stepped.normalized_value, .75), "Leaving the panel preserves a discrete choice")
	await send(face, stepped, XRToolsPointerEvent.Type.PRESSED, 1)
	await send(face, stepped, XRToolsPointerEvent.Type.RELEASED, 1)
	await send(face, retained, XRToolsPointerEvent.Type.PRESSED, .25)
	await send(face, retained, XRToolsPointerEvent.Type.RELEASED, .25)
	check(is_equal_approx(retained.get_signed_value(), -.5), "Signed setting persists at -0.5 after release")
	check(is_equal_approx(reference.receivers[2].position.y, 1.475), "Retained receiver agrees with the selected setting")
	check(reference.readout.text.contains("-0.50"), "Flat readout reports actual receiver values")
	await capture("released")
	camera.position = Vector3(0, 1.40, .82)
	camera.look_at(Vector3(0, 1.10, 0))
	await capture("surface")
	# World-space conversion must survive a translated/rotated/scaled assembly.
	demo.position = Vector3(2, .3, -1)
	demo.rotation_degrees.y = 42
	demo.scale = Vector3.ONE * 1.3
	await send(face, stepped, XRToolsPointerEvent.Type.PRESSED, .25)
	await send(face, stepped, XRToolsPointerEvent.Type.RELEASED, .25)
	check(is_equal_approx(stepped.normalized_value, .25), "Transformed assembly maps the pointer to the same choice")
	await send(face, spring, XRToolsPointerEvent.Type.PRESSED, .75)
	check(is_equal_approx(spring.get_signed_value(), .5), "Transformed assembly maps the signed value correctly")
	await send(face, spring, XRToolsPointerEvent.Type.RELEASED, .75)
	check(is_zero_approx(spring.get_signed_value()), "Transformed assembly still releases to zero")
	check(reference.find_children("*", "Label3D", true, false).is_empty(), "All reference text is rendered on 2D surfaces")
	var collider: CollisionShape3D = face.get_node("PanelCollision").get_child(0)
	check(is_equal_approx(collider.shape.size.x, .576), "Collider matches the 57.6 cm panel")
	# Adjacent canonical controls retain their continuous scalar input.
	for type in ["H", "V"]:
		var control: Control = load("res://commons/audio/rack_controls/RackSlider%s.tscn" % type).instantiate()
		root.add_child(control)
		check(control.size == (Vector2(180, 50) if type == "H" else Vector2(60, 180)), "Default " + type + " keeps its canonical footprint")
		control.set_normalized_value(.123)
		check(is_equal_approx(control.normalized_value, .123), "Continuous " + type + " remains unsnapped")
		control.queue_free()
	# A configured continuous control must still get its GUI events after sizing.
	var other_face: Node3D = load("res://commons/audio/rack_controls/vr_wrappers/ModuleFaceTexture.gd").new()
	world.add_child(other_face)
	other_face.build({"hp_width": 24, "controls": [
		{"id": "continuous", "type": "slv", "x_hp": 12, "y_frac": .5, "width_hp": 6,
		"height_px": 240, "default": .5}]})
	for frame in 3: await process_frame
	var continuous: Control = other_face.get_2d_control("continuous")
	var top := 10.0 # Existing continuous slider metrics: 6px handle + 4px gap.
	var bottom: float = continuous.size.y - 34
	await send_at(other_face, continuous, XRToolsPointerEvent.Type.PRESSED, Vector2(54, lerpf(bottom, top, .123)))
	await send_at(other_face, continuous, XRToolsPointerEvent.Type.RELEASED, Vector2(54, lerpf(bottom, top, .123)))
	check(is_equal_approx(continuous.normalized_value, .123), "Configured continuous slider retains its precise value through GUI dispatch")
	var file := FileAccess.open(OUT + "checks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures,
		"input": "XRToolsPointerEvent -> PanelCollision -> ModuleFaceTexture -> SubViewport.push_input -> Control._gui_input -> value_changed -> receiver",
		"headset_tested": false}, "\t"))
	file.close()
	print("RACK_INPUT_RESULT ", checks, " checks, ", failures.size(), " failures")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func send(face: Node3D, control: Control, type: int, value: float) -> void:
	var limits: Vector2 = control._track_limits()
	var local := Vector2(control.size.x / 2, lerpf(limits.y, limits.x, value))
	await send_at(face, control, type, local)

func send_at(face: Node3D, control: Control, type: int, local: Vector2) -> void:
	var pixel: Vector2 = control.get_global_transform() * local
	var vp: Vector2 = Vector2(face._viewport.size)
	var hit: Vector3 = face.to_global(Vector3((pixel.x / vp.x - .5) * face._physical_w,
		(.5 - pixel.y / vp.y) * face._physical_h, 0))
	XRToolsPointerEvent.report(XRToolsPointerEvent.new(type, pointer, face.get_node("PanelCollision"), hit, hit))
	await process_frame

func capture(tag: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + tag + ".png")
