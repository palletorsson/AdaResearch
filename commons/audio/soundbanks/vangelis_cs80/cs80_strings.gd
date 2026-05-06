# cs80_strings.gd
# CS-80 string pad - lush, wide, orchestral synth strings
# Character: Warm, evolving, cinematic, layered
# Source: Yamaha CS-80 with chorus/ensemble
# Processing: Slow LFO modulation, heavy reverb

# Technical anatomy:
# - Sawtooth oscillators (foundation of string sound)
# - Very slow attack (300-500ms) for orchestral swell
# - Long release for sustain pedal feel
# - Chorus/ensemble creates width
# - LPF with subtle modulation for movement

class_name CS80Strings
extends RefCounted

const SAMPLE_RATE = 44100.0

# String pad parameters
const VOICES = 4  # Detuned voices for thickness
const DETUNE_SPREAD_CENTS = 12.0  # Total spread across voices
const LPF_CUTOFF_HZ = 3000.0
const LPF_LFO_DEPTH_HZ = 500.0
const LPF_LFO_RATE_HZ = 0.3  # Very slow movement
const ATTACK_MS = 400.0  # Slow orchestral swell
const DECAY_MS = 300.0
const SUSTAIN = 0.8
const RELEASE_MS = 800.0
const CHORUS_RATE_HZ = 0.6
const CHORUS_DEPTH = 0.003  # Subtle pitch modulation


static func generate(t: float, freq: float, params: Dictionary = {}) -> float:
	var brightness = params.get("brightness", 0.5)
	var width = params.get("width", 0.8)
	
	var output = 0.0
	var total_level = 0.0
	
	# Multiple detuned voices
	for v in range(VOICES):
		var voice_detune = (float(v) / (VOICES - 1) - 0.5) * DETUNE_SPREAD_CENTS
		var detune_ratio = pow(2.0, voice_detune / 1200.0)
		
		# Chorus modulation per voice (different phase)
		var chorus_phase = float(v) * TAU / VOICES
		var chorus_mod = sin(TAU * CHORUS_RATE_HZ * t + chorus_phase) * CHORUS_DEPTH
		
		var voice_freq = freq * detune_ratio * (1.0 + chorus_mod)
		var voice_signal = _saw(t, voice_freq)
		
		# Voice level (center voices slightly louder)
		var voice_level = 1.0 - abs(float(v) / (VOICES - 1) - 0.5) * 0.3
		output += voice_signal * voice_level
		total_level += voice_level
	
	output /= total_level
	
	# Filter with slow LFO
	var lfo = sin(TAU * LPF_LFO_RATE_HZ * t)
	var cutoff = LPF_CUTOFF_HZ + lfo * LPF_LFO_DEPTH_HZ * brightness
	output = _lpf_approx(output, cutoff)
	
	# Envelope
	var env = _adsr_envelope(t, ATTACK_MS/1000.0, DECAY_MS/1000.0, SUSTAIN, RELEASE_MS/1000.0, 2.5)
	
	return clamp(output * env * 0.6, -1.0, 1.0)


static func _saw(t: float, freq: float) -> float:
	return fmod(freq * t, 1.0) * 2.0 - 1.0


static func _lpf_approx(input: float, cutoff_hz: float) -> float:
	var alpha = cutoff_hz / (cutoff_hz + SAMPLE_RATE / TAU)
	return input * alpha


static func _adsr_envelope(t: float, a: float, d: float, s: float, r: float, gate_time: float) -> float:
	if t < a:
		return t / a
	elif t < a + d:
		return 1.0 - (1.0 - s) * ((t - a) / d)
	elif t < gate_time:
		return s
	else:
		var release_t = t - gate_time
		return s * max(0.0, 1.0 - release_t / r)


static func get_duration() -> float:
	return 3.0


static func get_description() -> String:
	return "CS-80 Strings - Lush orchestral synth strings with slow attack, chorus width, and gentle filter movement."
