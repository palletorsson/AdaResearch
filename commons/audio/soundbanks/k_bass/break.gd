# K-Bass Break - Chopped Break Overlay
# Reference: Amen, Think, Funky Drummer lineage
#
# Character: Syncopated rhythmic texture, ghost notes
# Source: Synthesized break character (not sample-based)
#
# USAGE: Overlays main drums for jungle texture

class_name KBassBreak
extends RefCounted

const SAMPLE_RATE = 44100.0

# Combined break character - pitched noise + body
const BODY_HZ = 250.0
const NOISE_FILTER_HZ = 4000.0
const DECAY_S = 0.06              # Tight, choppy
const SATURATION = 1.6            # Break character
const LEVEL = 0.3


static func generate(t: float, trigger_time: float = 0.0, velocity: float = 1.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.12:
		return 0.0
	
	var env = exp(-dt / DECAY_S)
	
	# Body component
	var body = sin(2.0 * PI * BODY_HZ * dt) * 0.4
	
	# Noise component (pitched noise character)
	var noise_phase = dt * NOISE_FILTER_HZ
	var noise = sin(noise_phase) * sin(noise_phase * 1.5) * sin(noise_phase * 0.8)
	noise *= 0.6
	
	# Transient click
	var click = sin(2.0 * PI * 5000.0 * dt) * exp(-dt * 400.0) * 0.3
	
	var output = (body + noise + click) * env
	
	# Saturation for break character
	output = tanh(output * SATURATION)
	
	return clampf(output * LEVEL * velocity, -1.0, 1.0)


static func get_duration() -> float:
	return 0.12
