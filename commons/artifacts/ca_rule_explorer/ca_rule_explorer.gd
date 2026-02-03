# ca_rule_explorer.gd
# 1×1m horizontal board displaying Wolfram 1D cellular automata
# Interactive rule selection (0-255), shows pattern evolution

extends Node3D

class_name CARuleExplorer

## Board dimensions
@export var board_size: float = 1.0

## Grid resolution
@export var cells_x: int = 64
@export var rows_visible: int = 50

## Current rule (0-255)
@export_range(0, 255) var rule: int = 110:
	set(value):
		rule = value
		if is_inside_tree():
			_reset()
			_update_rule_display()

## Animation
@export var generations_per_second: float = 10.0
@export var auto_run: bool = true

## Colors
@export var alive_color: Color = Color(0.2, 0.9, 0.4)
@export var dead_color: Color = Color(0.05, 0.08, 0.05)
@export var board_color: Color = Color(0.1, 0.12, 0.1)

# Internal state
var _current_row: Array[bool] = []
var _grid: Array[Array] = []  # History of rows
var _multimesh_instance: MultiMeshInstance3D
var _multimesh: MultiMesh
var _cell_size: Vector2
var _generation_timer: float = 0.0
var _rule_label: Label3D

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

func _ready():
	_cell_size = Vector2(board_size / cells_x, board_size / rows_visible)
	_create_board()
	_create_multimesh()
	_create_rule_display()
	_create_controls_hint()
	_reset()

func _create_board():
	# Base board (horizontal surface)
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
	
	# Frame/edge
	_create_frame()

func _create_frame():
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.2, 0.22, 0.25)
	frame_mat.metallic = 0.6
	frame_mat.roughness = 0.4
	
	var thickness = 0.02
	var height = 0.03
	var half = board_size / 2.0
	
	# Four edges
	var edges = [
		Vector3(0, height/2, -half - thickness/2),  # Front
		Vector3(0, height/2, half + thickness/2),   # Back
		Vector3(-half - thickness/2, height/2, 0),  # Left
		Vector3(half + thickness/2, height/2, 0)    # Right
	]
	var sizes = [
		Vector3(board_size + thickness*2, height, thickness),
		Vector3(board_size + thickness*2, height, thickness),
		Vector3(thickness, height, board_size),
		Vector3(thickness, height, board_size)
	]
	
	for i in range(4):
		var edge = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = sizes[i]
		edge.mesh = box
		edge.material_override = frame_mat
		edge.position = edges[i]
		add_child(edge)

func _create_multimesh():
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.instance_count = cells_x * rows_visible
	
	# Small flat box for each cell
	var cell_mesh = BoxMesh.new()
	cell_mesh.size = Vector3(_cell_size.x * 0.95, 0.005, _cell_size.y * 0.95)
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
	
	# Initialize positions
	var half = board_size / 2.0
	for row in range(rows_visible):
		for col in range(cells_x):
			var idx = row * cells_x + col
			var x = (col - cells_x / 2.0 + 0.5) * _cell_size.x
			var z = (row - rows_visible / 2.0 + 0.5) * _cell_size.y
			
			var transform = Transform3D()
			transform.origin = Vector3(x, 0.015, z)
			_multimesh.set_instance_transform(idx, transform)
			_multimesh.set_instance_color(idx, dead_color)

func _create_rule_display():
	_rule_label = Label3D.new()
	_rule_label.name = "RuleLabel"
	_rule_label.pixel_size = 0.002
	_rule_label.font_size = 48
	_rule_label.position = Vector3(0, 0.05, -board_size/2 - 0.08)
	_rule_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_rule_label)
	_update_rule_display()

func _create_controls_hint():
	var hint = Label3D.new()
	hint.name = "ControlsHint"
	hint.pixel_size = 0.001
	hint.font_size = 24
	hint.text = "← → Change Rule  |  R Reset  |  Space Pause"
	hint.position = Vector3(0, 0.03, board_size/2 + 0.06)
	hint.modulate = Color(0.6, 0.6, 0.6)
	add_child(hint)

func _update_rule_display():
	var rule_name = FAMOUS_RULES.get(rule, "")
	if rule_name != "":
		_rule_label.text = "RULE %d\n%s" % [rule, rule_name]
	else:
		_rule_label.text = "RULE %d" % rule

func _reset():
	# Clear grid
	_grid.clear()
	
	# Initialize first row - single cell in center
	_current_row.clear()
	_current_row.resize(cells_x)
	for i in range(cells_x):
		_current_row[i] = false
	_current_row[cells_x / 2] = true
	
	_grid.append(_current_row.duplicate())
	_update_display()

func _apply_rule(left: bool, center: bool, right: bool) -> bool:
	# Wolfram elementary CA rule encoding
	var neighborhood = (int(left) << 2) | (int(center) << 1) | int(right)
	return (rule >> neighborhood) & 1 == 1

func _advance():
	var new_row: Array[bool] = []
	new_row.resize(cells_x)
	
	for i in range(cells_x):
		var left = _current_row[(i - 1 + cells_x) % cells_x]
		var center = _current_row[i]
		var right = _current_row[(i + 1) % cells_x]
		new_row[i] = _apply_rule(left, center, right)
	
	_current_row = new_row
	_grid.push_front(new_row.duplicate())
	
	# Keep only visible rows
	while _grid.size() > rows_visible:
		_grid.pop_back()
	
	_update_display()

func _update_display():
	for row in range(mini(_grid.size(), rows_visible)):
		var row_data = _grid[row]
		for col in range(cells_x):
			var idx = row * cells_x + col
			var alive = row_data[col] if col < row_data.size() else false
			var color = alive_color if alive else dead_color
			_multimesh.set_instance_color(idx, color)

func _process(delta):
	if not auto_run:
		return
	
	_generation_timer += delta
	var interval = 1.0 / generations_per_second
	
	if _generation_timer >= interval:
		_generation_timer = 0.0
		_advance()

func _input(event):
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

## Set rule externally (for sliders)
func set_rule(new_rule: int):
	rule = clampi(new_rule, 0, 255)

## Get current rule
func get_rule() -> int:
	return rule

## Toggle auto-run
func toggle_pause():
	auto_run = not auto_run

## Step one generation manually
func step():
	_advance()
