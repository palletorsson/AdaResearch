# Madonna 80s Hi-Hat - Crisp Pop Hat
#
# Character: Bright, crisp, danceable
# Source: LinnDrum

class_name MadonnaHihat
extends RefCounted

const SAMPLE_RATE = 44100.0

const CLOSED_DECAY_S = 0.025
const OPEN_DECAY_S = 0.1
const LEVEL = 0.16


static func generate(t: float, trigger_time: float = 0.0, open: bool = false) -> float:
	var dt = t - trigger_time
	var max_dur = 0.2 if open else 0.08
	if dt < 0.0 or dt > max_dur:
		return 0.0
	
	var decay = OPEN_DECAY_S if open else CLOSED_DECAY_S
	var env = exp(-dt / decay)
	
	var noise = (randf() * 2.0 - 1.0) * 0.7
	var bright = sin(2.0 * PI * 10000.0 * dt) * 0.3
	
	return clampf((noise + bright) * env * LEVEL, -1.0, 1.0)


static func generate_closed(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, false)


static func generate_open(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, true)
