extends "res://addons/godot-xr-tools/objects/viewport_2d_in_3d.gd"

## Graphics Monitor - Extends viewport_2d_in_3d for grid system integration
## Displays visualization graphics with topic configuration support

# Grid system configuration
func apply_grid_config(config_data: Dictionary) -> void:
	print("GraphicsMonitor: Applying grid config: %s" % config_data)

	# Check for topic configuration
	var valid_topics = ["vectors", "forces", "arrays", "waves", "randomness", "procedural",
		"unitcircle", "point", "line", "triangle", "quad", "cube", "sphere",
		"cylinder", "torus", "polyhedra", "coordinatesystem"]

	if config_data.has("topic"):
		var topic = str(config_data.topic).to_lower()
		if topic in valid_topics:
			_set_display_topic(topic)

	# Check for shorthand topic (e.g., graphics_monitor#vectors)
	for key in config_data.keys():
		var key_str = str(key).to_lower()
		if key_str in valid_topics:
			_set_display_topic(key_str)
			break

	# Optional: frame duration config
	if config_data.has("duration"):
		if scene_node and "frame_duration" in scene_node:
			scene_node.frame_duration = float(config_data.duration)

	# Optional: auto-advance config
	if config_data.has("auto"):
		if scene_node and "auto_advance" in scene_node:
			scene_node.auto_advance = str(config_data.auto).to_lower() == "true"

func _set_display_topic(topic: String) -> void:
	# Set topic on the scene node if it exists
	if scene_node and scene_node.has_method("set_topic"):
		scene_node.set_topic(topic)
	elif scene_node and "visualization_topic" in scene_node:
		scene_node.visualization_topic = topic
