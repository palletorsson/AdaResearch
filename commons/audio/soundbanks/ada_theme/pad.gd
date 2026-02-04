# Ada Theme Pad - Warm Supportive Pad for Vocal Backing
#
# Character: Warm, wide, leaves space for vocals (200-4000Hz pocket)
# Source: Inspired by Vangelis/Eno ambient pads

class_name AdaPad
extends RefCounted

const SAMPLE_RATE = 44100.0

const VOICES = 5
const DETUNE_CENTS = 8.0
const ATTACK_S = 0.5
const SUSTAIN = 0.65
const RELEASE_S = 2.0
const LEVEL = 0.12

# EQ: slight cut in vocal range
const VOCAL_CUT_FREQ = 800.0
const VOCAL_CUT_AMOUNT = 0.7  # Multiplier, less = more cut


static func generate(t: float, chord_freqs: Array, note_duration: float = 4.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# Envelope with long release
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
		# Skip frequencies in vocal range (reduce masking)
		var freq_weight = 1.0
		if freq > 200.0 and freq < 1000.0:
			freq_weight = VOCAL_CUT_AMOUNT
		
		for i in range(VOICES):
			var detune = (float(i) - 2.0) * DETUNE_CENTS / 1200.0
			var voice_freq = freq * pow(2.0, detune)
			
			# Mix of saw and sine for warmth
			var saw = fmod(voice_freq * t, 1.0) * 2.0 - 1.0
			var sine = sin(2.0 * PI * voice_freq * t)
			output += (saw * 0.3 + sine * 0.7) * freq_weight
	
	output /= chord_freqs.size() * VOICES
	
	# Subtle slow filter movement
	var filter_mod = sin(t * 0.1) * 0.1 + 0.9
	output *= filter_mod
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 10.0, 0.0)
