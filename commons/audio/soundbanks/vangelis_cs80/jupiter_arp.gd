# jupiter_arp.gd
# Roland Jupiter-4 arpeggio synth - bubbling sequences
# Character: Bright, punchy, rhythmic, iconic 80s arpeggio
# Source: Jupiter-4 with built-in arpeggiator
# Processing: Ensemble effect, subtle delay

# Technical anatomy:
# - Single VCO per voice + sub oscillator
# - 4-voice polyphonic
# - Built-in arpeggiator (up, down, up/down, random)
# - Ensemble (BBD chorus) for width
# - Fast envelopes for rhythmic stabs

class_name JupiterArp
extends RefCounted

const SAMPLE_RATE = 44100.0

# Jupiter-4 arp parameters
const SUB_LEVEL = 0.35  # Sub oscillator mix
const LPF_CUTOFF_HZ = 3500.0
const LPF_ENV_DEPTH_HZ = 2000.0
const RESONANCE = 0.3
const ATTACK_MS = 5.0  # Very fast for arps
const DECAY_MS = 150.0
const SUSTAIN = 0.3
const RELEASE_MS = 100.0
const ENSEMBLE_RATE_HZ = 0.8
const ENSEMBLE_DEPTH = 0.004


static func generate(t: float, freq: float, params: Dictionary = {}) -> float:
	var brightness = params.get("brightness", 0.7)
	var ensemble = params.get("ensemble", 0.6)
	var decay_time = params.get("decay", DECAY_MS) / 1000.0
	
	# Main oscillator (sawtooth)
	var osc_main = _saw(t, freq)
	
	# Sub oscillator (one octave down, square)
	var osc_sub = _square(t, freq * 0.5) * SUB_LEVEL
	
	# Ensemble effect (stereo chorus simulation)
	var ens_mod1 = sin(TAU * ENSEMBLE_RATE_HZ * t) * ENSEMBLE_DEPTH * ensemble
	var ens_mod2 = sin(TAU * ENSEMBLE_RATE_HZ * 1.1 * t + PI/3) * ENSEMBLE_DEPTH * ensemble
	
	var voice1 = _saw(t, freq * (1.0 + ens_mod1))
	var voice2 = _saw(t, freq * (1.0 + ens_mod2))
	
	var mix = (osc_main * 0.4 + voice1 * 0.3 + voice2 * 0.3) + osc_sub
	
	# Filter with fast envelope
	var filter_env = exp(-t / 0.08)  # Fast decay
	var cutoff = LPF_CUTOFF_HZ + filter_env * LPF_ENV_DEPTH_HZ * brightness
	var filtered = _lpf(mix, cutoff, RESONANCE)
	
	# Amplitude envelope (fast for rhythmic effect)
	var env = _adsr_envelope(t, ATTACK_MS/1000.0, decay_time, SUSTAIN, RELEASE_MS/1000.0, 0.3)
	
	return clamp(filtered * env * 0.7, -1.0, 1.0)


static func _saw(t: float, freq: float) -> float:
	return fmod(freq * t, 1.0) * 2.0 - 1.0


static func _square(t: float, freq: float) -> float:
	return 1.0 if fmod(freq * t, 1.0) < 0.5 else -1.0


static func _lpf(input: float, cutoff_hz: float, reso: float) -> float:
	var alpha = cutoff_hz / (cutoff_hz + SAMPLE_RATE / TAU)
	return input * alpha * (1.0 + reso * 2.5 * (1.0 - alpha))


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
	return 0.5


static func get_description() -> String:
	return "Jupiter-4 Arp - Punchy arpeggio synth with sub oscillator, ensemble chorus, fast envelopes for rhythmic sequences."
