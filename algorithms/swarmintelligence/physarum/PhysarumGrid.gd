extends Resource
class_name PhysarumGrid

# Dimensions
var width: int = 128
var height: int = 128
var size: int = 0

# Data (Single channel for Slime)
var grid: PackedFloat32Array

# Parameters
var decay_rate: float = 0.95 # Higher decay = thinner trails
var diffuse_rate: float = 0.5 # Fast diffusion helps network formation

func _init(w: int = 128, h: int = 128):
	width = w
	height = h
	size = w * h
	
	grid = PackedFloat32Array()
	grid.resize(size)
	grid.fill(0.0)

# Get index from coordinates (clamped)
func get_index(x: int, y: int) -> int:
	if x < 0: x = 0
	if x >= width: x = width - 1
	if y < 0: y = 0
	if y >= height: y = height - 1
	return y * width + x

# Add slime at position
func add_slime(x: int, y: int, amount: float):
	var idx = get_index(x, y)
	grid[idx] = min(grid[idx] + amount, 10.0)

# Get slime level
func get_slime(x: int, y: int) -> float:
	var idx = get_index(x, y)
	return grid[idx]

# Source Emission (Centers of Power - Food)
func process_attractors(centers: Array):
	for c in centers:
		var r = int(c.radius)
		var start_x = clampi(c.x - r, 0, width)
		var end_x = clampi(c.x + r + 1, 0, width)
		var start_y = clampi(c.y - r, 0, height)
		var end_y = clampi(c.y + r + 1, 0, height)
		
		for y in range(start_y, end_y):
			for x in range(start_x, end_x):
				if (x - c.x)*(x - c.x) + (y - c.y)*(y - c.y) <= r*r:
					add_slime(x, y, c.amount)

# Process Step (Decay + Diffusion)
func process_step():
	# 1. Decay
	for i in range(size):
		grid[i] *= decay_rate
		if grid[i] < 0.001: grid[i] = 0.0
		
	# 2. Diffusion (Simple Box Blur)
	# For Physarum, strong diffusion is key to merging trails
	# Using 4-tap in-place approximation
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			var i = y * width + x
			if grid[i] > 0.001:
				var avg = (grid[i-1] + grid[i+1] + grid[i-width] + grid[i+width]) * 0.25
				grid[i] = lerp(grid[i], avg, diffuse_rate)

# Generate Image for visualization
func get_image() -> Image:
	var data = PackedByteArray()
	data.resize(size * 3) # RGB8
	
	for i in range(size):
		var val = grid[i]
		if val > 0.01:
			var idx = i * 3
			var c = min(int(val * 255.0), 255)
			# Green/Yellow Slime Color (High G, Mid R)
			data[idx] = int(c * 0.8)   # R
			data[idx+1] = c          # G
			data[idx+2] = int(c * 0.2) # B
			
	return Image.create_from_data(width, height, false, Image.FORMAT_RGB8, data)
