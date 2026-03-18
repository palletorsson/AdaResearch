# TimelineController.gd - VR timeline controls using push buttons
extends Node3D

# VR push button scene
const PushButtonScene = preload("res://commons/interactables/push_button.tscn")

# Button references
var record_button: Node3D
var play_button: Node3D
var stop_button: Node3D
var clear_button: Node3D

# Timeline visualizer
var timeline_visualizer: SoundTimelineVisualizer

# Button labels
var _record_label: Label3D
var _play_label: Label3D

func _ready() -> void:
	# Create the timeline visualizer
	timeline_visualizer = SoundTimelineVisualizer.new()
	add_child(timeline_visualizer)
	timeline_visualizer.position = Vector3(0, -0.05, 0)

	# Create VR push buttons
	_create_buttons()

	# Start with recording enabled
	timeline_visualizer.start_recording()

func _create_buttons() -> void:
	"""Create VR push button instances for transport controls"""
	var button_spacing = 0.08
	var button_y = 0.0

	# Record button
	record_button = PushButtonScene.instantiate()
	record_button.position = Vector3(0, button_y, 0)
	add_child(record_button)
	_record_label = Label3D.new()
	_record_label.text = "REC"
	_record_label.font_size = 32
	_record_label.pixel_size = 0.001
	_record_label.no_depth_test = false
	_record_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_record_label.modulate = Color.RED
	_record_label.position = Vector3(0, 0.03, 0.01)
	record_button.add_child(_record_label)
	var rec_area = record_button.get_node_or_null("InteractableAreaButton")
	if rec_area:
		rec_area.button_pressed.connect(_on_record_pressed)

	# Play button
	play_button = PushButtonScene.instantiate()
	play_button.position = Vector3(button_spacing, button_y, 0)
	add_child(play_button)
	_play_label = Label3D.new()
	_play_label.text = "PLAY"
	_play_label.font_size = 32
	_play_label.pixel_size = 0.001
	_play_label.no_depth_test = false
	_play_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_play_label.modulate = Color.GREEN
	_play_label.position = Vector3(0, 0.03, 0.01)
	play_button.add_child(_play_label)
	var play_area = play_button.get_node_or_null("InteractableAreaButton")
	if play_area:
		play_area.button_pressed.connect(_on_play_pressed)

	# Stop button
	stop_button = PushButtonScene.instantiate()
	stop_button.position = Vector3(button_spacing * 2, button_y, 0)
	add_child(stop_button)
	var stop_label = Label3D.new()
	stop_label.text = "STOP"
	stop_label.font_size = 32
	stop_label.pixel_size = 0.001
	stop_label.no_depth_test = false
	stop_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	stop_label.modulate = Color.WHITE
	stop_label.position = Vector3(0, 0.03, 0.01)
	stop_button.add_child(stop_label)
	var stop_area = stop_button.get_node_or_null("InteractableAreaButton")
	if stop_area:
		stop_area.button_pressed.connect(_on_stop_pressed)

	# Clear button
	clear_button = PushButtonScene.instantiate()
	clear_button.position = Vector3(button_spacing * 3, button_y, 0)
	add_child(clear_button)
	var clear_label = Label3D.new()
	clear_label.text = "CLEAR"
	clear_label.font_size = 32
	clear_label.pixel_size = 0.001
	clear_label.no_depth_test = false
	clear_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	clear_label.modulate = Color.YELLOW
	clear_label.position = Vector3(0, 0.03, 0.01)
	clear_button.add_child(clear_label)
	var clear_area = clear_button.get_node_or_null("InteractableAreaButton")
	if clear_area:
		clear_area.button_pressed.connect(_on_clear_pressed)

func _on_record_pressed() -> void:
	if timeline_visualizer.is_recording:
		timeline_visualizer.stop_recording()
		_record_label.text = "REC"
		_record_label.modulate = Color.RED
	else:
		timeline_visualizer.start_recording()
		_record_label.text = "STOP REC"
		_record_label.modulate = Color(1, 0.3, 0.3)

func _on_play_pressed() -> void:
	if timeline_visualizer.is_playing and not timeline_visualizer.is_recording:
		timeline_visualizer.stop_playback()
		_play_label.text = "PLAY"
		_play_label.modulate = Color.GREEN
	else:
		timeline_visualizer.start_playback()
		_play_label.text = "PAUSE"
		_play_label.modulate = Color(0.3, 1.0, 0.3)

func _on_stop_pressed() -> void:
	timeline_visualizer.stop_playback()
	timeline_visualizer.stop_recording()

	_play_label.text = "PLAY"
	_play_label.modulate = Color.GREEN
	_record_label.text = "REC"
	_record_label.modulate = Color.RED

func _on_clear_pressed() -> void:
	timeline_visualizer.clear_timeline()
	_on_stop_pressed()

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
