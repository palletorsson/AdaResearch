# K-Pop Prog Kick - punchy hybrid electronic kick

class_name KPopProgKick
extends RefCounted

const LEVEL = 0.92


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.55:
		return 0.0
	
	var pitch_env = clampf(dt / 0.075, 0.0, 1.0)
	var freq = lerpf(140.0, 46.0, pitch_env)
	var body = sin(TAU * freq * dt)
	var click = sin(TAU * 1900.0 * dt) * exp(-dt * 145.0)
	var env = exp(-dt * 8.8)
	return clampf((body * 0.9 + click * 0.18) * env * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.55
