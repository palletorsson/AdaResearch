# K-Pop Prog Kraftwerk Seq - crisp pulse/saw sequencer line

class_name KPopProgKraftwerkSeq
extends RefCounted

const LEVEL = 0.2


static func generate(t: float, freq: float, note_duration: float = 0.16, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0 or dt > note_duration + 0.08:
		return 0.0
	
	var env = 1.0
	if dt < 0.003:
		env = dt / 0.003
	elif dt > note_duration:
		env = maxf(0.0, 1.0 - (dt - note_duration) / 0.08)
	
	var pulse = 1.0 if fmod(freq * t, 1.0) < 0.47 else -1.0
	var saw = fmod(freq * t, 1.0) * 2.0 - 1.0
	var signal = tanh((pulse * 0.62 + saw * 0.38) * 1.05)
	return clampf(signal * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 0.16, 0.0)


static func get_duration() -> float:
	return 0.24
