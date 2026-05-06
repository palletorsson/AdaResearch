# Chromatic Story Hi-Hat - Light Jazz Hat
#
# Character: Soft, swung hi-hats - the jazz drummer's touch
# Light and airy, not aggressive

class_name ChromaticHihat
extends RefCounted

const SAMPLE_RATE = 44100.0

const DECAY_CLOSED = 0.05
const DECAY_OPEN = 0.2
const LEVEL = 0.18


static func generate(t: float, trigger_time: float = 0.0, open: bool = false) -> float:
	var dt = t - trigger_time
	if dt < 0.0:
		return 0.0
	
	var decay = DECAY_OPEN if open else DECAY_CLOSED
	if dt > decay * 5.0:
		return 0.0
	
	# Gentle envelope
	var env = exp(-dt / decay)
	
	# High-frequency noise for cymbal
	var noise = (randf() * 2.0 - 1.0)
	
	# High-pass character (metallic ring)
	var ring = sin(2.0 * PI * 8000.0 * dt) * 0.3
	ring += sin(2.0 * PI * 10500.0 * dt) * 0.2
	
	var output = noise * 0.5 + ring * 0.5
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_closed(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, false)


static func generate_open(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, true)
