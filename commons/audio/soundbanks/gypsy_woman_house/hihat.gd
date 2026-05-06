# Gypsy Woman House Hi-Hat - Shuffled House Style
#
# Character: Swinging, groovy
# Source: TR-909

class_name GypsyHihat
extends RefCounted

const SAMPLE_RATE = 44100.0

const CLOSED_DECAY_S = 0.028
const OPEN_DECAY_S = 0.12
const LEVEL = 0.15


static func generate(t: float, trigger_time: float = 0.0, open: bool = false) -> float:
	var dt = t - trigger_time
	var max_dur = 0.2 if open else 0.1
	if dt < 0.0 or dt > max_dur:
		return 0.0
	
	var decay = OPEN_DECAY_S if open else CLOSED_DECAY_S
	var env = exp(-dt / decay)
	
	var noise = (randf() * 2.0 - 1.0) * 0.7
	var metal = sin(2.0 * PI * 8500.0 * dt) * 0.3
	
	return clampf((noise + metal) * env * LEVEL, -1.0, 1.0)


static func generate_closed(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, false)


static func generate_open(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, true)
