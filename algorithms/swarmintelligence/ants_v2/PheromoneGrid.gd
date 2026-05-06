extends Resource
class_name PheromoneGrid

# Dimensions
var width: int = 128
var height: int = 128
var size: int = 0

# Data (Packed arrays for performance)
var grid_home: PackedFloat32Array
var grid_food: PackedFloat32Array

# Parameters
var decay_rate: float = 0.98

func _init(w: int = 128, h: int = 128) -> void:
	width = w
	height = h
	size = w * h
	
	grid_home = PackedFloat32Array()
	grid_home.resize(size)
	grid_home.fill(0.0)
	
	grid_food = PackedFloat32Array()
	grid_food.resize(size)
	grid_food.fill(0.0)

# Get index from coordinates (clamped)
func get_index(x: int, y: int) -> int:
	# Clamp to borders
	if x < 0: x = 0
	if x >= width: x = width - 1
	if y < 0: y = 0
	if y >= height: y = height - 1
	return y * width + x

# Add pheromone at position
func add_pheromone(x: int, y: int, type: int, amount: float) -> void:
	var idx = get_index(x, y)
	if type == 0: # HOME
		grid_home[idx] = min(grid_home[idx] + amount, 10.0) # Cap values
	else: # FOOD
		grid_food[idx] = min(grid_food[idx] + amount, 10.0)

# Get pheromone level
func get_pheromone(x: int, y: int, type: int) -> float:
	var idx = get_index(x, y)
	if type == 0:
		return grid_home[idx]
	else:
		return grid_food[idx]

# Process Decay (Run potentially every frame or tick)
func process_decay() -> void:
	for i in range(size):
		grid_home[i] *= decay_rate
		grid_food[i] *= decay_rate
		
		# Threshold cleanup optimization (optional)
		if grid_home[i] < 0.01: grid_home[i] = 0.0
		if grid_food[i] < 0.01: grid_food[i] = 0.0

# Process Source Emission (Centers of Power)
func process_source_emission(centers: Array) -> void:
	for c in centers:
		# Approximate circle as square for speed
		var r = int(c.radius)
		var start_x = clampi(c.x - r, 0, width)
		var end_x = clampi(c.x + r + 1, 0, width)
		var start_y = clampi(c.y - r, 0, height)
		var end_y = clampi(c.y + r + 1, 0, height)
		
		for y in range(start_y, end_y):
			for x in range(start_x, end_x):
				# Distance check for circle?
				if (x - c.x)*(x - c.x) + (y - c.y)*(y - c.y) <= r*r:
					add_pheromone(x, y, c.type, c.amount)

# Process Diffusion (Blur)
func process_diffusion() -> void:
	# Simple 4-neighbor blur (In-place approximate)
	# Iterate excluding borders
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			var i = y * width + x
			
			# Home Blur
			if grid_home[i] > 0.001:
				var avg = (grid_home[i-1] + grid_home[i+1] + grid_home[i-width] + grid_home[i+width]) * 0.25
				grid_home[i] = lerp(grid_home[i], avg, 0.01)
			
			# Food Blur
			if grid_food[i] > 0.001:
				var avg = (grid_food[i-1] + grid_food[i+1] + grid_food[i-width] + grid_food[i+width]) * 0.25
				grid_food[i] = lerp(grid_food[i], avg, 0.01)

# Generate Image for visualization (Optimized)
func get_image() -> Image:
	var data = PackedByteArray()
	data.resize(width * height * 3) # RGB8
	
	for i in range(size):
		var h_val = grid_home[i]
		var f_val = grid_food[i]
		
		# Skip small values (black is 0)
		if h_val > 0.01 or f_val > 0.01:
			var idx = i * 3
			# R = Food, G = 0, B = Home
			# Clamp to 255
			var r = min(int(f_val * 255.0), 255)
			var b = min(int(h_val * 255.0), 255)
			
			data[idx] = r
			data[idx+1] = 0
			data[idx+2] = b
			
	return Image.create_from_data(width, height, false, Image.FORMAT_RGB8, data)
