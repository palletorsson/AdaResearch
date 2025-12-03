extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")

@export var grid_size: int = 20
@export var update_interval: float = 0.35
@export var survive_min: int = 2
@export var survive_max: int = 3
@export var birth_value: int = 3

var _sim_root: Node3D
var _cells: Array[OopCell] = []
var _multi_mesh: MultiMeshInstance3D
var _timer: float = 0.0
var _status_label: Label3D
var _generation: int = 1

func _ready() -> void:
	_setup_environment()
	_init_cells()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)

	_multi_mesh = MultiMeshInstance3D.new()
	_sim_root.add_child(_multi_mesh)
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	var cell_size = 0.9 / grid_size
	mm.mesh.size = Vector3(cell_size * 0.95, cell_size * 0.55, 0.01)
	mm.instance_count = grid_size * grid_size
	_multi_mesh.multimesh = mm
	
	# Initialize transforms
	var idx = 0
	for y in range(grid_size):
		for x in range(grid_size):
			var x_pos = -0.45 + x * cell_size + cell_size * 0.5
			var y_pos = 0.15 + y * cell_size * 0.6 + cell_size * 0.275
			var t = Transform3D(Basis(), Vector3(x_pos, y_pos, 0))
			mm.set_instance_transform(idx, t)
			mm.set_instance_color(idx, Color(0,0,0,0))
			idx += 1

	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 22
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.82, 0)
	_sim_root.add_child(_status_label)

	var controller_root := Node3D.new()
	controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(controller_root)

	var survive_controller := CONTROLLER_SCENE.instantiate()
	survive_controller.parameter_name = "Survive Min"
	survive_controller.min_value = 1
	survive_controller.max_value = 4
	survive_controller.step_size = 1
	survive_controller.default_value = survive_min
	survive_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(survive_controller)
	survive_controller.value_changed.connect(func(v: float) -> void:
		survive_min = int(v)
	)
	survive_controller.set_value(survive_min)

	var survive_max_controller := CONTROLLER_SCENE.instantiate()
	survive_max_controller.parameter_name = "Survive Max"
	survive_max_controller.min_value = 2
	survive_max_controller.max_value = 4
	survive_max_controller.step_size = 1
	survive_max_controller.default_value = survive_max
	survive_max_controller.position = Vector3(0, -0.18, 0)
	survive_max_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(survive_max_controller)
	survive_max_controller.value_changed.connect(func(v: float) -> void:
		survive_max = int(v)
	)
	survive_max_controller.set_value(survive_max)

	var birth_controller := CONTROLLER_SCENE.instantiate()
	birth_controller.parameter_name = "Birth"
	birth_controller.min_value = 2
	birth_controller.max_value = 4
	birth_controller.step_size = 1
	birth_controller.default_value = birth_value
	birth_controller.position = Vector3(0, -0.36, 0)
	birth_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(birth_controller)
	birth_controller.value_changed.connect(func(v: float) -> void:
		birth_value = int(v)
	)
	birth_controller.set_value(birth_value)

	_update_status()

func _init_cells() -> void:
	_cells.clear()
	for y in range(grid_size):
		for x in range(grid_size):
			var alive := randf() < 0.3
			_cells.append(OopCell.new(x, y, alive))
	_generation = 1
	_update_mesh()

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= update_interval:
		_timer = 0.0
		_step_generation()

func _step_generation() -> void:
	var next_states := PackedByteArray()
	next_states.resize(_cells.size())
	for i in range(_cells.size()):
		var cell := _cells[i]
		var neighbors := _count_neighbors(cell.x, cell.y)
		var alive = cell.alive
		var next := 0
		if alive and (neighbors >= survive_min and neighbors <= survive_max):
			next = 1
		elif not alive and neighbors == birth_value:
			next = 1
		next_states[i] = next

	for i in range(_cells.size()):
		_cells[i].alive = next_states[i] == 1

	_generation += 1
	_update_mesh()
	_update_status()

func _count_neighbors(x: int, y: int) -> int:
	var total := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx := (x + dx + grid_size) % grid_size
			var ny := (y + dy + grid_size) % grid_size
			if _cell(nx, ny).alive:
				total += 1
	return total

func _cell(x: int, y: int) -> OopCell: 
	return _cells[y * grid_size + x]

func _update_mesh() -> void:
	var mm = _multi_mesh.multimesh
	var active_color = Color(1.0, 0.7, 0.95)
	var inactive_color = Color(0,0,0,0)
	
	for i in range(_cells.size()):
		if _cells[i].alive:
			mm.set_instance_color(i, active_color)
		else:
			mm.set_instance_color(i, inactive_color)

func _update_status() -> void:
	_status_label.text = "OOP Game of Life | Gen %d" % _generation

class OopCell:
	var x: int
	var y: int
	var alive: bool

	func _init(ix: int, iy: int, state: bool) -> void:
		x = ix
		y = iy
		alive = state
