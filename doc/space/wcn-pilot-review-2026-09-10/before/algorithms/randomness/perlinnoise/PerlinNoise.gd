extends Node3D

# @identity
# essence: perlin(p) = Σᵢ amplitudeᵢ × interpolate(gradient_hash(grid_corner(frequencyᵢ × p))) — gradient noise using a permutation table to assign consistent random gradients to grid corners
# desire: to turn three sliders and watch the same mathematical recipe produce mountains, heartbeats, or alien textures — to feel that frequency, amplitude, and octaves are a complete description of organic shape
# critical_parameter: octaves — each additional octave adds one more frequency layer of detail; at 1 the noise is smooth blobs, at 8 it fractures into rock-like complexity
# triggers: animation_button toggles time-based offset that slides the noise field — revealing that Perlin noise is a 3D field being sampled in a 2D plane, and time is the third dimension
# emerges: the learner discovers that regenerate with same octaves produces a different landscape but the same character — octaves constrain the space of possible shapes without determining which shape
# needs: frequency slider [has] (2D UI); amplitude slider [has]; octaves slider [has]; animate button [has]; regenerate button [has]; VR panel [has, under panel=front]
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
## THE COMPARISON CONTRACT (2026-09-10, doc/research/waves-chance-noise, the
## Noise_Perlin_Simplex pilot): seed, ramp, size and panel, declared here exactly
## as on SimplexNoise.gd and for the same reason. Read that file's header; the
## two roots are kept as twins on purpose, one for each basis, until a third
## consumer says what to share.
##
## Usage in map_data.json:
##   "perlin_noise#generator:perlin"
##   "perlin_noise#readout:plate"
##   "perlin_noise:0:1.1#generator:perlin#seed:20260910#size:8#ramp:shared#panel:front"

## DNA axis: which noise basis fills the field.
@export var generator: String = "simplex"  # simplex | perlin | value | cellular
## DNA axis: what the field is claimed to be — relief (terrain), plate (an image
## of a scalar function), column (measured quantities in a bar chart).
@export var readout: String = "relief"  # relief | plate | column
## A named seed; -1 keeps the shipped randi() at build.
@export var seed_value: int = -1
## legacy (this display's blue-to-orange) or shared (the ramp both displays use).
@export_enum("legacy", "shared") var ramp: String = "legacy"
## Cells on a side; the resolution stays 0.5 m.
@export var size: int = 20
## none, or front: a reachable panel in front of the field.
@export_enum("none", "front") var panel: String = "none"

const PROBE_A := Vector2(0.0, 0.0)
const PROBE_B := Vector2(2.5, 2.5)
const FREQ_MIN := 0.1
const FREQ_MAX := 5.0

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
var _frequency: float = 1.0
var _amplitude: float = 1.0
var _octaves: int = 4
var _panel_node: Node3D
var _readout: Label3D

func _ready() -> void:
	if is_instance_valid(frequency_slider):
		_frequency = float(frequency_slider.value)
		_amplitude = float(amplitude_slider.value)
		_octaves = int(octaves_slider.value)
		frequency_slider.value_changed.connect(_on_frequency_changed)
		amplitude_slider.value_changed.connect(_on_amplitude_changed)
		octaves_slider.value_changed.connect(_on_octaves_changed)
		regenerate_button.pressed.connect(_on_regenerate_pressed)
		animation_button.pressed.connect(_on_animation_pressed)

	# Push the declared genome down before the first sample is taken
	if noise_field:
		noise_field.set_dna(generator, readout)
	_apply_contract()

	# Initialize the noise field
	_update_noise_parameters()
	_build_panel()
	_built = true

func _apply_contract() -> void:
	if noise_field == null:
		return
	noise_field.ramp = ramp
	if size != noise_field.noise_field_size:
		noise_field.rebuild_size(size)
	if seed_value >= 0 and noise_field.current_seed != seed_value:
		noise_field.reseed(seed_value)

func _process(delta: float) -> void:
	if is_animating:
		animation_time += delta
		noise_field.animation_offset = animation_time * 0.5

func _on_frequency_changed(value) -> void:
	_frequency = float(value)
	if is_instance_valid(frequency_label):
		frequency_label.text = "Frequency: " + str(value)
	_update_noise_parameters()

func _on_amplitude_changed(value) -> void:
	_amplitude = float(value)
	if is_instance_valid(amplitude_label):
		amplitude_label.text = "Amplitude: " + str(value)
	_update_noise_parameters()

func _on_octaves_changed(value) -> void:
	_octaves = int(value)
	if is_instance_valid(octaves_label):
		octaves_label.text = "Octaves: " + str(int(value))
	_update_noise_parameters()

func _on_regenerate_pressed() -> void:
	regenerate()

func _on_animation_pressed() -> void:
	is_animating = !is_animating
	if is_instance_valid(animation_button):
		animation_button.text = "Stop Animation" if is_animating else "Animate Noise"

func _update_noise_parameters() -> void:
	if noise_field:
		noise_field.frequency = _frequency
		noise_field.amplitude = _amplitude
		noise_field.octaves = _octaves
		noise_field.update_noise_field()
	_refresh_readout()

# ── the reachable panel — the twin of SimplexNoise._build_panel ──────────────
func _build_panel() -> void:
	if panel != "front":
		return
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	if RackTpl == null:
		return
	var f0: float = clampf((_frequency - FREQ_MIN) / (FREQ_MAX - FREQ_MIN), 0.0, 1.0)
	var o0: float = clampf(float(_octaves - 1) / 7.0, 0.0, 1.0)
	_panel_node = RackTpl.create_panel(generator.to_upper(), [
		[{"type": "slider_h", "label": "FREQ", "default": f0}],
		[{"type": "slider_h", "label": "OCTAVES", "default": o0}],
		[
			{"type": "button", "label": "REGEN"},
			{"type": "button", "label": "REPLAY"},
		],
	])
	var half: float = float(noise_field.noise_field_size) * 0.5 * float(noise_field.noise_resolution) if noise_field else 5.0
	_panel_node.position = Vector3(0.0, 0.2, -(half + 0.7))
	_panel_node.rotation_degrees = Vector3(-20.0, 0.0, 0.0)
	add_child(_panel_node)
	var fs: Node = _panel_node.find_child("Param_0", true, false)
	if fs and fs.has_signal("slider_moved"):
		fs.slider_moved.connect(func(_v): _on_panel_freq(fs))
	var os_: Node = _panel_node.find_child("Param_1", true, false)
	if os_ and os_.has_signal("slider_moved"):
		os_.slider_moved.connect(func(_v): _on_panel_octaves(os_))
	var b0: Node = _panel_node.find_child("Btn_0", true, false)
	if b0:
		var a0 = b0.get_node_or_null("InteractableAreaButton")
		if a0:
			a0.button_pressed.connect(func(_b): regenerate())
	var b1: Node = _panel_node.find_child("Btn_1", true, false)
	if b1:
		var a1 = b1.get_node_or_null("InteractableAreaButton")
		if a1:
			a1.button_pressed.connect(func(_b): replay())
	_readout = Label3D.new()
	_readout.name = "Readout"
	_readout.pixel_size = 0.0018
	_readout.font_size = 16
	_readout.outline_size = 4
	_readout.modulate = Color(0.92, 0.9, 0.8)
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_readout.position = Vector3(0.0, 0.55, -(half + 0.7))
	add_child(_readout)
	_refresh_readout()

func _on_panel_freq(slider: Node) -> void:
	if slider.has_method("get_normalized_value"):
		_frequency = lerpf(FREQ_MIN, FREQ_MAX, float(slider.get_normalized_value()))
		_update_noise_parameters()

func _on_panel_octaves(slider: Node) -> void:
	if slider.has_method("get_normalized_value"):
		_octaves = clampi(1 + int(round(float(slider.get_normalized_value()) * 7.0)), 1, 8)
		_update_noise_parameters()

func _refresh_readout() -> void:
	if _readout == null or noise_field == null:
		return
	var a: float = noise_field.sample_at(PROBE_A.x, PROBE_A.y)
	var b: float = noise_field.sample_at(PROBE_B.x, PROBE_B.y)
	_readout.text = "%s · seed %d · oct %d · f %.2f · gain %.2f\n(%.1f, %.1f) = %+.3f    (%.1f, %.1f) = %+.3f" % [
		basis_name(), noise_field.current_seed, _octaves, _frequency, float(noise_field.persistence),
		PROBE_A.x, PROBE_A.y, a, PROBE_B.x, PROBE_B.y, b]

func regenerate() -> void:
	if noise_field:
		noise_field.regenerate_noise()
	_refresh_readout()

func replay() -> void:
	if noise_field:
		noise_field.reseed(seed_value if seed_value >= 0 else noise_field.current_seed)
	_refresh_readout()

# ── read by the probe (commons/testing/probe_wcn_noise_pair.gd) ──────────────
## The basis the field is ACTUALLY drawn from, read back from the generator —
## not the name on the scene.
func basis_name() -> String:
	match noise_type():
		FastNoiseLite.TYPE_PERLIN:
			return "perlin"
		FastNoiseLite.TYPE_VALUE:
			return "value"
		FastNoiseLite.TYPE_CELLULAR:
			return "cellular"
		FastNoiseLite.TYPE_SIMPLEX:
			return "simplex"
	return generator

func noise_type() -> int:
	return noise_field.noise_generator.noise_type if noise_field and noise_field.noise_generator else -1

func current_seed() -> int:
	return noise_field.current_seed if noise_field else -1

func sample_at(x: float, z: float) -> float:
	return noise_field.sample_at(x, z) if noise_field else 0.0

func contract() -> Dictionary:
	return {"basis": basis_name(), "seed": current_seed(), "octaves": _octaves, "frequency": _frequency,
		"gain": float(noise_field.persistence) if noise_field else 0.5, "amplitude": _amplitude,
		"size": noise_field.noise_field_size if noise_field else 0,
		"resolution": noise_field.noise_resolution if noise_field else 0.0, "ramp": ramp, "readout": readout}

func set_frequency(f: float) -> void:
	_frequency = clampf(f, FREQ_MIN, FREQ_MAX)
	_update_noise_parameters()

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
	var contract_changed: bool = false
	if config.has("seed"):
		var s: int = int(config["seed"])
		if s != seed_value:
			seed_value = s
			contract_changed = true
	if config.has("octaves"):
		var o: int = int(config["octaves"])
		if o != _octaves:
			_octaves = o
			contract_changed = true
	if config.has("ramp"):
		var m: String = str(config["ramp"]).to_lower()
		if m != ramp:
			ramp = m
			contract_changed = true
	if config.has("size"):
		var n: int = int(config["size"])
		if n != size:
			size = n
			contract_changed = true
	if config.has("panel"):
		var p: String = str(config["panel"]).to_lower()
		if p != panel:
			panel = p
			if _built and _panel_node == null:
				_build_panel()
	if changed and _built and noise_field:
		noise_field.set_dna(generator, readout)
	if contract_changed and _built and noise_field:
		_apply_contract()
		_update_noise_parameters()
	elif changed and _built:
		_refresh_readout()
