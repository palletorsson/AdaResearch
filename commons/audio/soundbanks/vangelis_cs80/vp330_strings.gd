# vp330_strings.gd
# Roland VP-330 Vocoder Plus string section
# Character: Lush, synthetic, paraphonic, Solina-like
# Source: Roland VP-330 string machine section
# Processing: Built-in ensemble chorus

# Technical anatomy:
# - Paraphonic divide-down oscillators
# - Not individually articulated (all notes share filter)
# - Built-in BBD ensemble effect (essential!)
# - Very similar to Solina String Ensemble
# - Creates the "bed" for other sounds

class_name VP330Strings
extends RefCounted

const SAMPLE_RATE = 44100.0

# VP-330 strings parameters
const LPF_CUTOFF_HZ = 4000.0
const ATTACK_MS = 200.0
const DECAY_MS = 100.0
const SUSTAIN = 0.9
const RELEASE_MS = 400.0
const ENSEMBLE_RATE_1_HZ = 0.5
const ENSEMBLE_RATE_2_HZ = 0.63
const ENSEMBLE_DEPTH = 0.005
const OCTAVE_MIX = 0.3  # Mix of octave-up


static func generate(t: float, freq: float, params: Dictionary = {}) -> float:
	var brightness = params.get("brightness", 0.6)
	var ensemble_amount = params.get("ensemble", 0.8)
	var octave = params.get("octave_up", OCTAVE_MIX)
	
	# Divide-down style: multiple octaves present
	var osc_main = _saw(t, freq)
	var osc_octave = _saw(t, freq * 2.0) * octave
	
	# Ensemble effect (two LFOs at slightly different rates - BBD simulation)
	var ens1 = sin(TAU * ENSEMBLE_RATE_1_HZ * t) * ENSEMBLE_DEPTH * ensemble_amount
	var ens2 = sin(TAU * ENSEMBLE_RATE_2_HZ * t) * ENSEMBLE_DEPTH * ensemble_amount
	
	var voice1 = _saw(t, freq * (1.0 + ens1))
	var voice2 = _saw(t, freq * (1.0 - ens2))
	var voice3 = _saw(t, freq * (1.0 + ens2 * 0.7))
	
	# Mix all voices
	var mix = osc_main * 0.25 + voice1 * 0.25 + voice2 * 0.25 + voice3 * 0.25 + osc_octave
	mix /= (1.0 + octave)  # Normalize
	
	# Simple lowpass
	var cutoff = LPF_CUTOFF_HZ * brightness
	var filtered = _lpf(mix, cutoff)
	
	# Envelope
	var env = _adsr_envelope(t, ATTACK_MS/1000.0, DECAY_MS/1000.0, SUSTAIN, RELEASE_MS/1000.0, 2.5)
	
	return clamp(filtered * env * 0.5, -1.0, 1.0)


static func _saw(t: float, freq: float) -> float:
	return fmod(freq * t, 1.0) * 2.0 - 1.0


static func _lpf(input: float, cutoff_hz: float) -> float:
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
	return "VP-330 Strings - Lush paraphonic string machine with BBD ensemble chorus. The Solina-style bed sound."
