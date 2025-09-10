# BaseCA.gd
# Base class for all Cellular Automata implementations
class_name BaseCA
extends Node3D

# Common constants
const GRID_SIZE = 64
const CUBE_SIZE = 0.1
# Added a constant to match the step size in the child script (DiseaseSpreadCA.gd)
# This is crucial for making the cubes touch and removing the gutter.
const VISUALIZATION_STEP = 4

# Common variables
var grid: Array = []
var mesh_instance: MeshInstance3D
var materials: Dictionary = {}
var iteration_count = 0
var is_running = false

# Common materials
var material_occupied: StandardMaterial3D
var material_empty: StandardMaterial3D
var material_active: StandardMaterial3D

func _ready():
	setup_common_materials()
	create_mesh_instance()
	initialize_grid()
	start_simulation()

func setup_common_materials():
	# Create common materials for all CA types
	material_occupied = StandardMaterial3D.new()
	material_occupied.albedo_color = Color.WHITE
	material_occupied.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	
	material_empty = StandardMaterial3D.new()
	material_empty.albedo_color = Color.BLACK
	material_empty.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	
	material_active = StandardMaterial3D.new()
	# The infected cubes were originally a blue color.
	# This changes them to white to match the user's request.
	material_active.albedo_color = Color.WHITE
	material_active.emission_enabled = false

func create_mesh_instance():
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)

func initialize_grid():
	# Override in subclasses
	pass

func start_simulation():
	is_running = true
	print("Starting CA simulation: ", get_script().get_global_name())

func stop_simulation():
	is_running = false
	print("Stopping CA simulation")

func _process(delta):
	if is_running:
		update_simulation(delta)
		iteration_count += 1

func update_simulation(delta):
	# Override in subclasses
	pass

func update_visualization():
	# Override in subclasses
	pass

# Helper functions for grid creation
func create_3d_grid() -> Array:
	var grid = []
	grid.resize(GRID_SIZE)
	
	for x in range(GRID_SIZE):
		grid[x] = []
		grid[x].resize(GRID_SIZE)
		for y in range(GRID_SIZE):
			grid[x][y] = []
			grid[x][y].resize(GRID_SIZE)
			for z in range(GRID_SIZE):
				grid[x][y][z] = 0
	
	return grid

func create_2d_grid() -> Array:
	var grid = []
	grid.resize(GRID_SIZE)
	
	for x in range(GRID_SIZE):
		grid[x] = []
		grid[x].resize(GRID_SIZE)
		for y in range(GRID_SIZE):
			grid[x][y] = 0
	
	return grid

# Helper functions for neighbor detection
func get_3d_neighbors(pos: Vector3i) -> Array:
	var neighbors = []
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for dz in range(-1, 2):
				if dx == 0 and dy == 0 and dz == 0:
					continue
				neighbors.append(Vector3i(pos.x + dx, pos.y + dy, pos.z + dz))
	return neighbors

func get_2d_neighbors(pos: Vector2i) -> Array:
	var neighbors = []
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			neighbors.append(Vector2i(pos.x + dx, pos.y + dy))
	return neighbors

func is_valid_3d_position(pos: Vector3i) -> bool:
	return pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE and pos.z >= 0 and pos.z < GRID_SIZE

func is_valid_2d_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE

# Visualization helper
func create_cube_at_position(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array, start_index: int, x: int, y: int, z: int, state: int = 1):
	var world_pos = Vector3(
		(x - GRID_SIZE/2) * CUBE_SIZE,
		(y - GRID_SIZE/2) * CUBE_SIZE,
		(z - GRID_SIZE/2) * CUBE_SIZE
	)
	
	# The cube size is now scaled by the step to remove the gutter
	var size = CUBE_SIZE * VISUALIZATION_STEP
	var half_size = size * 0.5
	
	# Cube vertices
	var cube_verts = [
		world_pos + Vector3(-half_size, -half_size, -half_size),
		world_pos + Vector3(half_size, -half_size, -half_size),
		world_pos + Vector3(half_size, half_size, -half_size),
		world_pos + Vector3(-half_size, half_size, -half_size),
		world_pos + Vector3(-half_size, -half_size, half_size),
		world_pos + Vector3(half_size, -half_size, half_size),
		world_pos + Vector3(half_size, half_size, half_size),
		world_pos + Vector3(-half_size, half_size, half_size)
	]
	
	for vert in cube_verts:
		vertices.push_back(vert)
	
	# Cube normals
	var cube_normals = [
		Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD,
		Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK
	]
	
	for normal in cube_normals:
		normals.push_back(normal)
	
	# Cube indices (12 triangles, 6 faces)
	var cube_indices = [
		# Front face
		0, 1, 2, 0, 2, 3,
		# Back face
		4, 6, 5, 4, 7, 6,
		# Left face
		0, 3, 7, 0, 7, 4,
		# Right face
		1, 5, 6, 1, 6, 2,
		# Bottom face
		0, 4, 5, 0, 5, 1,
		# Top face
		3, 2, 6, 3, 6, 7
	]
	
	for index in cube_indices:
		indices.push_back(start_index + index)

# Utility functions
func duplicate_3d_grid(grid: Array) -> Array:
	var new_grid = []
	new_grid.resize(GRID_SIZE)
	
	for x in range(GRID_SIZE):
		new_grid[x] = []
		new_grid[x].resize(GRID_SIZE)
		for y in range(GRID_SIZE):
			new_grid[x][y] = grid[x][y].duplicate()
	
	return new_grid

func duplicate_2d_grid(grid: Array) -> Array:
	var new_grid = []
	new_grid.resize(GRID_SIZE)
	
	for x in range(GRID_SIZE):
		new_grid[x] = grid[x].duplicate()
	
	return new_grid
