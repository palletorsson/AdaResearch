# UniversalInfoBoard.gd
# UNIVERSAL TEMPLATE - Works for ANY InfoBoard by loading from JSON
# Just set the board_id in the inspector or when instantiating
extends Control

# Font resource
const ROBOTO_FONT = preload("res://commons/font/Roboto-VariableFont_wdth,wght.ttf")

# MAIN CONFIGURATION - Set this to load different board content
@export var board_id: String = "point"  # Change in inspector or via code
@export var auto_load_on_ready: bool = true  # Load content automatically

# Variables for interactive elements
var current_page := 0
var total_pages := 0
var animation_speed := 1.0
var animation_playing := true
var animation_time := 0.0
var vis_control: Control

# Content loaded from JSON
var page_content: Array = []
var board_meta: Dictionary = {}

# Node references
@onready var hbox_container = $MarginContainer/HBoxContainer
@onready var left_panel = $MarginContainer/HBoxContainer/LeftPanel
@onready var text_container = $MarginContainer/HBoxContainer/LeftPanel/TextScrollContainer/CodeContainer/MarginContainer/VBoxContainer
@onready var vis_container = $MarginContainer/HBoxContainer/VisualizationContainer/MarginContainer/VBoxContainer

@onready var title_label = $MarginContainer/HBoxContainer/LeftPanel/Title
@onready var prev_button = $MarginContainer/HBoxContainer/LeftPanel/NavigationButtons/PrevButton
@onready var next_button = $MarginContainer/HBoxContainer/LeftPanel/NavigationButtons/NextButton
@onready var navigation_buttons = $MarginContainer/HBoxContainer/LeftPanel/NavigationButtons

func _ready():
	if auto_load_on_ready:
		load_board(board_id)

	setup_ui()

# PUBLIC API - Load a specific board by ID
func load_board(new_board_id: String) -> bool:
	board_id = new_board_id

	# Load content from JSON
	page_content = InfoBoardContentLoader.get_pages(board_id)
	board_meta = InfoBoardContentLoader.get_board_meta(board_id)
	total_pages = page_content.size()

	if page_content.is_empty():
		push_error("UniversalInfoBoard: No content found for board ID '%s'" % board_id)
		show_error_content()
		return false

	print("UniversalInfoBoard: Loaded '%s - %s' (%d pages)" % [board_meta.title, board_meta.subtitle, total_pages])

	# Reset to first page
	current_page = 0
	if is_node_ready():
		update_page()

	return true

# Setup UI elements
func setup_ui():
	# Connect navigation buttons
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
	if page_content.is_empty():
		return

	# Clear previous content
	for child in text_container.get_children():
		child.queue_free()

	# Get current page data from loaded content
	var current_page_data = page_content[current_page]

	# Update title
	title_label.text = current_page_data.get("title", "Untitled")

	# Get text array from page data
	var text_lines = current_page_data.get("text", [])

	for text in text_lines:
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

	# Update visualization
	update_visualization(current_page_data.get("visualization", ""))

	# Update navigation buttons
	prev_button.disabled = (current_page == 0)
	next_button.disabled = (current_page == total_pages - 1)

func update_visualization(vis_type: String):
	# Clear previous visualization
	if vis_control and is_instance_valid(vis_control):
		vis_control.queue_free()
		vis_control = null

	if vis_type.is_empty():
		return

	# Try to load visualization scene for this board
	var vis_scene_path = get_visualization_scene_path(board_id)

	if not ResourceLoader.exists(vis_scene_path):
		push_warning("UniversalInfoBoard: Visualization scene not found: %s" % vis_scene_path)
		return

	var vis_scene = load(vis_scene_path)
	if vis_scene == null:
		push_warning("UniversalInfoBoard: Failed to load visualization scene: %s" % vis_scene_path)
		return

	vis_control = vis_scene.instantiate()

	# Set visualization type if the control supports it
	if "visualization_type" in vis_control:
		vis_control.visualization_type = vis_type

	# Set animation properties
	if "animation_time" in vis_control:
		vis_control.animation_time = animation_time
	if "animation_speed" in vis_control:
		vis_control.animation_speed = animation_speed
	if "animation_playing" in vis_control:
		vis_control.animation_playing = animation_playing

	# Set up sizing flags
	vis_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vis_control.size_flags_vertical = Control.SIZE_EXPAND_FILL

	vis_container.add_child(vis_control)

# Get the visualization scene path for a board
func get_visualization_scene_path(board_id_param: String) -> String:
	# Convention: boards/{BoardName}/{BoardName}VisualizationControl.tscn
	# Examples:
	# - point -> boards/Point/PointVisualizationControl.tscn
	# - line -> boards/Line/LineVisualizationControl.tscn

	var capitalized = board_id_param.capitalize().replace(" ", "")
	return "res://commons/infoboards_3d/boards/%s/%sVisualizationControl.tscn" % [capitalized, capitalized]

func show_error_content():
	page_content = [{
		"title": "Error Loading Content",
		"text": [
			"Failed to load content for board: %s" % board_id,
			"",
			"Please check:",
			"• Board ID exists in infoboard_content.json",
			"• JSON syntax is valid",
			"• Content is properly formatted"
		],
		"visualization": ""
	}]
	total_pages = 1
	current_page = 0
	update_page()

# Navigation
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
		if "animation_playing" in vis_control:
			vis_control.animation_playing = animation_playing

func _on_speed_slider_changed(value):
	animation_speed = value

	if vis_control and is_instance_valid(vis_control):
		if "animation_speed" in vis_control:
			vis_control.animation_speed = value

	var speed_label = left_panel.get_child(left_panel.get_child_count() - 1).get_child(0)
	speed_label.text = "Speed: " + str(snappedf(value, 0.1))

# PUBLIC API - Change to different board at runtime
func switch_to_board(new_board_id: String) -> bool:
	return load_board(new_board_id)

# PUBLIC API - Get current board info
func get_current_board_id() -> String:
	return board_id

func get_current_page_number() -> int:
	return current_page

func get_total_pages() -> int:
	return total_pages

func get_board_metadata() -> Dictionary:
	return board_meta
