# Boards of Canada Bass - Warm Drifting Sub
# Research: boards_of_canada.md
#
# Character: Warm, slightly drifting, tape-saturated
#
# FROM RESEARCH:
# "Warm sub bass: filter 400Hz, resonance 0.25, drift 4%"
# "Light distortion 0.1"

class_name BoCBass
extends RefCounted

const SAMPLE_RATE = 44100.0

const CUTOFF_HZ = 400.0
const DRIFT_PERCENT = 0.04        # 4% pitch drift
const DRIFT_RATE_HZ = 0.1         # Slow drift
const DISTORTION = 1.1            # Light
const ATTACK_S = 0.02
const SUSTAIN = 0.7
const LEVEL = 0.4


static func generate(t: float, freq: float, note_duration: float = 1.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# Envelope
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	else:
		env = SUSTAIN
	if dt > note_duration - 0.1:
		env *= 1.0 - (dt - (note_duration - 0.1)) / 0.1
	env = maxf(env, 0.0)
	
	# Pitch drift (tape wow)
	var drift = sin(2.0 * PI * DRIFT_RATE_HZ * t) * DRIFT_PERCENT
	var drifted_freq = freq * (1.0 + drift)
	
	# Warm bass
	var bass = sin(2.0 * PI * drifted_freq * t)
	bass += sin(2.0 * PI * drifted_freq * 2.0 * t) * 0.25  # Harmonic
	
	# Light saturation
	bass = tanh(bass * DISTORTION)
	
	return clampf(bass * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 10.0, 0.0)
