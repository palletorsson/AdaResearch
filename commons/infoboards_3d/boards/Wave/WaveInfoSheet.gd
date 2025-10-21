extends Control

# Constants for visualization
const CIRCLE_RADIUS = 100
const GRAPH_WIDTH = 400
const GRAPH_HEIGHT = 200
const WAVE_SEGMENTS = 120
const WAVE_AMPLITUDE = 80
const TIME_SCALE = 3.0  # Controls how many wave cycles are shown

# Variables for interactive elements
var current_page := 0
var total_pages := 5
var unit_circle_point := Vector2(CIRCLE_RADIUS, 0)
var angle := 0.0
var animation_speed := 2.0
var animation_playing := true
var vis_control: Control

# Node references
@onready var vbox_container = $MarginContainer/VBoxContainer
@onready var text_container = $MarginContainer/VBoxContainer/HBoxContainer/TextScrollContainer/CodeContainer/MarginContainer/VBoxContainer
@onready var vis_container = $MarginContainer/VBoxContainer/HBoxContainer/VisualizationContainer/MarginContainer/VBoxContainer

@onready var title_label = $MarginContainer/VBoxContainer/Title
@onready var prev_button = $MarginContainer/VBoxContainer/NavigationButtons/PrevButton
@onready var next_button = $MarginContainer/VBoxContainer/NavigationButtons/NextButton
@onready var navigation_buttons =  $MarginContainer/VBoxContainer/NavigationButtons

# Content for each page
var page_content = [
	{
		"title": "The Unit Circle",
		"text": [
			"The unit circle is a circle with a radius of 1 centered at the origin (0,0) in the Cartesian coordinate system.",
			"It provides a geometric model that helps visualize trigonometric functions.",
			"Any point on the unit circle can be represented by the coordinates (cos θ, sin θ), where θ is the angle measured counterclockwise from the positive x-axis.",
			"This relationship is the foundation of trigonometry and is essential for understanding wave patterns."
		],
		"visualization": "unit_circle"
	},
	{
		"title": "Sine Function",
		"text": [
			"The sine function (sin θ) represents the y-coordinate of a point on the unit circle at angle θ.",
			"Range: The sine function always produces values between -1 and 1.",
			"Period: The sine function repeats every 2π radians (360 degrees).",
			"When we plot sin(θ) against θ, we get a smooth, periodic wave pattern.",
			"This wave is fundamental to understanding many natural phenomena, including sound waves and light."
		],
		"visualization": "sine_wave"
	},
	{
		"title": "Cosine Function",
		"text": [
			"The cosine function (cos θ) represents the x-coordinate of a point on the unit circle at angle θ.",
			"Range: Like sine, cosine always produces values between -1 and 1.",
			"Period: Cosine also repeats every 2π radians (360 degrees).",
			"The cosine wave has the same shape as the sine wave, but is shifted by π/2 radians (90 degrees).",
			"This phase shift relationship between sine and cosine is crucial for understanding wave interactions."
		],
		"visualization": "cosine_wave"
	},
	{
		"title": "Tangent Function",
		"text": [
			"The tangent function (tan θ) is defined as the ratio of sine to cosine: tan θ = sin θ / cos θ",
			"Geometrically, it represents the slope of the line from the origin to the point on the unit circle.",
			"Range: The tangent function ranges from negative infinity to positive infinity.",
			"Undefined: Tangent is undefined when cos θ = 0 (at π/2, 3π/2, etc.).",
			"Period: The tangent function repeats every π radians (180 degrees).",
			"The tangent wave has vertical asymptotes and behaves differently from sine and cosine."
		],
		"visualization": "tangent_wave"
	},
	{
		"title": "Wave Patterns & Combinations",
		"text": [
			"Complex wave patterns can be created by combining sine and cosine waves with different:",
			"• Amplitudes: Controls the height of the wave",
			"• Frequencies: Controls how many cycles occur in a given distance",
			"• Phases: Controls the horizontal shift of the wave",
			"Any periodic waveform can be represented as a sum of sine and cosine waves (Fourier series).",
			"This principle is fundamental to understanding complex patterns in nature and is the basis for sound synthesis and analysis."
		],
		"visualization": "combined_waves"
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
	#speed_slider.size_flags_horizontal = Control.SIZE_FLAGS_EXPAND_FILL
	speed_slider.value_changed.connect(_on_speed_slider_changed)
	
	speed_container.add_child(speed_label)
	speed_container.add_child(speed_slider)
	vbox_container.add_child(speed_container)
	
	# Show initial page
	update_page()

func _process(delta):
	if animation_playing:
		angle += delta * animation_speed
		if angle > 2 * PI:
			angle -= 2 * PI
		
		# Update visualization based on current page
		queue_redraw()

func _draw():
	if not is_inside_tree():
		return
	
	var vis_rect = vis_container.get_global_rect()
	var center_x = vis_rect.position.x + vis_rect.size.x / 2
	var center_y = vis_rect.position.y + vis_rect.size.y / 2
	

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
	var vis_scene = preload("res://adaresearch/Common/Scenes/Context/infoBoards/UnitCircle/WaveVisualizationControl.tscn")

	vis_control = vis_scene.instantiate()
	vis_control.visualization_type = page_content[current_page]["visualization"]

	# Properly set up sizing flags
	vis_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vis_control.size_flags_vertical = Control.SIZE_EXPAND_FILL	

	vis_container.add_child(vis_control)
	# Now safely set the visualization type
		
	# Update navigation buttons
	prev_button.disabled = (current_page == 0)
	next_button.disabled = (current_page == total_pages - 1)
	
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
	if vis_control:
		vis_control.animation_playing = !vis_control.animation_playing
		var play_button = navigation_buttons.get_child(2)
		play_button.text = "Play Animation" if not vis_control.animation_playing else "Pause Animation"

func _on_speed_slider_changed(value):
	if vis_control:
		vis_control.animation_speed = value
		var speed_label = vbox_container.get_child(vbox_container.get_child_count() - 1).get_child(0)
		speed_label.text = "Speed: " + str(snappedf(value, 0.1))		
