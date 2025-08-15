extends Node3D

@onready var noise_field = $NoiseField
@onready var frequency_slider = $UI/VBoxContainer/FrequencySlider
@onready var amplitude_slider = $UI/VBoxContainer/AmplitudeSlider
@onready var persistence_slider = $UI/VBoxContainer/PersistenceSlider
@onready var frequency_label = $UI/VBoxContainer/FrequencyLabel
@onready var amplitude_label = $UI/VBoxContainer/AmplitudeLabel
@onready var persistence_label = $UI/VBoxContainer/PersistenceLabel
@onready var regenerate_button = $UI/VBoxContainer/RegenerateButton
@onready var compare_button = $UI/VBoxContainer/CompareButton

func _ready():
	# Connect UI signals
	frequency_slider.value_changed.connect(_on_frequency_changed)
	amplitude_slider.value_changed.connect(_on_amplitude_changed)
	persistence_slider.value_changed.connect(_on_persistence_changed)
	regenerate_button.pressed.connect(_on_regenerate_pressed)
	compare_button.pressed.connect(_on_compare_pressed)
	
	# Initialize the noise field
	_update_noise_parameters()

func _on_frequency_changed(value):
	frequency_label.text = "Frequency: " + str(value)
	_update_noise_parameters()

func _on_amplitude_changed(value):
	amplitude_label.text = "Amplitude: " + str(value)
	_update_noise_parameters()

func _on_persistence_changed(value):
	persistence_label.text = "Persistence: " + str(value)
	_update_noise_parameters()

func _on_regenerate_pressed():
	noise_field.regenerate_noise()

func _on_compare_pressed():
	# This could open a comparison scene or overlay
	print("Comparison feature - could show Perlin vs Simplex side by side")

func _update_noise_parameters():
	if noise_field:
		noise_field.frequency = frequency_slider.value
		noise_field.amplitude = amplitude_slider.value
		noise_field.persistence = persistence_slider.value
		noise_field.update_noise_field()
