# AlgorithmInfoBoardBase.gd
# Base controller for handheld algorithm info boards
# Manages page navigation, content display, and visualization switching
extends Control
class_name AlgorithmInfoBoardBase

# VR input handling
var vr_input_handler: VRInfoBoardInput

# Signals
signal page_changed(page_index: int)
signal animation_toggled(is_playing: bool)

# Export parameters
@export var board_title: String = "Algorithm Info Board"
@export var category_color: Color = Color(0.3, 0.6, 0.9, 1.0)
@export var auto_advance: bool = false
@export var auto_advance_delay: float = 10.0

# Node references (to be connected in ready)
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleBar/Title
@onready var page_counter: Label = $MarginContainer/VBoxContainer/TitleBar/PageCounter
@onready var text_scroll: ScrollContainer = $MarginContainer/VBoxContainer/ContentArea/TextScroll
@onready var text_container: VBoxContainer = $MarginContainer/VBoxContainer/ContentArea/TextScroll/TextContainer
@onready var vis_container: Control = $MarginContainer/VBoxContainer/ContentArea/VisualizationContainer
@onready var prev_button: Button = $MarginContainer/VBoxContainer/NavigationBar/PrevButton
@onready var next_button: Button = $MarginContainer/VBoxContainer/NavigationBar/NextButton
@onready var play_pause_button: Button = $MarginContainer/VBoxContainer/NavigationBar/PlayPauseButton

# State variables
var current_page: int = 0
var total_pages: int = 0
var page_content: Array = []
var visualization_control: Control = null
var animation_playing: bool = true
var auto_advance_timer: float = 0.0

# Content structure:
# page_content = [
#   {
#     "title": "Page Title",
#     "text": ["Paragraph 1", "Paragraph 2", ...],
#     "visualization": "visualization_type"
#   }
# ]

func _ready():
	# Apply theme color
	apply_category_theme()

	# Connect button signals
	if prev_button:
		prev_button.pressed.connect(_on_prev_pressed)
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	if play_pause_button:
		play_pause_button.pressed.connect(_on_play_pause_pressed)

	# Initialize content (override in child classes)
	initialize_content()

	# Set total pages
	total_pages = page_content.size()

	# Display first page
	if total_pages > 0:
		update_page()
	
	# Setup VR input handling
	_setup_vr_input()

func _process(delta):
	# Auto advance
	if auto_advance and animation_playing and current_page < total_pages - 1:
		auto_advance_timer += delta
		if auto_advance_timer >= auto_advance_delay:
			auto_advance_timer = 0.0
			next_page()

# Virtual function - override in child classes to populate page_content
func initialize_content() -> void:
	# Example content - override this
	page_content = [
		{
			"title": "Welcome to Algorithm Info Board",
			"text": [
				"This is a handheld 3D info board for exploring algorithms.",
				"Navigate through pages using the Previous and Next buttons.",
				"Each page can include text and interactive visualizations."
			],
			"visualization": "default"
		}
	]

# Apply theme based on category color
func apply_category_theme() -> void:
	if title_label:
		title_label.add_theme_color_override("font_color", category_color.lightened(0.3))

# Page navigation
func next_page() -> void:
	if current_page < total_pages - 1:
		current_page += 1
		update_page()
		auto_advance_timer = 0.0

func prev_page() -> void:
	if current_page > 0:
		current_page -= 1
		update_page()
		auto_advance_timer = 0.0

func goto_page(page_index: int) -> void:
	if page_index >= 0 and page_index < total_pages:
		current_page = page_index
		update_page()
		auto_advance_timer = 0.0

# Update display for current page
func update_page() -> void:
	if current_page < 0 or current_page >= page_content.size():
		return

	var page = page_content[current_page]

	# Update title
	if title_label:
		title_label.text = page.get("title", board_title)

	# Update page counter
	if page_counter:
		page_counter.text = "%d / %d" % [current_page + 1, total_pages]

	# Update text content
	update_text_content(page.get("text", []))

	# Update visualization
	update_visualization(page.get("visualization", "none"))

	# Update navigation buttons
	if prev_button:
		prev_button.disabled = (current_page == 0)
	if next_button:
		next_button.disabled = (current_page == total_pages - 1)

	# Reset scroll to top
	if text_scroll:
		text_scroll.scroll_vertical = 0

	# Emit signal
	emit_signal("page_changed", current_page)

# Update text container with new content
func update_text_content(texts: Array) -> void:
	if not text_container:
		return

	# Clear existing content
	for child in text_container.get_children():
		child.queue_free()

	# Add new content
	var roboto_regular = load("res://commons/font/static/Roboto-Regular.ttf")

	for text in texts:
		var label = Label.new()
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
		label.add_theme_font_override("font", roboto_regular)
		label.add_theme_font_size_override("font_size", 42)
		label.add_theme_constant_override("line_spacing", 12)
		text_container.add_child(label)

		# Add spacing between paragraphs
		if text_container.get_child_count() > 1:
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(0, 30)
			text_container.add_child(spacer)
			text_container.move_child(spacer, text_container.get_child_count() - 2)

# Update visualization (virtual - override in child classes)
func update_visualization(vis_type: String) -> void:
	# Clear existing visualization
	if visualization_control and is_instance_valid(visualization_control):
		visualization_control.queue_free()
		visualization_control = null

	# Create new visualization based on type
	visualization_control = create_visualization(vis_type)

	if visualization_control:
		vis_container.add_child(visualization_control)

		# Set animation state
		if visualization_control.has_method("set_animation_playing"):
			visualization_control.set_animation_playing(animation_playing)

# Virtual function - override to create specific visualizations
func create_visualization(vis_type: String) -> Control:
	# Return null by default - child classes should override
	return null

# Toggle animation
func toggle_animation() -> void:
	animation_playing = !animation_playing

	if play_pause_button:
		play_pause_button.text = "Play" if not animation_playing else "Pause"

	if visualization_control and visualization_control.has_method("set_animation_playing"):
		visualization_control.set_animation_playing(animation_playing)

	emit_signal("animation_toggled", animation_playing)

# Button callbacks
func _on_prev_pressed() -> void:
	prev_page()

func _on_next_pressed() -> void:
	next_page()

func _on_play_pause_pressed() -> void:
	toggle_animation()

# Utility functions
func get_current_page_index() -> int:
	return current_page

func get_total_pages() -> int:
	return total_pages

func is_animation_playing() -> bool:
	return animation_playing

func get_page_title(page_index: int) -> String:
	if page_index >= 0 and page_index < page_content.size():
		return page_content[page_index].get("title", "")
	return ""

# VR input handling
func _setup_vr_input():
	"""Setup VR input handling for scrolling and navigation"""
	# Create VR input handler
	vr_input_handler = VRInfoBoardInput.new()
	add_child(vr_input_handler)
	
	# Configure VR input
	vr_input_handler.set_target_scroll_container(text_scroll)
	vr_input_handler.set_info_board_base(self)
	vr_input_handler.set_scroll_sensitivity(0.15)  # Adjust scroll sensitivity
	vr_input_handler.set_haptic_feedback(true, 0.3)
	
	# Connect VR input signals
	vr_input_handler.scroll_changed.connect(_on_vr_scroll_changed)
	vr_input_handler.vr_input_detected.connect(_on_vr_input_detected)
	
	print("AlgorithmInfoBoardBase: VR input handler configured")

func _on_vr_scroll_changed(scroll_value: float):
	"""Handle VR scroll changes - override in child classes for custom behavior"""
	pass

func _on_vr_input_detected(controller: XRController3D):
	"""Handle VR input detection - override in child classes for custom behavior"""
	print("AlgorithmInfoBoardBase: VR input detected from controller: ", controller.name)
