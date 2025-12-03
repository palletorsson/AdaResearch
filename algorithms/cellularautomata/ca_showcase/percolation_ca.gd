# PercolationCA.gd
# Fluid percolation through porous medium
extends BaseCA

const PERCOLATION_THRESHOLD = 0.593
const FLOW_RATE = 0.1
const POROSITY = 0.6

var flow_grid: Array = []

func initialize_grid():
	# Configure MultiMesh
	var step = 4
	var cube_size = CUBE_SIZE * step
	var mesh = BoxMesh.new()
	mesh.size = Vector3(cube_size, cube_size, cube_size)
	
	var max_instances = (GRID_SIZE / step) * (GRID_SIZE / step) * (GRID_SIZE / step)
	configure_multimesh(mesh, max_instances)
	
	grid = create_3d_grid()
	flow_grid = create_3d_grid()
	
	# Create porous structure
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if randf() < PERCOLATION_THRESHOLD + 0.05:
					grid[x][y][z] = 1  # Occupied site
				else:
					grid[x][y][z] = 0  # Empty site
	
	# Set source points on top face
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid[x][y][GRID_SIZE - 1] == 1:
				grid[x][y][GRID_SIZE - 1] = 2  # Source
				flow_grid[x][y][GRID_SIZE - 1] = 1.0

func update_simulation(delta):
	# Percolate fluid through connected sites
	percolate_fluid()
	update_visualization()

func percolate_fluid():
	var new_flow = duplicate_3d_grid(flow_grid)
	
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] == 1:  # Occupied site
					var neighbor_flow = calculate_neighbor_flow(x, y, z)
					if neighbor_flow > 0:
						new_flow[x][y][z] = min(1.0, neighbor_flow * FLOW_RATE)
						grid[x][y][z] = 3  # Flowing
				elif grid[x][y][z] == 2:  # Source
					new_flow[x][y][z] = 1.0
					propagate_flow_to_neighbors(new_flow, x, y, z, 1.0)
	
	flow_grid = new_flow

func calculate_neighbor_flow(x: int, y: int, z: int) -> float:
	var max_flow = 0.0
	var neighbors = get_3d_neighbors(Vector3i(x, y, z))
	
	for neighbor in neighbors:
		if is_valid_3d_position(neighbor):
			var neighbor_state = grid[neighbor.x][neighbor.y][neighbor.z]
			if neighbor_state == 2 or neighbor_state == 3:  # Source or flowing
				max_flow = max(max_flow, flow_grid[neighbor.x][neighbor.y][neighbor.z])
	
	return max_flow

func propagate_flow_to_neighbors(new_flow: Array, x: int, y: int, z: int, current_flow: float):
	var flow_amount = current_flow * FLOW_RATE
	var neighbors = get_3d_neighbors(Vector3i(x, y, z))
	
	for neighbor in neighbors:
		if is_valid_3d_position(neighbor):
			var neighbor_state = grid[neighbor.x][neighbor.y][neighbor.z]
			if neighbor_state == 1:  # Occupied
				new_flow[neighbor.x][neighbor.y][neighbor.z] = max(
					new_flow[neighbor.x][neighbor.y][neighbor.z],
					flow_amount * randf_range(0.7, 1.0)
				)

func update_visualization():
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
				if state == 1 or state == 2 or state == 3:
					var world_pos = Vector3(
						(x - GRID_SIZE/2) * CUBE_SIZE,
						(y - GRID_SIZE/2) * CUBE_SIZE,
						(z - GRID_SIZE/2) * CUBE_SIZE
					)
					
					mm.set_instance_transform(idx, Transform3D(Basis(), world_pos))
					
					# Color logic
					if state == 1:
						mm.set_instance_color(idx, Color.WHITE.darkened(0.5)) # Occupied (porous rock)
					elif state == 2:
						mm.set_instance_color(idx, Color.CYAN) # Source
					elif state == 3:
						mm.set_instance_color(idx, Color.BLUE) # Flowing
					
					idx += 1

func get_flow_count() -> int:
	var count = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] == 3:
					count += 1
	return count

func reset_simulation():
	grid = create_3d_grid()
	flow_grid = create_3d_grid()
	initialize_grid()
	iteration_count = 0
