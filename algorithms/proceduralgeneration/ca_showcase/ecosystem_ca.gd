# EcosystemCA.gd
# Predator-prey ecosystem simulation
extends BaseCA

const PREY_BIRTH_RATE = 0.1
const PREDATOR_DEATH_RATE = 0.05
const HUNT_SUCCESS_RATE = 0.3

# States: 0 = empty, 1 = prey, 2 = predator

func initialize_grid():
	grid = create_3d_grid()
	
	# Initialize with random population
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var rand = randf()
				if rand < 0.1:
					grid[x][y][z] = 1  # Prey
				elif rand < 0.15:
					grid[x][y][z] = 2  # Predator

func update_simulation(delta):
	# Update population dynamics
	update_population_dynamics()
	update_visualization()

func update_population_dynamics():
	var new_grid = duplicate_3d_grid(grid)
	
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var cell = grid[x][y][z]
				match cell:
					1:  # Prey
						# Birth
						if randf() < PREY_BIRTH_RATE:
							var neighbors = get_3d_neighbors(Vector3i(x, y, z))
							for neighbor in neighbors:
								if is_valid_3d_position(neighbor) and grid[neighbor.x][neighbor.y][neighbor.z] == 0:
									new_grid[neighbor.x][neighbor.y][neighbor.z] = 1
									break
					
					2:  # Predator
						# Death
						if randf() < PREDATOR_DEATH_RATE:
							new_grid[x][y][z] = 0
						# Hunting
						elif randf() < HUNT_SUCCESS_RATE:
							var neighbors = get_3d_neighbors(Vector3i(x, y, z))
							for neighbor in neighbors:
								if is_valid_3d_position(neighbor) and grid[neighbor.x][neighbor.y][neighbor.z] == 1:
									new_grid[neighbor.x][neighbor.y][neighbor.z] = 2  # Convert prey to predator
									break
	
	grid = new_grid

func update_visualization():
	var array_mesh = ArrayMesh.new()
	
	# Create separate surfaces for prey and predators
	create_mesh_surface(array_mesh, 1, material_occupied)  # Prey (white)
	create_mesh_surface(array_mesh, 2, material_active)    # Predators (blue)
	
	mesh_instance.mesh = array_mesh

func create_mesh_surface(array_mesh: ArrayMesh, target_state: int, material: StandardMaterial3D):
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	var vertex_index = 0
	
	var step = 4
	
	for x in range(0, GRID_SIZE, step):
		for y in range(0, GRID_SIZE, step):
			for z in range(0, GRID_SIZE, step):
				if grid[x][y][z] == target_state:
					create_cube_at_position(vertices, normals, indices, vertex_index, x, y, z)
					vertex_index += 8
	
	if vertices.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices
		
		var surface_index = array_mesh.get_surface_count()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		array_mesh.surface_set_material(surface_index, material)

func get_population_counts() -> Dictionary:
	var prey_count = 0
	var predator_count = 0
	
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				match grid[x][y][z]:
					1: prey_count += 1
					2: predator_count += 1
	
	return {"prey": prey_count, "predators": predator_count}

func reset_simulation():
	grid = create_3d_grid()
	initialize_grid()
	iteration_count = 0
