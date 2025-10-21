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
		"title": "Arrays and For Loops: Introduction",
		"text": [
			"Arrays are collections of values that allow you to store multiple items in a single variable.",
			"For loops are control structures that let you repeat code a specific number of times, making them perfect for working with arrays.",
			"Together, arrays and for loops form the backbone of data manipulation in programming.",
			"This info board will show you how to use these concepts to create visual elements like panels, grids, and 3D structures.",
			"We'll start with 1D arrays, move to 2D arrays, and finally explore 3D arrays, showing practical visualizations for each.",
			"\nCode Example:\n# Basic array declaration\nvar my_array = [1, 2, 3, 4, 5]\n\n# Basic for loop\nfor i in range(5):\n    print(my_array[i])\n\n# Alternative syntax (more Godot-like)\nfor item in my_array:\n    print(item)"
		],
		"visualization": "intro"
	},
	{
		"title": "1D Arrays: Creating a Row of Panels",
		"text": [
			"1D arrays are simple lists of values, with each value accessible by a single index.",
			"They're perfect for creating rows of UI elements, menu items, or any linear collection of objects.",
			"The animation shows how a for loop iterates through a 1D array to create a horizontal row of panels.",
			"Each panel's position is calculated based on its index in the array.",
			"This pattern is commonly used for toolbars, inventories, and other UI elements that display items in a row or column.",
			"\nCode Example:\nvar panel_data = [\"Item 1\", \"Item 2\", \"Item 3\", \"Item 4\", \"Item 5\"]\n\nfor i in range(panel_data.size()):\n    var panel = Panel.new()\n    panel.position.x = i * (panel_size.x + margin)\n    panel.text = panel_data[i]\n    add_child(panel)"
		],
		"visualization": "array_1d"
	},
	{
		"title": "2D Arrays: Building Data Tables and Grids",
		"text": [
			"2D arrays are arrays of arrays, creating a grid-like structure with rows and columns.",
			"Each value is accessed using two indices: one for the row and one for the column.",
			"They're ideal for creating data tables, game boards, tile maps, and grid-based UIs.",
			"The animation demonstrates how nested for loops iterate through a 2D array to build a grid of panels.",
			"This approach is used in spreadsheets, inventory systems, and any interface that arranges items in rows and columns.",
			"\nCode Example:\nvar grid_data = [\n    [1, 2, 3, 4],\n    [5, 6, 7, 8],\n    [9, 10, 11, 12]\n]\n\nfor y in range(grid_data.size()):\n    for x in range(grid_data[y].size()):\n        var panel = Panel.new()\n        panel.position = Vector2(x, y) * (size + margin)\n        panel.text = str(grid_data[y][x])\n        add_child(panel)"
		],
		"visualization": "array_2d"
	},
	{
		"title": "3D Arrays: Creating Volumetric Data Structures",
		"text": [
			"3D arrays add a third dimension to our data structure, allowing us to represent volumes of data.",
			"They're accessed using three indices: one each for x, y, and z coordinates.",
			"3D arrays are valuable for voxel-based games, 3D simulations, and complex data visualizations.",
			"The animation shows how triple-nested for loops can be used to create a 3D grid of objects.",
			"This pattern is used in 3D editors, scientific visualizations, and voxel-based games like Minecraft.",
			"\nCode Example:\nvar cube_data = []\nfor z in range(3):\n    var plane = []\n    for y in range(3):\n        var row = []\n        for x in range(3):\n            row.append(x + y*3 + z*9)\n        plane.append(row)\n    cube_data.append(plane)\n\nfor z in range(cube_data.size()):\n    for y in range(cube_data[z].size()):\n        for x in range(cube_data[z][y].size()):\n            var cube = Cube.new()\n            cube.position = Vector3(x, y, z) * (size + margin)\n            cube.value = cube_data[z][y][x]\n            add_child(cube)"
		],
		"visualization": "array_3d"
	},
	{
		"title": "Practical Applications and Advanced Techniques",
		"text": [
			"Arrays and loops can be combined with other programming concepts for powerful results:",
			"• Array methods like append(), erase(), and sort() let you manipulate data dynamically.",
			"• Dictionary arrays can store complex data with named properties.",
			"• Lambda functions can transform array data on the fly.",
			"• Array slicing allows you to work with specific portions of large datasets.",
			"These techniques are essential for creating dynamic UIs, procedural content, and data-driven applications.",
			"\nCode Example:\nvar numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]\nvar even_numbers = numbers.filter(func(n): return n % 2 == 0)\n\nvar inventory_grid = []\nfor y in range(4):\n    var row = []\n    for x in range(6):\n        row.append({\"position\": Vector2(x, y), \"item_id\": null, \"quantity\": 0})\n    inventory_grid.append(row)"
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
	var vis_scene = preload("res://commons/infoBoards/Arrays/ArrayVisualizationControl.tscn")

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
