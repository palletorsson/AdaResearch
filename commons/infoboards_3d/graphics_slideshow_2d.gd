extends Control

## Graphics Slideshow 2D - Navigate through all graphics boards in 2D
## Manual control to flip through topics

@export var show_topic_label: bool = true
@export var auto_advance: bool = false
@export var frame_duration: float = 5.0

var _all_topics = [
	"vectors", "arrays", "waves", "procedural",
	"point", "line", "triangle", "quad", "cube", "sphere",
	"cylinder", "torus", "polyhedra", "coordinatesystem"
]

var _current_topic_index = 0
var _display_control: Control = null
var _topic_label: Label = null

func _ready():
	# Set up full screen
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Create display control
	var GraphicsDisplayScene = load("res://commons/infoboards_3d/boards/GraphicsDisplay/GraphicsDisplayControl.tscn")
	_display_control = GraphicsDisplayScene.instantiate()
	_display_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_display_control.auto_advance = auto_advance
	_display_control.frame_duration = frame_duration
	add_child(_display_control)

	# Create topic label
	if show_topic_label:
		_topic_label = Label.new()
		_topic_label.add_theme_font_size_override("font_size", 32)
		_topic_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		_topic_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		_topic_label.add_theme_constant_override("outline_size", 8)
		_topic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_topic_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		_topic_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
		_topic_label.offset_top = 20
		_topic_label.offset_bottom = 80
		add_child(_topic_label)

	_set_current_topic()

func _set_current_topic():
	var topic = _all_topics[_current_topic_index]
	if _display_control and _display_control.has_method("set_topic"):
		_display_control.set_topic(topic)
		print("GraphicsSlideshow2D: Showing topic %d/%d: %s" % [_current_topic_index + 1, _all_topics.size(), topic])

	if _topic_label:
		_topic_label.text = "%s (%d/%d)" % [topic.capitalize(), _current_topic_index + 1, _all_topics.size()]

func next_topic():
	_current_topic_index = (_current_topic_index + 1) % _all_topics.size()
	_set_current_topic()

func prev_topic():
	_current_topic_index = (_current_topic_index - 1 + _all_topics.size()) % _all_topics.size()
	_set_current_topic()

func _input(event):
	# Allow keyboard navigation
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_RIGHT, KEY_D, KEY_SPACE:
				next_topic()
			KEY_LEFT, KEY_A:
				prev_topic()
			KEY_ESCAPE:
				queue_free()

# Grid system configuration
func apply_grid_config(config_data: Dictionary) -> void:
	print("GraphicsSlideshow2D: Applying grid config: %s" % config_data)

	# Optional: start at specific topic
	if config_data.has("start_topic"):
		var topic = str(config_data.start_topic).to_lower()
		var index = _all_topics.find(topic)
		if index >= 0:
			_current_topic_index = index
			call_deferred("_set_current_topic")

	# Optional: show/hide label
	if config_data.has("show_label"):
		show_topic_label = str(config_data.show_label).to_lower() == "true"
