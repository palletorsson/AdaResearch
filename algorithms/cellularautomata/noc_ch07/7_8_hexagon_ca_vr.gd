extends Node3D


const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")

@export var radius: int = 6
@export var update_interval: float = 0.45
@export var random_flip: float = 0.05

const HEX_DIRECTIONS := [
	Vector2(1, 0), Vector2(1, -1), Vector2(0, -1),
	Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1)
]

var _sim_root: Node3D
var _cells := {} # Dictionary Vector2 -> bool
var _coords: Array[Vector2] = []
var _mesh_root: Node3D
var _timer: float = 0.0
var _generation: int = 1
var _status_label: Label3D

func _ready() -> void:
	_setup_environment()
	_initialize_grid()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)



	_mesh_root = Node3D.new()
	_sim_root.add_child(_mesh_root)

	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 22
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.82, 0)
	_sim_root.add_child(_status_label)

	var controller_root := Node3D.new()
	controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(controller_root)

	var flip_controller := CONTROLLER_SCENE.instantiate()
	flip_controller.parameter_name = "Random Flip"
	flip_controller.min_value = 0.0
	flip_controller.max_value = 0.2
	flip_controller.default_value = random_flip
	flip_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(flip_controller)
	flip_controller.value_changed.connect(func(v: float) -> void:
		random_flip = clamp(v, 0.0, 0.2)
	)
	flip_controller.set_value(random_flip)

	_update_status()

func _initialize_grid() -> void:
	for child in _mesh_root.get_children():
		child.queue_free()
	_cells.clear()
	_coords.clear()

	for q in range(-radius, radius + 1):
		var r_min = max(-radius, -q - radius)
		var r_max = min(radius, -q + radius)
		for r in range(r_min, r_max + 1):
			var coord := Vector2(q, r)
			var alive := randf() < 0.35
			_cells[coord] = alive
			_coords.append(coord)
			_create_hex_instance(coord, alive)

	_generation = 1

func _create_hex_instance(coord: Vector2, alive: bool) -> void:
	var hex := MeshInstance3D.new()
	var hex_mesh := CylinderMesh.new()
	hex_mesh.radial_segments = 6
	hex_mesh.top_radius = 0.065
	hex_mesh.bottom_radius = 0.065
	hex_mesh.height = 0.02
	hex.mesh = hex_mesh
	hex.position = _hex_to_world(coord)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.7, 0.95) if alive else Color(1.0, 0.7, 0.95, 0.18)
	mat.emission_enabled = alive
	mat.emission = Color(1.0, 0.6, 0.95) * 0.4 if alive else Color(0, 0, 0)
	hex.material_override = mat
	_mesh_root.add_child(hex)

func _hex_to_world(coord: Vector2) -> Vector3:
	var x := (sqrt(3.0) * coord.x + sqrt(3.0) / 2.0 * coord.y) * 0.085
	var y := 0.25 + (3.0 / 2.0 * coord.y) * 0.085
	return Vector3(x, y, 0)

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= update_interval:
		_timer = 0.0
		_step_generation()

func _step_generation() -> void:
	var next := {}
	for coord in _coords:
		var neighbors := _count_neighbors(coord)
		var alive = _cells[coord]
		var new_state = alive
		if alive and (neighbors == 2 or neighbors == 3):
			new_state = true
		elif not alive and neighbors == 2:
			new_state = true
		else:
			new_state = false
		if randf() < random_flip:
			new_state = !new_state
		next[coord] = new_state

	_cells = next
	_generation += 1
	_update_mesh_colors()
	_update_status()

func _count_neighbors(coord: Vector2) -> int:
	var total := 0
	for dir in HEX_DIRECTIONS:
		var neighbor = coord + dir
		if _cells.has(neighbor) and _cells[neighbor]:
			total += 1
	return total

func _update_mesh_colors() -> void:
	for i in range(_coords.size()):
		var alive = _cells[_coords[i]]
		var hex := _mesh_root.get_child(i)
		if hex is MeshInstance3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(1.0, 0.7, 0.95) if alive else Color(1.0, 0.7, 0.95, 0.2)
			mat.emission_enabled = alive
			mat.emission = Color(1.0, 0.6, 0.95) * 0.4 if alive else Color(0, 0, 0)
			(hex as MeshInstance3D).material_override = mat

func _update_status() -> void:
	_status_label.text = "Hex CA | Gen %d | Flip %.2f" % [_generation, random_flip]
