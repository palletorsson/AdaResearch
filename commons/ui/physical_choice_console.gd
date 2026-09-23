extends Node3D
## Reusable four-choice station: physical caps, retained fader, flat lettering.
## Configure before tree entry. Owner sets selection; RESET stays momentary.
signal choice_pressed(index: int)
signal value_changed(value: float)
signal reset_pressed

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const ValueSurface = preload("res://commons/ui/control_value_surface.gd")
@export var title := "CHOOSE A RULE"
@export var choices: PackedStringArray = ["ONE", "TWO", "THREE", "FOUR"]
@export var parameter := "VALUE"
var buttons: Array[Node3D] = []
var slider: Node3D
var reset_button: Node3D
var _selected := 0
var _value := 0.0
var _display: Dictionary = {}
var _reading := ""

func _ready() -> void:
	assert(choices.size() >= 1 and choices.size() <= 4, "Choice console supports one to four modes")
	_box("Case", Vector3(.76, .68, .05), Vector3(0, .045, -.04), Color(.16, .19, .21))
	_box("Face", Vector3(.74, .66, .012), Vector3(0, .045, -.009), Color(.78, .78, .72))
	var panel := ControlPanel.new()
	panel.name = "Choices"
	panel.title = title
	panel.tilt_degrees = 0
	panel.spacing = .18
	panel.layout_columns = 2
	panel.instrument_face = true
	panel.position = Vector3(-.12, .055, .002)
	add_child(panel)
	for index in choices.size():
		var button := panel.add_button(choices[index])
		button.name = "Choice_%d" % index
		button.selected_color = Color(.20, .80, .69)
		button.pressed_emission_energy = .25
		button.released_emission_energy = .08
		button.pressed.connect(func(): choice_pressed.emit(index))
		buttons.append(button)
	slider = load("res://commons/interactables/physical_stepped_slider.gd").new()
	slider.name = "Parameter"
	slider.param_name = parameter
	slider.continuous = true
	slider.position = Vector3(.25, .060, .016)
	slider.set_normalized_value(_value)
	add_child(slider)
	slider.value_changed.connect(func(value: float):
		_value = value
		value_changed.emit(value)
	)
	reset_button = load("res://commons/interactables/push_button.tscn").instantiate()
	reset_button.name = "Reset"
	reset_button.position = Vector3(.25, -.180, .005)
	add_child(reset_button)
	reset_button.pressed.connect(func(): reset_pressed.emit())
	_print("ResetLabel", "RESET", Vector2(.12, .027), Vector3(.25, -.25, .003))
	_display = ValueSurface.build(self, Vector2(.36, .052), Vector3(-.12, -.205, .003))
	_display.viewport.size = Vector2i(640, 100)
	_display.label.size = Vector2(640, 100)
	_display.viewport.get_child(0).size = Vector2(640, 100)
	_display.label.add_theme_font_size_override("font_size", 45)
	set_reading(_reading)
	set_selected(_selected)

## Silent state synchronization, including configuration before tree entry.
func set_selected(index: int) -> void:
	_selected = clampi(index, 0, choices.size() - 1)
	for i in buttons.size(): buttons[i].set_selected(i == _selected)

func set_value(value: float) -> void:
	_value = clampf(value, 0, 1)
	if is_instance_valid(slider): slider.set_normalized_value(_value)

func set_reading(text: String) -> void:
	_reading = text
	if not _display.is_empty() and _display.label.text != text:
		_display.label.text = text
		_display.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func _print(node_name: String, text: String, size: Vector2, at: Vector3) -> void:
	var label := BakedText.make_label_mesh(text, Color(.08, .10, .12), size, 2200, true)
	label.name = node_name
	label.position = at
	add_child(label)

func _box(node_name: String, size: Vector3, at: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = size
	mesh.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = .72
	mesh.material_override = mat
	add_child(mesh)
