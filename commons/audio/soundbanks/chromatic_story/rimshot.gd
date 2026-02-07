# Chromatic Story Rimshot - Woody Jazz Click
#
# Character: The classic jazz rimclick - delicate and woody
# Used for subtle accents and groove articulation

class_name ChromaticRimshot
extends RefCounted

const SAMPLE_RATE = 44100.0

const CLICK_FREQ = 1200.0
const BODY_FREQ = 400.0
const ATTACK = 0.001
const DECAY = 0.08
const LEVEL = 0.22


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.15:
		return 0.0
	
	# Sharp attack, quick decay
	var env = 0.0
	if dt < ATTACK:
		env = dt / ATTACK
	else:
		env = exp(-dt / DECAY)
	
	# Woody click transient
	var click = sin(2.0 * PI * CLICK_FREQ * dt) * exp(-dt * 80.0)
	
	# Stick body resonance  
	var body = sin(2.0 * PI * BODY_FREQ * dt) * exp(-dt * 20.0)
	
	var output = click * 0.6 + body * 0.4
	
	return clampf(output * env * LEVEL, -1.0, 1.0)
