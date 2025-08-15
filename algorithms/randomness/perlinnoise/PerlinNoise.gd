extends Node3D

@onready var noise_field = $NoiseField
@onready var frequency_slider = $UI/VBoxContainer/FrequencySlider
@onready var amplitude_slider = $UI/VBoxContainer/AmplitudeSlider
@onready var octaves_slider = $UI/VBoxContainer/OctavesSlider
@onready var frequency_label = $UI/VBoxContainer/FrequencyLabel
@onready var amplitude_label = $UI/VBoxContainer/AmplitudeLabel
@onready var octaves_label = $UI/VBoxContainer/OctavesLabel
@onready var regenerate_button = $UI/VBoxContainer/RegenerateButton
@onready var animation_button = $UI/VBoxContainer/AnimationButton

var is_animating = false
var animation_time = 0.0

func _ready():
	# Connect UI signals
	frequency_slider.value_changed.connect(_on_frequency_changed)
	amplitude_slider.value_changed.connect(_on_amplitude_changed)
	octaves_slider.value_changed.connect(_on_octaves_changed)
	regenerate_button.pressed.connect(_on_regenerate_pressed)
	animation_button.pressed.connect(_on_animation_pressed)
	
	# Initialize the noise field
	_update_noise_parameters()

func _process(delta):
	if is_animating:
		animation_time += delta
		noise_field.animation_offset = animation_time * 0.5

func _on_frequency_changed(value):
	frequency_label.text = "Frequency: " + str(value)
	_update_noise_parameters()

func _on_amplitude_changed(value):
	amplitude_label.text = "Amplitude: " + str(value)
	_update_noise_parameters()

func _on_octaves_changed(value):
	octaves_label.text = "Octaves: " + str(int(value))
	_update_noise_parameters()

func _on_regenerate_pressed():
	noise_field.regenerate_noise()

func _on_animation_pressed():
	is_animating = !is_animating
	if is_animating:
		animation_button.text = "Stop Animation"
	else:
		animation_button.text = "Animate Noise"

func _update_noise_parameters():
	if noise_field:
		noise_field.frequency = frequency_slider.value
		noise_field.amplitude = amplitude_slider.value
		noise_field.octaves = int(octaves_slider.value)
		noise_field.update_noise_field()
