# Rave Hi-Hat - Frantic
# Research: rave.md
#
# Character: Fast, aggressive
#
# FROM RESEARCH:
# "140-160 BPM, frantic"

class_name RaveHihat
extends RefCounted

const SAMPLE_RATE = 44100.0

const CLOSED_DECAY_S = 0.02       # Very short - frantic
const OPEN_DECAY_S = 0.08
const LEVEL = 0.18


static func generate(t: float, trigger_time: float = 0.0, open: bool = false) -> float:
	var dt = t - trigger_time
	var max_dur = 0.15 if open else 0.06
	if dt < 0.0 or dt > max_dur:
		return 0.0
	
	var decay = OPEN_DECAY_S if open else CLOSED_DECAY_S
	var env = exp(-dt / decay)
	
	var noise = (randf() * 2.0 - 1.0)
	
	return clampf(noise * env * LEVEL, -1.0, 1.0)


static func generate_closed(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, false)


static func generate_open(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, true)
