# RealtimeSynthesizerComponent.gd
# Integration component for the RealtimeAudioSynthesizer

extends Control
class_name RealtimeSynthesizerComponent

# UI References
var synthesizer: RealtimeAudioSynthesizer
var bpm_slider: HSlider
var filter_slider: HSlider
var gate_toggle: CheckBox
var pattern_selector: OptionButton
var volume_slider: HSlider

# Labels for displaying values
var bpm_label: Label
var filter_label: Label
var volume_label: Label

# Pattern definitions
var patterns = {
	"Pattern 1 (Simple)": {
		"notes": [0],
		"transpose": -14,
		"scale": "g:minor",
		"synth": "supersaw",
		"octave": 2,
		"trance_gate": [1.5, 5, 45, 1],
		"filter_cutoff": 0.5,
		"lpenv": 2
	},
	"Pattern 2 (Complex)": {
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
	}
}

func _ready():
	create_ui()
	create_synthesizer()

func create_ui():
	# Main container
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)
	
	# Title
	var title = Label.new()
	title.text = "Realtime Audio Synthesizer"
	title.add_theme_font_size_override("font_size", 16)
	main_vbox.add_child(title)
	
	# BPM Control
	var bpm_container = HBoxContainer.new()
	main_vbox.add_child(bpm_container)
	
	var bpm_label_container = VBoxContainer.new()
	bpm_container.add_child(bpm_label_container)
	
	var bpm_text = Label.new()
	bpm_text.text = "BPM"
	bpm_label_container.add_child(bpm_text)
	
	bpm_label = Label.new()
	bpm_label.text = "120"
	bpm_label_container.add_child(bpm_label)
	
	bpm_slider = HSlider.new()
	bpm_slider.min_value = 60
	bpm_slider.max_value = 200
	bpm_slider.value = 120
	bpm_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bpm_slider.value_changed.connect(_on_bpm_changed)
	bpm_container.add_child(bpm_slider)
	
	# Filter Control
	var filter_container = HBoxContainer.new()
	main_vbox.add_child(filter_container)
	
	var filter_label_container = VBoxContainer.new()
	filter_container.add_child(filter_label_container)
	
	var filter_text = Label.new()
	filter_text.text = "Filter Cutoff"
	filter_label_container.add_child(filter_text)
	
	filter_label = Label.new()
	filter_label.text = "0.5"
	filter_label_container.add_child(filter_label)
	
	filter_slider = HSlider.new()
	filter_slider.min_value = 0.0
	filter_slider.max_value = 1.0
	filter_slider.value = 0.5
	filter_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_slider.value_changed.connect(_on_filter_changed)
	filter_container.add_child(filter_slider)
	
	# Volume Control
	var volume_container = HBoxContainer.new()
	main_vbox.add_child(volume_container)
	
	var volume_label_container = VBoxContainer.new()
	volume_container.add_child(volume_label_container)
	
	var volume_text = Label.new()
	volume_text.text = "Volume"
	volume_label_container.add_child(volume_text)
	
	volume_label = Label.new()
	volume_label.text = "0.3"
	volume_label_container.add_child(volume_label)
	
	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.value = 0.3
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_container.add_child(volume_slider)
	
	# Trance Gate Toggle
	gate_toggle = CheckBox.new()
	gate_toggle.text = "Enable Trance Gate"
	gate_toggle.button_pressed = true
	gate_toggle.toggled.connect(_on_gate_toggled)
	main_vbox.add_child(gate_toggle)
	
	# Pattern Selector
	var pattern_container = HBoxContainer.new()
	main_vbox.add_child(pattern_container)
	
	var pattern_text = Label.new()
	pattern_text.text = "Pattern:"
	pattern_container.add_child(pattern_text)
	
	pattern_selector = OptionButton.new()
	pattern_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for pattern_name in patterns.keys():
		pattern_selector.add_item(pattern_name)
	pattern_selector.item_selected.connect(_on_pattern_selected)
	pattern_container.add_child(pattern_selector)
	
	# Control buttons
	var button_container = HBoxContainer.new()
	main_vbox.add_child(button_container)
	
	var play_button = Button.new()
	play_button.text = "Play"
	play_button.pressed.connect(_on_play_pressed)
	button_container.add_child(play_button)
	
	var stop_button = Button.new()
	stop_button.text = "Stop"
	stop_button.pressed.connect(_on_stop_pressed)
	button_container.add_child(stop_button)

func create_synthesizer():
	synthesizer = RealtimeAudioSynthesizer.new()
	add_child(synthesizer)
	
	# Set initial pattern
	synthesizer.set_pattern(patterns["Pattern 2 (Complex)"])
	synthesizer.set_trance_gate(1.5, 5, 45, 1)

func _on_bpm_changed(value: float):
	synthesizer.set_bpm(value)
	bpm_label.text = str(int(value))

func _on_filter_changed(value: float):
	synthesizer.set_filter(value)
	filter_label.text = "%.2f" % value

func _on_volume_changed(value: float):
	# Adjust the synthesizer volume by modifying the sample generation
	# This would require adding a volume parameter to the synthesizer
	volume_label.text = "%.2f" % value

func _on_gate_toggled(pressed: bool):
	synthesizer.trance_gate_active = pressed

func _on_pattern_selected(index: int):
	var pattern_names = patterns.keys()
	var selected_pattern = pattern_names[index]
	synthesizer.set_pattern(patterns[selected_pattern])

func _on_play_pressed():
	if not synthesizer.playing:
		synthesizer.play()

func _on_stop_pressed():
	synthesizer.stop()

# Integration with existing audio system
func get_audio_parameters() -> Dictionary:
	return synthesizer.get_audio_parameters()

func set_audio_parameters(params: Dictionary):
	synthesizer.set_audio_parameters(params)
	
	# Update UI to reflect parameter changes
	if "bpm" in params:
		bpm_slider.value = params["bpm"]
		bpm_label.text = str(int(params["bpm"]))
	if "filter_cutoff" in params:
		filter_slider.value = params["filter_cutoff"]
		filter_label.text = "%.2f" % params["filter_cutoff"]
	if "trance_gate_active" in params:
		gate_toggle.button_pressed = params["trance_gate_active"]

# Export functions for integration
func export_synthesizer() -> RealtimeAudioSynthesizer:
	return synthesizer

func is_playing() -> bool:
	return synthesizer.playing









