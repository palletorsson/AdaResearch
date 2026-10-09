extends SceneTree
## Generated rays hit actual colliders, then GUI events drive shared controls
## and an existing artifact. This is desktop automation, not headset evidence.
const OUT := "res://doc/reports/interfaces-2026-09-21/physical-slider/screen-regression/"
const Wrapper = preload("res://commons/audio/rack_controls/vr_wrappers/VRRackControl.gd")
var checks := 0
var failures: Array[String] = []
var pointer: Node3D
var world: Node3D
var camera: Camera3D
var actions := 0

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	print("WRAPPER ", "PASS " if ok else "FAIL ", message)
	if not ok: failures.append(message)

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(.08, .10, .12)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(.9, .93, 1)
	env.environment.ambient_light_energy = .8
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	world.add_child(light)
	pointer = Node3D.new()
	world.add_child(pointer)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 40
	world.add_child(camera)
	root.msaa_3d = Viewport.MSAA_4X
	var slider := make("RackSliderH", Vector3(-1, 1.2, 0))
	slider.set_param_name("RATE")
	slider.set_normalized_value(.25)
	world.add_child(slider)
	var snap := make("RackSliderStepped", Vector3(-.65, 1.2, 0))
	snap.set_step_count(6)
	snap.set_normalized_value(.37)
	world.add_child(snap)
	var spring := make("RackSliderBipolar", Vector3(-.4, 1.2, 0))
	world.add_child(spring)
	var meter := make("RackMeter", Vector3(-.15, 1.2, 0))
	world.add_child(meter)
	var label := make("RackLabel", Vector3(.1, 1.2, 0))
	world.add_child(label)
	var disabled := make("RackSliderH", Vector3(.4, 1.2, 0))
	disabled.pointer_enabled = false
	world.add_child(disabled)
	for frame in 5: await physics_frame
	check(slider.get_control().control_label == "RATE", "Label configured before tree entry survives")
	check(is_equal_approx(slider.get_normalized_value(), .25), "Initial value configured before tree entry survives")
	check(slider.get_control().size == Vector2(180, 50), "Canonical layout units preserved inside the viewport")
	check(slider.get_control().scale == Vector2(2, 2), "Text scales with the control, not just its rectangle")
	check(is_equal_approx(snap.get_normalized_value(), .4), "Initial discrete value quantizes once against the configured six steps")
	var surf: Node3D = slider._pointer_surface
	check(surf.get_node("HitShape").shape.size.is_equal_approx(Vector3(.18 * .92, .05 * .92, .004)), "Hit bounds match the visible screen inside its bezel")
	check(meter._pointer_surface == null and label._pointer_surface == null, "Passive meters and labels do not intercept pointers")
	check(disabled._pointer_surface == null, "Authored input opt-out remains available")
	await send(slider, Vector2(50, 17), XRToolsPointerEvent.Type.PRESSED)
	await send(slider, Vector2(130, 17), XRToolsPointerEvent.Type.MOVED)
	await send(slider, Vector2(130, 17), XRToolsPointerEvent.Type.RELEASED)
	check(is_equal_approx(slider.get_normalized_value(), .75), "Ray hit and rightward GUI drag yield 0.75")
	await send(snap, Vector2(30, 30), XRToolsPointerEvent.Type.PRESSED)
	await send(snap, Vector2(30, 30), XRToolsPointerEvent.Type.RELEASED)
	check(snap.get_normalized_value() == 1 and snap.get_control().steps == 6, "Wrapped six-step selection operates and persists")
	await send(spring, Vector2(30, 30), XRToolsPointerEvent.Type.PRESSED)
	print("RETURN_LIMIT_VALUE ", spring.get_normalized_value())
	check(is_equal_approx(spring.get_normalized_value(), 1), "Wrapped returning control reaches positive limit")
	var owner := pointer
	pointer = Node3D.new()
	world.add_child(pointer)
	await send(spring, Vector2(30, 142), XRToolsPointerEvent.Type.RELEASED)
	check(is_equal_approx(spring.get_normalized_value(), 1), "Another pointer cannot release the wrapped control")
	pointer.queue_free()
	pointer = owner
	await send(spring, Vector2(30, 30), XRToolsPointerEvent.Type.EXITED)
	check(spring.get_normalized_value() == .5, "Exiting wrapped screen returns its command to zero")
	await send(spring, Vector2(30, 30), XRToolsPointerEvent.Type.PRESSED)
	spring._pointer_surface.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await process_frame
	check(spring.get_normalized_value() == .5, "Focus loss cancels a held command")
	await send(spring, Vector2(30, 30), XRToolsPointerEvent.Type.PRESSED)
	pointer.queue_free()
	await process_frame
	await process_frame
	check(spring.get_normalized_value() == .5, "A removed pointer cannot leave a command stuck")
	pointer = Node3D.new()
	world.add_child(pointer)
	slider.rotation_degrees = Vector3(-18, 37, 12)
	slider.scale = Vector3(1.4, .8, 1.2)
	await physics_frame
	await send(slider, Vector2(30, 17), XRToolsPointerEvent.Type.PRESSED)
	await send(slider, Vector2(30, 17), XRToolsPointerEvent.Type.RELEASED)
	check(is_equal_approx(slider.get_normalized_value(), .125), "Rotation and nonuniform world scale preserve coordinate mapping")
	# Existing artifact-helper callback path, including the formerly missing signal.
	var helper := ArtifactControls.new()
	helper.position = Vector3(1, 1.2, 0)
	world.add_child(helper)
	var action: Node3D = helper.add_button("STEP", func(): actions += 1)
	var text_surface: Node3D = helper.add_label("status", "READY")
	for frame in 4: await physics_frame
	await send(action, Vector2(35, 15), XRToolsPointerEvent.Type.PRESSED)
	await send(action, Vector2(35, 15), XRToolsPointerEvent.Type.PRESSED)
	check(actions == 1, "ArtifactControls callback fires once on press, even with a duplicate event")
	await send(action, Vector2(35, 15), XRToolsPointerEvent.Type.RELEASED)
	check(actions == 1 and not action.get_control().is_pressed, "Button release resets feedback without repeating the action")
	await send(action, Vector2(35, 15), XRToolsPointerEvent.Type.PRESSED)
	await send(action, Vector2(35, 15), XRToolsPointerEvent.Type.EXITED)
	check(actions == 2 and not action.get_control().is_pressed, "A second click works; pointer exit resets its feedback")
	helper.update_label("status", "DONE")
	var display: Dictionary = text_surface.get_meta("status_surface")
	check(display.label.text == "DONE" and display.screen.mesh is QuadMesh, "Helper status updates a real 2D screen")
	check(helper.find_children("*", "Label3D", true, false).is_empty(), "Artifact helper creates no floating text")
	for child in [slider, snap, spring, meter, label, disabled, helper]: child.queue_free()
	await process_frame
	# A real consumer: its grammar implementation and provenance text are untouched.
	var grammar: Node3D = load("res://commons/artifacts/grammar_provenance/grammar_provenance.tscn").instantiate()
	grammar.use_physical_controls = false # Retained screen route has its own regression.
	grammar.generation_depth = 1
	world.add_child(grammar)
	for frame in 5: await physics_frame
	var selector: Node3D = grammar._controls._controls["DEPTH"]
	check(selector.get_control().steps == 6, "Grammar selector represents precisely six generations")
	check(grammar._immediate_meshes[0].surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == 10, "First generation has five actual rendered segments")
	await send(selector, Vector2(30, lerpf(142, 30, .2)), XRToolsPointerEvent.Type.PRESSED)
	await send(selector, Vector2(30, lerpf(142, 30, .2)), XRToolsPointerEvent.Type.RELEASED)
	check(grammar.generation_depth == 2, "Pointer input changes the existing artifact to generation two")
	check(grammar._immediate_meshes[0].surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == 50, "Receiver geometry changes to twenty-five segments")
	var status: Dictionary = grammar._controls._controls["depth_display"].get_meta("status_surface")
	check(status.label.text == "Depth: 2", "Grammar display reports the actual generation")
	check(grammar.find_children("*", "Label3D", true, false).is_empty(), "Grammar's text is on flat supported surfaces")
	camera.position = Vector3(.35, 1.60, 2.15)
	camera.look_at(Vector3(0, .86, 1.7))
	await capture("grammar-controls")
	camera.position = Vector3(0, 1.65, 2.1)
	camera.fov = 85
	camera.look_at(Vector3(0, .30, .4))
	await capture("grammar-artifact")
	var file := FileAccess.open(OUT + "checks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "headset_tested": false,
		"method": "Physics ray intersections -> screen pointer bridge -> viewport GUI input -> consumer callbacks -> rendered geometry"}, "\t"))
	file.close()
	print("WRAPPER_RESULT ", checks, " checks, ", failures.size(), " failures")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func make(type: String, at: Vector3) -> Node3D:
	var instance := Wrapper.new()
	instance.control_scene_path = "res://commons/audio/rack_controls/%s.tscn" % type
	instance.position = at
	return instance

func send(wrapper: Node3D, local: Vector2, type: int) -> void:
	var control: Control = wrapper.get_control()
	var pixel: Vector2 = control.get_global_transform() * local
	var dims: Vector2 = wrapper._screen_mesh.mesh.size
	var vp_size := Vector2(wrapper._viewport.size)
	var hit: Vector3 = wrapper._screen_mesh.to_global(Vector3((pixel.x / vp_size.x - .5) * dims.x,
		(.5 - pixel.y / vp_size.y) * dims.y, 0))
	var normal: Vector3 = wrapper._screen_mesh.global_basis.z.normalized()
	var query := PhysicsRayQueryParameters3D.create(hit + normal * .2, hit - normal * .02, (1 << 20) | (1 << 22))
	var result := world.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		check(false, "Ray missed " + wrapper.name)
		return
	check(result.collider == wrapper._pointer_surface, "Ray reaches " + wrapper.name + " screen")
	XRToolsPointerEvent.report(XRToolsPointerEvent.new(type, pointer, result.collider, result.position, result.position))
	await process_frame

func capture(tag: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + tag + ".png")
