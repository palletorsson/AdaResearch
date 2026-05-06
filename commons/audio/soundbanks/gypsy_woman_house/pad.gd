# Gypsy Woman House Pad - Warm String Pad
#
# Character: Warm, lush, supportive
# Source: Korg M1 / Roland D-50 strings

class_name GypsyPad
extends RefCounted

const SAMPLE_RATE = 44100.0

const VOICES = 4
const DETUNE_CENTS = 8.0
const ATTACK_S = 0.6
const SUSTAIN = 0.65
const LEVEL = 0.12


static func generate(t: float, chord_freqs: Array, note_duration: float = 4.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < note_duration:
		env = SUSTAIN
	else:
		env = SUSTAIN * maxf(0.0, 1.0 - (dt - note_duration) / 1.0)
	
	var output = 0.0
	
	for freq in chord_freqs:
		for i in range(VOICES):
			var detune = (float(i) - 1.5) * DETUNE_CENTS / 1200.0
			var voice_freq = freq * pow(2.0, detune)
			output += sin(2.0 * PI * voice_freq * t)
	
	output /= chord_freqs.size() * VOICES
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 10.0, 0.0)
