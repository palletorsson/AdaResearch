# Gypsy Woman House Kick - 909 House Style
#
# Character: Punchy, warm, bouncy
# Source: TR-909 (the house music standard)
# Processing: Warm, not too aggressive

class_name GypsyKick
extends RefCounted

const SAMPLE_RATE = 44100.0

# 909 house kick - warm and bouncy
const PITCH_START_HZ = 120.0
const PITCH_END_HZ = 50.0
const PITCH_DECAY_S = 0.028
const BODY_DECAY_S = 0.12
const CLICK_LEVEL = 0.1
const LEVEL = 0.52


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.4:
		return 0.0
	
	var pitch_env = exp(-dt / PITCH_DECAY_S)
	var freq = PITCH_END_HZ + (PITCH_START_HZ - PITCH_END_HZ) * pitch_env
	
	var body = sin(2.0 * PI * freq * dt) * exp(-dt / BODY_DECAY_S)
	var click = sin(2.0 * PI * 3000.0 * dt) * exp(-dt / 0.003) * CLICK_LEVEL
	
	# Slight warmth
	var output = body + click
	output = tanh(output * 1.1)
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.4
