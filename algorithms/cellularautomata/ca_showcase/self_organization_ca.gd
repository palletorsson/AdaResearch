# SelfOrganizationCA.gd
# Self-organizing patterns and emergence
extends BaseCA

const INTERACTION_STRENGTH = 0.1
const RANDOMNESS = 0.05

func initialize_grid():
	# Configure MultiMesh
	var step = 3
	var cube_size = CUBE_SIZE * step
	var mesh = BoxMesh.new()
	mesh.size = Vector3(cube_size, cube_size, cube_size)
	
	var max_instances = (GRID_SIZE / step) * (GRID_SIZE / step) * (GRID_SIZE / step)
	configure_multimesh(mesh, max_instances)
	
	grid = create_3d_grid()
	
	# Initialize with random values
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				grid[x][y][z] = randi() % 10  # Random state 0-9

func update_simulation(delta):
	# Evolve self-organizing patterns
	evolve_self_organization()
	update_visualization()

func evolve_self_organization():
	var new_grid = duplicate_3d_grid(grid)
	
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var neighbors = get_3d_neighbors(Vector3i(x, y, z))
				var neighbor_sum = 0
				var valid_neighbors = 0
				
				for neighbor in neighbors:
					if is_valid_3d_position(neighbor):
						neighbor_sum += grid[neighbor.x][neighbor.y][neighbor.z]
						valid_neighbors += 1
				
				if valid_neighbors > 0:
					# Self-organization rule: become similar to neighbors
					var avg_neighbor = float(neighbor_sum) / valid_neighbors
					var new_value = grid[x][y][z] * (1.0 - INTERACTION_STRENGTH) + avg_neighbor * INTERACTION_STRENGTH
					
					# Add some randomness
					new_value += randf_range(-RANDOMNESS, RANDOMNESS)
					
					# Clamp to valid range
					new_grid[x][y][z] = int(clamp(new_value, 0, 9))
	
	grid = new_grid

func update_visualization():
	if not multi_mesh_instance or not multi_mesh_instance.multimesh:
		return
		
	var mm = multi_mesh_instance.multimesh
	var idx = 0
	var step = 3
	
	# Reset remaining instances
	for i in range(mm.instance_count):
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -1000, 0)))
	
	for x in range(0, GRID_SIZE, step):
		for y in range(0, GRID_SIZE, step):
			for z in range(0, GRID_SIZE, step):
				var state = grid[x][y][z]
				if state > 0:  # Only show non-zero states
					var world_pos = Vector3(
						(x - GRID_SIZE/2) * CUBE_SIZE,
						(y - GRID_SIZE/2) * CUBE_SIZE,
						(z - GRID_SIZE/2) * CUBE_SIZE
					)
					
					mm.set_instance_transform(idx, Transform3D(Basis(), world_pos))
					
					# Add colors for each vertex
					var color = get_state_color(state)
					mm.set_instance_color(idx, color)
					
					idx += 1

func get_state_color(state: int) -> Color:
	# Color-code different states
	var colors = [
		Color.BLACK,           # 0
		Color.RED,             # 1
		Color.GREEN,           # 2
		Color.BLUE,            # 3
		Color.YELLOW,          # 4
		Color.MAGENTA,         # 5
		Color.CYAN,            # 6
		Color.WHITE,           # 7
		Color(1.0, 0.5, 0.0),  # 8 - Orange
		Color(0.5, 0.0, 1.0)   # 9 - Purple
	]
	
	return colors[state % colors.size()]

func get_pattern_diversity() -> int:
	var unique_states = {}
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var state = grid[x][y][z]
				unique_states[state] = true
	return unique_states.size()

func reset_simulation():
	grid = create_3d_grid()
	initialize_grid()
	iteration_count = 0
