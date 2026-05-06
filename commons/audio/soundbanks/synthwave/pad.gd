# Synthwave Pad - Warm Analog Pad
# Research: synthwave.md
#
# Character: Warm, wide, evolving analog pad with chorus
# Source: Oberheim OB-8 / Prophet style

class_name SynthwavePad
extends RefCounted

const SAMPLE_RATE = 44100.0

const VOICES = 6
const DETUNE_CENTS = 8.0
const CHORUS_RATE = 0.3
const CHORUS_DEPTH = 0.003
const ATTACK_S = 0.8
const SUSTAIN = 0.7
const RELEASE_S = 1.5
const LEVEL = 0.18


static func generate(t: float, chord_freqs: Array, note_duration: float = 4.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# Slow envelope
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < note_duration:
		env = SUSTAIN
	else:
		env = SUSTAIN * maxf(0.0, 1.0 - (dt - note_duration) / RELEASE_S)
	
	var chorus = sin(2.0 * PI * CHORUS_RATE * t) * CHORUS_DEPTH
	
	var output = 0.0
	
	for freq in chord_freqs:
		for i in range(VOICES):
			var detune = (float(i) - 2.5) * DETUNE_CENTS / 1200.0
			var voice_freq = freq * pow(2.0, detune) * (1.0 + chorus)
			var saw = fmod(t * voice_freq, 1.0) * 2.0 - 1.0
			output += saw
	
	output /= chord_freqs.size() * VOICES
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 10.0, 0.0)
