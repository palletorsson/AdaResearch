extends SceneTree
## Shannon's operator controls and the shared owner-selected button contract.
const OUT := "res://doc/reports/interfaces-2026-09-20/shannon-pilot/control-checks.json"
var checks := 0
var failures: Array[String] = []
var momentary_presses := 0

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("SHANNON_UI ", "PASS " if ok else "FAIL ", message)

func press(pointer: Node3D, button: Node3D) -> void:
	var area: Area3D = button.get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(pointer, area, area.global_position)
	XRToolsPointerEvent.released(pointer, area, area.global_position)

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var pointer := Node3D.new()
	world.add_child(pointer)
	var bench: Node3D = load("res://commons/artifacts/shannon_workbench/shannon_workbench.tscn").instantiate()
	bench.prediction_study = true
	bench.rotation_degrees.y = 37
	world.add_child(bench)
	var plain: Node3D = load("res://commons/artifacts/shannon_workbench/shannon_workbench.tscn").instantiate()
	plain.position.x = 3
	world.add_child(plain)
	var selected: Node3D = load("res://commons/interactables/push_button.tscn").instantiate()
	selected.set_selected(true)
	world.add_child(selected)
	var momentary: Node3D = load("res://commons/interactables/push_button.tscn").instantiate()
	momentary.pressed.connect(func(): momentary_presses += 1)
	world.add_child(momentary)
	for frame in 10: await process_frame
	check(selected.is_selected() and selected._button_material.albedo_color.is_equal_approx(selected.selected_color), "Selection set before tree entry is rendered")
	press(pointer, momentary)
	check(momentary_presses == 1 and not momentary.is_selected(), "Ordinary button stays momentary and emits one activation")
	check(bench._plate_root.panel().scale.is_equal_approx(Vector3.ONE), "Study panel keeps full size")
	check(plain._plate_root.panel().scale.is_equal_approx(Vector3.ONE) and plain._prediction_buttons.is_empty(), "Single-control default retains its lesson with full-size slider")
	check(bench._prediction_buttons[0].is_selected() and not bench._prediction_buttons[1].is_selected(), "Initial predictor choice is visible")
	check(bench._prediction_buttons[0]._button_material != bench._prediction_buttons[1]._button_material, "Choice colours are independent materials")
	var monitor: Node3D = bench._grid_root.get_parent()
	var support: MeshInstance3D = monitor.get_node("Support")
	var screen: MeshInstance3D = monitor.get_node("Screen")
	check(support.position.z + support.mesh.size.z / 2 < screen.position.z - screen.mesh.size.z / 2, "Monitor support stays entirely behind the screen")
	var slider: Node3D = bench._slider
	var handle: Node3D = slider.get_node("SliderOrigin/InteractableSlider/HandleOrigin/InteractableHandle")
	var initial_draws: PackedFloat32Array = bench._draws.duplicate()
	var endpoints: Array[Vector3] = []
	for value in [0.0, 1.0]:
		slider.set_normalized_value(value)
		for frame in 5: await physics_frame
		endpoints.append(handle.global_position)
	check(is_equal_approx(endpoints[0].distance_to(endpoints[1]), .14), "Fader retains 14 cm travel after physics settles")
	var right: Vector3 = bench._plate_root.panel()._row.global_basis.x.normalized()
	check((endpoints[1] - endpoints[0]).dot(right) > .139, "Increasing probability moves the handle right across the panel")
	slider.set_normalized_value(.25)
	var origin := handle.global_position
	var axis: Vector3 = slider.get_node("SliderOrigin").global_basis.x.normalized()
	XRToolsPointerEvent.pressed(pointer, slider, origin)
	XRToolsPointerEvent.moved(pointer, slider, origin + axis * .07, origin)
	XRToolsPointerEvent.released(pointer, slider, origin + axis * .07)
	bench._process(.25)
	check(is_equal_approx(bench._p, .75), "Seven-centimetre pointer drag changes source by half its range")
	check(float(slider._surface_value.text) == .75, "Flat fader value agrees with source probability")
	var colours: Array = []
	for material in bench._grid_materials: colours.append(material.albedo_color)
	var previous: Dictionary = bench.prediction_reading()
	press(pointer, bench._prediction_buttons[1])
	check(bench._prediction == 1 and bench._prediction_buttons[1].is_selected() and not bench._prediction_buttons[0].is_selected(), "EXPECT 1 changes and latches exactly one choice")
	check(bench._prediction_buttons[1]._button_material.albedo_color.is_equal_approx(bench._prediction_buttons[1].selected_color), "Selected cap stays lit after release")
	check(is_equal_approx(bench._p, .75) and bench._draws == initial_draws, "Choice preserves probability and original sample")
	var unchanged := true
	for i in colours.size(): unchanged = unchanged and colours[i] == bench._grid_materials[i].albedo_color
	check(unchanged, "Choice preserves the bit grid colours")
	check(bench._observed_errors == 256 - int(previous.observed_errors), "Switching constant predictor complements observed errors")
	press(pointer, bench._prediction_buttons[1])
	check(bench._prediction == 1 and bench._prediction_buttons[1].is_selected(), "Repeated choice remains selected rather than toggling off")
	press(pointer, bench._prediction_buttons[0])
	check(bench._prediction == 0 and bench._prediction_buttons[0].is_selected() and not bench._prediction_buttons[1].is_selected(), "EXPECT 0 restores the other choice")
	bench.apply_grid_config({"prediction_study":"off"})
	check(not bench._prediction_buttons[0].is_selected() and not bench._prediction_buttons[0].visible, "Disabled study hides and clears its indicators")
	bench.apply_grid_config({"prediction_study":"on"})
	check(bench._prediction_buttons.size() == 2 and bench._prediction_buttons[0].is_selected(), "Re-enabled study restores selection without duplicate controls")
	var grid_id: int = plain._grid_root.get_instance_id()
	var readout_id: int = plain._plate_readout.get_instance_id()
	var sample: PackedFloat32Array = plain._draws.duplicate()
	plain.apply_grid_config({"prediction_study":"on"})
	for frame in 10: await process_frame
	var head: CSGBox3D = plain._plate_root.get_node("Body/Head")
	var plate: MeshInstance3D = plain._plate_root.panel().get_node("Tilt/Chrome/BackPanel")
	var fits := true
	for corner in 8:
		var point: Vector3 = head.to_local(plate.to_global(plate.get_aabb().get_endpoint(corner)))
		fits = fits and absf(point.x) <= head.size.x / 2 and absf(point.y) <= head.size.y / 2
	check(fits, "Enabling predictions on an assembled single-control bench refits the casing")
	check(plain._grid_root.get_instance_id() == grid_id and plain._plate_readout.get_instance_id() == readout_id and plain._draws == sample, "Housing refit preserves display instances and the sample")
	var body_id: int = plain._plate_root.get_node("Body").get_instance_id()
	for frame in 5: await process_frame
	check(plain._plate_root.get_node("Body").get_instance_id() == body_id, "Idle console does not repeatedly rebuild its housing")
	FileAccess.open(OUT, FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"\t"))
	world.queue_free()
	for frame in 3: await process_frame
	quit(0 if failures.is_empty() else 1)
