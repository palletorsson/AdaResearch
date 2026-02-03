# Rave Kick - Distorted 909
# Research: rave.md
#
# Character: Punchy, distorted, aggressive
# Source: TR-909 through distortion
#
# FROM RESEARCH:
# "Breakbeat foundation, tempo 140-160 BPM"
# "Heavy compression, distortion"

class_name RaveKick
extends RefCounted

const SAMPLE_RATE = 44100.0

const PITCH_START_HZ = 140.0      # Higher for punch
const PITCH_END_HZ = 60.0
const PITCH_DECAY_S = 0.02        # Fast
const BODY_DECAY_S = 0.1
const DISTORTION = 1.8            # Heavy!
const LEVEL = 0.55


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.4:
		return 0.0
	
	var pitch_env = exp(-dt / PITCH_DECAY_S)
	var freq = PITCH_END_HZ + (PITCH_START_HZ - PITCH_END_HZ) * pitch_env
	
	var body = sin(2.0 * PI * freq * dt) * exp(-dt / BODY_DECAY_S)
	
	# Heavy distortion
	body = tanh(body * DISTORTION)
	
	return clampf(body * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.4
