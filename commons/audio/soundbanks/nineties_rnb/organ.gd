# 90s R&B Organ - M1/JV style comping stab
# Character: warm digital organ with soft key click and short soulful sustain
# Reference: New Jack Swing and late 90s R&B chord comp layers

class_name NinetiesRnBOrgan
extends RefCounted

const SAMPLE_RATE = 44100.0
const LEVEL = 0.2

const ATTACK_S = 0.003
const DECAY_S = 0.06
const SUSTAIN = 0.58
const RELEASE_S = 0.2
const DEFAULT_NOTE_DURATION = 0.26


static func generate(t: float, chord_freqs: Array = [], trigger_time: float = 0.0, note_duration: float = DEFAULT_NOTE_DURATION) -> float:
	var dt = t - trigger_time
	if dt < 0.0:
		return 0.0
	
	var release_len = maxf(0.08, RELEASE_S)
	if dt > note_duration + release_len:
		return 0.0
	
	if chord_freqs.is_empty():
		return 0.0
	
	var env = 0.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		var d = (dt - ATTACK_S) / DECAY_S
		env = 1.0 - (1.0 - SUSTAIN) * d
	elif dt < note_duration:
		env = SUSTAIN
	else:
		var r = (dt - note_duration) / release_len
		env = SUSTAIN * maxf(0.0, 1.0 - r)
	
	if env <= 0.0001:
		return 0.0
	
	var output = 0.0
	var voice_count = mini(chord_freqs.size(), 4)
	
	for i in range(voice_count):
		var freq = chord_freqs[i]
		if freq <= 0.0:
			continue
		
		# Drawbar-ish additive blend.
		var fundamental = sin(TAU * freq * t) * 1.0
		var h2 = sin(TAU * freq * 2.0 * t) * 0.52
		var h3 = sin(TAU * freq * 3.0 * t) * 0.34
		var h4 = sin(TAU * freq * 4.0 * t) * 0.2
		
		# Light key-click transient for attack definition.
		var click = 0.0
		if dt < 0.012:
			var click_env = 1.0 - dt / 0.012
			click = sin(TAU * freq * 8.0 * dt) * click_env * 0.1
		
		output += fundamental + h2 + h3 + h4 + click
	
	output /= voice_count * 2.15
	
	# Gentle static saturation to keep warmth without harshness.
	var shaped = tanh(output * 1.1)
	return clampf(shaped * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 0.0)


static func get_duration() -> float:
	return 0.55
