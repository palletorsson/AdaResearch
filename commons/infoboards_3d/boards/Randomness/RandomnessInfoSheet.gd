extends Control

# Constants for visualization
const CIRCLE_RADIUS = 100
const GRAPH_WIDTH = 400
const GRAPH_HEIGHT = 200
const HISTOGRAM_BARS = 10
const WALKER_STEPS = 1000
const PERLIN_RESOLUTION = 100

# Font resource
const ROBOTO_FONT = preload("res://commons/font/Roboto-VariableFont_wdth,wght.ttf")

# Variables for interactive elements
var current_page := 0
var total_pages := 5
var animation_speed := 2.0
var animation_playing := true
var animation_time := 0.0
var rand_values := []
var walker_positions := []
var perlin_values := []
var vis_control: Control

# Node references
@onready var hbox_container = $MarginContainer/HBoxContainer
@onready var left_panel = $MarginContainer/HBoxContainer/LeftPanel
@onready var text_container = $MarginContainer/HBoxContainer/LeftPanel/TextScrollContainer/CodeContainer/MarginContainer/VBoxContainer
@onready var vis_container = $MarginContainer/HBoxContainer/VisualizationContainer/MarginContainer/VBoxContainer

@onready var title_label = $MarginContainer/HBoxContainer/LeftPanel/Title
@onready var prev_button = $MarginContainer/HBoxContainer/LeftPanel/NavigationButtons/PrevButton
@onready var next_button = $MarginContainer/HBoxContainer/LeftPanel/NavigationButtons/NextButton
@onready var navigation_buttons = $MarginContainer/HBoxContainer/LeftPanel/NavigationButtons

# Content for each page
var page_content = [
	{
		"title": "Understanding Randomness: Introduction",
		"text": [
			"Randomness is a fundamental concept in computing, used in everything from games to simulations.",
			"True randomness is difficult to achieve in computers, so we use pseudorandom number generators (PRNGs).",
			"PRNGs create sequences of numbers that appear random but are actually determined by an initial value called a seed.",
			"This info board will explain different types of randomness and their applications in creative coding.",
			"We'll explore uniform distribution, Gaussian (normal) distribution, random walks, and Perlin noise.",
			"\nCode Example:\n# Basic random number generation in Godot\nvar rng = RandomNumberGenerator.new()\nrng.randomize()  # Uses current time as seed\n\n# Generate a random float between 0 and 1\nvar random_value = rng.randf()\n\n# Generate a random integer between 1 and 10\nvar random_int = rng.randi_range(1, 10)"
		],
		"visualization": "intro"
	},
	{
		"title": "Uniform Distribution: Equal Probability",
		"text": [
			"Uniform distribution gives each possible outcome an equal probability of occurring.",
			"In programming, the standard random() function typically produces uniformly distributed values between 0 and 1.",
			"This distribution is perfect for simulating dice rolls, card shuffling, or any scenario where all outcomes should be equally likely.",
			"The animation shows random values being generated and plots them on a histogram.",
			"Over time, with enough samples, the histogram should appear relatively flat, indicating equal distribution across all possible values.",
			"\nCode Example:\n# Generate uniformly distributed random values\nfunc generate_uniform_values(count: int) -> Array:\n    var values = []\n    var rng = RandomNumberGenerator.new()\n    rng.randomize()\n    \n    for i in range(count):\n        values.append(rng.randf())  # Values between 0 and 1\n    \n    return values"
		],
		"visualization": "uniform"
	},
	{
		"title": "Gaussian Distribution: Normal Probability",
		"text": [
			"Gaussian (or normal) distribution creates a bell curve where values cluster around the mean.",
			"Unlike uniform distribution, values near the middle are more likely than values at the extremes.",
			"This type of randomness is useful for modeling natural phenomena, like heights, weights, or measurement errors.",
			"In creative coding, Gaussian randomness creates more natural-looking variation in generative art or procedural animation.",
			"The visualization shows how values cluster around the center when using Gaussian distribution.",
			"\nCode Example:\n# Box-Muller transform to generate Gaussian distribution\nfunc generate_gaussian(mean: float, std_dev: float) -> float:\n    var rng = RandomNumberGenerator.new()\n    rng.randomize()\n    \n    # Generate two independent uniform random values\n    var u1 = rng.randf()\n    var u2 = rng.randf()\n    \n    # Box-Muller transform\n    var z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)\n    \n    # Scale and shift to desired mean and standard deviation\n    return mean + z0 * std_dev"
		],
		"visualization": "gaussian"
	},
	{
		"title": "Random Walks: Accumulating Randomness",
		"text": [
			"A random walk is a mathematical object that describes a path of random steps in some mathematical space.",
			"In its simplest form, each step moves in a random direction from the current position.",
			"Random walks are used to model many processes in physics, economics, and biology.",
			"In creative coding, they create organic-looking paths for generative art or procedural movement.",
			"The visualization shows different types of random walks, from simple to biased movement.",
			"\nCode Example:\n# Simple 2D Random Walker\nclass Walker:\n    var position = Vector2.ZERO\n    var rng = RandomNumberGenerator.new()\n    \n    func _init():\n        rng.randomize()\n    \n    func step():\n        # Choose a random direction\n        var direction = rng.randi_range(0, 3)\n        \n        match direction:\n            0: position.x += 1  # Right\n            1: position.x -= 1  # Left\n            2: position.y += 1  # Down\n            3: position.y -= 1  # Up\n            \n        return position"
		],
		"visualization": "random_walk"
	},
	{
		"title": "Perlin Noise: Coherent Randomness",
		"text": [
			"Perlin Noise, developed by Ken Perlin, is a type of gradient noise that creates smooth, natural-looking randomness.",
			"Unlike uniform or Gaussian randomness, Perlin noise values change smoothly over time or space.",
			"This property makes it ideal for generating terrain, clouds, textures, and natural motion.",
			"The visualization shows how Perlin noise creates smoothly changing values across one and two dimensions.",
			"In creative coding, Perlin noise is essential for creating organic environments and natural movements.",
			"\nCode Example:\n# Using Godot's built-in noise functions\nvar noise = FastNoiseLite.new()\n\n# Configure the noise\nfunc setup_noise():\n    noise.seed = randi()\n    noise.noise_type = FastNoiseLite.TYPE_PERLIN\n    noise.frequency = 0.01\n\n# Get a noise value at a position\nfunc get_noise_value(x: float, y: float) -> float:\n    return noise.get_noise_2d(x, y)"
		],
		"visualization": "perlin"
	}
]

func _ready():
	# Connect buttons
	prev_button.pressed.connect(_on_prev_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	
	# Add play/pause button
	var play_button = Button.new()
	play_button.text = "Pause Animation"
	play_button.add_theme_font_override("font", ROBOTO_FONT)
	play_button.pressed.connect(_on_play_button_pressed)
	navigation_buttons.add_child(play_button)
	
	# Add speed slider
	var speed_container = HBoxContainer.new()
	var speed_label = Label.new()
	speed_label.text = "Speed: "
	speed_label.add_theme_font_override("font", ROBOTO_FONT)
	speed_label.add_theme_font_size_override("font_size", 14)
	var speed_slider = HSlider.new()
	speed_slider.min_value = 0.5
	speed_slider.max_value = 4.0
	speed_slider.step = 0.1
	speed_slider.value = animation_speed
	speed_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_slider.value_changed.connect(_on_speed_slider_changed)
	
	speed_container.add_child(speed_label)
	speed_container.add_child(speed_slider)
	left_panel.add_child(speed_container)
	
	# Initialize random values for visualizations
	_initialize_random_data()
	
	# Show initial page
	update_page()

func _process(delta):
	if animation_playing:
		animation_time += delta * animation_speed
		
		# Update visualization based on current page
		if vis_control and is_instance_valid(vis_control):
			vis_control.animation_time = animation_time
			vis_control.animation_speed = animation_speed
			vis_control.queue_redraw()

func _initialize_random_data():
	# Initialize random values for uniform distribution
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	rand_values = []
	for i in range(100):
		rand_values.append(rng.randf())
	
	# Initialize random walk
	walker_positions = [Vector2.ZERO]
	for i in range(WALKER_STEPS):
		var last_pos = walker_positions[walker_positions.size() - 1]
		var dir = rng.randi_range(0, 3)
		var new_pos = last_pos
		
		match dir:
			0: new_pos.x += 1
			1: new_pos.x -= 1
			2: new_pos.y += 1
			3: new_pos.y -= 1
		
		walker_positions.append(new_pos)
	
	# Initialize perlin noise values
	perlin_values = []
	var noise = FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	for i in range(PERLIN_RESOLUTION):
		perlin_values.append(noise.get_noise_1d(i * 0.05))

func update_page():
	# Clear previous content
	for child in text_container.get_children():
		if child.name != "HeaderLabel" and child.name != "Separator":
			child.queue_free()

	# Update title
	title_label.text = page_content[current_page]["title"]
	
	for text in page_content[current_page]["text"]:
		var label = Label.new()
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		label.add_theme_font_override("font", ROBOTO_FONT)
		label.add_theme_font_size_override("font_size", 14)
		text_container.add_child(label)
		
		# Add some spacing between paragraphs
		if text_container.get_child_count() > 1:
			label.add_theme_constant_override("margin_top", 10)

	if vis_control and is_instance_valid(vis_control):
		vis_control.queue_free()
		vis_control = null

	# Load and instantiate the new visualization control scene
	var vis_scene = preload("res://commons/infoboards_3d/boards/Randomness/RandomnessVisualizationControl.tscn")
	vis_control = vis_scene.instantiate()
	vis_control.visualization_type = page_content[current_page]["visualization"]
	vis_control.animation_time = animation_time
	vis_control.animation_speed = animation_speed
	vis_control.rand_values = rand_values
	vis_control.walker_positions = walker_positions
	vis_control.perlin_values = perlin_values

	# Properly set up sizing flags
	vis_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vis_control.size_flags_vertical = Control.SIZE_EXPAND_FILL	

	vis_container.add_child(vis_control)
	
	# Update navigation buttons
	prev_button.disabled = (current_page == 0)
	next_button.disabled = (current_page == total_pages - 1)
	
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
	
	if vis_control and is_instance_valid(vis_control):
		vis_control.animation_speed = value
		
	var speed_label = left_panel.get_child(left_panel.get_child_count() - 1).get_child(0)
	speed_label.text = "Speed: " + str(snappedf(value, 0.1))
