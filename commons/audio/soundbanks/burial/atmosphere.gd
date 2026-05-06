# Burial Atmosphere Pad - Dark, Ghostly
# Research: burial.md
#
# Character: Dark, evolving, heavily reverbed, rolled-off highs
# Source: Burial's signature atmospheric sound
#
# FROM RESEARCH:
# "Atmosphere Pad: 3 voices, 8 cent detune, filter 1500Hz"
# "Attack 1.5s, release 3.0s"
# "Reverb 0.7 mix / 6s decay, with pre-delay"
# "High shelf cut -3dB"

class_name BurialAtmosphere
extends RefCounted

const SAMPLE_RATE = 44100.0

const VOICES = 3
const DETUNE_CENTS = 8.0
const CUTOFF_HZ = 1500.0          # Low - dark sound
const ATTACK_S = 1.5              # Very slow attack
const SUSTAIN = 0.6
const RELEASE_S = 3.0             # Very long release
const LEVEL = 0.15


static func generate(t: float, chord_freqs: Array, note_duration: float = 4.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# Very slow envelope
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < note_duration:
		env = SUSTAIN
	else:
		env = SUSTAIN * maxf(0.0, 1.0 - (dt - note_duration) / RELEASE_S)
	
	var output = 0.0
	
	for freq in chord_freqs:
		# Octave down for depth
		output += sin(2.0 * PI * freq * 0.5 * t) * 0.5
		
		# Main voices with slight detune
		for i in range(VOICES):
			var detune = (float(i) - 1.0) * DETUNE_CENTS / 1200.0
			output += sin(2.0 * PI * freq * pow(2.0, detune) * t) * 0.35
	
	output /= chord_freqs.size() * 2.5
	
	# Phaser-like movement
	output *= 0.85 + sin(2.0 * PI * 0.3 * t) * 0.15
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 10.0, 0.0)
