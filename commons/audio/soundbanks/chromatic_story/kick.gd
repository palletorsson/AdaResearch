# Chromatic Story Kick - Soft Jazz Kick
#
# Character: Gentle, acoustic-feeling kick - jazz club warmth
# Not punchy or aggressive - supportive and round

class_name ChromaticKick
extends RefCounted

const SAMPLE_RATE = 44100.0

const PITCH_START = 70.0
const PITCH_END = 40.0
const PITCH_DECAY = 0.1
const AMP_ATTACK = 0.005
const AMP_DECAY = 0.3
const LEVEL = 0.4


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.6:
		return 0.0
	
	# Soft attack envelope - no harsh transient
	var env = 0.0
	if dt < AMP_ATTACK:
		env = dt / AMP_ATTACK
	else:
		env = exp(-dt / AMP_DECAY)
	
	# Gentle pitch sweep for body
	var pitch_env = exp(-dt / PITCH_DECAY)
	var freq = PITCH_END + (PITCH_START - PITCH_END) * pitch_env
	
	# Sine body with subtle 2nd harmonic for warmth
	var output = sin(2.0 * PI * freq * dt)
	output += sin(2.0 * PI * freq * 2.0 * dt) * 0.15
	
	return clampf(output * env * LEVEL, -1.0, 1.0)
