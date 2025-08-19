extends Node3D

# 3D Standing 10 PRINT Maze with Ant Pathfinder
# Based on the classic one-liner: 10 PRINT CHR$(205.5+RND(1)); : GOTO 10

# Maze settings
@export var cell_size: float = 1.0
@export var wall_height: float = 2.0
@export var grid_width: int = 10
@export var grid_depth: int = 10
@export var wall_thickness: float = 0.1

# Ant settings
@export var ant_speed: float = 2.0
@export var ant_size: float = 0.3
@export var ant_color: Color = Color.RED
@export var path_color: Color = Color(1.0, 0.5, 0.0)

# Maze representation
var maze: Array = []
var start_pos: Vector2i
var exit_pos: Vector2i

# Navigation grid
var nav_grid: Array = []
var nav_grid_scale: int = 2

# Ant properties
var ant_node: Node3D
var ant_nav_pos: Vector2i
var ant_path: Array = []
var ant_moving: bool = false
var found_exit: bool = false
var path_node: Node3D

# Path visualization
var path_mesh_instance: MeshInstance3D

# Pathfinding
var visited: Dictionary = {}

func _ready():
	randomize()
	generate_maze()
	# build_navigation_grid()
	create_3d_maze()
	# for later
	#create_ant()
	#create_path_visualization()
	#place_ant()

func _process(delta):
	if ant_moving and not found_exit:
		move_ant(delta)
		update_path_visualization()

func generate_maze():
	# Initialize maze grid
	maze.clear()
	for z in range(grid_depth):
		var row = []
		for x in range(grid_width):
			# 50/50 chance of \ or /
			row.append(randi() % 2)
		maze.append(row)
	
	# Set entrance and exit
	start_pos = Vector2i(0, randi() % grid_depth)
	exit_pos = Vector2i(grid_width - 1, randi() % grid_depth)

func build_navigation_grid():
	# Create a finer grid for navigation where lines are walls
	nav_grid.clear()
	
	# Initialize with empty spaces
	for z in range(grid_depth * nav_grid_scale):
		var row = []
		for x in range(grid_width * nav_grid_scale):
			row.append(0)  # 0 = empty space
		nav_grid.append(row)
	
	# Add walls based on diagonal lines
	for z in range(grid_depth):
		for x in range(grid_width):
			var cell_type = maze[z][x]
			
			if cell_type == 0:  # / diagonal
				# Add wall for / line
				for i in range(nav_grid_scale):
					var nx = x * nav_grid_scale + i
					var nz = z * nav_grid_scale + (nav_grid_scale - 1 - i)
					if nx < grid_width * nav_grid_scale and nz < grid_depth * nav_grid_scale:
						nav_grid[nz][nx] = 1  # 1 = wall
			else:  # \ diagonal
				# Add wall for \ line
				for i in range(nav_grid_scale):
					var nx = x * nav_grid_scale + i
					var nz = z * nav_grid_scale + i
					if nx < grid_width * nav_grid_scale and nz < grid_depth * nav_grid_scale:
						nav_grid[nz][nx] = 1  # 1 = wall

func create_3d_maze():
	# Create the floor
	var floor_mesh = PlaneMesh.new()
	floor_mesh.size = Vector2(grid_width * cell_size, grid_depth * cell_size)
	
	var floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.2, 0.2, 0.2)
	
	var floor_instance = MeshInstance3D.new()
	floor_instance.mesh = floor_mesh
	floor_instance.material_override = floor_material
	floor_instance.position = Vector3(grid_width * cell_size / 3, -1, grid_depth * cell_size / 2)
	add_child(floor_instance)
	
	# Create maze walls
	for z in range(grid_depth):
		for x in range(grid_width):
			var wall_position = Vector3(x * cell_size, 3, z * cell_size)
			
			if maze[z][x] == 0:  # / diagonal
				create_diagonal_wall(wall_position, true)
			else:  # \ diagonal
				create_diagonal_wall(wall_position, false)
	
	# Create entrance and exit markers
	create_marker(Vector3(0, 0.05, start_pos.y * cell_size + cell_size/2), Color.GREEN)
	create_marker(Vector3(grid_width * cell_size, 0.05, exit_pos.y * cell_size + cell_size/2), Color.BLUE)

func create_diagonal_wall(position, is_forward_slash):
	var wall_node = Node3D.new()
	wall_node.position = position
	add_child(wall_node)
	
	var wall_mesh = BoxMesh.new()
	wall_mesh.size = Vector3(cell_size * sqrt(2), wall_height, wall_thickness)
	
	var wall_material = StandardMaterial3D.new()
	wall_material.albedo_color = Color.WHITE
	
	var wall_instance = MeshInstance3D.new()
	wall_instance.mesh = wall_mesh
	wall_instance.material_override = wall_material
	
	# Position adjustments
	wall_instance.position = Vector3(cell_size/2, wall_height/2, cell_size/2)
	
	# Rotate based on diagonal type
	if is_forward_slash:  # /
		wall_instance.rotate_y(PI/4)
	else:  # \
		wall_instance.rotate_y(-PI/4)
	
	wall_node.add_child(wall_instance)

func create_marker(position, color):
	var marker_mesh = CylinderMesh.new()
	marker_mesh.top_radius = cell_size * 0.3
	marker_mesh.bottom_radius = cell_size * 0.3
	marker_mesh.height = 0.1
	
	var marker_material = StandardMaterial3D.new()
	marker_material.albedo_color = color
	marker_material.emission_enabled = true
	marker_material.emission = color
	marker_material.emission_energy_multiplier = 0.5
	
	var marker_instance = MeshInstance3D.new()
	marker_instance.mesh = marker_mesh
	marker_instance.material_override = marker_material
	marker_instance.position = position
	
	add_child(marker_instance)



func create_ant():
	ant_node = Node3D.new()
	ant_node.name = "Ant"
	
	var ant_mesh = SphereMesh.new()
	ant_mesh.radius = ant_size
	ant_mesh.height = ant_size * 2
	
	var ant_material = StandardMaterial3D.new()
	ant_material.albedo_color = ant_color
	ant_material.emission_enabled = true
	ant_material.emission = ant_color
	ant_material.emission_energy_multiplier = 0.5
	
	var ant_mesh_instance = MeshInstance3D.new()
	ant_mesh_instance.mesh = ant_mesh
	ant_mesh_instance.material_override = ant_material
	
	ant_node.add_child(ant_mesh_instance)
	add_child(ant_node)

func create_path_visualization():
	path_node = Node3D.new()
	path_node.name = "Path"
	add_child(path_node)
	
	# We'll create the actual path mesh in update_path_visualization()

func place_ant():
	# Place ant at start (left side)
	var start_z = start_pos.y * nav_grid_scale + nav_grid_scale / 2
	ant_nav_pos = Vector2i(0, start_z)
	ant_path = [ant_nav_pos]
	
	# Set 3D position
	var ant_3d_x = ant_nav_pos.x * cell_size / nav_grid_scale
	var ant_3d_z = ant_nav_pos.y * cell_size / nav_grid_scale
	ant_node.position = Vector3(ant_3d_x, ant_size, ant_3d_z)
	
	ant_moving = true
	visited = {ant_nav_pos: true}

func move_ant(delta):
	if is_at_exit():
		found_exit = true
		return
	
	# Get available moves
	var moves = get_possible_moves()
	
	if moves.size() == 0:
		# If stuck, backtrack
		if ant_path.size() > 1:
			ant_path.pop_back()
			if ant_path.size() > 0:
				ant_nav_pos = ant_path[ant_path.size() - 1]
				update_ant_3d_position()
		return
	
	# Choose move with preference toward exit
	var next_pos = choose_best_move(moves)
	ant_nav_pos = next_pos
	ant_path.append(ant_nav_pos)
	visited[ant_nav_pos] = true
	update_ant_3d_position()

func update_ant_3d_position():
	# Update the 3D position of the ant based on its navigation grid position
	var ant_3d_x = ant_nav_pos.x * cell_size / nav_grid_scale
	var ant_3d_z = ant_nav_pos.y * cell_size / nav_grid_scale
	ant_node.position = Vector3(ant_3d_x, ant_size, ant_3d_z)

func is_at_exit():
	# Check if ant has reached right edge of maze
	return ant_nav_pos.x >= (grid_width * nav_grid_scale - 1)

func get_possible_moves():
	var moves = []
	var directions = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
	
	for dir in directions:
		var new_pos = ant_nav_pos + dir
		
		# Check bounds
		if new_pos.x < 0 or new_pos.x >= grid_width * nav_grid_scale or \
		   new_pos.y < 0 or new_pos.y >= grid_depth * nav_grid_scale:
			continue
		
		# Check if we've been here before
		if visited.has(new_pos):
			continue
		
		# Check if this is a wall
		if new_pos.y < nav_grid.size() and new_pos.x < nav_grid[new_pos.y].size():
			if nav_grid[new_pos.y][new_pos.x] == 1:
				continue
		
		moves.append(new_pos)
	
	return moves

func choose_best_move(moves):
	# Use a simple heuristic: prefer moves that get us closer to the exit
	var best_score = -1
	var best_move = null
	
	# Target is the exit on the right side
	var target_x = grid_width * nav_grid_scale - 1
	
	for move in moves:
		# Score based on distance to exit
		var dx = target_x - move.x
		
		# We want to minimize dx (distance to right edge)
		var distance = dx * dx
		
		# Add some randomness to avoid straight paths
		var score = 1000.0 / (distance + 1) + randf() * 2.0
		
		if best_move == null or score > best_score:
			best_score = score
			best_move = move
	
	return best_move

func update_path_visualization():
	# Remove previous path
	if path_mesh_instance != null:
		path_mesh_instance.queue_free()
	
	if ant_path.size() <= 1:
		return
	
	# Create a new path using ImmediateMesh
	var path_immediate_mesh = ImmediateMesh.new()
	path_mesh_instance = MeshInstance3D.new()
	path_mesh_instance.mesh = path_immediate_mesh
	
	var path_material = StandardMaterial3D.new()
	path_material.albedo_color = path_color
	path_material.emission_enabled = true
	path_material.emission = path_color
	path_material.emission_energy_multiplier = 1.0
	path_mesh_instance.material_override = path_material
	
	# Draw the path
	path_immediate_mesh.clear_surfaces()
	path_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, path_material)
	
	for point in ant_path:
		var x = point.x * cell_size / nav_grid_scale
		var z = point.y * cell_size / nav_grid_scale
		path_immediate_mesh.surface_add_vertex(Vector3(x, ant_size, z))
	
	path_immediate_mesh.surface_end()
	path_node.add_child(path_mesh_instance)
