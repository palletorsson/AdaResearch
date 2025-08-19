extends Node2D

# Mirrored Cellular Automata Texture Generator
# Creates symmetrical patterns that evolve according to cellular automata rules

@export_category("Grid Settings")
@export var grid_size: int = 21  # Use odd number for center symmetry
@export var cell_size: int = 20   # Pixel size of each cell
@export var update_interval: float = 0.2  # Time between updates
@export var auto_evolve: bool = true  # Whether to evolve automatically

@export_category("Pattern Settings")
@export_enum("Quad Mirror", "Eight-Way Mirror", "Rotational") var symmetry_type: int = 0
@export_range(0.0, 1.0) var random_fill_percent: float = 0.3
@export_range(0.0, 1.0) var birth_probability: float = 0.2
@export_range(0.0, 1.0) var death_probability: float = 0.1
@export var fixed_border: bool = true

# Internal variables
var grid = []
var half_size: int
var update_timer: float = 0.0
var render_texture: ImageTexture

func _ready():
	randomize()
	half_size = grid_size / 2
	
	# Create the TextureRect node if it doesn't exist
	if not has_node("TextureRect"):
		var texture_rect = TextureRect.new()
		texture_rect.name = "TextureRect"
		texture_rect.expand = true
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(texture_rect)
	
	# Initialize UI elements
	if has_node("UI"):
		var toggle_button = $UI/VBoxContainer/ToggleEvolutionButton
		if toggle_button:
			toggle_button.text = "Stop Evolution" if auto_evolve else "Start Evolution"
	
	initialize_grid()
	generate_initial_pattern()
	create_render_texture()

func _process(delta):
	if auto_evolve:
		update_timer += delta
		if update_timer >= update_interval:
			update_timer = 0
			update_grid()
			update_render_texture()

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_SPACE:
					update_grid()
					update_render_texture()
				KEY_R:
					initialize_grid()
					generate_initial_pattern()
					update_render_texture()
				KEY_S:
					save_texture()

func initialize_grid():
	grid = []
	for y in range(grid_size):
		var row = []
		for x in range(grid_size):
			row.append(0)  # Initialize all cells as dead
		grid.append(row)

func generate_initial_pattern():
	# Only generate the core pattern, then apply symmetry
	match symmetry_type:
		0:  # Quad mirror (four quadrants)
			generate_quadrant_pattern()
		1:  # Eight-way mirror
			generate_octant_pattern()
		2:  # Rotational symmetry
			generate_rotational_pattern()

func generate_quadrant_pattern():
	# Only generate the top-left quadrant
	for y in range(half_size):
		for x in range(half_size):
			if randf() <= random_fill_percent:
				set_cell_with_symmetry(x, y, 1)

func generate_octant_pattern():
	# Only generate 1/8 of the pattern (top-left triangle)
	for y in range(half_size):
		for x in range(y + 1):  # Only fill cells where x <= y to create a triangle
			if randf() <= random_fill_percent:
				set_cell_with_symmetry(x, y, 1)

func generate_rotational_pattern():
	# Generate a pattern with rotational symmetry
	# Start with a random core
	var pattern_size = min(5, half_size)  # Size of the pattern to repeat
	
	# Generate a small random pattern
	var pattern = []
	for y in range(pattern_size):
		var row = []
		for x in range(pattern_size):
			row.append(1 if randf() <= random_fill_percent else 0)
		pattern.append(row)
	
	# Apply the pattern with rotational symmetry
	for y in range(grid_size):
		for x in range(grid_size):
			# Map to pattern coordinates (mod pattern_size)
			var pattern_x = abs(x - half_size) % pattern_size
			var pattern_y = abs(y - half_size) % pattern_size
			grid[y][x] = pattern[pattern_y][pattern_x]

func set_cell_with_symmetry(x, y, value):
	match symmetry_type:
		0:  # Quad mirror
			# Set in all four quadrants
			grid[y][x] = value
			grid[y][grid_size - 1 - x] = value
			grid[grid_size - 1 - y][x] = value
			grid[grid_size - 1 - y][grid_size - 1 - x] = value
		1:  # Eight-way mirror
			# Set in all eight octants
			grid[y][x] = value
			grid[y][grid_size - 1 - x] = value
			grid[grid_size - 1 - y][x] = value
			grid[grid_size - 1 - y][grid_size - 1 - x] = value
			grid[x][y] = value
			grid[x][grid_size - 1 - y] = value
			grid[grid_size - 1 - x][y] = value
			grid[grid_size - 1 - x][grid_size - 1 - y] = value
		2:  # Rotational
			# Calculate distance and angle from center
			var center_x = half_size
			var center_y = half_size
			var dx = x - center_x
			var dy = y - center_y
			var distance = sqrt(dx*dx + dy*dy)
			var angle = atan2(dy, dx)
			
			# Set in a circular pattern
			for rot in range(4):  # 4-fold rotation
				var new_angle = angle + rot * PI/2
				var new_x = center_x + int(cos(new_angle) * distance)
				var new_y = center_y + int(sin(new_angle) * distance)
				
				# Make sure coordinates are within bounds
				if new_x >= 0 and new_x < grid_size and new_y >= 0 and new_y < grid_size:
					grid[new_y][new_x] = value

func update_grid():
	# Create a copy of the current grid
	var new_grid = []
	for y in range(grid_size):
		var row = []
		for x in range(grid_size):
			row.append(grid[y][x])
		new_grid.append(row)
	
	# Update each cell based on its neighbors
	for y in range(grid_size):
		for x in range(grid_size):
			# Skip border cells if fixed_border is true
			if fixed_border and (x == 0 or y == 0 or x == grid_size - 1 or y == grid_size - 1):
				continue
				
			var live_neighbors = count_live_neighbors(x, y)
			
			if grid[y][x] == 1:  # Cell is alive
				# Die if too few or too many neighbors
				if live_neighbors < 2 or live_neighbors > 3:
					if randf() <= death_probability:
						new_grid[y][x] = 0
			else:  # Cell is dead
				# Become alive if exactly 3 neighbors are alive
				if live_neighbors == 3:
					if randf() <= birth_probability:
						new_grid[y][x] = 1
	
	# Apply symmetry to the new grid
	if symmetry_type == 0:  # Quad mirror
		apply_quad_symmetry(new_grid)
	elif symmetry_type == 1:  # Eight-way mirror
		apply_eight_way_symmetry(new_grid)
	elif symmetry_type == 2:  # Rotational
		apply_rotational_symmetry(new_grid)
	
	# Update the main grid
	grid = new_grid

func count_live_neighbors(x, y):
	var count = 0
	for ny in range(max(0, y - 1), min(grid_size, y + 2)):
		for nx in range(max(0, x - 1), min(grid_size, x + 2)):
			if nx == x and ny == y:
				continue  # Skip the cell itself
			if grid[ny][nx] == 1:
				count += 1
	return count

func apply_quad_symmetry(new_grid):
	# Apply symmetry to the top-left quadrant only
	for y in range(half_size):
		for x in range(half_size):
			var value = new_grid[y][x]
			new_grid[y][grid_size - 1 - x] = value
			new_grid[grid_size - 1 - y][x] = value
			new_grid[grid_size - 1 - y][grid_size - 1 - x] = value

func apply_eight_way_symmetry(new_grid):
	# Apply symmetry to the top-left octant only
	for y in range(half_size):
		for x in range(y + 1):  # Only process triangle where x <= y
			var value = new_grid[y][x]
			new_grid[y][grid_size - 1 - x] = value
			new_grid[grid_size - 1 - y][x] = value
			new_grid[grid_size - 1 - y][grid_size - 1 - x] = value
			new_grid[x][y] = value
			new_grid[x][grid_size - 1 - y] = value
			new_grid[grid_size - 1 - x][y] = value
			new_grid[grid_size - 1 - x][grid_size - 1 - y] = value

func apply_rotational_symmetry(new_grid):
	# Apply 4-fold rotational symmetry
	var center_x = half_size
	var center_y = half_size
	
	for y in range(center_y + 1):
		for x in range(center_x + 1):
			# Skip the center cell
			if x == center_x and y == center_y:
				continue
				
			var dx = x - center_x
			var dy = y - center_y
			var distance = sqrt(dx*dx + dy*dy)
			var angle = atan2(dy, dx)
			
			var value = new_grid[y][x]
			
			# Apply to all four quadrants
			for rot in range(1, 4):  # Skip the first rotation (already set)
				var new_angle = angle + rot * PI/2
				var new_x = center_x + int(cos(new_angle) * distance)
				var new_y = center_y + int(sin(new_angle) * distance)
				
				# Make sure coordinates are within bounds
				if new_x >= 0 and new_x < grid_size and new_y >= 0 and new_y < grid_size:
					new_grid[new_y][new_x] = value

func create_render_texture():
	var img = Image.create(grid_size * cell_size, grid_size * cell_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))  # White background
	
	render_texture = ImageTexture.create_from_image(img)
	update_render_texture()

func update_render_texture():
	var img = Image.create(grid_size * cell_size, grid_size * cell_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))  # White background
	
	# Draw the grid
	for y in range(grid_size):
		for x in range(grid_size):
			if grid[y][x] == 1:
				# Draw a filled cell
				for py in range(cell_size):
					for px in range(cell_size):
						img.set_pixel(x * cell_size + px, y * cell_size + py, Color(0, 0, 0, 1))
	
	# Draw grid lines
	for y in range(grid_size + 1):
		for x in range(grid_size * cell_size):
			img.set_pixel(x, y * cell_size, Color(0.7, 0.7, 0.7, 1))
	
	for x in range(grid_size + 1):
		for y in range(grid_size * cell_size):
			img.set_pixel(x * cell_size, y, Color(0.7, 0.7, 0.7, 1))
	
	# Update the texture
	render_texture = ImageTexture.create_from_image(img)
	
	# Make sure TextureRect exists before assigning the texture
	if has_node("TextureRect"):
		$TextureRect.texture = render_texture
		
		# Update size of TextureRect to match the texture
		$TextureRect.size = Vector2(grid_size * cell_size, grid_size * cell_size)
	
	queue_redraw()  # Request a redraw to update the display

func save_texture():
	var img = render_texture.get_image()
	var datetime = Time.get_datetime_dict_from_system()
	var filename = "res://cellular_pattern_%s.png" % [datetime.hour * 10000 + datetime.minute * 100 + datetime.second]
	img.save_png(filename)
	print("Saved texture to: " + filename)

func _draw():
	if render_texture:
		draw_texture(render_texture, Vector2.ZERO)

func _on_random_button_pressed():
	initialize_grid()
	generate_initial_pattern()
	update_render_texture()

func _on_step_button_pressed():
	update_grid()
	update_render_texture()

func _on_toggle_evolution_button_pressed():
	auto_evolve = !auto_evolve
	$UI/VBoxContainer/ToggleEvolutionButton.text = "Stop Evolution" if auto_evolve else "Start Evolution"

func _on_save_button_pressed():
	save_texture()

func _on_symmetry_option_item_selected(index):
	symmetry_type = index
	initialize_grid()
	generate_initial_pattern()
	update_render_texture()

func _on_fill_percent_slider_value_changed(value):
	random_fill_percent = value / 100.0
	$UI/SymmetryOptionsContainer/FillPercentLabel.text = "Fill Percent: %d%%" % value
	initialize_grid()
	generate_initial_pattern()
	update_render_texture()

func _on_birth_prob_slider_value_changed(value):
	birth_probability = value
	$UI/SymmetryOptionsContainer/BirthProbLabel.text = "Birth Probability: %d%%" % (value * 100)

func _on_death_prob_slider_value_changed(value):
	death_probability = value
	$UI/SymmetryOptionsContainer/DeathProbLabel.text = "Death Probability: %d%%" % (value * 100)
