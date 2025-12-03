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
	# Configure MultiMesh
	var step = 4
	var cube_size = CUBE_SIZE * VISUALIZATION_STEP
	var mesh = BoxMesh.new()
	mesh.size = Vector3(cube_size, cube_size, cube_size)
	
	var max_instances = (GRID_SIZE / step) * (GRID_SIZE / step) * (GRID_SIZE / step)
	configure_multimesh(mesh, max_instances)
	
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
	if not multi_mesh_instance or not multi_mesh_instance.multimesh:
		return
		
	var mm = multi_mesh_instance.multimesh
	var idx = 0
	var step = 4
	var cube_size = CUBE_SIZE * VISUALIZATION_STEP
	
	# Reset remaining instances
	for i in range(mm.instance_count):
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -1000, 0)))
	
	for x in range(0, GRID_SIZE, step):
		for y in range(0, GRID_SIZE, step):
			for z in range(0, GRID_SIZE, step):
				var state = grid[x][y][z]
				if state == 1 or state == 2:  # Infected or Recovered
					var world_pos = Vector3(
						(x - GRID_SIZE/2) * CUBE_SIZE,
						(y - GRID_SIZE/2) * CUBE_SIZE,
						(z - GRID_SIZE/2) * CUBE_SIZE
					)
					
					mm.set_instance_transform(idx, Transform3D(Basis(), world_pos))
					
					# Color logic
					if state == 1:
						mm.set_instance_color(idx, Color.RED) # Infected
					else:
						mm.set_instance_color(idx, Color.GREEN) # Recovered
						
					idx += 1

 

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
