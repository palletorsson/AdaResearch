extends SceneTree
## Console-size and input regression. Direct pointer events, not tracked hands.
const Presets = preload("res://commons/ui/interface_presets.gd")
const OUT := "res://doc/reports/interfaces-2026-09-20/console-finish/console-regression.json"
var failures: Array[String] = []
var checks := 0
var presses := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("CONSOLE ", "PASS " if ok else "FAIL ", message)

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var pointer := Node3D.new()
	world.add_child(pointer)
	var consoles: Array = []
	for mode in ["legacy", "compact"]:
		for mount in ["kiosk", "lectern", "wall"]:
			var console := Presets.build("workbench", "SAME CONTROLS", 1.0, "braun", mode)
			console.mounting = mount
			console.position = Vector3(consoles.size() * 3, 1, 0)
			console.rotation_degrees.y = 27
			world.add_child(console)
			var sliders: Array = []
			for label in ["F", "E", "WEIGHT", "CHANGE"]: sliders.append(console.add_slider(label))
			var button: Node3D = console.add_button("KEEP")
			button.pressed.connect(func(): presses += 1)
			var readout: Label = console.add_readout("retained 0.450")
			consoles.append({"console":console, "mode":mode, "mount":mount, "sliders":sliders, "button":button, "readout":readout})
	for frame in 10: await process_frame
	for case in consoles:
		var console: Node3D = case.console
		var panel: Node3D = console.panel()
		var head: CSGBox3D = console.get_node("Body/Head")
		var plate: MeshInstance3D = panel.get_node("Tilt/Chrome/BackPanel")
		var tag: String = case.mode + "/" + case.mount
		check(console.get_node("Body").get_child_count() > 0, tag + " has a casing")
		check((console.get_node_or_null("Body/Base") != null) == (case.mount == "kiosk"), tag + " respects mounting")
		check(panel._items.size() == 5 and case.readout.text == "retained 0.450", tag + " preserves controls and readout")
		check(is_equal_approx(console.board_width, .62), tag + " keeps configured width unchanged")
		if case.mode == "legacy":
			check(is_equal_approx(head.size.x, .70) and panel.scale.x < .4, tag + " retains existing fit behaviour")
			continue
		check(panel.scale.is_equal_approx(Vector3.ONE), tag + " never scales the panel")
		check(panel.layout_columns == 3, tag + " adopts compact preset")
		check(head.size.x > 1.0 and head.size.x < 1.2, tag + " casing fits three full-size slots")
		check(panel._items[3].node.position.y < panel._items[0].node.position.y, tag + " wraps the fourth rail")
		var fits := true
		for corner in 8:
			var p: Vector3 = head.to_local(plate.to_global(plate.get_aabb().get_endpoint(corner)))
			fits = fits and absf(p.x) <= head.size.x * .5 and absf(p.y) <= head.size.y * .5
		check(fits, tag + " backplate stays inside the casing")
		for index in 4:
			var slider: Node3D = case.sliders[index]
			check(slider.global_basis.get_scale().is_equal_approx(Vector3.ONE), tag + " rail %d remains unscaled" % index)
			var handle: Node3D = slider.get_node("SliderOrigin/InteractableSlider/HandleOrigin/InteractableHandle")
			slider.set_normalized_value(0)
			var begin := handle.global_position
			slider.set_normalized_value(1)
			var end := handle.global_position
			check(is_equal_approx(begin.distance_to(end), .14), tag + " rail %d retains 14 cm travel" % index)
			slider.set_normalized_value(.25)
			var axis: Vector3 = slider.get_node("SliderOrigin").global_basis.x.normalized()
			var origin: Vector3 = handle.global_position
			XRToolsPointerEvent.pressed(pointer, slider, origin)
			XRToolsPointerEvent.moved(pointer, slider, origin + axis * .07, origin)
			XRToolsPointerEvent.released(pointer, slider, origin + axis * .07)
			check(absf(slider.get_normalized_value() - .75) < .0001, tag + " rail %d maps 7 cm pointer motion to half-range" % index)
			XRToolsPointerEvent.pressed(pointer, slider, origin)
			XRToolsPointerEvent.moved(pointer, slider, origin - axis * .07, origin)
			XRToolsPointerEvent.released(pointer, slider, origin - axis * .07)
			check(absf(slider.get_normalized_value() - .25) < .0001, tag + " rail %d reverses correctly" % index)
			check(not slider.get_node("Frame/Label3DValue").visible and slider.get_node("Frame/ValueSurface").mesh is QuadMesh, tag + " rail %d value is 2D on its backing" % index)
			check(slider._surface_value.text == slider._last_display_text, tag + " rail %d display retains the current value" % index)
			slider.set_range(-2, 2)
			check(is_equal_approx(float(slider._surface_value.text), -1.0) and slider._surface_value.text == slider._last_display_text, tag + " rail %d preserves logical range formatting" % index)
		var area: Area3D = case.button.get_node("InteractableAreaButton")
		var old := presses
		XRToolsPointerEvent.pressed(pointer, area, area.global_position)
		XRToolsPointerEvent.released(pointer, area, area.global_position)
		check(presses == old + 1, tag + " KEEP receives one pointer press")
		var body_id := console.get_node("Body").get_instance_id()
		var scale_before := panel.scale
		for frame in 5: await process_frame
		check(console.get_node("Body").get_instance_id() == body_id and panel.scale.is_equal_approx(scale_before), tag + " does not rebuild or shrink each frame")
	var result := {"checks":checks, "failures":failures,"headset_tested":false,
		"scope":"Legacy versus compact preset; kiosk, lectern and wall; full-scale geometry, backing, direct pointer drag and button events"}
	FileAccess.open(OUT, FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	world.queue_free()
	for frame in 3: await process_frame
	quit(0 if failures.is_empty() else 1)
