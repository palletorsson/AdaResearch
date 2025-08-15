extends Node3D

@onready var pattern_visualizer = $PatternVisualizer
@onready var feed_rate_slider = $UI/VBoxContainer/FeedRateSlider
@onready var kill_rate_slider = $UI/VBoxContainer/KillRateSlider
@onready var diffusion_a_slider = $UI/VBoxContainer/DiffusionASlider
@onready var diffusion_b_slider = $UI/VBoxContainer/DiffusionBSlider
@onready var pattern_type_slider = $UI/VBoxContainer/PatternTypeSlider
@onready var feed_rate_label = $UI/VBoxContainer/FeedRateLabel
@onready var kill_rate_label = $UI/VBoxContainer/KillRateLabel
@onready var diffusion_a_label = $UI/VBoxContainer/DiffusionALabel
@onready var diffusion_b_label = $UI/VBoxContainer/DiffusionBLabel
@onready var pattern_type_label = $UI/VBoxContainer/PatternTypeLabel
@onready var start_button = $UI/VBoxContainer/StartButton
@onready var reset_button = $UI/VBoxContainer/ResetButton
@onready var export_button = $UI/VBoxContainer/ExportButton

var pattern_types = ["Spots", "Stripes", "Waves", "Mazes"]
var is_simulation_running = false

func _ready():
	# Connect UI signals
	feed_rate_slider.value_changed.connect(_on_feed_rate_changed)
	kill_rate_slider.value_changed.connect(_on_kill_rate_changed)
	diffusion_a_slider.value_changed.connect(_on_diffusion_a_changed)
	diffusion_b_slider.value_changed.connect(_on_diffusion_b_changed)
	pattern_type_slider.value_changed.connect(_on_pattern_type_changed)
	start_button.pressed.connect(_on_start_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	export_button.pressed.connect(_on_export_pressed)
	
	# Initialize the pattern visualizer
	_update_parameters()

func _on_feed_rate_changed(value):
	feed_rate_label.text = "Feed Rate: " + str(value)
	_update_parameters()

func _on_kill_rate_changed(value):
	kill_rate_label.text = "Kill Rate: " + str(value)
	_update_parameters()

func _on_diffusion_a_changed(value):
	diffusion_a_label.text = "Diffusion A: " + str(value)
	_update_parameters()

func _on_diffusion_b_changed(value):
	diffusion_b_label.text = "Diffusion B: " + str(value)
	_update_parameters()

func _on_pattern_type_changed(value):
	var pattern_type = pattern_types[int(value)]
	pattern_type_label.text = "Pattern Type: " + pattern_type
	_update_parameters()

func _on_start_pressed():
	if is_simulation_running:
		stop_simulation()
	else:
		start_simulation()

func _on_reset_pressed():
	pattern_visualizer.reset_pattern()

func _on_export_pressed():
	pattern_visualizer.export_pattern()

func start_simulation():
	is_simulation_running = true
	start_button.text = "Stop Simulation"
	pattern_visualizer.start_simulation()

func stop_simulation():
	is_simulation_running = false
	start_button.text = "Start Simulation"
	pattern_visualizer.stop_simulation()

func _update_parameters():
	if pattern_visualizer:
		pattern_visualizer.feed_rate = feed_rate_slider.value
		pattern_visualizer.kill_rate = kill_rate_slider.value
		pattern_visualizer.diffusion_a = diffusion_a_slider.value
		pattern_visualizer.diffusion_b = diffusion_b_slider.value
		pattern_visualizer.pattern_type = int(pattern_type_slider.value)
		pattern_visualizer.update_parameters()

