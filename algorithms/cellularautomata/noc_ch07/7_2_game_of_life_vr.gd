extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_ALIVE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_DEAD := preload("res://commons/resourses/materials/noc_vr/noc_vr_fishtank_glass.tres")

@export var grid_size: int = 20
@export var update_interval: float = 0.4
@export var alive_probability: float = 0.3

var _sim_root: Node3D
var _cells: Array[PackedByteArray] = []
var _mesh: MeshInstance3D
var _timer: float = 0.0
var _controller_root: Node3D
var _status_label: Label3D
var _generation: int = 1

func _ready() -> void:
	_setup_environment()
	_initialize_grid()
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

	_controller_root = Node3D.new()
	_controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(_controller_root)

	var probability_controller := CONTROLLER_SCENE.instantiate()
	probability_controller.parameter_name = "Alive %"
	probability_controller.min_value = 0.05
	probability_controller.max_value = 0.9
	probability_controller.default_value = alive_probability
	probability_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(probability_controller)
	probability_controller.value_changed.connect(func(v: float) -> void:
		alive_probability = v
		_initialize_grid()
	)
	probability_controller.set_value(alive_probability)

	_update_status()

func _initialize_grid() -> void:
	_cells.resize(grid_size)
	for y in range(grid_size):
		var row := PackedByteArray()
		row.resize(grid_size)
		for x in range(grid_size):
			row[x] = 1 if randf() < alive_probability else 0
		_cells[y] = row
	_generation = 1
	_update_mesh()

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= update_interval:
		_timer = 0.0
		_step_generation()

func _step_generation() -> void:
	var next: Array[PackedByteArray] = []
	next.resize(grid_size)
	for y in range(grid_size):
		var row := PackedByteArray()
		row.resize(grid_size)
		for x in range(grid_size):
			var alive := _cells[y][x]
			var count := _count_neighbors(x, y)
			if alive == 1 and (count == 2 or count == 3):
				row[x] = 1
			elif alive == 0 and count == 3:
				row[x] = 1
			else:
				row[x] = 0
		next[y] = row
	_cells = next
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
			total += _cells[ny][nx]
	return total

func _update_mesh() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var cell := 0.9 / grid_size
	for y in range(grid_size):
		for x in range(grid_size):
			if _cells[y][x] == 0:
				continue
			var color := Color(1.0, 0.7, 0.95)
			mesh.surface_set_color(color)
			var x0 := -0.45 + x * cell
			var x1 := x0 + cell * 0.95
			var y0 := 0.15 + y * cell * 0.6
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
	_status_label.text = "Game of Life | Generation %d" % _generation
