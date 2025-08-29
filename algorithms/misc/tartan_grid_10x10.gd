extends Control

# 10x10 Tartan Grid Gallery
# Displays different Scottish tartan patterns in a grid layout

const GRID_SIZE = 10
const CELL_PADDING = 8
const CELL_SIZE = 80

# Famous Scottish Tartan Patterns
var tartan_patterns = [
	{
		"name": "Royal Stewart",
		"colors": [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.BLACK],
		"pattern": [0, 1, 0, 2, 0, 3, 0, 4]
	},
	{
		"name": "Black Watch",
		"colors": [Color.BLUE, Color.GREEN, Color.BLACK],
		"pattern": [0, 1, 0, 2, 1, 2]
	},
	{
		"name": "Gordon",
		"colors": [Color.GREEN, Color.BLUE, Color.BLACK, Color.YELLOW],
		"pattern": [0, 1, 0, 2, 0, 3, 1]
	},
	{
		"name": "MacLeod",
		"colors": [Color.YELLOW, Color.BLACK, Color.RED],
		"pattern": [0, 1, 0, 2, 0, 1]
	},
	{
		"name": "Campbell",
		"colors": [Color.GREEN, Color.BLUE, Color.BLACK, Color.WHITE],
		"pattern": [0, 1, 0, 2, 0, 3, 1]
	},
	{
		"name": "MacKenzie",
		"colors": [Color.GREEN, Color.BLUE, Color.RED, Color.BLACK],
		"pattern": [0, 1, 0, 2, 0, 3, 1]
	},
	{
		"name": "Fraser",
		"colors": [Color.RED, Color.GREEN, Color.BLUE, Color.WHITE],
		"pattern": [0, 1, 0, 2, 0, 3]
	},
	{
		"name": "MacDonald",
		"colors": [Color.GREEN, Color.RED, Color.BLACK, Color.BLUE],
		"pattern": [0, 1, 0, 2, 0, 3, 1]
	},
	{
		"name": "Wallace",
		"colors": [Color.YELLOW, Color.RED, Color.BLACK],
		"pattern": [0, 1, 0, 2, 1, 2]
	},
	{
		"name": "Scott",
		"colors": [Color.RED, Color.GREEN, Color.BLACK, Color.WHITE],
		"pattern": [0, 1, 0, 2, 0, 3, 1]
	},
	{
		"name": "MacPherson",
		"colors": [Color.RED, Color.GREEN, Color.BLUE, Color.WHITE, Color.BLACK],
		"pattern": [0, 1, 0, 2, 0, 3, 0, 4]
	},
	{
		"name": "Cameron",
		"colors": [Color.RED, Color.GREEN, Color.YELLOW, Color.BLACK],
		"pattern": [0, 1, 0, 2, 0, 3, 1]
	},
	{
		"name": "Kennedy",
		"colors": [Color.BLACK, Color.WHITE, Color.RED],
		"pattern": [0, 1, 0, 2, 1, 0]
	},
	{
		"name": "Robertson",
		"colors": [Color.RED, Color.BLUE, Color.GREEN, Color.WHITE],
		"pattern": [0, 1, 0, 2, 0, 3]
	},
	{
		"name": "Grant",
		"colors": [Color.RED, Color.GREEN, Color.BLUE, Color.BLACK],
		"pattern": [0, 1, 0, 2, 0, 3]
	},
	{
		"name": "MacKay",
		"colors": [Color.BLUE, Color.GREEN, Color.BLACK, Color.WHITE],
		"pattern": [0, 1, 0, 2, 0, 3]
	},
	{
		"name": "Sinclair",
		"colors": [Color.RED, Color.GREEN, Color.BLACK],
		"pattern": [0, 1, 0, 2, 1, 0]
	},
	{
		"name": "Douglas",
		"colors": [Color.GREEN, Color.BLUE, Color.BLACK, Color.YELLOW],
		"pattern": [0, 1, 0, 2, 0, 3]
	},
	{
		"name": "Stewart",
		"colors": [Color.RED, Color.BLUE, Color.WHITE, Color.BLACK],
		"pattern": [0, 1, 0, 2, 0, 3]
	},
	{
		"name": "Murray",
		"colors": [Color.BLUE, Color.GREEN, Color.RED, Color.BLACK],
		"pattern": [0, 1, 0, 2, 0, 3]
	}
]

# Custom patterns for variation
var custom_patterns = [
	{
		"name": "Pride Tartan",
		"colors": [Color.RED, Color(1, 0.5, 0), Color.YELLOW, Color.GREEN, Color.BLUE, Color(0.5, 0, 1)],
		"pattern": [0, 1, 2, 3, 4, 5]
	},
	{
		"name": "Ocean Waves",
		"colors": [Color(0, 0.3, 0.8), Color(0, 0.6, 1), Color.WHITE, Color(0, 0.8, 0.9)],
		"pattern": [0, 1, 2, 3, 1, 0]
	},
	{
		"name": "Forest Fire",
		"colors": [Color.RED, Color(1, 0.3, 0), Color.YELLOW, Color.GREEN, Color(0, 0.5, 0)],
		"pattern": [0, 1, 2, 3, 4, 3]
	},
	{
		"name": "Sunset Glory",
		"colors": [Color(1, 0.2, 0.4), Color(1, 0.5, 0), Color.YELLOW, Color(1, 0.8, 0.4)],
		"pattern": [0, 1, 2, 3, 2, 1]
	}
]

var all_patterns = []
var grid_container: GridContainer
var pattern_cells = []

func _ready():
	print("🏴󠁧󠁢󠁳󠁣󠁴󠁿 TartanGrid10x10: Initializing tartan pattern gallery...")
	
	# Combine traditional and custom patterns
	all_patterns = tartan_patterns + custom_patterns
	
	# Ensure we have exactly 100 patterns for 10x10 grid
	while all_patterns.size() < 100:
		all_patterns.append(generate_random_tartan())
	
	setup_grid()
	generate_tartan_grid()
	
	print("✅ Generated ", all_patterns.size(), " tartan patterns in 10x10 grid")

func setup_grid():
	# Create grid container
	grid_container = GridContainer.new()
	grid_container.columns = GRID_SIZE
	grid_container.add_theme_constant_override("h_separation", CELL_PADDING)
	grid_container.add_theme_constant_override("v_separation", CELL_PADDING)
	
	# Position grid below header
	grid_container.position = Vector2(CELL_PADDING, 60)
	grid_container.size = Vector2(
		GRID_SIZE * (CELL_SIZE + CELL_PADDING) - CELL_PADDING,
		GRID_SIZE * (CELL_SIZE + CELL_PADDING) - CELL_PADDING
	)
	
	add_child(grid_container)

func generate_tartan_grid():
	for i in range(GRID_SIZE * GRID_SIZE):
		var pattern_index = i % all_patterns.size()
		var pattern = all_patterns[pattern_index]
		
		var cell = create_tartan_cell(pattern, i)
		grid_container.add_child(cell)
		pattern_cells.append(cell)

func create_tartan_cell(pattern: Dictionary, index: int) -> Control:
	var cell = Control.new()
	cell.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	cell.tooltip_text = pattern.name
	
	# Create tartan pattern
	var tartan_rect = ColorRect.new()
	tartan_rect.size = Vector2(CELL_SIZE, CELL_SIZE)
	tartan_rect.material = create_tartan_material(pattern)
	
	cell.add_child(tartan_rect)
	
	# Add label with pattern name
	var label = Label.new()
	label.text = pattern.name
	label.position = Vector2(2, CELL_SIZE - 20)
	label.size = Vector2(CELL_SIZE - 4, 18)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_contents = true
	
	cell.add_child(label)
	
	# Make clickable
	var button = Button.new()
	button.size = Vector2(CELL_SIZE, CELL_SIZE)
	button.flat = true
	button.pressed.connect(_on_tartan_clicked.bind(pattern, index))
	
	cell.add_child(button)
	
	return cell

func create_tartan_material(pattern: Dictionary) -> CanvasItemMaterial:
	# For now, create a simple gradient approximation
	# In a full implementation, this would be a custom shader
	var material = CanvasItemMaterial.new()
	return material

func generate_random_tartan() -> Dictionary:
	var colors = []
	var num_colors = randi_range(3, 6)
	
	# Generate random colors
	for i in range(num_colors):
		colors.append(Color(randf(), randf(), randf(), 1.0))
	
	# Generate random pattern
	var pattern = []
	var pattern_length = randi_range(4, 8)
	for i in range(pattern_length):
		pattern.append(randi_range(0, num_colors - 1))
	
	return {
		"name": "Random " + str(randi()),
		"colors": colors,
		"pattern": pattern
	}

func _on_tartan_clicked(pattern: Dictionary, index: int):
	print("🏴󠁧󠁢󠁳󠁣󠁴󠁿 Clicked tartan: ", pattern.name)
	print("  Colors: ", pattern.colors.size())
	print("  Pattern: ", pattern.pattern)
	print("  Grid position: ", index, " (", index % GRID_SIZE, ",", index / GRID_SIZE, ")")
	
	# Could add popup with detailed pattern information
	show_pattern_details(pattern, index)

func show_pattern_details(pattern: Dictionary, index: int):
	# Create a simple popup with pattern details
	var popup = AcceptDialog.new()
	popup.title = pattern.name + " Tartan"
	popup.size = Vector2(400, 300)
	popup.position = get_global_mouse_position()
	
	var vbox = VBoxContainer.new()
	
	var info_label = RichTextLabel.new()
	info_label.bbcode_enabled = true
	info_label.size = Vector2(380, 200)
	
	var info_text = "[center][b]" + pattern.name + " Tartan[/b][/center]\n\n"
	info_text += "[b]Grid Position:[/b] " + str(index % GRID_SIZE) + ", " + str(index / GRID_SIZE) + "\n"
	info_text += "[b]Colors:[/b] " + str(pattern.colors.size()) + " colors\n"
	info_text += "[b]Pattern Length:[/b] " + str(pattern.pattern.size()) + " segments\n\n"
	
	if pattern.name in ["Royal Stewart", "Black Watch", "Gordon", "MacLeod"]:
		info_text += "[b]Historical:[/b] Traditional Scottish clan tartan\n"
	elif "Pride" in pattern.name or "Ocean" in pattern.name:
		info_text += "[b]Type:[/b] Modern artistic interpretation\n"
	else:
		info_text += "[b]Type:[/b] Procedurally generated pattern\n"
	
	info_label.text = info_text
	
	vbox.add_child(info_label)
	popup.add_child(vbox)
	get_tree().root.add_child(popup)
	popup.popup_centered()
	
	# Remove popup after showing
	popup.confirmed.connect(popup.queue_free)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			print("🔄 Regenerating random patterns...")
			regenerate_random_patterns()
		elif event.keycode == KEY_S:
			print("💾 Saving tartan gallery screenshot...")
			save_screenshot()

func regenerate_random_patterns():
	# Replace some patterns with new random ones
	var start_index = tartan_patterns.size()
	for i in range(start_index, all_patterns.size()):
		all_patterns[i] = generate_random_tartan()
	
	# Update the grid
	for i in range(pattern_cells.size()):
		var pattern_index = i % all_patterns.size()
		var pattern = all_patterns[pattern_index]
		
		# Update the existing cell
		var cell = pattern_cells[i]
		var label = cell.get_child(1) as Label
		label.text = pattern.name
		cell.tooltip_text = pattern.name

func save_screenshot():
	# Simple screenshot functionality
	var viewport = get_viewport()
	var img = viewport.get_texture().get_image()
	var timestamp = Time.get_datetime_string_from_system().replace(":", "_")
	var filename = "tartan_gallery_" + timestamp + ".png"
	
	# Save to user directory
	var path = OS.get_user_data_dir() + "/" + filename
	img.save_png(path)
	print("📸 Tartan gallery saved: ", path)
