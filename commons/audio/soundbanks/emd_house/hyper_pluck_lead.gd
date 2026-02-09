# EMD House Recreation - Hyper Pluck Lead
# Character: Bright, snappy pluck with stereo-like shimmer and crisp transient
# Source: Festival/future-house style pluck stacks
# Processing: Layered saw + sine, sharp envelope, short delays, soft clipping

class_name EmdHyperPluckLead
extends RefCounted

const SAMPLE_RATE = 44100.0

const DETUNE_CENTS = 8.0
const ATTACK_S = 0.001
const DECAY_S = 0.11
const SUSTAIN = 0.12
const RELEASE_S = 0.14
const GATE_S = 0.20
const TAP_A_S = 0.08
const TAP_B_S = 0.16
const LEVEL = 0.26


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.9:
		return 0.0

	var env = _envelope(dt)
	if env <= 0.0:
		return 0.0

	var dry = _source(t, freq)
	var wet = 0.0

	if dt > TAP_A_S:
		wet += _source(t - TAP_A_S, freq) * exp(-(dt - TAP_A_S) / 0.16) * 0.24
	if dt > TAP_B_S:
		wet += _source(t - TAP_B_S, freq) * exp(-(dt - TAP_B_S) / 0.18) * 0.14

	var output = tanh((dry + wet) * 1.55)
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func _source(t: float, freq: float) -> float:
	var ratio = pow(2.0, DETUNE_CENTS / 1200.0)
	var saw_a = fmod(freq * ratio * t, 1.0) * 2.0 - 1.0
	var saw_b = fmod(freq / ratio * t, 1.0) * 2.0 - 1.0
	var sine = sin(TAU * freq * t)
	var air = sin(TAU * freq * 3.0 * t) * 0.12
	return (saw_a + saw_b) * 0.34 + sine * 0.42 + air


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
	return 0.9
