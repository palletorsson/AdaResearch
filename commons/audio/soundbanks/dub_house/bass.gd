# Dub House Bass - Deep, round, sub-first
#
# Character: Sub weight with a soft harmonic edge
# Source: Sine + low saw, dub house style
# Processing: Gentle saturation

class_name DubHouseBass
extends RefCounted

const SAMPLE_RATE = 44100.0

const ATTACK_S = 0.006
const DECAY_S = 0.24
const SUSTAIN = 0.45
const RELEASE_S = 0.12

const SUB_MIX = 0.7
const HARMONIC_MIX = 0.25
const LEVEL = 0.5
const DRIVE = 1.25


static func generate(t: float, freq: float, note_duration: float = 0.5, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# ADSR envelope
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		var decay_progress = (dt - ATTACK_S) / DECAY_S
		env = 1.0 - (1.0 - SUSTAIN) * decay_progress
	else:
		env = SUSTAIN
	
	# Release at note end
	if dt > note_duration:
		env *= exp(-(dt - note_duration) / RELEASE_S)
	env = maxf(env, 0.0)
	
	# Oscillators
	var sub = sin(2.0 * PI * freq * t) * SUB_MIX
	var saw = fmod(t * freq, 1.0) * 2.0 - 1.0
	var square = 1.0 if sin(2.0 * PI * freq * t) >= 0.0 else -1.0
	var harmonic = (saw * 0.7 + square * 0.3) * HARMONIC_MIX
	
	var output = sub + harmonic
	output = tanh(output * DRIVE)
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 10.0, 0.0)
