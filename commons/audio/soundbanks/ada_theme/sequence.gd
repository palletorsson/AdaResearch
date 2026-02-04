# Ada Theme Sequence - Gentle Twinkling Arpeggio
#
# Character: Soft bell-like tones, delay trails
# Sparkles in the background without competing with vocals

class_name AdaSequence
extends RefCounted

const SAMPLE_RATE = 44100.0

const ATTACK_S = 0.005
const DECAY_S = 0.3
const LEVEL = 0.08


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 1.0:
		return 0.0
	
	# Bell-like envelope: quick attack, medium decay
	var env = 0.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	else:
		env = exp(-(dt - ATTACK_S) / DECAY_S)
	
	# Bell tone: fundamental + inharmonic partials
	var fundamental = sin(2.0 * PI * freq * dt)
	var partial1 = sin(2.0 * PI * freq * 2.0 * dt) * 0.5
	var partial2 = sin(2.0 * PI * freq * 2.4 * dt) * 0.25  # Slightly inharmonic for bell character
	var partial3 = sin(2.0 * PI * freq * 5.2 * dt) * 0.1
	
	var output = fundamental + partial1 + partial2 + partial3
	output /= 1.85  # Normalize
	
	return clampf(output * env * LEVEL, -1.0, 1.0)
