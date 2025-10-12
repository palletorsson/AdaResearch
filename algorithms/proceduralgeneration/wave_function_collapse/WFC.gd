extends Node3D

@export_group("WFC Settings")
@export var grid_size: Vector3i = Vector3i(10, 5, 10)
@export var cell_size: float = 2.0
@export var generation_speed: float = 0.1  # Time between steps
@export var auto_generate: bool = true
@export var show_debug_info: bool = true

@export_group("Tile Setup")
@export var tile_textures: Array[Texture2D] = []
@export var use_default_edges: bool = true

# WFC Core classes
class WFCCell:
	var collapsed: bool = false
	var options: Array[int] = []
	var position: Vector3i
	
	func _init(tile_count: int, pos: Vector3i = Vector3i.ZERO):
		position = pos
		for i in range(tile_count):
			options.append(i)
	
	func set_options(new_options: Array[int]):
		options = new_options.duplicate()
	
	func collapse_to(tile_index: int):
		collapsed = true
		options = [tile_index]

class WFCBasicTile:
	var index: int
	var edges: Array[String] = []
	var texture: Texture2D
	var material: StandardMaterial3D
	
	# Adjacent tile indices that can connect
	var up: Array[int] = []      # Y+
	var down: Array[int] = []    # Y-
	var north: Array[int] = []   # Z-
	var south: Array[int] = []   # Z+
	var east: Array[int] = []    # X+
	var west: Array[int] = []    # X-
	
	func _init(idx: int, tile_edges: Array[String], tex: Texture2D = null):
		index = idx
		edges = tile_edges.duplicate()
		texture = tex
		_create_material()
	
	func _create_material():
		material = StandardMaterial3D.new()
		if texture:
			material.albedo_texture = texture
		material.roughness = 0.8
		material.metallic = 0.1
	
	func analyze_adjacency(all_tiles: Array):
		# Analyze which tiles can be adjacent based on matching edges
		up.clear()
		down.clear()
		north.clear()
		south.clear()
		east.clear()
		west.clear()
		
		for i in range(all_tiles.size()):
			var other_tile = all_tiles[i] as WFCBasicTile
			
			# For 3D, we check edge compatibility
			# Top face (Y+) matches with bottom face (Y-) of tile above
			if _edges_compatible(edges[0], other_tile.edges[1]):  # top matches bottom
				up.append(i)
			
			# Bottom face (Y-) matches with top face (Y+) of tile below  
			if _edges_compatible(edges[1], other_tile.edges[0]):  # bottom matches top
				down.append(i)
			
			# North face (Z-) matches south face (Z+) of northern tile
			if _edges_compatible(edges[2], other_tile.edges[3]):  # north matches south
				north.append(i)
			
			# South face (Z+) matches north face (Z-) of southern tile
			if _edges_compatible(edges[3], other_tile.edges[2]):  # south matches north
				south.append(i)
			
			# East face (X+) matches west face (X-) of eastern tile
			if _edges_compatible(edges[4], other_tile.edges[5]):  # east matches west
				east.append(i)
			
			# West face (X-) matches east face (X+) of western tile
			if _edges_compatible(edges[5], other_tile.edges[4]):  # west matches east
				west.append(i)
	
	func _edges_compatible(edge_a: String, edge_b: String) -> bool:
		# Simple compatibility: edges must be identical or complementary
		return edge_a == _reverse_string(edge_b)
	
	func _reverse_string(s: String) -> String:
		var chars = s.split("")
		chars.reverse()
		return "".join(chars)

# Main WFC variables
var tiles: Array[WFCBasicTile] = []
var grid: Array[WFCCell] = []
var mesh_instances: Array[MeshInstance3D] = []
var generation_timer: float = 0.0
var is_generating: bool = false

# Default tile edge definitions (circuit-like)
var default_tile_edges: Array = [
	["AAA", "AAA", "AAA", "AAA", "AAA", "AAA"],  # Tile 0: Empty
	["BBB", "BBB", "BBB", "BBB", "BBB", "BBB"],  # Tile 1: Solid
	["BBB", "BBB", "BCB", "BBB", "BBB", "BBB"],  # Tile 2: Single connection
	["BBB", "BBB", "BDB", "BDB", "BBB", "BBB"],  # Tile 3: Opposite connections
	["ABB", "BBA", "BCB", "AAA", "AAA", "AAA"],  # Tile 4: Corner piece
	["ABB", "BBA", "BBB", "BBB", "BBB", "BBB"],  # Tile 5: Straight piece
	["BBB", "BBB", "BCB", "BCB", "BBB", "BBB"],  # Tile 6: T-junction
	["BDB", "BDB", "BCB", "BCB", "BBB", "BBB"],  # Tile 7: Cross
	["BDB", "BCB", "BBB", "BBB", "BBB", "BBB"],  # Tile 8: L-piece
	["BCB", "BBB", "BCB", "BCB", "BBB", "BBB"],  # Tile 9: Three-way
	["BCB", "BCB", "BCB", "BCB", "BBB", "BBB"],  # Tile 10: Four-way
	["BCB", "BBB", "BCB", "BBB", "BBB", "BBB"],  # Tile 11: Two-way
]

func _ready():
	setup_tiles()
	initialize_grid()
	if auto_generate:
		start_generation()

func setup_tiles():
	tiles.clear()
	
	# Create default materials if no textures provided
	if tile_textures.is_empty():
		_create_default_textures()
	
	# Initialize tiles with edges and textures
	for i in range(12):
		var edges: Array[String] = []
		if use_default_edges:
			# Convert the array to Array[String]
			var raw_edges = default_tile_edges[i]
			for edge in raw_edges:
				edges.append(edge as String)
		else:
			edges = ["BBB", "BBB", "BBB", "BBB", "BBB", "BBB"]
		
		var texture = tile_textures[i] if i < tile_textures.size() else null
		var tile = WFCBasicTile.new(i, edges, texture)
		tiles.append(tile)
	
	# Generate rotated variations for some tiles (excluding symmetric ones)
	var original_count = tiles.size()
	for i in range(original_count):
		if _should_generate_rotations(i):
			_generate_rotations(tiles[i])
	
	# Analyze adjacency rules
	for tile in tiles:
		tile.analyze_adjacency(tiles)
	
	print("Generated ", tiles.size(), " total tiles (including rotations)")

func _should_generate_rotations(tile_index: int) -> bool:
	# Don't rotate symmetric tiles (0, 1, 7, 10)
	return not tile_index in [0, 1, 7, 10]

func _generate_rotations(base_tile: WFCBasicTile):
	# Generate Y-axis rotations (90°, 180°, 270°)
	for rotation in range(1, 4):
		var rotated_edges = _rotate_edges_y(base_tile.edges, rotation)
		var rotated_tile = WFCBasicTile.new(base_tile.index, rotated_edges, base_tile.texture)
		
		# Check if this rotation creates a unique tile
		if not _is_duplicate_tile(rotated_tile):
			tiles.append(rotated_tile)

func _rotate_edges_y(edges: Array[String], rotations: int) -> Array[String]:
	# Rotate horizontal edges (keep top/bottom, rotate north/south/east/west)
	var new_edges: Array[String] = edges.duplicate()
	for i in range(rotations):
		var temp: Array[String] = [new_edges[0], new_edges[1]]  # Keep top/bottom
		temp.append(new_edges[5])  # west -> north
		temp.append(new_edges[2])  # north -> south  
		temp.append(new_edges[3])  # south -> east
		temp.append(new_edges[4])  # east -> west
		new_edges = temp
	return new_edges

func _is_duplicate_tile(new_tile: WFCBasicTile) -> bool:
	for existing_tile in tiles:
		if existing_tile.edges == new_tile.edges:
			return true
	return false

func _create_default_textures():
	# Create simple colored textures if none provided
	var colors = [
		Color.BLACK, Color.WHITE, Color.RED, Color.GREEN, 
		Color.BLUE, Color.YELLOW, Color.MAGENTA, Color.CYAN,
		Color.ORANGE, Color.PURPLE, Color.PINK, Color.LIME
	]
	
	tile_textures.clear()
	for i in range(12):
		var image = Image.create(64, 64, false, Image.FORMAT_RGB8)
		image.fill(colors[i % colors.size()])
		var texture = ImageTexture.new()
		texture.create_from_image(image)
		tile_textures.append(texture)

func initialize_grid():
	grid.clear()
	mesh_instances.clear()
	
	# Clear existing mesh instances
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	# Create grid cells
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			for z in range(grid_size.z):
				var pos = Vector3i(x, y, z)
				var cell = WFCCell.new(tiles.size(), pos)
				grid.append(cell)
				
				# Create mesh instance for visualization
				var mesh_instance = MeshInstance3D.new()
				var box_mesh = BoxMesh.new()
				box_mesh.size = Vector3.ONE * cell_size * 0.9  # Slightly smaller for gaps
				mesh_instance.mesh = box_mesh
				mesh_instance.position = Vector3(x, y, z) * cell_size
				add_child(mesh_instance)
				mesh_instances.append(mesh_instance)
	
	print("Initialized grid: ", grid_size, " = ", grid.size(), " cells")

func start_generation():
	is_generating = true
	generation_timer = 0.0

func _process(delta):
	if is_generating:
		generation_timer += delta
		if generation_timer >= generation_speed:
			generation_timer = 0.0
			wfc_step()

func wfc_step():
	# Get uncollapsed cells
	var uncollapsed_cells = grid.filter(func(cell): return not cell.collapsed)
	
	if uncollapsed_cells.is_empty():
		is_generating = false
		print("WFC Generation complete!")
		return
	
	# Find cells with minimum entropy (fewest options)
	var min_entropy = INF
	for cell in uncollapsed_cells:
		if cell.options.size() < min_entropy:
			min_entropy = cell.options.size()
	
	var min_entropy_cells = uncollapsed_cells.filter(func(cell): return cell.options.size() == min_entropy)
	
	if min_entropy == 0:
		print("Contradiction detected! Restarting...")
		restart_generation()
		return
	
	# Pick random cell from minimum entropy cells
	var chosen_cell = min_entropy_cells[randi() % min_entropy_cells.size()]
	
	# Collapse the cell
	var chosen_tile = chosen_cell.options[randi() % chosen_cell.options.size()]
	chosen_cell.collapse_to(chosen_tile)
	
	# Update visualization
	_update_cell_visual(chosen_cell)
	
	# Propagate constraints
	_propagate_constraints(chosen_cell)

func _update_cell_visual(cell: WFCCell):
	var index = _cell_position_to_index(cell.position)
	if index >= 0 and index < mesh_instances.size():
		var mesh_instance = mesh_instances[index]
		if cell.collapsed and cell.options.size() > 0:
			var tile = tiles[cell.options[0]]
			mesh_instance.material_override = tile.material
		else:
			# Show uncollapsed state
			var material = StandardMaterial3D.new()
			material.albedo_color = Color.GRAY
			material.flags_transparent = true
			material.albedo_color.a = 0.3
			mesh_instance.material_override = material

func _propagate_constraints(changed_cell: WFCCell):
	var stack = [changed_cell]
	
	while not stack.is_empty():
		var current_cell = stack.pop_back()
		var neighbors = _get_neighbors(current_cell.position)
		
		for neighbor_data in neighbors:
			var neighbor_cell = neighbor_data["cell"]
			var direction = neighbor_data["direction"]
			
			if neighbor_cell.collapsed:
				continue
			
			var valid_options = _get_valid_options_for_direction(current_cell, direction)
			var old_size = neighbor_cell.options.size()
			
			# Filter neighbor options
			neighbor_cell.options = neighbor_cell.options.filter(func(option): return option in valid_options)
			
			# If options changed, add to stack for further propagation
			if neighbor_cell.options.size() != old_size:
				stack.append(neighbor_cell)
				_update_cell_visual(neighbor_cell)

func _get_neighbors(pos: Vector3i) -> Array:
	var neighbors = []
	var directions = [
		{"offset": Vector3i(0, 1, 0), "direction": "up"},
		{"offset": Vector3i(0, -1, 0), "direction": "down"},
		{"offset": Vector3i(0, 0, -1), "direction": "north"},
		{"offset": Vector3i(0, 0, 1), "direction": "south"},
		{"offset": Vector3i(1, 0, 0), "direction": "east"},
		{"offset": Vector3i(-1, 0, 0), "direction": "west"}
	]
	
	for dir_data in directions:
		var neighbor_pos = pos + dir_data["offset"]
		if _is_valid_position(neighbor_pos):
			var neighbor_cell = _get_cell_at_position(neighbor_pos)
			neighbors.append({"cell": neighbor_cell, "direction": dir_data["direction"]})
	
	return neighbors

func _get_valid_options_for_direction(cell: WFCCell, direction: String) -> Array[int]:
	var valid_options: Array[int] = []
	
	for tile_index in cell.options:
		var tile = tiles[tile_index]
		match direction:
			"up":
				valid_options.append_array(tile.up)
			"down":
				valid_options.append_array(tile.down)
			"north":
				valid_options.append_array(tile.north)
			"south":
				valid_options.append_array(tile.south)
			"east":
				valid_options.append_array(tile.east)
			"west":
				valid_options.append_array(tile.west)
	
	# Remove duplicates
	var unique_options: Array[int] = []
	for option in valid_options:
		if not option in unique_options:
			unique_options.append(option)
	
	return unique_options

func _is_valid_position(pos: Vector3i) -> bool:
	return pos.x >= 0 and pos.x < grid_size.x and \
		   pos.y >= 0 and pos.y < grid_size.y and \
		   pos.z >= 0 and pos.z < grid_size.z

func _get_cell_at_position(pos: Vector3i) -> WFCCell:
	var index = _cell_position_to_index(pos)
	return grid[index]

func _cell_position_to_index(pos: Vector3i) -> int:
	return pos.x + pos.y * grid_size.x + pos.z * grid_size.x * grid_size.y

func restart_generation():
	initialize_grid()
	if auto_generate:
		start_generation()

# Public functions for external control
func generate_step():
	if is_generating:
		wfc_step()

func toggle_generation():
	is_generating = not is_generating
	if is_generating:
		generation_timer = 0.0

func clear_grid():
	is_generating = false
	initialize_grid()

# Debug information
func _draw_debug_info():
	if not show_debug_info:
		return
	
	var uncollapsed = grid.filter(func(cell): return not cell.collapsed)
	print("Uncollapsed cells: ", uncollapsed.size(), "/", grid.size())
	
	if uncollapsed.size() > 0:
		var min_entropy = uncollapsed.map(func(cell): return cell.options.size()).min()
		var max_entropy = uncollapsed.map(func(cell): return cell.options.size()).max()
		print("Entropy range: ", min_entropy, " - ", max_entropy)

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space key
		toggle_generation()
	elif event.is_action_pressed("ui_cancel"):  # Escape key  
		restart_generation()
	elif event.is_action_pressed("ui_select"):  # Enter key
		generate_step()
