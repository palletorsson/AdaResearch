# K-Pop Prog Clap - layered short clap bursts

class_name KPopProgClap
extends RefCounted

const LEVEL = 0.58
const BURSTS = [0.0, 0.011, 0.024]


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.28:
		return 0.0
	
	var out = 0.0
	for offset in BURSTS:
		var burst_t = dt - offset
		if burst_t < 0.0:
			continue
		out += _noise(t + offset * 1000.0) * exp(-burst_t * 42.0)
	
	return clampf(out * 0.42 * LEVEL, -1.0, 1.0)


static func _noise(x: float) -> float:
	return fmod(sin(x * 10873.1) * 19642.349, 1.0) * 2.0 - 1.0


static func get_duration() -> float:
	return 0.28
