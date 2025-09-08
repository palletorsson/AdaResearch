# TimelineController.gd
extends Control

# UI References
@onready var record_button = $VBoxContainer/ControlPanel/RecordButton
@onready var play_button = $VBoxContainer/ControlPanel/PlayButton
@onready var stop_button = $VBoxContainer/ControlPanel/StopButton
@onready var clear_button = $VBoxContainer/ControlPanel/ClearButton
@onready var zoom_slider = $VBoxContainer/ControlPanel/ZoomSlider
@onready var scroll_slider = $VBoxContainer/ControlPanel/ScrollSlider
@onready var timeline_area = $VBoxContainer/TimelineArea

# Timeline visualizer
var timeline_visualizer: SoundTimelineVisualizer

func _ready():
	# Create the timeline visualizer
	timeline_visualizer = SoundTimelineVisualizer.new()
	timeline_area.add_child(timeline_visualizer)
	
	# Connect UI signals
	connect_ui_signals()
	
	# Start with recording enabled
	timeline_visualizer.start_recording()

func connect_ui_signals():
	if record_button:
		record_button.pressed.connect(_on_record_pressed)
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if stop_button:
		stop_button.pressed.connect(_on_stop_pressed)
	if clear_button:
		clear_button.pressed.connect(_on_clear_pressed)
	if zoom_slider:
		zoom_slider.value_changed.connect(_on_zoom_changed)
	if scroll_slider:
		scroll_slider.value_changed.connect(_on_scroll_changed)

func _on_record_pressed():
	if timeline_visualizer.is_recording:
		timeline_visualizer.stop_recording()
		record_button.text = "Record"
		record_button.modulate = Color.WHITE
	else:
		timeline_visualizer.start_recording()
		record_button.text = "Stop Rec"
		record_button.modulate = Color.RED

func _on_play_pressed():
	if timeline_visualizer.is_playing and not timeline_visualizer.is_recording:
		timeline_visualizer.stop_playback()
		play_button.text = "Play"
		play_button.modulate = Color.WHITE
	else:
		timeline_visualizer.start_playback()
		play_button.text = "Pause"
		play_button.modulate = Color.GREEN

func _on_stop_pressed():
	timeline_visualizer.stop_playback()
	timeline_visualizer.stop_recording()
	
	# Reset button states
	play_button.text = "Play"
	play_button.modulate = Color.WHITE
	record_button.text = "Record"
	record_button.modulate = Color.WHITE

func _on_clear_pressed():
	timeline_visualizer.clear_timeline()
	_on_stop_pressed()  # Also stop any current operations

func _on_zoom_changed(value: float):
	if timeline_visualizer:
		timeline_visualizer.set_zoom(value)

func _on_scroll_changed(value: float):
	if timeline_visualizer:
		timeline_visualizer.set_scroll(value)

func _process(delta):
	# Update UI based on timeline state
	if timeline_visualizer:
		# Update scroll slider max value based on timeline content
		var timeline_duration = timeline_visualizer.get_timeline_duration()
		if timeline_duration > 0 and scroll_slider:
			scroll_slider.max_value = max(0.0, 1.0 - (timeline_visualizer.timeline_width / (timeline_duration * 60.0)))
