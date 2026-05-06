# K-Pop Prog 808 Sub - rounded sine with light harmonics

class_name KPopProgSub808
extends RefCounted

const LEVEL = 0.62


static func generate(t: float, freq: float, note_duration: float = 0.8, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0 or dt > note_duration:
		return 0.0
	
	var sub_freq = freq * 0.5 if freq > 90.0 else freq
	var env = 1.0
	if dt < 0.01:
		env = dt / 0.01
	elif dt > note_duration - 0.14:
		env = maxf(0.0, 1.0 - (dt - (note_duration - 0.14)) / 0.14)
	
	var body = sin(TAU * sub_freq * t)
	var harmonic = sin(TAU * sub_freq * 2.0 * t) * 0.18
	var transient = sin(TAU * sub_freq * 5.0 * t) * exp(-dt * 28.0) * 0.12
	return clampf(tanh((body + harmonic + transient) * 1.25) * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 1.0, 0.0)


static func get_duration() -> float:
	return 1.0
