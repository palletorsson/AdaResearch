# LineInfoBoard.gd
# Info board for Line concepts - connecting two points
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
		"title": "The Line: Connecting Points",
		"text": [
			"A line connects two points in space, creating direction and distance.",
			"",
			"In 3D graphics, a line is defined by two endpoints: a start and an end.",
			"The space between them forms a path we can visualize and measure.",
			"",
			"AXIOM 1: A line is defined by two points in space.",
			"",
			"CODE:",
			"var point_a = Vector3(0, 0, 0)",
			"var point_b = Vector3(1, 1, 0)",
			"",
			"These two points define a line segment from origin to (1,1,0).",
			"",
			"The vector from A to B is: direction = point_b - point_a",
			"The length of the line is: distance = direction.length()"
		],
		"visualization": "basic_line"
	},
	{
		"title": "Drawing Lines",
		"text": [
			"Godot provides multiple ways to visualize lines in 3D space.",
			"",
			"METHOD 1: ImmediateMesh (Simple, flexible)",
			"",
			"CODE:",
			"var mesh_instance = MeshInstance3D.new()",
			"var immediate_mesh = ImmediateMesh.new()",
			"mesh_instance.mesh = immediate_mesh",
			"",
			"immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)",
			"immediate_mesh.surface_add_vertex(point_a)",
			"immediate_mesh.surface_add_vertex(point_b)",
			"immediate_mesh.surface_end()",
			"",
			"add_child(mesh_instance)",
			"",
			"This creates a single line from point A to point B."
		],
		"visualization": "drawing_lines"
	},
	{
		"title": "Line Direction and Magnitude",
		"text": [
			"A line has both direction and magnitude (length).",
			"",
			"AXIOM 2: The direction vector points from start to end.",
			"",
			"CODE:",
			"var direction = (point_b - point_a).normalized()",
			"var distance = point_a.distance_to(point_b)",
			"",
			"# Move along the line",
			"var t = 0.5  # halfway",
			"var midpoint = point_a + direction * distance * t",
			"",
			"The parameter 't' (0 to 1) lets us find any point along the line:",
			"• t = 0.0 → point_a (start)",
			"• t = 0.5 → midpoint",
			"• t = 1.0 → point_b (end)",
			"",
			"This is called linear interpolation or 'lerp'."
		],
		"visualization": "direction_magnitude"
	},
	{
		"title": "Cylinders as Lines",
		"text": [
			"For thicker, more visible lines, we can use cylinders.",
			"",
			"AXIOM 3: A cylinder can represent a thick line segment.",
			"",
			"CODE:",
			"var cylinder = MeshInstance3D.new()",
			"var cylinder_mesh = CylinderMesh.new()",
			"cylinder_mesh.height = distance",
			"cylinder_mesh.top_radius = 0.02  # thickness",
			"cylinder_mesh.bottom_radius = 0.02",
			"cylinder.mesh = cylinder_mesh",
			"",
			"# Position at midpoint",
			"cylinder.position = (point_a + point_b) / 2.0",
			"",
			"# Rotate to align with direction",
			"cylinder.look_at_from_position(",
			"    cylinder.position, point_b, Vector3.UP",
			")",
			"",
			"add_child(cylinder)"
		],
		"visualization": "cylinder_lines"
	},
	{
		"title": "Multiple Lines and Paths",
		"text": [
			"Lines can connect multiple points to create paths and shapes.",
			"",
			"AXIOM 4: A sequence of connected lines forms a path.",
			"",
			"CODE:",
			"var points = [",
			"    Vector3(0, 0, 0),",
			"    Vector3(1, 1, 0),",
			"    Vector3(2, 0.5, 0),",
			"    Vector3(3, 1.5, 0)",
			"]",
			"",
			"immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)",
			"for point in points:",
			"    immediate_mesh.surface_add_vertex(point)",
			"immediate_mesh.surface_end()",
			"",
			"LINE_STRIP connects consecutive points with lines.",
			"LINES requires pairs of points (every 2 vertices = 1 line).",
			"",
			"Paths are fundamental to curves, splines, and trajectories."
		],
		"visualization": "multiple_lines"
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
	var vis_scene = preload("res://commons/infoboards_3d/boards/Line/LineVisualizationControl.tscn")
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

