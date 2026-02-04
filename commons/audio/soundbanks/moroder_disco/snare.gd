# Moroder Disco Snare - Electronic, tight
# Character: Snappy, not too prominent
# Source: CR-78 style

class_name MoroderSnare
extends RefCounted

const SAMPLE_RATE = 44100.0
const LEVEL = 0.12

static func generate(t: float, freq: float = 0.0, duration: float = 0.15, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.15:
		return 0.0
	
	# Tone component (body)
	var tone_freq = 180.0
	var tone = sin(TAU * tone_freq * dt)
	var tone_env = exp(-dt * 30.0)
	
	# Noise component (snare wires)
	var noise = randf() * 2.0 - 1.0
	var noise_env = exp(-dt * 20.0)
	
	# Mix
	var output = tone * tone_env * 0.4 + noise * noise_env * 0.6
	
	return clampf(output * LEVEL, -1.0, 1.0)

static func get_duration() -> float:
	return 0.15
