# Chromatic Story Piano - Rhodes Electric Piano
#
# Character: Warm Rhodes EP - the classic jazz keyboard
# Bell-like attack with warm sustain, perfect for jazz voicings

class_name ChromaticPiano
extends RefCounted

const SAMPLE_RATE = 44100.0

const ATTACK_S = 0.003
const DECAY_S = 0.4
const SUSTAIN = 0.35
const RELEASE_S = 0.5
const LEVEL = 0.28


static func generate(t: float, chord_freqs: Array, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 2.0:
		return 0.0
	
	# Rhodes-style envelope with bell attack
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		env = 1.0 - (1.0 - SUSTAIN) * (dt - ATTACK_S) / DECAY_S
	else:
		env = SUSTAIN * exp(-(dt - ATTACK_S - DECAY_S) / RELEASE_S)
	
	var output = 0.0
	
	for freq in chord_freqs:
		# Rhodes tine + bell character
		var tine = sin(2.0 * PI * freq * t)
		var bell = sin(2.0 * PI * freq * 2.0 * t) * exp(-dt * 8.0)  # Bell overtone
		var bark = sin(2.0 * PI * freq * 3.0 * t) * 0.15            # Bark harmonic
		
		# Slight detuning for warmth
		var detune = sin(2.0 * PI * freq * 1.002 * t) * 0.2
		
		output += tine * 0.6 + bell * 0.25 + bark + detune
	
	output /= chord_freqs.size() * 1.5
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 2.0
