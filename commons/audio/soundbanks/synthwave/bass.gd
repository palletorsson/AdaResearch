# Synthwave Bass - Fat Saw Bass
# Research: synthwave.md
#
# Character: Fat, warm, slightly detuned saw bass
# Source: Moog-style / Juno bass
#
# FROM RESEARCH:
# "Saw bass: 2-voice, 5 cent detune, filter 600Hz, resonance 0.4"
# "Attack 0.001s, decay 0.1s, sustain 0.8"

class_name SynthwaveBass
extends RefCounted

const SAMPLE_RATE = 44100.0

# Fat saw bass parameters
const VOICES = 2
const DETUNE_CENTS = 5.0          # Slight detune for thickness
const CUTOFF_HZ = 600.0           # Low-mid filter
const RESONANCE = 0.4
const ATTACK_S = 0.001
const DECAY_S = 0.1
const SUSTAIN = 0.8
const LEVEL = 0.45


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
	
	# Release
	if dt > note_duration - 0.1:
		env *= 1.0 - (dt - (note_duration - 0.1)) / 0.1
	env = maxf(env, 0.0)
	
	# 2-voice detuned saw
	var detune_ratio = pow(2.0, DETUNE_CENTS / 1200.0)
	var saw1 = fmod(t * freq * detune_ratio, 1.0) * 2.0 - 1.0
	var saw2 = fmod(t * freq / detune_ratio, 1.0) * 2.0 - 1.0
	
	# Sub octave for weight
	var sub = sin(2.0 * PI * freq * 0.5 * t)
	
	var output = (saw1 + saw2) * 0.35 + sub * 0.4
	
	# Slight saturation for warmth (Moog character)
	output = tanh(output * 1.2)
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 10.0, 0.0)
