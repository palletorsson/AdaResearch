# Akayo Recreation - Unique Gritty Lead
# Character: Distorted lead from stacked sine layers with fast pitch motion
# Source: "How To Create ANY Sound from ANY Song" chapter "Unique gritty lead"
# Processing: Low/high octave sine stack, fast pitch LFO, wavefold + tanh drive

class_name AkayoGrittyLead
extends RefCounted

const SAMPLE_RATE = 44100.0

const FAST_LFO_RATE_HZ = 31.0
const FAST_LFO_DEPTH_SEMITONES = 0.36
const ATTACK_S = 0.003
const DECAY_S = 0.09
const SUSTAIN = 0.38
const RELEASE_S = 0.20
const GATE_S = 0.24
const DRIVE = 4.4
const LEVEL = 0.24


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.9:
		return 0.0
	
	var env = _envelope(dt)
	if env <= 0.0:
		return 0.0
	
	var pitch_lfo = sin(TAU * FAST_LFO_RATE_HZ * dt) + sin(TAU * FAST_LFO_RATE_HZ * 2.0 * dt) * 0.33
	var pitch_ratio = pow(2.0, (pitch_lfo * FAST_LFO_DEPTH_SEMITONES) / 12.0)
	
	var low = sin(TAU * freq * 0.5 * pitch_ratio * t)
	var high = sin(TAU * freq * 4.0 / pitch_ratio * t)
	var ring = sin(TAU * freq * 1.5 * t + low * 2.5)
	
	var source = low * 0.52 + high * 0.33 + ring * 0.15
	var folded = _fold(source * 2.6)
	var output = tanh((folded + source * 0.40) * DRIVE * 0.5)
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func _fold(x: float) -> float:
	if x > 1.0:
		return 2.0 - x
	if x < -1.0:
		return -2.0 - x
	return x


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
