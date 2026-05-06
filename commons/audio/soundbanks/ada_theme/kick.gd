# Ada Theme Kick - Soft Pillow Kick
#
# Character: Gentle, low, not punchy - supportive not driving
# Like a heartbeat in the background

class_name AdaKick
extends RefCounted

const SAMPLE_RATE = 44100.0

const PITCH_START = 80.0
const PITCH_END = 45.0
const PITCH_DECAY = 0.08
const AMP_DECAY = 0.25
const LEVEL = 0.35


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.5:
		return 0.0
	
	# Soft amplitude envelope - no sharp attack
	var env = 0.0
	if dt < 0.01:
		env = dt / 0.01  # Very soft attack
	else:
		env = exp(-dt / AMP_DECAY)
	
	# Gentle pitch sweep
	var pitch_env = exp(-dt / PITCH_DECAY)
	var freq = PITCH_END + (PITCH_START - PITCH_END) * pitch_env
	
	# Sine body (no click)
	var output = sin(2.0 * PI * freq * dt)
	
	return clampf(output * env * LEVEL, -1.0, 1.0)
