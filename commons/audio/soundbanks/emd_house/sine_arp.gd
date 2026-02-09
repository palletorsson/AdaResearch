# Akayo Recreation - Beautiful Sine Arp
# Character: Soft plucky arp with a slightly crushed haze and delayed bloom
# Source: "How To Create ANY Sound from ANY Song" chapter "Beautiful sine arp"
# Processing: Triangle+sine core, gentle attack, light downsample grit, two delay taps

class_name AkayoSineArp
extends RefCounted

const SAMPLE_RATE = 44100.0

const DETUNE_CENTS = 4.0
const ATTACK_S = 0.018
const DECAY_S = 0.20
const SUSTAIN = 0.26
const RELEASE_S = 0.32
const GATE_S = 0.34

const BIT_STEPS = 36.0
const DELAY_TAP_A_S = 0.14
const DELAY_TAP_B_S = 0.29
const LEVEL = 0.24


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 1.1:
		return 0.0
	
	var env = _envelope(dt)
	if env <= 0.0:
		return 0.0
	
	var dry = _source(t, freq)
	var wet = 0.0
	
	if dt > DELAY_TAP_A_S:
		var env_a = exp(-(dt - DELAY_TAP_A_S) / 0.33)
		wet += _source(t - DELAY_TAP_A_S, freq) * env_a * 0.28
	
	if dt > DELAY_TAP_B_S:
		var env_b = exp(-(dt - DELAY_TAP_B_S) / 0.34)
		wet += _source(t - DELAY_TAP_B_S, freq) * env_b * 0.17
	
	var output = dry + wet
	output = tanh(output * 1.35)
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func _source(t: float, freq: float) -> float:
	var detune_ratio = pow(2.0, DETUNE_CENTS / 1200.0)
	var tri_a = _triangle(t, freq * detune_ratio)
	var tri_b = _triangle(t, freq / detune_ratio)
	var sine = sin(TAU * freq * t)
	var upper = sin(TAU * freq * 2.0 * t)
	
	var raw = (tri_a + tri_b) * 0.32 + sine * 0.36 + upper * 0.07
	raw = lerp(raw, sine, 0.22)  # soften the front edge
	
	# Light bit-crush texture for subtle artifacting.
	var crushed = floor((raw * 0.5 + 0.5) * BIT_STEPS) / BIT_STEPS
	crushed = crushed * 2.0 - 1.0
	var textured = lerp(raw, crushed, 0.18)
	
	# Deterministic "noise-like" sprinkle without state.
	var noise_seed = sin((t + 0.37) * 9123.17) * 43758.5453
	var noise = (noise_seed - floor(noise_seed)) * 2.0 - 1.0
	return textured + noise * 0.012


static func _triangle(t: float, freq: float) -> float:
	return 2.0 * abs(2.0 * fmod(freq * t, 1.0) - 1.0) - 1.0


static func _envelope(dt: float) -> float:
	if dt < ATTACK_S:
		return dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		var decay_p = (dt - ATTACK_S) / DECAY_S
		return 1.0 - (1.0 - SUSTAIN) * decay_p
	elif dt < GATE_S:
		return SUSTAIN
	else:
		return SUSTAIN * exp(-(dt - GATE_S) / RELEASE_S)


static func get_duration() -> float:
	return 1.1
