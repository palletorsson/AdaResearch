# Moroder Disco Pad - Spacey, floating strings
# Character: Ethereal, long reverb tails, slow movement
# Source: ARP Odyssey / String machine

class_name MoroderPad
extends RefCounted

const SAMPLE_RATE = 44100.0

const VOICES = 5
const DETUNE_CENTS = [0, 5, -5, 8, -8]
const ATTACK_S = 0.4
const SUSTAIN = 0.7
const LEVEL = 0.08


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
		env = SUSTAIN * maxf(0.0, 1.0 - (dt - note_duration) / 1.0)
	
	var output = 0.0
	
	for freq in chord_freqs:
		# Multiple detuned voices per chord note
		for cents in DETUNE_CENTS:
			var ratio = pow(2.0, cents / 1200.0)
			var voice_freq = freq * ratio
			output += sin(TAU * voice_freq * dt)
	
	output /= chord_freqs.size() * DETUNE_CENTS.size()
	
	# Slow filter movement for spacey feel
	var filter_mod = sin(dt * 0.3) * 0.3 + 0.5
	var cutoff = 1500.0 + 1000.0 * filter_mod
	var alpha = cutoff / (cutoff + SAMPLE_RATE / TAU)
	output *= alpha
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 10.0, 0.0)
