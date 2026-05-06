# Rave Snare - Aggressive Distorted
# Research: rave.md
#
# Character: Hard, distorted, punchy
#
# FROM RESEARCH:
# "Heavy compression, distortion on bass elements"

class_name RaveSnare
extends RefCounted

const SAMPLE_RATE = 44100.0

const BODY_FREQ_HZ = 180.0
const BODY_DECAY_S = 0.03
const NOISE_DECAY_S = 0.04
const DISTORTION = 1.5
const LEVEL = 0.4


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.25:
		return 0.0
	
	var body = sin(2.0 * PI * BODY_FREQ_HZ * dt) * exp(-dt / BODY_DECAY_S) * 0.5
	var noise = (randf() * 2.0 - 1.0) * exp(-dt / NOISE_DECAY_S) * 0.5
	
	var output = body + noise
	output = tanh(output * DISTORTION)
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.25
