# maze_generator_vr.gd
# VR-optimized Maze Generation - Human-scale walkable maze
extends Node3D

# Maze Configuration - VR optimized defaults
@export_category("Maze Configuration")
@export var maze_width: int = 15  # Odd number for proper maze generation
@export var maze_height: int = 15
@export var cell_size: float = 2.0  # 2 meter wide corridors
@export var wall_height: float = 2.8  # Above head height for immersion
@export var wall_thickness: float = 0.3  # Thin walls for more space
@export var generation_speed: float = 0.05  # Fast generation

@export_category("Visual Settings")
@export var wall_color: Color = Color(0.25, 0.25, 0.35)
@export var floor_color: Color = Color(0.15, 0.15, 0.2)
@export var current_color: Color = Color(0.9, 0.3, 0.3)
@export var visited_color: Color = Color(0.2, 0.5, 0.3)
@export var entrance_color: Color = Color(0.3, 0.8, 0.3)
@export var exit_color: Color = Color(0.8, 0.3, 0.3)
@export var show_generation: bool = true

@export_category("Lighting")
@export var add_ambient_light: bool = true
@export var light_intensity: float = 0.4

# Maze data
var maze: Array = []
var visited: Array = []
var generation_stack: Array = []
var current_cell: Vector2i
var generating: bool = false
var generation_timer: float = 0.0
var generation_complete: bool = false

# Visual elements
var cell_meshes: Array = []
var wall_colliders: Array = []
var floor_mesh: MeshInstance3D
var ceiling_mesh: MeshInstance3D

# Directions for maze generation (step by 2 for wall carving)
var directions = [
	Vector2i(0, -2),  # North
	Vector2i(2, 0),   # East
	Vector2i(0, 2),   # South
	Vector2i(-2, 0)   # West
]

# Materials (reused for performance)
var wall_material: StandardMaterial3D
var floor_material: StandardMaterial3D
var path_material: StandardMaterial3D

func _ready():
	_create_materials()
	_initialize_maze()
	_create_floor_and_ceiling()
	_create_maze_visuals()

	if add_ambient_light:
		_setup_lighting()

	if show_generation:
		start_generation()
	else:
		_generate_instant()

func _process(delta):
	if generating:
		generation_timer += delta
		if generation_timer >= generation_speed:
			_generation_step()
			generation_timer = 0.0

func _create_materials():
	# Wall material
	wall_material = StandardMaterial3D.new()
	wall_material.albedo_color = wall_color
	wall_material.roughness = 0.9

	# Floor material
	floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = floor_color
	floor_material.roughness = 0.95

	# Path material (for generation visualization)
	path_material = StandardMaterial3D.new()
	path_material.albedo_color = visited_color
	path_material.roughness = 0.9

func _initialize_maze():
	maze.clear()
	visited.clear()

	for y in range(maze_height):
		var row = []
		var visited_row = []
		for x in range(maze_width):
			row.append(true)  # Start with all walls
			visited_row.append(false)
		maze.append(row)
		visited.append(visited_row)

	# Create path cells at odd coordinates
	for y in range(1, maze_height, 2):
		for x in range(1, maze_width, 2):
			maze[y][x] = false

func _create_floor_and_ceiling():
	var total_width = maze_width * cell_size
	var total_depth = maze_height * cell_size

	# Create floor
	floor_mesh = MeshInstance3D.new()
	floor_mesh.name = "Floor"
	var floor_box = BoxMesh.new()
	floor_box.size = Vector3(total_width, 0.2, total_depth)
	floor_mesh.mesh = floor_box
	floor_mesh.position = Vector3(total_width / 2 - cell_size / 2, -0.1, total_depth / 2 - cell_size / 2)
	floor_mesh.material_override = floor_material
	add_child(floor_mesh)

	# Floor collision
	var floor_body = StaticBody3D.new()
	floor_body.name = "FloorCollision"
	var floor_shape = CollisionShape3D.new()
	var floor_box_shape = BoxShape3D.new()
	floor_box_shape.size = Vector3(total_width + 4, 0.2, total_depth + 4)
	floor_shape.shape = floor_box_shape
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(total_width / 2 - cell_size / 2, -0.1, total_depth / 2 - cell_size / 2)
	add_child(floor_body)

func _setup_lighting():
	# Add subtle ambient lighting throughout the maze
	var light = DirectionalLight3D.new()
	light.name = "MazeLight"
	light.light_color = Color(0.9, 0.9, 1.0)
	light.light_energy = light_intensity
	light.rotation_degrees = Vector3(-45, 45, 0)
	light.shadow_enabled = false  # Better VR performance
	add_child(light)

func _create_maze_visuals():
	# Clear existing
	for child in get_children():
		if child.name.begins_with("Wall_"):
			child.queue_free()

	cell_meshes.clear()
	wall_colliders.clear()

	for y in range(maze_height):
		var row = []
		var collider_row = []
		for x in range(maze_width):
			if maze[y][x]:  # Wall
				var wall = _create_wall(x, y)
				row.append(wall)
				add_child(wall)

				var collider = _create_wall_collider(x, y)
				collider_row.append(collider)
				add_child(collider)
			else:
				row.append(null)
				collider_row.append(null)
		cell_meshes.append(row)
		wall_colliders.append(collider_row)

func _create_wall(x: int, y: int) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Wall_" + str(x) + "_" + str(y)

	var box = BoxMesh.new()
	box.size = Vector3(cell_size - wall_thickness, wall_height, cell_size - wall_thickness)
	mesh_instance.mesh = box
	mesh_instance.position = Vector3(x * cell_size, wall_height / 2, y * cell_size)
	mesh_instance.material_override = wall_material

	return mesh_instance

func _create_wall_collider(x: int, y: int) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.name = "WallCollider_" + str(x) + "_" + str(y)

	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(cell_size, wall_height, cell_size)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(x * cell_size, wall_height / 2, y * cell_size)

	return body

func start_generation():
	current_cell = Vector2i(1, 1)
	visited[1][1] = true
	generation_stack.clear()
	generating = true
	generation_complete = false

	_highlight_cell(current_cell, current_color)

func _generation_step():
	var neighbors = _get_unvisited_neighbors(current_cell)

	if neighbors.size() > 0:
		var next_cell = neighbors[randi() % neighbors.size()]
		visited[next_cell.y][next_cell.x] = true

		# Remove wall between cells
		var wall_x = current_cell.x + (next_cell.x - current_cell.x) / 2
		var wall_y = current_cell.y + (next_cell.y - current_cell.y) / 2
		_remove_wall(wall_x, wall_y)

		_highlight_cell(current_cell, visited_color)
		generation_stack.push_back(current_cell)
		current_cell = next_cell
		_highlight_cell(current_cell, current_color)

	elif generation_stack.size() > 0:
		_highlight_cell(current_cell, visited_color)
		current_cell = generation_stack.pop_back()
		_highlight_cell(current_cell, current_color)

	else:
		generating = false
		generation_complete = true
		_highlight_cell(current_cell, visited_color)
		_create_entrance_exit()
		_finalize_visuals()

func _get_unvisited_neighbors(cell: Vector2i) -> Array:
	var neighbors = []
	for direction in directions:
		var next = cell + direction
		if next.x >= 1 and next.x < maze_width - 1 and next.y >= 1 and next.y < maze_height - 1:
			if not visited[next.y][next.x]:
				neighbors.append(next)
	return neighbors

func _remove_wall(x: int, y: int):
	maze[y][x] = false

	# Remove visual
	if cell_meshes[y][x]:
		cell_meshes[y][x].queue_free()
		cell_meshes[y][x] = null

	# Remove collider
	if wall_colliders[y][x]:
		wall_colliders[y][x].queue_free()
		wall_colliders[y][x] = null

func _highlight_cell(cell: Vector2i, color: Color):
	# During generation, we highlight path cells by creating temporary markers
	pass  # Skip for VR performance

func _create_entrance_exit():
	# Entrance at top
	maze[0][1] = false
	_remove_wall(1, 0)
	_add_marker(1, 0, entrance_color, "Entrance")

	# Exit at bottom
	maze[maze_height - 1][maze_width - 2] = false
	_remove_wall(maze_width - 2, maze_height - 1)
	_add_marker(maze_width - 2, maze_height - 1, exit_color, "Exit")

func _add_marker(x: int, y: int, color: Color, marker_name: String):
	# Add a glowing marker at entrance/exit
	var marker = MeshInstance3D.new()
	marker.name = marker_name + "Marker"

	var cylinder = CylinderMesh.new()
	cylinder.top_radius = cell_size * 0.3
	cylinder.bottom_radius = cell_size * 0.3
	cylinder.height = 0.1
	marker.mesh = cylinder

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	marker.material_override = mat

	marker.position = Vector3(x * cell_size, 0.05, y * cell_size)
	add_child(marker)

func _finalize_visuals():
	# Remove all remaining wall highlights, use final colors
	for y in range(maze_height):
		for x in range(maze_width):
			if cell_meshes[y][x]:
				cell_meshes[y][x].material_override = wall_material

func _generate_instant():
	# Generate maze without animation
	current_cell = Vector2i(1, 1)
	visited[1][1] = true
	generation_stack.clear()

	while true:
		var neighbors = _get_unvisited_neighbors(current_cell)

		if neighbors.size() > 0:
			var next_cell = neighbors[randi() % neighbors.size()]
			visited[next_cell.y][next_cell.x] = true

			var wall_x = current_cell.x + (next_cell.x - current_cell.x) / 2
			var wall_y = current_cell.y + (next_cell.y - current_cell.y) / 2
			_remove_wall(wall_x, wall_y)

			generation_stack.push_back(current_cell)
			current_cell = next_cell

		elif generation_stack.size() > 0:
			current_cell = generation_stack.pop_back()
		else:
			break

	generation_complete = true
	_create_entrance_exit()
	_finalize_visuals()

func regenerate():
	# Clear and regenerate
	for child in get_children():
		if child.name.begins_with("Wall_") or child.name.begins_with("WallCollider_"):
			child.queue_free()
		if child.name.ends_with("Marker"):
			child.queue_free()

	await get_tree().process_frame

	_initialize_maze()
	_create_maze_visuals()

	if show_generation:
		start_generation()
	else:
		_generate_instant()

func get_entrance_position() -> Vector3:
	return Vector3(1 * cell_size, 0, -cell_size)

func get_exit_position() -> Vector3:
	return Vector3((maze_width - 2) * cell_size, 0, maze_height * cell_size)

func get_maze_center() -> Vector3:
	return Vector3(
		(maze_width * cell_size) / 2 - cell_size / 2,
		wall_height / 2,
		(maze_height * cell_size) / 2 - cell_size / 2
	)

func get_total_size() -> Vector3:
	return Vector3(maze_width * cell_size, wall_height, maze_height * cell_size)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				regenerate()
			KEY_G:
				if not generating:
					show_generation = true
					regenerate()
			KEY_I:
				if not generating:
					show_generation = false
					regenerate()
