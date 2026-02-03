# Kraftwerk Hi-Hat - Motorik Style
# Research: kraftwerk.md
#
# Character: Clean, driving 8th note pattern (motorik beat)
# Source: Neu!/Kraftwerk motorik tradition
#
# FROM RESEARCH:
# "Motorik beat: Steady 4/4 with driving 8th-note hi-hats"
# "Clean electronic hats - zero distortion"

class_name KraftwerkHihat
extends RefCounted

const SAMPLE_RATE = 44100.0

const CLOSED_DECAY_S = 0.025      # Tight
const OPEN_DECAY_S = 0.1
const LEVEL = 0.12                # Clean, not harsh


static func generate(t: float, trigger_time: float = 0.0, open: bool = false) -> float:
	var dt = t - trigger_time
	var max_dur = 0.15 if open else 0.08
	if dt < 0.0 or dt > max_dur:
		return 0.0
	
	var decay = OPEN_DECAY_S if open else CLOSED_DECAY_S
	var env = exp(-dt / decay)
	
	var noise = (randf() * 2.0 - 1.0)
	
	# Clean - no processing
	return clampf(noise * env * LEVEL, -1.0, 1.0)


static func generate_closed(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, false)


static func generate_open(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, true)
