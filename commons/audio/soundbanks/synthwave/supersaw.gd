# Synthwave Supersaw - JP-8000 Style Lead
# Research: synthwave.md
#
# Character: MASSIVE wall of detuned saws, the signature synthwave anthem sound
# Source: Roland JP-8000 supersaw oscillator
#
# FROM RESEARCH:
# "Supersaw Lead: 7 voices, 15 cent detune, filter 4500Hz"
# "Vibrato 5.5Hz at 0.02 depth, stereo 1.4x"
# "Delay: 0.35s, 35% mix"
# "Reverb: 40% mix"

class_name SynthwaveSupersaw
extends RefCounted

const SAMPLE_RATE = 44100.0

# JP-8000 supersaw parameters
const VOICES = 7                  # Classic supersaw voice count
const DETUNE_CENTS = 15.0         # Heavy detune for width
const CUTOFF_HZ = 4500.0          # Bright filter
const VIBRATO_RATE_HZ = 5.5       # Vibrato speed
const VIBRATO_DEPTH = 0.02        # Vibrato amount
const ATTACK_S = 0.02             # Fast attack
const SUSTAIN = 0.9               # Near-full sustain
const RELEASE_S = 0.5             # Medium release
const LEVEL = 0.25

# Voice detune spread (7 voices)
const DETUNE_SPREAD = [-0.5, -0.33, -0.17, 0.0, 0.17, 0.33, 0.5]


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
	
	# Vibrato
	var vibrato = sin(2.0 * PI * VIBRATO_RATE_HZ * t) * VIBRATO_DEPTH
	
	var output = 0.0
	
	for freq in chord_freqs:
		var vibrated_freq = freq * (1.0 + vibrato)
		
		# 7-voice supersaw
		for i in range(VOICES):
			var detune = DETUNE_SPREAD[i] * DETUNE_CENTS / 1200.0
			var voice_freq = vibrated_freq * pow(2.0, detune)
			var saw = fmod(t * voice_freq, 1.0) * 2.0 - 1.0
			output += saw
	
	output /= chord_freqs.size() * VOICES
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 10.0, 0.0)
