# Dub House Kick - Deep, warm, round
#
# Character: Deep 4-on-floor with soft click
# Source: TR-909 tuned down, dub house style
# Processing: Gentle saturation, longer body

class_name DubHouseKick
extends RefCounted

const SAMPLE_RATE = 44100.0

const PITCH_START_HZ = 140.0
const PITCH_END_HZ = 48.0
const PITCH_DECAY_S = 0.03
const BODY_DECAY_S = 0.22
const CLICK_LEVEL = 0.06
const DRIVE = 1.1
const LEVEL = 0.52


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.5:
		return 0.0
	
	var pitch_env = exp(-dt / PITCH_DECAY_S)
	var freq = PITCH_END_HZ + (PITCH_START_HZ - PITCH_END_HZ) * pitch_env
	
	var body = sin(2.0 * PI * freq * dt) * exp(-dt / BODY_DECAY_S)
	var click = sin(2.0 * PI * 2800.0 * dt) * exp(-dt / 0.004) * CLICK_LEVEL
	
	var output = (body + click) * DRIVE
	output = tanh(output)
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.5
