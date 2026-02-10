# K-Pop Prog Snare - bright clap/snare hybrid

class_name KPopProgSnare
extends RefCounted

const LEVEL = 0.68


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.35:
		return 0.0
	
	var noise = _noise(t) * exp(-dt * 20.0)
	var tone_a = sin(TAU * 205.0 * dt) * exp(-dt * 26.0) * 0.32
	var tone_b = sin(TAU * 330.0 * dt) * exp(-dt * 30.0) * 0.22
	return clampf((noise * 0.72 + tone_a + tone_b) * LEVEL, -1.0, 1.0)


static func _noise(x: float) -> float:
	return fract(sin(x * 14983.2) * 43758.5453) * 2.0 - 1.0


static func get_duration() -> float:
	return 0.35
