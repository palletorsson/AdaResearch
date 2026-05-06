# Kraftwerk Pad - Vocoder Style
# Research: kraftwerk.md
#
# Character: Clean, synthetic, vocoder-like
#
# FROM RESEARCH:
# "Vocoder Pad: 6 voices, 16 bands, filter 3000Hz"
# "Attack 0.05s, sustain 0.8, subtle chorus for width"

class_name KraftwerkPad
extends RefCounted

const SAMPLE_RATE = 44100.0

const ATTACK_S = 0.05
const SUSTAIN = 0.8
const RELEASE_S = 0.5
const LEVEL = 0.15


static func generate(t: float, chord_freqs: Array, note_duration: float = 4.0, note_time: float = 0.0) -> float:
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
	
	var output = 0.0
	
	for freq in chord_freqs:
		# Harmonic content for vocoder-like sound
		output += sin(2.0 * PI * freq * t) * 0.5
		output += sin(2.0 * PI * freq * 2.0 * t) * 0.3
		output += sin(2.0 * PI * freq * 3.0 * t) * 0.2
		output += sin(2.0 * PI * freq * 4.0 * t) * 0.1
	
	output /= chord_freqs.size()
	
	# Subtle width - very slight chorus
	output += sin(2.0 * PI * chord_freqs[0] * 1.002 * t) * 0.1
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 10.0, 0.0)
