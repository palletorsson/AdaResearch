# Aphex Twin Kick - SAW/Syro hybrid
#
# Character: Punchy but warm, slight tape saturation, not overly clean
# Source: TR-808 + tape processing

class_name AphexKick
extends RefCounted

const SAMPLE_RATE = 44100.0

const PUNCH_HZ = 140.0
const BODY_HZ = 50.0
const ATTACK_MS = 3.0
const DECAY_MS = 180.0
const LEVEL = 0.45

# Tape warmth
const SATURATION = 0.15


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.4:
		return 0.0
	
	# Fast pitch sweep for punch
	var pitch_env = exp(-dt / 0.02)
	var freq = BODY_HZ + (PUNCH_HZ - BODY_HZ) * pitch_env
	
	# Amplitude envelope
	var attack_t = ATTACK_MS / 1000.0
	var decay_t = DECAY_MS / 1000.0
	var env = 1.0
	if dt < attack_t:
		env = dt / attack_t
	else:
		env = exp(-(dt - attack_t) / decay_t)
	
	# Sine body with slight harmonic
	var body = sin(TAU * freq * dt)
	var harmonic = sin(TAU * freq * 2.0 * dt) * 0.1
	
	var output = (body + harmonic) * env
	
	# Tape saturation (soft clip)
	output = tanh(output * (1.0 + SATURATION))
	
	return clampf(output * LEVEL, -1.0, 1.0)
