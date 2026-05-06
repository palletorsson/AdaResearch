extends Node3D

var maze_node: Node
var _control_panel: Node3D
var width_slider: Node
var height_slider: Node
var speed_slider: Node

func _ready() -> void:
	maze_node = get_node_or_null("../../MazeGenerator")

	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("MAZE GEN", [
		[
			{"type": "slider_h", "label": "WIDTH", "default": 0.5},
			{"type": "slider_h", "label": "HEIGHT", "default": 0.5},
			{"type": "slider_h", "label": "SPEED", "default": 0.5},
		],
		[
			{"type": "button", "label": "GENERATE"},
		],
	])
	_control_panel.position = Vector3(0, 0.35, 0)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	width_slider = _control_panel.find_child("Param_0", true, false)
	height_slider = _control_panel.find_child("Param_1", true, false)
	speed_slider = _control_panel.find_child("Param_2", true, false)

	if width_slider:
		width_slider.slider_moved.connect(_on_width_changed)
	if height_slider:
		height_slider.slider_moved.connect(_on_height_changed)
	if speed_slider:
		speed_slider.slider_moved.connect(_on_speed_changed)

	var gen_btn = _control_panel.find_child("Btn_0", true, false)
	if gen_btn:
		var area = gen_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_restart_pressed())

	_update_ui()

func _update_ui() -> void:
	if not maze_node:
		return
	if width_slider:
		width_slider.set_normalized_value(remap(maze_node.maze_width, 3, 30, 0.0, 1.0))
	if height_slider:
		height_slider.set_normalized_value(remap(maze_node.maze_height, 3, 30, 0.0, 1.0))
	if speed_slider:
		speed_slider.set_normalized_value(remap(maze_node.generation_speed, 0.01, 0.54, 0.0, 1.0))

func _on_restart_pressed() -> void:
	if not maze_node:
		return
	maze_node.maze_width = int(remap(width_slider.get_normalized_value(), 0.0, 1.0, 3, 30))
	maze_node.maze_height = int(remap(height_slider.get_normalized_value(), 0.0, 1.0, 3, 30))
	maze_node.generation_speed = max(0.01, 0.55 - remap(speed_slider.get_normalized_value(), 0.0, 1.0, 0.0, 0.54))
	maze_node.initialize_maze()
	maze_node.create_maze_visuals()
	maze_node.start_generation()

func _on_width_changed(_value: float) -> void:
	pass

func _on_height_changed(_value: float) -> void:
	pass

func _on_speed_changed(_value: float) -> void:
	if not maze_node:
		return
	maze_node.generation_speed = max(0.01, 0.55 - remap(speed_slider.get_normalized_value(), 0.0, 1.0, 0.0, 0.54))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass
