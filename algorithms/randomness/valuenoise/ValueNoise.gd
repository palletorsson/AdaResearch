extends Node3D

@onready var noise_field = $NoiseField
@onready var interpolation_slider = $UI/VBoxContainer/InterpolationSlider
@onready var grid_size_slider = $UI/VBoxContainer/GridSizeSlider
@onready var amplitude_slider = $UI/VBoxContainer/AmplitudeSlider
@onready var interpolation_label = $UI/VBoxContainer/InterpolationLabel
@onready var grid_size_label = $UI/VBoxContainer/GridSizeLabel
@onready var amplitude_label = $UI/VBoxContainer/AmplitudeLabel
@onready var regenerate_button = $UI/VBoxContainer/RegenerateButton
@onready var show_grid_button = $UI/VBoxContainer/ShowGridButton

var interpolation_methods = ["None", "Linear", "Smoothstep"]

func _ready():
	# Connect UI signals
	interpolation_slider.value_changed.connect(_on_interpolation_changed)
	grid_size_slider.value_changed.connect(_on_grid_size_changed)
	amplitude_slider.value_changed.connect(_on_amplitude_changed)
	regenerate_button.pressed.connect(_on_regenerate_pressed)
	show_grid_button.pressed.connect(_on_show_grid_pressed)
	
	# Initialize the noise field
	_update_noise_parameters()

func _on_interpolation_changed(value):
	var method = interpolation_methods[int(value)]
	interpolation_label.text = "Interpolation: " + method
	_update_noise_parameters()

func _on_grid_size_changed(value):
	grid_size_label.text = "Grid Size: " + str(int(value))
	_update_noise_parameters()

func _on_amplitude_changed(value):
	amplitude_label.text = "Amplitude: " + str(value)
	_update_noise_parameters()

func _on_regenerate_pressed():
	noise_field.regenerate_noise()

func _on_show_grid_pressed():
	noise_field.toggle_grid_lines()

func _update_noise_parameters():
	if noise_field:
		noise_field.interpolation_method = int(interpolation_slider.value)
		noise_field.grid_size = int(grid_size_slider.value)
		noise_field.amplitude = amplitude_slider.value
		noise_field.update_noise_field()
