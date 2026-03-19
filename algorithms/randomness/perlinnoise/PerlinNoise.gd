extends Node3D

# @identity
# essence: perlin(p) = Σᵢ amplitudeᵢ × interpolate(gradient_hash(grid_corner(frequencyᵢ × p))) — gradient noise using a permutation table to assign consistent random gradients to grid corners
# desire: to turn three sliders and watch the same mathematical recipe produce mountains, heartbeats, or alien textures — to feel that frequency, amplitude, and octaves are a complete description of organic shape
# critical_parameter: octaves — each additional octave adds one more frequency layer of detail; at 1 the noise is smooth blobs, at 8 it fractures into rock-like complexity
# triggers: animation_button toggles time-based offset that slides the noise field — revealing that Perlin noise is a 3D field being sampled in a 2D plane, and time is the third dimension
# emerges: the learner discovers that regenerate with same octaves produces a different landscape but the same character — octaves constrain the space of possible shapes without determining which shape
# needs: frequency slider [has] (2D UI); amplitude slider [has]; octaves slider [has]; animate button [has]; regenerate button [has]; no VR slider_horizontal controls [missing]
# relationships: contrasts with SimplexNoise (gradient vs simplex basis); shares scene structure with NoiseVisualizer.gd; feeds into noise_terrain and noiselayers; historically the foundation of procedural generation
# truth: Perlin noise is organized hallucination — the algorithm enforces continuity and smoothness onto randomness, creating the illusion that chaos has intention

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

func _ready() -> void:
	# Connect UI signals
	frequency_slider.value_changed.connect(_on_frequency_changed)
	amplitude_slider.value_changed.connect(_on_amplitude_changed)
	octaves_slider.value_changed.connect(_on_octaves_changed)
	regenerate_button.pressed.connect(_on_regenerate_pressed)
	animation_button.pressed.connect(_on_animation_pressed)
	
	# Initialize the noise field
	_update_noise_parameters()

func _process(delta: float) -> void:
	if is_animating:
		animation_time += delta
		noise_field.animation_offset = animation_time * 0.5

func _on_frequency_changed(value) -> void:
	frequency_label.text = "Frequency: " + str(value)
	_update_noise_parameters()

func _on_amplitude_changed(value) -> void:
	amplitude_label.text = "Amplitude: " + str(value)
	_update_noise_parameters()

func _on_octaves_changed(value) -> void:
	octaves_label.text = "Octaves: " + str(int(value))
	_update_noise_parameters()

func _on_regenerate_pressed() -> void:
	noise_field.regenerate_noise()

func _on_animation_pressed() -> void:
	is_animating = !is_animating
	if is_animating:
		animation_button.text = "Stop Animation"
	else:
		animation_button.text = "Animate Noise"

func _update_noise_parameters() -> void:
	if noise_field:
		noise_field.frequency = frequency_slider.value
		noise_field.amplitude = amplitude_slider.value
		noise_field.octaves = int(octaves_slider.value)
		noise_field.update_noise_field()

func apply_grid_config(config: Dictionary) -> void:
	pass
