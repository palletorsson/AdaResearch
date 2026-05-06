# Gypsy Woman House Organ - Gospel/House Organ
#
# Character: Warm, soulful, gospel-influenced
# Source: Hammond B3 style

class_name GypsyOrgan
extends RefCounted

const SAMPLE_RATE = 44100.0

# Hammond-style organ
const ATTACK_S = 0.01
const DECAY_S = 0.1
const SUSTAIN = 0.8
const LEVEL = 0.15


static func generate(t: float, chord_freqs: Array, note_duration: float = 2.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < note_duration:
		env = SUSTAIN
	else:
		env = SUSTAIN * maxf(0.0, 1.0 - (dt - note_duration) / 0.3)
	
	var output = 0.0
	
	for freq in chord_freqs:
		# Hammond drawbar simulation
		output += sin(2.0 * PI * freq * 0.5 * t) * 0.3   # 16'
		output += sin(2.0 * PI * freq * t) * 1.0          # 8'
		output += sin(2.0 * PI * freq * 2.0 * t) * 0.6    # 4'
		output += sin(2.0 * PI * freq * 3.0 * t) * 0.3    # 2 2/3'
		output += sin(2.0 * PI * freq * 4.0 * t) * 0.2    # 2'
	
	output /= chord_freqs.size() * 2.5
	
	# Slight overdrive (Leslie character)
	output = tanh(output * 1.2)
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 10.0, 0.0)
