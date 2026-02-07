# Chromatic Story Bass - Upright Jazz Bass
#
# Character: Warm, round upright bass - the jazz foundation
# Walking bass style with natural decay

class_name ChromaticBass
extends RefCounted

const SAMPLE_RATE = 44100.0

const ATTACK_S = 0.01
const DECAY_S = 0.8
const SUSTAIN = 0.4
const LEVEL = 0.35


static func generate(t: float, freq: float, note_duration: float = 0.5, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > note_duration + 0.2:
		return 0.0
	
	# Plucked bass envelope
	var env = 0.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < note_duration:
		env = 1.0 - (1.0 - SUSTAIN) * (dt - ATTACK_S) / DECAY_S
		env = maxf(env, SUSTAIN)
	else:
		env = SUSTAIN * exp(-(dt - note_duration) * 8.0)
	
	# Upright bass harmonics
	var output = sin(2.0 * PI * freq * t) * 1.0       # Fundamental
	output += sin(2.0 * PI * freq * 2.0 * t) * 0.35   # 2nd harmonic
	output += sin(2.0 * PI * freq * 3.0 * t) * 0.15   # 3rd harmonic
	
	# String buzz character (subtle)
	output += (randf() * 2.0 - 1.0) * 0.02 * exp(-dt * 10.0)
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 0.5, 0.0)
