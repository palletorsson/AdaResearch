# K-Pop Prog Supersaw Pad - chorus lift layer

class_name KPopProgSupersawPad
extends RefCounted

const LEVEL = 0.22
const DETUNE = [-0.42, -0.21, 0.0, 0.21, 0.42]


static func generate(t: float, chord_freqs: Array = [], note_duration: float = 4.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	if chord_freqs.is_empty():
		return 0.0
	
	var env = 1.0
	if dt < 0.22:
		env = pow(dt / 0.22, 0.8)
	elif dt > note_duration:
		env = maxf(0.0, 1.0 - (dt - note_duration) / 0.8)
	
	if env <= 0.0001:
		return 0.0
	
	var out = 0.0
	var voices = mini(chord_freqs.size(), 4)
	for i in range(voices):
		var f0 = chord_freqs[i]
		for d in DETUNE:
			var freq = f0 * pow(2.0, (d * 24.0) / 1200.0)
			out += fmod(freq * t, 1.0) * 2.0 - 1.0
	
	out /= voices * DETUNE.size() * 1.2
	var chorus = 1.0 + sin(TAU * 0.31 * t) * 0.03
	return clampf(out * env * chorus * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 6.0, 0.0)
