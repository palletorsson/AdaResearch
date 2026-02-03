# Madonna 80s Bass - Synth Pop Bass
#
# Character: Punchy, melodic, driving
# Source: Moog / Oberheim / Yamaha DX7 bass
# Processing: Tight, punchy, leaves room for kick

class_name MadonnaBass
extends RefCounted

const SAMPLE_RATE = 44100.0

# Synth pop bass - punchy, not too sub-heavy
const ATTACK_S = 0.005
const DECAY_S = 0.15
const SUSTAIN = 0.7
const DETUNE_CENTS = 3.0          # Slight thickness
const LEVEL = 0.42


static func generate(t: float, freq: float, note_duration: float = 1.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# Envelope
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		env = 1.0 - (1.0 - SUSTAIN) * (dt - ATTACK_S) / DECAY_S
	else:
		env = SUSTAIN
	
	if dt > note_duration - 0.05:
		env *= 1.0 - (dt - (note_duration - 0.05)) / 0.05
	env = maxf(env, 0.0)
	
	# Saw + sub
	var detune = pow(2.0, DETUNE_CENTS / 1200.0)
	var saw1 = fmod(t * freq * detune, 1.0) * 2.0 - 1.0
	var saw2 = fmod(t * freq / detune, 1.0) * 2.0 - 1.0
	var sub = sin(2.0 * PI * freq * 0.5 * t)
	
	var output = (saw1 + saw2) * 0.3 + sub * 0.35
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 10.0, 0.0)
