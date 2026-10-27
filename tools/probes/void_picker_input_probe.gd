extends SceneTree
## Actual menu callbacks and XRTools pointer events; no headset is claimed.
class StagingFixture extends Node3D:
	var destination := ""
	func load_scene(path: String) -> void: destination = path
	func return_to_main_menu() -> void: pass

class PickerFixture extends Node3D:
	var selected := -1
	func _open_void_floor(index: int) -> void: selected = index

var checks: Array[Dictionary] = []
var out := "user://"
var menu: Node3D
var fixture: Node3D
var pointer: Node3D

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "passed": passed})
	print("[picker-input] ", "PASS " if passed else "FAIL ", label)

func find_button(caption: String) -> Node3D:
	for button in menu.get_node("VoidTrialPicker").buttons:
		if button.visible and button.text.begins_with(caption): return button
	return null

func press(button: Node3D) -> void:
	XRToolsPointerEvent.pressed(pointer, button, button.global_position)

func dwell(button: Node3D) -> void:
	XRToolsPointerEvent.entered(pointer, button, button.global_position)
	button._process(button.hover_time_required + .01)

func run() -> void:
	fixture = StagingFixture.new()
	root.add_child(fixture)
	var controller := XRController3D.new()
	fixture.add_child(controller)
	pointer = Node3D.new()
	controller.add_child(pointer)
	menu = load("res://commons/scenes/main_menu/MainMenu3D.tscn").instantiate()
	fixture.add_child(menu)
	await process_frame
	press(menu.get_node("Buttons/VoidButton"))
	check("Controller trigger opens the Void picker", menu.has_node("VoidTrialPicker"))
	if not menu.has_node("VoidTrialPicker"): dwell(menu.get_node("Buttons/VoidButton"))
	var sequence_button := find_button("Transformation")
	press(sequence_button)
	check("Controller trigger selects a sequence", menu.get_node("VoidTrialPicker").selected_sequence == 1)
	if menu.get_node("VoidTrialPicker").selected_sequence != 1: dwell(sequence_button)
	var map_button := find_button("014 /")
	press(map_button)
	check("Controller trigger opens the selected main map", fixture.destination == "res://commons/void/void.tscn" and load("res://commons/void/game.gd").requested_floor == 14)
	menu._close_void_trials()
	await process_frame
	menu._entering_head_arena = false
	fixture.destination = ""
	menu._on_void_clicked()
	sequence_button = find_button("Transformation")
	dwell(sequence_button)
	map_button = find_button("014 /")
	check("Regression uses the same pooled button for sequence and map", map_button == sequence_button)
	# XR's ray keeps the same collider between pages and sends MOVED, not ENTERED.
	XRToolsPointerEvent.moved(pointer, map_button, map_button.global_position + Vector3(.001, 0, 0), map_button.global_position)
	map_button._process(map_button.hover_time_required + .01)
	check("Dwell can select a repurposed map without leaving the row", fixture.destination == "res://commons/void/void.tscn" and load("res://commons/void/game.gd").requested_floor == 14)
	var receiver := PickerFixture.new()
	root.add_child(receiver)
	var picker: Node3D = load("res://commons/void/spine_picker.gd").new()
	receiver.add_child(picker)
	picker.configure(receiver)
	var routed: Array[int] = []
	var correct := true
	var mismatches: Array = []
	for sequence_index in range(picker.layout.spine.size()):
		picker.selected_sequence = sequence_index
		var floors: Array = picker.layout.spine[sequence_index].floors
		for page_index in range(ceili(float(floors.size()) / picker.PAGE_SIZE)):
			picker.page = page_index
			picker.show_page()
			for button in picker.buttons:
				if not button.visible or not button.text.substr(0, 3).is_valid_int(): continue
				var expected := int(button.text.substr(0, 3))
				receiver.selected = -1
				button.clicked.emit()
				correct = correct and receiver.selected == expected and floors.any(func(f): return int(f) == expected)
				if receiver.selected != expected: mismatches.append([expected, receiver.selected])
				routed.append(receiver.selected)
	routed.sort()
	var full_coverage: bool = routed.size() == picker.rooms.floors.size()
	for i in range(routed.size()): full_coverage = full_coverage and routed[i] == i
	print("[picker-input] Routed ", routed.size(), " destinations; mismatches=", mismatches)
	check("Every saved floor button routes to its own index across all sequence pages", correct and full_coverage)
	receiver.queue_free()
	var passed: bool = checks.all(func(c): return c.passed)
	var file := FileAccess.open(out.path_join("input-checks.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "checks": checks, "physical_headset": "not tested"}, "\t"))
	file.close()
	fixture.queue_free()
	for frame in range(12): await process_frame
	quit(0 if passed else 1)
