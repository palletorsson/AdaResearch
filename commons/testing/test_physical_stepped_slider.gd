extends SceneTree
## Real ray targets and XR Tools grab-driver motion, without headset hardware.
const OUT := "res://doc/reports/interfaces-2026-09-21/physical-slider/"
var PhysicalSlider: Script
var checks := 0
var failures: Array[String] = []
var world: Node3D
var pointer: Node3D
var signals_received := 0
var camera: Camera3D

class TestGrabber extends Node3D:
	var picked_up_ranged := false
	var held: Node3D
	func drop_object() -> void:
		if held:
			held.let_go(self, Vector3.ZERO, Vector3.ZERO)
			held = null

func _initialize() -> void: run.call_deferred()
func check(condition: bool, description: String) -> void:
	checks += 1
	print("PHYSICAL ", "PASS " if condition else "FAIL ", description)
	if not condition: failures.append(description)

func settle() -> void:
	for frame in 5:
		await physics_frame
		await process_frame

func run() -> void:
	# Load XR-dependent scripts after the project autoloads exist.
	PhysicalSlider = load("res://commons/interactables/physical_stepped_slider.gd")
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
	world.add_child(camera)
	root.msaa_3d = Viewport.MSAA_4X
	# Exercise the complete selector range without repeatedly rebuilding the
	# existing million-segment generation-six grammar during input tests.
	var selector: Node3D = PhysicalSlider.new()
	selector.position = Vector3(0, .86, 1.7)
	selector.rotation_degrees.x = -55
	world.add_child(selector)
	await settle()
	selector.value_changed.connect(func(_value): signals_received += 1)
	check(selector._handle.global_basis.get_scale().is_equal_approx(Vector3.ONE), "Grab body has unit world scale on the inclined station")
	check(selector._track.slider_steps > 0 and selector.step_count == 6, "Six discrete stops include both ends")
	check(selector.find_children("*", "Label3D", true, false).is_empty(), "All lettering remains flat on surfaces")
	check(selector.find_children("*", "SubViewport", true, false).is_empty(), "Physical selector needs no continuously rendered screen")
	var grabber := TestGrabber.new()
	world.add_child(grabber)
	grabber.global_transform = selector._handle.global_transform
	grabber.held = selector._handle
	selector._handle.pick_up(grabber)
	check(selector._handle.is_picked_up() and selector._track.grabbed_handles.size() == 1, "XR Tools pickup activates the real handle driver")
	# Moving the grabber drives RemoteTransform -> handle -> slider -> artifact.
	for index in [1, 2, 3, 4, 5, 4, 3, 2, 1, 0]:
		grabber.global_position = selector._track.get_parent().to_global(Vector3(index * .036, 0, 0))
		await settle()
		print("GRAB_POSITION ", index, " value=", selector.get_normalized_value(), " position=", selector._track.position.x)
		check(is_equal_approx(selector.get_normalized_value(), index / 5.0) and is_equal_approx(selector._track.position.x, index * .036), "Grab reaches position %d and its physical stop" % (index + 1))
	check(signals_received == 10, "Holding each stop produces one change, without repeat updates")
	grabber.global_position = selector._track.get_parent().to_global(Vector3(.036, 0, 0))
	await settle()
	# Pointer input must not seize a held physical handle.
	selector.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED, pointer, selector, selector.to_global(Vector3(0, .09, .02)), selector.to_global(Vector3(0, .09, .02))))
	check(selector._pointer == null, "Direct grab owns the control over competing pointer input")
	grabber.drop_object()
	await settle()
	check(is_equal_approx(selector.get_normalized_value(), .2) and selector._handle.transform.is_equal_approx(Transform3D.IDENTITY), "Release parks the cap at stop two and resets the grab proxy")
	check(not selector._track.is_processing(), "Idle physical slider does no frame processing")
	# Actual collider hits, through the same pointer_event route as desktop/XR rays.
	await send(selector, -.054, XRToolsPointerEvent.Type.PRESSED)
	await send(selector, .09, XRToolsPointerEvent.Type.MOVED)
	await send(selector, .09, XRToolsPointerEvent.Type.RELEASED)
	check(is_equal_approx(selector.get_normalized_value(), 1), "Pointer drag reaches and retains the final stop")
	await send(selector, .09, XRToolsPointerEvent.Type.PRESSED)
	var owner := pointer
	pointer = Node3D.new()
	world.add_child(pointer)
	await send(selector, -.09, XRToolsPointerEvent.Type.MOVED)
	await send(selector, -.09, XRToolsPointerEvent.Type.RELEASED)
	check(is_equal_approx(selector.get_normalized_value(), 1) and selector._pointer == owner, "Another pointer cannot move or release the selection")
	pointer.queue_free()
	pointer = owner
	await send(selector, -.09, XRToolsPointerEvent.Type.MOVED)
	await send(selector, -.09, XRToolsPointerEvent.Type.EXITED)
	check(is_equal_approx(selector.get_normalized_value(), 0) and selector._pointer == null, "Reverse pointer drag and exit retain the first stop")
	await send(selector, -.09, XRToolsPointerEvent.Type.PRESSED)
	selector.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(selector._pointer == null, "Focus loss releases pointer ownership")
	await send(selector, -.09, XRToolsPointerEvent.Type.PRESSED)
	pointer.queue_free()
	await settle()
	check(selector._pointer == null and not selector.is_processing(), "Freed pointer cannot leave a drag active")
	selector.set_normalized_value(-2)
	check(selector.get_normalized_value() == 0, "External values clamp at minimum")
	selector.set_normalized_value(3)
	check(selector.get_normalized_value() == 1, "External values clamp at maximum")
	selector.queue_free()
	await process_frame
	var grammar: Node3D = load("res://commons/artifacts/grammar_provenance/grammar_provenance.tscn").instantiate()
	grammar.generation_depth = 1
	world.add_child(grammar)
	await settle()
	selector = grammar._controls._controls["DEPTH"]
	check(selector.get_script() == PhysicalSlider, "Museum artifact defaults to a physical selector")
	check(selector._handle.global_basis.get_scale().is_equal_approx(Vector3.ONE), "Actual station leaves the grab body at unit scale")
	grabber.global_transform = selector._handle.global_transform
	grabber.held = selector._handle
	selector._handle.pick_up(grabber)
	grabber.global_position = selector._track.get_parent().to_global(Vector3(.036, 0, 0))
	await settle()
	grabber.drop_object()
	check(grammar.generation_depth == 2 and grammar._immediate_meshes[0].surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == 50, "Real grab changes generation one to two and renders twenty-five branches")
	var status: Dictionary = grammar._controls._controls["depth_display"].get_meta("status_surface")
	check(status.label.text == "Depth: 2", "Readout agrees with the grabbed physical position")
	grammar.generation_depth = 1
	check(is_equal_approx(selector.get_normalized_value(), 0) and status.label.text == "Depth: 1", "External artifact changes reset handle and readout")
	# Also verify pointer input through the actual artifact callback.
	pointer = Node3D.new()
	world.add_child(pointer)
	await send(selector, -.09, XRToolsPointerEvent.Type.PRESSED)
	await send(selector, -.054, XRToolsPointerEvent.Type.MOVED)
	await send(selector, -.054, XRToolsPointerEvent.Type.RELEASED)
	check(grammar.generation_depth == 2, "Pointer input also changes the actual artifact to generation two")
	check(is_equal_approx(selector.get_normalized_value(), .2) and status.label.text == "Depth: 2", "External artifact changes synchronize handle and readout")
	await capture_pair("physical")
	# Compare the preserved screen with precisely the same cameras and generation.
	grammar.queue_free()
	await process_frame
	grammar = load("res://commons/artifacts/grammar_provenance/grammar_provenance.tscn").instantiate()
	grammar.use_physical_controls = false
	grammar.generation_depth = 2
	world.add_child(grammar)
	await settle()
	await capture_pair("screen")
	FileAccess.open(OUT + "checks.json", FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "headset_tested": false, "method": "XR Tools pickup, grab-driver motion and release; physics rays to physical colliders; actual grammar geometry and readout"}, "\t"))
	print("PHYSICAL_RESULT ", checks, " checks, ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)

func send(selector: Node3D, y: float, kind: int) -> void:
	await physics_frame
	var query := PhysicsRayQueryParameters3D.create(selector.to_global(Vector3(0, y, .3)), selector.to_global(Vector3(0, y, -.02)), PhysicalSlider.POINTER_LAYERS)
	var hit: Dictionary = world.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty(), "Physics ray reaches physical selector at %.3f" % y)
	if not hit.is_empty():
		XRToolsPointerEvent.report(XRToolsPointerEvent.new(kind, pointer, hit.collider, hit.position, hit.position))
	await process_frame

func capture_pair(prefix: String) -> void:
	camera.fov = 40
	camera.position = Vector3(.35, 1.60, 2.15)
	camera.look_at(Vector3(0, .86, 1.7))
	await capture(prefix + "-close")
	camera.fov = 85
	camera.position = Vector3(0, 1.65, 2.1)
	camera.look_at(Vector3(0, .30, .4))
	await capture(prefix + "-front")

func capture(tag: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + tag + ".png")
