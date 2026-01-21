# FractalSoundGenerator.gd
# Generates self-similar audio patterns at multiple time scales
# Fractal structure: same patterns appear at beat, bar, phrase, and section levels

extends AudioStreamPlayer
class_name FractalSoundGenerator

# Audio parameters
var sample_rate := 44100
var buffer_size := 1024
var playback: AudioStreamGeneratorPlayback

# Time tracking
var time := 0.0
var beat_time := 0.0
var phase := 0.0

# Fractal parameters
@export var bpm := 120.0
@export var fractal_depth := 4  # How many levels of self-similarity
@export var base_pattern: Array[float] = [1.0, 0.0, 0.5, 0.0, 0.75, 0.0, 0.25, 0.0]  # Basic rhythm

# Synthesis parameters
@export var base_frequency := 110.0  # A2
@export var waveform := "sine"  # sine, saw, square, triangle
@export var filter_cutoff := 0.6
@export var filter_resonance := 0.3

# Scale (minor pentatonic by default)
var scale_intervals := [0, 3, 5, 7, 10]  # Minor pentatonic
var octave_range := 3

# Fractal state
var fractal_levels: Array[Dictionary] = []
var current_notes: Array[float] = []

# Filter state
var filter_state := [0.0, 0.0]

signal beat_triggered(level: int, intensity: float)
signal note_played(frequency: float, velocity: float)

func _ready():
	_setup_audio()
	_initialize_fractal_levels()

func _setup_audio():
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = sample_rate
	generator.buffer_length = 0.1
	stream = generator
	play()
	playback = get_stream_playback()

func _initialize_fractal_levels():
	"""Initialize fractal levels - each level operates at different time scale"""
	fractal_levels.clear()

	var beat_duration = 60.0 / bpm

	for i in range(fractal_depth):
		var scale_factor = pow(2, i)  # Each level is 2x slower
		fractal_levels.append({
			"time_scale": scale_factor,
			"duration": beat_duration * scale_factor,
			"pattern": _generate_pattern_at_scale(i),
			"current_step": 0,
			"accumulated_time": 0.0,
			"intensity": 1.0 / (i + 1)  # Deeper levels are quieter
		})

	print("FractalSoundGenerator: Initialized %d fractal levels" % fractal_depth)

func _generate_pattern_at_scale(level: int) -> Array[float]:
	"""Generate pattern for a specific fractal level"""
	var pattern: Array[float] = []

	# Use base pattern but transform it based on level
	var pattern_length = base_pattern.size()

	for i in range(pattern_length):
		var value = base_pattern[i]

		# Apply fractal transformation
		# Higher levels get modified versions of the pattern
		if level > 0:
			# Rotate pattern
			var rotated_index = (i + level * 2) % pattern_length
			value = base_pattern[rotated_index]

			# Scale intensity
			value *= pow(0.7, level)

			# Add variation
			if randf() < 0.3:
				value *= randf_range(0.5, 1.5)

		pattern.append(value)

	return pattern

func _process(delta):
	if playback == null:
		return

	time += delta

	# Update each fractal level
	_update_fractal_levels(delta)

	# Fill audio buffer
	var frames_available = playback.get_frames_available()
	if frames_available > 0:
		_fill_audio_buffer(frames_available)

func _update_fractal_levels(delta: float):
	"""Update timing for each fractal level and trigger events"""
	for i in range(fractal_levels.size()):
		var level = fractal_levels[i]
		level.accumulated_time += delta

		var step_duration = level.duration / base_pattern.size()

		while level.accumulated_time >= step_duration:
			level.accumulated_time -= step_duration

			# Get current pattern value
			var pattern_value = level.pattern[level.current_step]

			if pattern_value > 0.01:
				_trigger_note_at_level(i, pattern_value)
				beat_triggered.emit(i, pattern_value)

			# Advance step
			level.current_step = (level.current_step + 1) % level.pattern.size()

func _trigger_note_at_level(level: int, intensity: float):
	"""Trigger a note based on fractal level"""
	# Choose note from scale based on level and time
	var scale_index = (level + int(time * 2)) % scale_intervals.size()
	var interval = scale_intervals[scale_index]

	# Octave based on level (higher levels = lower octaves)
	var octave = octave_range - level
	octave = clamp(octave, 0, octave_range)

	var frequency = base_frequency * pow(2, octave + interval / 12.0)

	# Add to current notes with envelope
	current_notes.append(frequency)

	# Limit polyphony
	while current_notes.size() > 6:
		current_notes.pop_front()

	note_played.emit(frequency, intensity)

func _fill_audio_buffer(frames: int):
	"""Fill the audio buffer with fractal-generated sound"""
	for i in range(frames):
		var sample = 0.0

		# Generate sound for each active note
		for freq in current_notes:
			sample += _generate_waveform(freq) * 0.2

		# Apply filter
		sample = _apply_filter(sample)

		# Apply envelope decay to notes
		_decay_notes()

		# Clamp output
		sample = clamp(sample, -1.0, 1.0)

		playback.push_frame(Vector2(sample, sample))
		phase += 1.0 / sample_rate

func _generate_waveform(frequency: float) -> float:
	"""Generate waveform sample at given frequency"""
	var t = phase * frequency
	var value = 0.0

	match waveform:
		"sine":
			value = sin(t * TAU)
		"saw":
			value = 2.0 * fmod(t, 1.0) - 1.0
		"square":
			value = 1.0 if fmod(t, 1.0) < 0.5 else -1.0
		"triangle":
			var p = fmod(t, 1.0)
			value = 4.0 * abs(p - 0.5) - 1.0

	return value

func _apply_filter(sample: float) -> float:
	"""Simple low-pass filter"""
	var cutoff = filter_cutoff
	var resonance = filter_resonance

	# 2-pole low-pass filter
	var f = cutoff * 0.5
	var q = 1.0 - resonance * 0.9

	filter_state[0] += f * (sample - filter_state[0] + q * (filter_state[0] - filter_state[1]))
	filter_state[1] += f * (filter_state[0] - filter_state[1])

	return filter_state[1]

func _decay_notes():
	"""Gradually remove notes (simple envelope)"""
	if randf() < 0.001:  # Random note removal for organic feel
		if current_notes.size() > 0:
			current_notes.pop_front()

# Public API
func set_base_pattern(pattern: Array[float]):
	"""Set the base rhythmic pattern"""
	base_pattern = pattern
	_initialize_fractal_levels()

func set_scale(intervals: Array[int]):
	"""Set the musical scale"""
	scale_intervals = intervals

func randomize_pattern():
	"""Generate a new random base pattern"""
	base_pattern.clear()
	for i in range(8):
		base_pattern.append(randf() if randf() > 0.3 else 0.0)
	_initialize_fractal_levels()

func set_fractal_depth(depth: int):
	"""Change number of fractal levels"""
	fractal_depth = clamp(depth, 1, 6)
	_initialize_fractal_levels()

# Preset patterns
func use_preset(preset_name: String):
	"""Apply a preset pattern"""
	match preset_name:
		"minimal":
			base_pattern = [1.0, 0.0, 0.0, 0.0, 0.5, 0.0, 0.0, 0.0]
		"complex":
			base_pattern = [1.0, 0.25, 0.5, 0.25, 0.75, 0.25, 0.5, 0.125]
		"syncopated":
			base_pattern = [1.0, 0.0, 0.5, 0.75, 0.0, 0.5, 0.25, 0.0]
		"dense":
			base_pattern = [1.0, 0.5, 0.75, 0.5, 1.0, 0.5, 0.75, 0.5]
		"sparse":
			base_pattern = [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.0]

	_initialize_fractal_levels()
