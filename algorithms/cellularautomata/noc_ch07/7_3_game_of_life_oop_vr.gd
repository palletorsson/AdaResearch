extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")

@export var grid_size: int = 20
@export var update_interval: float = 0.35
@export var survive_min: int = 2
@export var survive_max: int = 3
@export var birth_value: int = 3

var _sim_root: Node3D
var _cells: Array[Cell] = []
var _mesh: MeshInstance3D
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


	_mesh = MeshInstance3D.new()
	_sim_root.add_child(_mesh)

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
			_cells.append(Cell.new(x, y, alive))
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
		var alive := cell.alive
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

func _cell(x: int, y: int) -> Cell:
	return _cells[y * grid_size + x]

func _update_mesh() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var cell := 0.9 / grid_size
	for c in _cells:
		if not c.alive:
			continue
		mesh.surface_set_color(Color(1.0, 0.7, 0.95))
		var x0 := -0.45 + c.x * cell
		var x1 := x0 + cell * 0.95
		var y0 := 0.15 + c.y * cell * 0.6
		var y1 := y0 + cell * 0.55
		# Triangle 1
		mesh.surface_add_vertex(Vector3(x0, y0, 0))
		mesh.surface_add_vertex(Vector3(x1, y0, 0))
		mesh.surface_add_vertex(Vector3(x1, y1, 0))
		# Triangle 2
		mesh.surface_add_vertex(Vector3(x0, y0, 0))
		mesh.surface_add_vertex(Vector3(x1, y1, 0))
		mesh.surface_add_vertex(Vector3(x0, y1, 0))
	mesh.surface_end()
	_mesh.mesh = mesh

func _update_status() -> void:
	_status_label.text = "OOP Game of Life | Gen %d" % _generation

class Cell:
	var x: int
	var y: int
	var alive: bool

	func _init(ix: int, iy: int, state: bool) -> void:
		x = ix
		y = iy
		alive = state
