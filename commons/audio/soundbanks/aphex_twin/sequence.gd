# Aphex Twin Sequence - Detuned bell-like arpeggio
#
# Character: Shimmering, slightly detuned, nostalgic
# Source: FM synthesis + tape degradation

class_name AphexSequence
extends RefCounted

const SAMPLE_RATE = 44100.0

const DETUNE_CENTS = 8.0
const ATTACK_S = 0.003
const DECAY_S = 0.4
const LEVEL = 0.12


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 1.5:
		return 0.0
	
	# Bell-like envelope
	var env = 0.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	else:
		env = exp(-(dt - ATTACK_S) / DECAY_S)
	
	# Detune ratio
	var detune = pow(2.0, DETUNE_CENTS / 1200.0)
	
	# FM-style bell tone with harmonics
	var carrier = sin(TAU * freq * dt)
	var carrier_det = sin(TAU * freq * detune * dt)
	
	# Inharmonic partials for bell character
	var partial1 = sin(TAU * freq * 2.0 * dt) * 0.4
	var partial2 = sin(TAU * freq * 2.76 * dt) * 0.2  # Slightly inharmonic
	var partial3 = sin(TAU * freq * 5.4 * dt) * 0.1
	
	var output = (carrier + carrier_det) * 0.5 + partial1 + partial2 + partial3
	output /= 2.2  # Normalize
	
	# Subtle bitcrush for lo-fi
	output = round(output * 24.0) / 24.0
	
	return clampf(output * env * LEVEL, -1.0, 1.0)
