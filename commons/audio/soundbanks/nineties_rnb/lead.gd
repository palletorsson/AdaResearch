# 90s R&B Lead - silky hook line synth
# Character: expressive mono lead, soft attack, slight vibrato and glide
# Reference: late 90s New Jack / slow jam top lines

class_name NinetiesRnBLead
extends RefCounted

const SAMPLE_RATE = 44100.0
const LEVEL = 0.19

const ATTACK_S = 0.004
const DECAY_S = 0.12
const SUSTAIN = 0.42
const RELEASE_S = 0.22


static func generate(t: float, freq: float, note_duration: float = 0.35, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
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
		var r = (dt - note_duration) / RELEASE_S
		env = SUSTAIN * maxf(0.0, 1.0 - r)
	
	if env <= 0.001:
		return 0.0
	
	# Small pitch bloom for a vocal-like attack.
	var pitch_env = 1.0
	if dt < 0.02:
		pitch_env = 0.985 + 0.015 * (dt / 0.02)
	
	var vib = sin(TAU * 5.4 * t) * 0.004
	var f = freq * pitch_env * (1.0 + vib)
	
	# Soft saw + triangle blend with harmonic damping.
	var phase = fmod(f * t, 1.0)
	var saw = phase * 2.0 - 1.0
	var tri = 4.0 * absf(phase - 0.5) - 1.0
	var osc = saw * 0.55 + tri * 0.45
	
	# Static lowpass-like harmonic softening.
	var harmonics = 0.0
	for h in range(1, 9):
		var amp = 1.0 / h
		if h > 4:
			amp *= 0.45
		harmonics += sin(TAU * f * h * t) * amp
	harmonics *= 0.22
	
	var body = tanh((osc + harmonics) * 0.85)
	return clampf(body * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 0.35, 0.0)


static func get_duration() -> float:
	return 0.6
