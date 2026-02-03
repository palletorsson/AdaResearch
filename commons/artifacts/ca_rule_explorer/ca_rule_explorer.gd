# ca_rule_explorer.gd
# 1×1m horizontal board displaying Wolfram 1D cellular automata
# VR-enabled with slider and button controls

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
		rule = clampi(value, 0, 255)
		if is_inside_tree():
			_reset()
			_update_rule_display()
			_sync_rule_slider()

## Animation
@export var generations_per_second: float = 10.0:
	set(value):
		generations_per_second = clampf(value, 1.0, 30.0)
		if is_inside_tree():
			_sync_speed_slider()

@export var auto_run: bool = true

## Colors
@export var alive_color: Color = Color(0.2, 0.9, 0.4)
@export var dead_color: Color = Color(0.05, 0.08, 0.05)
@export var board_color: Color = Color(0.1, 0.12, 0.1)

# Internal state
var _current_row: Array[bool] = []
var _grid: Array[Array] = []
var _multimesh_instance: MultiMeshInstance3D
var _multimesh: MultiMesh
var _cell_size: Vector2
var _generation_timer: float = 0.0
var _rule_label: Label3D

# VR Controls
var _rule_slider: Node
var _speed_slider: Node
var _control_panel: Node3D

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

const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

func _ready():
	_cell_size = Vector2(board_size / cells_x, board_size / rows_visible)
	_create_board()
	_create_multimesh()
	_create_rule_display()
	_create_vr_controls()
	_reset()

func _create_board():
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
	
	_create_frame()

func _create_frame():
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.2, 0.22, 0.25)
	frame_mat.metallic = 0.6
	frame_mat.roughness = 0.4
	
	var thickness = 0.02
	var height = 0.03
	var half = board_size / 2.0
	
	var edges = [
		Vector3(0, height/2, -half - thickness/2),
		Vector3(0, height/2, half + thickness/2),
		Vector3(-half - thickness/2, height/2, 0),
		Vector3(half + thickness/2, height/2, 0)
	]
	var sizes = [
		Vector3(board_size + thickness*2, height, thickness),
		Vector3(board_size + thickness*2, height, thickness),
		Vector3(thickness, height, board_size),
		Vector3(thickness, height, board_size)
	]
	
	for i in range(4):
		var edge = MeshInstance3D.new()
		var ebox = BoxMesh.new()
		ebox.size = sizes[i]
		edge.mesh = ebox
		edge.material_override = frame_mat
		edge.position = edges[i]
		add_child(edge)

func _create_multimesh():
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.instance_count = cells_x * rows_visible
	
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
	add_child(_rule_label)
	_update_rule_display()

func _create_vr_controls():
	# Control panel behind the board
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.04, board_size/2 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)  # Angled toward user
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.5, 0.2, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)
	
	# Rule slider (0-255)
	_rule_slider = SLIDER_HORIZONTAL.instantiate()
	_rule_slider.name = "RuleSlider"
	_rule_slider.position = Vector3(-0.12, 0.05, 0)
	_rule_slider.rotation_degrees.x = -30
	_rule_slider.set_range(0, 255)
	var rule_label = _rule_slider.get_node_or_null("Frame/LabelName")
	if rule_label:
		rule_label.text = "RULE"
	_control_panel.add_child(_rule_slider)
	_rule_slider.slider_moved.connect(_on_rule_slider_moved)
	
	# Speed slider (1-30 gen/sec)
	_speed_slider = SLIDER_HORIZONTAL.instantiate()
	_speed_slider.name = "SpeedSlider"
	_speed_slider.position = Vector3(0.12, 0.05, 0)
	_speed_slider.rotation_degrees.x = -30
	_speed_slider.set_range(1, 30)
	var speed_label = _speed_slider.get_node_or_null("Frame/LabelName")
	if speed_label:
		speed_label.text = "SPEED"
	_control_panel.add_child(_speed_slider)
	_speed_slider.slider_moved.connect(_on_speed_slider_moved)
	
	# Preset buttons
	var presets = [30, 90, 110, 184]
	var btn_x_start = -0.18
	for i in range(presets.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Preset%d" % presets[i]
		btn.position = Vector3(btn_x_start + i * 0.07, -0.05, 0)
		_control_panel.add_child(btn)
		
		# Label for button
		var btn_label = Label3D.new()
		btn_label.text = str(presets[i])
		btn_label.pixel_size = 0.001
		btn_label.font_size = 14
		btn_label.position = Vector3(0, -0.025, 0)
		btn.add_child(btn_label)
		
		# Connect signal - use lambda with captured value
		var rule_val = presets[i]
		var area_btn = btn.get_node_or_null("InteractableAreaButton")
		if area_btn:
			area_btn.button_pressed.connect(func(): _on_preset_pressed(rule_val))
	
	# Reset button
	var reset_btn = PUSH_BUTTON.instantiate()
	reset_btn.name = "ResetButton"
	reset_btn.position = Vector3(0.18, -0.05, 0)
	reset_btn.rotation_degrees.x = -30
	_control_panel.add_child(reset_btn)
	
	var reset_label = Label3D.new()
	reset_label.text = "RST"
	reset_label.pixel_size = 0.001
	reset_label.font_size = 14
	reset_label.position = Vector3(0, -0.025, 0)
	reset_btn.add_child(reset_label)
	
	var reset_area = reset_btn.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(_on_reset_pressed)
	
	# Sync initial values
	call_deferred("_sync_sliders_deferred")

func _sync_sliders_deferred():
	_sync_rule_slider()
	_sync_speed_slider()

func _sync_rule_slider():
	if _rule_slider and _rule_slider.has_method("set_normalized_value"):
		_rule_slider.set_normalized_value(float(rule) / 255.0)

func _sync_speed_slider():
	if _speed_slider and _speed_slider.has_method("set_normalized_value"):
		_speed_slider.set_normalized_value((generations_per_second - 1.0) / 29.0)

func _on_rule_slider_moved(_position):
	if _rule_slider and _rule_slider.has_method("get_normalized_value"):
		var norm = _rule_slider.get_normalized_value()
		var new_rule = int(norm * 255.0)
		if new_rule != rule:
			rule = new_rule

func _on_speed_slider_moved(_position):
	if _speed_slider and _speed_slider.has_method("get_normalized_value"):
		var norm = _speed_slider.get_normalized_value()
		generations_per_second = 1.0 + norm * 29.0

func _on_preset_pressed(preset_rule: int):
	rule = preset_rule

func _on_reset_pressed():
	_reset()

func _update_rule_display():
	var rule_name = FAMOUS_RULES.get(rule, "")
	if rule_name != "":
		_rule_label.text = "RULE %d\n%s" % [rule, rule_name]
	else:
		_rule_label.text = "RULE %d" % rule

func _reset():
	_grid.clear()
	_current_row.clear()
	_current_row.resize(cells_x)
	for i in range(cells_x):
		_current_row[i] = false
	_current_row[cells_x / 2] = true
	_grid.append(_current_row.duplicate())
	_update_display()

func _apply_rule(left: bool, center: bool, right: bool) -> bool:
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

# Keep keyboard for desktop testing
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

## External API
func set_rule(new_rule: int):
	rule = clampi(new_rule, 0, 255)

func get_rule() -> int:
	return rule

func toggle_pause():
	auto_run = not auto_run

func step():
	_advance()