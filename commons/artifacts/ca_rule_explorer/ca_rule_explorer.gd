# ca_rule_explorer.gd
# 1×1m horizontal board displaying Wolfram 1D cellular automata
# VR-enabled with slider and button controls
#
# @identity
# essence: next_cell = (rule >> (left<<2 | center<<1 | right)) & 1 — all 256 Wolfram rules on one board
# desire: To be dialed — slide through all 256 rules and watch chaos, order, and Turing completeness appear
# critical_parameter: rule (0-255) — a single 8-bit number that determines the entire visual universe
# triggers: Rule 30 → chaos from a single seed; Rule 110 → Turing complete computation; Rule 90 → Sierpinski triangle
# emerges: The full spectrum from death (Rule 0) to chaos (Rule 30) to computation (Rule 110) from one integer
# needs: VR rule slider [has], speed slider [has], preset buttons [has], reset button [has], Label3D [has]
# relationships: Central to CA_AgentsCircuits. Extends ca_bridge (single rule, no interaction vs full exploration).
# truth: An 8-bit number is a universe — Rule 110 proves that three neighbors and one bit can compute anything.

extends Node3D

class_name CARuleExplorer
## Implements Wolfram's elementary 1D cellular automaton (rules 0–255).

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")
## Each generation applies a 3-neighbor lookup against the 8-bit rule number
## to determine the next row state. Rows scroll downward on a MultiMesh board.
## Key parameters: rule selects the automaton, generations_per_second controls speed.

## Side length of the square board in meters
@export_range(0.1, 5.0, 0.1) var board_size: float = 1.0

## Number of cells across one row
@export_range(4, 256) var cells_x: int = 64

## Number of history rows shown on the board
@export_range(4, 200) var rows_visible: int = 50

## Current rule (0-255)
@export_range(0, 255) var rule: int = 110:
	set(value):
		rule = clampi(value, 0, 255)
		if is_inside_tree():
			_reset()
			_update_rule_display()
			_sync_rule_slider()

## Simulation speed in generations per second
@export_range(1.0, 30.0, 0.5) var generations_per_second: float = 10.0:
	set(value):
		generations_per_second = clampf(value, 1.0, 30.0)
		if is_inside_tree():
			_sync_speed_slider()

## Whether the simulation advances automatically
@export var auto_run: bool = true

## Color for alive (1) cells
@export var alive_color: Color = Color(0.2, 0.9, 0.4)
## Color for dead (0) cells
@export var dead_color: Color = Color(0.05, 0.08, 0.05)
## Background board color
@export var board_color: Color = Color(0.1, 0.12, 0.1)

# Internal state
var _current_row: Array[bool] = []
var _grid: Array[Array] = []
var _multimesh_instance: MultiMeshInstance3D
var _multimesh: MultiMesh
var _cell_size: Vector2
var _generation_timer: float = 0.0
var _rule_label: Label3D
var _created_nodes: Array[Node] = []

# VR Controls
var _rule_slider: Node
var _speed_slider: Node
var _control_panel: Node3D
var _grid_config: Dictionary = {}

# Signal tracking for cleanup
var _signal_connections: Array = []

# Layout constants
const CELL_HEIGHT := 0.005
const CELL_ELEVATION := 0.015
const CELL_SCALE := 0.95
const FRAME_THICKNESS := 0.02
const FRAME_HEIGHT := 0.03
const PANEL_TILT_DEG := -30.0

# Famous rules
const FAMOUS_RULES = {
	30: "Chaotic",
	90: "Sierpiński",
	110: "Turing Complete",
	184: "Traffic",
	250: "Solid",
	0: "Death",
	255: "Life"
}


func _ready() -> void:
	_cell_size = Vector2(board_size / maxi(cells_x, 1), board_size / maxi(rows_visible, 1))
	_create_board()
	_create_multimesh()
	_create_rule_display()
	_create_vr_controls()
	_reset()

func _exit_tree() -> void:
	for conn in _signal_connections:
		if is_instance_valid(conn[0]) and conn[0].is_connected(conn[1], conn[2]):
			conn[0].disconnect(conn[1], conn[2])
	_signal_connections.clear()
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()

## Build the flat board surface and surrounding frame
func _create_board() -> void:
	var board = MeshInstance3D.new()
	board.name = "Board"

	var box = BoxMesh.new()
	box.size = Vector3(board_size, 0.02, board_size)
	board.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = board_color
	mat.metallic = 0.3
	mat.roughness = 0.7
	board.material_override = mat

	board.position = Vector3(0, -0.01, 0)
	add_child(board)
	_created_nodes.append(board)

	_create_frame()

## Add bevelled edges around the board perimeter
func _create_frame() -> void:
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.2, 0.22, 0.25)
	frame_mat.metallic = 0.6
	frame_mat.roughness = 0.4

	var half = board_size / 2.0

	var edges = [
		Vector3(0, FRAME_HEIGHT / 2, -half - FRAME_THICKNESS / 2),
		Vector3(0, FRAME_HEIGHT / 2, half + FRAME_THICKNESS / 2),
		Vector3(-half - FRAME_THICKNESS / 2, FRAME_HEIGHT / 2, 0),
		Vector3(half + FRAME_THICKNESS / 2, FRAME_HEIGHT / 2, 0)
	]
	var sizes = [
		Vector3(board_size + FRAME_THICKNESS * 2, FRAME_HEIGHT, FRAME_THICKNESS),
		Vector3(board_size + FRAME_THICKNESS * 2, FRAME_HEIGHT, FRAME_THICKNESS),
		Vector3(FRAME_THICKNESS, FRAME_HEIGHT, board_size),
		Vector3(FRAME_THICKNESS, FRAME_HEIGHT, board_size)
	]

	for i in range(4):
		var edge = MeshInstance3D.new()
		var ebox = BoxMesh.new()
		ebox.size = sizes[i]
		edge.mesh = ebox
		edge.material_override = frame_mat
		edge.position = edges[i]
		add_child(edge)
		_created_nodes.append(edge)

## Set up the MultiMesh grid for efficient cell rendering
func _create_multimesh() -> void:
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.instance_count = cells_x * rows_visible

	var cell_mesh = BoxMesh.new()
	cell_mesh.size = Vector3(_cell_size.x * CELL_SCALE, CELL_HEIGHT, _cell_size.y * CELL_SCALE)
	_multimesh.mesh = cell_mesh

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.3

	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "CellMultiMesh"
	_multimesh_instance.multimesh = _multimesh
	_multimesh_instance.material_override = mat
	add_child(_multimesh_instance)
	_created_nodes.append(_multimesh_instance)

	for row in range(rows_visible):
		for col in range(cells_x):
			var idx = row * cells_x + col
			var x = (col - cells_x / 2.0 + 0.5) * _cell_size.x
			var z = (row - rows_visible / 2.0 + 0.5) * _cell_size.y

			var xform = Transform3D()
			xform.origin = Vector3(x, CELL_ELEVATION, z)
			_multimesh.set_instance_transform(idx, xform)
			_multimesh.set_instance_color(idx, dead_color)

## Create the floating rule label above the board
func _create_rule_display() -> void:
	# A framed plate on a STALK at the back of the board; the live rule text sits on its face
	# (2D-on-surface, fixed orientation) so it reads as a mounted readout, not floating.
	var rule_plate := HangarKit.signage("", [], Vector2(0.62, 0.22), 0.3, Vector3(0, 1, 0))
	rule_plate.position = Vector3(0, 0.0, -board_size / 2 - 0.06)
	add_child(rule_plate)
	_created_nodes.append(rule_plate)
	_rule_label = Label3D.new()
	_rule_label.name = "RuleLabel"
	_rule_label.pixel_size = 0.0014
	_rule_label.font_size = 48
	_rule_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_rule_label.modulate = Color(0.90, 0.95, 0.96)
	_rule_label.position = Vector3(0, 0.3, -board_size / 2 - 0.06 + 0.04)
	add_child(_rule_label)
	_created_nodes.append(_rule_label)
	_update_rule_display()

## Build the VR control panel with sliders and preset buttons.
## Uses CSG boolean case when mount type is specified.
func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var mount: String = str(_grid_config.get("mount", ""))

	# Build controls (frameless when using CSG case)
	var use_csg := mount in ["shelf", "wall", "floor"]
	var panel: Node3D = RackTpl.create_panel("CA RULES", [
		[
			{"type": "slider_h", "label": "RULE", "default": float(rule) / 255.0},
			{"type": "slider_h", "label": "SPEED", "default": (generations_per_second - 1.0) / 29.0},
		],
		[
			{"type": "button", "label": "30"},
			{"type": "button", "label": "90"},
			{"type": "button", "label": "110"},
			{"type": "button", "label": "184"},
			{"type": "button", "label": "RST"},
		],
	], use_csg)

	if use_csg:
		# CSG boolean case — size and style from mount type
		var case_w := 0.30
		var case_h := 0.20
		var case_d := 0.16
		var tilt := 35.0
		var color := Color(0.12, 0.12, 0.12)
		match mount:
			"wall":
				case_d = 0.04
				tilt = 0.0
			"floor":
				case_h = 0.25
				tilt = 25.0
				color = Color(0.55, 0.38, 0.22)
		_control_panel = RackTpl.create_csg_case(case_w, case_h, case_d, tilt, panel, color)
		_control_panel.position = Vector3(0, 0.04, board_size / 2 + 0.15)
	else:
		# Standalone framed panel (backward compatible)
		_control_panel = panel
		_control_panel.position = Vector3(0, 0.04, board_size / 2 + 0.15)
		_control_panel.rotation_degrees = Vector3(PANEL_TILT_DEG, 0, 0)

	add_child(_control_panel)
	_created_nodes.append(_control_panel)

	# Find controls (may be deep in CSG hierarchy)
	_rule_slider = _control_panel.find_child("Param_0", true, false)
	_speed_slider = _control_panel.find_child("Param_1", true, false)

	if _rule_slider and _rule_slider.has_signal("slider_moved"):
		_rule_slider.slider_moved.connect(_on_rule_slider_moved)
	if _speed_slider and _speed_slider.has_signal("slider_moved"):
		_speed_slider.slider_moved.connect(_on_speed_slider_moved)

	# Preset buttons: 30, 90, 110, 184
	var presets := [30, 90, 110, 184]
	for i in presets.size():
		var btn: Node = _control_panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var rule_val: int = presets[i]
			var area = btn.get_node_or_null("InteractableAreaButton")
			if area:
				area.button_pressed.connect(func(_b): _on_preset_pressed(rule_val))

	# RST button (Btn_4)
	var rst_btn: Node = _control_panel.find_child("Btn_4", true, false)
	if rst_btn:
		var rst_area = rst_btn.get_node_or_null("InteractableAreaButton")
		if rst_area:
			rst_area.button_pressed.connect(func(_b): _on_reset_pressed())

func _sync_rule_slider() -> void:
	if _rule_slider and _rule_slider.has_method("set_normalized_value"):
		_rule_slider.set_normalized_value(float(rule) / 255.0)

func _sync_speed_slider() -> void:
	if _speed_slider and _speed_slider.has_method("set_normalized_value"):
		_speed_slider.set_normalized_value((generations_per_second - 1.0) / 29.0)

func _on_rule_slider_moved(_position) -> void:
	if _rule_slider and _rule_slider.has_method("get_normalized_value"):
		var norm = _rule_slider.get_normalized_value()
		var new_rule = int(norm * 255.0)
		if new_rule != rule:
			rule = new_rule

func _on_speed_slider_moved(_position) -> void:
	if _speed_slider and _speed_slider.has_method("get_normalized_value"):
		var norm = _speed_slider.get_normalized_value()
		generations_per_second = 1.0 + norm * 29.0

func _on_preset_pressed(preset_rule: int) -> void:
	rule = preset_rule

func _on_reset_pressed() -> void:
	_reset()

## Update the rule label text with name if it's a famous rule
func _update_rule_display() -> void:
	var rule_name = FAMOUS_RULES.get(rule, "")
	if rule_name != "":
		_rule_label.text = "RULE %d\n%s" % [rule, rule_name]
	else:
		_rule_label.text = "RULE %d" % rule

## Clear grid and seed the center cell of the first row
func _reset() -> void:
	_grid.clear()
	_current_row.clear()
	_current_row.resize(cells_x)
	for i in range(cells_x):
		_current_row[i] = false
	_current_row[cells_x / 2] = true
	_grid.append(_current_row.duplicate())
	_update_display()

## Evaluate the rule bit for a 3-cell neighborhood
func _apply_rule(left: bool, center: bool, right: bool) -> bool:
	var neighborhood = (int(left) << 2) | (int(center) << 1) | int(right)
	return (rule >> neighborhood) & 1 == 1

## Compute next generation and scroll the grid
func _advance() -> void:
	var new_row: Array[bool] = []
	new_row.resize(cells_x)

	for i in range(cells_x):
		var left = _current_row[(i - 1 + cells_x) % cells_x]
		var center = _current_row[i]
		var right = _current_row[(i + 1) % cells_x]
		new_row[i] = _apply_rule(left, center, right)

	_current_row = new_row
	_grid.push_front(new_row.duplicate())

	while _grid.size() > rows_visible:
		_grid.pop_back()

	_update_display()

## Push grid state to MultiMesh instance colors
func _update_display() -> void:
	for row in range(mini(_grid.size(), rows_visible)):
		var row_data = _grid[row]
		for col in range(cells_x):
			var idx = row * cells_x + col
			var alive = row_data[col] if col < row_data.size() else false
			var color = alive_color if alive else dead_color
			_multimesh.set_instance_color(idx, color)

func _process(delta: float) -> void:
	if not auto_run:
		return

	_generation_timer += delta
	var interval = 1.0 / generations_per_second

	if _generation_timer >= interval:
		_generation_timer = 0.0
		_advance()

# Keep keyboard for desktop testing
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				rule = (rule - 1 + 256) % 256
			KEY_RIGHT:
				rule = (rule + 1) % 256
			KEY_R:
				_reset()
			KEY_SPACE:
				auto_run = not auto_run
			KEY_1:
				rule = 30
			KEY_2:
				rule = 90
			KEY_3:
				rule = 110
			KEY_4:
				rule = 184

## External API

## Set the active rule number (clamped 0–255)
func set_rule(new_rule: int) -> void:
	rule = clampi(new_rule, 0, 255)

func get_rule() -> int:
	return rule

## Toggle between running and paused
func toggle_pause() -> void:
	auto_run = not auto_run

## Advance one generation manually
func step() -> void:
	_advance()

func apply_grid_config(config_data: Dictionary) -> void:
	_grid_config = config_data
	if config_data.has("rule"):
		rule = clampi(int(config_data["rule"]), 0, 255)
	if config_data.has("speed"):
		generations_per_second = clampf(float(config_data["speed"]), 1.0, 30.0)
