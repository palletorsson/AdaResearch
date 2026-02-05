# Dub House Snare - Short and airy
#
# Character: Tight, airy snare with a soft body
# Source: 909-style snare tuned for dub space
# Processing: Light saturation

class_name DubHouseSnare
extends RefCounted

const SAMPLE_RATE = 44100.0

const BODY_HZ = 200.0
const BODY_DECAY_S = 0.06
const NOISE_DECAY_S = 0.16
const TONE_MIX = 0.45
const NOISE_MIX = 0.55
const LEVEL = 0.26


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.3:
		return 0.0
	
	var body = sin(2.0 * PI * BODY_HZ * dt) * exp(-dt / BODY_DECAY_S)
	var noise = (randf() * 2.0 - 1.0) * sin(2.0 * PI * 3000.0 * dt)
	noise *= exp(-dt / NOISE_DECAY_S)
	
	var output = body * TONE_MIX + noise * NOISE_MIX
	output = tanh(output * 1.2)
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.3
