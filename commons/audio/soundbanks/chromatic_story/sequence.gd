# Chromatic Story Sequence - Gentle Jazz Arpeggio
#
# Character: Soft, bell-like arpeggiated sequence
# Chromatic exploration with warmth

class_name ChromaticSequence
extends RefCounted

const SAMPLE_RATE = 44100.0

const ATTACK_S = 0.01
const DECAY_S = 0.3
const SUSTAIN = 0.2
const LEVEL = 0.18


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 1.0:
		return 0.0
	
	# Bell-like envelope
	var env = 0.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		env = 1.0 - (1.0 - SUSTAIN) * (dt - ATTACK_S) / DECAY_S
	else:
		env = SUSTAIN * exp(-(dt - ATTACK_S - DECAY_S) * 3.0)
	
	# Bell-like tone with upper partials
	var output = sin(2.0 * PI * freq * t) * 0.7
	output += sin(2.0 * PI * freq * 2.0 * t) * 0.2  # Octave
	output += sin(2.0 * PI * freq * 3.0 * t) * 0.1  # Fifth above
	
	# Slight shimmer
	output += sin(2.0 * PI * freq * 1.01 * t) * 0.15
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 0.0)
