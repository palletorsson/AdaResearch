# Chromatic Story Pad - Warm Jazz Pad
#
# Character: Soft, warm pad for harmonic support
# Ethereal but not cold - supports the jazz harmony

class_name ChromaticPad
extends RefCounted

const SAMPLE_RATE = 44100.0

const VOICES = 4
const DETUNE_CENTS = 6.0
const ATTACK_S = 0.6
const SUSTAIN = 0.55
const RELEASE_S = 1.5
const LEVEL = 0.14


static func generate(t: float, chord_freqs: Array, note_duration: float = 4.0, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0:
		return 0.0
	
	# Gentle envelope
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < note_duration:
		env = SUSTAIN
	else:
		env = SUSTAIN * maxf(0.0, 1.0 - (dt - note_duration) / RELEASE_S)
	
	if env < 0.001:
		return 0.0
	
	var output = 0.0
	
	for freq in chord_freqs:
		for i in range(VOICES):
			var detune = (float(i) - 1.5) * DETUNE_CENTS / 1200.0
			var voice_freq = freq * pow(2.0, detune)
			
			# Warm sine-based pad
			var sine = sin(2.0 * PI * voice_freq * t)
			var sine_oct = sin(2.0 * PI * voice_freq * 0.5 * t) * 0.3  # Sub octave
			output += sine * 0.8 + sine_oct
	
	output /= chord_freqs.size() * VOICES * 0.8
	
	# Subtle movement
	var lfo = sin(t * 0.08) * 0.1 + 0.9
	output *= lfo
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 8.0, 0.0)
