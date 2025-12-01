# SystemsMusicSynth.gd
# Path: res://commons/audio/airpoints/SystemsMusicSynth.gd
# Agent: Agent-SynthesisEngineer (Agent B)
# Task: 023 - Create DuoSynth-style Synthesizer
# Reference: Teropa's "Discreet Music" implementation
#
# Dual-oscillator synthesizer inspired by Brian Eno's Discreet Music (1975)
# Voice 1: Sawtooth wave (harmonically rich)
# Voice 2: Sine wave (fundamental tone)
# Low-pass filtering for warm synth washes
# ADSR envelopes with long release
# LFO-based vibrato
# Part of the Audio_AirPoints system
# Renamed to avoid conflict with existing classes

extends AudioStreamPlayer
class_name SystemsMusicSynth

## The SystemsMusicListener that provides modulation data
@export var listener: SystemsMusicListener

## Enable/disable audio generation
@export var enabled: bool = true

## Stereo panning (-1 = left, 1 = right)
@export var stereo_pan: float = 0.0

## Voice mixing (0 = all sawtooth, 1 = all sine, 0.5 = equal mix)
@export var voice_mix: float = 0.5

## Harmonicity: frequency ratio between voice 1 and voice 2
@export var harmonicity: float = 1.0

# === FILTER PARAMETERS (Teropa: baseFrequency: 200, octaves: 2) ===
@export_group("Low-Pass Filter")
@export var filter_base_frequency: float = 200.0
@export var filter_octaves: float = 2.0  # Passes up to ~800 Hz
@export var filter_resonance: float = 1.0  # Q factor

# === ADSR ENVELOPE (Modified for bell/piano quality) ===
@export_group("ADSR Envelope")
@export var attack_time: float = 0.01  # Fast percussive attack (was 0.1s)
@export var decay_time: float = 0.0   # Not used
@export var sustain_level: float = 1.0
@export var release_time: float = 4.0  # Exponential decay time

# === VIBRATO (Teropa: vibratoRate: 0.5, vibratoAmount: 0.1) ===
@export_group("Vibrato")
@export var vibrato_rate: float = 0.5   # Hz
@export var vibrato_amount: float = 0.1 # Depth (0-1)

# === FREQUENCY MAPPING ===
@export_group("Frequency Mapping")
@export var min_distance: float = 0.0
@export var max_distance: float = 10.0
@export var min_frequency: float = 110.0  # Low A
@export var max_frequency: float = 880.0  # High A (2 octaves)

# === AMPLITUDE MAPPING ===
@export_group("Amplitude")
@export var max_amplitude: float = 0.7

# === SMOOTHING ===
@export var parameter_smoothing: float = 0.95  # 0-1, higher = smoother

# === AUDIO GENERATION ===

const SAMPLE_RATE = 44100
const BUFFER_SIZE = 2048
const TAU = 6.283185307179586

var _playback: AudioStreamGeneratorPlayback

# Oscillator state
var _phase_voice1: float = 0.0
var _phase_voice2: float = 0.0
var _vibrato_phase: float = 0.0

# Current synthesis parameters (smoothed)
var _current_frequency: float = 440.0
var _current_amplitude: float = 0.0
var _current_filter_cutoff: float = 400.0
var _current_vibrato_rate: float = 0.5
var _current_harmonicity: float = 1.0

# Target synthesis parameters (from modulation)
var _target_frequency: float = 440.0
var _target_amplitude: float = 0.0
var _target_filter_cutoff: float = 400.0
var _target_vibrato_rate: float = 0.5
var _target_harmonicity: float = 1.0

# ADSR envelope state
var _envelope_value: float = 0.0
var _envelope_stage: int = 0  # 0=idle, 1=attack, 2=decay, 3=sustain, 4=release
var _envelope_time: float = 0.0
var _is_note_active: bool = false

# Filter state (two-pole low-pass for stronger filtering)
var _filter_state: float = 0.0
var _filter_state2: float = 0.0

# Noise filter state (high-pass for airy quality)
var _noise_prev_input: float = 0.0
var _noise_prev_output: float = 0.0


func _ready() -> void:
	# Create AudioStreamGenerator
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = 0.1  # 100ms buffer
	
	stream = generator
	autoplay = true
	bus = "Master"
	
	# Connect to listener if set
	if listener:
		listener.modulation_updated.connect(_on_modulation_updated)
	
	# Initialize filter cutoff
	_current_filter_cutoff = filter_base_frequency * pow(2.0, filter_octaves)
	_target_filter_cutoff = _current_filter_cutoff
	
	play()
	_playback = get_stream_playback()
	
	# Set initial amplitude so we can hear something immediately
	_current_amplitude = 0.3
	_target_amplitude = 0.3
	
	# Set volume to -20dB as per Teropa (prevents distortion with delays)
	volume_db = -20.0
	
	# Start note (continuous synthesis)
	_trigger_note()
	
	print("SystemsMusicSynth: Ready and playing")
	print("  REDESIGNED FOR BELL/PIANO/AIRY QUALITY")
	print("  Voice 1: Triangle wave (soft)")
	print("  Voice 2: Sine wave")
	print("  Voice 3: Filtered noise (10% for air)")
	print("  Filter: Two-pole low-pass (aggressive)")
	print("  Attack: %.3fs (percussive)" % attack_time)
	print("  Release: %.1fs (exponential decay)" % release_time)
	print("  Frequency: %.1f Hz" % _current_frequency)
	print("  Amplitude: %.2f" % _current_amplitude)
	print("  Volume: %.1f dB" % volume_db)
	print("  Listener connected: ", listener != null)


func _process(delta: float) -> void:
	if not enabled or not _playback:
		return
	
	# Update envelope
	_update_envelope(delta)
	
	# Fill audio buffer
	_fill_buffer()


func _fill_buffer() -> void:
	if not _playback:
		return
	
	var frames_available = _playback.get_frames_available()
	if frames_available == 0:
		return
	
	var frames_to_fill = min(frames_available, BUFFER_SIZE)
	
	# Smooth parameter transitions
	var smoothing = parameter_smoothing
	_current_frequency = lerp(_current_frequency, _target_frequency, 1.0 - smoothing)
	_current_amplitude = lerp(_current_amplitude, _target_amplitude, 1.0 - smoothing)
	_current_filter_cutoff = lerp(_current_filter_cutoff, _target_filter_cutoff, 1.0 - smoothing)
	_current_vibrato_rate = lerp(_current_vibrato_rate, _target_vibrato_rate, 1.0 - smoothing)
	_current_harmonicity = lerp(_current_harmonicity, _target_harmonicity, 1.0 - smoothing)
	
	# Generate audio samples
	for i in range(frames_to_fill):
		var sample = _generate_sample()
		
		# Apply stereo panning
		var left = sample * (1.0 - max(0.0, stereo_pan))
		var right = sample * (1.0 + min(0.0, stereo_pan))
		
		_playback.push_frame(Vector2(left, right))


func _generate_sample() -> float:
	# === VIBRATO (LFO modulating pitch) ===
	var vibrato = sin(_vibrato_phase * TAU) * vibrato_amount
	var modulated_freq = _current_frequency * (1.0 + vibrato)
	
	# Advance vibrato phase
	_vibrato_phase += _current_vibrato_rate / SAMPLE_RATE
	if _vibrato_phase >= 1.0:
		_vibrato_phase = fmod(_vibrato_phase, 1.0)
	
	# === VOICE 1: TRIANGLE WAVE (softer than sawtooth) ===
	# Triangle: abs(4 * (phase - 0.5)) - 1
	var t1 = fmod(_phase_voice1, 1.0)
	var triangle = abs(4.0 * (t1 - 0.5)) - 1.0
	
	# Advance voice 1 phase
	_phase_voice1 += modulated_freq / SAMPLE_RATE
	if _phase_voice1 >= 1.0:
		_phase_voice1 = fmod(_phase_voice1, 1.0)
	
	# === VOICE 2: SINE WAVE ===
	var sine = sin(_phase_voice2 * TAU)
	
	# Advance voice 2 phase (with harmonicity)
	var voice2_freq = modulated_freq * _current_harmonicity
	_phase_voice2 += voice2_freq / SAMPLE_RATE
	if _phase_voice2 >= 1.0:
		_phase_voice2 = fmod(_phase_voice2, 1.0)
	
	# === VOICE 3: FILTERED NOISE (for airy quality) ===
	# Generate white noise
	var noise = randf() * 2.0 - 1.0
	
	# High-pass filter the noise (for breathiness)
	# Simple one-pole high-pass: y = x - prev_x + 0.95 * prev_y
	var noise_filtered = noise - _noise_prev_input + 0.95 * _noise_prev_output
	_noise_prev_input = noise
	_noise_prev_output = noise_filtered
	
	# === MIX VOICES ===
	# Triangle + Sine (as before) + Noise (10% for air)
	var mixed = lerp(triangle, sine, voice_mix) * 0.9 + noise_filtered * 0.1
	
	# === AGGRESSIVE LOW-PASS FILTER (Multi-pole for stronger effect) ===
	# Two-pole filter for better attenuation
	var cutoff_normalized = clamp(_current_filter_cutoff / SAMPLE_RATE, 0.0, 0.5)
	var alpha = cutoff_normalized * TAU
	alpha = clamp(alpha, 0.0, 1.0)
	
	# First pole
	_filter_state = _filter_state + alpha * (mixed - _filter_state)
	# Second pole (cascade for steeper rolloff)
	_filter_state2 = _filter_state2 + alpha * (_filter_state - _filter_state2)
	
	var filtered = _filter_state2
	
	# === APPLY ADSR ENVELOPE ===
	filtered *= _envelope_value
	
	# === APPLY AMPLITUDE ===
	filtered *= _current_amplitude
	
	# === SOFT CLIPPING ===
	filtered = tanh(filtered * 1.2) * 0.8
	
	return filtered


func _update_envelope(delta: float) -> void:
	if not _is_note_active:
		return
	
	_envelope_time += delta
	
	match _envelope_stage:
		1:  # Attack
			if _envelope_time < attack_time:
				_envelope_value = _envelope_time / attack_time if attack_time > 0 else 1.0
			else:
				_envelope_value = 1.0
				_envelope_stage = 2  # Move to decay
				_envelope_time = 0.0
		
		2:  # Decay
			if _envelope_time < decay_time:
				var decay_progress = _envelope_time / decay_time if decay_time > 0 else 1.0
				_envelope_value = 1.0 - (1.0 - sustain_level) * decay_progress
			else:
				_envelope_value = sustain_level
				_envelope_stage = 3  # Move to sustain
		
		3:  # Sustain
			_envelope_value = sustain_level
		
		4:  # Release
			if _envelope_time < release_time:
				# EXPONENTIAL decay (natural for bells/pianos)
				# envelope = exp(-time * decay_rate)
				var decay_rate = 3.0 / release_time  # Adjust rate for desired tail
				_envelope_value = sustain_level * exp(-_envelope_time * decay_rate)
			else:
				_envelope_value = 0.0
				_envelope_stage = 0  # Idle
				_is_note_active = false


func _trigger_note() -> void:
	"""Start a note (begin attack phase)"""
	_is_note_active = true
	_envelope_stage = 1  # Attack
	_envelope_time = 0.0


func _release_note() -> void:
	"""Release a note (begin release phase)"""
	if _envelope_stage == 1 or _envelope_stage == 2 or _envelope_stage == 3:
		_envelope_stage = 4  # Release
		_envelope_time = 0.0


func _on_modulation_updated(params: Dictionary) -> void:
	if not enabled:
		return
	
	# Extract parameters
	var distance: float = params.get("distance", 5.0)
	var proximity: float = params.get("proximity_factor", 0.0)
	var position: Vector3 = params.get("position", Vector3.ZERO)
	var velocity: Vector3 = params.get("velocity", Vector3.ZERO)
	var direction: Vector3 = params.get("direction_vector", Vector3.ZERO)
	
	# === FREQUENCY MAPPING (inverse distance) ===
	var distance_normalized = clamp(distance / max_distance, 0.0, 1.0)
	_target_frequency = lerp(max_frequency, min_frequency, distance_normalized)
	
	# === AMPLITUDE MAPPING (proximity) ===
	_target_amplitude = proximity * max_amplitude
	
	# === FILTER CUTOFF MODULATION (position.y) ===
	# Position.y modulates filter cutoff ±200 Hz
	var filter_mod = position.y * 200.0
	var base_cutoff = filter_base_frequency * pow(2.0, filter_octaves)
	_target_filter_cutoff = clamp(base_cutoff + filter_mod, filter_base_frequency, 8000.0)
	
	# === VIBRATO RATE MODULATION (velocity) ===
	# Speed modulates vibrato rate (0.3-0.8 Hz)
	var speed = velocity.length()
	_target_vibrato_rate = lerp(0.3, 0.8, clamp(speed / 5.0, 0.0, 1.0))
	
	# === HARMONICITY ===
	# CRITICAL: Must stay at 1.0 for Teropa/Eno sound
	# Both voices play the SAME frequency (not octaves)
	# This creates "fuller sound" without being "eerie"
	_target_harmonicity = 1.0  # Fixed, as per Teropa specification
	
	# Ensure note is active
	if not _is_note_active:
		_trigger_note()


## Set stereo panning from position.x
func set_pan_from_position(x: float, max_x: float = 10.0) -> void:
	stereo_pan = clamp(x / max_x, -1.0, 1.0)


## Connect to a different listener
func set_listener(new_listener: SystemsMusicListener) -> void:
	if listener and listener.modulation_updated.is_connected(_on_modulation_updated):
		listener.modulation_updated.disconnect(_on_modulation_updated)
	
	listener = new_listener
	if listener:
		listener.modulation_updated.connect(_on_modulation_updated)
