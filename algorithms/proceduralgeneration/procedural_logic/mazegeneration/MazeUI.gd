extends Node3D

const VRSlider = preload("res://commons/interactables/slider_horizontal.tscn")
const VRButton = preload("res://commons/interactables/push_button.tscn")

var maze_node: Node
var width_slider: Node3D
var height_slider: Node3D
var speed_slider: Node3D
var status_label: Label3D

func _ready() -> void:
	maze_node = get_node_or_null("../../MazeGenerator")

	# Status label
	status_label = Label3D.new()
	status_label.position = Vector3(0, 0.5, 0)
	status_label.text = "Maze Generator"
	status_label.font_size = 48
	status_label.modulate = Color.WHITE
	add_child(status_label)

	# Width slider
	width_slider = VRSlider.instantiate()
	width_slider.position = Vector3(0, 0.3, 0)
	add_child(width_slider)
	width_slider.set_param_name("Width")
	width_slider.slider_moved.connect(_on_width_changed)

	# Height slider
	height_slider = VRSlider.instantiate()
	height_slider.position = Vector3(0, 0.18, 0)
	add_child(height_slider)
	height_slider.set_param_name("Height")
	height_slider.slider_moved.connect(_on_height_changed)

	# Speed slider
	speed_slider = VRSlider.instantiate()
	speed_slider.position = Vector3(0, 0.06, 0)
	add_child(speed_slider)
	speed_slider.set_param_name("Speed")
	speed_slider.slider_moved.connect(_on_speed_changed)

	# Generate button
	var gen_btn = VRButton.instantiate()
	gen_btn.position = Vector3(0, -0.1, 0)
	add_child(gen_btn)
	var gen_area = gen_btn.get_node_or_null("InteractableAreaButton")
	if gen_area:
		gen_area.button_pressed.connect(_on_restart_pressed)

	_update_ui()

func _update_ui() -> void:
	if not maze_node:
		return
	width_slider.set_normalized_value(remap(maze_node.maze_width, 3, 30, 0.0, 1.0))
	height_slider.set_normalized_value(remap(maze_node.maze_height, 3, 30, 0.0, 1.0))
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
