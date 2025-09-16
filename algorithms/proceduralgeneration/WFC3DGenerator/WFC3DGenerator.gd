@tool
extends Node3D
class_name AdvancedWFCGenerator

# Advanced WFC with socket-based connections + Queer Joyful Tiles
@export var grid_dimensions: Vector3i = Vector3i(8, 2, 8)  # Smaller grid for testing
@export var tile_size: float = 4.0
@export var generate: bool = false : set = _trigger_generation
@export var clear_all: bool = false : set = _clear_all
@export var seed_value: int = 0
@export var room_density: float = 0.3
@export var corridor_density: float = 0.4

# Socket types for precise connections
enum SocketType {
	NONE,           # No connection
	FLOOR_OPEN,     # Open floor space
	WALL_SOLID,     # Solid wall
	DOOR_FRAME,     # Door opening
	CORRIDOR_PATH,  # Corridor pathway
	ROOM_SPACE,     # Room interior
	PILLAR_BASE,    # Pillar connection
	STAIR_UP,       # Stairs going up
	STAIR_DOWN      # Stairs going down
}

# Tile definitions with socket connections
class WFCTile:
	var name: String
	var sockets: Array[SocketType] = []  # [North, South, East, West, Up, Down]
	var weight: float = 1.0
	var mesh_type: String = ""
	var color: Color = Color.WHITE
	var can_rotate: bool = true
	
	func _init(tile_name: String, socket_pattern: Array[SocketType], w: float = 1.0, mesh: String = "box", col: Color = Color.WHITE, can_rot: bool = true):
		name = tile_name
		sockets = socket_pattern.duplicate()
		weight = w
		mesh_type = mesh
		color = col
		can_rotate = can_rot

var tile_library: Array[WFCTile] = []
var grid: Array = []  # 3D grid of cells
var generation_queue: Array = []

class GridCell:
	var position: Vector3i
	var possible_tiles: Array[WFCTile] = []
	var collapsed: bool = false
	var chosen_tile: WFCTile = null
	var rotation: int = 0  # 0-3 for 90-degree rotations
	
	func _init(pos: Vector3i):
		position = pos
	
	func get_entropy() -> int:
		return possible_tiles.size()
	
	func collapse_with_weights() -> bool:
		if possible_tiles.is_empty():
			print("ERROR: No possible tiles for cell at ", position)
			# Set as empty tile as fallback
			collapsed = true
			chosen_tile = null
			return false
		
		# Calculate total weight
		var total_weight = 0.0
		for tile in possible_tiles:
			total_weight += tile.weight
		
		# Random selection based on weights
		var random_val = randf() * total_weight
		var current_weight = 0.0
		
		for tile in possible_tiles:
			current_weight += tile.weight
			if random_val <= current_weight:
				chosen_tile = tile
				if tile.can_rotate:
					rotation = randi() % 4
				else:
					rotation = 0
				collapsed = true
				return true
		
		# Fallback - choose first tile if random selection fails
		chosen_tile = possible_tiles[0]
		rotation = 0
		collapsed = true
		return true

func _ready():
	setup_tile_library()

func _trigger_generation(value):
	if value:
		generate_wfc_space()

func _clear_all(value):
	if value:
		clear_generated_content()

func setup_tile_library():
	tile_library.clear()
	
	# SIMPLIFIED TILE SET FOR BETTER COMPATIBILITY
	
	# Empty/Air tile - can connect to anything
	tile_library.append(WFCTile.new("Empty", 
		[SocketType.NONE, SocketType.NONE, SocketType.NONE, SocketType.NONE, SocketType.NONE, SocketType.NONE],
		1.0, "none", Color.TRANSPARENT))
	
	# Basic floor - connects to other floors and walls
	tile_library.append(WFCTile.new("Floor", 
		[SocketType.FLOOR_OPEN, SocketType.FLOOR_OPEN, SocketType.FLOOR_OPEN, SocketType.FLOOR_OPEN, SocketType.NONE, SocketType.WALL_SOLID],
		5.0, "floor", Color(0.6, 0.4, 0.2)))
	
	# Basic wall - connects to walls and floors
	tile_library.append(WFCTile.new("Wall", 
		[SocketType.WALL_SOLID, SocketType.WALL_SOLID, SocketType.WALL_SOLID, SocketType.WALL_SOLID, SocketType.NONE, SocketType.WALL_SOLID],
		3.0, "wall_straight", Color(0.7, 0.7, 0.7)))
	
	# ADD SIMPLIFIED QUEER JOYFUL TILES
	add_queer_joyful_tiles()
	
	print("Tile library setup complete. Total tiles: ", tile_library.size())
	for tile in tile_library:
		print("- ", tile.name, " (weight: ", tile.weight, ")")

func add_queer_joyful_tiles():
	"""Add simplified queer joyful tiles that are more compatible"""
	
	# RAINBOW DANCE FLOOR - acts like a floor
	tile_library.append(WFCTile.new("Rainbow_Dance_Floor", 
		[SocketType.FLOOR_OPEN, SocketType.FLOOR_OPEN, SocketType.FLOOR_OPEN, SocketType.FLOOR_OPEN, SocketType.NONE, SocketType.WALL_SOLID],
		6.0, "rainbow_floor", Color(1.0, 0.3, 0.8), true))
	
	# PRIDE FLAG WALL - acts like a wall
	tile_library.append(WFCTile.new("Pride_Flag_Wall", 
		[SocketType.WALL_SOLID, SocketType.WALL_SOLID, SocketType.WALL_SOLID, SocketType.WALL_SOLID, SocketType.NONE, SocketType.WALL_SOLID],
		3.0, "pride_wall", Color(0.9, 0.4, 0.0), true))
	
	# COMMUNITY CIRCLE - acts like a floor
	tile_library.append(WFCTile.new("Community_Circle", 
		[SocketType.FLOOR_OPEN, SocketType.FLOOR_OPEN, SocketType.FLOOR_OPEN, SocketType.FLOOR_OPEN, SocketType.NONE, SocketType.WALL_SOLID],
		4.0, "community_circle", Color(0.7, 0.2, 0.9), true))
	
	# GLITTER FOUNTAIN - acts like a floor with some decoration
	tile_library.append(WFCTile.new("Glitter_Fountain", 
		[SocketType.FLOOR_OPEN, SocketType.FLOOR_OPEN, SocketType.FLOOR_OPEN, SocketType.FLOOR_OPEN, SocketType.NONE, SocketType.WALL_SOLID],
		2.0, "glitter_fountain", Color(0.0, 0.8, 0.9), false))
	
	# LOVE ARCHWAY - acts like a wall with openings
	tile_library.append(WFCTile.new("Love_Archway", 
		[SocketType.FLOOR_OPEN, SocketType.FLOOR_OPEN, SocketType.WALL_SOLID, SocketType.WALL_SOLID, SocketType.NONE, SocketType.WALL_SOLID],
		2.0, "love_archway", Color(1.0, 0.8, 0.0), false))
	
	# SAFE SPACE - acts like a floor
	tile_library.append(WFCTile.new("Safe_Space", 
		[SocketType.FLOOR_OPEN, SocketType.FLOOR_OPEN, SocketType.FLOOR_OPEN, SocketType.FLOOR_OPEN, SocketType.NONE, SocketType.WALL_SOLID],
		3.0, "safe_alcove", Color(0.4, 0.7, 0.4), true))
	
	print("🌈 Added 6 simplified queer joyful tiles!")

func generate_wfc_space():
	if seed_value > 0:
		seed(seed_value)
	
	print("\n=== STARTING WFC GENERATION ===")
	print("Grid size: ", grid_dimensions)
	print("Using seed: ", seed_value if seed_value > 0 else "random")
	
	clear_generated_content()
	initialize_grid()
	run_wfc_algorithm()
	generate_3d_meshes()
	print("=== WFC GENERATION COMPLETE ===\n")

func clear_generated_content():
	print("Clearing existing content...")
	var cleared_count = 0
	for child in get_children():
		if child.has_meta("wfc_generated"):
			child.queue_free()
			cleared_count += 1
	print("Cleared ", cleared_count, " generated objects")

func initialize_grid():
	print("Initializing grid...")
	grid.clear()
	grid.resize(grid_dimensions.x)
	
	var total_cells = grid_dimensions.x * grid_dimensions.y * grid_dimensions.z
	
	for x in grid_dimensions.x:
		grid[x] = []
		grid[x].resize(grid_dimensions.y)
		for y in grid_dimensions.y:
			grid[x][y] = []
			grid[x][y].resize(grid_dimensions.z)
			for z in grid_dimensions.z:
				var cell = GridCell.new(Vector3i(x, y, z))
				cell.possible_tiles = tile_library.duplicate()
				grid[x][y][z] = cell
	
	print("Grid initialized with ", total_cells, " cells, each with ", tile_library.size(), " possible tiles")

func run_wfc_algorithm():
	print("Starting WFC algorithm...")
	var max_iterations = grid_dimensions.x * grid_dimensions.y * grid_dimensions.z * 2
	var iterations = 0
	var last_progress = -1
	
	while not is_fully_collapsed() and iterations < max_iterations:
		var lowest_entropy_cell = find_lowest_entropy_cell()
		if lowest_entropy_cell == null:
			print("No valid cell found for collapse. Stopping.")
			break
		
		if not lowest_entropy_cell.collapse_with_weights():
			print("Failed to collapse cell at: ", lowest_entropy_cell.position)
			# Continue anyway - the cell is marked as collapsed
		
		propagate_constraints(lowest_entropy_cell)
		iterations += 1
		
		# Progress feedback
		var progress = int((float(iterations) / float(max_iterations)) * 100)
		if progress > last_progress and progress % 10 == 0:
			print("Progress: ", progress, "% (", iterations, "/", max_iterations, " iterations)")
			last_progress = progress
	
	var collapsed_count = count_collapsed_cells()
	var total_cells = grid_dimensions.x * grid_dimensions.y * grid_dimensions.z
	print("WFC completed in ", iterations, " iterations")
	print("Collapsed cells: ", collapsed_count, "/", total_cells, " (", int(float(collapsed_count)/float(total_cells)*100), "%)")

func count_collapsed_cells() -> int:
	var count = 0
	for x in grid_dimensions.x:
		for y in grid_dimensions.y:
			for z in grid_dimensions.z:
				if grid[x][y][z].collapsed:
					count += 1
	return count

func find_lowest_entropy_cell() -> GridCell:
	var min_entropy = INF
	var candidates: Array[GridCell] = []
	
	for x in grid_dimensions.x:
		for y in grid_dimensions.y:
			for z in grid_dimensions.z:
				var cell: GridCell = grid[x][y][z]
				if not cell.collapsed:
					var entropy = cell.get_entropy()
					if entropy > 0 and entropy < min_entropy:
						min_entropy = entropy
						candidates = [cell]
					elif entropy > 0 and entropy == min_entropy:
						candidates.append(cell)
	
	if candidates.is_empty():
		# Find any uncollapsed cell as fallback
		for x in grid_dimensions.x:
			for y in grid_dimensions.y:
				for z in grid_dimensions.z:
					var cell: GridCell = grid[x][y][z]
					if not cell.collapsed:
						print("Using fallback cell at ", cell.position, " with entropy ", cell.get_entropy())
						return cell
		return null
	
	return candidates[randi() % candidates.size()]

func propagate_constraints(collapsed_cell: GridCell):
	var propagation_stack: Array[GridCell] = [collapsed_cell]
	var processed_cells: Array[Vector3i] = []
	
	while not propagation_stack.is_empty():
		var current_cell = propagation_stack.pop_back()
		if current_cell.position in processed_cells:
			continue
		processed_cells.append(current_cell.position)
		
		var neighbors = get_neighbor_cells(current_cell.position)
		
		for i in range(6):  # 6 directions
			var neighbor = neighbors[i]
			if neighbor == null or neighbor.collapsed:
				continue
			
			var valid_tiles: Array[WFCTile] = []
			
			for tile in neighbor.possible_tiles:
				if can_tiles_connect_with_rotation(current_cell.chosen_tile, current_cell.rotation, tile, 0, i):
					valid_tiles.append(tile)
			
			var old_count = neighbor.possible_tiles.size()
			neighbor.possible_tiles = valid_tiles
			
			# If no valid tiles, give it a default set
			if neighbor.possible_tiles.is_empty():
				# Emergency fallback - use empty tile
				var empty_tile = tile_library.filter(func(t): return t.name == "Empty")
				if not empty_tile.is_empty():
					neighbor.possible_tiles = [empty_tile[0]]
			
			if neighbor.possible_tiles.size() < old_count and neighbor not in propagation_stack:
				propagation_stack.append(neighbor)

func get_neighbor_cells(pos: Vector3i) -> Array:
	var directions = [
		Vector3i(0, 0, -1),  # North
		Vector3i(0, 0, 1),   # South  
		Vector3i(1, 0, 0),   # East
		Vector3i(-1, 0, 0),  # West
		Vector3i(0, 1, 0),   # Up
		Vector3i(0, -1, 0)   # Down
	]
	
	var neighbors = []
	for direction in directions:
		var neighbor_pos = pos + direction
		if is_valid_position(neighbor_pos):
			neighbors.append(grid[neighbor_pos.x][neighbor_pos.y][neighbor_pos.z])
		else:
			neighbors.append(null)
	
	return neighbors

func can_tiles_connect_with_rotation(tile1: WFCTile, rotation1: int, tile2: WFCTile, rotation2: int, direction: int) -> bool:
	if tile1 == null or tile2 == null:
		return true  # Allow null connections
	
	var socket1 = get_rotated_socket(tile1, rotation1, direction)
	var socket2 = get_rotated_socket(tile2, rotation2, get_opposite_direction(direction))
	
	return sockets_compatible(socket1, socket2)

func get_rotated_socket(tile: WFCTile, rotation: int, direction: int) -> SocketType:
	# Only rotate horizontal directions (N=0, S=1, E=2, W=3)
	if direction >= 4:  # Up/Down don't rotate
		return tile.sockets[direction]
	
	var rotated_direction = (direction + rotation) % 4
	return tile.sockets[rotated_direction]

func sockets_compatible(socket1: SocketType, socket2: SocketType) -> bool:
	# SIMPLIFIED COMPATIBILITY - more permissive
	match socket1:
		SocketType.NONE:
			return socket2 in [SocketType.NONE, SocketType.WALL_SOLID]
		SocketType.FLOOR_OPEN:
			return socket2 in [SocketType.FLOOR_OPEN, SocketType.WALL_SOLID, SocketType.NONE]
		SocketType.WALL_SOLID:
			return socket2 in [SocketType.WALL_SOLID, SocketType.FLOOR_OPEN, SocketType.NONE]
		_:
			return true  # Allow other combinations

func get_opposite_direction(direction: int) -> int:
	match direction:
		0: return 1  # North -> South
		1: return 0  # South -> North  
		2: return 3  # East -> West
		3: return 2  # West -> East
		4: return 5  # Up -> Down
		5: return 4  # Down -> Up
		_: return direction

func is_valid_position(pos: Vector3i) -> bool:
	return pos.x >= 0 and pos.x < grid_dimensions.x and \
		   pos.y >= 0 and pos.y < grid_dimensions.y and \
		   pos.z >= 0 and pos.z < grid_dimensions.z

func is_fully_collapsed() -> bool:
	for x in grid_dimensions.x:
		for y in grid_dimensions.y:
			for z in grid_dimensions.z:
				if not grid[x][y][z].collapsed:
					return false
	return true

func generate_3d_meshes():
	print("Generating 3D meshes...")
	var mesh_count = 0
	
	for x in grid_dimensions.x:
		for y in grid_dimensions.y:
			for z in grid_dimensions.z:
				var cell: GridCell = grid[x][y][z]
				if cell.collapsed and cell.chosen_tile != null and cell.chosen_tile.mesh_type != "none":
					create_tile_mesh(cell)
					mesh_count += 1
	
	print("Generated ", mesh_count, " meshes")

func create_tile_mesh(cell: GridCell):
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.set_meta("wfc_generated", true)
	mesh_instance.name = cell.chosen_tile.name + "_" + str(cell.position)
	
	# Position in world space
	mesh_instance.position = Vector3(cell.position) * tile_size
	
	# Create mesh based on type
	var mesh = create_mesh_for_type(cell.chosen_tile.mesh_type)
	mesh_instance.mesh = mesh
	
	# Apply rotation
	mesh_instance.rotation_degrees.y = cell.rotation * 90.0
	
	# Create and apply material
	var material = StandardMaterial3D.new()
	material.albedo_color = cell.chosen_tile.color
	material.roughness = 0.7
	material.metallic = 0.2
	# Make materials brighter and more vibrant
	material.emission_enabled = true
	material.emission = cell.chosen_tile.color * 0.1
	mesh_instance.material_override = material
	
	# Add collision for walkable surfaces
	if cell.chosen_tile.mesh_type in ["floor", "rainbow_floor", "community_circle", "safe_alcove"]:
		add_collision_to_mesh(mesh_instance, mesh)
	
	add_child(mesh_instance)
	if Engine.is_editor_hint():
		mesh_instance.owner = get_tree().edited_scene_root

func create_mesh_for_type(mesh_type: String) -> Mesh:
	match mesh_type:
		"floor":
			var box = BoxMesh.new()
			box.size = Vector3(tile_size, 0.2, tile_size)
			return box
		"wall_straight":
			var box = BoxMesh.new()
			box.size = Vector3(tile_size, tile_size, 0.3)
			return box
		
		# QUEER JOYFUL TILE MESHES
		"rainbow_floor":
			var box = BoxMesh.new()
			box.size = Vector3(tile_size, 0.4, tile_size)  # Thicker for dancing
			return box
		"pride_wall":
			var box = BoxMesh.new()
			box.size = Vector3(tile_size, tile_size, 0.4)
			return box
		"community_circle":
			var cylinder = CylinderMesh.new()
			cylinder.top_radius = tile_size * 0.45
			cylinder.bottom_radius = tile_size * 0.45
			cylinder.height = 0.3
			cylinder.radial_segments = 16
			return cylinder
		"glitter_fountain":
			var cylinder = CylinderMesh.new()
			cylinder.top_radius = tile_size * 0.2
			cylinder.bottom_radius = tile_size * 0.35
			cylinder.height = tile_size * 0.8
			cylinder.radial_segments = 12
			return cylinder
		"love_archway":
			var box = BoxMesh.new()
			box.size = Vector3(tile_size, tile_size * 0.9, 0.3)
			return box
		"safe_alcove":
			var box = BoxMesh.new()
			box.size = Vector3(tile_size * 0.9, 0.4, tile_size * 0.9)
			return box
		
		_:
			var box = BoxMesh.new()
			box.size = Vector3(tile_size * 0.5, tile_size * 0.5, tile_size * 0.5)
			return box

func add_collision_to_mesh(mesh_instance: MeshInstance3D, mesh: Mesh):
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = mesh.create_trimesh_shape()
	static_body.add_child(collision_shape)
	mesh_instance.add_child(static_body)
	
	if Engine.is_editor_hint():
		static_body.owner = get_tree().edited_scene_root
		collision_shape.owner = get_tree().edited_scene_root
