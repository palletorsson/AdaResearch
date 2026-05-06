# Madonna 80s Pad - Lush Synth Pad
#
# Character: Warm, wide, chorused, uplifting
# Source: Oberheim / Roland Juno

class_name MadonnaPad
extends RefCounted

const SAMPLE_RATE = 44100.0

const VOICES = 5
const DETUNE_CENTS = 10.0
const CHORUS_RATE = 0.4
const CHORUS_DEPTH = 0.003
const ATTACK_S = 0.4
const SUSTAIN = 0.7
const LEVEL = 0.15


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
		env = SUSTAIN * maxf(0.0, 1.0 - (dt - note_duration) / 0.8)
	
	var chorus = sin(2.0 * PI * CHORUS_RATE * t) * CHORUS_DEPTH
	
	var output = 0.0
	
	for freq in chord_freqs:
		for i in range(VOICES):
			var detune = (float(i) - 2.0) * DETUNE_CENTS / 1200.0
			var voice_freq = freq * pow(2.0, detune) * (1.0 + chorus)
			output += sin(2.0 * PI * voice_freq * t)
	
	output /= chord_freqs.size() * VOICES
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 10.0, 0.0)
