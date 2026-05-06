# Aphex Twin Bass - Sub + acid hybrid
#
# Character: Deep sub with occasional acid squelch
# Source: Roland TB-303 + 808 sub
# Research: 40-80Hz focus, moderate resonance for warmth

class_name AphexBass
extends RefCounted

const SAMPLE_RATE = 44100.0

const ATTACK_S = 0.01
const DECAY_S = 0.3
const SUSTAIN = 0.7
const RELEASE_S = 0.3
const LEVEL = 0.28

# Subtle filter movement
const FILTER_BASE_HZ = 300.0
const FILTER_MOD_HZ = 200.0
const FILTER_RATE = 0.5


static func generate(t: float, freq: float, note_duration: float = 1.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# Envelope
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		env = 1.0 - (1.0 - SUSTAIN) * ((dt - ATTACK_S) / DECAY_S)
	elif dt < note_duration:
		env = SUSTAIN
	else:
		env = SUSTAIN * maxf(0.0, 1.0 - (dt - note_duration) / RELEASE_S)
	
	if env < 0.001:
		return 0.0
	
	# Sub sine (fundamental)
	var sub = sin(TAU * freq * dt)
	
	# Saw for grit
	var phase = fmod(freq * dt, 1.0)
	var saw = phase * 2.0 - 1.0
	
	# Subtle square for body
	var square = sign(sin(TAU * freq * dt))
	
	# Mix
	var output = sub * 0.6 + saw * 0.25 + square * 0.15
	
	# Simple filter modulation
	var filter_env = exp(-dt / 0.2)
	var cutoff = FILTER_BASE_HZ + FILTER_MOD_HZ * filter_env
	var filter_amount = clampf(cutoff / (freq * 4.0), 0.0, 1.0)
	output *= filter_amount
	
	# Soft saturation
	output = tanh(output * 1.3)
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 2.0, 0.0)
