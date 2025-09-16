extends Node3D

# Simple WFC implementation for dungeon generation
@export var width: int = 10
@export var height: int = 6
@export var depth: int = 10
@export var cell_size: float = 4.0

# Tile types
enum Tile {
	EMPTY,      # 0
	FLOOR,      # 1
	WALL,       # 2
	DOOR,       # 3
	PILLAR      # 4
}

# WFC Rules: [North, South, East, West, Up, Down] - what can connect to each direction
var tile_rules = {
	Tile.EMPTY: [
		[Tile.EMPTY, Tile.WALL],                    # North
		[Tile.EMPTY, Tile.WALL],                    # South
		[Tile.EMPTY, Tile.WALL],                    # East
		[Tile.EMPTY, Tile.WALL],                    # West
		[Tile.EMPTY, Tile.FLOOR, Tile.PILLAR],      # Up
		[Tile.EMPTY, Tile.FLOOR, Tile.PILLAR]       # Down
	],
	Tile.FLOOR: [
		[Tile.FLOOR, Tile.WALL, Tile.DOOR, Tile.PILLAR],  # North
		[Tile.FLOOR, Tile.WALL, Tile.DOOR, Tile.PILLAR],  # South
		[Tile.FLOOR, Tile.WALL, Tile.DOOR, Tile.PILLAR],  # East
		[Tile.FLOOR, Tile.WALL, Tile.DOOR, Tile.PILLAR],  # West
		[Tile.EMPTY, Tile.FLOOR, Tile.PILLAR],            # Up
		[Tile.EMPTY, Tile.FLOOR, Tile.PILLAR]             # Down
	],
	Tile.WALL: [
		[Tile.WALL, Tile.DOOR],                     # North
		[Tile.WALL, Tile.DOOR],                     # South
		[Tile.WALL, Tile.DOOR],                     # East
		[Tile.WALL, Tile.DOOR],                     # West
		[Tile.WALL, Tile.EMPTY],                    # Up
		[Tile.WALL, Tile.FLOOR]                     # Down
	],
	Tile.DOOR: [
		[Tile.WALL, Tile.FLOOR],                    # North
		[Tile.WALL, Tile.FLOOR],                    # South
		[Tile.WALL, Tile.FLOOR],                    # East
		[Tile.WALL, Tile.FLOOR],                    # West
		[Tile.EMPTY],                               # Up
		[Tile.FLOOR]                                # Down
	],
	Tile.PILLAR: [
		[Tile.FLOOR, Tile.PILLAR],                  # North
		[Tile.FLOOR, Tile.PILLAR],                  # South
		[Tile.FLOOR, Tile.PILLAR],                  # East
		[Tile.FLOOR, Tile.PILLAR],                  # West
		[Tile.PILLAR, Tile.EMPTY],                  # Up
		[Tile.PILLAR, Tile.FLOOR]                   # Down
	]
}

# WFC grid
var grid = []
var possible_states = []

func _ready():
	generate_dungeon()

func generate_dungeon():
	initialize_grid()
	run_wfc()
	create_meshes()

func initialize_grid():
	grid = []
	possible_states = []
	
	# Initialize 3D arrays
	for x in width:
		grid.append([])
		possible_states.append([])
		for y in height:
			grid[x].append([])
			possible_states[x].append([])
			for z in depth:
				grid[x][y].append(-1)  # -1 means uncollapsed
				# Start with all tile types possible
				possible_states[x][y].append([Tile.EMPTY, Tile.FLOOR, Tile.WALL, Tile.DOOR, Tile.PILLAR])
	
	# Set boundary constraints
	apply_boundary_constraints()

func apply_boundary_constraints():
	# Force walls or empty on boundaries for structure
	for x in width:
		for y in height:
			for z in depth:
				# Ground floor should have floors
				if y == 0:
					possible_states[x][y][z] = [Tile.FLOOR, Tile.WALL, Tile.PILLAR]
				
				# Top level should be mostly empty
				elif y == height - 1:
					possible_states[x][y][z] = [Tile.EMPTY, Tile.PILLAR]
				
				# Outer walls
				elif x == 0 or x == width - 1 or z == 0 or z == depth - 1:
					if y <= 2:  # Lower levels
						possible_states[x][y][z] = [Tile.WALL, Tile.DOOR]
					else:
						possible_states[x][y][z] = [Tile.EMPTY, Tile.WALL]

func run_wfc():
	var iterations = 0
	var max_iterations = width * height * depth * 2
	
	while not is_fully_collapsed() and iterations < max_iterations:
		var pos = find_lowest_entropy_cell()
		if pos == null:
			break
		
		collapse_cell(pos)
		propagate_constraints(pos)
		iterations += 1
	
	print("WFC completed in ", iterations, " iterations")

func find_lowest_entropy_cell():
	var lowest_entropy = INF
	var candidates = []
	
	for x in width:
		for y in height:
			for z in depth:
				if grid[x][y][z] == -1:  # Uncollapsed
					var entropy = possible_states[x][y][z].size()
					if entropy < lowest_entropy and entropy > 0:
						lowest_entropy = entropy
						candidates = [[x, y, z]]
					elif entropy == lowest_entropy:
						candidates.append([x, y, z])
	
	if candidates.is_empty():
		return null
	
	return candidates[randi() % candidates.size()]

func collapse_cell(pos):
	var x = pos[0]
	var y = pos[1] 
	var z = pos[2]
	
	var possibilities = possible_states[x][y][z]
	if possibilities.is_empty():
		print("Error: No possibilities for cell ", pos)
		grid[x][y][z] = Tile.EMPTY
		return
	
	# Weighted selection (you can add weights to make certain tiles more likely)
	var weights = {
		Tile.EMPTY: 2.0,
		Tile.FLOOR: 3.0,
		Tile.WALL: 2.5,
		Tile.DOOR: 0.5,
		Tile.PILLAR: 1.0
	}
	
	var weighted_possibilities = []
	for tile in possibilities:
		var weight = weights.get(tile, 1.0)
		for i in int(weight * 10):  # Scale weights
			weighted_possibilities.append(tile)
	
	grid[x][y][z] = weighted_possibilities[randi() % weighted_possibilities.size()]
	possible_states[x][y][z] = [grid[x][y][z]]

func propagate_constraints(changed_pos):
	var stack = [changed_pos]
	
	while not stack.is_empty():
		var pos = stack.pop_back()
		var x = pos[0]
		var y = pos[1]
		var z = pos[2]
		
		var neighbors = get_neighbors(x, y, z)
		var directions = [
			[-1, 0, 0],  # North
			[1, 0, 0],   # South
			[0, 0, -1],  # East
			[0, 0, 1],   # West
			[0, 1, 0],   # Up
			[0, -1, 0]   # Down
		]
		
		for i in range(neighbors.size()):
			var neighbor_pos = neighbors[i]
			if neighbor_pos == null:
				continue
			
			var nx = neighbor_pos[0]
			var ny = neighbor_pos[1]
			var nz = neighbor_pos[2]
			
			if grid[nx][ny][nz] != -1:  # Already collapsed
				continue
			
			var old_possibilities = possible_states[nx][ny][nz].duplicate()
			var new_possibilities = []
			
			# Check which tiles can still be placed based on current cell
			for tile in old_possibilities:
				if can_place_tile(tile, nx, ny, nz):
					new_possibilities.append(tile)
			
			possible_states[nx][ny][nz] = new_possibilities
			
			# If possibilities changed, add to stack for further propagation
			if new_possibilities.size() < old_possibilities.size():
				if neighbor_pos not in stack:
					stack.append(neighbor_pos)

func can_place_tile(tile, x, y, z) -> bool:
	var neighbors = get_neighbors(x, y, z)
	var directions = [0, 1, 2, 3, 4, 5]  # N, S, E, W, U, D
	
	for i in range(neighbors.size()):
		var neighbor_pos = neighbors[i]
		if neighbor_pos == null:
			continue
		
		var nx = neighbor_pos[0]
		var ny = neighbor_pos[1]
		var nz = neighbor_pos[2]
		
		var neighbor_tile = grid[nx][ny][nz]
		if neighbor_tile == -1:  # Not collapsed yet
			continue
		
		# Check if this tile can connect to the neighbor
		var direction = directions[i]
		var opposite_direction = get_opposite_direction(direction)
		
		if not tile_rules[tile][direction].has(neighbor_tile):
			return false
		if not tile_rules[neighbor_tile][opposite_direction].has(tile):
			return false
	
	return true

func get_neighbors(x, y, z):
	var neighbors = []
	var offsets = [
		[-1, 0, 0],  # North
		[1, 0, 0],   # South
		[0, 0, -1],  # East
		[0, 0, 1],   # West
		[0, 1, 0],   # Up
		[0, -1, 0]   # Down
	]
	
	for offset in offsets:
		var nx = x + offset[0]
		var ny = y + offset[1]
		var nz = z + offset[2]
		
		if nx >= 0 and nx < width and ny >= 0 and ny < height and nz >= 0 and nz < depth:
			neighbors.append([nx, ny, nz])
		else:
			neighbors.append(null)
	
	return neighbors

func get_opposite_direction(direction):
	match direction:
		0: return 1  # North -> South
		1: return 0  # South -> North
		2: return 3  # East -> West
		3: return 2  # West -> East
		4: return 5  # Up -> Down
		5: return 4  # Down -> Up
		_: return direction

func is_fully_collapsed() -> bool:
	for x in width:
		for y in height:
			for z in depth:
				if grid[x][y][z] == -1:
					return false
	return true

func create_meshes():
	# Clear existing meshes
	for child in get_children():
		child.queue_free()
	
	for x in width:
		for y in height:
			for z in depth:
				var tile = grid[x][y][z]
				if tile != Tile.EMPTY and tile != -1:
					create_tile_mesh(tile, Vector3(x, y, z))

func create_tile_mesh(tile_type, grid_pos):
	var mesh_instance = MeshInstance3D.new()
	var world_pos = grid_pos * cell_size
	mesh_instance.position = world_pos
	
	var mesh
	var material = StandardMaterial3D.new()
	
	match tile_type:
		Tile.FLOOR:
			mesh = BoxMesh.new()
			mesh.size = Vector3(cell_size, 0.2, cell_size)
			material.albedo_color = Color(0.6, 0.4, 0.2)  # Brown floor
		
		Tile.WALL:
			mesh = BoxMesh.new()
			mesh.size = Vector3(cell_size, cell_size, cell_size)
			material.albedo_color = Color(0.7, 0.7, 0.7)  # Gray wall
		
		Tile.DOOR:
			# Create door frame
			mesh = BoxMesh.new()
			mesh.size = Vector3(cell_size, cell_size * 0.8, 0.2)
			material.albedo_color = Color(0.4, 0.2, 0.1)  # Dark brown door
		
		Tile.PILLAR:
			mesh = CylinderMesh.new()
			mesh.top_radius = cell_size * 0.2
			mesh.bottom_radius = cell_size * 0.2
			mesh.height = cell_size
			material.albedo_color = Color(0.5, 0.5, 0.8)  # Blue pillar
		
		_:
			mesh = BoxMesh.new()
			mesh.size = Vector3(cell_size * 0.8, cell_size * 0.8, cell_size * 0.8)
			material.albedo_color = Color.WHITE
	
	mesh_instance.mesh = mesh
	material.roughness = 0.8
	mesh_instance.material_override = material
	
	# Add collision
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = mesh.create_trimesh_shape()
	static_body.add_child(collision_shape)
	mesh_instance.add_child(static_body)
	
	add_child(mesh_instance)

# Additional utility functions for enhanced WFC

func add_seed_rooms():
	"""Add predefined room patterns to guide generation"""
	# Place a guaranteed room in the center
	var center_x = width / 2
	var center_z = depth / 2
	
	# Create a 3x3 room
	for x in range(center_x - 1, center_x + 2):
		for z in range(center_z - 1, center_z + 2):
			if x >= 0 and x < width and z >= 0 and z < depth:
				possible_states[x][0][z] = [Tile.FLOOR]
				possible_states[x][1][z] = [Tile.EMPTY]

func apply_structural_constraints():
	"""Ensure structural integrity and navigability"""
	# Ensure ground level has some floors
	for x in width:
		for z in depth:
			if randi() % 4 == 0:  # 25% chance for guaranteed floor
				possible_states[x][0][z] = [Tile.FLOOR]
	
	# Add some guaranteed pillars for support
	for i in range(width * depth / 20):
		var x = randi() % width
		var z = randi() % depth
		for y in range(height):
			if y == 0:
				possible_states[x][y][z] = [Tile.PILLAR]
			else:
				possible_states[x][y][z] = [Tile.PILLAR, Tile.EMPTY]

# Enhanced generation function
func generate_advanced_dungeon():
	"""Generate dungeon with better structure"""
	initialize_grid()
	add_seed_rooms()
	apply_structural_constraints()
	run_wfc()
	post_process_generation()
	create_meshes()

func post_process_generation():
	"""Clean up generation artifacts and ensure connectivity"""
	# Ensure there are some doors
	var door_count = 0
	for x in width:
		for y in height:
			for z in depth:
				if grid[x][y][z] == Tile.DOOR:
					door_count += 1
	
	# If no doors, convert some walls to doors
	if door_count < 3:
		add_doors_to_walls()

func add_doors_to_walls():
	"""Convert some strategic walls to doors for connectivity"""
	var walls_converted = 0
	for x in range(1, width - 1):
		for z in range(1, depth - 1):
			if grid[x][0][z] == Tile.WALL and walls_converted < 5:
				# Check if this wall separates floor areas
				var neighbors_floors = 0
				var neighbor_positions = [[x-1, 0, z], [x+1, 0, z], [x, 0, z-1], [x, 0, z+1]]
				
				for pos in neighbor_positions:
					if pos[0] >= 0 and pos[0] < width and pos[2] >= 0 and pos[2] < depth:
						if grid[pos[0]][pos[1]][pos[2]] == Tile.FLOOR:
							neighbors_floors += 1
				
				if neighbors_floors >= 2:
					grid[x][0][z] = Tile.DOOR
					walls_converted += 1
