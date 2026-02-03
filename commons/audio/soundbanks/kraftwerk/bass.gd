# Kraftwerk Bass - Minimoog Style
# Research: kraftwerk.md
#
# Character: Warm but precise, minimal drift
# Source: Minimoog Model D with ladder filter
#
# FROM RESEARCH:
# "Minimoog: dual detuned saws, 600Hz ladder filter"
# "Resonance 0.35, 2 cent drift for warmth"
# Only 2 CENTS - minimal!

class_name KraftwerkBass
extends RefCounted

const SAMPLE_RATE = 44100.0

# Minimoog bass - only 2 cent drift
const DRIFT_CENTS = 2.0           # MINIMAL - only for slight warmth
const CUTOFF_HZ = 600.0
const RESONANCE = 0.35
const ATTACK_S = 0.001
const DECAY_S = 0.2
const SUSTAIN = 0.8
const LEVEL = 0.38


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
	if dt > note_duration - 0.08:
		env *= 1.0 - (dt - (note_duration - 0.08)) / 0.08
	env = maxf(env, 0.0)
	
	# Dual detuned saws - only 2 cents!
	var drift_ratio = pow(2.0, DRIFT_CENTS / 1200.0)
	var saw1 = fmod(t * freq, 1.0) * 2.0 - 1.0
	var saw2 = fmod(t * freq * drift_ratio, 1.0) * 2.0 - 1.0
	
	var bass = (saw1 + saw2) * 0.5
	
	# Slight warmth only - NOT distorted
	bass = tanh(bass * 0.9)
	
	return clampf(bass * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 10.0, 0.0)
