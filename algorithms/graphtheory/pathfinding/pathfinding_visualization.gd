extends Node3D

# Pathfinding Visualization using Dijkstra's Algorithm
# Shows step-by-step pathfinding with visual feedback

@export_category("Grid Configuration")
@export var grid_width: int = 20
@export var grid_height: int = 20
@export var cell_size: float = 1.0
@export var obstacle_probability: float = 0.3

@export_category("Pathfinding Parameters")
@export var start_pos: Vector2i = Vector2i(2, 2)
@export var goal_pos: Vector2i = Vector2i(17, 17)
@export var algorithm_speed: float = 0.1  # Seconds between steps
@export var show_costs: bool = true
@export var animate_search: bool = true

@export_category("Visualization")
@export var show_grid_lines: bool = true
@export var show_visited_cells: bool = true
@export var show_frontier: bool = true
@export var path_width: float = 0.3

# Grid and pathfinding state
var grid: Array = []
var distances: Array = []
var previous: Array = []
var visited: Array = []
var frontier: Array = []  # Priority queue
var path: Array = []
var algorithm_running: bool = false
var algorithm_timer: float = 0.0

# Visual elements
var cell_meshes: Array = []
var grid_container: Node3D
var ui_labels: Array = []

# Cell types
enum CellType {
	EMPTY,
	OBSTACLE,
	START,
	GOAL,
	VISITED,
	FRONTIER,
	PATH
}

# Colors for different cell types
var cell_colors = {
	CellType.EMPTY: Color(0.9, 0.9, 0.9),
	CellType.OBSTACLE: Color(0.2, 0.2, 0.2),
	CellType.START: Color(0.2, 0.8, 0.2),
	CellType.GOAL: Color(0.8, 0.2, 0.2),
	CellType.VISITED: Color(0.7, 0.7, 0.9),
	CellType.FRONTIER: Color(0.9, 0.7, 0.2),
	CellType.PATH: Color(0.2, 0.6, 0.9)
}

# Grid cell class
class GridCell:
	var x: int
	var y: int
	var type: CellType
	var mesh_instance: MeshInstance3D
	var distance: float = INF
	var visited: bool = false
	var in_frontier: bool = false
	
	func _init(grid_x: int, grid_y: int, cell_type: CellType = CellType.EMPTY):
		x = grid_x
		y = grid_y
		type = cell_type
	
	func get_position() -> Vector2i:
		return Vector2i(x, y)

func _ready():
	setup_environment()
	initialize_grid()
	create_grid_visuals()
	setup_ui()
	start_pathfinding()

func _process(delta):
	if algorithm_running and animate_search:
		algorithm_timer += delta
		if algorithm_timer >= algorithm_speed:
			pathfinding_step()
			algorithm_timer = 0.0
	
	update_ui()

func setup_environment():
	# Lighting
	var light = DirectionalLight3D.new()
	light.light_energy = 1.0
	light.rotation_degrees = Vector3(-45, 45, 0)
	add_child(light)
	
	# Environment
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.1, 0.1, 0.1)
	environment.ambient_light_color = Color(0.4, 0.4, 0.4)
	environment.ambient_light_energy = 0.8
	env.environment = environment
	add_child(env)
	
	# Camera setup
	var camera = Camera3D.new()
	camera.position = Vector3(grid_width * cell_size / 2.0, 15, grid_height * cell_size / 2.0 + 10)
	camera.look_at_from_position(camera.position, Vector3(grid_width * cell_size / 2.0, 0, grid_height * cell_size / 2.0), Vector3.UP)
	add_child(camera)

func initialize_grid():
	grid.clear()
	distances.clear()
	previous.clear()
	visited.clear()
	frontier.clear()
	path.clear()
	
	# Initialize 2D arrays
	for x in range(grid_width):
		grid.append([])
		distances.append([])
		previous.append([])
		visited.append([])
		
		for y in range(grid_height):
			# Determine cell type
			var cell_type = CellType.EMPTY
			
			if Vector2i(x, y) == start_pos:
				cell_type = CellType.START
			elif Vector2i(x, y) == goal_pos:
				cell_type = CellType.GOAL
			elif randf() < obstacle_probability:
				cell_type = CellType.OBSTACLE
			
			var cell = GridCell.new(x, y, cell_type)
			grid[x].append(cell)
			distances[x].append(INF)
			previous[x].append(null)
			visited[x].append(false)

func create_grid_visuals():
	# Container for all grid visuals
	grid_container = Node3D.new()
	grid_container.name = "GridContainer"
	add_child(grid_container)
	
	cell_meshes.clear()
	
	for x in range(grid_width):
		cell_meshes.append([])
		for y in range(grid_height):
			var cell = grid[x][y]
			var mesh_instance = create_cell_mesh(cell)
			cell.mesh_instance = mesh_instance
			grid_container.add_child(mesh_instance)
			cell_meshes[x].append(mesh_instance)

func create_cell_mesh(cell: GridCell) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(cell_size * 0.9, 0.1, cell_size * 0.9)
	mesh_instance.mesh = box
	
	var material = StandardMaterial3D.new()
	material.albedo_color = cell_colors[cell.type]
	if cell.type == CellType.START or cell.type == CellType.GOAL:
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.5
	mesh_instance.material_override = material
	
	mesh_instance.position = Vector3(
		cell.x * cell_size,
		0,
		cell.y * cell_size
	)
	
	return mesh_instance

func start_pathfinding():
	if start_pos.x < 0 or start_pos.x >= grid_width or start_pos.y < 0 or start_pos.y >= grid_height:
		print("Invalid start position")
		return
	
	if goal_pos.x < 0 or goal_pos.x >= grid_width or goal_pos.y < 0 or goal_pos.y >= grid_height:
		print("Invalid goal position")
		return
	
	# Initialize Dijkstra's algorithm
	distances[start_pos.x][start_pos.y] = 0
	frontier.append({"pos": start_pos, "distance": 0})
	algorithm_running = true
	
	print("Starting pathfinding from ", start_pos, " to ", goal_pos)

func pathfinding_step():
	if frontier.is_empty():
		algorithm_running = false
		print("No path found!")
		return
	
	# Find cell with minimum distance in frontier
	var current_index = 0
	var min_distance = frontier[0].distance
	
	for i in range(1, frontier.size()):
		if frontier[i].distance < min_distance:
			min_distance = frontier[i].distance
			current_index = i
	
	var current = frontier[current_index]
	frontier.remove_at(current_index)
	
	var pos = current.pos
	
	# Mark as visited
	if not visited[pos.x][pos.y]:
		visited[pos.x][pos.y] = true
		
		# Update visual
		if grid[pos.x][pos.y].type == CellType.EMPTY:
			grid[pos.x][pos.y].type = CellType.VISITED
			update_cell_visual(pos.x, pos.y)
	
	# Check if we reached the goal
	if pos == goal_pos:
		algorithm_running = false
		reconstruct_path()
		print("Path found!")
		return
	
	# Check neighbors
	var neighbors = get_neighbors(pos)
	for neighbor_pos in neighbors:
		var nx = neighbor_pos.x
		var ny = neighbor_pos.y
		
		if visited[nx][ny] or grid[nx][ny].type == CellType.OBSTACLE:
			continue
		
		var new_distance = distances[pos.x][pos.y] + 1
		
		if new_distance < distances[nx][ny]:
			distances[nx][ny] = new_distance
			previous[nx][ny] = pos
			
			# Add to frontier if not already there
			var in_frontier = false
			for frontier_item in frontier:
				if frontier_item.pos == neighbor_pos:
					frontier_item.distance = new_distance
					in_frontier = true
					break
			
			if not in_frontier:
				frontier.append({"pos": neighbor_pos, "distance": new_distance})
				
				# Update visual
				if grid[nx][ny].type == CellType.EMPTY:
					grid[nx][ny].type = CellType.FRONTIER
					update_cell_visual(nx, ny)

func get_neighbors(pos: Vector2i) -> Array:
	var neighbors = []
	var directions = [
		Vector2i(0, 1),   # Up
		Vector2i(0, -1),  # Down
		Vector2i(1, 0),   # Right
		Vector2i(-1, 0)   # Left
	]
	
	for direction in directions:
		var neighbor = pos + direction
		if neighbor.x >= 0 and neighbor.x < grid_width and neighbor.y >= 0 and neighbor.y < grid_height:
			neighbors.append(neighbor)
	
	return neighbors

func reconstruct_path():
	path.clear()
	var current = goal_pos
	
	while current != start_pos:
		path.append(current)
		current = previous[current.x][current.y]
		if current == null:
			print("Error reconstructing path")
			return
	
	path.append(start_pos)
	path.reverse()
	
	# Update visual path
	for pos in path:
		if grid[pos.x][pos.y].type != CellType.START and grid[pos.x][pos.y].type != CellType.GOAL:
			grid[pos.x][pos.y].type = CellType.PATH
			update_cell_visual(pos.x, pos.y)

func update_cell_visual(x: int, y: int):
	var cell = grid[x][y]
	var material = cell.mesh_instance.material_override
	material.albedo_color = cell_colors[cell.type]
	
	if cell.type == CellType.PATH:
		material.emission_enabled = true
		material.emission = Color(0.1, 0.3, 0.5)
	elif cell.type == CellType.FRONTIER:
		material.emission_enabled = true
		material.emission = Color(0.4, 0.3, 0.1)

func setup_ui():
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	var status_label = Label.new()
	status_label.position = Vector2(20, 20)
	status_label.text = "Initializing pathfinding..."
	canvas.add_child(status_label)
	ui_labels.append(status_label)
	
	var stats_label = Label.new()
	stats_label.position = Vector2(20, 50)
	stats_label.text = "Frontier: 0 | Visited: 0"
	canvas.add_child(stats_label)
	ui_labels.append(stats_label)

func update_ui():
	if ui_labels.size() >= 1:
		if algorithm_running:
			ui_labels[0].text = "Searching for path..."
		else:
			if path.size() > 0:
				ui_labels[0].text = "Path found! Length: " + str(path.size())
			else:
				ui_labels[0].text = "No path found"
	
	if ui_labels.size() >= 2:
		var visited_count = 0
		for x in range(grid_width):
			for y in range(grid_height):
				if visited[x][y]:
					visited_count += 1
		
		ui_labels[1].text = "Frontier: " + str(frontier.size()) + " | Visited: " + str(visited_count) 
