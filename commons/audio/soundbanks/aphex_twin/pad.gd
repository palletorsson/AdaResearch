# Aphex Twin Pad - SAW-style warm detuned pad
#
# Character: Warm, wobbly, nostalgic, tape-degraded
# Source: Roland Juno + tape processing
# Research: +/- 8-15 cents detune, slow pitch drift

class_name AphexPad
extends RefCounted

const SAMPLE_RATE = 44100.0

const VOICES = 5
const DETUNE_CENTS = 12.0
const WOW_RATE_HZ = 0.08  # Slow tape drift
const WOW_DEPTH_CENTS = 6.0
const ATTACK_S = 0.6
const SUSTAIN = 0.7
const RELEASE_S = 2.5
const LEVEL = 0.14


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
	
	if env < 0.001:
		return 0.0
	
	# Tape wow (slow pitch drift)
	var wow = sin(TAU * WOW_RATE_HZ * t) * WOW_DEPTH_CENTS / 1200.0
	
	var output = 0.0
	
	for freq in chord_freqs:
		for i in range(VOICES):
			# Spread detune across voices
			var voice_detune = (float(i) - 2.0) * DETUNE_CENTS / 1200.0
			var total_detune = voice_detune + wow
			var voice_freq = freq * pow(2.0, total_detune)
			
			# Mix of saw and sine for warmth
			var phase = fmod(voice_freq * t, 1.0)
			var saw = phase * 2.0 - 1.0
			var sine = sin(TAU * voice_freq * t)
			
			output += saw * 0.4 + sine * 0.6
	
	output /= chord_freqs.size() * VOICES
	
	# Soft saturation for tape warmth
	output = tanh(output * 1.2)
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 10.0, 0.0)
