# Kraftwerk Snare - Clean Electronic
# Research: kraftwerk.md
#
# Character: Clean, precise, electronic
#
# FROM RESEARCH:
# "Clean - zero distortion"

class_name KraftwerkSnare
extends RefCounted

const SAMPLE_RATE = 44100.0

const BODY_FREQ_HZ = 220.0        # Pitched electronic snare
const BODY_DECAY_S = 0.035
const NOISE_DECAY_S = 0.04
const LEVEL = 0.2                 # Clean, not aggressive


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.2:
		return 0.0
	
	var body = sin(2.0 * PI * BODY_FREQ_HZ * dt) * exp(-dt / BODY_DECAY_S) * 0.45
	var noise = (randf() * 2.0 - 1.0) * exp(-dt / NOISE_DECAY_S) * 0.4
	
	# NO distortion - perfectly clean
	return clampf((body + noise) * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.2
