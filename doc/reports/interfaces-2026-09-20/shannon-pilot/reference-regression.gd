extends SceneTree
## Actual control callbacks and renderer, with a second receiver and two skins.
const OUT := "res://doc/reports/interfaces-2026-09-20/shannon-pilot/"
var failures: Array[String] = []
var checks := 0
var views: Array = []

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("INSTRUMENT ", "PASS " if ok else "FAIL ", message)

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color(0.065, 0.075, 0.09)
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color(0.9, 0.93, 1)
	sky.ambient_light_energy = 0.7
	environment.environment = sky
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -25, 0)
	light.light_energy = 1.4
	world.add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	floor_mesh.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.16, 0.18, 0.20)
	floor_mesh.material_override = floor_material
	world.add_child(floor_mesh)
	var demo: Node3D = load("res://commons/interactables/interactable_console_demo.tscn").instantiate()
	world.add_child(demo)
	var reference: Node3D = demo.get_node("ReferenceConsole")
	var dark: Node3D = load("res://commons/ui/interface_reference_console.gd").new()
	dark.skin = "black_mesa"
	dark.position.x = 3.0
	world.add_child(dark)
	var pointer := Node3D.new()
	world.add_child(pointer)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.current = true
	camera.fov = 46
	for frame in 12: await process_frame
	root.scaling_3d_scale = 1.0
	root.msaa_3d = Viewport.MSAA_4X
	for example in [reference, dark]:
		var panel: Node3D = example.console.panel()
		var slider: Node3D = example.size_control
		var dial: Node3D = example.turn_control
		var tag: String = example.skin
		check(panel._items.size() == 4, tag + " has slider, dial, joystick and reset")
		check(panel.scale.is_equal_approx(Vector3.ONE), tag + " keeps control scale")
		check(panel._items[2].node.position.y < panel._items[0].node.position.y, tag + " two-column layout wraps")
		for item in panel._items:
			check(item.node.global_basis.get_scale().is_equal_approx(Vector3.ONE), tag + " unscaled " + item.label)
		var head: CSGBox3D = example.console.get_node("Body/Head")
		var plate: MeshInstance3D = panel.get_node("Tilt/Chrome/BackPanel")
		var fits := true
		for corner in 8:
			var p: Vector3 = head.to_local(plate.to_global(plate.get_aabb().get_endpoint(corner)))
			fits = fits and absf(p.x) <= head.size.x / 2 and absf(p.y) <= head.size.y / 2
		check(fits, tag + " face fits its housing")
		var axis: Vector3 = slider.get_node("SliderOrigin").global_basis.x.normalized()
		var origin: Vector3 = slider.global_position
		XRToolsPointerEvent.pressed(pointer, slider, origin)
		XRToolsPointerEvent.moved(pointer, slider, origin + axis * .035, origin)
		XRToolsPointerEvent.released(pointer, slider, origin + axis * .035)
		check(is_equal_approx(example.specimen.scale.x, 1.25), tag + " real slider pointer path changes body size")
		var dial_origin: Vector3 = dial.global_position
		XRToolsPointerEvent.pressed(pointer, dial, dial_origin)
		XRToolsPointerEvent.moved(pointer, dial, dial_origin + Vector3.UP * .15, dial_origin)
		XRToolsPointerEvent.released(pointer, dial, dial_origin + Vector3.UP * .15)
		check(is_equal_approx(example.specimen.rotation_degrees.y, 45), tag + " real dial pointer path rotates body")
		check(float(dial._surface_value.text) == 45, tag + " dial display shows signed logical degrees")
		check(float(slider._surface_value.text) == 1.25, tag + " slider display shows logical size")
		var value_screen: MeshInstance3D = slider.get_node("Frame/ValueSurface")
		var frame_mesh: MeshInstance3D = slider.get_node("Frame/PanelMesh")
		var screen_bottom: float = absf(value_screen.position.x) - value_screen.mesh.size.y / 2
		check(screen_bottom > 0.0175, tag + " fader window clears the handle across its entire travel")
		check(absf(value_screen.position.x) + value_screen.mesh.size.y / 2 < frame_mesh.mesh.size.x / 2, tag + " fader window stays on its backing")
		var joystick: Node3D = example.position_control.get_node("JoystickOrigin/InteractableJoystick")
		joystick.move_joystick(deg_to_rad(15), deg_to_rad(-15))
		check(example.offset.is_equal_approx(Vector2(1.0/3, -1.0/3)), tag + " joystick signal changes both axes")
		check(example.specimen.position.x > 0.07 and example.specimen.position.z < -0.97, tag + " position visibly moves receiver")
		check(example.readout.text.contains("TURN +45"), tag + " summary reflects actual controls")
		for control in [slider, dial]:
			check(not control.get_node("Frame/Label3DValue").visible, tag + " legacy value is not drawn")
			check(control.get_node("Frame/ValueSurface").mesh is QuadMesh, tag + " value rendered in 2D on control")
		await process_frame
		await RenderingServer.frame_post_draw
		var viewport: SubViewport = slider._surface_viewport
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		slider._update_label(slider._current_slider_value())
		check(viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, tag + " unchanged values do not request redraw")
		var button_area: Area3D = example.reset_control.get_node("InteractableAreaButton")
		XRToolsPointerEvent.pressed(pointer, button_area, button_area.global_position)
		XRToolsPointerEvent.released(pointer, button_area, button_area.global_position)
		check(example.specimen.scale.is_equal_approx(Vector3.ONE) and is_zero_approx(example.specimen.rotation.y) and example.offset.is_zero_approx(), tag + " physical RESET restores all parameters")
		# Remove reset indication before capturing the settled instrument.
		for frame in 5: await process_frame
		camera.position = example.position + Vector3(0.12, 1.95, 2.0)
		camera.look_at(example.position + Vector3(0, 1.10, -0.20))
		for frame in 3: await process_frame
		await RenderingServer.frame_post_draw
		var image_path := OUT + "reference-" + tag + ".png"
		root.get_texture().get_image().save_png(image_path)
		views.append(image_path)
	FileAccess.open(OUT + "instrument-checks.json", FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "shots": views, "headset_tested": false}, "\t"))
	world.queue_free()
	for frame in 3: await process_frame
	quit(0 if failures.is_empty() else 1)
