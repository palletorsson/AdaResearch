extends Control

var visualization_type = "intro"
var animation_time = 0.0
var animation_speed = 2.0
var animation_playing = true

# Data for visualizations
var rand_values = []
var walker_positions = []
var perlin_values = []

# Visual styling constants
const CELL_SIZE := Vector2(40, 40)
const CELL_MARGIN := Vector2(5, 5)
const GRID_OFFSET := Vector2(50, 50)
const COLOR_PRIMARY := Color(0.2, 0.6, 0.8, 0.8)
const COLOR_SECONDARY := Color(0.8, 0.4, 0.2, 0.8)
const COLOR_HIGHLIGHT := Color(1.0, 0.9, 0.2, 0.8)
const BG_COLOR := Color(0.15, 0.15, 0.2)

# Constants for visualizations
const GRAPH_WIDTH = 400
const GRAPH_HEIGHT = 200
const HISTOGRAM_BARS = 10
const PERLIN_RESOLUTION = 100
const WALKER_STEPS = 1000
const PARTICLE_COUNT = 200

# Derived visualization parameters
var histogram_bar_width = GRAPH_WIDTH / HISTOGRAM_BARS
var rng = RandomNumberGenerator.new()
var particles = []
var perlin_mesh = []

func _ready():
	rng.randomize()
	_initialize_particles()
	_initialize_perlin_mesh()

func _initialize_particles():
	particles = []
	for i in range(PARTICLE_COUNT):
		particles.append({
			"position": Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y)),
			"velocity": Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 50,
			"size": rng.randf_range(2, 6),
			"color": Color(rng.randf(), rng.randf(), rng.randf(), 0.7)
		})

func _initialize_perlin_mesh():
	perlin_mesh = []
	var noise = FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05
	
	for y in range(20):
		for x in range(20):
			perlin_mesh.append({
				"position": Vector2(x, y) * 20,
				"value": noise.get_noise_2d(x, y)
			})

func _process(delta):
	if animation_playing:
		animation_time += delta * animation_speed
		
		# Update particles for intro visualization
		if visualization_type == "intro":
			for particle in particles:
				particle.position += particle.velocity * delta
				
				# Bounce off edges
				if particle.position.x < 0 or particle.position.x > size.x:
					particle.velocity.x *= -1
				if particle.position.y < 0 or particle.position.y > size.y:
					particle.velocity.y *= -1
		
		queue_redraw()

func _draw():
	if size.x < 10 or size.y < 10:  # Guard against drawing before properly sized
		return
		
	var center_x = size.x / 2
	var center_y = size.y / 2
	
	# Draw based on the current visualization type
	match visualization_type:
		"intro":
			draw_intro_visualization(center_x, center_y)
		"uniform":
			draw_uniform_visualization(center_x, center_y)
		"gaussian":
			draw_gaussian_visualization(center_x, center_y)
		"random_walk":
			draw_random_walk_visualization(center_x, center_y)
		"perlin":
			draw_perlin_visualization(center_x, center_y)

func draw_intro_visualization(center_x, center_y):
	# Draw background with grid pattern
	draw_rect(Rect2(0, 0, size.x, size.y), BG_COLOR, true)
	
	# Draw subtle grid lines
	var grid_color = Color(1, 1, 1, 0.1)
	var grid_step = 40
	for x in range(0, int(size.x), grid_step):
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color)
	for y in range(0, int(size.y), grid_step):
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color)
	
	# Draw animated particles
	for particle in particles:
		draw_circle(particle.position, particle.size, particle.color)
	
	# Draw dice rolling animation
	var dice_size = 60
	var dice_positions = [
		Vector2(center_x - dice_size * 1.5, center_y - dice_size / 2),
		Vector2(center_x, center_y - dice_size / 2),
		Vector2(center_x + dice_size * 1.5, center_y - dice_size / 2)
	]
	
	for i in range(dice_positions.size()):
		var dice_value = int(fmod(animation_time * (i + 1), 6)) + 1
		draw_dice(dice_positions[i], dice_size, dice_value)
	
	# Draw computer seed visualization
	var seed_rect = Rect2(center_x - 150, center_y + 50, 300, 60)
	draw_rect(seed_rect, Color(0.2, 0.2, 0.3, 0.8), true)
	draw_rect(seed_rect, Color.WHITE, false, 2)
	
	# Binary animation inside the seed
	var seed_time = fmod(animation_time * 2, 10)
	var binary_width = 8
	var binary_height = 20
	var binary_spacing = 4
	var binary_count = int(seed_rect.size.x / (binary_width + binary_spacing))
	
	for i in range(binary_count):
		var binary_value = int(fmod(seed_time + i, 2))
		var binary_color = Color.GREEN if binary_value == 1 else Color(0, 0.5, 0, 0.5)
		var binary_pos = Vector2(
			seed_rect.position.x + i * (binary_width + binary_spacing) + 5,
			seed_rect.position.y + (seed_rect.size.y - binary_height) / 2
		)
		draw_rect(Rect2(binary_pos, Vector2(binary_width, binary_height)), binary_color, true)

func draw_uniform_visualization(center_x, center_y):
	# Draw background
	draw_rect(Rect2(0, 0, size.x, size.y), BG_COLOR, true)
	
	# Draw coordinate system for the histogram
	var graph_x = center_x - GRAPH_WIDTH / 2
	var graph_y = center_y - GRAPH_HEIGHT / 2
	
	# Draw axes
	draw_line(Vector2(graph_x, graph_y + GRAPH_HEIGHT), Vector2(graph_x + GRAPH_WIDTH, graph_y + GRAPH_HEIGHT), Color.WHITE, 2)
	draw_line(Vector2(graph_x, graph_y), Vector2(graph_x, graph_y + GRAPH_HEIGHT), Color.WHITE, 2)
	
	# Draw histogram
	var bins = []
	for i in range(HISTOGRAM_BARS):
		bins.append(0)
	
	# Calculate how many points to show based on animation time
	var points_to_show = min(int(animation_time * 20), rand_values.size())
	
	# Fill bins
	for i in range(points_to_show):
		var bin_index = min(int(rand_values[i] * HISTOGRAM_BARS), HISTOGRAM_BARS - 1)
		bins[bin_index] += 1
	
	# Find max bin value for scaling
	var max_bin = 1
	for bin_value in bins:
		max_bin = max(max_bin, bin_value)
	
	# Draw bins
	for i in range(HISTOGRAM_BARS):
		var bin_height = (float(bins[i]) / max_bin) * GRAPH_HEIGHT
		var bin_x = graph_x + i * histogram_bar_width
		var bin_y = graph_y + GRAPH_HEIGHT - bin_height
		
		draw_rect(Rect2(bin_x, bin_y, histogram_bar_width - 2, bin_height), COLOR_PRIMARY, true)
		draw_rect(Rect2(bin_x, bin_y, histogram_bar_width - 2, bin_height), Color.WHITE, false)
	
	# Draw bar labels
	for i in range(HISTOGRAM_BARS + 1):
		if i % 2 == 0:  # Only show every other label to avoid crowding
			var label_x = graph_x + i * histogram_bar_width
			var label_value = float(i) / HISTOGRAM_BARS
			
			# Draw tick mark
			draw_line(
				Vector2(label_x, graph_y + GRAPH_HEIGHT), 
				Vector2(label_x, graph_y + GRAPH_HEIGHT + 5), 
				Color.WHITE, 2
			)
	
	# Animate random value generation
	var rand_gen_y = graph_y + GRAPH_HEIGHT + 60
	var rand_gen_width = 120
	var rand_gen_height = 60
	var rand_gen_x = center_x - rand_gen_width / 2
	
	# Draw random generator box
	draw_rect(Rect2(rand_gen_x, rand_gen_y, rand_gen_width, rand_gen_height), Color(0.3, 0.3, 0.4, 0.8), true)
	draw_rect(Rect2(rand_gen_x, rand_gen_y, rand_gen_width, rand_gen_height), Color.WHITE, false, 2)
	
	# Animate a random number inside
	var rand_index = int(fmod(animation_time * 10, rand_values.size()))
	var rand_value = rand_values[rand_index]
	var rand_flash = sin(animation_time * 10) * 0.5 + 0.5
	
	# Highlight the corresponding histogram bin
	var bin_index = min(int(rand_value * HISTOGRAM_BARS), HISTOGRAM_BARS - 1)
	var highlight_x = graph_x + bin_index * histogram_bar_width
	var bin_height = (float(bins[bin_index]) / max_bin) * GRAPH_HEIGHT
	var highlight_y = graph_y + GRAPH_HEIGHT - bin_height
	
	# Draw connection line with animated pulse
	var line_start = Vector2(rand_gen_x + rand_gen_width / 2, rand_gen_y)
	var line_end = Vector2(highlight_x + histogram_bar_width / 2, graph_y + GRAPH_HEIGHT)
	draw_line(line_start, line_end, Color(1, 1, 1, 0.3), 1)
	
	# Animate a dot traveling along the line
	var dot_pos = line_start.lerp(line_end, fmod(animation_time, 1.0))
	draw_circle(dot_pos, 5, COLOR_HIGHLIGHT)
	
	# Highlight bin
	draw_rect(Rect2(highlight_x, highlight_y, histogram_bar_width - 2, bin_height), 
			  Color(COLOR_HIGHLIGHT.r, COLOR_HIGHLIGHT.g, COLOR_HIGHLIGHT.b, rand_flash * 0.5 + 0.2), true)

func draw_gaussian_visualization(center_x, center_y):
	# Draw background
	draw_rect(Rect2(0, 0, size.x, size.y), BG_COLOR, true)
	
	# Draw coordinate system for the distribution curves
	var graph_x = center_x - GRAPH_WIDTH / 2
	var graph_y = center_y - GRAPH_HEIGHT / 2
	
	# Draw axes
	draw_line(Vector2(graph_x, graph_y + GRAPH_HEIGHT), Vector2(graph_x + GRAPH_WIDTH, graph_y + GRAPH_HEIGHT), Color.WHITE, 2)
	draw_line(Vector2(graph_x, graph_y), Vector2(graph_x, graph_y + GRAPH_HEIGHT), Color.WHITE, 2)
	
	# Draw uniform distribution curve (flat line)
	var uniform_points = PackedVector2Array()
	for i in range(GRAPH_WIDTH):
		var x = graph_x + i
		var y = graph_y + GRAPH_HEIGHT * 0.7
		uniform_points.append(Vector2(x, y))
	
	draw_polyline(uniform_points, Color(COLOR_PRIMARY.r, COLOR_PRIMARY.g, COLOR_PRIMARY.b, 0.5), 2)
	
	# Draw Gaussian distribution curve (bell curve)
	var gaussian_points = PackedVector2Array()
	for i in range(GRAPH_WIDTH):
		var x_normalized = float(i) / GRAPH_WIDTH
		var x_value = (x_normalized - 0.5) * 6  # Scale to approximately -3 to 3 standard deviations
		var gaussian_value = exp(-(x_value * x_value) / 2) / sqrt(2 * PI)  # Standard normal PDF
		var y = graph_y + GRAPH_HEIGHT - gaussian_value * GRAPH_HEIGHT * 2
		gaussian_points.append(Vector2(graph_x + i, y))
	
	draw_polyline(gaussian_points, COLOR_SECONDARY, 2)
	
	# Label the curves
	draw_string_outlined(Vector2(graph_x + 10, graph_y + GRAPH_HEIGHT * 0.7 - 15), "Uniform", Color.WHITE, Color.BLACK, 1)
	draw_string_outlined(Vector2(graph_x + 10, graph_y + GRAPH_HEIGHT * 0.3 - 15), "Gaussian", COLOR_SECONDARY, Color.BLACK, 1)
	
	# Animate random sampling visualization
	var point_count = int(fmod(animation_time * 10, 100))
	
	# Draw uniform random points
	for i in range(point_count):
		var random_x = rng.randf()
		var point_x = graph_x + random_x * GRAPH_WIDTH
		var point_y = graph_y + GRAPH_HEIGHT + 30 + i * 1.0  # Stack points vertically
		
		draw_circle(Vector2(point_x, point_y), 2, COLOR_PRIMARY)
	
	# Draw Gaussian random points (using Box-Muller transform)
	for i in range(point_count):
		# Box-Muller transform for Gaussian distribution
		var u1 = rng.randf()
		var u2 = rng.randf()
		var z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
		
		# Scale to fit within our graph
		var gaussian_x = 0.5 + z0 * 0.15  # Mean 0.5, adjust stddev to fit visualization
		gaussian_x = clamp(gaussian_x, 0, 1)  # Clamp outliers
		
		var point_x = graph_x + gaussian_x * GRAPH_WIDTH
		var point_y = graph_y - 30 - i * 1.0  # Stack points vertically above the graph
		
		draw_circle(Vector2(point_x, point_y), 2, COLOR_SECONDARY)

func draw_random_walk_visualization(center_x, center_y):
	# Draw background
	draw_rect(Rect2(0, 0, size.x, size.y), BG_COLOR, true)
	
	# Draw grid
	var grid_color = Color(1, 1, 1, 0.1)
	var grid_step = 20
	for x in range(0, int(size.x), grid_step):
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color)
	for y in range(0, int(size.y), grid_step):
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color)
	
	# Calculate how much of the walk to show based on animation time
	var steps_to_show = int(min(animation_time * 50, walker_positions.size() - 1))
	
	# Find the bounds of the path to scale it appropriately
	var min_x = 0
	var max_x = 0
	var min_y = 0
	var max_y = 0
	
	for i in range(steps_to_show + 1):
		min_x = min(min_x, walker_positions[i].x)
		max_x = max(max_x, walker_positions[i].x)
		min_y = min(min_y, walker_positions[i].y)
		max_y = max(max_y, walker_positions[i].y)
	
	# Add padding
	min_x -= 1
	max_x += 1
	min_y -= 1
	max_y += 1
	
	# Calculate scaling factor to fit the visualization
	var width = max_x - min_x
	var height = max_y - min_y
	
	var scale_factor = min(
		(size.x * 0.8) / max(width, 1.0),
		(size.y * 0.8) / max(height, 1.0)
	)
	
	# Draw the random walk
	if steps_to_show > 0:
		var path_points = PackedVector2Array()
		
		for i in range(steps_to_show + 1):
			var walker_pos = walker_positions[i]
			var scaled_x = center_x + (walker_pos.x - (min_x + width/2)) * scale_factor
			var scaled_y = center_y + (walker_pos.y - (min_y + height/2)) * scale_factor
			path_points.append(Vector2(scaled_x, scaled_y))
		
		# Draw path
		draw_polyline(path_points, COLOR_PRIMARY, 2.0)
		
		# Draw start point
		draw_circle(path_points[0], 6, Color(0.2, 0.8, 0.2, 0.8))
		
		# Draw current point
		draw_circle(path_points[path_points.size() - 1], 8, COLOR_HIGHLIGHT)
	
	# Draw different walker types
	var walker_types = [
		{"name": "Equal Probability", "position": Vector2(center_x - 300, center_y - 140)},
		{"name": "Right Bias", "position": Vector2(center_x, center_y - 140)},
		{"name": "Levy Flight", "position": Vector2(center_x + 300, center_y - 140)}
	]
	
	for walker_type in walker_types:
		draw_mini_walker(walker_type.position, walker_type.name, walker_types.find(walker_type))

func draw_mini_walker(position, name, type):
	# Draw title
	draw_string_outlined(Vector2(position.x - 50, position.y - 80), name, Color.WHITE, Color.BLACK, 1)
	
	# Draw mini grid background
	var grid_size = 100
	var grid_rect = Rect2(position.x - grid_size/2, position.y - grid_size/2, grid_size, grid_size)
	draw_rect(grid_rect, Color(0.2, 0.2, 0.3, 0.4), true)
	draw_rect(grid_rect, Color.WHITE, false)
	
	# Draw mini grid lines
	var mini_grid_step = 20
	var grid_color = Color(1, 1, 1, 0.2)
	
	for x in range(int(grid_rect.position.x), int(grid_rect.position.x + grid_rect.size.x) + 1, mini_grid_step):
		draw_line(Vector2(x, grid_rect.position.y), Vector2(x, grid_rect.position.y + grid_rect.size.y), grid_color)
	
	for y in range(int(grid_rect.position.y), int(grid_rect.position.y + grid_rect.size.y) + 1, mini_grid_step):
		draw_line(Vector2(grid_rect.position.x, y), Vector2(grid_rect.position.x + grid_rect.size.x, y), grid_color)
	
	# Simulate a simple random walk for this mini visualization
	var mini_walk = PackedVector2Array()
	mini_walk.append(Vector2(position.x, position.y))
	
	var step_time = fmod(animation_time * 2, 10)
	var steps = int(step_time * 5)
	
	for i in range(steps):
		var prev_pos = mini_walk[mini_walk.size() - 1]
		var new_pos = prev_pos
		
		match type:
			0:  # Equal probability
				var dir = rng.randi_range(0, 3)
				match dir:
					0: new_pos.x += 5
					1: new_pos.x -= 5
					2: new_pos.y += 5
					3: new_pos.y -= 5
			
			1:  # Right bias
				var dir = rng.randi_range(0, 100)
				if dir < 60:  # 60% chance to go right
					new_pos.x += 5
				elif dir < 80:  # 20% chance to go left
					new_pos.x -= 5
				elif dir < 90:  # 10% chance to go up
					new_pos.y -= 5
				else:  # 10% chance to go down
					new_pos.y += 5
			
			2:  # Levy flight (occasional big jumps)
				var is_big_jump = rng.randf() < 0.2  # 20% chance for a big jump
				var dir = rng.randi_range(0, 3)
				var step_size = 5
				
				if is_big_jump:
					step_size = rng.randi_range(10, 20)
				
				match dir:
					0: new_pos.x += step_size
					1: new_pos.x -= step_size
					2: new_pos.y += step_size
					3: new_pos.y -= step_size
		
		# Keep within bounds
		new_pos.x = clamp(new_pos.x, grid_rect.position.x + 5, grid_rect.position.x + grid_rect.size.x - 5)
		new_pos.y = clamp(new_pos.y, grid_rect.position.y + 5, grid_rect.position.y + grid_rect.size.y - 5)
		
		mini_walk.append(new_pos)
	
	# Draw the mini walk
	if mini_walk.size() > 1:
		draw_polyline(mini_walk, COLOR_PRIMARY, 2.0)
		draw_circle(mini_walk[0], 4, Color(0.2, 0.8, 0.2, 0.8))
		draw_circle(mini_walk[mini_walk.size() - 1], 6, COLOR_HIGHLIGHT)

func draw_perlin_visualization(center_x, center_y):
	# Draw background
	draw_rect(Rect2(0, 0, size.x, size.y), BG_COLOR, true)
	
	# Draw 1D Perlin Noise graph
	var graph_x = center_x - GRAPH_WIDTH / 2
	var graph_y = center_y - 120
	
	# Draw axes
	draw_line(Vector2(graph_x, graph_y), Vector2(graph_x + GRAPH_WIDTH, graph_y), Color.WHITE, 2)
	draw_line(Vector2(graph_x, graph_y - GRAPH_HEIGHT/2), Vector2(graph_x, graph_y + GRAPH_HEIGHT/2), Color.WHITE, 2)
	
	# Draw 1D noise curve
	var noise_points = PackedVector2Array()
	var segment_width = float(GRAPH_WIDTH) / perlin_values.size()
	
	for i in range(perlin_values.size()):
		var x = graph_x + i * segment_width
		var y = graph_y - perlin_values[i] * GRAPH_HEIGHT / 2
		noise_points.append(Vector2(x, y))
	
	draw_polyline(noise_points, COLOR_PRIMARY, 2.0)
	
	# Draw moving point along the curve
	var time_position = fmod(animation_time, 1.0) * perlin_values.size()
	var point_index = int(time_position)
	var interp = time_position - point_index
	
	if point_index < perlin_values.size() - 1:
		var current_pos = noise_points[point_index]
		var next_pos = noise_points[point_index + 1]
		var interp_pos = current_pos.lerp(next_pos, interp)
		
		draw_circle(interp_pos, 6, COLOR_HIGHLIGHT)
	
	# Draw 2D Perlin Noise visualization
	draw_2d_perlin(center_x, center_y + 80)
	
	# Draw comparison with other random types
	var labels = [
		{"text": "Random Noise", "position": Vector2(center_x - 250, center_y - 200)},
		{"text": "Perlin Noise", "position": Vector2(center_x + 50, center_y - 200)}
	]
	
	for label in labels:
		draw_string_outlined(label.position, label.text, Color.WHITE, Color.BLACK, 1)
	
	# Draw random noise sample
	var random_sample_rect = Rect2(center_x - 350, center_y - 180, 200, 100)
	draw_rect(random_sample_rect, Color(0.2, 0.2, 0.3, 0.8), true)
	draw_rect(random_sample_rect, Color.WHITE, false)
	
	# Draw random noise pixels
	var cell_size = 10
	for y in range(10):
		for x in range(20):
			var noise_value = rng.randf()
			var color = Color(noise_value, noise_value, noise_value)
			var pos = Vector2(
				random_sample_rect.position.x + x * cell_size,
				random_sample_rect.position.y + y * cell_size
			)
			draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), color, true)
	
	# Draw Perlin noise sample
	var perlin_sample_rect = Rect2(center_x - 50, center_y - 180, 200, 100)
	draw_rect(perlin_sample_rect, Color(0.2, 0.2, 0.3, 0.8), true)
	draw_rect(perlin_sample_rect, Color.WHITE, false)
	
	# Draw Perlin noise pixels
	var noise = FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.1
	
	for y in range(10):
		for x in range(20):
			var noise_value = (noise.get_noise_2d(x, y) + 1) / 2  # Convert from [-1,1] to [0,1]
			var color = Color(noise_value, noise_value, noise_value)
			var pos = Vector2(
				perlin_sample_rect.position.x + x * cell_size,
				perlin_sample_rect.position.y + y * cell_size
			)
			draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), color, true)

func draw_2d_perlin(center_x, center_y):
	# Draw 2D Perlin noise as a height map
	var map_size = 200
	var cell_size = 10
	var grid_size = map_size / cell_size
	
	var map_rect = Rect2(center_x - map_size/2, center_y - map_size/2, map_size, map_size)
	draw_rect(map_rect, Color(0.2, 0.2, 0.3, 0.8), true)
	draw_rect(map_rect, Color.WHITE, false)
	
	# Generate noise with time variation for animation
	var noise = FastNoiseLite.new()
	noise.seed = 12345  # Fixed seed for consistent visualization
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.03
	
	for y in range(grid_size):
		for x in range(grid_size):
			# Add time to z coordinate for animation
			var noise_value = (noise.get_noise_3d(x, y, animation_time * 0.5) + 1) / 2
			
			# Create color gradient from deep blue to white
			var color = Color.BLUE.lerp(Color.WHITE, noise_value)
			
			var pos = Vector2(
				map_rect.position.x + x * cell_size,
				map_rect.position.y + y * cell_size
			)
			draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), color, true)

func draw_dice(position, size, value):
	# Draw dice background
	draw_rect(Rect2(position, Vector2(size, size)), Color(0.9, 0.9, 0.9), true)
	draw_rect(Rect2(position, Vector2(size, size)), Color.BLACK, false, 2)
	
	# Draw pips based on dice value
	var pip_radius = size * 0.1
	var pip_color = Color.BLACK
	
	# Center of the dice
	var center = position + Vector2(size/2, size/2)
	
	# Corner offset for pips
	var offset = size * 0.25
	
	match value:
		1:
			# Center pip
			draw_circle(center, pip_radius, pip_color)
		2:
			# Top-left and bottom-right pips
			draw_circle(position + Vector2(offset, offset), pip_radius, pip_color)
			draw_circle(position + Vector2(size - offset, size - offset), pip_radius, pip_color)
		3:
			# 2 + center pip
			draw_circle(position + Vector2(offset, offset), pip_radius, pip_color)
			draw_circle(center, pip_radius, pip_color)
			draw_circle(position + Vector2(size - offset, size - offset), pip_radius, pip_color)
		4:
			# All four corners
			draw_circle(position + Vector2(offset, offset), pip_radius, pip_color)
			draw_circle(position + Vector2(size - offset, offset), pip_radius, pip_color)
			draw_circle(position + Vector2(offset, size - offset), pip_radius, pip_color)
			draw_circle(position + Vector2(size - offset, size - offset), pip_radius, pip_color)
		6:
			# Left and right sides, 3 pips each
			draw_circle(position + Vector2(offset, offset), pip_radius, pip_color)
			draw_circle(position + Vector2(offset, size/2), pip_radius, pip_color)
			draw_circle(position + Vector2(offset, size - offset), pip_radius, pip_color)
			draw_circle(position + Vector2(size - offset, offset), pip_radius, pip_color)
			draw_circle(position + Vector2(size - offset, size/2), pip_radius, pip_color)
			draw_circle(position + Vector2(size - offset, size - offset), pip_radius, pip_color)

func draw_string_outlined(position, text, text_color, outline_color, outline_size):
	# Draw outline
	for x_offset in range(-outline_size, outline_size + 1):
		for y_offset in range(-outline_size, outline_size + 1):
			if x_offset != 0 or y_offset != 0:
				draw_string(
					ThemeDB.fallback_font,
					Vector2(position.x + x_offset, position.y + y_offset),
					text,
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					14,
					outline_color
				)
	
	# Draw main text
	draw_string(
		ThemeDB.fallback_font,
		position,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		text_color
	)
