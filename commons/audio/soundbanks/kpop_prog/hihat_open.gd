# K-Pop Prog Open Hi-Hat - explicit open articulation

class_name KPopProgOpenHihat
extends RefCounted

const LEVEL = 0.16


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.24:
		return 0.0
	var noise = _noise(t) * 0.82
	var metal = sin(TAU * 6400.0 * dt) * 0.33 + sin(TAU * 9100.0 * dt) * 0.24
	var env = exp(-dt * 31.0)
	return clampf((noise + metal) * env * LEVEL, -1.0, 1.0)


static func _noise(x: float) -> float:
	return fmod(sin(x * 16311.2, 1.0) * 31987.19) * 2.0 - 1.0


static func get_duration() -> float:
	return 0.24
