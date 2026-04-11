## ShaderRackPanel — Ada-styled rack panel for Shader examples
##
## Builds a white backing panel with title, sliders, readouts,
## and an optional code snippet display for showing GLSL lines.
##
## Usage:
##   var panel = ShaderRackPanel.new()
##   panel.setup("Shaping: smoothstep()", 2, 4)
##   panel.add_slider("Edge 0", 0.0, 1.0, 0.2, 0.01)
##   panel.set_code_snippet("float y = smoothstep(edge0, edge1, x);")
##   add_child(panel)
class_name ShaderRackPanel
extends Node3D

const SLIDER_SMOOTH_SCENE := preload("res://commons/interactables/slider_smooth.tscn")
const PANEL_MATERIAL := preload("res://commons/ui/materials/panel_white.tres")

# Ada palette constants
const TEXT_PRIMARY := Color(0.12, 0.12, 0.14, 1.0)
const TEXT_SECONDARY := Color(0.40, 0.40, 0.44, 1.0)
const TEXT_ON_DARK := Color(0.92, 0.92, 0.94, 1.0)
const ACCENT_ORANGE := Color(0.95, 0.45, 0.15, 1.0)
const ACCENT_CYAN := Color(0.00, 0.78, 0.85, 1.0)
const CODE_BG := Color(0.08, 0.08, 0.12, 1.0)

# Layout constants
const RACK_UNIT := 0.08
const MODULE_GAP := 0.006
const PANEL_DEPTH := 0.012

const SLIDER_WIDTH := 0.08
const SLIDER_HEIGHT := 0.16

const TITLE_HEIGHT := 0.04
const PADDING_H := 0.02
const PADDING_V := 0.015
const READOUT_HEIGHT := 0.025
const SLIDER_SLOT_GAP := 0.012
const CODE_SNIPPET_HEIGHT := 0.06

# Internal state
var _title_label: Label3D
var _panel_mesh: MeshInstance3D
var _code_label: Label3D
var _code_bg: MeshInstance3D
var _columns: int = 1
var _rack_units_tall: int = 3
var _next_slider_index: int = 0
var _readout_count: int = 0
var _sliders: Array = []
var _readouts: Dictionary = {}
var _has_code_snippet: bool = false

signal slider_value_changed(slider_name: String, value: float)


func setup(title: String, columns: int = 1, rack_units_tall: int = 3) -> void:
	_columns = max(1, columns)
	_rack_units_tall = max(2, rack_units_tall)
	_build_panel(title)


func _build_panel(title: String) -> void:
	var panel_width: float = _columns * SLIDER_WIDTH + (_columns - 1) * SLIDER_SLOT_GAP + PADDING_H * 2.0
	var panel_height: float = _rack_units_tall * RACK_UNIT
	panel_width = max(panel_width, 0.22)

	# Backing panel
	_panel_mesh = MeshInstance3D.new()
	_panel_mesh.name = "PanelBacking"
	var box := BoxMesh.new()
	box.size = Vector3(panel_width, panel_height, PANEL_DEPTH)
	_panel_mesh.mesh = box
	_panel_mesh.material_override = PANEL_MATERIAL
	add_child(_panel_mesh)

	# Title label
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

	# Instruction label
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


## Show a code snippet on the panel — a small monospace-styled GLSL line
## displayed in ACCENT_CYAN on a dark background strip at the bottom.
func set_code_snippet(text: String) -> void:
	var panel_height: float = _rack_units_tall * RACK_UNIT
	var panel_width: float = _columns * SLIDER_WIDTH + (_columns - 1) * SLIDER_SLOT_GAP + PADDING_H * 2.0
	panel_width = max(panel_width, 0.22)

	if not _has_code_snippet:
		# Create dark background strip for code
		_code_bg = MeshInstance3D.new()
		_code_bg.name = "CodeBg"
		var bg_box := BoxMesh.new()
		bg_box.size = Vector3(panel_width - 0.008, CODE_SNIPPET_HEIGHT, 0.002)
		_code_bg.mesh = bg_box
		var bg_mat := StandardMaterial3D.new()
		bg_mat.albedo_color = CODE_BG
		bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_code_bg.material_override = bg_mat
		_code_bg.position = Vector3(0, -panel_height * 0.5 + CODE_SNIPPET_HEIGHT * 0.5 + 0.004, PANEL_DEPTH * 0.5 + 0.001)
		add_child(_code_bg)

		# Code text label
		_code_label = Label3D.new()
		_code_label.name = "CodeSnippet"
		_code_label.font_size = 8
		_code_label.pixel_size = 0.001
		_code_label.modulate = ACCENT_CYAN
		_code_label.outline_size = 0
		_code_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		_code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_code_label.position = Vector3(-panel_width * 0.5 + 0.01, -panel_height * 0.5 + CODE_SNIPPET_HEIGHT * 0.5 + 0.004, PANEL_DEPTH * 0.5 + 0.003)
		add_child(_code_label)
		_has_code_snippet = true

	_code_label.text = text


## Add a slider to the panel. Returns the slider Node3D.
func add_slider(param_name: String, range_min: float, range_max: float, default_val: float, step: float = 0.0, use_snap: bool = false) -> Node3D:
	var slider_instance: Node3D = SLIDER_SMOOTH_SCENE.instantiate()
	slider_instance.name = "Slider_%s" % param_name.replace(" ", "_")

	if use_snap:
		slider_instance.set("decimal_places", 0)

	var slot_pos := _get_slider_slot_position(_next_slider_index)
	slider_instance.position = slot_pos
	add_child(slider_instance)

	if slider_instance.has_method("set_range"):
		slider_instance.set_range(range_min, range_max)

	if slider_instance.has_method("set_param_name"):
		slider_instance.set_param_name(param_name)

	if range_max != range_min:
		var norm := (default_val - range_min) / (range_max - range_min)
		norm = clampf(norm, 0.0, 1.0)
		_defer_set_normalized.call_deferred(slider_instance, norm)

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


## Add a display-only readout label. Returns the Label3D.
func add_readout(label_name: String, initial_text: String = "--") -> Label3D:
	var panel_height: float = _rack_units_tall * RACK_UNIT
	var panel_width: float = _columns * SLIDER_WIDTH + (_columns - 1) * SLIDER_SLOT_GAP + PADDING_H * 2.0
	panel_width = max(panel_width, 0.22)

	var readout := Label3D.new()
	readout.name = "Readout_%s" % label_name.replace(" ", "_")
	readout.font_size = 11
	readout.pixel_size = 0.001
	readout.modulate = ACCENT_CYAN
	readout.outline_size = 0
	readout.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var code_offset := CODE_SNIPPET_HEIGHT + 0.008 if _has_code_snippet else 0.0
	var readout_y: float = -panel_height * 0.5 + PADDING_V + code_offset + _readout_count * READOUT_HEIGHT + READOUT_HEIGHT * 0.5
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


func get_panel_width() -> float:
	var w: float = _columns * SLIDER_WIDTH + (_columns - 1) * SLIDER_SLOT_GAP + PADDING_H * 2.0
	return max(w, 0.22)


func get_panel_height() -> float:
	return _rack_units_tall * RACK_UNIT


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
	panel_width = max(panel_width, 0.22)

	var col: int = index % _columns
	var row: int = index / _columns

	var total_sliders_width: float = _columns * SLIDER_WIDTH + (_columns - 1) * SLIDER_SLOT_GAP
	var start_x: float = -total_sliders_width * 0.5 + SLIDER_WIDTH * 0.5
	var x: float = start_x + col * (SLIDER_WIDTH + SLIDER_SLOT_GAP)

	var top_y: float = panel_height * 0.5 - TITLE_HEIGHT - 0.02
	var y: float = top_y - SLIDER_HEIGHT * 0.5 - row * (SLIDER_HEIGHT + MODULE_GAP)

	var z: float = PANEL_DEPTH * 0.5 + 0.002

	return Vector3(x, y, z)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
