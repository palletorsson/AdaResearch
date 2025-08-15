extends Node3D

@onready var signal_generator = $SignalGenerator
@onready var signal_type_slider = $UI/VBoxContainer/SignalTypeSlider
@onready var frequency_slider = $UI/VBoxContainer/FrequencySlider
@onready var amplitude_slider = $UI/VBoxContainer/AmplitudeSlider
@onready var harmonics_slider = $UI/VBoxContainer/HarmonicsSlider
@onready var signal_type_label = $UI/VBoxContainer/SignalTypeLabel
@onready var frequency_label = $UI/VBoxContainer/FrequencyLabel
@onready var amplitude_label = $UI/VBoxContainer/AmplitudeLabel
@onready var harmonics_label = $UI/VBoxContainer/HarmonicsLabel
@onready var transform_button = $UI/VBoxContainer/TransformButton
@onready var reset_button = $UI/VBoxContainer/ResetButton

var signal_types = ["Sine Wave", "Square Wave", "Triangle Wave", "Sawtooth Wave"]

func _ready():
	# Connect UI signals
	signal_type_slider.value_changed.connect(_on_signal_type_changed)
	frequency_slider.value_changed.connect(_on_frequency_changed)
	amplitude_slider.value_changed.connect(_on_amplitude_changed)
	harmonics_slider.value_changed.connect(_on_harmonics_changed)
	transform_button.pressed.connect(_on_transform_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	
	# Initialize the signal generator
	_update_signal_parameters()

func _on_signal_type_changed(value):
	var signal_type = signal_types[int(value)]
	signal_type_label.text = "Signal Type: " + signal_type
	_update_signal_parameters()

func _on_frequency_changed(value):
	frequency_label.text = "Frequency: " + str(value) + " Hz"
	_update_signal_parameters()

func _on_amplitude_changed(value):
	amplitude_label.text = "Amplitude: " + str(value)
	_update_signal_parameters()

func _on_harmonics_changed(value):
	harmonics_label.text = "Harmonics: " + str(int(value))
	_update_signal_parameters()

func _on_transform_pressed():
	signal_generator.compute_fft()

func _on_reset_pressed():
	signal_generator.reset_signal()
	_update_signal_parameters()

func _update_signal_parameters():
	if signal_generator:
		signal_generator.signal_type = int(signal_type_slider.value)
		signal_generator.frequency = frequency_slider.value
		signal_generator.amplitude = amplitude_slider.value
		signal_generator.harmonics = int(harmonics_slider.value)
		signal_generator.update_signal()
