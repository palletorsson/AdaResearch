# Boards of Canada Hi-Hat - Dusty, Dark
# Research: boards_of_canada.md
#
# Character: High shelf cut, dusty
#
# FROM RESEARCH:
# "High shelf cut -3dB, dusty"

class_name BoCHihat
extends RefCounted

const SAMPLE_RATE = 44100.0

const CLOSED_DECAY_S = 0.035
const OPEN_DECAY_S = 0.12
const LEVEL = 0.08  # Quiet, rolled off


static func generate(t: float, trigger_time: float = 0.0, open: bool = false) -> float:
	var dt = t - trigger_time
	var max_dur = 0.2 if open else 0.1
	if dt < 0.0 or dt > max_dur:
		return 0.0
	
	var decay = OPEN_DECAY_S if open else CLOSED_DECAY_S
	var env = exp(-dt / decay)
	
	var noise = (randf() * 2.0 - 1.0)
	
	# High shelf cut - darker sound
	return clampf(noise * env * LEVEL * 0.7, -1.0, 1.0)


static func generate_closed(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, false)


static func generate_open(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, true)
