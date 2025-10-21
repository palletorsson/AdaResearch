# PointInfoBoard.gd
# Info board for Point concepts - the fundamental building block
extends Control

# Font resource
const ROBOTO_FONT = preload("res://commons/font/Roboto-VariableFont_wdth,wght.ttf")

# Variables for interactive elements
var current_page := 0
var total_pages := 5
var animation_speed := 1.0
var animation_playing := true
var animation_time := 0.0
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
		"title": "The Point: The Atom of Space",
		"text": [
			"AXIOM 1: A point in 3D space is a vector defining a position (x, y, z).",
			"",
			"CODE:[point]",
			"var point_position_zero = Vector3(0, 0, 0)",
		],
		"visualization": "origin"
	},
	{
		"title": "Visualizing the Point",
		"text": [
			"AXIOM 2: A visible point can be represented by a small sphere at its designated position.",
			"",
			"CODE:[Mesh]",
			"var sphere_mesh = SphereMesh.new()",
			"var radius = 0.01  # one centimeter",
			"sphere_mesh.radius = radius",
			"sphere_mesh.height = radius * 2  # height is diameter"
		],
		"visualization": "origin"
	},
	{
		"title": "Instantiating the Point",
		"text": [
			"AXIOM 2.5: A mesh must be instantiated into the scene tree to exist in the world.",
			"",
			"CODE:[Instance]",
			"var mesh_instance = MeshInstance3D.new()",
			"mesh_instance.mesh = sphere_mesh",
			"mesh_instance.position = point_position",
			"add_child(mesh_instance)",
			"",
			"The add_child() call integrates the point into the scene tree, making it part of the rendered world.",
			
		],
		"visualization": "origin"
	},
	{
		"title": "Labeling the Point",
		"text": [
			"AXIOM 3: The identity of a point is represented as a text label close to the point.",
			"",
			"CODE:",
			"var label_3d = Label3D.new()",
			"label_3d.text = str(point_position)",
			"var offset = Vector3(0, 0.15, 0)",
			"label_3d.position = point_position + offset",
			"label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED",
			"add_child(label_3d)",
			"",
			"Billboard mode makes the label always face the camera,",
			"ensuring readability from any angle."
		],
		"visualization": "labels"
	},
	{
		"title": "Dynamic Updates",
		"text": [
			"AXIOM 4: The text label must update when the point's position changes.",
			"",
			"CODE:",
			"func _process(delta):",
			"\tlabel_3d.text = str(point_position)",
			"\tlabel_3d.position = point_position + label_offset",
			""
			
		],
		"visualization": "dynamic"
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
	speed_label.text = "Speed: 1.0"
	speed_label.add_theme_font_override("font", ROBOTO_FONT)
	speed_label.add_theme_font_size_override("font_size", 14)
	var speed_slider = HSlider.new()
	speed_slider.min_value = 0.5
	speed_slider.max_value = 3.0
	speed_slider.step = 0.1
	speed_slider.value = animation_speed
	speed_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_slider.value_changed.connect(_on_speed_slider_changed)
	
	speed_container.add_child(speed_label)
	speed_container.add_child(speed_slider)
	left_panel.add_child(speed_container)
	
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

func update_page():
	# Clear previous content
	for child in text_container.get_children():
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
	var vis_scene = preload("res://commons/infoboards_3d/boards/Point/PointVisualizationControl.tscn")
	vis_control = vis_scene.instantiate()
	vis_control.visualization_type = page_content[current_page]["visualization"]
	vis_control.animation_time = animation_time
	vis_control.animation_speed = animation_speed

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
