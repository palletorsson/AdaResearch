# Boards of Canada Pad - THE SIGNATURE SOUND
# Research: boards_of_canada.md
#
# Character: Warbly, tape-degraded, nostalgic, sun-bleached
# THE defining BoC sound
#
# FROM RESEARCH:
# "Warbly Tape-Degraded Pad: 4 voices, 15 cent detune, 12% drift"
# "Filter 800Hz, LFO 0.15Hz at 8% depth"
# "Saturation 0.2, high shelf -4dB"
# "Very slow LFO (0.15Hz) modulating pitch (8% depth)"

class_name BoCPad
extends RefCounted

const SAMPLE_RATE = 44100.0

# THE signature BoC parameters
const VOICES = 4
const DETUNE_CENTS = 15.0         # Heavy detune
const DRIFT_PERCENT = 0.08        # 8% pitch drift from LFO
const DRIFT_RATE_HZ = 0.15        # 0.15Hz - VERY SLOW (signature!)
const CUTOFF_HZ = 800.0           # Dark, warm
const SATURATION = 1.2            # Tape saturation 0.2
const BITCRUSH_LEVELS = 256.0     # 10-bit simulation
const ATTACK_S = 0.8
const SUSTAIN = 0.6
const RELEASE_S = 2.0
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
	
	# THE SIGNATURE: 0.15Hz tape wow/flutter
	var global_drift = sin(2.0 * PI * DRIFT_RATE_HZ * t) * DRIFT_PERCENT
	
	var output = 0.0
	
	for freq in chord_freqs:
		var drifted_freq = freq * (1.0 + global_drift)
		
		# 4 voices with 15 cent detune
		for i in range(VOICES):
			var detune = (float(i) - 1.5) * DETUNE_CENTS / 1200.0
			var voice_freq = drifted_freq * pow(2.0, detune)
			output += sin(2.0 * PI * voice_freq * t)
	
	output /= chord_freqs.size() * VOICES
	
	# Tape saturation
	output = tanh(output * SATURATION)
	
	# 10-bit quantization
	output = floor(output * BITCRUSH_LEVELS) / BITCRUSH_LEVELS
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 10.0, 0.0)
