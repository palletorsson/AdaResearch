# Ada Theme Bass - Deep Supportive Sine Bass
#
# Character: Warm sine sub, stays out of vocal range
# Simple, sustained, foundational

class_name AdaBass
extends RefCounted

const SAMPLE_RATE = 44100.0

const ATTACK_S = 0.1
const SUSTAIN = 0.8
const RELEASE_S = 0.5
const LEVEL = 0.2


static func generate(t: float, freq: float, note_duration: float = 1.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# Envelope
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < note_duration:
		env = SUSTAIN
	else:
		env = SUSTAIN * maxf(0.0, 1.0 - (dt - note_duration) / RELEASE_S)
	
	if env < 0.001:
		return 0.0
	
	# Pure sine for clean sub
	var sine = sin(2.0 * PI * freq * dt)
	
	# Add subtle second harmonic for presence
	var harmonic = sin(2.0 * PI * freq * 2.0 * dt) * 0.15
	
	var output = sine + harmonic
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 2.0, 0.0)
