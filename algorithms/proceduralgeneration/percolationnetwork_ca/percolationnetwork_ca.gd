# PercolationNetwork3D.gd
# Attach this script to a Node3D in your scene
extends Node3D

const GRID_SIZE = 18
const CUBE_SIZE = 0.5
const PERCOLATION_THRESHOLD = 0.4  # Lower threshold to create more pathways
const FLOW_RATE = 0.15
const MAX_ITERATIONS = 500

var grid: Array = []
var flow_grid: Array = []
var cube_nodes: Array = []  # Store individual cube nodes for collision
var material_occupied: StandardMaterial3D
var material_flowing: StandardMaterial3D
var material_blocked: StandardMaterial3D

var iteration_count = 0
var percolation_complete = false

# Cellular automata states for percolation
enum CellState {
	EMPTY = 0,        # Empty space (blocked)
	OCCUPIED = 1,     # Occupied site (can conduct)
	FLOWING = 2,      # Currently has flow
	CONNECTED = 3,    # Connected to percolating cluster
	SOURCE = 4        # Source points (top face)
}

func _ready():
	setup_percolation_system()
	initialize_lattice()
	create_cube_collision_boxes()
	start_percolation()

func setup_percolation_system():
	# Initialize 3D arrays
	grid.resize(GRID_SIZE)
	flow_grid.resize(GRID_SIZE)
	
	for x in range(GRID_SIZE):
		grid[x] = []
		flow_grid[x] = []
		grid[x].resize(GRID_SIZE)
		flow_grid[x].resize(GRID_SIZE)
		
		for y in range(GRID_SIZE):
			grid[x][y] = []
			flow_grid[x][y] = []
			grid[x][y].resize(GRID_SIZE)
			flow_grid[x][y].resize(GRID_SIZE)
			
			for z in range(GRID_SIZE):
				grid[x][y][z] = CellState.EMPTY
				flow_grid[x][y][z] = 0.0

func initialize_lattice():
	# Create random occupied sites based on percolation threshold
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if randf() < PERCOLATION_THRESHOLD:  # Use threshold directly for pathways
					grid[x][y][z] = CellState.OCCUPIED
	
	# Set source points on top face (z = GRID_SIZE - 1)
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid[x][y][GRID_SIZE - 1] == CellState.OCCUPIED:
				grid[x][y][GRID_SIZE - 1] = CellState.SOURCE
				flow_grid[x][y][GRID_SIZE - 1] = 1.0

func create_cube_collision_boxes():
	# Initialize cube nodes array
	cube_nodes.resize(GRID_SIZE)
	for x in range(GRID_SIZE):
		cube_nodes[x] = []
		cube_nodes[x].resize(GRID_SIZE)
		for y in range(GRID_SIZE):
			cube_nodes[x][y] = []
			cube_nodes[x][y].resize(GRID_SIZE)
	
	# Create materials for different states - white cubes with collision, pink very transparent no collision
	material_occupied = StandardMaterial3D.new()
	material_occupied.albedo_color = Color.WHITE
	material_occupied.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	
	material_flowing = StandardMaterial3D.new()
	material_flowing.albedo_color = Color(1.0, 0.75, 0.8)  # Pink color
	material_flowing.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_flowing.albedo_color.a = 0.2  # Very transparent (20% opacity) - NO COLLISION
	
	material_blocked = StandardMaterial3D.new()
	material_blocked.albedo_color = Color(1.0, 0.75, 0.8)  # Pink color
	material_blocked.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_blocked.albedo_color.a = 0.2  # Very transparent (20% opacity) - NO COLLISION
	
	# Create individual collision boxes for each occupied cell
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] != CellState.EMPTY:
					create_single_cube_collision(x, y, z, grid[x][y][z])

func start_percolation():
	print("Starting percolation simulation...")
	print("Grid size: ", GRID_SIZE, "³")
	print("Occupied sites: ", count_occupied_sites())

func _process(_delta):
	if not percolation_complete and iteration_count < MAX_ITERATIONS:
		update_percolation_automata()
		update_cube_visualization()
		iteration_count += 1
		
		if iteration_count % 10 == 0:
			check_percolation_status()

func update_percolation_automata():
	var new_grid = duplicate_grid()
	var new_flow = duplicate_flow_grid()
	
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var current_state = grid[x][y][z]
				var current_flow = flow_grid[x][y][z]
				
				match current_state:
					CellState.OCCUPIED:
						# Check if flow reaches this occupied site
						var neighbor_flow = calculate_neighbor_flow(x, y, z)
						if neighbor_flow > 0:
							new_grid[x][y][z] = CellState.FLOWING
							new_flow[x][y][z] = min(1.0, neighbor_flow * FLOW_RATE)
					
					CellState.FLOWING:
						# Flowing sites maintain flow and spread to neighbors
						new_flow[x][y][z] = max(0.1, current_flow * 0.9)
						propagate_flow_to_neighbors(new_flow, x, y, z, current_flow)
						
						# Check if this site should become permanently connected
						if current_flow > 0.8:
							new_grid[x][y][z] = CellState.CONNECTED
					
					CellState.CONNECTED:
						# Connected sites maintain permanent flow
						new_flow[x][y][z] = 1.0
						propagate_flow_to_neighbors(new_flow, x, y, z, 1.0)
					
					CellState.SOURCE:
						# Source sites always have maximum flow
						new_flow[x][y][z] = 1.0
						propagate_flow_to_neighbors(new_flow, x, y, z, 1.0)
	
	grid = new_grid
	flow_grid = new_flow

func calculate_neighbor_flow(x: int, y: int, z: int) -> float:
	var max_flow = 0.0
	
	# Check 6-connected neighbors (face neighbors only)
	var neighbors = [
		Vector3i(x+1, y, z), Vector3i(x-1, y, z),
		Vector3i(x, y+1, z), Vector3i(x, y-1, z),
		Vector3i(x, y, z+1), Vector3i(x, y, z-1)
	]
	
	for neighbor in neighbors:
		if is_valid_position(neighbor.x, neighbor.y, neighbor.z):
			var neighbor_state = grid[neighbor.x][neighbor.y][neighbor.z]
			if neighbor_state == CellState.FLOWING or neighbor_state == CellState.CONNECTED or neighbor_state == CellState.SOURCE:
				max_flow = max(max_flow, flow_grid[neighbor.x][neighbor.y][neighbor.z])
	
	return max_flow

func propagate_flow_to_neighbors(new_flow: Array, x: int, y: int, z: int, current_flow: float):
	var flow_amount = current_flow * FLOW_RATE
	
	# 6-connected neighborhood
	var neighbors = [
		Vector3i(x+1, y, z), Vector3i(x-1, y, z),
		Vector3i(x, y+1, z), Vector3i(x, y-1, z),
		Vector3i(x, y, z+1), Vector3i(x, y, z-1)
	]
	
	for neighbor in neighbors:
		if is_valid_position(neighbor.x, neighbor.y, neighbor.z):
			var neighbor_state = grid[neighbor.x][neighbor.y][neighbor.z]
			if neighbor_state == CellState.OCCUPIED:
				new_flow[neighbor.x][neighbor.y][neighbor.z] = max(
					new_flow[neighbor.x][neighbor.y][neighbor.z],
					flow_amount * randf_range(0.7, 1.0)
				)

func is_valid_position(x: int, y: int, z: int) -> bool:
	return x >= 0 and x < GRID_SIZE and y >= 0 and y < GRID_SIZE and z >= 0 and z < GRID_SIZE

func duplicate_grid() -> Array:
	var new_grid = []
	new_grid.resize(GRID_SIZE)
	
	for x in range(GRID_SIZE):
		new_grid[x] = []
		new_grid[x].resize(GRID_SIZE)
		for y in range(GRID_SIZE):
			new_grid[x][y] = grid[x][y].duplicate()
	
	return new_grid

func duplicate_flow_grid() -> Array:
	var new_flow = []
	new_flow.resize(GRID_SIZE)
	
	for x in range(GRID_SIZE):
		new_flow[x] = []
		new_flow[x].resize(GRID_SIZE)
		for y in range(GRID_SIZE):
			new_flow[x][y] = flow_grid[x][y].duplicate()
	
	return new_flow

func create_single_cube_collision(x: int, y: int, z: int, state: CellState):
	# Create parent node
	var cube_node = Node3D.new()
	cube_node.name = "Cube_" + str(x) + "_" + str(y) + "_" + str(z)
	
	# Set position (no gutter - cubes touch)
	var world_pos = Vector3(
		(x - GRID_SIZE/2) * CUBE_SIZE,
		(y - GRID_SIZE/2) * CUBE_SIZE,
		(z - GRID_SIZE/2) * CUBE_SIZE
	)
	cube_node.position = world_pos
	
	# Only add collision for white cubes (occupied state)
	# Pink cubes (FLOWING, CONNECTED, SOURCE) have NO collision
	if state == CellState.OCCUPIED:
		var static_body = StaticBody3D.new()
		static_body.name = "CollisionBody"
		
		# Create CollisionShape3D
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)
		collision_shape.shape = box_shape
		static_body.add_child(collision_shape)
		
		cube_node.add_child(static_body)
	
	# Create MeshInstance3D for visualization (all cubes)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)
	mesh_instance.mesh = box_mesh
	cube_node.add_child(mesh_instance)
	
	# Set material based on state
	var material = get_material_for_state(state)
	mesh_instance.material_override = material
	
	# Store reference
	cube_nodes[x][y][z] = cube_node
	add_child(cube_node)

func get_material_for_state(state: CellState) -> StandardMaterial3D:
	match state:
		CellState.OCCUPIED:
			return material_occupied
		CellState.FLOWING, CellState.CONNECTED, CellState.SOURCE:
			return material_flowing
		_:
			return material_blocked

func update_cube_visualization():
	# Update existing cubes and create new ones as needed
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var current_state = grid[x][y][z]
				var cube_node = cube_nodes[x][y][z]
				
				if current_state != CellState.EMPTY:
					if cube_node:
						# Update existing cube
						var mesh_instance = cube_node.get_node("MeshInstance3D")
						var material = get_material_for_state(current_state)
						mesh_instance.material_override = material
						
						# Update collision based on state
						update_cube_collision(cube_node, current_state)
					else:
						# Create new cube for newly occupied cell
						create_single_cube_collision(x, y, z, current_state)
				else:
					# Remove cube if cell becomes empty
					if cube_node:
						cube_node.queue_free()
						cube_nodes[x][y][z] = null

func update_cube_collision(cube_node: Node3D, state: CellState):
	# Remove existing collision body if it exists
	var existing_collision = cube_node.get_node_or_null("CollisionBody")
	if existing_collision:
		existing_collision.queue_free()
		# Remove from parent immediately to ensure no collision interference
		cube_node.remove_child(existing_collision)
	
	# Add collision only for white cubes (occupied state)
	# Pink cubes (FLOWING, CONNECTED, SOURCE) have NO collision
	if state == CellState.OCCUPIED:
		var static_body = StaticBody3D.new()
		static_body.name = "CollisionBody"
		
		# Create CollisionShape3D
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)
		collision_shape.shape = box_shape
		static_body.add_child(collision_shape)
		
		cube_node.add_child(static_body)

# Helper function to get cube world position
func get_cube_world_position(x: int, y: int, z: int) -> Vector3:
	return Vector3(
		(x - GRID_SIZE/2.0) * CUBE_SIZE,
		(y - GRID_SIZE/2.0) * CUBE_SIZE,
		(z - GRID_SIZE/2.0) * CUBE_SIZE
	)

func check_percolation_status():
	var bottom_connected = false
	
	# Check if flow has reached the bottom face (z = 0)
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid[x][y][0] == CellState.FLOWING or grid[x][y][0] == CellState.CONNECTED:
				bottom_connected = true
				break
		if bottom_connected:
			break
	
	if bottom_connected and not percolation_complete:
		percolation_complete = true
		print("PERCOLATION ACHIEVED! Flow connected from top to bottom.")
		print("Iterations required: ", iteration_count)
		print("Connected sites: ", count_connected_sites())
	elif iteration_count >= MAX_ITERATIONS and not percolation_complete:
		print("Simulation complete. No percolation detected.")
		print("This may be below the percolation threshold.")

func count_occupied_sites() -> int:
	var count = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] != CellState.EMPTY:
					count += 1
	return count

func count_connected_sites() -> int:
	var count = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] == CellState.CONNECTED or grid[x][y][z] == CellState.FLOWING:
					count += 1
	return count

# Debug method to get percolation statistics
func get_percolation_stats() -> Dictionary:
	return {
		"iteration": iteration_count,
		"occupied_sites": count_occupied_sites(),
		"connected_sites": count_connected_sites(),
		"percolation_achieved": percolation_complete,
		"occupation_probability": float(count_occupied_sites()) / (GRID_SIZE * GRID_SIZE * GRID_SIZE),
		"total_cubes": count_total_cubes(),
		"colliding_cubes": count_colliding_cubes(),
		"pink_cubes": count_total_cubes() - count_colliding_cubes()
	}

func count_total_cubes() -> int:
	var count = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if cube_nodes[x][y][z] != null:
					count += 1
	return count

func count_colliding_cubes() -> int:
	var count = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] == CellState.OCCUPIED:
					count += 1
	return count

# Method to get collision information for a specific position
func get_cube_at_position(world_pos: Vector3) -> Node3D:
	var grid_pos = world_to_grid_position(world_pos)
	if is_valid_position(grid_pos.x, grid_pos.y, grid_pos.z):
		return cube_nodes[grid_pos.x][grid_pos.y][grid_pos.z]
	return null

# Method to get collision body for a specific position (only for white cubes)
func get_collision_body_at_position(world_pos: Vector3) -> StaticBody3D:
	var cube_node = get_cube_at_position(world_pos)
	if cube_node:
		return cube_node.get_node_or_null("CollisionBody")
	return null

func world_to_grid_position(world_pos: Vector3) -> Vector3i:
	var x = int(round(world_pos.x / CUBE_SIZE + GRID_SIZE/2))
	var y = int(round(world_pos.y / CUBE_SIZE + GRID_SIZE/2))
	var z = int(round(world_pos.z / CUBE_SIZE + GRID_SIZE/2))
	return Vector3i(x, y, z)

# Debug function to check collision status at a position
func debug_collision_at_position(world_pos: Vector3) -> Dictionary:
	var grid_pos = world_to_grid_position(world_pos)
	var cube_node = get_cube_at_position(world_pos)
	var collision_body = get_collision_body_at_position(world_pos)
	
	return {
		"grid_position": grid_pos,
		"cube_exists": cube_node != null,
		"has_collision": collision_body != null,
		"state": grid[grid_pos.x][grid_pos.y][grid_pos.z] if is_valid_position(grid_pos.x, grid_pos.y, grid_pos.z) else -1
	}

# Force remove all collision from pink cubes (call this if needed)
func force_remove_pink_cube_collisions():
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var state = grid[x][y][z]
				if state == CellState.FLOWING or state == CellState.CONNECTED or state == CellState.SOURCE:
					var cube_node = cube_nodes[x][y][z]
					if cube_node:
						var collision_body = cube_node.get_node_or_null("CollisionBody")
						if collision_body:
							cube_node.remove_child(collision_body)
							collision_body.queue_free()
							print("Removed collision from pink cube at ", x, ",", y, ",", z)
