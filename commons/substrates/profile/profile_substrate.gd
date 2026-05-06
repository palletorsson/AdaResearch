@tool
extends Node3D
class_name ProfileSubstrate

## Profile Substrate — continuous 1D curve renderer.
## Ribbon-strip ImmediateMesh traces over a grid background.
## Waveforms, loss curves, noise profiles, distributions, oscillation decay.
##
## Place in map: "profile_sine", "profile#algorithm:fourier#traces:4", etc.

## --- Configuration ---

@export var sample_count: int = 256
@export var step_interval: float = 0.016  ## 60fps default (smooth curves)
@export var auto_play: bool = true
@export var label_text: String = ""

## Algorithm selection
enum Algorithm {
	SINE_WAVE, SQUARE_WAVE, SAW_WAVE, TRIANGLE_WAVE,
	FOURIER_SERIES, BEAT_FREQUENCIES,
	LISSAJOUS_1D,
	NOISE_1D, NOISE_OCTAVES,
	RANDOM_WALK, BROWNIAN_BRIDGE, BELL_CURVE,
	DAMPED_OSCILLATION, SPRING_MASS,
	GRADIENT_DESCENT,
	LOGISTIC_MAP,
}

@export var algorithm: Algorithm = Algorithm.SINE_WAVE:
	set(v):
		algorithm = v
		if is_inside_tree() and not Engine.is_editor_hint():
			_load_cartridge()

## --- Signals ---

signal step_advanced(step_index: int)
signal playback_changed(is_playing: bool)
signal algorithm_complete()

## --- Internal ---

var _cartridge: ProfileCartridge
var _traces: Array = []  # Array[PackedFloat32Array]
var _step_index: int = 0
var _elapsed: float = 0.0
var _is_playing: bool = false
var _is_done: bool = false
var _time_accumulator: float = 0.0

@onready var _renderer: ProfileRenderer = $Renderer
@onready var _label: Label3D = $Label3D


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_resolve_algorithm_from_lookup_name()
	_load_cartridge()

	if auto_play:
		_is_playing = true


func _load_cartridge() -> void:
	_cartridge = _create_cartridge(algorithm)

	# Let cartridge override sample count and interval
	var pi = _cartridge.get_preferred_interval()
	if pi > 0.0:
		step_interval = pi

	# Initialize traces
	_traces = _cartridge.initialize(sample_count)
	_step_index = 0
	_elapsed = 0.0
	_time_accumulator = 0.0
	_is_done = false

	# Setup renderer
	if _renderer:
		_renderer.setup(_cartridge.get_trace_count(), sample_count, _cartridge)
		_renderer.update_traces(_traces, _cartridge)

	# Warmup
	var warmup = _cartridge.get_warmup_steps()
	for i in range(warmup):
		_do_step(step_interval)

	_update_label()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if not _is_playing or not _cartridge or _is_done:
		return

	_time_accumulator += delta
	if _time_accumulator >= step_interval:
		_time_accumulator -= step_interval
		_do_step(delta)


func _do_step(delta: float) -> void:
	_elapsed += delta
	var result = _cartridge.step(_traces, _step_index, _elapsed)

	if result.get("traces") != null:
		_traces = result["traces"]

	_step_index += 1

	if _renderer:
		_renderer.update_traces(_traces, _cartridge)
		var markers = result.get("markers", [])
		if markers.size() > 0:
			_renderer.update_markers(markers)

	step_advanced.emit(_step_index)

	if result.get("done", false):
		_is_done = true
		algorithm_complete.emit()


## --- Public API ---

func play() -> void:
	_is_playing = true
	_time_accumulator = 0.0
	playback_changed.emit(true)

func pause() -> void:
	_is_playing = false
	playback_changed.emit(false)

func toggle_play() -> void:
	if _is_playing:
		pause()
	else:
		play()

func single_step() -> void:
	_do_step(step_interval)

func reset() -> void:
	_load_cartridge()

func is_playing() -> bool:
	return _is_playing


## --- Label ---

func _update_label() -> void:
	if not _label or not _cartridge:
		return
	_label.text = label_text if label_text != "" else _cartridge.get_name()


## --- Cartridge factory ---

func _create_cartridge(algo: Algorithm) -> ProfileCartridge:
	match algo:
		Algorithm.SINE_WAVE:
			return preload("res://commons/substrates/profile/cartridges/cartridge_sine_wave.gd").new()
		Algorithm.SQUARE_WAVE:
			return preload("res://commons/substrates/profile/cartridges/cartridge_square_wave.gd").new()
		Algorithm.SAW_WAVE:
			return preload("res://commons/substrates/profile/cartridges/cartridge_saw_wave.gd").new()
		Algorithm.TRIANGLE_WAVE:
			return preload("res://commons/substrates/profile/cartridges/cartridge_triangle_wave.gd").new()
		Algorithm.FOURIER_SERIES:
			return preload("res://commons/substrates/profile/cartridges/cartridge_fourier_series.gd").new()
		Algorithm.BEAT_FREQUENCIES:
			return preload("res://commons/substrates/profile/cartridges/cartridge_beat_frequencies.gd").new()
		Algorithm.LISSAJOUS_1D:
			return preload("res://commons/substrates/profile/cartridges/cartridge_lissajous_1d.gd").new()
		Algorithm.NOISE_1D:
			return preload("res://commons/substrates/profile/cartridges/cartridge_noise_1d.gd").new()
		Algorithm.NOISE_OCTAVES:
			return preload("res://commons/substrates/profile/cartridges/cartridge_noise_octaves.gd").new()
		Algorithm.RANDOM_WALK:
			return preload("res://commons/substrates/profile/cartridges/cartridge_random_walk_1d.gd").new()
		Algorithm.BROWNIAN_BRIDGE:
			return preload("res://commons/substrates/profile/cartridges/cartridge_brownian_bridge.gd").new()
		Algorithm.BELL_CURVE:
			return preload("res://commons/substrates/profile/cartridges/cartridge_bell_curve.gd").new()
		Algorithm.DAMPED_OSCILLATION:
			return preload("res://commons/substrates/profile/cartridges/cartridge_damped_oscillation.gd").new()
		Algorithm.SPRING_MASS:
			return preload("res://commons/substrates/profile/cartridges/cartridge_spring_mass.gd").new()
		Algorithm.GRADIENT_DESCENT:
			return preload("res://commons/substrates/profile/cartridges/cartridge_gradient_descent.gd").new()
		Algorithm.LOGISTIC_MAP:
			return preload("res://commons/substrates/profile/cartridges/cartridge_logistic_map.gd").new()

	return preload("res://commons/substrates/profile/cartridges/cartridge_sine_wave.gd").new()


## --- Lookup name auto-resolve ---

func _resolve_algorithm_from_lookup_name() -> void:
	var lookup = get_meta("artifact_lookup_name", "")
	if lookup == "" or lookup == "profile":
		return
	var key = lookup.replace("profile_", "")
	var algo_map = {
		"sine": Algorithm.SINE_WAVE,
		"sine_wave": Algorithm.SINE_WAVE,
		"square": Algorithm.SQUARE_WAVE,
		"square_wave": Algorithm.SQUARE_WAVE,
		"saw": Algorithm.SAW_WAVE,
		"sawtooth": Algorithm.SAW_WAVE,
		"triangle": Algorithm.TRIANGLE_WAVE,
		"triangle_wave": Algorithm.TRIANGLE_WAVE,
		"fourier": Algorithm.FOURIER_SERIES,
		"fourier_series": Algorithm.FOURIER_SERIES,
		"beat": Algorithm.BEAT_FREQUENCIES,
		"beat_frequencies": Algorithm.BEAT_FREQUENCIES,
		"lissajous": Algorithm.LISSAJOUS_1D,
		"noise": Algorithm.NOISE_1D,
		"noise_octaves": Algorithm.NOISE_OCTAVES,
		"random_walk": Algorithm.RANDOM_WALK,
		"brownian": Algorithm.BROWNIAN_BRIDGE,
		"bell_curve": Algorithm.BELL_CURVE,
		"damped": Algorithm.DAMPED_OSCILLATION,
		"spring": Algorithm.SPRING_MASS,
		"gradient_descent": Algorithm.GRADIENT_DESCENT,
		"logistic": Algorithm.LOGISTIC_MAP,
	}
	if key in algo_map:
		algorithm = algo_map[key]
		print("Profile: Auto-selected '%s' from lookup_name '%s'" % [key, lookup])


## --- Grid config ---

func apply_grid_config(config: Dictionary) -> void:
	print("Profile: apply_grid_config: %s" % str(config))

	if config.has("samples"):
		sample_count = int(config["samples"])
	if config.has("interval"):
		step_interval = float(config["interval"])
	if config.has("auto_play"):
		auto_play = str(config["auto_play"]).to_lower() == "true"

	if config.has("algorithm"):
		var algo_name = str(config["algorithm"]).to_lower()
		var algo_map = {
			"sine": Algorithm.SINE_WAVE,
			"square": Algorithm.SQUARE_WAVE,
			"saw": Algorithm.SAW_WAVE,
			"triangle": Algorithm.TRIANGLE_WAVE,
			"fourier": Algorithm.FOURIER_SERIES,
			"beat": Algorithm.BEAT_FREQUENCIES,
			"lissajous": Algorithm.LISSAJOUS_1D,
			"noise": Algorithm.NOISE_1D,
			"noise_octaves": Algorithm.NOISE_OCTAVES,
			"random_walk": Algorithm.RANDOM_WALK,
			"brownian": Algorithm.BROWNIAN_BRIDGE,
			"bell_curve": Algorithm.BELL_CURVE,
			"damped": Algorithm.DAMPED_OSCILLATION,
			"spring": Algorithm.SPRING_MASS,
			"gradient_descent": Algorithm.GRADIENT_DESCENT,
			"logistic": Algorithm.LOGISTIC_MAP,
		}
		if algo_name in algo_map:
			algorithm = algo_map[algo_name]

	if auto_play and not _is_playing:
		play()
