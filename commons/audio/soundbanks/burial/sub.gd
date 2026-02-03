# Burial Sub Bass - UK Garage Mono Sub
# Research: burial.md
#
# Character: Deep, warm, heavy, MONO, distorted yet earthy
# Source: UK Garage tradition
#
# FROM RESEARCH:
# "UK garage sub: cutoff 120Hz, MONO, +6dB sub level"
# "Attack 0.01s, decay 0.4s, sustain 0.5"
# "Basslines sound like nothing else on Earth. Distorted and heavy, yet also warm and earthy"
# "They resemble the balmy gust of air that precedes an underground train"

class_name BurialSub
extends RefCounted

const SAMPLE_RATE = 44100.0

# UK Garage sub parameters
const CUTOFF_HZ = 120.0           # Very low - mostly sub
const ATTACK_S = 0.01             # Gentle attack
const DECAY_S = 0.4               # Medium decay
const SUSTAIN = 0.5               # Medium sustain
const SUB_BOOST = 2.0             # +6dB
const DISTORTION = 1.4            # "Distorted and heavy, yet warm and earthy"
const LEVEL = 0.55


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
	
	if dt > note_duration - 0.15:
		env *= 1.0 - (dt - (note_duration - 0.15)) / 0.15
	env = maxf(env, 0.0)
	
	# Pure sub sine
	var sub = sin(2.0 * PI * freq * t) * SUB_BOOST
	
	# Add slight harmonic
	sub += sin(2.0 * PI * freq * 2.0 * t) * 0.2
	
	# "Distorted and heavy, yet warm and earthy"
	sub = tanh(sub * DISTORTION)
	
	# MONO - centered (this is enforced by being single channel)
	return clampf(sub * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 10.0, 0.0)
