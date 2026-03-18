extends Node3D

@export var grid_size: Vector3i = Vector3i(20, 10, 20)
@export var tile_size: float = 2.0
@export var tile_height: float = 1.0 # Half height match
@export var prototypes_path: String = "res://algorithms/proceduralgeneration/wfc3D/prototypes_3d.tscn"
@export var animate_generation: bool = true   # Toggle for real-time visualization
@export var steps_per_frame: int = 5          # Speed of visualization

var prototypes = []
var width: int
var height: int
var depth: int
var wave = []       # wave[index] = [possible_prototype_indices]
var collapsed = []  # collapsed[index] = prototype_index or -1
var stack = []      # For propagation
var weights = {}    # weights[proto_idx] = float

var is_running: bool = false
var cells_collapsed_count: int = 0
var total_cells: int = 0

func _ready() -> void:
	width = grid_size.x
	height = grid_size.y
	depth = grid_size.z
	total_cells = width * height * depth
	
	randomize()
	if not _load_prototypes():
		return
	
	_init_grid()
	
	# Initial base terrain generation
	_generate_base_terrain()
	
	# Calculate initial collapsed count from base terrain
	cells_collapsed_count = 0
	var initial_collapsed_indices = []
	for i in total_cells:
		if collapsed[i] != -1:
			cells_collapsed_count += 1
			initial_collapsed_indices.append(i)
	
	# Initial Propagation: Constrain the empty cells based on the fixed base terrain
	print("ðŸŒŠ Propagating initial constraints...")
	for idx in initial_collapsed_indices:
		if not _propagate(idx):
			push_error("Initial propagation failed! Base terrain invalid.")
			return
			
	# If NOT animating, run the rest instantly
	if not animate_generation:
		var success = _run_rest_of_wfc_instant()
		if success:
			print("âœ… WFC (Instant) Completed!")
		else:
			print("âŒ WFC (Instant) Failed!")
	else:
		print("â–¶ï¸ Starting WFC Animation...")
		is_running = true

func _process(_delta):
	if is_running:
		for i in range(steps_per_frame):
			if cells_collapsed_count >= total_cells:
				print("âœ… WFC (Animated) Completed!")
				is_running = false
				break
				
			# Perform one step
			if not _step_wfc():
				print("âŒ WFC Failed (Contradiction) during animation!")
				is_running = false
				break

func _load_prototypes() -> bool:
	if prototypes_path == "":
		push_error("No prototypes scene path!")
		return false
	
	var scene = ResourceLoader.load(prototypes_path)
	if not scene:
		push_error("Could not load prototypes: " + prototypes_path)
		return false
		
	var root = scene.instantiate()
	prototypes = []
	weights = {}
	
	for i in root.get_child_count():
		var child = root.get_child(i)
		# Check for sockets metadata (robust check)
		if child.has_meta("sockets"):
			prototypes.append(child)
			# Read weight
			var w = 1.0
			if child.has_meta("weight"):
				w = float(child.get_meta("weight"))
			weights[i] = w
		else:
			push_warning("Skipping " + child.name + ": No sockets meta.")
			
	print("Loaded %d prototypes." % prototypes.size())
	return true

func _init_grid() -> void:
	wave = []
	collapsed = []
	wave.resize(total_cells)
	collapsed.resize(total_cells)
	
	# Clear existing children
	for c in get_children():
		c.queue_free()
	
	# Initial state: All prototypes are possible for all cells
	var all_indices = []
	for i in prototypes.size():
		all_indices.append(i)
	
	for i in total_cells:
		wave[i] = all_indices.duplicate()
		collapsed[i] = -1

func _step_wfc() -> bool:
	# 1. Find Min Entropy cell
	var idx = _find_min_entropy()
	if idx == -1:
		# Should check if we are actually done or stuck
		return true 
	
	# 2. Collapse it
	_collapse_cell(idx)
	cells_collapsed_count += 1
	
	# 3. Propagate
	if not _propagate(idx):
		return false
		
	return true

func _run_rest_of_wfc_instant() -> bool:
	# Propagate from the base layer up first (initial constraints)
	for z in range(depth):
		for x in range(width):
			var idx = _pos_to_idx(Vector3i(x, 0, z))
			if not _propagate(idx):
				return false
	
	while cells_collapsed_count < total_cells:
		if not _step_wfc():
			return false
	return true

func _generate_base_terrain() -> void:
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.08
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3
	
	# Find indices
	var air_idx = -1
	var air_water_idx = -1
	var water_idx = -1
	var sand_idx = -1
	var grass_idx = -1
	var stone_idx = -1
	var dirt_idx = -1
	
	var slope_n = -1
	var slope_s = -1
	var slope_e = -1
	var slope_w = -1
	
	for i in prototypes.size():
		var n = prototypes[i].name
		if n == "Water": water_idx = i
		elif n == "Sand": sand_idx = i
		elif n == "Grass": grass_idx = i
		elif n == "Stone": stone_idx = i
		elif n == "Dirt": dirt_idx = i
		elif n == "Air": air_idx = i
		elif n == "Air_Water": air_water_idx = i
		elif n == "Slope_N": slope_n = i
		elif n == "Slope_S": slope_s = i
		elif n == "Slope_E": slope_e = i
		elif n == "Slope_W": slope_w = i
	
	if water_idx == -1 or grass_idx == -1:
		push_warning("âš ï¸ Biome tiles missing, skipping base terrain gen.")
		return

	print("ðŸŒ Generating Heightmap & Ramps...")
	
	# 1. Generate Raw Heightmap
	var hmap = []
	hmap.resize(width)
	for x in range(width):
		hmap[x] = []
		hmap[x].resize(depth)
		for z in range(depth):
			var val = noise.get_noise_2d(x * tile_size, z * tile_size)
			var h = 0
			if val < -0.2: h = 0 # Water
			elif val < 0.0: h = 1 # Beach
			elif val < 0.3: h = 1 # Plains
			else: h = 2 + int((val - 0.3) * 8) # Mountains
			if h > height - 2: h = height - 2
			hmap[x][z] = h

	# 2. Smooth Heightmap (Ensure validity for walking)
	var changed = true
	while changed:
		changed = false
		for x in range(width):
			for z in range(depth):
				var my_h = hmap[x][z]
				
				var neighbors = [
					Vector2i(x+1, z), Vector2i(x-1, z), 
					Vector2i(x, z+1), Vector2i(x, z-1)
				]
				
				for n in neighbors:
					if n.x >= 0 and n.x < width and n.y >= 0 and n.y < depth:
						var n_h = hmap[n.x][n.y]
						if my_h > n_h + 1:
							hmap[x][z] = n_h + 1
							changed = true
							my_h = n_h + 1 # Update local
	
	# 3. Apply Blocks
	for x in range(width):
		for z in range(depth):
			var h = hmap[x][z]
			var top_block = grass_idx
			if h == 0: top_block = water_idx
			elif h == 1 and noise.get_noise_2d(x*tile_size, z*tile_size) < 0.0: top_block = sand_idx
			elif h > 2: top_block = stone_idx # High peaks
			
			var fill_block = dirt_idx
			if h > 2: fill_block = stone_idx
			if h == 0: fill_block = -1 # No fill under water
			
			for y in range(height):
				var idx = _pos_to_idx(Vector3i(x, y, z))
				var chosen = -1
				
				if y < h:
					chosen = fill_block
				elif y == h:
					chosen = top_block
				elif y == h + 1:
					# Check for Ramps (Slope)
					var ramp_type = -1
					# CORRECTED SLOPE DIRECTION: Reverse N/S due to rotation
					# North Z-1 neighbor is higher -> We need High-North ramp.
					# Slope_S has rot=-90 -> High at -Z (North). So use Slope_S.
					if z > 0 and hmap[x][z-1] == h + 1: ramp_type = slope_s 
					
					# South Z+1 neighbor is higher -> We need High-South ramp.
					# Slope_N has rot=90 -> High at +Z (South). So use Slope_N.
					elif z < depth-1 and hmap[x][z+1] == h + 1: ramp_type = slope_n 
					
					elif x < width-1 and hmap[x+1][z] == h + 1: ramp_type = slope_e
					elif x > 0 and hmap[x-1][z] == h + 1: ramp_type = slope_w
					
					if ramp_type != -1:
						chosen = ramp_type
					else:
						# Default Air
						if h == 0: chosen = air_water_idx
						else: chosen = air_idx
				else:
					# Use standard air for sky
					chosen = air_idx
				
				if chosen != -1:
					collapsed[idx] = chosen
					wave[idx] = [chosen]
					# Spawn IMMEIDATELY for base terrain so it's visible at start
					_spawn_tile(idx, chosen)

func _spawn_tile(idx: int, proto_idx: int):
	if proto_idx == -1: return
	
	var proto = prototypes[proto_idx]
	if proto.name == "Air" or proto.name == "Sky" or proto.name == "Air_Water":
		return # Don't render empty air
		
	var tile = proto.duplicate()
	var pos_i = _idx_to_pos(idx)
	tile.position = Vector3(pos_i.x * tile_size, pos_i.y * tile_height, pos_i.z * tile_size)
	tile.name = "Tile_%d_%d_%d" % [pos_i.x, pos_i.y, pos_i.z]
	add_child(tile)

func _collapse_cell(idx: int) -> void:
	var options = wave[idx]
	var total_weight = 0.0
	for opt in options:
		total_weight += weights.get(opt, 1.0)
	
	var r = randf() * total_weight
	var chosen = options[0]
	var current_w = 0.0
	
	for opt in options:
		current_w += weights.get(opt, 1.0)
		if r <= current_w:
			chosen = opt
			break
	
	collapsed[idx] = chosen
	wave[idx] = [chosen]
	
	# Visual Spawn (Immediate)
	_spawn_tile(idx, chosen)

func _find_min_entropy() -> int:
	var min_entropy = 999999.0
	var min_idx = -1
	
	for i in total_cells:
		if collapsed[i] != -1:
			continue
			
		var options = wave[i]
		if options.size() == 0:
			return -1 # Error state usually
			
		# Entropy calc: size + small random noise
		var entropy = float(options.size()) + randf() * 0.1
		
		if entropy < min_entropy:
			min_entropy = entropy
			min_idx = i
			
	return min_idx

func _propagate(start_idx: int) -> bool:
	stack = [start_idx]
	
	while stack.size() > 0:
		var current_idx = stack.pop_back()
		var cur_pos = _idx_to_pos(current_idx)
		var current_options = wave[current_idx]
		
		# Check all 6 neighbors
		var neighbors = [
			Vector3i(cur_pos.x + 1, cur_pos.y, cur_pos.z), # +X
			Vector3i(cur_pos.x - 1, cur_pos.y, cur_pos.z), # -X
			Vector3i(cur_pos.x, cur_pos.y + 1, cur_pos.z), # +Y (Up)
			Vector3i(cur_pos.x, cur_pos.y - 1, cur_pos.z), # -Y (Down)
			Vector3i(cur_pos.x, cur_pos.y, cur_pos.z + 1), # +Z
			Vector3i(cur_pos.x, cur_pos.y, cur_pos.z - 1)  # -Z
		]
		
		# Directions corresponding to neighbors
		# CAREFUL: "px" means Positive X face of CURRENT tile needs to match "nx" of NEIGHBOR +X
		var dirs = ["px", "nx", "py", "ny", "pz", "nz"]
		var opps = ["nx", "px", "ny", "py", "nz", "pz"]
		
		for i in range(6):
			var n_pos = neighbors[i]
			if not _is_valid_pos(n_pos):
				continue
				
			var n_idx = _pos_to_idx(n_pos)
			if collapsed[n_idx] != -1:
				continue # Already collapsed
				
			var neighbor_options = wave[n_idx]
			var direction = dirs[i]
			var opposite = opps[i]
			
			var new_options = []
			var changed = false
			
			for n_opt in neighbor_options:
				# Check if n_opt is compatible with ANY of current_options
				var compatible = false
				for c_opt in current_options:
					if _check_socket(c_opt, n_opt, direction, opposite):
						compatible = true
						break
				
				if compatible:
					new_options.append(n_opt)
				else:
					changed = true
			
			if new_options.size() == 0:
				return false # Contradiction!
				
			if changed:
				wave[n_idx] = new_options
				stack.append(n_idx)
				
	return true

func _is_valid_pos(pos: Vector3i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height and pos.z >= 0 and pos.z < depth

func _pos_to_idx(pos: Vector3i) -> int:
	return (pos.y * width * depth) + (pos.z * width) + pos.x

func _idx_to_pos(idx: int) -> Vector3i:
	var y = idx / (width * depth)
	var rem = idx % (width * depth)
	var z = rem / width
	var x = rem % width
	return Vector3i(x, y, z)

func _check_socket(tile_a: int, tile_b: int, dir_a: String, dir_b: String) -> bool:
	# Get socket name for tile_a in direction dir_a
	var meta_a = prototypes[tile_a].get_meta("sockets")
	var socket_a = meta_a[dir_a]
	
	# Get socket name for tile_b in direction dir_b
	var meta_b = prototypes[tile_b].get_meta("sockets")
	var socket_b = meta_b[dir_b]
	
	return socket_a == socket_b

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
