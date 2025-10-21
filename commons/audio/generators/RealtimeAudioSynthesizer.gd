# RealtimeAudioSynthesizer.gd
# Path: res://commons/audio/generators/RealtimeAudioSynthesizer.gd
# Real-time audio synthesizer for live pattern generation

extends AudioStreamPlayer
class_name RealtimeAudioSynthesizer

# Audio generation parameters
var sample_rate := 44100
var buffer_size := 1024
var playback: AudioStreamGeneratorPlayback

# Synthesis state
var phase := 0.0
var time := 0.0

# Pattern parameters
var current_pattern := {}
var pattern_index := 0
var bpm := 120.0
var beat_duration := 0.0

# Effects parameters
var trance_gate_active := false
var trance_gate_phase := 0.0
var trance_gate_speed := 1.5
var trance_gate_depth := 45.0
var trance_gate_shape := 1.0

var filter_cutoff := 0.5
var filter_resonance := 0.7
var filter_state := [0.0, 0.0]

var delay_time := 0.7
var delay_buffer := []
var delay_index := 0

var pan_value := 0.5

# Scale degrees (G minor)
var scale_notes := [0, 2, 3, 5, 7, 8, 10]  # G minor scale degrees
var root_note := 67 - 14  # G4 (MIDI 67) transposed down

func _ready():
	# Setup audio stream
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = sample_rate
	generator.buffer_length = 0.1
	stream = generator
	play()
	
	beat_duration = 60.0 / bpm
	
	# Initialize delay buffer (0.7 seconds)
	var delay_samples = int(delay_time * sample_rate)
	delay_buffer.resize(delay_samples)
	delay_buffer.fill(0.0)
	
	playback = get_stream_playback()
	
	# Setup patterns from your code
	setup_patterns()

func setup_patterns():
	# Pattern 1: n("@", add(-14))
	var pattern1 = {
		"notes": [0],
		"transpose": -14,
		"scale": "g:minor",
		"synth": "supersaw",
		"octave": 2,
		"trance_gate": [1.5, 5, 45, 1],
		"filter_cutoff": 0.5,
		"lpenv": 2
	}
	
	# Pattern 2: n("0@2 <-7 [-5 -2]>@3 <0 -3 2 1>@3", add(7))
	var pattern2 = {
		"notes": [0, 0, -7, -5, -2, -5, -2, 0, -3, 2, 1],
		"durations": [2, 2, 3, 1, 1, 1, 1, 3, 1, 1, 1],
		"transpose": 7,
		"scale": "g:minor",
		"synth": "supersaw",
		"octave": 3,
		"trance_gate": [1.5, 5, 45, 1],
		"delay": 0.7,
		"filter_cutoff": 0.593,
		"lpenv": 2
	}
	
	current_pattern = pattern2

func _process(delta):
	if playback == null:
		return
	
	time += delta
	
	# Fill audio buffer
	var frames_available = playback.get_frames_available()
	if frames_available > 0:
		fill_buffer(frames_available)

func fill_buffer(frames: int):
	for i in range(frames):
		var sample = generate_sample()
		
		# Apply trance gate
		if trance_gate_active:
			sample = apply_trance_gate(sample)
		
		# Apply resonant low-pass filter
		sample = apply_rlpf(sample)
		
		# Apply delay
		sample = apply_delay(sample)
		
		# Stereo output with panning
		var left = sample * (1.0 - pan_value)
		var right = sample * pan_value
		
		playback.push_frame(Vector2(left, right))
		
		time += 1.0 / sample_rate

func generate_sample() -> float:
	# Get current note from pattern
	var note_degree = get_current_note()
	var midi_note = scale_to_midi(note_degree)
	var freq = midi_to_freq(midi_note)
	
	# Supersaw synthesis (multiple detuned saws)
	var sample = 0.0
	var num_oscillators = 7
	var detune_amount = 0.1
	
	for osc in range(num_oscillators):
		var detune = (osc - num_oscillators / 2.0) * detune_amount
		var detuned_freq = freq * (1.0 + detune * 0.01)
		sample += generate_saw(detuned_freq)
	
	sample /= num_oscillators
	
	return sample * 0.3  # Volume control

func generate_saw(freq: float) -> float:
	var period = sample_rate / freq
	phase += 1.0
	if phase >= period:
		phase -= period
	return (phase / period) * 2.0 - 1.0

func apply_trance_gate(sample: float) -> float:
	trance_gate_phase += trance_gate_speed * (bpm / 60.0) / sample_rate
	if trance_gate_phase >= 1.0:
		trance_gate_phase -= 1.0
	
	# Square wave gate with adjustable depth
	var gate = 1.0 if sin(trance_gate_phase * TAU * trance_gate_depth) > 0.0 else 0.0
	return sample * gate

func apply_rlpf(sample: float) -> float:
	# Simple resonant low-pass filter (biquad)
	var cutoff_freq = filter_cutoff * 10000.0 + 100.0
	var omega = TAU * cutoff_freq / sample_rate
	var cos_omega = cos(omega)
	var alpha = sin(omega) / (2.0 * filter_resonance)
	
	var b0 = (1.0 - cos_omega) / 2.0
	var b1 = 1.0 - cos_omega
	var b2 = (1.0 - cos_omega) / 2.0
	var a0 = 1.0 + alpha
	var a1 = -2.0 * cos_omega
	var a2 = 1.0 - alpha
	
	var output = (b0 * sample + b1 * filter_state[0] + b2 * filter_state[1] - a1 * filter_state[0] - a2 * filter_state[1]) / a0
	
	filter_state[1] = filter_state[0]
	filter_state[0] = output
	
	return output

func apply_delay(sample: float) -> float:
	var delayed = delay_buffer[delay_index]
	delay_buffer[delay_index] = sample + delayed * 0.4
	delay_index = (delay_index + 1) % delay_buffer.size()
	
	return sample + delayed * 0.5

func get_current_note() -> int:
	# Simplified pattern playback
	if current_pattern["notes"].size() > 0:
		return current_pattern["notes"][pattern_index % current_pattern["notes"].size()] + current_pattern["transpose"]
	return 0

func scale_to_midi(degree: int) -> int:
	var octave_offset = int(degree / 7)
	var scale_degree = degree % 7
	if scale_degree < 0:
		scale_degree += 7
		octave_offset -= 1
	
	return root_note + scale_notes[scale_degree] + octave_offset * 12 + current_pattern.get("octave", 0) * 12

func midi_to_freq(midi_note: int) -> float:
	return 440.0 * pow(2.0, (midi_note - 69) / 12.0)

# Control functions
func set_trance_gate(speed: float, cycles: int, depth: float, shape: float):
	trance_gate_active = true
	trance_gate_speed = speed
	trance_gate_depth = depth
	trance_gate_shape = shape

func set_filter(cutoff: float):
	filter_cutoff = clamp(cutoff, 0.0, 1.0)

func set_pan(value: float):
	pan_value = clamp(value, 0.0, 1.0)

func set_pattern(pattern: Dictionary):
	current_pattern = pattern
	pattern_index = 0

func set_bpm(new_bpm: float):
	bpm = new_bpm
	beat_duration = 60.0 / bpm

# Pattern management
func next_pattern():
	pattern_index = (pattern_index + 1) % current_pattern["notes"].size()

func reset_pattern():
	pattern_index = 0

# Integration with existing audio system
func get_audio_parameters() -> Dictionary:
	return {
		"bpm": bpm,
		"filter_cutoff": filter_cutoff,
		"filter_resonance": filter_resonance,
		"trance_gate_active": trance_gate_active,
		"trance_gate_speed": trance_gate_speed,
		"trance_gate_depth": trance_gate_depth,
		"delay_time": delay_time,
		"pan": pan_value
	}

func set_audio_parameters(params: Dictionary):
	if "bpm" in params:
		set_bpm(params["bpm"])
	if "filter_cutoff" in params:
		set_filter(params["filter_cutoff"])
	if "filter_resonance" in params:
		filter_resonance = clamp(params["filter_resonance"], 0.0, 1.0)
	if "trance_gate_active" in params:
		trance_gate_active = params["trance_gate_active"]
	if "trance_gate_speed" in params:
		trance_gate_speed = params["trance_gate_speed"]
	if "trance_gate_depth" in params:
		trance_gate_depth = params["trance_gate_depth"]
	if "delay_time" in params:
		delay_time = params["delay_time"]
		# Reinitialize delay buffer
		var delay_samples = int(delay_time * sample_rate)
		delay_buffer.resize(delay_samples)
		delay_buffer.fill(0.0)
	if "pan" in params:
		set_pan(params["pan"])




