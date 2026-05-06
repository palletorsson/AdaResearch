# Rave Mentasm Stab - Aggressive Chord Hit
# Research: rave.md
#
# Character: Aggressive, detuned chord stab
# Source: "Mentasm" by Second Phase / Joey Beltram
#
# FROM RESEARCH:
# "Mentasm stab: 4 voices, 25 cent detune"
# Aggressive, distorted chord hits

class_name RaveStab
extends RefCounted

const SAMPLE_RATE = 44100.0

const VOICES = 4
const DETUNE_CENTS = 25.0         # Heavy detune for aggression
const ATTACK_S = 0.001            # Instant
const DECAY_S = 0.12              # Short stab
const DISTORTION = 1.5
const LEVEL = 0.3


static func generate(t: float, chord_freqs: Array, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.3:
		return 0.0
	
	# Fast attack, decay to zero
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	else:
		env = exp(-(dt - ATTACK_S) / DECAY_S)
	
	var output = 0.0
	
	for freq in chord_freqs:
		# Play octave up for brightness
		var stab_freq = freq * 2.0
		
		for i in range(VOICES):
			var detune = (float(i) - 1.5) * DETUNE_CENTS / 1200.0
			var voice_freq = stab_freq * pow(2.0, detune)
			var saw = fmod(t * voice_freq, 1.0) * 2.0 - 1.0
			output += saw
	
	output /= chord_freqs.size() * VOICES
	
	# Distortion
	output = tanh(output * DISTORTION)
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.3
