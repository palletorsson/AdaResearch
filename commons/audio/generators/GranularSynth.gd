extends Node
class_name GranularSynth

# Granular Synth - General Purpose
# Creates overlapping grain clouds from a source buffer.
# Port from algorithms/proceduralaudio/granular_synthesis/ audio logic.

@onready var player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var generator: AudioStreamGenerator = AudioStreamGenerator.new()
var playback: AudioStreamGeneratorPlayback

# Configuration
var sample_rate: float = 44100.0
var source_buffer: PackedFloat32Array = PackedFloat32Array()

# Grain Parameters
@export var grain_size_sec: float = 0.08
@export var grain_density: float = 12.0  # Grains per second
@export var grain_pitch: float = 1.0
@export var grain_scatter: float = 0.03  # Random variation
@export var grain_position: float = 0.0  # 0.0-1.0 position in source
@export var pan_spread: float = 0.3
@export var master_gain: float = 0.6
@export var noise_amount: float = 0.05

# Pad layer (optional background tone)
var pad_enabled: bool = false
var pad_phase: float = 0.0
var pad_frequency: float = 110.0
var pad_mix: float = 0.15

# State
var grains: Array = []
var grain_accumulator: float = 0.0
var is_playing: bool = false

@export var output_bus: String = "Master"

func _ready():
	_generate_default_source()

	generator.mix_rate = sample_rate
	generator.buffer_length = 0.2

	add_child(player)
	player.stream = generator
	player.bus = output_bus

func _generate_default_source():
	# Default: Complex harmonic waveform (like GranularSynthesis used)
	source_buffer.resize(2048)
	for i in range(source_buffer.size()):
		var t = float(i) / float(source_buffer.size())
		var sample = sin(t * TAU * 3) + sin(t * TAU * 7) * 0.5 + sin(t * TAU * 11) * 0.25
		source_buffer[i] = sample
	_normalize_buffer()

func _normalize_buffer():
	if source_buffer.is_empty():
		return
	var max_amp = 0.001
	for sample in source_buffer:
		max_amp = max(max_amp, abs(sample))
	for i in range(source_buffer.size()):
		source_buffer[i] = source_buffer[i] / max_amp

func load_buffer(buffer: PackedFloat32Array):
	source_buffer = buffer.duplicate()
	_normalize_buffer()

func generate_sine_source(harmonics: int = 8):
	source_buffer.resize(2048)
	for i in range(source_buffer.size()):
		var t = float(i) / float(source_buffer.size())
		var sample = 0.0
		for h in range(1, harmonics + 1):
			sample += sin(t * TAU * h) / float(h)
		source_buffer[i] = sample
	_normalize_buffer()

func generate_noise_source(length_sec: float = 1.0):
	# Pink noise approximation (Voss-McCartney style)
	var size = int(sample_rate * length_sec)
	source_buffer.resize(size)

	var octaves = 6
	var octave_vals = []
	for k in range(octaves):
		octave_vals.append(0.0)

	for i in range(size):
		for k in range(octaves):
			if i % (1 << k) == 0:
				octave_vals[k] = randf() * 2.0 - 1.0

		var pink = 0.0
		for k in range(octaves):
			pink += octave_vals[k]
		source_buffer[i] = pink / float(octaves)
	_normalize_buffer()

func play():
	if is_playing:
		return
	is_playing = true
	grains.clear()
	grain_accumulator = 0.0
	pad_phase = 0.0
	player.play()
	playback = player.get_stream_playback()

func stop():
	is_playing = false
	player.stop()
	grains.clear()

func play_note(freq: float, vel: float, pos: float = 0.0):
	# Map frequency to grain parameters
	grain_pitch = freq / 220.0  # Normalize around A3
	master_gain = vel
	grain_position = clamp(pos, 0.0, 1.0)
	play()

func stop_note():
	stop()

func _process(_delta):
	if not is_playing:
		return
	if not playback:
		playback = player.get_stream_playback()
		if not playback:
			return

	var frames_available = playback.get_frames_available()
	if frames_available < 1:
		return

	_process_chunk(frames_available)

func _process_chunk(frames: int):
	if source_buffer.is_empty():
		return

	for _i in range(frames):
		# Spawn grains based on density
		grain_accumulator += grain_density / sample_rate
		while grain_accumulator >= 1.0:
			_spawn_grain()
			grain_accumulator -= 1.0

		# Sum grain contributions
		var left = 0.0
		var right = 0.0

		var g = 0
		while g < grains.size():
			var grain = grains[g]
			var env_phase = float(grain.age) / float(grain.duration)
			# Hanning window envelope
			var envelope = sin(env_phase * PI)

			var sample = _get_buffer_sample(grain.position) * envelope * grain.amplitude

			left += sample * (1.0 - grain.pan * 0.5)
			right += sample * (1.0 + grain.pan * 0.5)

			grain.position += grain.increment
			grain.age += 1

			if grain.age >= grain.duration:
				grains.remove_at(g)
				continue

			grains[g] = grain
			g += 1

		# Optional pad layer
		if pad_enabled:
			pad_phase = wrapf(pad_phase + pad_frequency * TAU / sample_rate, 0.0, TAU)
			var pad = sin(pad_phase) * pad_mix
			left += pad
			right += pad

		# Noise layer
		var noise = randf_range(-1.0, 1.0) * noise_amount * 0.3
		left += noise
		right += noise

		# Apply gain and limit
		var left_sample = clamp(left * master_gain, -1.0, 1.0)
		var right_sample = clamp(right * master_gain, -1.0, 1.0)

		playback.push_frame(Vector2(left_sample, right_sample))

func _spawn_grain():
	if source_buffer.is_empty():
		return

	var duration_samples = max(16, int(grain_size_sec * sample_rate))
	var base_pos = fposmod(grain_position + randf_range(-grain_scatter, grain_scatter), 1.0)
	var start_index = base_pos * float(source_buffer.size() - 1)
	var pitch = grain_pitch * (1.0 + randf_range(-grain_scatter, grain_scatter))
	var increment = max(0.001, pitch * float(source_buffer.size()) / float(duration_samples))

	var grain = {
		"position": start_index,
		"increment": increment,
		"duration": duration_samples,
		"age": 0,
		"amplitude": randf_range(0.5, 1.0),
		"pan": clamp(randf_range(-pan_spread, pan_spread), -1.0, 1.0)
	}
	grains.append(grain)

func _get_buffer_sample(index: float) -> float:
	if source_buffer.is_empty():
		return 0.0
	var size = source_buffer.size()
	var wrapped = fposmod(index, size)
	var i0 = int(wrapped)
	var i1 = (i0 + 1) % size
	var frac = wrapped - float(i0)
	return lerp(source_buffer[i0], source_buffer[i1], frac)

# Preset configurations
func apply_preset(preset_name: String):
	match preset_name:
		"queer":
			grain_size_sec = 0.085
			grain_density = 18.0
			grain_pitch = 1.15
			grain_scatter = 0.045
			grain_position = 0.2
			pan_spread = 0.4
			master_gain = 0.65
			noise_amount = 0.06
		"sci_fi":
			grain_size_sec = 0.06
			grain_density = 24.0
			grain_pitch = 1.35
			grain_scatter = 0.06
			grain_position = 0.45
			pan_spread = 0.3
			master_gain = 0.55
			noise_amount = 0.08
		"cyberpunk":
			grain_size_sec = 0.05
			grain_density = 28.0
			grain_pitch = 0.85
			grain_scatter = 0.075
			grain_position = 0.65
			pan_spread = 0.5
			master_gain = 0.7
			noise_amount = 0.12
		"ambient":
			grain_size_sec = 0.12
			grain_density = 8.0
			grain_pitch = 1.0
			grain_scatter = 0.02
			grain_position = 0.0
			pan_spread = 0.6
			master_gain = 0.5
			noise_amount = 0.03
		"texture":
			grain_size_sec = 0.15
			grain_density = 6.0
			grain_pitch = 0.7
			grain_scatter = 0.08
			grain_position = 0.5
			pan_spread = 0.8
			master_gain = 0.4
			noise_amount = 0.02
