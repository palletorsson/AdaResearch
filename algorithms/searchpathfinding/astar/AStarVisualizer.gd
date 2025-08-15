extends Node3D

@export var grid_size: int = 10
@export var heuristic_type: int = 0  # 0=Manhattan, 1=Euclidean, 2=Chebyshev, 3=Octile
@export var obstacle_density: float = 0.3
@export var allow_diagonal: bool = true

var grid: Array[Array] = []
var grid_cubes: Array[CSGBox3D] = []
var start_pos: Vector2i = Vector2i(1, 1)
var goal_pos: Vector2i = Vector2i(grid_size-2, grid_size-2)
var path: Array[Vector2i] = []
var explored_nodes: Array[Vector2i] = []
var is_step_by_step = false
var step_timer = 0.0
var step_delay = 0.1

# A* algorithm variables
var open_set: Array[Vector2i] = []
var closed_set: Array[Vector2i] = []
var came_from: Dictionary = {}
var g_score: Dictionary = {}
var f_score: Dictionary = {}

func _ready():
	generate_grid()

func _process(delta):
	if is_step_by_step:
		step_timer += delta
		if step_timer >= step_delay:
			step_timer = 0.0
			step_astar()

func generate_grid():
	clear_grid()
	
	# Initialize grid
	grid.clear()
	for x in range(grid_size):
		grid.append([])
		for y in range(grid_size):
			grid[x].append(0)  # 0 = walkable, 1 = obstacle
	
	# Generate obstacles
	randomize()
	for x in range(grid_size):
		for y in range(grid_size):
			if randf() < obstacle_density:
				grid[x][y] = 1
	
	# Ensure start and goal are walkable
	grid[start_pos.x][start_pos.y] = 0
	grid[goal_pos.x][goal_pos.y] = 0
	
	create_visual_grid()

func create_visual_grid():
	# Clear existing cubes
	for cube in grid_cubes:
		cube.queue_free()
	grid_cubes.clear()
	
	# Create grid of cubes
	for x in range(grid_size):
		for y in range(grid_size):
			var cube = CSGBox3D.new()
			cube.size = Vector3(0.8, 0.8, 0.8)
			
			# Position the cube
			var world_x = (x - grid_size/2) * 1.0
			var world_z = (y - grid_size/2) * 1.0
			cube.position = Vector3(world_x, 0, world_z)
			
			# Set material based on grid type
			var material = StandardMaterial3D.new()
			if grid[x][y] == 1:  # Obstacle
				material.albedo_color = Color(0.5, 0.2, 0.2)
			elif Vector2i(x, y) == start_pos:  # Start
				material.albedo_color = Color(0.2, 0.8, 0.2)
			elif Vector2i(x, y) == goal_pos:  # Goal
				material.albedo_color = Color(0.8, 0.2, 0.2)
			else:  # Walkable
				material.albedo_color = Color(0.3, 0.6, 0.9)
			
			material.metallic = 0.1
			material.roughness = 0.8
			cube.material_override = material
			
			add_child(cube)
			grid_cubes.append(cube)

func find_path():
	clear_path()
	reset_astar()
	
	if is_step_by_step:
		# Start step-by-step mode
		pass
	else:
		# Run A* immediately
		run_astar()

func run_astar():
	# Initialize A* variables
	open_set.append(start_pos)
	g_score[start_pos] = 0
	f_score[start_pos] = heuristic(start_pos, goal_pos)
	
	while open_set.size() > 0:
		# Find node with lowest f_score
		var current = open_set[0]
		var current_index = 0
		for i in range(open_set.size()):
			if f_score[open_set[i]] < f_score[current]:
				current = open_set[i]
				current_index = i
		
		# Check if we reached the goal
		if current == goal_pos:
			reconstruct_path()
			return
		
		# Move current from open to closed set
		open_set.remove_at(current_index)
		closed_set.append(current)
		explored_nodes.append(current)
		
		# Get neighbors
		var neighbors = get_neighbors(current)
		for neighbor in neighbors:
			if neighbor in closed_set:
				continue
			
			var tentative_g_score = g_score[current] + 1
			
			if neighbor not in open_set:
				open_set.append(neighbor)
			elif tentative_g_score >= g_score[neighbor]:
				continue
			
			came_from[neighbor] = current
			g_score[neighbor] = tentative_g_score
			f_score[neighbor] = g_score[neighbor] + heuristic(neighbor, goal_pos)
	
	# No path found
	print("No path found!")

func step_astar():
	# Single step of A* algorithm
	if open_set.size() == 0:
		return
	
	# Find node with lowest f_score
	var current = open_set[0]
	var current_index = 0
	for i in range(open_set.size()):
		if f_score[open_set[i]] < f_score[current]:
			current = open_set[i]
			current_index = i
	
	# Check if we reached the goal
	if current == goal_pos:
		reconstruct_path()
		is_step_by_step = false
		return
	
	# Move current from open to closed set
	open_set.remove_at(current_index)
	closed_set.append(current)
	explored_nodes.append(current)
	
	# Get neighbors
	var neighbors = get_neighbors(current)
	for neighbor in neighbors:
		if neighbor in closed_set:
			continue
		
		var tentative_g_score = g_score[current] + 1
		
		if neighbor not in open_set:
			open_set.append(neighbor)
		elif tentative_g_score >= g_score[neighbor]:
			continue
		
		came_from[neighbor] = current
		g_score[neighbor] = tentative_g_score
		f_score[neighbor] = g_score[neighbor] + heuristic(neighbor, goal_pos)
	
	update_visualization()

func get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
	
	if allow_diagonal:
		directions.append_array([Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)])
	
	for dir in directions:
		var neighbor = pos + dir
		if is_valid_position(neighbor) and grid[neighbor.x][neighbor.y] == 0:
			neighbors.append(neighbor)
	
	return neighbors

func is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_size and pos.y >= 0 and pos.y < grid_size

func heuristic(a: Vector2i, b: Vector2i) -> float:
	var dx = abs(b.x - a.x)
	var dy = abs(b.y - a.y)
	
	match heuristic_type:
		0:  # Manhattan
			return dx + dy
		1:  # Euclidean
			return sqrt(dx * dx + dy * dy)
		2:  # Chebyshev
			return max(dx, dy)
		3:  # Octile
			return max(dx, dy) + (sqrt(2) - 1) * min(dx, dy)
		_:
			return dx + dy

func reconstruct_path():
	path.clear()
	var current = goal_pos
	
	while current in came_from:
		path.append(current)
		current = came_from[current]
	
	path.append(start_pos)
	path.reverse()
	
	update_visualization()

func reset_astar():
	open_set.clear()
	closed_set.clear()
	came_from.clear()
	g_score.clear()
	f_score.clear()
	explored_nodes.clear()
	path.clear()

func clear_path():
	path.clear()
	explored_nodes.clear()
	update_visualization()

func toggle_step_by_step():
	is_step_by_step = !is_step_by_step
	if is_step_by_step:
		reset_astar()
		open_set.append(start_pos)
		g_score[start_pos] = 0
		f_score[start_pos] = heuristic(start_pos, goal_pos)

func update_visualization():
	# Update grid cube colors
	for i in range(grid_cubes.size()):
		var x = i / grid_size
		var y = i % grid_size
		
		if x < grid_size and y < grid_size:
			var cube = grid_cubes[i]
			var pos = Vector2i(x, y)
			
			var material = cube.material_override
			if pos in path:
				material.albedo_color = Color(1.0, 1.0, 0.0)  # Yellow for path
			elif pos in explored_nodes:
				material.albedo_color = Color(0.8, 0.8, 0.3)  # Light yellow for explored
			elif pos in open_set:
				material.albedo_color = Color(0.3, 0.8, 0.8)  # Cyan for open set
			elif grid[x][y] == 1:
				material.albedo_color = Color(0.5, 0.2, 0.2)  # Red for obstacles
			elif pos == start_pos:
				material.albedo_color = Color(0.2, 0.8, 0.2)  # Green for start
			elif pos == goal_pos:
				material.albedo_color = Color(0.8, 0.2, 0.2)  # Red for goal
			else:
				material.albedo_color = Color(0.3, 0.6, 0.9)  # Blue for walkable

func update_parameters():
	# This function is called when parameters change
	# Regenerate grid with new parameters
	generate_grid()

