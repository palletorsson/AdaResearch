# Gypsy Woman House Bass - Bouncy Offbeat Bass
#
# Character: THE signature house bass - bouncy, pumping, offbeat
# Source: Roland SH-101 / Juno style
# Pattern: Offbeat hits that make you move!

class_name GypsyBass
extends RefCounted

const SAMPLE_RATE = 44100.0

# Bouncy house bass
const ATTACK_S = 0.008
const DECAY_S = 0.12
const SUSTAIN = 0.6
const FILTER_CUTOFF = 800.0
const LEVEL = 0.48


static func generate(t: float, freq: float, note_duration: float = 0.25, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# Bouncy envelope - quick attack, moderate decay
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		env = 1.0 - (1.0 - SUSTAIN) * (dt - ATTACK_S) / DECAY_S
	else:
		env = SUSTAIN * exp(-(dt - ATTACK_S - DECAY_S) * 6.0)
	
	# Cut off at note duration
	if dt > note_duration:
		env *= exp(-(dt - note_duration) * 20.0)
	
	# Saw bass (house character)
	var saw = fmod(t * freq, 1.0) * 2.0 - 1.0
	var sub = sin(2.0 * PI * freq * t)
	
	var output = saw * 0.4 + sub * 0.5
	
	# Slight saturation for warmth
	output = tanh(output * 1.3)
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 0.25, 0.0)
