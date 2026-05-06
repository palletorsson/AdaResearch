# Gypsy Woman House Piano - THE SIGNATURE SOUND
#
# Character: Bright, punchy piano stabs - THE defining house sound
# Source: Korg M1 "House Piano" preset (legendary)
# This is what makes it "Gypsy Woman" style!

class_name GypsyPiano
extends RefCounted

const SAMPLE_RATE = 44100.0

# M1 House Piano character
const ATTACK_S = 0.002            # Instant attack (stab!)
const DECAY_S = 0.2               # Quick decay
const SUSTAIN = 0.2               # Low sustain (staccato feel)
const BRIGHT_MULT = 2.0           # Play bright
const LEVEL = 0.3


static func generate(t: float, chord_freqs: Array, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.5:
		return 0.0
	
	# Piano stab envelope - instant attack, quick decay
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		env = 1.0 - (1.0 - SUSTAIN) * (dt - ATTACK_S) / DECAY_S
	else:
		env = SUSTAIN * exp(-(dt - ATTACK_S - DECAY_S) * 4.0)
	
	var output = 0.0
	
	for freq in chord_freqs:
		# Play in bright octave
		var piano_freq = freq * BRIGHT_MULT
		
		# Piano-like harmonics
		output += sin(2.0 * PI * piano_freq * t) * 1.0
		output += sin(2.0 * PI * piano_freq * 2.0 * t) * 0.5    # 2nd harmonic
		output += sin(2.0 * PI * piano_freq * 3.0 * t) * 0.25   # 3rd harmonic
		output += sin(2.0 * PI * piano_freq * 4.0 * t) * 0.12   # 4th harmonic
		
		# Slight detuning for width
		output += sin(2.0 * PI * piano_freq * 1.003 * t) * 0.3
	
	output /= chord_freqs.size() * 2.5
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.5
