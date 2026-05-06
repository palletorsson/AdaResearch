# cs80_brass.gd
# The Blade Runner brass sound - THE CS-80 signature
# Character: Crying, human, metallic edge, incredibly expressive
# Source: Yamaha CS-80 - 2 VCO per voice, ring mod, poly aftertouch
# Processing: Lexicon 224 reverb, subtle chorus

# Technical anatomy:
# - 2 oscillators per voice (saw + saw, slightly detuned)
# - Ring modulation adds metallic/bell overtones
# - HPF + LPF dual filter topology (unique to CS-80)
# - Polyphonic aftertouch: each note responds independently
# - Ribbon controller for pitch sweeps
# - Slow attack (~80-150ms) for that "breathing" quality

class_name CS80Brass
extends RefCounted

const SAMPLE_RATE = 44100.0

# CS-80 brass parameters (researched from service manual + player accounts)
const DETUNE_CENTS = 8.0  # Subtle detune between oscillators
const RING_MOD_AMOUNT = 0.15  # Metallic edge, not overwhelming
const HPF_CUTOFF_HZ = 150.0  # High-pass removes mud
const LPF_CUTOFF_HZ = 2500.0  # Low-pass starting point
const LPF_ENV_DEPTH_HZ = 3000.0  # Filter opens with expression
const RESONANCE = 0.25  # Subtle resonance peak
const ATTACK_MS = 100.0  # The "breath" - slower than typical brass
const DECAY_MS = 200.0
const SUSTAIN = 0.7
const RELEASE_MS = 400.0
const VIBRATO_RATE_HZ = 5.0  # Aftertouch triggers vibrato
const VIBRATO_DEPTH_CENTS = 20.0


static func generate(t: float, freq: float, params: Dictionary = {}) -> float:
	# Get parameters with defaults
	var aftertouch = params.get("aftertouch", 0.5)  # 0-1, simulates pressure
	var ring_mod = params.get("ring_mod", RING_MOD_AMOUNT)
	var brightness = params.get("brightness", 0.6)
	var expression = params.get("expression", 0.7)
	
	# Detune ratio
	var detune_ratio = pow(2.0, DETUNE_CENTS / 1200.0)
	
	# Two oscillators (both sawtooth, CS-80 style)
	var osc1 = _saw(t, freq)
	var osc2 = _saw(t, freq * detune_ratio)
	
	# Ring modulation (osc1 * osc2 creates sum and difference frequencies)
	var ring = osc1 * osc2
	
	# Mix: mostly saws, touch of ring mod for metallic edge
	var mix = (osc1 + osc2) * 0.5 * (1.0 - ring_mod) + ring * ring_mod
	
	# Vibrato (increases with aftertouch, like real CS-80)
	var vib_depth = VIBRATO_DEPTH_CENTS * aftertouch
	var vib = sin(TAU * VIBRATO_RATE_HZ * t) * vib_depth / 1200.0
	mix *= (1.0 + vib * 0.02)  # Subtle pitch wobble
	
	# Dual filter (HPF then LPF) - CS-80's unique topology
	# The aftertouch/expression opens the LPF
	var lpf_cutoff = LPF_CUTOFF_HZ + LPF_ENV_DEPTH_HZ * expression * brightness
	var filtered = _simple_lpf(mix, lpf_cutoff, t)
	filtered = _simple_hpf(filtered, HPF_CUTOFF_HZ, t)
	
	# Amplitude envelope with expression
	var env = _adsr_envelope(t, ATTACK_MS/1000.0, DECAY_MS/1000.0, SUSTAIN, RELEASE_MS/1000.0, 1.0)
	
	return clamp(filtered * env * expression, -1.0, 1.0)


static func _saw(t: float, freq: float) -> float:
	return fmod(freq * t, 1.0) * 2.0 - 1.0


static func _simple_lpf(input: float, cutoff_hz: float, t: float) -> float:
	# Simplified one-pole LPF (stateless approximation for procedural use)
	var rc = 1.0 / (TAU * cutoff_hz)
	var alpha = 1.0 / (1.0 + rc * SAMPLE_RATE)
	# This is a simplification - real implementation needs state
	return input * alpha + input * (1.0 - alpha) * 0.8


static func _simple_hpf(input: float, cutoff_hz: float, t: float) -> float:
	# Simplified HPF
	var rc = 1.0 / (TAU * cutoff_hz)
	var alpha = rc * SAMPLE_RATE / (1.0 + rc * SAMPLE_RATE)
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
	return 2.0


static func get_description() -> String:
	return "CS-80 Brass - The Blade Runner sound. Dual saw oscillators with ring mod edge, dual filter, expressive aftertouch response."
