# RealtimeSynthesizerTest.gd
# Test script for the RealtimeAudioSynthesizer

extends Node3D

var synthesizer: RealtimeAudioSynthesizer
var ui_controls: Control

func _ready():
	# Create the synthesizer
	synthesizer = RealtimeAudioSynthesizer.new()
	add_child(synthesizer)
	
	# Create simple UI controls
	setup_ui()
	
	# Start with pattern 2 (the complex one)
	synthesizer.set_pattern({
		"notes": [0, 0, -7, -5, -2, -5, -2, 0, -3, 2, 1],
		"durations": [2, 2, 3, 1, 1, 1, 1, 3, 1, 1, 1],
		"transpose": 7,
		"scale": "g:minor",
		"synth": "supersaw",
		"octave": 3,
		"trance_gate": [1.5, 5, 45, 1],
		"delay": 0.7,
		"filter_cutoff": 0.593,
		"lpenv": 2
	})
	
	# Enable trance gate
	synthesizer.set_trance_gate(1.5, 5, 45, 1)

func setup_ui():
	# Create a simple UI for testing
	ui_controls = Control.new()
	ui_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui_controls)
	
	# BPM control
	var bpm_label = Label.new()
	bpm_label.text = "BPM: 120"
	bpm_label.position = Vector2(10, 10)
	ui_controls.add_child(bpm_label)
	
	var bpm_slider = HSlider.new()
	bpm_slider.min_value = 60
	bpm_slider.max_value = 200
	bpm_slider.value = 120
	bpm_slider.position = Vector2(10, 40)
	bpm_slider.size = Vector2(200, 20)
	bpm_slider.value_changed.connect(_on_bpm_changed)
	ui_controls.add_child(bpm_slider)
	
	# Filter cutoff control
	var filter_label = Label.new()
	filter_label.text = "Filter Cutoff: 0.5"
	filter_label.position = Vector2(10, 70)
	ui_controls.add_child(filter_label)
	
	var filter_slider = HSlider.new()
	filter_slider.min_value = 0.0
	filter_slider.max_value = 1.0
	filter_slider.value = 0.5
	filter_slider.position = Vector2(10, 100)
	filter_slider.size = Vector2(200, 20)
	filter_slider.value_changed.connect(_on_filter_changed)
	ui_controls.add_child(filter_slider)
	
	# Trance gate toggle
	var gate_button = Button.new()
	gate_button.text = "Toggle Trance Gate"
	gate_button.position = Vector2(10, 130)
	gate_button.size = Vector2(150, 30)
	gate_button.pressed.connect(_on_toggle_gate)
	ui_controls.add_child(gate_button)
	
	# Pattern switch button
	var pattern_button = Button.new()
	pattern_button.text = "Switch Pattern"
	pattern_button.position = Vector2(10, 170)
	pattern_button.size = Vector2(150, 30)
	pattern_button.pressed.connect(_on_switch_pattern)
	ui_controls.add_child(pattern_button)

func _on_bpm_changed(value: float):
	synthesizer.set_bpm(value)
	var bpm_label = ui_controls.get_child(0)
	bpm_label.text = "BPM: " + str(int(value))

func _on_filter_changed(value: float):
	synthesizer.set_filter(value)
	var filter_label = ui_controls.get_child(2)
	filter_label.text = "Filter Cutoff: " + str(value)

func _on_toggle_gate():
	synthesizer.trance_gate_active = !synthesizer.trance_gate_active

func _on_switch_pattern():
	# Switch between the two patterns
	if synthesizer.current_pattern["transpose"] == 7:
		# Switch to pattern 1
		synthesizer.set_pattern({
			"notes": [0],
			"transpose": -14,
			"scale": "g:minor",
			"synth": "supersaw",
			"octave": 2,
			"trance_gate": [1.5, 5, 45, 1],
			"filter_cutoff": 0.5,
			"lpenv": 2
		})
	else:
		# Switch to pattern 2
		synthesizer.set_pattern({
			"notes": [0, 0, -7, -5, -2, -5, -2, 0, -3, 2, 1],
			"durations": [2, 2, 3, 1, 1, 1, 1, 3, 1, 1, 1],
			"transpose": 7,
			"scale": "g:minor",
			"synth": "supersaw",
			"octave": 3,
			"trance_gate": [1.5, 5, 45, 1],
			"delay": 0.7,
			"filter_cutoff": 0.593,
			"lpenv": 2
		})








