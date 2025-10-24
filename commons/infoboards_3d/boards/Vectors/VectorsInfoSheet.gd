extends Control

# Constants for visualization
const GRID_SIZE = 400
const VECTOR_SCALE = 40
const BALL_RADIUS = 10
const FORCE_STRENGTH = 200
const DISTANCE_THRESHOLD = 80

# Variables for interactive elements
var current_page := 0
var total_pages := 5
var animation_speed := 2.0
var animation_playing := true
var animation_time := 0.0
var vis_control: Control

# Physics simulation objects
var particles = []
var forces = []

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
		"title": "Vectors: Introduction",
		"text": [
			"Vectors are mathematical objects that represent both magnitude (length) and direction.",
			"In programming, vectors are used to represent positions, velocities, accelerations, and forces.",
			"They allow us to model motion and physical interactions in 2D and 3D space.",
			"This info board will explain vector operations and their applications in creative coding and simulations.",
			"We'll explore vector basics, addition, multiplication, and how to use them to create physics-based animations.",
			"\nCode Example:\n# Vector declaration in Godot\nvar position = Vector2(100, 200)  # x=100, y=200\nvar velocity = Vector2(5, -3)    # Moving right and up\n\n# Basic vector operations\nposition += velocity  # Vector addition\nvelocity *= 0.98     # Vector scaling (applying friction)\n\n# Get vector properties\nvar speed = velocity.length()       # Magnitude\nvar direction = velocity.normalized()  # Direction (unit vector)"
		],
		"visualization": "intro"
	},
	{
		"title": "Vector Addition and Subtraction",
		"text": [
			"Vector addition combines two or more vectors by adding their corresponding components.",
			"Geometrically, it can be visualized using the 'head-to-tail' method or the parallelogram rule.",
			"Vector subtraction (A - B) gives the displacement vector from B to A.",
			"These operations are fundamental for calculating resultant forces, relative positions, and motion.",
			"The animation shows vector addition as combining movements in different directions.",
			"\nCode Example:\n# Vector addition in Godot\nvar force1 = Vector2(10, 5)    # First force\nvar force2 = Vector2(-3, 8)   # Second force\n\n# Calculate resultant force\nvar resultant = force1 + force2\n\n# Vector subtraction\nvar object_pos = Vector2(100, 100)\nvar target_pos = Vector2(200, 150)\n\n# Direction from object to target\nvar direction = target_pos - object_pos\n\n# Distance between objects\nvar distance = direction.length()"
		],
		"visualization": "addition"
	},
	{
		"title": "Vector Multiplication and Normalization",
		"text": [
			"Vectors can be multiplied by scalars (regular numbers) to change their magnitude without changing direction.",
			"Multiplying a vector by 2 doubles its length while keeping the same direction.",
			"Normalization creates a unit vector (length of 1) that preserves only the direction information.",
			"The dot product of two vectors produces a scalar value related to the angle between them.",
			"These operations are essential for controlling movement speed, calculating projections, and detecting alignment.",
			"\nCode Example:\n# Scalar multiplication\nvar velocity = Vector2(3, 4)\nvar speed_factor = 2.5\nvelocity *= speed_factor  # Increase speed\n\n# Normalization (unit vector)\nvar direction = (target - position).normalized()\n\n# Moving at consistent speed toward target\nvar speed = 5.0\nvelocity = direction * speed\n\n# Dot product (returns a scalar)\nvar forward = Vector2(0, -1)  # Forward direction\nvar to_target = (target - position).normalized()\nvar alignment = forward.dot(to_target)  # 1=aligned, 0=perpendicular, -1=opposite"
		],
		"visualization": "multiplication"
	},
	{
		"title": "Forces and Motion",
		"text": [
			"Vectors are perfect for simulating physical forces and resulting motion.",
			"Newton's Second Law: Force = Mass × Acceleration, or Acceleration = Force / Mass.",
			"By accumulating forces and updating position based on velocity, we can create realistic physics simulations.",
			"Common forces include gravity, friction, spring forces, and attraction/repulsion.",
			"The animation demonstrates particles responding to various forces in a 2D environment.",
			"\nCode Example:\n# Simple physics system\nclass Particle:\n    var position = Vector2.ZERO\n    var velocity = Vector2.ZERO\n    var acceleration = Vector2.ZERO\n    var mass = 1.0\n    \n    func apply_force(force):\n        # F = ma, so a = F/m\n        acceleration += force / mass\n    \n    func update(delta):\n        # Update velocity and position\n        velocity += acceleration * delta\n        position += velocity * delta\n        \n        # Reset acceleration\n        acceleration = Vector2.ZERO\n        \n        # Apply friction\n        velocity *= 0.99"
		],
		"visualization": "forces"
	},
	{
		"title": "Vector Fields and Flow",
		"text": [
			"Vector fields assign a vector to each point in space, creating flow patterns that particles can follow.",
			"They can be used to create complex, naturalistic movement patterns in particle systems.",
			"Applications include simulating fluids, crowd movement, wind effects, and dynamic terrain.",
			"Vector fields can be generated using noise functions, mathematical formulas, or custom algorithms.",
			"The visualization shows particles flowing through different types of vector fields.",
			"\nCode Example:\n# Creating a circular vector field\nfunc get_field_vector(position):\n    var center = Vector2(width/2, height/2)\n    var offset = position - center\n    \n    # Create a perpendicular vector for circular motion\n    var perpendicular = Vector2(-offset.y, offset.x).normalized()\n    \n    # Scale by distance from center (stronger near center)\n    var distance = offset.length()\n    var strength = max(0, 1 - distance/200)\n    \n    return perpendicular * strength * 5.0\n\n# Apply field force to all particles\nfor particle in particles:\n    var field_force = get_field_vector(particle.position)\n    particle.apply_force(field_force)"
		],
		"visualization": "fields"
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
	speed_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_slider.value_changed.connect(_on_speed_slider_changed)
	
	speed_container.add_child(speed_label)
	speed_container.add_child(speed_slider)
	vbox_container.add_child(speed_container)
	
	# Initialize random data for visualizations
	_initialize_physics_objects()
	
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

func _initialize_physics_objects():
	# Create particles
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	particles = []
	for i in range(10):
		particles.append({
			"position": Vector2(rng.randf_range(50, GRID_SIZE - 50), rng.randf_range(50, GRID_SIZE - 50)),
			"velocity": Vector2(rng.randf_range(-50, 50), rng.randf_range(-50, 50)),
			"acceleration": Vector2.ZERO,
			"mass": rng.randf_range(1, 5),
			"color": Color(rng.randf(), rng.randf(), rng.randf(), 0.8)
		})
	
	# Create forces
	forces = []
	for i in range(3):
		forces.append({
			"position": Vector2(rng.randf_range(50, GRID_SIZE - 50), rng.randf_range(50, GRID_SIZE - 50)),
			"strength": rng.randf_range(100, 300) * (1 if rng.randf() > 0.5 else -1),
			"color": Color(1, 0.5, 0, 0.8) if i % 2 == 0 else Color(0, 0.5, 1, 0.8)
		})

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
		text_container.add_child(label)
		
		# Add some spacing between paragraphs
		if text_container.get_child_count() > 1:
			label.add_theme_constant_override("margin_top", 10)

	if vis_control and is_instance_valid(vis_control):
		vis_control.queue_free()
		vis_control = null

	# Load and instantiate the new visualization control scene
	var vis_scene = preload("res://commons/infoboards_3d/boards/Vectors/VectorsVisualizationControl.tscn")
	vis_control = vis_scene.instantiate()
	vis_control.visualization_type = page_content[current_page]["visualization"]
	vis_control.animation_time = animation_time
	vis_control.animation_speed = animation_speed
	vis_control.particles = particles
	#vis_control.forces = forces

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
		
	var speed_label = vbox_container.get_child(vbox_container.get_child_count() - 1).get_child(0)
	speed_label.text = "Speed: " + str(snappedf(value, 0.1))
