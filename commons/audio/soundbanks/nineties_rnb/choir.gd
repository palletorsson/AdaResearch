# 90s R&B Choir - airy "ooh/ahh" support layer
# Character: silky synthetic choir pad with slow bloom and soft formant movement
# Reference: JV/M1-style digital choir textures used under choruses and bridges

class_name NinetiesRnBChoir
extends RefCounted

const SAMPLE_RATE = 44100.0
const LEVEL = 0.17

const ATTACK_S = 0.55
const DECAY_S = 0.35
const SUSTAIN = 0.78
const RELEASE_S = 0.9

const DETUNE_CENTS = [-5.0, -2.0, 2.0, 5.0]


static func generate(t: float, chord_freqs: Array = [], note_duration: float = 4.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	if chord_freqs.is_empty():
		return 0.0
	
	var env = 0.0
	if dt < ATTACK_S:
		env = pow(dt / ATTACK_S, 0.8)
	elif dt < ATTACK_S + DECAY_S:
		var d = (dt - ATTACK_S) / DECAY_S
		env = 1.0 - (1.0 - SUSTAIN) * d
	elif dt < note_duration:
		env = SUSTAIN
	else:
		var r = (dt - note_duration) / RELEASE_S
		env = SUSTAIN * maxf(0.0, 1.0 - r)
	
	if env <= 0.0001:
		return 0.0
	
	var vowel_lfo = 0.5 + 0.5 * sin(TAU * 0.11 * t)
	var output = 0.0
	var chord_voices = mini(chord_freqs.size(), 4)
	
	for i in range(chord_voices):
		var base_freq = chord_freqs[i]
		if base_freq <= 0.0:
			continue
		
		for cents in DETUNE_CENTS:
			var ratio = pow(2.0, cents / 1200.0)
			var f = base_freq * ratio
			var phase = fmod(f * t, 1.0)
			
			# Blend sine+triangle+soft saw for a breathy synthetic choir body.
			var sine = sin(TAU * f * t)
			var tri = 4.0 * absf(phase - 0.5) - 1.0
			var saw = phase * 2.0 - 1.0
			
			# Slow "vowel" color drift.
			var bright = lerpf(0.16, 0.29, vowel_lfo)
			var voice = sine * 0.56 + tri * 0.31 + saw * bright
			
			# Light shimmer partial.
			voice += sin(TAU * f * 2.0 * t) * 0.08
			output += voice
	
	output /= chord_voices * DETUNE_CENTS.size() * 1.25
	
	# Slow ensemble movement.
	var ensemble = 1.0 + sin(TAU * 0.37 * t) * 0.035
	var shaped = tanh(output * 1.05)
	return clampf(shaped * env * ensemble * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 6.0, 0.0)


static func get_duration() -> float:
	return 5.0
