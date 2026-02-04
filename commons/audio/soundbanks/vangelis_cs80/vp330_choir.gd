# vp330_choir.gd
# Roland VP-330 Vocoder Plus choir section
# Character: Ethereal, synthetic choir, angelic, otherworldly
# Source: Roland VP-330 - vocoder + string machine hybrid
# Processing: Built-in ensemble, heavy reverb

# Technical anatomy:
# - Paraphonic divide-down oscillators (organ-style)
# - Formant filters simulating vowels (ah, oh, ee)
# - Not a true vocoder here - the "human voice" mode
# - Ensemble chorus for width
# - Very slow attack for "ahh" choir swell

class_name VP330Choir
extends RefCounted

const SAMPLE_RATE = 44100.0

# VP-330 choir parameters
# Formant frequencies for "ah" vowel (approximate)
const FORMANT_1_HZ = 800.0  # First formant
const FORMANT_2_HZ = 1200.0  # Second formant
const FORMANT_3_HZ = 2500.0  # Third formant
const FORMANT_Q = 8.0  # Resonance of formants
const ATTACK_MS = 500.0  # Very slow choir swell
const DECAY_MS = 200.0
const SUSTAIN = 0.85
const RELEASE_MS = 1000.0
const ENSEMBLE_RATE_HZ = 0.5
const ENSEMBLE_DEPTH = 0.006
const VIBRATO_RATE_HZ = 5.5
const VIBRATO_DEPTH = 0.008


static func generate(t: float, freq: float, params: Dictionary = {}) -> float:
	var vowel = params.get("vowel", 0.5)  # 0=oh, 0.5=ah, 1=ee
	var vibrato_amount = params.get("vibrato", 0.4)
	var width = params.get("width", 0.7)
	
	# Vibrato (choir-like)
	var vib = sin(TAU * VIBRATO_RATE_HZ * t) * VIBRATO_DEPTH * vibrato_amount
	var vibrato_freq = freq * (1.0 + vib)
	
	# Base waveform: sawtooth (bright, harmonically rich)
	var base = _saw(t, vibrato_freq)
	
	# Add slight detuned voices for ensemble
	var ens1 = sin(TAU * ENSEMBLE_RATE_HZ * t) * ENSEMBLE_DEPTH * width
	var ens2 = sin(TAU * ENSEMBLE_RATE_HZ * 1.2 * t + PI/2) * ENSEMBLE_DEPTH * width
	var voice1 = _saw(t, vibrato_freq * (1.0 + ens1))
	var voice2 = _saw(t, vibrato_freq * (1.0 + ens2))
	
	var mix = (base * 0.4 + voice1 * 0.3 + voice2 * 0.3)
	
	# Formant filtering (simulate vowel)
	# Interpolate formant frequencies based on vowel parameter
	var f1 = lerp(600.0, 800.0, vowel) if vowel < 0.5 else lerp(800.0, 300.0, (vowel - 0.5) * 2)
	var f2 = lerp(900.0, 1200.0, vowel) if vowel < 0.5 else lerp(1200.0, 2300.0, (vowel - 0.5) * 2)
	
	# Apply formant peaks (simplified bandpass resonances)
	var formant_signal = _bandpass(mix, f1, 6.0) * 0.6 + _bandpass(mix, f2, 6.0) * 0.4
	
	# Mix formant with original for more body
	var filtered = mix * 0.3 + formant_signal * 0.7
	
	# Amplitude envelope
	var env = _adsr_envelope(t, ATTACK_MS/1000.0, DECAY_MS/1000.0, SUSTAIN, RELEASE_MS/1000.0, 3.0)
	
	return clamp(filtered * env * 0.5, -1.0, 1.0)


static func _saw(t: float, freq: float) -> float:
	return fmod(freq * t, 1.0) * 2.0 - 1.0


static func _bandpass(input: float, center_hz: float, q: float) -> float:
	# Simplified bandpass approximation
	var bw = center_hz / q
	var alpha = bw / (bw + SAMPLE_RATE / TAU)
	return input * alpha * q * 0.3


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
	return 4.0


static func get_description() -> String:
	return "VP-330 Choir - Ethereal synthetic choir with formant filtering, ensemble width, slow swelling attack. The voice of the machine."
