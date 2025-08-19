extends Node3D

# Wave Function Collapse parameters
const GRID_SIZE = 20
const TILE_SIZE = 2.0
const COLLAPSE_SPEED = 0.1

# Tile types with their collapse rules
enum TileType {
	EMPTY,
	ROCK,
	CRYSTAL,
	VOID,
	BRIDGE
}

# Each tile stores possible states
class WFCTile:
	var possible_states: Array[TileType]
	var collapsed: bool = false
	var final_state: TileType
	var position: Vector3
	var mesh_instance: MeshInstance3D
	
	func _init(pos: Vector3):
		position = pos
		possible_states.assign([TileType.EMPTY, TileType.ROCK, TileType.CRYSTAL, TileType.VOID, TileType.BRIDGE])

# Grid of tiles and visual components
var grid: Array[Array] = []
var collapse_timer: float = 0.0
var current_collapse_pos: Vector2i = Vector2i.ZERO
var is_generating: bool = true

# Materials for different tile types
var materials: Dictionary = {}

func _ready():
	setup_materials()
	setup_camera()
	initialize_grid()
	
func setup_materials():
	# Rock material - dark gray
	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.3, 0.3, 0.3)
	rock_mat.roughness = 0.8
	materials[TileType.ROCK] = rock_mat
	
	# Crystal material - blue with emission
	var crystal_mat = StandardMaterial3D.new()
	crystal_mat.albedo_color = Color(0.2, 0.4, 1.0)
	crystal_mat.emission = Color(0.1, 0.2, 0.5)
	crystal_mat.roughness = 0.1
	materials[TileType.CRYSTAL] = crystal_mat
	
	# Bridge material - brown
	var bridge_mat = StandardMaterial3D.new()
	bridge_mat.albedo_color = Color(0.6, 0.4, 0.2)
	bridge_mat.roughness = 0.6
	materials[TileType.BRIDGE] = bridge_mat

func setup_camera():
	var camera = Camera3D.new()
	camera.position = Vector3(GRID_SIZE, GRID_SIZE * 0.8, GRID_SIZE * 1.2)
	add_child(camera)
	camera.look_at(Vector3(GRID_SIZE/2, 0, GRID_SIZE/2))
	
	# Add some ambient lighting
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.3
	camera.environment = env
	
	# Directional light
	var light = DirectionalLight3D.new()
	light.position = Vector3(10, 10, 10)
	add_child(light)
	light.look_at(Vector3.ZERO, Vector3.UP)

func initialize_grid():
	grid.resize(GRID_SIZE)
	for x in range(GRID_SIZE):
		grid[x] = []
		grid[x].resize(GRID_SIZE)
		for z in range(GRID_SIZE):
			var pos = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
			var tile = WFCTile.new(pos)
			grid[x][z] = tile
			
			# Create visual placeholder
			var mesh_instance = MeshInstance3D.new()
			var box_mesh = BoxMesh.new()
			box_mesh.size = Vector3(TILE_SIZE * 0.9, 0.1, TILE_SIZE * 0.9)
			mesh_instance.mesh = box_mesh
			mesh_instance.position = pos
			
			# Uncollapsed tiles are transparent
			var placeholder_mat = StandardMaterial3D.new()
			placeholder_mat.albedo_color = Color(1, 1, 1, 0.1)
			placeholder_mat.flags_transparent = true
			mesh_instance.material_override = placeholder_mat
			
			tile.mesh_instance = mesh_instance
			add_child(mesh_instance)

func _process(delta):
	if not is_generating:
		return
		
	collapse_timer += delta
	if collapse_timer >= COLLAPSE_SPEED:
		collapse_timer = 0.0
		collapse_next_tile()

func collapse_next_tile():
	# Find tile with minimum entropy (fewest possible states)
	var min_entropy = 999
	var candidates: Array[Vector2i] = []
	
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			var tile = grid[x][z]
			if not tile.collapsed:
				var entropy = tile.possible_states.size()
				if entropy < min_entropy and entropy > 0:
					min_entropy = entropy
					candidates.clear()
					candidates.append(Vector2i(x, z))
				elif entropy == min_entropy:
					candidates.append(Vector2i(x, z))
	
	if candidates.is_empty():
		is_generating = false
		print("Wave Function Collapse complete!")
		return
	
	# Randomly pick from minimum entropy candidates
	var chosen = candidates[randi() % candidates.size()]
	collapse_tile(chosen.x, chosen.y)
	propagate_constraints(chosen.x, chosen.y)

func collapse_tile(x: int, z: int):
	var tile = grid[x][z]
	if tile.collapsed:
		return
	
	# Choose random state from possible states
	if tile.possible_states.is_empty():
		tile.final_state = TileType.VOID
	else:
		tile.final_state = tile.possible_states[randi() % tile.possible_states.size()]
	
	tile.collapsed = true
	update_tile_visual(tile)

func update_tile_visual(tile: WFCTile):
	var mesh_instance = tile.mesh_instance
	
	match tile.final_state:
		TileType.EMPTY:
			mesh_instance.visible = false
		TileType.VOID:
			mesh_instance.visible = false
		TileType.ROCK:
			var box = BoxMesh.new()
			box.size = Vector3(TILE_SIZE * 0.9, randf_range(0.5, 2.0), TILE_SIZE * 0.9)
			mesh_instance.mesh = box
			mesh_instance.material_override = materials[TileType.ROCK]
			mesh_instance.position.y = box.size.y / 2
		TileType.CRYSTAL:
			var prism = BoxMesh.new()
			prism.size = Vector3(TILE_SIZE * 0.6, randf_range(1.0, 3.0), TILE_SIZE * 0.6)
			mesh_instance.mesh = prism
			mesh_instance.material_override = materials[TileType.CRYSTAL]
			mesh_instance.position.y = prism.size.y / 2
			mesh_instance.rotation.y = randf() * PI
		TileType.BRIDGE:
			var bridge = BoxMesh.new()
			bridge.size = Vector3(TILE_SIZE * 0.8, 0.2, TILE_SIZE * 0.8)
			mesh_instance.mesh = bridge
			mesh_instance.material_override = materials[TileType.BRIDGE]
			mesh_instance.position.y = 0.5

func propagate_constraints(x: int, z: int):
	var collapsed_tile = grid[x][z]
	var neighbors = get_neighbors(x, z)
	
	for neighbor_pos in neighbors:
		var nx = neighbor_pos.x
		var nz = neighbor_pos.y
		var neighbor = grid[nx][nz]
		
		if neighbor.collapsed:
			continue
			
		# Remove incompatible states based on adjacency rules
		var allowed_states = get_allowed_adjacent_states(collapsed_tile.final_state)
		var new_possible: Array[TileType] = []
		
		for state in neighbor.possible_states:
			if state in allowed_states:
				new_possible.append(state)
		
		neighbor.possible_states = new_possible
		
		# If no states possible, force to VOID
		if neighbor.possible_states.is_empty():
			neighbor.possible_states.clear()
			neighbor.possible_states.append(TileType.VOID)

func get_neighbors(x: int, z: int) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	
	for dir in directions:
		var nx = x + dir.x
		var nz = z + dir.y
		if nx >= 0 and nx < GRID_SIZE and nz >= 0 and nz < GRID_SIZE:
			neighbors.append(Vector2i(nx, nz))
	
	return neighbors

func get_allowed_adjacent_states(state: TileType) -> Array[TileType]:
	# Define adjacency rules for the strange landscape
	match state:
		TileType.EMPTY:
			return [TileType.EMPTY, TileType.BRIDGE, TileType.VOID]
		TileType.ROCK:
			return [TileType.ROCK, TileType.CRYSTAL, TileType.BRIDGE, TileType.EMPTY]
		TileType.CRYSTAL:
			return [TileType.CRYSTAL, TileType.ROCK, TileType.VOID, TileType.EMPTY]
		TileType.VOID:
			return [TileType.VOID, TileType.BRIDGE, TileType.CRYSTAL, TileType.EMPTY]
		TileType.BRIDGE:
			return [TileType.BRIDGE, TileType.EMPTY, TileType.ROCK, TileType.VOID]
		_:
			return [TileType.EMPTY]
