# Kraftwerk Sequencer Line - ZERO MODULATION
# Research: kraftwerk.md
#
# Character: Perfectly precise, no wobble, machine-like
# THE defining Kraftwerk sound
#
# FROM RESEARCH:
# "Sequencer Lines: Square wave, filter 2000Hz"
# "Very short envelope (attack 0.001s, decay 0.08s)"
# "ZERO modulation - Kraftwerk sequences are precise, not wobbly"
# "Stable pitch (no drift) - mechanical perfection"

class_name KraftwerkSequence
extends RefCounted

const SAMPLE_RATE = 44100.0

# ZERO modulation - machine precision
const ATTACK_S = 0.001
const DECAY_S = 0.08
const LEVEL = 0.18


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.2:
		return 0.0
	
	# Fast envelope
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	else:
		env = exp(-(dt - ATTACK_S) / DECAY_S)
	
	# Square wave - NO modulation, NO drift
	var square = sign(sin(2.0 * PI * freq * t))
	
	# Perfectly clean
	return clampf(square * env * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.2
