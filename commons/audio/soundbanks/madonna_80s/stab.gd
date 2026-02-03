# Madonna 80s Stab - Bright Oberheim Chord
#
# Character: Bright, punchy, iconic 80s stab
# Source: Oberheim OB-X / OB-8
# Processing: Bright, slightly chorused

class_name MadonnaStab
extends RefCounted

const SAMPLE_RATE = 44100.0

# Oberheim-style bright stab
const VOICES = 4
const DETUNE_CENTS = 8.0
const ATTACK_S = 0.002
const DECAY_S = 0.15
const SUSTAIN = 0.3
const LEVEL = 0.28


static func generate(t: float, chord_freqs: Array, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.4:
		return 0.0
	
	# Punchy envelope
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		env = 1.0 - (1.0 - SUSTAIN) * (dt - ATTACK_S) / DECAY_S
	else:
		env = SUSTAIN * exp(-(dt - ATTACK_S - DECAY_S) * 5.0)
	
	var output = 0.0
	
	for freq in chord_freqs:
		# Bright - play in higher octave
		var stab_freq = freq * 2.0
		
		for i in range(VOICES):
			var detune = (float(i) - 1.5) * DETUNE_CENTS / 1200.0
			var voice_freq = stab_freq * pow(2.0, detune)
			# Saw for brightness
			output += fmod(t * voice_freq, 1.0) * 2.0 - 1.0
	
	output /= chord_freqs.size() * VOICES
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.4
