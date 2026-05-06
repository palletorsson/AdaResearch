# Dub House Kick - Deep, warm, round
#
# Character: Deep 4-on-floor with soft click
# Source: TR-909 tuned down, dub house style
# Processing: Gentle saturation, longer body

class_name DubHouseKick
extends RefCounted

const SAMPLE_RATE = 44100.0

# Tuned for Basic Channel / Chain Reaction depth
const PITCH_START_HZ = 130.0   # Slightly lower start - darker attack
const PITCH_END_HZ = 42.0      # Deeper fundamental (sub territory)
const PITCH_DECAY_S = 0.035    # Slightly longer pitch sweep
const BODY_DECAY_S = 0.32      # LONGER body - dub house kicks sustain
const CLICK_LEVEL = 0.04       # Even softer click - all sub, no snap
const DRIVE = 1.05             # Less drive - cleaner for dub space
const LEVEL = 0.55             # Slightly louder to compensate for softer character


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
