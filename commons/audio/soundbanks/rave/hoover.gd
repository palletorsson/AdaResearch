# Rave Hoover Bass - THE SIGNATURE SOUND
# Research: rave.md
#
# Character: MASSIVE detuned saw bass, the defining rave sound
# Source: Roland Alpha Juno "What The" patch
#
# FROM RESEARCH:
# "HOOVER: 3-voice, EXTREME DETUNE 40 cents (!)"
# "PWM, filter 800Hz, resonance 0.5, LFO 3Hz, distortion 0.3"
# This is 40 CENTS - not 4, not 15 - FORTY!

class_name RaveHoover
extends RefCounted

const SAMPLE_RATE = 44100.0

# THE HOOVER - 40 cent detune is CRITICAL
const VOICES = 3
const DETUNE_CENTS = 40.0         # EXTREME - this makes it a hoover!
const FILTER_LFO_RATE = 3.0       # Filter wobble
const FILTER_LFO_DEPTH = 0.3      # Depth of wobble
const DISTORTION = 1.3            # 0.3 in research
const ATTACK_S = 0.01
const SUSTAIN = 0.8
const LEVEL = 0.4


static func generate(t: float, freq: float, note_duration: float = 1.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# Envelope
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	else:
		env = SUSTAIN
	if dt > note_duration - 0.1:
		env *= 1.0 - (dt - (note_duration - 0.1)) / 0.1
	env = maxf(env, 0.0)
	
	# Filter LFO wobble
	var filter_mod = sin(2.0 * PI * FILTER_LFO_RATE * t) * FILTER_LFO_DEPTH
	
	var hoover = 0.0
	
	# 3-voice with EXTREME 40 cent detune
	for i in range(VOICES):
		var detune = (float(i) - 1.0) * DETUNE_CENTS / 1200.0
		var voice_freq = freq * pow(2.0, detune)
		var saw = fmod(t * voice_freq, 1.0) * 2.0 - 1.0
		hoover += saw
	
	hoover /= VOICES
	
	# Apply filter LFO
	hoover *= (0.7 + filter_mod * 0.3)
	
	# Heavy distortion
	hoover = tanh(hoover * DISTORTION)
	
	return clampf(hoover * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 10.0, 0.0)
