# K-Pop Prog Hi-Hat - crisp closed/open hat pair

class_name KPopProgHihat
extends RefCounted

const LEVEL = 0.18


static func generate_closed(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.09:
		return 0.0
	var n = _noise(t) * 0.9
	var metal = sin(TAU * 7600.0 * dt) * 0.35 + sin(TAU * 9800.0 * dt) * 0.2
	var env = exp(-dt * 82.0)
	return clampf((n + metal) * env * LEVEL, -1.0, 1.0)


static func generate(t: float, trigger_time: float = 0.0, open: bool = false) -> float:
	if not open:
		return generate_closed(t, trigger_time)
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.22:
		return 0.0
	var n = _noise(t + 15.0) * 0.85
	var metal = sin(TAU * 6800.0 * dt) * 0.3 + sin(TAU * 9200.0 * dt) * 0.26
	var env = exp(-dt * 35.0)
	return clampf((n + metal) * env * LEVEL * 0.9, -1.0, 1.0)


static func _noise(x: float) -> float:
	return fract(sin(x * 20344.7) * 9241.73) * 2.0 - 1.0


static func get_duration() -> float:
	return 0.22
