## ForcesRackPanel — Shared Ada-styled rack panel for Forces examples
##
## Builds a white backing panel with title, sliders, and readouts.
## Uses the Ada design system palette and interactable slider scenes.
##
## Usage:
##   var panel = ForcesRackPanel.new()
##   panel.setup("Example 2.3: Gravity", 1, 3)
##   var slider = panel.add_slider("Gravity", 0.1, 2.5, 0.9, 0.05)
##   slider.value_changed.connect(_on_gravity_changed)
##   add_child(panel)
class_name ForcesRackPanel
extends Node3D

const SLIDER_SMOOTH_SCENE := preload("res://commons/interactables/slider_smooth.tscn")
const PANEL_MATERIAL := preload("res://commons/ui/materials/panel_white.tres")

# Ada palette constants
const TEXT_PRIMARY := Color(0.12, 0.12, 0.14, 1.0)
const TEXT_SECONDARY := Color(0.40, 0.40, 0.44, 1.0)
const TEXT_ON_DARK := Color(0.92, 0.92, 0.94, 1.0)
const ACCENT_ORANGE := Color(0.95, 0.45, 0.15, 1.0)
const ACCENT_CYAN := Color(0.00, 0.78, 0.85, 1.0)

# Layout constants (from AdaPalette)
const RACK_UNIT := 0.08     # 8cm
const MODULE_GAP := 0.006   # 6mm
const PANEL_DEPTH := 0.012  # 12mm

# Slider module size: 1x2 rack units = 8cm x 16cm
const SLIDER_WIDTH := 0.08
const SLIDER_HEIGHT := 0.16

# Panel layout
const TITLE_HEIGHT := 0.04       # Space for title at top
const PADDING_H := 0.02          # Horizontal padding
const PADDING_V := 0.015         # Vertical padding
const READOUT_HEIGHT := 0.025    # Height for a readout row
const SLIDER_SLOT_GAP := 0.012   # Gap between slider columns

# Internal state
var _title_label: Label3D
var _panel_mesh: MeshInstance3D
var _columns: int = 1
var _rack_units_tall: int = 3
var _next_slider_index: int = 0
var _readout_count: int = 0
var _sliders: Array = []
var _readouts: Dictionary = {}

# Signal forwarded from sliders — carries (slider_name: String, value: float)
signal slider_value_changed(slider_name: String, value: float)


func setup(title: String, columns: int = 1, rack_units_tall: int = 3) -> void:
	_columns = max(1, columns)
	_rack_units_tall = max(2, rack_units_tall)
	_build_panel(title)


func _build_panel(title: String) -> void:
	# Calculate panel dimensions
	var panel_width: float = _columns * SLIDER_WIDTH + (_columns - 1) * SLIDER_SLOT_GAP + PADDING_H * 2.0
	var panel_height: float = _rack_units_tall * RACK_UNIT

	# Ensure minimum width for title
	panel_width = max(panel_width, 0.18)

	# Create backing panel mesh
	_panel_mesh = MeshInstance3D.new()
	_panel_mesh.name = "PanelBacking"
	var box := BoxMesh.new()
	box.size = Vector3(panel_width, panel_height, PANEL_DEPTH)
	_panel_mesh.mesh = box
	_panel_mesh.material_override = PANEL_MATERIAL
	add_child(_panel_mesh)

	# Title label — at top of panel, on the surface
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = title
	_title_label.font_size = 14
	_title_label.pixel_size = 0.001
	_title_label.modulate = TEXT_PRIMARY
	_title_label.outline_size = 0
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_title_label.position = Vector3(0, panel_height * 0.5 - TITLE_HEIGHT * 0.5 - 0.005, PANEL_DEPTH * 0.5 + 0.001)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title_label)

	# Instruction label below title
	var instructions_label := Label3D.new()
	instructions_label.name = "InstructionsLabel"
	instructions_label.text = ""
	instructions_label.font_size = 9
	instructions_label.pixel_size = 0.001
	instructions_label.modulate = TEXT_SECONDARY
	instructions_label.outline_size = 0
	instructions_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	instructions_label.position = Vector3(0, panel_height * 0.5 - TITLE_HEIGHT - 0.005, PANEL_DEPTH * 0.5 + 0.001)
	instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(instructions_label)


func set_instructions(text: String) -> void:
	var lbl = get_node_or_null("InstructionsLabel")
	if lbl:
		lbl.text = text


## Add a slider to the panel.
## Returns the slider root Node3D (has slider_moved signal and value API).
## For integer/stepped params, set use_snap=true — values will be rounded.
## All sliders use slider_smooth.tscn which provides set_range/get_normalized_value/slider_moved.
func add_slider(param_name: String, range_min: float, range_max: float, default_val: float, step: float = 0.0, use_snap: bool = false) -> Node3D:
	var slider_instance: Node3D = SLIDER_SMOOTH_SCENE.instantiate()
	slider_instance.name = "Slider_%s" % param_name.replace(" ", "_")

	# For snap sliders, set decimal_places to 0 so the label shows integers
	if use_snap:
		slider_instance.set("decimal_places", 0)

	# Position the slider in its slot on the panel
	var slot_pos := _get_slider_slot_position(_next_slider_index)
	slider_instance.position = slot_pos
	add_child(slider_instance)

	# Configure range and default value
	# The smooth slider has set_range() and set_normalized_value()
	if slider_instance.has_method("set_range"):
		slider_instance.set_range(range_min, range_max)

	if slider_instance.has_method("set_param_name"):
		slider_instance.set_param_name(param_name)

	# Set default normalized value (deferred so the slider's _ready() runs first)
	if range_max != range_min:
		var norm := (default_val - range_min) / (range_max - range_min)
		norm = clampf(norm, 0.0, 1.0)
		_defer_set_normalized.call_deferred(slider_instance, norm)

	# The smooth slider scene has a built-in LabelName node — no extra label needed

	_sliders.append({
		"instance": slider_instance,
		"name": param_name,
		"min": range_min,
		"max": range_max,
		"default": default_val
	})
	_next_slider_index += 1

	return slider_instance


func _defer_set_normalized(slider: Node3D, norm: float) -> void:
	if is_instance_valid(slider) and slider.has_method("set_normalized_value"):
		slider.set_normalized_value(norm)


## Add a display-only readout label on the panel.
## Returns the Label3D so the caller can update its text.
func add_readout(label_name: String, initial_text: String = "--") -> Label3D:
	var panel_height: float = _rack_units_tall * RACK_UNIT
	var panel_width: float = _columns * SLIDER_WIDTH + (_columns - 1) * SLIDER_SLOT_GAP + PADDING_H * 2.0
	panel_width = max(panel_width, 0.18)

	var readout := Label3D.new()
	readout.name = "Readout_%s" % label_name.replace(" ", "_")
	readout.font_size = 11
	readout.pixel_size = 0.001
	readout.modulate = ACCENT_CYAN
	readout.outline_size = 0
	readout.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Position readouts below the sliders area
	var readout_y: float = -panel_height * 0.5 + PADDING_V + _readout_count * READOUT_HEIGHT + READOUT_HEIGHT * 0.5
	readout.position = Vector3(0, readout_y, PANEL_DEPTH * 0.5 + 0.001)
	readout.text = "%s: %s" % [label_name, initial_text]

	add_child(readout)
	_readouts[label_name] = readout
	_readout_count += 1

	return readout


## Update a named readout's displayed value
func update_readout(label_name: String, value_text: String) -> void:
	var readout: Label3D = _readouts.get(label_name, null)
	if readout and is_instance_valid(readout):
		var new_text := "%s: %s" % [label_name, value_text]
		if readout.text != new_text:
			readout.text = new_text


## Get the panel width for external positioning
func get_panel_width() -> float:
	var w: float = _columns * SLIDER_WIDTH + (_columns - 1) * SLIDER_SLOT_GAP + PADDING_H * 2.0
	return max(w, 0.18)


## Get the panel height for external positioning
func get_panel_height() -> float:
	return _rack_units_tall * RACK_UNIT


## Programmatically set a slider's value by index
func set_slider_value(index: int, value: float) -> void:
	if index < 0 or index >= _sliders.size():
		return
	var data: Dictionary = _sliders[index]
	var slider: Node3D = data["instance"]
	if not is_instance_valid(slider):
		return
	var range_min: float = data["min"]
	var range_max: float = data["max"]
	if range_max == range_min:
		return
	var norm: float = clampf((value - range_min) / (range_max - range_min), 0.0, 1.0)
	if slider.has_method("set_normalized_value"):
		slider.set_normalized_value(norm)


## Get a slider's current logical value by index
func get_slider_value(index: int) -> float:
	if index < 0 or index >= _sliders.size():
		return 0.0
	var data: Dictionary = _sliders[index]
	var slider: Node3D = data["instance"]
	if not is_instance_valid(slider):
		return data["default"]
	var range_min: float = data["min"]
	var range_max: float = data["max"]
	if slider.has_method("get_normalized_value"):
		var norm: float = slider.get_normalized_value()
		return lerp(range_min, range_max, norm)
	return data["default"]


func _get_slider_slot_position(index: int) -> Vector3:
	var panel_height: float = _rack_units_tall * RACK_UNIT
	var panel_width: float = _columns * SLIDER_WIDTH + (_columns - 1) * SLIDER_SLOT_GAP + PADDING_H * 2.0
	panel_width = max(panel_width, 0.18)

	var col: int = index % _columns
	var row: int = index / _columns

	# Horizontal: center the columns on the panel
	var total_sliders_width: float = _columns * SLIDER_WIDTH + (_columns - 1) * SLIDER_SLOT_GAP
	var start_x: float = -total_sliders_width * 0.5 + SLIDER_WIDTH * 0.5
	var x: float = start_x + col * (SLIDER_WIDTH + SLIDER_SLOT_GAP)

	# Vertical: start below title area, each row goes down
	var top_y: float = panel_height * 0.5 - TITLE_HEIGHT - 0.02
	var y: float = top_y - SLIDER_HEIGHT * 0.5 - row * (SLIDER_HEIGHT + MODULE_GAP)

	# Z: on the front surface of the panel
	var z: float = PANEL_DEPTH * 0.5 + 0.002

	return Vector3(x, y, z)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
