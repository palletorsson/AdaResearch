extends Node3D

@export_group("Cave Generation")
@export var cave_size: Vector3i = Vector3i(20, 8, 20)
@export var cell_size: float = 4.0
@export var generation_speed: float = 0.02
@export var auto_generate: bool = true

@export_group("Cave Parameters")
@export var cave_density: float = 0.3  # How much of the cave is hollow
@export var entrance_probability: float = 0.1  # Chance for entrance tiles
@export var chamber_probability: float = 0.05  # Chance for large chambers
@export var water_probability: float = 0.02  # Chance for water features

@export_group("Model Synthesis")
@export var use_noise_seeding: bool = true
@export var noise_scale: float = 0.1
@export var connectivity_bias: float = 0.7  # Prefer connected paths

# Cave tile types with connectivity patterns
enum CaveType {
	SOLID,           # 0: Solid rock
	EMPTY,           # 1: Empty space
	TUNNEL_NS,       # 2: North-South tunnel
	TUNNEL_EW,       # 3: East-West tunnel  
	TUNNEL_UD,       # 4: Up-Down tunnel
	CORNER_NE,       # 5: Northeast corner
	CORNER_NW,       # 6: Northwest corner
	CORNER_SE,       # 7: Southeast corner
	CORNER_SW,       # 8: Southwest corner
	T_JUNCTION_N,    # 9: T-junction opening north
	T_JUNCTION_S,    # 10: T-junction opening south
	T_JUNCTION_E,    # 11: T-junction opening east
	T_JUNCTION_W,    # 12: T-junction opening west
	CROSS,           # 13: Four-way intersection
	CHAMBER,         # 14: Large chamber
	ENTRANCE,        # 15: Cave entrance
	WATER,           # 16: Water feature
	STALACTITE,      # 17: Stalactite formation
	STALAGMITE,      # 18: Stalagmite formation
	PILLAR           # 19: Support pillar
}

class CaveTile:
	var type: CaveType
	var connections: Dictionary = {}  # Direction -> bool (can connect)
	var mesh: Mesh
	var material: Material
	var weight: float = 1.0  # Probability weight for WFC
	
	func _init(tile_type: CaveType):
		type = tile_type
		_setup_connections()
		_create_mesh()
	
	func _setup_connections():
		# Define which directions each tile type can connect to
		match type:
			CaveType.SOLID:
				connections = {"north": false, "south": false, "east": false, "west": false, "up": false, "down": false}
			CaveType.EMPTY:
				connections = {"north": true, "south": true, "east": true, "west": true, "up": true, "down": true}
			CaveType.TUNNEL_NS:
				connections = {"north": true, "south": true, "east": false, "west": false, "up": false, "down": false}
			CaveType.TUNNEL_EW:
				connections = {"north": false, "south": false, "east": true, "west": true, "up": false, "down": false}
			CaveType.TUNNEL_UD:
				connections = {"north": false, "south": false, "east": false, "west": false, "up": true, "down": true}
			CaveType.CORNER_NE:
				connections = {"north": true, "south": false, "east": true, "west": false, "up": false, "down": false}
			CaveType.CORNER_NW:
				connections = {"north": true, "south": false, "east": false, "west": true, "up": false, "down": false}
			CaveType.CORNER_SE:
				connections = {"north": false, "south": true, "east": true, "west": false, "up": false, "down": false}
			CaveType.CORNER_SW:
				connections = {"north": false, "south": true, "east": false, "west": true, "up": false, "down": false}
			CaveType.T_JUNCTION_N:
				connections = {"north": true, "south": false, "east": true, "west": true, "up": false, "down": false}
			CaveType.T_JUNCTION_S:
				connections = {"north": false, "south": true, "east": true, "west": true, "up": false, "down": false}
			CaveType.T_JUNCTION_E:
				connections = {"north": true, "south": true, "east": true, "west": false, "up": false, "down": false}
			CaveType.T_JUNCTION_W:
				connections = {"north": true, "south": true, "east": false, "west": true, "up": false, "down": false}
			CaveType.CROSS:
				connections = {"north": true, "south": true, "east": true, "west": true, "up": false, "down": false}
			CaveType.CHAMBER:
				connections = {"north": true, "south": true, "east": true, "west": true, "up": true, "down": false}
			CaveType.ENTRANCE:
				connections = {"north": true, "south": false, "east": false, "west": false, "up": false, "down": false}
			CaveType.WATER:
				connections = {"north": true, "south": true, "east": true, "west": true, "up": false, "down": false}
			CaveType.STALACTITE:
				connections = {"north": false, "south": false, "east": false, "west": false, "up": false, "down": true}
			CaveType.STALAGMITE:
				connections = {"north": false, "south": false, "east": false, "west": false, "up": true, "down": false}
			CaveType.PILLAR:
				connections = {"north": false, "south": false, "east": false, "west": false, "up": true, "down": true}
	
	func _create_mesh():
		# Create procedural meshes for each cave tile type
		match type:
			CaveType.SOLID:
				mesh = _create_solid_block()
				material = _create_rock_material()
			CaveType.EMPTY:
				mesh = null  # No mesh for empty space
				material = null
			CaveType.TUNNEL_NS, CaveType.TUNNEL_EW, CaveType.TUNNEL_UD:
				mesh = _create_tunnel_mesh()
				material = _create_rock_material()
			CaveType.CORNER_NE, CaveType.CORNER_NW, CaveType.CORNER_SE, CaveType.CORNER_SW:
				mesh = _create_corner_mesh()
				material = _create_rock_material()
			CaveType.T_JUNCTION_N, CaveType.T_JUNCTION_S, CaveType.T_JUNCTION_E, CaveType.T_JUNCTION_W:
				mesh = _create_t_junction_mesh()
				material = _create_rock_material()
			CaveType.CROSS:
				mesh = _create_cross_mesh()
				material = _create_rock_material()
			CaveType.CHAMBER:
				mesh = _create_chamber_mesh()
				material = _create_rock_material()
			CaveType.ENTRANCE:
				mesh = _create_entrance_mesh()
				material = _create_rock_material()
			CaveType.WATER:
				mesh = _create_water_mesh()
				material = _create_water_material()
			CaveType.STALACTITE:
				mesh = _create_stalactite_mesh()
				material = _create_rock_material()
			CaveType.STALAGMITE:
				mesh = _create_stalagmite_mesh()
				material = _create_rock_material()
			CaveType.PILLAR:
				mesh = _create_pillar_mesh()
				material = _create_rock_material()
	
	func _create_solid_block() -> BoxMesh:
		var box = BoxMesh.new()
		box.size = Vector3.ONE * 4.0
		return box
	
	func _create_tunnel_mesh() -> ArrayMesh:
		# Create a tunnel by subtracting a cylinder from a box
		var array_mesh = ArrayMesh.new()
		var vertices = PackedVector3Array()
		var normals = PackedVector3Array()
		var uvs = PackedVector2Array()
		var indices = PackedInt32Array()
		
		# Create tunnel walls (simplified)
		var tunnel_radius = 1.5
		var segments = 12
		
		for i in range(segments):
			var angle = i * TAU / segments
			var x = cos(angle) * tunnel_radius
			var y = sin(angle) * tunnel_radius
			
			# Front and back vertices
			vertices.append(Vector3(x, y, -2))
			vertices.append(Vector3(x, y, 2))
			
			# Normals pointing inward
			normals.append(Vector3(cos(angle), sin(angle), 0))
			normals.append(Vector3(cos(angle), sin(angle), 0))
			
			# UVs
			uvs.append(Vector2(float(i) / segments, 0))
			uvs.append(Vector2(float(i) / segments, 1))
		
		# Create indices for tunnel walls
		for i in range(segments):
			var next_i = (i + 1) % segments
			
			# Two triangles per segment
			indices.append(i * 2)
			indices.append(next_i * 2)
			indices.append(i * 2 + 1)
			
			indices.append(next_i * 2)
			indices.append(next_i * 2 + 1)
			indices.append(i * 2 + 1)
		
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = indices
		
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return array_mesh
	
	func _create_corner_mesh() -> ArrayMesh:
		# Create L-shaped tunnel
		return _create_tunnel_mesh()  # Simplified for now
	
	func _create_t_junction_mesh() -> ArrayMesh:
		# Create T-shaped tunnel junction
		return _create_tunnel_mesh()  # Simplified for now
	
	func _create_cross_mesh() -> ArrayMesh:
		# Create four-way intersection
		return _create_tunnel_mesh()  # Simplified for now
	
	func _create_chamber_mesh() -> SphereMesh:
		var sphere = SphereMesh.new()
		sphere.radius = 3.0
		sphere.height = 3.0
		return sphere
	
	func _create_entrance_mesh() -> ArrayMesh:
		# Create cave entrance (arch shape)
		return _create_tunnel_mesh()  # Simplified for now
	
	func _create_water_mesh() -> BoxMesh:
		var box = BoxMesh.new()
		box.size = Vector3(4.0, 0.2, 4.0)
		return box
	
	func _create_stalactite_mesh() -> ArrayMesh:
		# Create hanging cone
		var array_mesh = ArrayMesh.new()
		var vertices = PackedVector3Array()
		var normals = PackedVector3Array()
		var indices = PackedInt32Array()
		
		# Simple cone pointing down
		vertices.append(Vector3(0, 2, 0))    # Top
		vertices.append(Vector3(0, -2, 0))   # Bottom point
		
		var segments = 8
		for i in range(segments):
			var angle = i * TAU / segments
			var x = cos(angle) * 0.5
			var z = sin(angle) * 0.5
			vertices.append(Vector3(x, 2, z))
			normals.append(Vector3(x, 0.5, z).normalized())
		
		# Create cone indices
		for i in range(segments):
			var next_i = (i + 1) % segments
			# Top triangle
			indices.append(0)
			indices.append(2 + i)
			indices.append(2 + next_i)
			
			# Bottom triangle  
			indices.append(1)
			indices.append(2 + next_i)
			indices.append(2 + i)
		
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices
		
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return array_mesh
	
	func _create_stalagmite_mesh() -> ArrayMesh:
		# Create cone pointing up
		var stalactite_mesh = _create_stalactite_mesh()
		# In a real implementation, we'd flip the vertices
		return stalactite_mesh
	
	func _create_pillar_mesh() -> CylinderMesh:
		var cylinder = CylinderMesh.new()
		cylinder.height = 4.0
		cylinder.top_radius = 0.8
		cylinder.bottom_radius = 0.8
		return cylinder
	
	func _create_rock_material() -> StandardMaterial3D:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.4, 0.3, 0.2)  # Brown rock
		material.roughness = 0.9
		material.metallic = 0.0
		return material
	
	func _create_water_material() -> StandardMaterial3D:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 0.4, 0.8, 0.7)  # Blue water
		material.roughness = 0.1
		material.metallic = 0.0
		material.flags_transparent = true
		return material

class CaveCell:
	var position: Vector3i
	var possible_tiles: Array[int] = []
	var collapsed: bool = false
	var selected_tile: int = -1
	var noise_influence: float = 0.0
	
	func _init(pos: Vector3i, tile_count: int):
		position = pos
		for i in range(tile_count):
			possible_tiles.append(i)
	
	func collapse_to_tile(tile_index: int):
		collapsed = true
		selected_tile = tile_index
		possible_tiles = [tile_index] as Array[int]
	
	func remove_tile_option(tile_index: int):
		possible_tiles.erase(tile_index)

# Main cave generation variables
var cave_tiles: Array[CaveTile] = []
var cave_grid: Array[CaveCell] = []
var mesh_instances: Array[MeshInstance3D] = []
var noise: FastNoiseLite
var generation_timer: float = 0.0
var is_generating: bool = false

func _ready():
	setup_noise()
	setup_cave_tiles()
	initialize_cave_grid()
	if auto_generate:
		start_generation()

func setup_noise():
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = noise_scale
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

func setup_cave_tiles():
	cave_tiles.clear()
	
	# Create all cave tile types
	for cave_type in CaveType.values():
		var tile = CaveTile.new(cave_type)
		
		# Set weights based on cave parameters
		match cave_type:
			CaveType.SOLID:
				tile.weight = 1.0 - cave_density
			CaveType.EMPTY:
				tile.weight = cave_density * 0.5
			CaveType.TUNNEL_NS, CaveType.TUNNEL_EW, CaveType.TUNNEL_UD:
				tile.weight = cave_density * 0.3
			CaveType.CORNER_NE, CaveType.CORNER_NW, CaveType.CORNER_SE, CaveType.CORNER_SW:
				tile.weight = cave_density * 0.2
			CaveType.T_JUNCTION_N, CaveType.T_JUNCTION_S, CaveType.T_JUNCTION_E, CaveType.T_JUNCTION_W:
				tile.weight = cave_density * 0.1
			CaveType.CROSS:
				tile.weight = cave_density * 0.05
			CaveType.CHAMBER:
				tile.weight = chamber_probability
			CaveType.ENTRANCE:
				tile.weight = entrance_probability
			CaveType.WATER:
				tile.weight = water_probability
			CaveType.STALACTITE, CaveType.STALAGMITE:
				tile.weight = cave_density * 0.1
			CaveType.PILLAR:
				tile.weight = cave_density * 0.05
		
		cave_tiles.append(tile)
	
	print("Created ", cave_tiles.size(), " cave tile types")

func initialize_cave_grid():
	cave_grid.clear()
	mesh_instances.clear()
	
	# Clear existing mesh instances
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	# Create cave cells with noise influence
	for x in range(cave_size.x):
		for y in range(cave_size.y):
			for z in range(cave_size.z):
				var pos = Vector3i(x, y, z)
				var cell = CaveCell.new(pos, cave_tiles.size())
				
				# Apply noise influence for more natural cave generation
				if use_noise_seeding:
					var world_pos = Vector3(x, y, z) * cell_size
					cell.noise_influence = noise.get_noise_3d(world_pos.x, world_pos.y, world_pos.z)
					
					# Bias towards hollow spaces in certain noise ranges
					if cell.noise_influence > 0.3:
						# Remove solid tile options in high noise areas
						cell.remove_tile_option(CaveType.SOLID)
					elif cell.noise_influence < -0.3:
						# Prefer solid tiles in low noise areas
						for i in range(cave_tiles.size()):
							if cave_tiles[i].type != CaveType.SOLID:
								cell.remove_tile_option(i)
				
				# Add entrance constraints at edges
				if x == 0 or x == cave_size.x - 1 or z == 0 or z == cave_size.z - 1:
					if y == 0:  # Ground level entrances
						cell.possible_tiles = [CaveType.ENTRANCE, CaveType.SOLID] as Array[int]
				
				# Force floor at bottom
				if y == 0:
					cell.remove_tile_option(CaveType.EMPTY)
				
				# Force ceiling constraint
				if y == cave_size.y - 1:
					cell.possible_tiles = [CaveType.SOLID, CaveType.STALACTITE] as Array[int]
				
				cave_grid.append(cell)
				
				# Create placeholder mesh instance
				var mesh_instance = MeshInstance3D.new()
				mesh_instance.position = Vector3(x, y, z) * cell_size
				add_child(mesh_instance)
				mesh_instances.append(mesh_instance)
	
	print("Initialized cave grid: ", cave_size, " = ", cave_grid.size(), " cells")

func start_generation():
	is_generating = true
	generation_timer = 0.0

func _process(delta):
	if is_generating:
		generation_timer += delta
		if generation_timer >= generation_speed:
			generation_timer = 0.0
			cave_wfc_step()

func cave_wfc_step():
	# Get uncollapsed cells
	var uncollapsed_cells = cave_grid.filter(func(cell): return not cell.collapsed)
	
	if uncollapsed_cells.is_empty():
		is_generating = false
		print("Cave generation complete!")
		_post_process_cave()
		return
	
	# Find minimum entropy cells (with connectivity bias)
	var min_entropy = INF
	for cell in uncollapsed_cells:
		var entropy = cell.possible_tiles.size()
		if use_noise_seeding:
			# Bias entropy based on noise and connectivity preferences
			entropy += cell.noise_influence * connectivity_bias
		if entropy < min_entropy:
			min_entropy = entropy
	
	var min_entropy_cells = uncollapsed_cells.filter(func(cell): 
		var entropy = cell.possible_tiles.size()
		if use_noise_seeding:
			entropy += cell.noise_influence * connectivity_bias
		return abs(entropy - min_entropy) < 0.1
	)
	
	if min_entropy_cells.is_empty():
		print("Cave generation failed - restarting...")
		restart_cave_generation()
		return
	
	# Pick weighted random cell
	var chosen_cell = _pick_weighted_cell(min_entropy_cells)
	
	# Collapse the cell with weighted tile selection
	var chosen_tile = _pick_weighted_tile(chosen_cell)
	chosen_cell.collapse_to_tile(chosen_tile)
	
	# Update visualization
	_update_cell_visual(chosen_cell)
	
	# Propagate constraints
	_propagate_cave_constraints(chosen_cell)

func _pick_weighted_cell(cells: Array[CaveCell]) -> CaveCell:
	# For now, just pick randomly - could add location-based weighting
	return cells[randi() % cells.size()]

func _pick_weighted_tile(cell: CaveCell) -> int:
	var weights = []
	var total_weight = 0.0
	
	for tile_index in cell.possible_tiles:
		var weight = cave_tiles[tile_index].weight
		
		# Apply noise influence
		if use_noise_seeding:
			if cave_tiles[tile_index].type == CaveType.EMPTY or cave_tiles[tile_index].type in [CaveType.TUNNEL_NS, CaveType.TUNNEL_EW, CaveType.CHAMBER]:
				weight *= (1.0 + cell.noise_influence * connectivity_bias)
			else:
				weight *= (1.0 - cell.noise_influence * connectivity_bias * 0.5)
		
		weights.append(weight)
		total_weight += weight
	
	# Weighted random selection
	var random_value = randf() * total_weight
	var cumulative_weight = 0.0
	
	for i in range(weights.size()):
		cumulative_weight += weights[i]
		if random_value <= cumulative_weight:
			return cell.possible_tiles[i]
	
	# Fallback
	return cell.possible_tiles[0] if cell.possible_tiles.size() > 0 else 0

func _update_cell_visual(cell: CaveCell):
	var index = _cell_position_to_index(cell.position)
	if index >= 0 and index < mesh_instances.size():
		var mesh_instance = mesh_instances[index]
		if cell.collapsed and cell.selected_tile >= 0:
			var tile = cave_tiles[cell.selected_tile]
			if tile.mesh != null:
				mesh_instance.mesh = tile.mesh
				mesh_instance.material_override = tile.material
			else:
				# Empty space - hide mesh
				mesh_instance.visible = false

func _propagate_cave_constraints(changed_cell: CaveCell):
	var stack = [changed_cell]
	var directions = [
		{"offset": Vector3i(0, 1, 0), "direction": "up", "opposite": "down"},
		{"offset": Vector3i(0, -1, 0), "direction": "down", "opposite": "up"},
		{"offset": Vector3i(0, 0, -1), "direction": "north", "opposite": "south"},
		{"offset": Vector3i(0, 0, 1), "direction": "south", "opposite": "north"},
		{"offset": Vector3i(1, 0, 0), "direction": "east", "opposite": "west"},
		{"offset": Vector3i(-1, 0, 0), "direction": "west", "opposite": "east"}
	]
	
	while not stack.is_empty():
		var current_cell = stack.pop_back()
		
		for dir_data in directions:
			var neighbor_pos = current_cell.position + dir_data["offset"]
			if not _is_valid_cave_position(neighbor_pos):
				continue
			
			var neighbor_cell = _get_cave_cell_at_position(neighbor_pos)
			if neighbor_cell.collapsed:
				continue
			
			var old_size = neighbor_cell.possible_tiles.size()
			var valid_tiles: Array[int] = []
			
			# Check which tiles can connect
			for tile_index in neighbor_cell.possible_tiles:
				var neighbor_tile = cave_tiles[tile_index]
				var can_connect = false
				
				for current_tile_index in current_cell.possible_tiles:
					var current_tile = cave_tiles[current_tile_index]
					
					# Check if tiles can connect in this direction
					var current_can_connect = current_tile.connections.get(dir_data["direction"], false)
					var neighbor_can_connect = neighbor_tile.connections.get(dir_data["opposite"], false)
					
					# Tiles are compatible if both want to connect or both don't
					if current_can_connect == neighbor_can_connect:
						can_connect = true
						break
				
				if can_connect:
					valid_tiles.append(tile_index)
			
			neighbor_cell.possible_tiles = valid_tiles
			
			if neighbor_cell.possible_tiles.size() != old_size:
				stack.append(neighbor_cell)
				if neighbor_cell.possible_tiles.size() == 0:
					print("Constraint violation detected!")
					return

func _post_process_cave():
	# Add additional cave features after main generation
	print("Post-processing cave...")
	
	# Add lighting
	_add_cave_lighting()
	
	# Add atmospheric effects
	_add_cave_atmosphere()

func _add_cave_lighting():
	# Add torches or bioluminescent lighting in chambers and tunnels
	for i in range(cave_grid.size()):
		var cell = cave_grid[i]
		if cell.collapsed and cell.selected_tile >= 0:
			var tile = cave_tiles[cell.selected_tile]
			if tile.type in [CaveType.CHAMBER, CaveType.CROSS, CaveType.ENTRANCE]:
				# Add point light
				var light = OmniLight3D.new()
				light.position = Vector3(cell.position) * cell_size + Vector3.ONE * cell_size * 0.5
				light.light_energy = 2.0
				light.light_color = Color(1.0, 0.8, 0.6)  # Warm torch light
				light.omni_range = cell_size * 3
				add_child(light)

func _add_cave_atmosphere():
	# Add fog or particle effects
	var environment = Environment.new()
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.3, 0.3, 0.4)
	environment.fog_light_energy = 0.5
	environment.fog_density = 0.1
	
	# Apply to camera if exists
	var camera = get_viewport().get_camera_3d()
	if camera:
		camera.environment = environment

func _is_valid_cave_position(pos: Vector3i) -> bool:
	return pos.x >= 0 and pos.x < cave_size.x and \
		   pos.y >= 0 and pos.y < cave_size.y and \
		   pos.z >= 0 and pos.z < cave_size.z

func _get_cave_cell_at_position(pos: Vector3i) -> CaveCell:
	var index = _cell_position_to_index(pos)
	return cave_grid[index]

func _cell_position_to_index(pos: Vector3i) -> int:
	return pos.x + pos.y * cave_size.x + pos.z * cave_size.x * cave_size.y

func restart_cave_generation():
	initialize_cave_grid()
	if auto_generate:
		start_generation()

# Public control functions
func toggle_generation():
	is_generating = not is_generating

func clear_cave():
	is_generating = false
	initialize_cave_grid()

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space
		toggle_generation()
	elif event.is_action_pressed("ui_cancel"):  # Escape
		restart_cave_generation()
	elif event.is_action_pressed("ui_select"):  # Enter
		if not is_generating:
			cave_wfc_step()
