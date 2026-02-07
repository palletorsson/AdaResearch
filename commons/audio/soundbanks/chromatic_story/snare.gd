# Chromatic Story Snare - Brushed Jazz Snare
#
# Character: Soft brushed snare - whispered not slapped
# Jazz club intimacy, not stadium rock

class_name ChromaticSnare
extends RefCounted

const SAMPLE_RATE = 44100.0

const BRUSH_FREQ = 200.0
const BODY_FREQ = 180.0
const ATTACK = 0.008
const DECAY = 0.2
const LEVEL = 0.25


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.4:
		return 0.0
	
	# Soft brushed envelope
	var env = 0.0
	if dt < ATTACK:
		env = dt / ATTACK
	else:
		env = exp(-dt / DECAY)
	
	# Brush swish (filtered noise)
	var noise = (randf() * 2.0 - 1.0) * 0.6
	
	# Body resonance
	var body = sin(2.0 * PI * BODY_FREQ * dt) * exp(-dt * 15.0)
	
	# Combine with emphasis on brush texture
	var output = noise * 0.7 + body * 0.3
	
	return clampf(output * env * LEVEL, -1.0, 1.0)
