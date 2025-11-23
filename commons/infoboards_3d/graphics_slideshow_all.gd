extends "res://addons/godot-xr-tools/objects/viewport_2d_in_3d.gd"

## Graphics Slideshow All - Navigate through all graphics boards
## Manual control to flip through topics

var _all_topics = [
	"vectors", "arrays", "waves", "procedural",
	"point", "line", "triangle", "quad", "cube", "sphere",
	"cylinder", "torus", "polyhedra", "coordinatesystem"
]

var _current_topic_index = 0

func _ready():
	super._ready()
	_set_current_topic()

func _set_current_topic():
	var topic = _all_topics[_current_topic_index]
	if scene_node and scene_node.has_method("set_topic"):
		scene_node.set_topic(topic)
		print("GraphicsSlideshowAll: Showing topic %d/%d: %s" % [_current_topic_index + 1, _all_topics.size(), topic])

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
			KEY_RIGHT, KEY_D:
				next_topic()
			KEY_LEFT, KEY_A:
				prev_topic()

# Grid system configuration
func apply_grid_config(config_data: Dictionary) -> void:
	print("GraphicsSlideshowAll: Applying grid config: %s" % config_data)

	# Optional: start at specific topic
	if config_data.has("start_topic"):
		var topic = str(config_data.start_topic).to_lower()
		var index = _all_topics.find(topic)
		if index >= 0:
			_current_topic_index = index
			call_deferred("_set_current_topic")
