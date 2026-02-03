# Boards of Canada Melodic Sequence
# Research: boards_of_canada.md
#
# Character: Simple, childlike melody with tape processing
#
# FROM RESEARCH:
# "Melodic Sequence: mono detuned, drift 8%, filter 1200Hz"
# "Tape distortion 0.15, dotted eighth delay (0.333s) 35% mix"
# "Heavy high shelf cut -6dB"

class_name BoCSequence
extends RefCounted

const SAMPLE_RATE = 44100.0

const DRIFT_PERCENT = 0.08
const DRIFT_RATE_HZ = 0.15
const DISTORTION = 1.15
const BITCRUSH_LEVELS = 512.0     # ~9-bit for sequences
const LEVEL = 0.15


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.6:
		return 0.0
	
	# Envelope
	var env = 1.0
	if dt < 0.01:
		env = dt / 0.01
	else:
		env = exp(-(dt - 0.01) * 4.0)
	
	# Tape drift
	var drift = sin(2.0 * PI * DRIFT_RATE_HZ * t) * DRIFT_PERCENT
	var drifted_freq = freq * (1.0 + drift)
	
	# Simple tone
	var tone = sin(2.0 * PI * drifted_freq * t)
	
	# Tape processing
	tone = tanh(tone * DISTORTION)
	tone = floor(tone * BITCRUSH_LEVELS) / BITCRUSH_LEVELS
	
	return clampf(tone * env * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.6
