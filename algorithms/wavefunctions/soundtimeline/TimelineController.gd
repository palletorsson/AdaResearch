# TimelineController.gd - VR timeline controls using push buttons
extends Control

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
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("TIMELINE", [
		[{"type": "button", "label": "REC"}, {"type": "button", "label": "PLAY"},
		 {"type": "button", "label": "STOP"}, {"type": "button", "label": "CLEAR"}],
	])
	panel.position = Vector3(0, 0, 0)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	record_button = panel.find_child("Btn_0", true, false)
	play_button = panel.find_child("Btn_1", true, false)
	stop_button = panel.find_child("Btn_2", true, false)
	clear_button = panel.find_child("Btn_3", true, false)

	if record_button:
		var area = record_button.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_on_record_pressed)
	if play_button:
		var area = play_button.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_on_play_pressed)
	if stop_button:
		var area = stop_button.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_on_stop_pressed)
	if clear_button:
		var area = clear_button.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_on_clear_pressed)

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
