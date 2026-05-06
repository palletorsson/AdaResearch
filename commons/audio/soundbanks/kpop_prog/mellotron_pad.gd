# K-Pop Prog Mellotron Pad - fluttering tape choir/string wash

class_name KPopProgMellotronPad
extends RefCounted

const LEVEL = 0.19


static func generate(t: float, chord_freqs: Array = [], note_duration: float = 4.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	if chord_freqs.is_empty():
		return 0.0
	
	var env = 1.0
	if dt < 0.24:
		env = dt / 0.24
	elif dt > note_duration:
		env = maxf(0.0, 1.0 - (dt - note_duration) / 1.0)
	
	if env <= 0.0001:
		return 0.0
	
	var wow = sin(TAU * 0.19 * t) * 0.007 + sin(TAU * 0.43 * t) * 0.003
	var out = 0.0
	var voices = mini(chord_freqs.size(), 4)
	for i in range(voices):
		var f = chord_freqs[i] * (1.0 + wow)
		var tri = 4.0 * absf(fmod(f * t, 1.0) - 0.5) - 1.0
		var sine = sin(TAU * f * t)
		var tape_noise = (fmod(sin((t + float(i)) * 9817.3) * 17823.1, 1.0) * 2.0 - 1.0) * 0.05
		out += tri * 0.55 + sine * 0.45 + tape_noise
	
	out /= voices * 1.4
	return clampf(out * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 6.0, 0.0)
