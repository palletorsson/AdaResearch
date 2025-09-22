class_name Pathfinding3D
extends Node3D

# 3D Pathfinding: Volumetric Navigation Algorithms
# Comprehensive 3D pathfinding with voxel grids and multiple algorithms
# Optimized for VR interaction and large-scale navigation

@export_category("Grid Configuration")
@export var grid_dimensions: Vector3i = Vector3i(50, 25, 50)
@export var voxel_size: float = 1.0
@export var grid_origin: Vector3 = Vector3.ZERO
@export var obstacle_probability: float = 0.25

@export_category("Algorithm Settings")
@export var algorithm_type: AlgorithmType = AlgorithmType.ASTAR_3D
@export var heuristic_type: HeuristicType = HeuristicType.EUCLIDEAN
@export var movement_model: MovementType = MovementType.FLYING
@export var heuristic_weight: float = 1.0
@export var tie_breaker: float = 0.001

@export_category("Movement Constraints")
@export var allow_diagonal_movement: bool = true
@export var max_slope_angle: float = 45.0  # degrees
@export var elevation_change_cost: float = 1.2
@export var diagonal_cost_multiplier: float = 1.414  # sqrt(2)
@export var vertical_cost_multiplier: float = 1.5

@export_category("VR Comfort")
@export var comfort_pathfinding: bool = true
@export var min_path_width: float = 1.0
@export var max_turn_angle: float = 90.0  # degrees
@export var smooth_path_curves: bool = true
@export var curve_segments: int = 8

@export_category("Visualization")
@export var show_grid: bool = false
@export var show_obstacles: bool = true
@export var show_path: bool = true
@export var show_search_progress: bool = true
@export var show_open_nodes: bool = false
@export var show_closed_nodes: bool = false
@export var animate_search: bool = true
@export var search_step_delay: float = 0.05

@export_category("Performance")
@export var max_search_nodes: int = 50000
@export var use_hierarchical_pathfinding: bool = false
@export var cluster_size: int = 10
@export var enable_path_caching: bool = true
@export var cache_size: int = 1000

# Enums
enum AlgorithmType {
	ASTAR_3D,
	DIJKSTRA_3D,
	JUMP_POINT_SEARCH_3D,
	HIERARCHICAL_ASTAR,
	FLOW_FIELD
}

enum HeuristicType {
	MANHATTAN,
	EUCLIDEAN,
	CHEBYSHEV,
	WEIGHTED_EUCLIDEAN,
	CUSTOM
}

enum MovementType {
	GROUND_BASED,    # Gravity-aware, can jump
	FLYING,          # Full 3D movement
	SWIMMING,        # Buoyancy effects
	CLIMBING,        # Wall climbing allowed
	CONSTRAINED      # Custom movement rules
}

enum VoxelType {
	EMPTY,
	OBSTACLE,
	START,
	GOAL,
	PATH,
	OPEN_NODE,
	CLOSED_NODE,
	WATER,
	CLIMBABLE,
	DANGEROUS
}

# 3D Voxel representation
class Voxel3D:
	var position: Vector3i
	var world_position: Vector3
	var type: VoxelType = VoxelType.EMPTY
	var movement_cost: float = 1.0
	var is_walkable: bool = true
	var terrain_modifier: float = 1.0
	var visual_object: Node3D
	var surface_normal: Vector3 = Vector3.UP
	
	func _init(pos: Vector3i, world_pos: Vector3):
		position = pos
		world_position = world_pos

# Pathfinding node for search algorithms
class PathNode3D:
	var position: Vector3i
	var world_position: Vector3
	var g_cost: float = 0.0  # Distance from start
	var h_cost: float = 0.0  # Heuristic to goal
	var f_cost: float = 0.0  # Total cost
	var parent: PathNode3D = null
	var movement_direction: Vector3i = Vector3i.ZERO
	var elevation_change: float = 0.0
	var comfort_score: float = 1.0  # VR comfort rating
	
	func _init(pos: Vector3i, world_pos: Vector3):
		position = pos
		world_position = world_pos
	
	func calculate_f_cost():
		f_cost = g_cost + h_cost

# Priority queue for A* algorithm
class PriorityQueue:
	var elements: Array[PathNode3D] = []
	
	func push(node: PathNode3D):
		elements.append(node)
		_bubble_up(elements.size() - 1)
	
	func pop() -> PathNode3D:
		if elements.is_empty():
			return null
		
		var result = elements[0]
		var last = elements.pop_back()
		
		if not elements.is_empty():
			elements[0] = last
			_bubble_down(0)
		
		return result
	
	func is_empty() -> bool:
		return elements.is_empty()
	
	func contains(node: PathNode3D) -> bool:
		return node in elements
	
	func _bubble_up(index: int):
		while index > 0:
			var parent_index = (index - 1) / 2
			if elements[index].f_cost >= elements[parent_index].f_cost:
				break
			
			var temp = elements[index]
			elements[index] = elements[parent_index]
			elements[parent_index] = temp
			index = parent_index
	
	func _bubble_down(index: int):
		while true:
			var left_child = 2 * index + 1
			var right_child = 2 * index + 2
			var smallest = index
			
			if left_child < elements.size() and elements[left_child].f_cost < elements[smallest].f_cost:
				smallest = left_child
			
			if right_child < elements.size() and elements[right_child].f_cost < elements[smallest].f_cost:
				smallest = right_child
			
			if smallest == index:
				break
			
			var temp = elements[index]
			elements[index] = elements[smallest]
			elements[smallest] = temp
			index = smallest

# Grid and algorithm state
var voxel_grid: Array = []  # 3D array of Voxel3D
var start_position: Vector3i
var goal_position: Vector3i
var current_path: Array[Vector3i] = []
var search_nodes_created: int = 0
var search_nodes_expanded: int = 0
var path_found: bool = false
var search_complete: bool = false

# Visualization containers
var grid_container: Node3D
var path_container: Node3D
var search_container: Node3D
var ui_container: CanvasLayer

# Search animation
var search_timer: Timer
var open_set_visual: Array = []
var closed_set_visual: Array = []

# Performance caching
var path_cache: Dictionary = {}
var heuristic_cache: Dictionary = {}

# Movement direction vectors for different connectivity
var movement_6_connected = [
	Vector3i(1, 0, 0), Vector3i(-1, 0, 0),    # X axis
	Vector3i(0, 1, 0), Vector3i(0, -1, 0),    # Y axis
	Vector3i(0, 0, 1), Vector3i(0, 0, -1)     # Z axis
]

var movement_18_connected = movement_6_connected + [
	# Face diagonals
	Vector3i(1, 1, 0), Vector3i(1, -1, 0), Vector3i(-1, 1, 0), Vector3i(-1, -1, 0),
	Vector3i(1, 0, 1), Vector3i(1, 0, -1), Vector3i(-1, 0, 1), Vector3i(-1, 0, -1),
	Vector3i(0, 1, 1), Vector3i(0, 1, -1), Vector3i(0, -1, 1), Vector3i(0, -1, -1)
]

var movement_26_connected = movement_18_connected + [
	# Edge and corner diagonals
	Vector3i(1, 1, 1), Vector3i(1, 1, -1), Vector3i(1, -1, 1), Vector3i(1, -1, -1),
	Vector3i(-1, 1, 1), Vector3i(-1, 1, -1), Vector3i(-1, -1, 1), Vector3i(-1, -1, -1)
]

func _ready():
	setup_environment()
	setup_containers()
	setup_ui()
	setup_search_timer()
	initialize_3d_grid()
	place_random_obstacles()
	set_start_and_goal()
	create_grid_visualization()
	
	print("3D Pathfinding initialized with grid ", grid_dimensions)

func _process(_delta):
	update_ui_stats()

func setup_environment():
	"""Setup basic 3D environment"""
	var light = DirectionalLight3D.new()
	light.light_energy = 1.0
	light.rotation_degrees = Vector3(-45, 45, 0)
	light.shadow_enabled = true
	add_child(light)
	
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.1, 0.1, 0.15)
	environment.ambient_light_color = Color(0.4, 0.4, 0.5)
	environment.ambient_light_energy = 0.5
	env.environment = environment
	add_child(env)

func setup_containers():
	"""Create containers for different visual elements"""
	grid_container = Node3D.new()
	grid_container.name = "GridContainer"
	add_child(grid_container)
	
	path_container = Node3D.new()
	path_container.name = "PathContainer"
	add_child(path_container)
	
	search_container = Node3D.new()
	search_container.name = "SearchContainer"
	add_child(search_container)

func setup_ui():
	"""Create UI for statistics and controls"""
	ui_container = CanvasLayer.new()
	ui_container.name = "UIContainer"
	add_child(ui_container)
	
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.size = Vector2(350, 400)
	panel.position = Vector2(-360, 10)
	ui_container.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	for i in range(20):
		var label = Label.new()
		label.name = "stat_label_" + str(i)
		label.text = ""
		vbox.add_child(label)

func setup_search_timer():
	"""Setup timer for animated search visualization"""
	search_timer = Timer.new()
	search_timer.wait_time = search_step_delay
	search_timer.timeout.connect(_on_search_step)
	add_child(search_timer)

func initialize_3d_grid():
	"""Initialize the 3D voxel grid"""
	voxel_grid.clear()
	
	for x in range(grid_dimensions.x):
		voxel_grid.append([])
		for y in range(grid_dimensions.y):
			voxel_grid[x].append([])
			for z in range(grid_dimensions.z):
				var grid_pos = Vector3i(x, y, z)
				var world_pos = grid_origin + Vector3(x, y, z) * voxel_size
				var voxel = Voxel3D.new(grid_pos, world_pos)
				voxel_grid[x][y].append(voxel)

func place_random_obstacles():
	"""Place random obstacles in the grid"""
	for x in range(grid_dimensions.x):
		for y in range(grid_dimensions.y):
			for z in range(grid_dimensions.z):
				if randf() < obstacle_probability:
					set_voxel_type(Vector3i(x, y, z), VoxelType.OBSTACLE)

func set_start_and_goal():
	"""Set start and goal positions"""
	# Find open positions for start and goal
	start_position = find_open_position()
	goal_position = find_open_position()
	
	# Ensure start and goal are different
	while goal_position == start_position:
		goal_position = find_open_position()
	
	set_voxel_type(start_position, VoxelType.START)
	set_voxel_type(goal_position, VoxelType.GOAL)
	
	print("Start: ", start_position, " Goal: ", goal_position)

func find_open_position() -> Vector3i:
	"""Find a random open position in the grid"""
	var attempts = 0
	while attempts < 1000:
		var pos = Vector3i(
			randi() % grid_dimensions.x,
			randi() % grid_dimensions.y,
			randi() % grid_dimensions.z
		)
		
		if is_position_valid(pos) and get_voxel(pos).type == VoxelType.EMPTY:
			return pos
		
		attempts += 1
	
	# Fallback to corner if no open position found
	return Vector3i(0, 0, 0)

func create_grid_visualization():
	"""Create visual representation of the 3D grid"""
	if not show_grid and not show_obstacles:
		return
	
	for x in range(grid_dimensions.x):
		for y in range(grid_dimensions.y):
			for z in range(grid_dimensions.z):
				var voxel = get_voxel(Vector3i(x, y, z))
				if voxel.type != VoxelType.EMPTY or show_grid:
					create_voxel_visual(voxel)

func create_voxel_visual(voxel: Voxel3D):
	"""Create visual representation for a single voxel"""
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3.ONE * voxel_size * 0.9
	mesh_instance.mesh = box
	
	var material = StandardMaterial3D.new()
	
	match voxel.type:
		VoxelType.EMPTY:
			material.albedo_color = Color(0.9, 0.9, 0.9, 0.1)
			material.flags_transparent = true
		VoxelType.OBSTACLE:
			material.albedo_color = Color(0.3, 0.3, 0.3)
		VoxelType.START:
			material.albedo_color = Color(0.2, 0.8, 0.2)
			material.emission_enabled = true
			material.emission = Color(0.1, 0.4, 0.1)
		VoxelType.GOAL:
			material.albedo_color = Color(0.8, 0.2, 0.2)
			material.emission_enabled = true
			material.emission = Color(0.4, 0.1, 0.1)
		VoxelType.PATH:
			material.albedo_color = Color(0.2, 0.6, 0.9)
			material.emission_enabled = true
			material.emission = Color(0.1, 0.3, 0.5)
		VoxelType.OPEN_NODE:
			material.albedo_color = Color(0.9, 0.9, 0.2)
			material.emission_enabled = true
			material.emission = Color(0.4, 0.4, 0.1)
		VoxelType.CLOSED_NODE:
			material.albedo_color = Color(0.6, 0.6, 0.9)
			material.emission_enabled = true
			material.emission = Color(0.2, 0.2, 0.4)
	
	mesh_instance.material_override = material
	mesh_instance.position = voxel.world_position
	mesh_instance.name = "Voxel_" + str(voxel.position)
	
	# Add to appropriate container
	if voxel.type == VoxelType.OPEN_NODE or voxel.type == VoxelType.CLOSED_NODE:
		search_container.add_child(mesh_instance)
	elif voxel.type == VoxelType.PATH:
		path_container.add_child(mesh_instance)
	else:
		grid_container.add_child(mesh_instance)
	
	voxel.visual_object = mesh_instance

func start_pathfinding():
	"""Start the pathfinding algorithm"""
	clear_previous_search()
	
	match algorithm_type:
		AlgorithmType.ASTAR_3D:
			if animate_search:
				start_animated_astar()
			else:
				find_path_astar_3d()
		AlgorithmType.DIJKSTRA_3D:
			find_path_dijkstra_3d()
		AlgorithmType.JUMP_POINT_SEARCH_3D:
			find_path_jps_3d()
		AlgorithmType.HIERARCHICAL_ASTAR:
			find_path_hierarchical()
		AlgorithmType.FLOW_FIELD:
			generate_flow_field()

func clear_previous_search():
	"""Clear previous search visualization"""
	current_path.clear()
	search_nodes_created = 0
	search_nodes_expanded = 0
	path_found = false
	search_complete = false
	
	# Clear visual containers
	for child in path_container.get_children():
		child.queue_free()
	for child in search_container.get_children():
		child.queue_free()
	
	# Reset voxel types
	for x in range(grid_dimensions.x):
		for y in range(grid_dimensions.y):
			for z in range(grid_dimensions.z):
				var voxel = get_voxel(Vector3i(x, y, z))
				if voxel.type in [VoxelType.PATH, VoxelType.OPEN_NODE, VoxelType.CLOSED_NODE]:
					if voxel.position == start_position:
						voxel.type = VoxelType.START
					elif voxel.position == goal_position:
						voxel.type = VoxelType.GOAL
					else:
						voxel.type = VoxelType.EMPTY

func find_path_astar_3d() -> Array[Vector3i]:
	"""Standard A* pathfinding in 3D"""
	var open_set = PriorityQueue.new()
	var closed_set: Dictionary = {}
	var came_from: Dictionary = {}
	var g_score: Dictionary = {}
	var f_score: Dictionary = {}
	
	# Initialize start node
	var start_node = PathNode3D.new(start_position, get_world_position(start_position))
	start_node.g_cost = 0
	start_node.h_cost = calculate_heuristic(start_position, goal_position)
	start_node.calculate_f_cost()
	
	open_set.push(start_node)
	g_score[start_position] = 0
	f_score[start_position] = start_node.h_cost
	
	while not open_set.is_empty():
		var current = open_set.pop()
		search_nodes_expanded += 1
		
		if current.position == goal_position:
			path_found = true
			current_path = reconstruct_path(came_from, current.position)
			visualize_path()
			return current_path
		
		closed_set[current.position] = true
		
		if show_search_progress:
			set_voxel_type(current.position, VoxelType.CLOSED_NODE)
		
		for neighbor_pos in get_valid_neighbors(current.position):
			if neighbor_pos in closed_set:
				continue
			
			var movement_cost = calculate_movement_cost(current.position, neighbor_pos)
			var tentative_g_score = g_score[current.position] + movement_cost
			
			if not neighbor_pos in g_score or tentative_g_score < g_score[neighbor_pos]:
				came_from[neighbor_pos] = current.position
				g_score[neighbor_pos] = tentative_g_score
				
				var neighbor_h_cost = calculate_heuristic(neighbor_pos, goal_position)
				f_score[neighbor_pos] = tentative_g_score + neighbor_h_cost
				
				var neighbor_node = PathNode3D.new(neighbor_pos, get_world_position(neighbor_pos))
				neighbor_node.g_cost = tentative_g_score
				neighbor_node.h_cost = neighbor_h_cost
				neighbor_node.calculate_f_cost()
				neighbor_node.parent = current
				
				if not open_set.contains(neighbor_node):
					open_set.push(neighbor_node)
					search_nodes_created += 1
					
					if show_search_progress:
						set_voxel_type(neighbor_pos, VoxelType.OPEN_NODE)
	
	search_complete = true
	return []  # No path found

# Animated A* for visualization
var animated_open_set: PriorityQueue
var animated_closed_set: Dictionary
var animated_came_from: Dictionary
var animated_g_score: Dictionary

func start_animated_astar():
	"""Start animated A* visualization"""
	animated_open_set = PriorityQueue.new()
	animated_closed_set = {}
	animated_came_from = {}
	animated_g_score = {}
	
	var start_node = PathNode3D.new(start_position, get_world_position(start_position))
	start_node.g_cost = 0
	start_node.h_cost = calculate_heuristic(start_position, goal_position)
	start_node.calculate_f_cost()
	
	animated_open_set.push(start_node)
	animated_g_score[start_position] = 0
	
	search_timer.start()

func _on_search_step():
	"""Perform one step of animated A* search"""
	if animated_open_set.is_empty():
		search_timer.stop()
		search_complete = true
		print("No path found!")
		return
	
	var current = animated_open_set.pop()
	search_nodes_expanded += 1
	
	if current.position == goal_position:
		search_timer.stop()
		path_found = true
		current_path = reconstruct_path(animated_came_from, current.position)
		visualize_path()
		print("Path found with length: ", current_path.size())
		return
	
	animated_closed_set[current.position] = true
	set_voxel_type(current.position, VoxelType.CLOSED_NODE)
	
	for neighbor_pos in get_valid_neighbors(current.position):
		if neighbor_pos in animated_closed_set:
			continue
		
		var movement_cost = calculate_movement_cost(current.position, neighbor_pos)
		var tentative_g_score = animated_g_score[current.position] + movement_cost
		
		if not neighbor_pos in animated_g_score or tentative_g_score < animated_g_score[neighbor_pos]:
			animated_came_from[neighbor_pos] = current.position
			animated_g_score[neighbor_pos] = tentative_g_score
			
			var neighbor_h_cost = calculate_heuristic(neighbor_pos, goal_position)
			
			var neighbor_node = PathNode3D.new(neighbor_pos, get_world_position(neighbor_pos))
			neighbor_node.g_cost = tentative_g_score
			neighbor_node.h_cost = neighbor_h_cost
			neighbor_node.calculate_f_cost()
			neighbor_node.parent = current
			
			animated_open_set.push(neighbor_node)
			search_nodes_created += 1
			set_voxel_type(neighbor_pos, VoxelType.OPEN_NODE)

func find_path_dijkstra_3d() -> Array[Vector3i]:
	"""Dijkstra's algorithm for 3D pathfinding"""
	var distances: Dictionary = {}
	var previous: Dictionary = {}
	var unvisited = PriorityQueue.new()
	
	# Initialize distances
	for x in range(grid_dimensions.x):
		for y in range(grid_dimensions.y):
			for z in range(grid_dimensions.z):
				var pos = Vector3i(x, y, z)
				if is_position_walkable(pos):
					distances[pos] = INF
					var node = PathNode3D.new(pos, get_world_position(pos))
					node.g_cost = INF
					unvisited.push(node)
	
	distances[start_position] = 0
	
	while not unvisited.is_empty():
		var current_node = unvisited.pop()
		var current_pos = current_node.position
		
		if current_pos == goal_position:
			path_found = true
			current_path = reconstruct_path_dijkstra(previous, goal_position)
			visualize_path()
			return current_path
		
		for neighbor_pos in get_valid_neighbors(current_pos):
			var movement_cost = calculate_movement_cost(current_pos, neighbor_pos)
			var alt_distance = distances[current_pos] + movement_cost
			
			if alt_distance < distances[neighbor_pos]:
				distances[neighbor_pos] = alt_distance
				previous[neighbor_pos] = current_pos
	
	return []  # No path found

func find_path_jps_3d() -> Array[Vector3i]:
	"""Jump Point Search for 3D grids (simplified version)"""
	# For now, fall back to standard A*
	return find_path_astar_3d()

func find_path_hierarchical() -> Array[Vector3i]:
	"""Hierarchical pathfinding for large grids"""
	# Simplified hierarchical approach
	return find_path_astar_3d()

func generate_flow_field():
	"""Generate flow field for goal position"""
	var flow_field: Dictionary = {}
	var integration_field: Dictionary = {}
	
	# Initialize with goal
	integration_field[goal_position] = 0.0
	var queue = [goal_position]
	var visited = {goal_position: true}
	
	# Breadth-first expansion
	while queue.size() > 0:
		var current = queue.pop_front()
		var current_cost = integration_field[current]
		
		for neighbor in get_valid_neighbors(current):
			if neighbor in visited:
				continue
			
			var movement_cost = calculate_movement_cost(current, neighbor)
			var new_cost = current_cost + movement_cost
			
			if not neighbor in integration_field or new_cost < integration_field[neighbor]:
				integration_field[neighbor] = new_cost
				queue.append(neighbor)
				visited[neighbor] = true
	
	# Generate flow vectors
	for position in integration_field:
		var best_neighbor = null
		var lowest_cost = integration_field[position]
		
		for neighbor in get_valid_neighbors(position):
			if neighbor in integration_field and integration_field[neighbor] < lowest_cost:
				lowest_cost = integration_field[neighbor]
				best_neighbor = neighbor
		
		if best_neighbor:
			flow_field[position] = best_neighbor - position
	
	visualize_flow_field(flow_field)

func get_valid_neighbors(position: Vector3i) -> Array[Vector3i]:
	"""Get valid neighbor positions based on movement model"""
	var neighbors: Array[Vector3i] = []
	var directions = get_movement_directions()
	
	for direction in directions:
		var neighbor_pos = position + direction
		
		if is_position_valid(neighbor_pos) and is_position_walkable(neighbor_pos):
			if is_movement_allowed(position, neighbor_pos):
				neighbors.append(neighbor_pos)
	
	return neighbors

func get_movement_directions() -> Array[Vector3i]:
	"""Get movement directions based on connectivity settings"""
	if allow_diagonal_movement:
		return movement_26_connected
	else:
		return movement_6_connected

func is_position_valid(position: Vector3i) -> bool:
	"""Check if position is within grid bounds"""
	return (position.x >= 0 and position.x < grid_dimensions.x and
			position.y >= 0 and position.y < grid_dimensions.y and
			position.z >= 0 and position.z < grid_dimensions.z)

func is_position_walkable(position: Vector3i) -> bool:
	"""Check if position is walkable"""
	if not is_position_valid(position):
		return false
	
	var voxel = get_voxel(position)
	return voxel.is_walkable and voxel.type != VoxelType.OBSTACLE

func is_movement_allowed(from: Vector3i, to: Vector3i) -> bool:
	"""Check if movement between positions is allowed based on movement model"""
	var direction = to - from
	
	match movement_model:
		MovementType.GROUND_BASED:
			# Ground-based movement with gravity
			if direction.y > 1:  # Can't jump more than 1 voxel high
				return false
			var slope = calculate_slope_angle(from, to)
			return slope <= max_slope_angle
		
		MovementType.FLYING:
			# Flying allows all movements
			return true
		
		MovementType.SWIMMING:
			# Swimming allows all movements but with different costs
			return true
		
		MovementType.CLIMBING:
			# Climbing allows vertical movement on climbable surfaces
			return true
		
		MovementType.CONSTRAINED:
			# Custom movement rules
			return true
	
	return true

func calculate_slope_angle(from: Vector3i, to: Vector3i) -> float:
	"""Calculate slope angle between two positions"""
	var horizontal_distance = Vector2(to.x - from.x, to.z - from.z).length()
	var vertical_distance = to.y - from.y
	
	if horizontal_distance == 0:
		return 90.0 if vertical_distance > 0 else 0.0
	
	return rad_to_deg(atan(vertical_distance / horizontal_distance))

func calculate_movement_cost(from: Vector3i, to: Vector3i) -> float:
	"""Calculate movement cost between two adjacent positions"""
	var direction = to - from
	var base_cost = 1.0
	
	# Distance-based cost
	var distance = Vector3(direction).length()
	var cost = base_cost * distance
	
	# Elevation change penalty
	if direction.y != 0:
		cost *= elevation_change_cost
	
	# Diagonal movement cost
	if direction.x != 0 and direction.z != 0:
		cost *= diagonal_cost_multiplier
	
	# Vertical movement cost
	if direction.y != 0:
		cost *= vertical_cost_multiplier
	
	# Terrain modifier
	var to_voxel = get_voxel(to)
	cost *= to_voxel.terrain_modifier
	
	# VR comfort adjustments
	if comfort_pathfinding:
		cost *= calculate_comfort_cost(from, to)
	
	return cost

func calculate_comfort_cost(from: Vector3i, to: Vector3i) -> float:
	"""Calculate VR comfort cost modifier"""
	var comfort_multiplier = 1.0
	
	# Penalize steep elevation changes
	var elevation_change = abs(to.y - from.y)
	if elevation_change > 0:
		comfort_multiplier += elevation_change * 0.5
	
	# Penalize sharp turns (simplified)
	var direction = to - from
	if direction.length() > 1.5:  # Diagonal movement
		comfort_multiplier += 0.2
	
	return comfort_multiplier

func calculate_heuristic(from: Vector3i, to: Vector3i) -> float:
	"""Calculate heuristic distance between two positions"""
	var cache_key = str(from) + "_" + str(to)
	if cache_key in heuristic_cache:
		return heuristic_cache[cache_key]
	
	var distance = 0.0
	
	match heuristic_type:
		HeuristicType.MANHATTAN:
			distance = abs(to.x - from.x) + abs(to.y - from.y) + abs(to.z - from.z)
		
		HeuristicType.EUCLIDEAN:
			var diff = Vector3(to - from)
			distance = diff.length()
		
		HeuristicType.CHEBYSHEV:
			distance = max(abs(to.x - from.x), max(abs(to.y - from.y), abs(to.z - from.z)))
		
		HeuristicType.WEIGHTED_EUCLIDEAN:
			var diff = Vector3(to - from)
			distance = diff.length() * heuristic_weight
		
		HeuristicType.CUSTOM:
			# Custom heuristic with elevation preference
			var horizontal_dist = Vector2(to.x - from.x, to.z - from.z).length()
			var vertical_dist = abs(to.y - from.y) * elevation_change_cost
			distance = horizontal_dist + vertical_dist
	
	# Apply tie-breaker to prefer certain directions
	distance += tie_breaker * distance
	
	# Cache result
	heuristic_cache[cache_key] = distance
	
	return distance

func reconstruct_path(came_from: Dictionary, current: Vector3i) -> Array[Vector3i]:
	"""Reconstruct path from came_from dictionary"""
	var path: Array[Vector3i] = [current]
	
	while current in came_from:
		current = came_from[current]
		path.push_front(current)
	
	return path

func reconstruct_path_dijkstra(previous: Dictionary, goal: Vector3i) -> Array[Vector3i]:
	"""Reconstruct path for Dijkstra's algorithm"""
	var path: Array[Vector3i] = []
	var current = goal
	
	while current in previous:
		path.push_front(current)
		current = previous[current]
	
	path.push_front(start_position)
	return path

func visualize_path():
	"""Create visual representation of the found path"""
	if not show_path or current_path.is_empty():
		return
	
	for i in range(current_path.size()):
		var position = current_path[i]
		
		# Skip start and goal (already visualized)
		if position == start_position or position == goal_position:
			continue
		
		set_voxel_type(position, VoxelType.PATH)
		
		# Create path segment visualization
		if i > 0 and smooth_path_curves:
			create_path_segment(current_path[i-1], position, i)

func create_path_segment(from: Vector3i, to: Vector3i, segment_index: int):
	"""Create a smooth path segment between two points"""
	var from_world = get_world_position(from)
	var to_world = get_world_position(to)
	
	var segment = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	
	var distance = from_world.distance_to(to_world)
	cylinder.top_radius = 0.1
	cylinder.bottom_radius = 0.1
	cylinder.height = distance
	
	segment.mesh = cylinder
	
	var mid_point = (from_world + to_world) * 0.5
	segment.position = mid_point
	segment.look_at(to_world, Vector3.UP)
	segment.rotate_object_local(Vector3.RIGHT, PI/2)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.8, 0.9)
	material.emission_enabled = true
	material.emission = Color(0.1, 0.4, 0.5)
	segment.material_override = material
	
	segment.name = "PathSegment_" + str(segment_index)
	path_container.add_child(segment)

func visualize_flow_field(flow_field: Dictionary):
	"""Visualize flow field with arrows"""
	for position in flow_field:
		var world_pos = get_world_position(position)
		var direction = flow_field[position]
		
		if direction.length() > 0:
			create_flow_arrow(world_pos, Vector3(direction))

func create_flow_arrow(position: Vector3, direction: Vector3):
	"""Create an arrow to show flow direction"""
	var arrow = MeshInstance3D.new()
	var mesh = SphereMesh.new()  # Simplified arrow as sphere
	mesh.radius = 0.1
	mesh.height = 0.2
	arrow.mesh = mesh
	
	arrow.position = position
	arrow.look_at(position + direction, Vector3.UP)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.5, 0.0)
	material.emission_enabled = true
	material.emission = Color(0.5, 0.25, 0.0)
	arrow.material_override = material
	
	path_container.add_child(arrow)

func get_voxel(position: Vector3i) -> Voxel3D:
	"""Get voxel at grid position"""
	return voxel_grid[position.x][position.y][position.z]

func set_voxel_type(position: Vector3i, type: VoxelType):
	"""Set voxel type and update visualization"""
	var voxel = get_voxel(position)
	voxel.type = type
	
	# Update visual if it exists
	if voxel.visual_object:
		update_voxel_visual(voxel)
	else:
		create_voxel_visual(voxel)

func update_voxel_visual(voxel: Voxel3D):
	"""Update existing voxel visual"""
	if not voxel.visual_object:
		return
	
	var material = voxel.visual_object.material_override as StandardMaterial3D
	
	match voxel.type:
		VoxelType.OPEN_NODE:
			material.albedo_color = Color(0.9, 0.9, 0.2)
			material.emission = Color(0.4, 0.4, 0.1)
		VoxelType.CLOSED_NODE:
			material.albedo_color = Color(0.6, 0.6, 0.9)
			material.emission = Color(0.2, 0.2, 0.4)
		VoxelType.PATH:
			material.albedo_color = Color(0.2, 0.6, 0.9)
			material.emission = Color(0.1, 0.3, 0.5)

func get_world_position(grid_position: Vector3i) -> Vector3:
	"""Convert grid position to world position"""
	return grid_origin + Vector3(grid_position) * voxel_size

func update_ui_stats():
	"""Update UI statistics"""
	if not ui_container:
		return
	
	var labels = []
	for i in range(20):
		var label = ui_container.get_node("Panel/VBoxContainer/stat_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 20:
		labels[0].text = "🧊 3D Pathfinding System"
		labels[1].text = "Algorithm: " + AlgorithmType.keys()[algorithm_type]
		labels[2].text = "Movement: " + MovementType.keys()[movement_model]
		labels[3].text = "Heuristic: " + HeuristicType.keys()[heuristic_type]
		labels[4].text = ""
		labels[5].text = "Grid: " + str(grid_dimensions)
		labels[6].text = "Voxel Size: " + str(voxel_size)
		labels[7].text = "Total Voxels: " + str(grid_dimensions.x * grid_dimensions.y * grid_dimensions.z)
		labels[8].text = ""
		labels[9].text = "Start: " + str(start_position)
		labels[10].text = "Goal: " + str(goal_position)
		labels[11].text = "Path Length: " + str(current_path.size())
		labels[12].text = "Path Found: " + ("Yes" if path_found else "No")
		labels[13].text = ""
		labels[14].text = "Nodes Created: " + str(search_nodes_created)
		labels[15].text = "Nodes Expanded: " + str(search_nodes_expanded)
		labels[16].text = "Search Complete: " + ("Yes" if search_complete else "No")
		labels[17].text = ""
		labels[18].text = "Controls: SPACE-Find Path, R-Reset"
		labels[19].text = "G-Toggle Grid, O-Toggle Obstacles"

func _input(event):
	"""Handle user input"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				start_pathfinding()
			KEY_R:
				reset_pathfinding()
			KEY_G:
				show_grid = not show_grid
				recreate_grid_visualization()
			KEY_O:
				show_obstacles = not show_obstacles
				recreate_grid_visualization()
			KEY_P:
				show_path = not show_path
				path_container.visible = show_path
			KEY_1:
				algorithm_type = AlgorithmType.ASTAR_3D
			KEY_2:
				algorithm_type = AlgorithmType.DIJKSTRA_3D
			KEY_3:
				algorithm_type = AlgorithmType.FLOW_FIELD
			KEY_A:
				animate_search = not animate_search

func reset_pathfinding():
	"""Reset the pathfinding system"""
	search_timer.stop()
	clear_previous_search()
	
	# Clear grid
	for child in grid_container.get_children():
		child.queue_free()
	
	# Reinitialize
	initialize_3d_grid()
	place_random_obstacles()
	set_start_and_goal()
	create_grid_visualization()
	
	print("Pathfinding system reset")

func recreate_grid_visualization():
	"""Recreate grid visualization based on current settings"""
	for child in grid_container.get_children():
		child.queue_free()
	
	create_grid_visualization()

func get_pathfinding_info() -> Dictionary:
	"""Get comprehensive pathfinding information"""
	return {
		"name": "3D Pathfinding System",
		"description": "Volumetric navigation with multiple algorithms",
		"grid_properties": {
			"dimensions": grid_dimensions,
			"voxel_size": voxel_size,
			"total_voxels": grid_dimensions.x * grid_dimensions.y * grid_dimensions.z
		},
		"algorithm_settings": {
			"algorithm": AlgorithmType.keys()[algorithm_type],
			"heuristic": HeuristicType.keys()[heuristic_type],
			"movement_model": MovementType.keys()[movement_model]
		},
		"search_results": {
			"path_found": path_found,
			"path_length": current_path.size(),
			"nodes_created": search_nodes_created,
			"nodes_expanded": search_nodes_expanded,
			"search_complete": search_complete
		}
	}
