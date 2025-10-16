# DiseaseSpreadCA.gd
# Epidemic spread model (SIR)
extends BaseCA

const INFECTION_RATE = 0.2
const RECOVERY_RATE = 0.1
const INITIAL_INFECTED = 5

var white_material: StandardMaterial3D

func _ready():
	# Create and configure the single white material
	white_material = StandardMaterial3D.new()
	white_material.albedo_color = Color.WHITE

func initialize_grid():
	grid = create_3d_grid()
	
	# Initialize with mostly susceptible population
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				grid[x][y][z] = 0  # Susceptible
	
	# Add initial infected individuals
	for i in range(INITIAL_INFECTED):
		var x = randi() % GRID_SIZE
		var y = randi() % GRID_SIZE
		var z = randi() % GRID_SIZE
		grid[x][y][z] = 1  # Infected

func update_simulation(delta):
	spread_disease()
	update_visualization()

func spread_disease():
	var new_grid = duplicate_3d_grid(grid)
	
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var cell = grid[x][y][z]
				match cell:
					0:  # Susceptible
						var infected_neighbors = count_infected_neighbors(Vector3i(x, y, z))
						if infected_neighbors > 0 and randf() < INFECTION_RATE:
							new_grid[x][y][z] = 1  # Become infected
					
					1:  # Infected
						if randf() < RECOVERY_RATE:
							new_grid[x][y][z] = 2  # Recover
					
					2:  # Recovered
						pass  # Immune
	
	grid = new_grid

func count_infected_neighbors(pos: Vector3i) -> int:
	var count = 0
	var neighbors = get_3d_neighbors(pos)
	for neighbor in neighbors:
		if is_valid_3d_position(neighbor) and grid[neighbor.x][neighbor.y][neighbor.z] == 1:
			count += 1
	return count

func update_visualization():
	if not mesh_instance or not mesh_instance.mesh:
		return
		
	var array_mesh = mesh_instance.mesh as ArrayMesh
	array_mesh.clear_surfaces()
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	var vertex_index = 0
	
	var step = 4
	var cube_size = 4  # Ensure cube size matches step to remove gaps
	
	for x in range(0, GRID_SIZE, step):
		for y in range(0, GRID_SIZE, step):
			for z in range(0, GRID_SIZE, step):
				var state = grid[x][y][z]
				if state == 1 or state == 2:  # Infected or Recovered
					# A single surface for all cubes
					create_cube_at_position(vertices, normals, indices, vertex_index, x, y, z, cube_size)
					vertex_index += 8
	
	if vertices.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices
		
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		array_mesh.surface_set_material(0, white_material)

 

func get_disease_counts() -> Dictionary:
	var susceptible = 0
	var infected = 0
	var recovered = 0
	
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				match grid[x][y][z]:
					0: susceptible += 1
					1: infected += 1
					2: recovered += 1
	
	return {"susceptible": susceptible, "infected": infected, "recovered": recovered}

func reset_simulation():
	grid = create_3d_grid()
	initialize_grid()
	iteration_count = 0
