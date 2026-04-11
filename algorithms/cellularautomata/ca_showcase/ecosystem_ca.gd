# EcosystemCA.gd
# Predator-prey ecosystem simulation
extends BaseCA

const PREY_BIRTH_RATE = 0.1
const PREDATOR_DEATH_RATE = 0.05
const HUNT_SUCCESS_RATE = 0.3

# States: 0 = empty, 1 = prey, 2 = predator

func initialize_grid() -> void:
	# Configure MultiMesh
	var step = 4
	var cube_size = CUBE_SIZE * step
	var mesh = BoxMesh.new()
	mesh.size = Vector3(cube_size, cube_size, cube_size)
	
	var max_instances = (GRID_SIZE / step) * (GRID_SIZE / step) * (GRID_SIZE / step)
	configure_multimesh(mesh, max_instances)
	
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

func update_simulation(_delta) -> void:
	# Update population dynamics
	update_population_dynamics()
	update_visualization()

func update_population_dynamics() -> void:
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

func update_visualization() -> void:
	if not multi_mesh_instance or not multi_mesh_instance.multimesh:
		return
		
	var mm = multi_mesh_instance.multimesh
	var idx = 0
	var step = 4
	
	# Reset remaining instances
	for i in range(mm.instance_count):
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -1000, 0)))
	
	for x in range(0, GRID_SIZE, step):
		for y in range(0, GRID_SIZE, step):
			for z in range(0, GRID_SIZE, step):
				var state = grid[x][y][z]
				if state == 1 or state == 2:
					var world_pos = Vector3(
						(x - GRID_SIZE/2) * CUBE_SIZE,
						(y - GRID_SIZE/2) * CUBE_SIZE,
						(z - GRID_SIZE/2) * CUBE_SIZE
					)
					
					mm.set_instance_transform(idx, Transform3D(Basis(), world_pos))
					
					# Color logic
					if state == 1:
						mm.set_instance_color(idx, Color.WHITE) # Prey
					else:
						mm.set_instance_color(idx, Color.BLUE) # Predator
					
					idx += 1

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

func reset_simulation() -> void:
	grid = create_3d_grid()
	initialize_grid()
	iteration_count = 0

func apply_grid_config(config: Dictionary) -> void:
	pass
