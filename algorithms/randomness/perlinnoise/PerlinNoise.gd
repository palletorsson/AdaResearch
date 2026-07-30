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

## STAGE-2 DNA PROMOTION (2026-07-29). Before this the artifact had no exports at
## all on its root: three sliders in a 2D UI that VR placements never touch, and a
## field whose two real decisions — which generator fills it, and whether the field
## is read as landscape or as measurement — were hard-coded one layer down in
## NoiseVisualizer.gd. Two axes, shared vocabulary with the simplex_noise sibling:
##
##   generator  which basis fills the field   simplex · perlin · value · cellular
##   readout    what the field is claimed     relief · plate · column
##              to BE
##
## readout is deliberately the SAME axis, with the same three values and the same
## default, as the simplex_noise sibling promoted the same day: the two artifacts
## ask one question of two generators, so they must answer in one vocabulary or the
## comparison the noise sequence is built on cannot be made.
##
## generator=simplex is the DEFAULT because it is what the shipped code sets
## (FastNoiseLite.TYPE_SIMPLEX) — the artifact named "Perlin Noise" has been drawing
## simplex noise all along. The promotion does not silently correct that; it makes
## the basis a declared choice so a placement can ask for generator=perlin and the
## two lineages can stand next to each other, which is the whole argument of the
## noise sequence.
##
## Usage in map_data.json:
##   "perlin_noise#generator:perlin"
##   "perlin_noise#readout:plate"

## DNA axis: which noise basis fills the field.
@export var generator: String = "simplex"  # simplex | perlin | value | cellular
## DNA axis: what the field is claimed to be — relief (terrain), plate (an image
## of a scalar function), column (measured quantities in a bar chart).
@export var readout: String = "relief"  # relief | plate | column

var _built: bool = false

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
	
	# Push the declared genome down before the first sample is taken
	if noise_field:
		noise_field.set_dna(generator, readout)

	# Initialize the noise field
	_update_noise_parameters()
	_built = true

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
	# Guarded: only touch the field when a declared axis actually changed, and only
	# after _ready has built once. An unguarded rebuild here rewrites the look of
	# every shipped placement.
	var changed: bool = false
	if config.has("generator"):
		var g: String = str(config["generator"]).to_lower()
		if g != generator:
			generator = g
			changed = true
	if config.has("readout"):
		var r: String = str(config["readout"]).to_lower()
		if r != readout:
			readout = r
			changed = true
	if changed and _built and noise_field:
		noise_field.set_dna(generator, readout)
