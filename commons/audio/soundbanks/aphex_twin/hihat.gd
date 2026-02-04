# Aphex Twin Hi-Hat - Intricate, velocity-sensitive
#
# Character: Metallic but warm, varied velocity
# Source: TR-808/909 + tape

class_name AphexHihat
extends RefCounted

const SAMPLE_RATE = 44100.0

const CLOSED_DECAY = 0.025
const OPEN_DECAY = 0.18
const LEVEL = 0.18


static func generate(t: float, trigger_time: float = 0.0, open: bool = false) -> float:
	var dt = t - trigger_time
	if dt < 0.0:
		return 0.0
	
	var decay = OPEN_DECAY if open else CLOSED_DECAY
	if dt > decay * 5.0:
		return 0.0
	
	# Envelope
	var env = exp(-dt / decay)
	
	# Metallic tone cluster
	var tone1 = sin(TAU * 4500.0 * dt)
	var tone2 = sin(TAU * 6000.0 * dt)
	var tone3 = sin(TAU * 7500.0 * dt)
	var tone4 = sin(TAU * 9000.0 * dt)
	
	# Noise component
	var rng = RandomNumberGenerator.new()
	rng.seed = int(t * SAMPLE_RATE) % 100000
	var noise = rng.randf_range(-1.0, 1.0)
	
	var output = (tone1 * 0.2 + tone2 * 0.25 + tone3 * 0.15 + tone4 * 0.1 + noise * 0.3) * env
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func generate_closed(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, false)


static func generate_open(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, true)
