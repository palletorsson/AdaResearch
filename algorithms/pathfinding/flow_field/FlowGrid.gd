extends Resource
class_name FlowGrid

# Dimensions
var width: int = 50
var height: int = 50
var size: int = 0
var cell_size: float = 1.0

# Fields
# 0 = Walkable (Cost 1), 255 = Wall (Impassable), 1-254 = Costs
var cost_field: PackedByteArray
# Distance to target (approximate)
var integration_field: PackedInt32Array
# Resulting flow vectors
var vector_field: PackedVector2Array

# Constants
const MAX_COST = 65535

func _init(w: int, h: int, c_size: float) -> void:
	width = w
	height = h
	size = w * h
	cell_size = c_size
	
	cost_field = PackedByteArray()
	cost_field.resize(size)
	cost_field.fill(1) # Default cost 1
	
	integration_field = PackedInt32Array()
	integration_field.resize(size)
	
	vector_field = PackedVector2Array()
	vector_field.resize(size)
	vector_field.fill(Vector2.ZERO)

# Convert World to Grid
func world_to_grid(pos: Vector3) -> Vector2i:
	var x = int((pos.x + (width * cell_size) / 2.0) / cell_size)
	var y = int((pos.z + (height * cell_size) / 2.0) / cell_size)
	return Vector2i(clampi(x, 0, width - 1), clampi(y, 0, height - 1))

# Convert Grid to World
func grid_to_world(x: int, y: int) -> Vector3:
	var wx = (x * cell_size) - (width * cell_size) / 2.0 + (cell_size / 2.0)
	var wz = (y * cell_size) - (height * cell_size) / 2.0 + (cell_size / 2.0)
	return Vector3(wx, 0, wz)

# Set Cost (Wall = 255)
func set_cost(x: int, y: int, cost: int) -> void:
	if x >= 0 and x < width and y >= 0 and y < height:
		cost_field[y * width + x] = cost

# Reset all costs to default (1)
func reset_costs() -> void:
	cost_field.fill(1)

# Fill a rectangle with a specific cost
func fill_rect(x: int, y: int, w: int, h: int, cost: int) -> void:
	for j in range(h):
		for i in range(w):
			set_cost(x + i, y + j, cost)

# CORE ALGORITHM: Generate Flow Field from Target
func calculate_flow_field(target_x: int, target_y: int) -> void:
	# 1. Integration Field (BFS / Dijkstra)
	integration_field.fill(MAX_COST)
	
	var target_idx = target_y * width + target_x
	integration_field[target_idx] = 0
	
	var queue = []
	queue.append(target_idx)
	
	# Neighbors: N, E, S, W (4-way for integration)
	var neighbors = [ -width, 1, width, -1 ]
	
	while not queue.is_empty():
		var curr_idx = queue.pop_front()
		var curr_cost = integration_field[curr_idx]
		
		# Check neighbors
		# We need to ensure we don't wrap around lines, so simple idx math needs x check
		var cx = curr_idx % width
		
		# Optimized neighbor loop
		for i in range(4):
			var n_idx = curr_idx + neighbors[i]
			
			# Bounds check
			if n_idx < 0 or n_idx >= size: continue
			
			# Fix Horizontal Wrapping
			var nx = n_idx % width
			if abs(nx - cx) > 1: continue # Warped
			
			# Wall Check
			var tile_cost = cost_field[n_idx]
			if tile_cost == 255: continue
			
			var new_cost = curr_cost + tile_cost
			if new_cost < integration_field[n_idx]:
				integration_field[n_idx] = new_cost
				queue.append(n_idx)
				
	# 2. Vector Field (Gradient)
	# For each cell, point to neighbor with LOWEST integration cost
	for y in range(height):
		for x in range(width):
			var idx = y * width + x
			var my_cost = integration_field[idx]
			
			if my_cost == MAX_COST: 
				vector_field[idx] = Vector2.ZERO
				continue
				
			var best_cost = my_cost
			var best_dir = Vector2.ZERO
			
			# Check 8 neighbors for vector (smoother)
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0: continue
					
					var nx = x + dx
					var ny = y + dy
					
					if nx >= 0 and nx < width and ny >= 0 and ny < height:
						var n_idx = ny * width + nx
						var n_cost = integration_field[n_idx]
						
						if n_cost < best_cost:
							best_cost = n_cost
							best_dir = Vector2(dx, dy)
			
			vector_field[idx] = best_dir.normalized()

func get_vector(world_pos: Vector3) -> Vector3:
	var coord = world_to_grid(world_pos)
	var idx = coord.y * width + coord.x
	var v2 = vector_field[idx] 
	return Vector3(v2.x, 0, v2.y)

# Generate a Perlin Noise Vector Field
func generate_noise_field(seed_val: int, time_offset: float = 0.0) -> void:
	var noise = FastNoiseLite.new()
	noise.seed = seed_val
	noise.frequency = 0.05
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	for i in range(size):
		var y = i / width
		var x = i % width
		
		# Get noise angle (map -1..1 to 0..TAU)
		# Use 3D noise for smoothed time animation
		var angle = noise.get_noise_3d(x, y, time_offset * 10.0) * TAU * 2.0
		vector_field[i] = Vector2(cos(angle), sin(angle))

# Generate a Constant Linear Field
func generate_linear_field(dir: Vector2) -> void:
	var v = dir.normalized()
	vector_field.fill(v)
