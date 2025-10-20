extends Node2D

# Simulation parameters - Reduced for VR performance
var width = 128
var height = 128
var grid_a = []  # Chemical A concentration
var grid_b = []  # Chemical B concentration
var next_a = []  # Next step for A
var next_b = []  # Next step for B

# Reaction-diffusion parameters
var diffusion_a = 1.0  # Diffusion rate of A
var diffusion_b = 0.5  # Diffusion rate of B
var feed_rate = 0.055  # Rate at which A is fed into the system
var kill_rate = 0.062  # Rate at which B is removed from the system
var reaction_rate = 1.0  # Rate of the reaction
var time_scale = 1.0  # Overall speed of the simulation

# Rendering
var image = Image.new()
var texture = ImageTexture.new()
var sprite = Sprite2D.new()
var frame_counter = 0

# Parameters UI
var parameter_panel
var diffusion_a_slider
var diffusion_b_slider
var feed_rate_slider
var kill_rate_slider
var reaction_rate_slider
var time_scale_slider
var preset_button
var random_button
var clear_button

# Current preset
var current_preset = 0
var presets = [
	{"name": "Coral", "dA": 1.0, "dB": 0.5, "f": 0.055, "k": 0.062},
	{"name": "Mitosis", "dA": 1.0, "dB": 0.5, "f": 0.0367, "k": 0.0649},
	{"name": "Fingers", "dA": 1.0, "dB": 0.5, "f": 0.037, "k": 0.06},
	{"name": "Spots", "dA": 1.0, "dB": 0.5, "f": 0.025, "k": 0.05},
	{"name": "Waves", "dA": 1.0, "dB": 0.5, "f": 0.018, "k": 0.051},
	{"name": "Maze", "dA": 1.0, "dB": 0.5, "f": 0.029, "k": 0.057}
]

func _ready():
	randomize()
	
	# Initialize grid arrays
	_initialize_grids()
	
	# Create initial image
	image.create(width, height, false, Image.FORMAT_RGB8)
	
	# Create and configure sprite
	add_child(sprite)
	sprite.centered = false
	sprite.position = Vector2(50, 50)
	
	# Set up UI
	_setup_ui()
	
	# Add some initial seed pattern
	_add_random_seeds()
	
	# Update texture
	_update_texture()

func _setup_ui():
	# Create panel for controls
	parameter_panel = Panel.new()
	parameter_panel.position = Vector2(width + 70, 50)
	parameter_panel.size = Vector2(250, 400)
	add_child(parameter_panel)
	
	# Create label
	var label = Label.new()
	label.text = "Reaction-Diffusion Parameters"
	label.position = Vector2(10, 10)
	label.size = Vector2(230, 30)
	parameter_panel.add_child(label)
	
	# Create diffusion A slider
	var label_a = Label.new()
	label_a.text = "Diffusion A: " + str(diffusion_a)
	label_a.position = Vector2(10, 50)
	parameter_panel.add_child(label_a)
	
	diffusion_a_slider = HSlider.new()
	diffusion_a_slider.position = Vector2(10, 70)
	diffusion_a_slider.size = Vector2(230, 20)
	diffusion_a_slider.min_value = 0.1
	diffusion_a_slider.max_value = 2.0
	diffusion_a_slider.step = 0.1
	diffusion_a_slider.value = diffusion_a
	parameter_panel.add_child(diffusion_a_slider)
	diffusion_a_slider.value_changed.connect(func(value): 
		diffusion_a = value
		label_a.text = "Diffusion A: " + str(snapped(diffusion_a, 0.1)))
	
	# Create diffusion B slider
	var label_b = Label.new()
	label_b.text = "Diffusion B: " + str(diffusion_b)
	label_b.position = Vector2(10, 100)
	parameter_panel.add_child(label_b)
	
	diffusion_b_slider = HSlider.new()
	diffusion_b_slider.position = Vector2(10, 120)
	diffusion_b_slider.size = Vector2(230, 20)
	diffusion_b_slider.min_value = 0.1
	diffusion_b_slider.max_value = 2.0
	diffusion_b_slider.step = 0.1
	diffusion_b_slider.value = diffusion_b
	parameter_panel.add_child(diffusion_b_slider)
	diffusion_b_slider.value_changed.connect(func(value): 
		diffusion_b = value
		label_b.text = "Diffusion B: " + str(snapped(diffusion_b, 0.1)))
	
	# Create feed rate slider
	var label_f = Label.new()
	label_f.text = "Feed Rate: " + str(feed_rate)
	label_f.position = Vector2(10, 150)
	parameter_panel.add_child(label_f)
	
	feed_rate_slider = HSlider.new()
	feed_rate_slider.position = Vector2(10, 170)
	feed_rate_slider.size = Vector2(230, 20)
	feed_rate_slider.min_value = 0.01
	feed_rate_slider.max_value = 0.1
	feed_rate_slider.step = 0.001
	feed_rate_slider.value = feed_rate
	parameter_panel.add_child(feed_rate_slider)
	feed_rate_slider.value_changed.connect(func(value): 
		feed_rate = value
		label_f.text = "Feed Rate: " + str(snapped(feed_rate, 0.001)))
	
	# Create kill rate slider
	var label_k = Label.new()
	label_k.text = "Kill Rate: " + str(kill_rate)
	label_k.position = Vector2(10, 200)
	parameter_panel.add_child(label_k)
	
	kill_rate_slider = HSlider.new()
	kill_rate_slider.position = Vector2(10, 220)
	kill_rate_slider.size = Vector2(230, 20)
	kill_rate_slider.min_value = 0.01
	kill_rate_slider.max_value = 0.1
	kill_rate_slider.step = 0.001
	kill_rate_slider.value = kill_rate
	parameter_panel.add_child(kill_rate_slider)
	kill_rate_slider.value_changed.connect(func(value): 
		kill_rate = value
		label_k.text = "Kill Rate: " + str(snapped(kill_rate, 0.001)))
	
	# Create reaction rate slider
	var label_r = Label.new()
	label_r.text = "Reaction Rate: " + str(reaction_rate)
	label_r.position = Vector2(10, 250)
	parameter_panel.add_child(label_r)
	
	reaction_rate_slider = HSlider.new()
	reaction_rate_slider.position = Vector2(10, 270)
	reaction_rate_slider.size = Vector2(230, 20)
	reaction_rate_slider.min_value = 0.1
	reaction_rate_slider.max_value = 2.0
	reaction_rate_slider.step = 0.1
	reaction_rate_slider.value = reaction_rate
	parameter_panel.add_child(reaction_rate_slider)
	reaction_rate_slider.value_changed.connect(func(value): 
		reaction_rate = value
		label_r.text = "Reaction Rate: " + str(snapped(reaction_rate, 0.1)))
	
	# Create time scale slider
	var label_t = Label.new()
	label_t.text = "Time Scale: " + str(time_scale)
	label_t.position = Vector2(10, 300)
	parameter_panel.add_child(label_t)
	
	time_scale_slider = HSlider.new()
	time_scale_slider.position = Vector2(10, 320)
	time_scale_slider.size = Vector2(230, 20)
	time_scale_slider.min_value = 0.1
	time_scale_slider.max_value = 3.0
	time_scale_slider.step = 0.1
	time_scale_slider.value = time_scale
	parameter_panel.add_child(time_scale_slider)
	time_scale_slider.value_changed.connect(func(value): 
		time_scale = value
		label_t.text = "Time Scale: " + str(snapped(time_scale, 0.1)))
	
	# Create preset button
	preset_button = Button.new()
	preset_button.text = "Next Preset: " + presets[current_preset].name
	preset_button.position = Vector2(10, 350)
	preset_button.size = Vector2(110, 30)
	parameter_panel.add_child(preset_button)
	preset_button.pressed.connect(_load_next_preset)
	
	# Create random button
	random_button = Button.new()
	random_button.text = "Randomize"
	random_button.position = Vector2(130, 350)
	random_button.size = Vector2(110, 30)
	parameter_panel.add_child(random_button)
	random_button.pressed.connect(_add_random_seeds)
	
	# Create clear button
	clear_button = Button.new()
	clear_button.text = "Clear"
	clear_button.position = Vector2(10, 390)
	clear_button.size = Vector2(230, 30)
	parameter_panel.add_child(clear_button)
	clear_button.pressed.connect(_clear_simulation)

func _initialize_grids():
	grid_a = []
	grid_b = []
	next_a = []
	next_b = []
	
	for y in range(height):
		var row_a = []
		var row_b = []
		var next_row_a = []
		var next_row_b = []
		
		for x in range(width):
			row_a.append(1.0)  # Fill with chemical A
			row_b.append(0.0)  # No chemical B
			next_row_a.append(0.0)
			next_row_b.append(0.0)
		
		grid_a.append(row_a)
		grid_b.append(row_b)
		next_a.append(next_row_a)
		next_b.append(next_row_b)

func _add_random_seeds():
	# Add some random seeds of chemical B
	for i in range(5):
		var x = randi() % width
		var y = randi() % height
		var size = randi() % 10 + 5
		
		for dx in range(-size, size):
			for dy in range(-size, size):
				var pos_x = (x + dx) % width
				var pos_y = (y + dy) % height
				
				if dx*dx + dy*dy < size*size:
					grid_b[pos_y][pos_x] = 1.0
					grid_a[pos_y][pos_x] = 0.0

func _clear_simulation():
	_initialize_grids()
	_update_texture()

func _load_next_preset():
	current_preset = (current_preset + 1) % presets.size()
	var preset = presets[current_preset]
	
	# Update parameters
	diffusion_a = preset.dA
	diffusion_b = preset.dB
	feed_rate = preset.f
	kill_rate = preset.k
	
	# Update sliders
	diffusion_a_slider.value = diffusion_a
	diffusion_b_slider.value = diffusion_b
	feed_rate_slider.value = feed_rate
	kill_rate_slider.value = kill_rate
	
	# Update button text
	preset_button.text = "Next Preset: " + preset.name
	
	# Add new seeds
	_add_random_seeds()

func _process(delta):
	# Reduced sampling for VR performance - only update every few frames
	var steps = int(time_scale * 3 * delta)  # Reduced from 10 to 3
	for i in range(max(1, steps)):
		_simulate_step(delta)
	
	# Update the texture less frequently for VR performance
	frame_counter += 1
	if frame_counter % 3 == 0:  # Update every 3rd frame
		_update_texture()

func _update_texture():
	# Check if image is properly initialized
	if image.get_width() == 0 or image.get_height() == 0:
		print("Image not initialized, recreating...")
		image.create(width, height, false, Image.FORMAT_RGB8)
		return
	
	# Update the image based on current concentrations
	for y in range(height):
		for x in range(width):
			# Bounds checking to prevent errors
			if x >= 0 and x < width and y >= 0 and y < height and x < image.get_width() and y < image.get_height():
				var a = grid_a[y][x]
				var b = grid_b[y][x]
				
				# Map the concentrations to a color
				var color = Color(a, a, a) - Color(0, b, b)
				
				# Ensure color values are in valid range
				color.r = clamp(color.r, 0.0, 1.0)
				color.g = clamp(color.g, 0.0, 1.0)
				color.b = clamp(color.b, 0.0, 1.0)
				
				image.set_pixel(x, y, color)
	
	# Create texture from the image
	texture = ImageTexture.create_from_image(image)
	sprite.texture = texture

func _simulate_step(delta):
	# Apply the reaction-diffusion equations
	for y in range(height):
		for x in range(width):
			# Calculate the Laplacian (approximation of the diffusion term)
			var laplacian_a = _calculate_laplacian(grid_a, x, y)
			var laplacian_b = _calculate_laplacian(grid_b, x, y)
			
			# Current values
			var a = grid_a[y][x]
			var b = grid_b[y][x]
			
			# Reaction-diffusion formula (Gray-Scott model)
			var reaction = a * b * b * reaction_rate
			
			# Update values
			next_a[y][x] = a + (diffusion_a * laplacian_a - reaction + feed_rate * (1.0 - a)) * delta
			next_b[y][x] = b + (diffusion_b * laplacian_b + reaction - (kill_rate + feed_rate) * b) * delta
			
			# Ensure values stay in valid range
			next_a[y][x] = clamp(next_a[y][x], 0.0, 1.0)
			next_b[y][x] = clamp(next_b[y][x], 0.0, 1.0)
	
	# Swap buffers
	var temp_a = grid_a
	var temp_b = grid_b
	grid_a = next_a
	grid_b = next_b
	next_a = temp_a
	next_b = temp_b

func _calculate_laplacian(grid, x, y):
	# 3x3 convolution for Laplacian (discrete approximation of ∇²)
	var result = 0.0
	
	# Center pixel
	var center = grid[y][x]
	
	# Cardinal directions (von Neumann neighborhood)
	result += grid[(y - 1 + height) % height][x] - center  # North
	result += grid[y][(x + 1) % width] - center  # East
	result += grid[(y + 1) % height][x] - center  # South
	result += grid[y][(x - 1 + width) % width] - center  # West
	
	# Diagonal directions (for a more accurate Laplacian)
	result += 0.05 * (grid[(y - 1 + height) % height][(x - 1 + width) % width] - center)  # Northwest
	result += 0.05 * (grid[(y - 1 + height) % height][(x + 1) % width] - center)  # Northeast
	result += 0.05 * (grid[(y + 1) % height][(x - 1 + width) % width] - center)  # Southwest
	result += 0.05 * (grid[(y + 1) % height][(x + 1) % width] - center)  # Southeast
	
	return result

func _input(event):
	# Allow drawing patterns with mouse
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_add_pattern_at_mouse()
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_add_pattern_at_mouse()

func _add_pattern_at_mouse():
	var mouse_pos = get_global_mouse_position() - sprite.position
	var x = int(mouse_pos.x)
	var y = int(mouse_pos.y)
	
	# Check if within bounds
	if x >= 0 and x < width and y >= 0 and y < height:
		# Add a small pattern at mouse position
		var size = 5
		for dx in range(-size, size):
			for dy in range(-size, size):
				var pos_x = (x + dx) % width
				var pos_y = (y + dy) % height
				
				if dx*dx + dy*dy < size*size:
					grid_b[pos_y][pos_x] = 1.0
					grid_a[pos_y][pos_x] = 0.0
