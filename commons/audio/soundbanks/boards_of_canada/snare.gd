# Boards of Canada Snare - Dusty Lo-Fi
# Research: boards_of_canada.md
#
# Character: Lo-fi, bit-crushed, tape-saturated
#
# FROM RESEARCH:
# "12-bit, distortion 0.2, high shelf -3dB"

class_name BoCSnare
extends RefCounted

const SAMPLE_RATE = 44100.0

const BODY_FREQ_HZ = 170.0
const BODY_DECAY_S = 0.04
const NOISE_DECAY_S = 0.05
const BITCRUSH_LEVELS = 2048.0
const DISTORTION = 1.2
const LEVEL = 0.28


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.3:
		return 0.0
	
	var body = sin(2.0 * PI * BODY_FREQ_HZ * dt) * exp(-dt / BODY_DECAY_S) * 0.45
	var noise = (randf() * 2.0 - 1.0) * exp(-dt / NOISE_DECAY_S) * 0.5
	
	var output = body + noise
	
	# 12-bit
	output = floor(output * BITCRUSH_LEVELS) / BITCRUSH_LEVELS
	
	# Tape saturation
	output = tanh(output * DISTORTION)
	
	# Rolled off highs (simulated by reducing noise contribution)
	return clampf(output * LEVEL * 0.85, -1.0, 1.0)


static func get_duration() -> float:
	return 0.3
