extends Node3D
## Two physical parameters beside up to four actions, with one flat readout.
## Configure before entry. Access is explicit: open, held, or absent.
signal parameter_changed(index: int, value: float)
signal action_pressed(index: int)
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const ValueSurface = preload("res://commons/ui/control_value_surface.gd")
@export var title := "PARAMETERS"
var parameters: Array[Dictionary] = []
var actions: PackedStringArray = []
var sliders: Array[Node3D] = []
var buttons: Array[Node3D] = []
var _brackets: Array[Node3D] = []
var _readout: Dictionary = {}

func _ready() -> void:
	assert(parameters.size() == 2 and actions.size() <= 4)
	_box(self, "Case", Vector3(.84, .66, .05), Vector3(0, .02, -.04), Color(.16, .19, .21))
	_box(self, "Face", Vector3(.82, .64, .012), Vector3(0, .02, -.009), Color(.78, .78, .72))
	_print(self, "Heading", title, Vector2(.73, .037), Vector3(0, .294, .003))
	for index in parameters.size():
		var config: Dictionary = parameters[index]
		var at := Vector3(-.30 + index * .19, .055, .016)
		var access: String = config.get("access", "open")
		if access == "absent":
			sliders.append(null)
			_brackets.append(null)
			var blank := Node3D.new()
			blank.name = "Blank_%d" % index
			blank.position = at
			add_child(blank)
			_box(blank, "Plate", Vector3(.154, .324, .022), Vector3.ZERO, Color(.15, .17, .19))
			_print(blank, "AbsentName", config.label, Vector2(.13, .028), Vector3(0, .07, .012), Color(.86, .87, .80))
			_print(blank, "AbsentLabel", "NOT FITTED", Vector2(.13, .025), Vector3(0, .018, .012), Color(.86, .87, .80))
			for side in [-1, 1]:
				for end in [-1, 1]:
					_box(blank, "Rivet", Vector3(.012, .012, .008), Vector3(side * .063, end * .146, .014), Color(.48, .50, .53))
			continue
		var slider: Node3D = load("res://commons/interactables/physical_stepped_slider.gd").new()
		slider.name = "Parameter_%d" % index
		slider.param_name = config.label
		slider.continuous = config.get("continuous", true)
		slider.step_count = config.get("steps", 6)
		slider.input_enabled = access == "open"
		slider.set_normalized_value(config.get("value", 0.0))
		slider.position = at
		add_child(slider)
		slider.value_changed.connect(func(value: float): parameter_changed.emit(index, value))
		sliders.append(slider)
		var bracket: Node3D
		if access == "held":
			bracket = Node3D.new()
			bracket.name = "Clamp_%d" % index
			slider.add_child(bracket)
			# A bolted bar holds the real cap; external configuration moves both.
			_box(bracket, "Bar", Vector3(.138, .018, .014), Vector3(0, 0, .055), Color(.48, .51, .54))
			for side in [-1, 1]:
				_box(bracket, "Anchor", Vector3(.022, .050, .048), Vector3(side * .058, 0, .025), Color(.25, .28, .30))
				_box(bracket, "Bolt", Vector3(.010, .010, .005), Vector3(side * .058, 0, .060), Color(.68, .69, .65))
		_brackets.append(bracket)
		set_parameter(index, config.get("value", 0.0))
	var panel := ControlPanel.new()
	panel.name = "Actions"
	panel.tilt_degrees = 0
	panel.spacing = .17
	panel.layout_columns = 2
	panel.instrument_face = true
	panel.position = Vector3(.21, .045, .002)
	add_child(panel)
	for index in actions.size():
		var button := panel.add_button(actions[index])
		button.name = "Action_%d" % index
		button.selected_color = Color(.20, .80, .69)
		button.pressed_emission_energy = .25
		button.released_emission_energy = .08
		button.pressed.connect(func(): action_pressed.emit(index))
		buttons.append(button)
	_readout = ValueSurface.build(self, Vector2(.76, .098), Vector3(0, -.227, .003))
	_readout.viewport.size = Vector2i(1140, 147)
	_readout.label.size = Vector2(1140, 147)
	_readout.viewport.get_child(0).size = Vector2(1140, 147)
	_readout.label.add_theme_font_size_override("font_size", 39)

func set_parameter(index: int, value: float) -> void:
	parameters[index].value = clampf(value, 0, 1)
	if index < sliders.size() and is_instance_valid(sliders[index]):
		sliders[index].set_normalized_value(value)
	if index < _brackets.size() and is_instance_valid(_brackets[index]):
		_brackets[index].position.y = (clampf(value, 0, 1) - .5) * .18

func set_action_selected(index: int, selected: bool) -> void:
	if index < buttons.size(): buttons[index].set_selected(selected)

func set_reading(text: String) -> void:
	if not _readout.is_empty() and _readout.label.text != text:
		_readout.label.text = text
		_readout.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func _print(parent: Node3D, node_name: String, text: String, size: Vector2, at: Vector3, ink := Color(.08, .10, .12)) -> void:
	var label := BakedText.make_label_mesh(text, ink, size, 2200, true)
	label.name = node_name
	label.position = at
	parent.add_child(label)

func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = size
	mesh.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = .72
	mesh.material_override = mat
	parent.add_child(mesh)
