extends Control

@onready var maze_node = $"../../MazeGenerator"
@onready var width_slider = $Panel/VBoxContainer/WidthSlider
@onready var height_slider = $Panel/VBoxContainer/HeightSlider
@onready var speed_slider = $Panel/VBoxContainer/SpeedSlider
@onready var restart_btn = $Panel/VBoxContainer/RestartButton

func _ready() -> void:
	_update_ui()

func _update_ui() -> void:
	if not maze_node: return
	width_slider.value = maze_node.maze_width
	height_slider.value = maze_node.maze_height
	speed_slider.value = maze_node.generation_speed

func _on_restart_pressed() -> void:
	# Update config
	maze_node.maze_width = int(width_slider.value)
	maze_node.maze_height = int(height_slider.value)
	maze_node.generation_speed = max(0.01, 0.55 - speed_slider.value) # Invert/Scale
	
	# Restart
	maze_node.initialize_maze()
	maze_node.create_maze_visuals()
	maze_node.start_generation()

func _on_width_changed(value) -> void:
	$Panel/VBoxContainer/WidthLabel.text = "Width: %d" % int(value)

func _on_height_changed(value) -> void:
	$Panel/VBoxContainer/HeightLabel.text = "Height: %d" % int(value)

func _on_speed_changed(value) -> void:
	pass # Only applied on restart for now or realtime if we link it
	maze_node.generation_speed = max(0.01, 0.55 - value)
