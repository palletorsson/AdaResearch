# Gypsy Woman House Snare - 909 House Style
#
# Character: Punchy, bright, not too processed
# Source: TR-909

class_name GypsySnare
extends RefCounted

const SAMPLE_RATE = 44100.0

const BODY_FREQ_HZ = 200.0
const BODY_DECAY_S = 0.035
const NOISE_DECAY_S = 0.045
const LEVEL = 0.32


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.25:
		return 0.0
	
	var body = sin(2.0 * PI * BODY_FREQ_HZ * dt) * exp(-dt / BODY_DECAY_S) * 0.4
	var noise = (randf() * 2.0 - 1.0) * exp(-dt / NOISE_DECAY_S) * 0.5
	
	return clampf((body + noise) * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.25
