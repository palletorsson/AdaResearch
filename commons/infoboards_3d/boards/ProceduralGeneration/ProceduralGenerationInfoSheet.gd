extends Control

# Constants for visualization
const NOISE_RESOLUTION = 128
const LSYSTEM_ITERATIONS = 4
const PROCEDURAL_ROOM_COUNT = 12
const ANIMATION_SPEED_DEFAULT = 1.0

# Variables for interactive elements
var current_page := 0
var total_pages := 5
var animation_playing := true
var animation_speed := ANIMATION_SPEED_DEFAULT
var time_elapsed := 0.0
var vis_control: Control

# Parameters that can be adjusted
var noise_seed := 42
var noise_scale := 25.0
var noise_octaves := 4
var lsystem_angle := 25.0
var dungeon_room_count := PROCEDURAL_ROOM_COUNT
var dungeon_connectivity := 0.5

# Node references
@onready var vbox_container = $MarginContainer/VBoxContainer
@onready var text_container = $MarginContainer/VBoxContainer/HBoxContainer/TextScrollContainer/CodeContainer/MarginContainer/VBoxContainer
@onready var vis_container = $MarginContainer/VBoxContainer/HBoxContainer/VisualizationContainer/MarginContainer/VBoxContainer

@onready var title_label = $MarginContainer/VBoxContainer/Title
@onready var prev_button = $MarginContainer/VBoxContainer/NavigationButtons/PrevButton
@onready var next_button = $MarginContainer/VBoxContainer/NavigationButtons/NextButton
@onready var navigation_buttons = $MarginContainer/VBoxContainer/NavigationButtons

# Content for each page
var page_content = [
	{
		"title": "Procedural Generation: Introduction",
		"text": [
			"Procedural generation is the algorithmic creation of content with limited or indirect user input.",
			"It enables creation of complex, varied, and potentially infinite worlds and objects from simple rules.",
			"Key advantages include reduced memory usage, greater variety, replayability, and rapid prototyping.",
			"Modern games and simulations use procedural generation for terrains, levels, textures, stories, and more.",
			"This info board will guide you through fundamental procedural generation techniques and their applications.",
			"\nCode Example:\n# Basic random dungeon generator\nfunc generate_dungeon(width: int, height: int, room_count: int) -> Array:\n    var dungeon = []\n    # Initialize empty grid\n    for y in range(height):\n        var row = []\n        for x in range(width):\n            row.append(0)  # 0 = wall\n        dungeon.append(row)\n    \n    # Generate rooms\n    var rooms = []\n    for i in range(room_count):\n        var room = place_random_room(dungeon)\n        if room:\n            rooms.append(room)\n    \n    # Connect rooms with corridors\n    connect_rooms(dungeon, rooms)\n    \n    return dungeon"
		],
		"visualization": "intro"
	},
	{
		"title": "Noise-Based Terrain Generation",
		"text": [
			"Noise functions are the foundation of procedural terrain generation.",
			"Perlin noise and Simplex noise create smooth, continuous random values that resemble natural patterns.",
			"By combining noise at different scales (octaves), we can create realistic terrain features.",
			"Noise can be interpreted as elevation data for height maps or used to blend between different biomes.",
			"The visualization demonstrates how modifying noise parameters affects the resulting terrain.",
			"\nCode Example:\n# Generate terrain using simplex noise\nfunc generate_terrain(width: int, height: int, seed: int) -> Array:\n    var noise = FastNoiseLite.new()\n    noise.seed = seed\n    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX\n    noise.fractal_type = FastNoiseLite.FRACTAL_FBM\n    noise.fractal_octaves = 4\n    noise.frequency = 0.01\n    \n    var terrain = []\n    for y in range(height):\n        var row = []\n        for x in range(width):\n            # Get noise value in range [-1,1]\n            var elevation = noise.get_noise_2d(x, y)\n            # Scale to desired range (e.g., 0-10)\n            elevation = (elevation + 1) * 5\n            row.append(elevation)\n        terrain.append(row)\n    \n    return terrain"
		],
		"visualization": "noise_terrain"
	},
	{
		"title": "L-Systems: Generating Plants and Fractals",
		"text": [
			"L-systems (Lindenmayer systems) are parallel rewriting systems that can model growth processes.",
			"They consist of an alphabet of symbols, a set of production rules, and an initial axiom.",
			"By repeatedly applying rules to the axiom, complex structures emerge from simple instructions.",
			"L-systems are particularly effective for generating plants, trees, and fractals.",
			"The visualization shows how simple rules can create intricate branching structures.",
			"\nCode Example:\n# Generate L-system string\nfunc generate_lsystem(axiom: String, rules: Dictionary, iterations: int) -> String:\n    var result = axiom\n    \n    for i in range(iterations):\n        var next_result = \"\"\n        \n        for c in result:\n            if rules.has(c):\n                next_result += rules[c]\n            else:\n                next_result += c\n        \n        result = next_result\n    \n    return result\n\n# Example rule for a plant-like structure\n# Axiom: \"F\"\n# Rules: {\"F\": \"F[+F]F[-F]F\"}\n# Where:\n# F = Draw forward\n# + = Turn right\n# - = Turn left\n# [ = Save position/angle\n# ] = Restore position/angle"
		],
		"visualization": "lsystem"
	},
	{
		"title": "Procedural Dungeon Generation",
		"text": [
			"Procedural dungeon generation creates game levels or mazes algorithmically.",
			"Common approaches include grid-based methods, BSP (Binary Space Partitioning) trees, agent-based systems, and cellular automata.",
			"The process typically involves room placement, corridor creation, and connectivity checks.",
			"Parameters like room density, corridor width, and connection probability control the resulting layout.",
			"The visualization demonstrates a BSP-based dungeon generator that recursively divides space to create rooms.",
			"\nCode Example:\n# Binary Space Partitioning dungeon generator\nclass BSPNode:\n    var x: int\n    var y: int\n    var width: int\n    var height: int\n    var room_x: int\n    var room_y: int\n    var room_width: int\n    var room_height: int\n    var left_child: BSPNode\n    var right_child: BSPNode\n    \n    func split(min_size: int) -> bool:\n        # Decide whether to split horizontally or vertically\n        var split_horizontal = randf() > 0.5\n        \n        if width > height && width / height >= 1.25:\n            split_horizontal = false\n        elif height > width && height / width >= 1.25:\n            split_horizontal = true\n        \n        # Calculate maximum possible split position\n        var max_split = 0\n        if split_horizontal:\n            max_split = height - min_size\n        else:\n            max_split = width - min_size\n        \n        # Ensure we can split at this size\n        if max_split < min_size:\n            return false\n        \n        # Determine split position\n        var split = min_size + randi() % (max_split - min_size + 1)\n        \n        # Create child nodes\n        if split_horizontal:\n            left_child = BSPNode.new(x, y, width, split)\n            right_child = BSPNode.new(x, y + split, width, height - split)\n        else:\n            left_child = BSPNode.new(x, y, split, height)\n            right_child = BSPNode.new(x + split, y, width - split, height)\n        \n        return true"
		],
		"visualization": "dungeon"
	},
	{
		"title": "Advanced Techniques and Applications",
		"text": [
			"Beyond the basics, procedural generation encompasses a wide range of advanced techniques:",
			"• Wave Function Collapse - Generates patterns based on constraints and local rules",
			"• Grammar-based generation - Creates content using formal grammars and rule systems",
			"• Generative adversarial networks - Uses machine learning for realistic content",
			"• Voronoi diagrams - Partitions space for natural-looking regions",
			"Procedural generation is used in games (Minecraft, No Man's Sky), film (landscapes, crowds), architecture (generative design), music, and more.",
			"The visualization demonstrates multiple interconnected procedural systems working together.",
			"\nCode Example:\n# Wave Function Collapse algorithm (simplified)\nfunc wave_function_collapse(width: int, height: int, tiles: Array, rules: Dictionary) -> Array:\n    # Initialize grid with all possibilities\n    var grid = []\n    for y in range(height):\n        var row = []\n        for x in range(width):\n            row.append({\"collapsed\": false, \"options\": tiles.duplicate()})\n        grid.append(row)\n    \n    # Continue until all cells are collapsed\n    while true:\n        # Find cell with minimum entropy (fewest options)\n        var min_entropy_cell = find_min_entropy(grid)\n        if min_entropy_cell == null:\n            break  # All cells collapsed\n        \n        # Collapse the cell to a random valid option\n        var options = grid[min_entropy_cell.y][min_entropy_cell.x].options\n        var chosen = options[randi() % options.size()]\n        grid[min_entropy_cell.y][min_entropy_cell.x].collapsed = true\n        grid[min_entropy_cell.y][min_entropy_cell.x].options = [chosen]\n        \n        # Propagate constraints to neighbors\n        propagate(grid, min_entropy_cell.x, min_entropy_cell.y, rules)\n    \n    return grid"
		],
		"visualization": "advanced"
	}
]

func _ready():
	# Connect buttons
	prev_button.pressed.connect(_on_prev_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	
	# Add play/pause button
	var play_button = Button.new()
	play_button.text = "Pause Animation"
	play_button.pressed.connect(_on_play_button_pressed)
	navigation_buttons.add_child(play_button)
	
	# Add speed slider
	var speed_container = HBoxContainer.new()
	var speed_label = Label.new()
	speed_label.text = "Speed: "
	var speed_slider = HSlider.new()
	speed_slider.min_value = 0.5
	speed_slider.max_value = 4.0
	speed_slider.step = 0.1
	speed_slider.value = animation_speed
	speed_slider.value_changed.connect(_on_speed_slider_changed)
	
	speed_container.add_child(speed_label)
	speed_container.add_child(speed_slider)
	vbox_container.add_child(speed_container)
	
	# Add noise parameters for terrain page
	var noise_param_container = HBoxContainer.new()
	
	# Seed control
	var seed_container = VBoxContainer.new()
	var seed_label = Label.new()
	seed_label.text = "Noise Seed:"
	var seed_slider = HSlider.new()
	seed_slider.min_value = 1
	seed_slider.max_value = 100
	seed_slider.step = 1
	seed_slider.value = noise_seed
	seed_slider.value_changed.connect(_on_seed_changed)
	
	seed_container.add_child(seed_label)
	seed_container.add_child(seed_slider)
	
	# Scale control
	var scale_container = VBoxContainer.new()
	var scale_label = Label.new()
	scale_label.text = "Noise Scale:"
	var scale_slider = HSlider.new()
	scale_slider.min_value = 5
	scale_slider.max_value = 50
	scale_slider.step = 1
	scale_slider.value = noise_scale
	scale_slider.value_changed.connect(_on_scale_changed)
	
	scale_container.add_child(scale_label)
	scale_container.add_child(scale_slider)
	
	# Octaves control
	var octaves_container = VBoxContainer.new()
	var octaves_label = Label.new()
	octaves_label.text = "Noise Octaves:"
	var octaves_slider = HSlider.new()
	octaves_slider.min_value = 1
	octaves_slider.max_value = 8
	octaves_slider.step = 1
	octaves_slider.value = noise_octaves
	octaves_slider.value_changed.connect(_on_octaves_changed)
	
	octaves_container.add_child(octaves_label)
	octaves_container.add_child(octaves_slider)
	
	noise_param_container.add_child(seed_container)
	noise_param_container.add_child(scale_container)
	noise_param_container.add_child(octaves_container)
	noise_param_container.visible = false
	noise_param_container.name = "NoiseParamContainer"
	vbox_container.add_child(noise_param_container)
	
	# Add L-system parameters
	var lsystem_param_container = HBoxContainer.new()
	var angle_label = Label.new()
	angle_label.text = "Branch Angle:"
	var angle_slider = HSlider.new()
	angle_slider.min_value = 10
	angle_slider.max_value = 45
	angle_slider.step = 1
	angle_slider.value = lsystem_angle
	angle_slider.value_changed.connect(_on_angle_changed)
	
	lsystem_param_container.add_child(angle_label)
	lsystem_param_container.add_child(angle_slider)
	lsystem_param_container.visible = false
	lsystem_param_container.name = "LSystemParamContainer"
	vbox_container.add_child(lsystem_param_container)
	
	# Add dungeon generation parameters
	var dungeon_param_container = HBoxContainer.new()
	
	# Room count control
	var room_container = VBoxContainer.new()
	var room_label = Label.new()
	room_label.text = "Room Count:"
	var room_slider = HSlider.new()
	room_slider.min_value = 5
	room_slider.max_value = 20
	room_slider.step = 1
	room_slider.value = dungeon_room_count
	room_slider.value_changed.connect(_on_room_count_changed)
	
	room_container.add_child(room_label)
	room_container.add_child(room_slider)
	
	# Connectivity control
	var connect_container = VBoxContainer.new()
	var connect_label = Label.new()
	connect_label.text = "Connectivity:"
	var connect_slider = HSlider.new()
	connect_slider.min_value = 0.1
	connect_slider.max_value = 1.0
	connect_slider.step = 0.1
	connect_slider.value = dungeon_connectivity
	connect_slider.value_changed.connect(_on_connectivity_changed)
	
	connect_container.add_child(connect_label)
	connect_container.add_child(connect_slider)
	
	dungeon_param_container.add_child(room_container)
	dungeon_param_container.add_child(connect_container)
	dungeon_param_container.visible = false
	dungeon_param_container.name = "DungeonParamContainer"
	vbox_container.add_child(dungeon_param_container)
	
	# Show initial page
	update_page()

func _process(delta):
	if animation_playing:
		time_elapsed += delta * animation_speed
		
		# If we have an active visualization control, update it
		if vis_control and is_instance_valid(vis_control):
			vis_control.animation_playing = animation_playing
			vis_control.animation_speed = animation_speed
			vis_control.time_elapsed = time_elapsed
		
		# Update visualization based on current page
		queue_redraw()

func update_page():
	# Clear previous content
	for child in text_container.get_children():
		if child.name != "HeaderLabel" and child.name != "Separator":
			child.queue_free()

	# Update title
	title_label.text = page_content[current_page]["title"]
	
	# Add text content
	for text in page_content[current_page]["text"]:
		var label = Label.new()
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		text_container.add_child(label)
		
		# Add some spacing between paragraphs
		if text_container.get_child_count() > 1:
			label.add_theme_constant_override("margin_top", 10)

	# Clean up previous visualization control if it exists
	if vis_control and is_instance_valid(vis_control):
		vis_control.queue_free()
		vis_control = null

	# Load and instantiate the new visualization control scene
	var vis_scene = load("res://commons/infoBoards/ProceduralGeneration/ProceduralGenerationVisualizationControl.tscn")
	vis_control = vis_scene.instantiate()
	vis_control.visualization_type = page_content[current_page]["visualization"]
	
	# Set additional parameters
	vis_control.noise_seed = noise_seed
	vis_control.noise_scale = noise_scale
	vis_control.noise_octaves = noise_octaves
	vis_control.lsystem_angle = lsystem_angle
	vis_control.dungeon_room_count = dungeon_room_count
	vis_control.dungeon_connectivity = dungeon_connectivity
	
	# Setup sizing
	vis_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vis_control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vis_container.add_child(vis_control)
	
	# Show/hide specific controls based on the page
	for child in vbox_container.get_children():
		if child.name == "NoiseParamContainer":
			child.visible = (current_page == 1)  # Noise terrain page
		elif child.name == "LSystemParamContainer":
			child.visible = (current_page == 2)  # L-system page
		elif child.name == "DungeonParamContainer":
			child.visible = (current_page == 3)  # Dungeon page
	
	# Update navigation buttons
	prev_button.disabled = (current_page == 0)
	next_button.disabled = (current_page == total_pages - 1)
	
	# Reset time elapsed
	time_elapsed = 0.0
	
	# Force redraw of visualization
	queue_redraw()

func _on_prev_button_pressed():
	if current_page > 0:
		current_page -= 1
		update_page()

func _on_next_button_pressed():
	if current_page < total_pages - 1:
		current_page += 1
		update_page()

func _on_play_button_pressed():
	animation_playing = !animation_playing
	var play_button = navigation_buttons.get_child(2)
	play_button.text = "Play Animation" if not animation_playing else "Pause Animation"
	
	if vis_control and is_instance_valid(vis_control):
		vis_control.animation_playing = animation_playing

func _on_speed_slider_changed(value):
	animation_speed = value
	var speed_label = vbox_container.get_child(vbox_container.get_child_count() - 4).get_child(0)
	speed_label.text = "Speed: " + str(snappedf(value, 0.1))
	
	if vis_control and is_instance_valid(vis_control):
		vis_control.animation_speed = animation_speed

func _on_seed_changed(value):
	noise_seed = value
	
	if vis_control and is_instance_valid(vis_control):
		vis_control.noise_seed = noise_seed
		vis_control.regenerate_terrain()

func _on_scale_changed(value):
	noise_scale = value
	
	if vis_control and is_instance_valid(vis_control):
		vis_control.noise_scale = noise_scale
		vis_control.regenerate_terrain()

func _on_octaves_changed(value):
	noise_octaves = value
	
	if vis_control and is_instance_valid(vis_control):
		vis_control.noise_octaves = noise_octaves
		vis_control.regenerate_terrain()

func _on_angle_changed(value):
	lsystem_angle = value
	
	if vis_control and is_instance_valid(vis_control):
		vis_control.lsystem_angle = lsystem_angle
		vis_control.regenerate_lsystem()

func _on_room_count_changed(value):
	dungeon_room_count = value
	
	if vis_control and is_instance_valid(vis_control):
		vis_control.dungeon_room_count = dungeon_room_count
		vis_control.regenerate_dungeon()

func _on_connectivity_changed(value):
	dungeon_connectivity = value
	
	if vis_control and is_instance_valid(vis_control):
		vis_control.dungeon_connectivity = dungeon_connectivity
		vis_control.regenerate_dungeon()
