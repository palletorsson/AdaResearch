# K-Pop Prog Neo-Moog Lead - bright expressive saw lead

extends RefCounted
class_name KPopProgNeoMoogLead

const LEVEL = 0.24


static func generate(t: float, freq: float, note_duration: float = 0.35, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	var env = 0.0
	if dt < 0.005:
		env = dt / 0.005
	elif dt < 0.09:
		env = 1.0 - (1.0 - 0.56) * ((dt - 0.005) / 0.085)
	elif dt < note_duration:
		env = 0.56
	else:
		env = 0.56 * maxf(0.0, 1.0 - (dt - note_duration) / 0.2)
	
	if env <= 0.0001:
		return 0.0
	
	var vib = sin(TAU * 5.7 * t) * 0.005
	var f = freq * (1.0 + vib)
	var phase = fmod(f * t, 1.0)
	var saw = phase * 2.0 - 1.0
	var tri = 4.0 * absf(phase - 0.5) - 1.0
	var bite = sin(TAU * f * 2.0 * t) * 0.2
	var signal = tanh((saw * 0.62 + tri * 0.38 + bite) * 1.15)
	return clampf(signal * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 0.35, 0.0)


static func get_duration() -> float:
	return 0.6
