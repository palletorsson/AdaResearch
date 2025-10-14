extends Node3D

# Controls sine wave parameters using ValueMapper interfaces
# ValueMapper2D controls frequency and amplitude
# ValueMapper1D controls a third parameter (like phase or volume)

@export var use_mario_slider: bool = false  # If true, connects to SimpleMarioSlider

@onready var mapper_2d = $ValueMapper2D  # Frequency (X) and Amplitude (Y)
@onready var mapper_1d = $ValueMapper1D  # Phase or other parameter

# Sine wave parameters
var frequency: float = 440.0
var amplitude: float = 0.5
var phase: float = 0.0

# Reference to Mario slider if using it
var mario_slider: SimpleMarioSlider

func _ready() -> void:
	if mapper_2d:
		mapper_2d.values_changed.connect(_on_2d_values_changed)
		var initial_2d = mapper_2d.get_values()
		_on_2d_values_changed(initial_2d.x, initial_2d.y)

	if mapper_1d:
		mapper_1d.value_changed.connect(_on_1d_value_changed)
		var initial_1d = mapper_1d.get_value()
		_on_1d_value_changed(initial_1d)

	if use_mario_slider:
		_find_mario_slider()

	print("SineWaveController ready")
	print("- Frequency range: %.0f - %.0f Hz" % [mapper_2d.output_x_min, mapper_2d.output_x_max])
	print("- Amplitude range: %.2f - %.2f" % [mapper_2d.output_y_min, mapper_2d.output_y_max])
	print("- Phase range: %.2f - %.2f" % [mapper_1d.output_min, mapper_1d.output_max])

func _find_mario_slider() -> void:
	# Wait for scene to load
	await get_tree().process_frame
	mario_slider = get_tree().get_first_node_in_group("mario_slider_control")
	if mario_slider:
		print("SineWaveController: Connected to SimpleMarioSlider")
	else:
		push_warning("SineWaveController: Could not find SimpleMarioSlider")

func _on_2d_values_changed(freq_value: float, amp_value: float) -> void:
	frequency = freq_value
	amplitude = amp_value

	print("Sine wave: Frequency=%.1f Hz, Amplitude=%.2f" % [frequency, amplitude])

	# If using Mario slider, update its parameters
	if use_mario_slider and mario_slider:
		_update_mario_slider()

func _on_1d_value_changed(phase_value: float) -> void:
	phase = phase_value
	print("Sine wave: Phase=%.2f" % phase)

	# If using Mario slider, update its parameters
	if use_mario_slider and mario_slider:
		_update_mario_slider()

func _update_mario_slider() -> void:
	if not mario_slider:
		return

	# Map our sine wave parameters to Mario slider frequencies
	# Freq1 = base frequency
	# Freq2 = frequency + some offset or harmonic relationship
	var freq1 = frequency
	var freq2 = frequency * 1.5  # Harmonic relationship

	# Access the sliders directly
	if mario_slider.has_node("VBox/Freq1Container/Freq1Slider"):
		var freq1_slider = mario_slider.get_node("VBox/Freq1Container/Freq1Slider")
		freq1_slider.value = clamp(freq1, freq1_slider.min_value, freq1_slider.max_value)

	if mario_slider.has_node("VBox/Freq2Container/Freq2Slider"):
		var freq2_slider = mario_slider.get_node("VBox/Freq2Container/Freq2Slider")
		freq2_slider.value = clamp(freq2, freq2_slider.min_value, freq2_slider.max_value)

	# Update volume based on amplitude
	if mario_slider.has_node("VBox/VolumeContainer/VolumeSlider"):
		var volume_slider = mario_slider.get_node("VBox/VolumeContainer/VolumeSlider")
		volume_slider.value = amplitude

	print("SineWaveController: Updated Mario slider - Freq1=%.1f Hz, Freq2=%.1f Hz, Volume=%.2f" %
		[freq1, freq2, amplitude])

# Public API for getting current sine wave value
func get_sine_value(time: float) -> float:
	return amplitude * sin(TAU * frequency * time + phase)

func get_parameters() -> Dictionary:
	return {
		"frequency": frequency,
		"amplitude": amplitude,
		"phase": phase
	}

func set_parameters(freq: float, amp: float, ph: float) -> void:
	if mapper_2d:
		mapper_2d.set_values(freq, amp)
	if mapper_1d:
		mapper_1d.set_value(ph)
