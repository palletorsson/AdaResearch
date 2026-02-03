# game_of_life_petri.gd
# Conway's Game of Life in a petri dish
# VR-enabled with pattern presets and drawing
#
# Rules: B3/S23
# - Birth: dead cell with exactly 3 neighbors → alive
# - Survival: live cell with 2 or 3 neighbors → stays alive
# - Death: otherwise

extends Node3D

class_name GameOfLifePetri

## Dish dimensions
@export var dish_size: float = 0.8

## Grid resolution
@export var grid_size: int = 64

## Animation
@export var generations_per_second: float = 8.0:
	set(value):
		generations_per_second = clampf(value, 1.0, 30.0)
		_sync_speed_slider()

@export var auto_run: bool = true

## Colors
@export var alive_color: Color = Color(0.2, 1.0, 0.4)
@export var dead_color: Color = Color(0.02, 0.05, 0.02)
@export var dish_color: Color = Color(0.15, 0.15, 0.18)

# Patterns
const PATTERNS = {
	"glider": [[0,1,0], [0,0,1], [1,1,1]],
	"blinker": [[1,1,1]],
	"toad": [[0,1,1,1], [1,1,1,0]],
	"beacon": [[1,1,0,0], [1,0,0,0], [0,0,0,1], [0,0,1,1]],
	"pulsar": [
		[0,0,1,1,1,0,0,0,1,1,1,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0],
		[1,0,0,0,0,1,0,1,0,0,0,0,1],
		[1,0,0,0,0,1,0,1,0,0,0,0,1],
		[1,0,0,0,0,1,0,1,0,0,0,0,1],
		[0,0,1,1,1,0,0,0,1,1,1,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,1,1,1,0,0,0,1,1,1,0,0],
		[1,0,0,0,0,1,0,1,0,0,0,0,1],
		[1,0,0,0,0,1,0,1,0,0,0,0,1],
		[1,0,0,0,0,1,0,1,0,0,0,0,1],
		[0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,1,1,1,0,0,0,1,1,1,0,0]
	],
	"glider_gun": [
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1],
		[0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1],
		[1,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[1,1,0,0,0,0,0,0,0,0,1,0,0,0,1,0,1,1,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
	]
}

var _grid: Array[Array] = []
var _next_grid: Array[Array] = []
var _multimesh: MultiMesh
var _multimesh_instance: MultiMeshInstance3D
var _cell_size: float
var _generation_timer: float = 0.0
var _generation: int = 0
var _population: int = 0
var _info_label: Label3D

# VR Controls
var _speed_slider: Node
var _control_panel: Node3D

const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

func _ready():
	_cell_size = dish_size / grid_size
	_create_dish()
	_create_multimesh()
	_create_labels()
	_create_vr_controls()
	_init_grid()
	_spawn_pattern("glider", grid_size/4, grid_size/4)
	_spawn_pattern("pulsar", grid_size/2, grid_size/2)

func _create_dish():
	# Petri dish base
	var dish = MeshInstance3D.new()
	dish.name = "Dish"
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = dish_size * 0.55
	cylinder.bottom_radius = dish_size * 0.6
	cylinder.height = 0.04
	dish.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = dish_color
	mat.metallic = 0.6
	mat.roughness = 0.4
	dish.material_override = mat
	
	dish.position = Vector3(0, -0.02, 0)
	add_child(dish)
	
	# Glass rim
	var rim = MeshInstance3D.new()
	rim.name = "Rim"
	var torus = TorusMesh.new()
	torus.inner_radius = dish_size * 0.5
	torus.outer_radius = dish_size * 0.55
	rim.mesh = torus
	
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.8, 0.9, 1.0, 0.3)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.metallic = 0.2
	glass_mat.roughness = 0.1
	rim.material_override = glass_mat
	rim.position = Vector3(0, 0.01, 0)
	add_child(rim)

func _create_multimesh():
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.instance_count = grid_size * grid_size
	
	var cell_mesh = BoxMesh.new()
	cell_mesh.size = Vector3(_cell_size * 0.9, 0.005, _cell_size * 0.9)
	_multimesh.mesh = cell_mesh
	
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.4
	
	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "CellMultiMesh"
	_multimesh_instance.multimesh = _multimesh
	_multimesh_instance.material_override = mat
	add_child(_multimesh_instance)
	
	# Initialize positions
	var half = dish_size / 2.0
	for y in range(grid_size):
		for x in range(grid_size):
			var idx = y * grid_size + x
			var px = (x - grid_size / 2.0 + 0.5) * _cell_size
			var pz = (y - grid_size / 2.0 + 0.5) * _cell_size
			
			var transform = Transform3D()
			transform.origin = Vector3(px, 0.01, pz)
			_multimesh.set_instance_transform(idx, transform)
			_multimesh.set_instance_color(idx, dead_color)

func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 24
	_info_label.position = Vector3(0, 0.06, -dish_size/2 - 0.08)
	add_child(_info_label)
	_update_info()

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.04, dish_size/2 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.5, 0.18, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)
	
	# Speed slider
	_speed_slider = SLIDER_HORIZONTAL.instantiate()
	_speed_slider.name = "SpeedSlider"
	_speed_slider.position = Vector3(0, 0.045, 0)
	var speed_label = _speed_slider.get_node_or_null("Frame/LabelName")
	if speed_label:
		speed_label.text = "SPEED"
	_control_panel.add_child(_speed_slider)
	_speed_slider.slider_moved.connect(_on_speed_slider_moved)
	
	# Pattern buttons
	var patterns = ["GLIDER", "PULSAR", "GUN", "RANDOM", "CLEAR"]
	for i in range(patterns.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Pattern%d" % i
		btn.position = Vector3(-0.18 + i * 0.09, -0.035, 0)
		btn.scale = Vector3(0.8, 0.8, 0.8)
		_control_panel.add_child(btn)
		_add_button_label(btn, patterns[i])
		
		var pattern_idx = i
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(): _on_pattern_button(pattern_idx))
	
	call_deferred("_sync_speed_slider")

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 8
	lbl.position = Vector3(0, -0.025, 0)
	btn.add_child(lbl)

func _sync_speed_slider():
	if _speed_slider and _speed_slider.has_method("set_normalized_value"):
		_speed_slider.set_normalized_value((generations_per_second - 1.0) / 29.0)

func _on_speed_slider_moved(_position):
	if _speed_slider and _speed_slider.has_method("get_normalized_value"):
		generations_per_second = 1.0 + _speed_slider.get_normalized_value() * 29.0

func _on_pattern_button(idx: int):
	match idx:
		0:  # Glider
			_clear_grid()
			_spawn_pattern("glider", grid_size/4, grid_size/4)
		1:  # Pulsar
			_clear_grid()
			_spawn_pattern("pulsar", grid_size/2, grid_size/2)
		2:  # Gun
			_clear_grid()
			_spawn_pattern("glider_gun", 5, grid_size/2)
		3:  # Random
			_randomize_grid()
		4:  # Clear
			_clear_grid()

func _init_grid():
	_grid.clear()
	_next_grid.clear()
	for y in range(grid_size):
		var row: Array[bool] = []
		var next_row: Array[bool] = []
		row.resize(grid_size)
		next_row.resize(grid_size)
		for x in range(grid_size):
			row[x] = false
			next_row[x] = false
		_grid.append(row)
		_next_grid.append(next_row)

func _clear_grid():
	for y in range(grid_size):
		for x in range(grid_size):
			_grid[y][x] = false
	_generation = 0
	_update_display()

func _randomize_grid():
	for y in range(grid_size):
		for x in range(grid_size):
			_grid[y][x] = randf() < 0.3
	_generation = 0
	_update_display()

func _spawn_pattern(pattern_name: String, cx: int, cy: int):
	if not PATTERNS.has(pattern_name):
		return
	var pattern = PATTERNS[pattern_name]
	var ph = pattern.size()
	var pw = pattern[0].size()
	
	for py in range(ph):
		for px in range(pw):
			var x = cx - pw/2 + px
			var y = cy - ph/2 + py
			if x >= 0 and x < grid_size and y >= 0 and y < grid_size:
				_grid[y][x] = pattern[py][px] == 1
	_update_display()

func _count_neighbors(x: int, y: int) -> int:
	var count = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = (x + dx + grid_size) % grid_size
			var ny = (y + dy + grid_size) % grid_size
			if _grid[ny][nx]:
				count += 1
	return count

func _advance():
	_population = 0
	for y in range(grid_size):
		for x in range(grid_size):
			var neighbors = _count_neighbors(x, y)
			var alive = _grid[y][x]
			
			if alive:
				_next_grid[y][x] = neighbors == 2 or neighbors == 3
			else:
				_next_grid[y][x] = neighbors == 3
			
			if _next_grid[y][x]:
				_population += 1
	
	# Swap grids
	var temp = _grid
	_grid = _next_grid
	_next_grid = temp
	
	_generation += 1
	_update_display()

func _update_display():
	_population = 0
	for y in range(grid_size):
		for x in range(grid_size):
			var idx = y * grid_size + x
			var alive = _grid[y][x]
			var color = alive_color if alive else dead_color
			_multimesh.set_instance_color(idx, color)
			if alive:
				_population += 1
	_update_info()

func _update_info():
	_info_label.text = "GAME OF LIFE\nGen: %d | Pop: %d" % [_generation, _population]

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
			KEY_SPACE:
				auto_run = not auto_run
			KEY_R:
				_randomize_grid()
			KEY_C:
				_clear_grid()
			KEY_G:
				_clear_grid()
				_spawn_pattern("glider", grid_size/4, grid_size/4)
			KEY_P:
				_clear_grid()
				_spawn_pattern("pulsar", grid_size/2, grid_size/2)
			KEY_U:
				_clear_grid()
				_spawn_pattern("glider_gun", 5, grid_size/2)

func step():
	_advance()

func reset():
	_clear_grid()
