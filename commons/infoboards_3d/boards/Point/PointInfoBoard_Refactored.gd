# PointInfoBoard_Refactored.gd
# REFACTORED VERSION - Uses centralized content from JSON
# This is an example of how to migrate from embedded content to centralized content
extends Control

# Font resource
const ROBOTO_FONT = preload("res://commons/font/Roboto-VariableFont_wdth,wght.ttf")

# Board identifier for content lookup
const BOARD_ID = "point"

# Variables for interactive elements
var current_page := 0
var total_pages := 0  # Will be set from loaded content
var animation_speed := 1.0
var animation_playing := true
var animation_time := 0.0
var vis_control: Control

# Content loaded from JSON (instead of hardcoded)
var page_content: Array = []

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
	# CHANGE: Load content from centralized JSON instead of hardcoded array
	load_content_from_json()

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

# NEW FUNCTION: Load content from centralized JSON
func load_content_from_json() -> void:
	# Get pages from the content loader
	page_content = InfoBoardContentLoader.get_pages(BOARD_ID)
	total_pages = page_content.size()

	if page_content.is_empty():
		push_error("PointInfoBoard: No content found for board ID '%s'" % BOARD_ID)
		# Fallback to minimal content
		page_content = [{
			"title": "Error",
			"text": ["Content not found for board: %s" % BOARD_ID],
			"visualization": "origin"
		}]
		total_pages = 1
		return

	# Optional: Load and display board metadata
	var meta = InfoBoardContentLoader.get_board_meta(BOARD_ID)
	print("Loaded InfoBoard: %s - %s (%d pages)" % [meta.title, meta.subtitle, total_pages])

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

	# CHANGE: Access content from loaded JSON structure
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

	if vis_control and is_instance_valid(vis_control):
		vis_control.queue_free()
		vis_control = null

	# Load and instantiate the visualization control scene
	var vis_scene = preload("res://commons/infoboards_3d/boards/Point/PointVisualizationControl.tscn")
	vis_control = vis_scene.instantiate()

	# CHANGE: Get visualization type from loaded content
	vis_control.visualization_type = current_page_data.get("visualization", "origin")
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
