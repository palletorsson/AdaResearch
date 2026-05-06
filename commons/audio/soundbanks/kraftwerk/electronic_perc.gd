# Kraftwerk electronic percussion - sparse metallic accent

class_name KraftwerkElectronicPerc
extends RefCounted

const LEVEL = 0.24


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.22:
		return 0.0
	
	var tone_a = sin(TAU * 620.0 * dt)
	var tone_b = sin(TAU * 930.0 * dt) * 0.7
	var tone_c = sin(TAU * 1380.0 * dt) * 0.35
	var env = exp(-dt * 24.0)
	return clampf((tone_a + tone_b + tone_c) * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float) -> float:
	return generate(t, 0.0)


static func get_duration() -> float:
	return 0.22
