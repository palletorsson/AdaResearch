extends Node3D

# Maze Generation using Recursive Backtracking
# Creates animated 3D maze with step-by-step generation

@export_category("Maze Configuration")
@export var maze_width: int = 9
@export var maze_height: int = 9
@export var cell_size: float = 1.0
@export var wall_height: float = 1.0
@export var generation_speed: float = 0.2

@export_category("Visual Settings")
@export var wall_color: Color = Color(0.4, 0.4, 0.6)
@export var path_color: Color = Color(0.8, 0.8, 0.9)
@export var current_color: Color = Color(0.9, 0.3, 0.3)
@export var visited_color: Color = Color(0.3, 0.9, 0.3)
@export var show_generation: bool = true

# Maze data
var maze: Array = []
var visited: Array = []
var generation_stack: Array = []
var current_cell: Vector2i
var generating: bool = false
var generation_timer: float = 0.0

# Visual elements
var cell_meshes: Array = []
var wall_meshes: Array = []
var wall_colliders: Array = []  # Store collision bodies for walls
var floor_colliders: Array = []  # Store collision bodies for floor/paths

# Directions for maze generation
var directions = [
	Vector2i(0, -2),  # North
	Vector2i(2, 0),   # East
	Vector2i(0, 2),   # South
	Vector2i(-2, 0)   # West
]

func _ready():
	setup_environment()
	initialize_maze()
	create_maze_visuals()
	
	if show_generation:
		start_generation()

func _process(delta):
	if generating:
		generation_timer += delta
		if generation_timer >= generation_speed:
			generation_step()
			generation_timer = 0.0

func setup_environment():
	# Lighting
	var light = DirectionalLight3D.new()
	light.light_energy = 1.0
	light.rotation_degrees = Vector3(-45, 30, 0)
	add_child(light)
	
	# Environment
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.1, 0.1, 0.2)
	environment.ambient_light_energy = 0.5
	env.environment = environment
	add_child(env)
	
	# Camera
	var camera = Camera3D.new()
	camera.position = Vector3(maze_width, maze_height * 1.5, maze_height)
	camera.look_at(Vector3(maze_width / 2, 0, maze_height / 2))
	add_child(camera)

func initialize_maze():
	# Initialize maze grid - true = wall, false = path
	maze.clear()
	visited.clear()
	
	for y in range(maze_height):
		var row = []
		var visited_row = []
		for x in range(maze_width):
			# Start with all walls
			row.append(true)
			visited_row.append(false)
		maze.append(row)
		visited.append(visited_row)
	
	# Create initial paths at odd coordinates
	for y in range(1, maze_height, 2):
		for x in range(1, maze_width, 2):
			maze[y][x] = false  # Create path cell

func create_maze_visuals():
	cell_meshes.clear()
	wall_meshes.clear()
	wall_colliders.clear()
	floor_colliders.clear()
	
	for y in range(maze_height):
		var row = []
		var wall_collider_row = []
		var floor_collider_row = []
		for x in range(maze_width):
			var mesh_instance = create_cell_visual(x, y)
			row.append(mesh_instance)
			add_child(mesh_instance)
			
			# Create collision for walls
			if maze[y][x]:  # If it's a wall
				var wall_collider = create_wall_collider(x, y)
				wall_collider_row.append(wall_collider)
				add_child(wall_collider)
				floor_collider_row.append(null)
			else:  # If it's a path/floor
				var floor_collider = create_floor_collider(x, y)
				wall_collider_row.append(null)
				floor_collider_row.append(floor_collider)
				add_child(floor_collider)
		cell_meshes.append(row)
		wall_colliders.append(wall_collider_row)
		floor_colliders.append(floor_collider_row)

func create_cell_visual(x: int, y: int) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	
	if maze[y][x]:  # Wall
		box.size = Vector3(cell_size, wall_height, cell_size)
		mesh_instance.position = Vector3(x * cell_size, wall_height / 2, y * cell_size)
	else:  # Path
		box.size = Vector3(cell_size, 0.1, cell_size)
		mesh_instance.position = Vector3(x * cell_size, 0.05, y * cell_size)
	
	mesh_instance.mesh = box
	
	var material = StandardMaterial3D.new()
	material.albedo_color = wall_color if maze[y][x] else path_color
	mesh_instance.material_override = material
	
	return mesh_instance

func create_wall_collider(x: int, y: int) -> StaticBody3D:
	# Create StaticBody3D for collision
	var static_body = StaticBody3D.new()
	static_body.name = "WallCollider_" + str(x) + "_" + str(y)
	
	# Create CollisionShape3D
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(cell_size, wall_height, cell_size)
	collision_shape.shape = box_shape
	static_body.add_child(collision_shape)
	
	# Position the collider
	static_body.position = Vector3(x * cell_size, wall_height / 2, y * cell_size)
	
	return static_body

func create_floor_collider(x: int, y: int) -> StaticBody3D:
	# Create StaticBody3D for floor collision
	var static_body = StaticBody3D.new()
	static_body.name = "FloorCollider_" + str(x) + "_" + str(y)
	
	# Create CollisionShape3D
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(cell_size, 0.1, cell_size)  # Thin floor collision
	collision_shape.shape = box_shape
	static_body.add_child(collision_shape)
	
	# Position the collider at ground level
	static_body.position = Vector3(x * cell_size, 0.05, y * cell_size)
	
	return static_body

func start_generation():
	# Start from top-left path cell
	current_cell = Vector2i(1, 1)
	visited[1][1] = true
	generation_stack.clear()
	generating = true
	
	update_cell_visual(current_cell, current_color)
	print("Starting maze generation...")

func generation_step():
	var neighbors = get_unvisited_neighbors(current_cell)
	
	if neighbors.size() > 0:
		# Choose random neighbor
		var next_cell = neighbors[randi() % neighbors.size()]
		
		# Mark as visited
		visited[next_cell.y][next_cell.x] = true
		
		# Remove wall between current and next cell
		var wall_x = current_cell.x + (next_cell.x - current_cell.x) / 2
		var wall_y = current_cell.y + (next_cell.y - current_cell.y) / 2
		maze[wall_y][wall_x] = false
		
		# Update visuals
		update_cell_visual(current_cell, visited_color)
		update_wall_visual(wall_x, wall_y)
		
		# Push current cell to stack
		generation_stack.push_back(current_cell)
		
		# Move to next cell
		current_cell = next_cell
		update_cell_visual(current_cell, current_color)
		
	elif generation_stack.size() > 0:
		# Backtrack
		update_cell_visual(current_cell, visited_color)
		current_cell = generation_stack.pop_back()
		update_cell_visual(current_cell, current_color)
		
	else:
		# Generation complete
		generating = false
		update_cell_visual(current_cell, visited_color)
		print("Maze generation complete!")
		
		# Add entrance and exit
		create_entrance_exit()

func get_unvisited_neighbors(cell: Vector2i) -> Array:
	var neighbors = []
	
	for direction in directions:
		var next_x = cell.x + direction.x
		var next_y = cell.y + direction.y
		
		# Check bounds
		if next_x >= 1 and next_x < maze_width - 1 and next_y >= 1 and next_y < maze_height - 1:
			# Check if unvisited
			if not visited[next_y][next_x]:
				neighbors.append(Vector2i(next_x, next_y))
	
	return neighbors

func update_cell_visual(cell: Vector2i, color: Color):
	if cell.y < cell_meshes.size() and cell.x < cell_meshes[cell.y].size():
		var mesh_instance = cell_meshes[cell.y][cell.x]
		if mesh_instance and mesh_instance.material_override:
			mesh_instance.material_override.albedo_color = color

func update_wall_visual(x: int, y: int):
	# Convert wall to path
	maze[y][x] = false
	
	var mesh_instance = cell_meshes[y][x]
	
	# Change mesh to path
	var box = BoxMesh.new()
	box.size = Vector3(cell_size, 0.1, cell_size)
	mesh_instance.mesh = box
	mesh_instance.position = Vector3(x * cell_size, 0.05, y * cell_size)
	
	# Change material
	var material = StandardMaterial3D.new()
	material.albedo_color = path_color
	mesh_instance.material_override = material
	
	# Remove wall collision body
	if wall_colliders[y][x]:
		wall_colliders[y][x].queue_free()
		wall_colliders[y][x] = null
	
	# Create floor collision body
	var floor_collider = create_floor_collider(x, y)
	floor_colliders[y][x] = floor_collider
	add_child(floor_collider)

func create_entrance_exit():
	# Create entrance at top
	maze[0][1] = false
	update_entrance_exit_visual(1, 0)
	
	# Create exit at bottom
	maze[maze_height - 1][maze_width - 2] = false
	update_entrance_exit_visual(maze_width - 2, maze_height - 1)

func update_entrance_exit_visual(x: int, y: int):
	var mesh_instance = cell_meshes[y][x]
	
	# Change to path
	var box = BoxMesh.new()
	box.size = Vector3(cell_size, 0.1, cell_size)
	mesh_instance.mesh = box
	mesh_instance.position = Vector3(x * cell_size, 0.05, y * cell_size)
	
	# Special color for entrance/exit
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.9, 0.3)  # Yellow
	material.emission_enabled = true
	material.emission = Color(0.9, 0.9, 0.3) * 0.3
	mesh_instance.material_override = material
	
	# Remove wall collision body for entrance/exit
	if wall_colliders[y][x]:
		wall_colliders[y][x].queue_free()
		wall_colliders[y][x] = null
	
	# Create floor collision body for entrance/exit
	var floor_collider = create_floor_collider(x, y)
	floor_colliders[y][x] = floor_collider
	add_child(floor_collider)

func get_maze_string() -> String:
	var result = ""
	for y in range(maze_height):
		for x in range(maze_width):
			result += "█" if maze[y][x] else " "
		result += "\n"
	return result

# Utility functions for collision management
func get_wall_collider_at_position(world_pos: Vector3) -> StaticBody3D:
	var x = int(round(world_pos.x / cell_size))
	var y = int(round(world_pos.z / cell_size))
	
	if x >= 0 and x < maze_width and y >= 0 and y < maze_height:
		return wall_colliders[y][x]
	return null

func get_floor_collider_at_position(world_pos: Vector3) -> StaticBody3D:
	var x = int(round(world_pos.x / cell_size))
	var y = int(round(world_pos.z / cell_size))
	
	if x >= 0 and x < maze_width and y >= 0 and y < maze_height:
		return floor_colliders[y][x]
	return null

func is_wall_at_position(world_pos: Vector3) -> bool:
	var x = int(round(world_pos.x / cell_size))
	var y = int(round(world_pos.z / cell_size))
	
	if x >= 0 and x < maze_width and y >= 0 and y < maze_height:
		return maze[y][x]
	return false

func is_floor_at_position(world_pos: Vector3) -> bool:
	var x = int(round(world_pos.x / cell_size))
	var y = int(round(world_pos.z / cell_size))
	
	if x >= 0 and x < maze_width and y >= 0 and y < maze_height:
		return not maze[y][x]  # Floor if not a wall
	return false

func get_wall_collision_count() -> int:
	var count = 0
	for y in range(maze_height):
		for x in range(maze_width):
			if wall_colliders[y][x] != null:
				count += 1
	return count

func get_floor_collision_count() -> int:
	var count = 0
	for y in range(maze_height):
		for x in range(maze_width):
			if floor_colliders[y][x] != null:
				count += 1
	return count

# Debug function to show collision status
func debug_collision_info() -> Dictionary:
	return {
		"total_walls": get_wall_collision_count(),
		"total_floors": get_floor_collision_count(),
		"maze_size": Vector2i(maze_width, maze_height),
		"cell_size": cell_size,
		"wall_height": wall_height
	} 
