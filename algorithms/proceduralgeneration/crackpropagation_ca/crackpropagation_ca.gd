# CrackPropagation.gd
# Attach this script to a Node3D in your scene
extends Node3D

const GRID_SIZE = 64
const CUBE_SIZE = 1.0
const CRACK_THRESHOLD = 0.3
const PROPAGATION_RATE = 0.02
const CRACK_PROPAGATION_CHANCE = 0.5 # New: chance for a cracked cell to start a new arm

var grid: Array = []
var stress_grid: Array = []
var crack_mesh: MeshInstance3D
var crack_material: StandardMaterial3D

# Cellular automata states
enum CellState {
	INTACT = 0,
	STRESSED = 1,
	CRACKED = 2,
}

func _ready():
	setup_crack_system()
	initialize_grid()
	create_crack_mesh()
	
	# Start the crack propagation
	add_initial_stress_points()

func setup_crack_system():
	# Initialize 2D arrays
	grid.resize(GRID_SIZE)
	stress_grid.resize(GRID_SIZE)
	
	for x in range(GRID_SIZE):
		grid[x] = []
		stress_grid[x] = []
		grid[x].resize(GRID_SIZE)
		stress_grid[x].resize(GRID_SIZE)
		
		for z in range(GRID_SIZE):
			grid[x][z] = CellState.INTACT
			stress_grid[x][z] = 0.0

func initialize_grid():
	# Add some random material weakness
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			if randf() < 0.05:  # 5% chance of weak spots
				stress_grid[x][z] = randf_range(0.1, 0.25)

func create_crack_mesh():
	crack_mesh = MeshInstance3D.new()
	add_child(crack_mesh)
	
	# Create material for cracks
	crack_material = StandardMaterial3D.new()
	crack_material.albedo_color = Color(0.2, 0.1, 0.0)  # Dark brown cracks
	crack_material.roughness = 0.8
	crack_material.metallic = 0.0
	
	update_crack_mesh()

func add_initial_stress_points():
	# Start from a single point in the center
	var x = GRID_SIZE / 2
	var z = GRID_SIZE / 2
	
	stress_grid[x][z] = 1.0 # High initial stress
	grid[x][z] = CellState.STRESSED
	
	# Add stress in surrounding area to start the propagation
	for dx in range(-2, 3):
		for dz in range(-2, 3):
			var nx = x + dx
			var nz = z + dz
			if is_valid_position(nx, nz):
				var distance = sqrt(dx*dx + dz*dz)
				if distance > 0:
					stress_grid[nx][nz] += 0.6 / distance
					if stress_grid[nx][nz] > CRACK_THRESHOLD:
						grid[nx][nz] = CellState.STRESSED
	
	print("Added initial stress concentrator at center")

func _process(_delta):
	update_cellular_automata()
	update_crack_mesh()

func update_cellular_automata():
	var new_grid = duplicate_grid()
	var new_stress = duplicate_stress_grid()
	
	for x in range(1, GRID_SIZE - 1):
		for z in range(1, GRID_SIZE - 1):
			var current_state = grid[x][z]
			var current_stress = stress_grid[x][z]
			
			match current_state:
				CellState.INTACT:
					# Intact cells become stressed if neighbor stress is high enough
					var neighbor_stress_influence = calculate_neighbor_stress(x, z)
					new_stress[x][z] += neighbor_stress_influence
					if new_stress[x][z] > CRACK_THRESHOLD:
						new_grid[x][z] = CellState.STRESSED
				
				CellState.STRESSED:
					# Stressed cells can become cracked based on probability
					var crack_probability = calculate_crack_probability(x, z)
					if randf() < crack_probability:
						new_grid[x][z] = CellState.CRACKED
						new_stress[x][z] = 1.0
				
				CellState.CRACKED:
					# Cracked cells are the source of new propagation
					propagate_stress_to_neighbors(new_stress, new_grid, x, z)
	
	grid = new_grid
	stress_grid = new_stress

func calculate_neighbor_stress(x: int, z: int) -> float:
	var total_stress = 0.0
	# Only propagate from cracked neighbors, not stressed ones
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			if dx == 0 and dz == 0:
				continue
			var nx = x + dx
			var nz = z + dz
			if is_valid_position(nx, nz) and grid[nx][nz] == CellState.CRACKED:
				total_stress += stress_grid[nx][nz] * PROPAGATION_RATE
	return total_stress

func calculate_crack_probability(x: int, z: int) -> float:
	# Probability is based on stress level and number of cracked neighbors
	var base_probability = 0.1
	var cracked_neighbors = 0
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			if dx == 0 and dz == 0:
				continue
			var nx = x + dx
			var nz = z + dz
			if is_valid_position(nx, nz) and grid[nx][nz] == CellState.CRACKED:
				cracked_neighbors += 1
	
	return base_probability + stress_grid[x][z] * 0.5 + (cracked_neighbors * 0.2)

func propagate_stress_to_neighbors(new_stress: Array, new_grid: Array, x: int, z: int):
	# A cracked cell can start a new arm
	if randf() > CRACK_PROPAGATION_CHANCE:
		return
	
	# Find a random neighbor to propagate to
	var possible_directions = []
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			if dx == 0 and dz == 0:
				continue
			var nx = x + dx
			var nz = z + dz
			# Only propagate to INTACT or STRESSED neighbors to create "arms"
			if is_valid_position(nx, nz) and grid[nx][nz] != CellState.CRACKED:
				possible_directions.push_back(Vector2i(nx, nz))
	
	if possible_directions.size() > 0:
		var target_pos = possible_directions[randi() % possible_directions.size()]
		# Apply a high amount of stress to the new point
		new_stress[target_pos.x][target_pos.y] = 0.8
		new_grid[target_pos.x][target_pos.y] = CellState.STRESSED

func is_valid_position(x: int, z: int) -> bool:
	return x >= 0 and x < GRID_SIZE and z >= 0 and z < GRID_SIZE

func duplicate_grid() -> Array:
	var new_grid = []
	new_grid.resize(GRID_SIZE)
	
	for x in range(GRID_SIZE):
		new_grid[x] = grid[x].duplicate()
	
	return new_grid

func duplicate_stress_grid() -> Array:
	var new_stress = []
	new_stress.resize(GRID_SIZE)
	
	for x in range(GRID_SIZE):
		new_stress[x] = stress_grid[x].duplicate()
	
	return new_stress

func update_crack_mesh():
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var vertex_index = 0
	
	# Keep track of visited cracked cells to avoid duplicates
	var visited_cells = {}
	
	# Iterate over all cells to find the start of crack segments
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			if grid[x][z] == CellState.CRACKED and not visited_cells.has(Vector2i(x, z)):
				# Start a new crack segment
				var current_pos = Vector2i(x, z)
				var path = [current_pos]
				visited_cells[current_pos] = true
				
				# Trace the path of the crack
				while true:
					var next_pos = find_next_crack_segment(current_pos, visited_cells)
					if next_pos:
						path.push_back(next_pos)
						visited_cells[next_pos] = true
						current_pos = next_pos
					else:
						break
				
				# Generate mesh for the traced path
				if path.size() > 1:
					for i in range(path.size() - 1):
						var p1 = path[i]
						var p2 = path[i+1]
						create_crack_line_segment(vertices, normals, indices, vertex_index, p1, p2)
						vertex_index += 4
	
	if vertices.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices
		
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		crack_mesh.mesh = array_mesh
		crack_mesh.material_override = crack_material

# Helper function to find the next cracked cell in a continuous path
func find_next_crack_segment(current_pos: Vector2i, visited_cells: Dictionary) -> Vector2i:
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var next_pos = Vector2i(current_pos.x + dx, current_pos.y + dz)
			if is_valid_position(next_pos.x, next_pos.y) and grid[next_pos.x][next_pos.y] == CellState.CRACKED:
				if not visited_cells.has(next_pos):
					return next_pos
	return Vector2i()

# New function to create a single quad between two cracked cells
func create_crack_line_segment(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array, start_index: int, p1: Vector2i, p2: Vector2i):
	var world_pos_1 = Vector3(
		(p1.x - GRID_SIZE/2) * CUBE_SIZE + CUBE_SIZE/2,
		-0.05,
		(p1.y - GRID_SIZE/2) * CUBE_SIZE + CUBE_SIZE/2
	)
	var world_pos_2 = Vector3(
		(p2.x - GRID_SIZE/2) * CUBE_SIZE + CUBE_SIZE/2,
		-0.05,
		(p2.y - GRID_SIZE/2) * CUBE_SIZE + CUBE_SIZE/2
	)
	
	var line_dir = (world_pos_2 - world_pos_1).normalized()
	var perp_dir = Vector3(line_dir.z, 0, -line_dir.x) * CUBE_SIZE * 0.1 # Thin line
	
	# Vertices for the quad segment
	vertices.push_back(world_pos_1 + perp_dir)
	vertices.push_back(world_pos_1 - perp_dir)
	vertices.push_back(world_pos_2 - perp_dir)
	vertices.push_back(world_pos_2 + perp_dir)
	
	# Add normals
	normals.push_back(Vector3.UP)
	normals.push_back(Vector3.UP)
	normals.push_back(Vector3.UP)
	normals.push_back(Vector3.UP)
	
	# Add indices
	indices.push_back(start_index)
	indices.push_back(start_index + 1)
	indices.push_back(start_index + 2)
	indices.push_back(start_index)
	indices.push_back(start_index + 2)
	indices.push_back(start_index + 3)

# Public method to add new stress points (for testing or interaction)
func add_stress_point(world_pos: Vector3):
	var grid_x = int((world_pos.x + GRID_SIZE/2 * CUBE_SIZE) / CUBE_SIZE)
	var grid_z = int((world_pos.z + GRID_SIZE/2 * CUBE_SIZE) / CUBE_SIZE)
	
	if is_valid_position(grid_x, grid_z):
		stress_grid[grid_x][grid_z] = 1.0
		grid[grid_x][grid_z] = CellState.STRESSED

# Debug method to visualize stress levels
func get_stress_at_position(world_pos: Vector3) -> float:
	var grid_x = int((world_pos.x + GRID_SIZE/2 * CUBE_SIZE) / CUBE_SIZE)
	var grid_z = int((world_pos.z + GRID_SIZE/2 * CUBE_SIZE) / CUBE_SIZE)
	
	if is_valid_position(grid_x, grid_z):
		return stress_grid[grid_x][grid_z]
	
	return 0.0
