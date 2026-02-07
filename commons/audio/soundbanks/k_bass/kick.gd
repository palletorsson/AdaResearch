# K-Bass Kick - Jungle Break Derived
# Reference: yunji "ECHO", jungle/DnB lineage
#
# Character: Punchy break kick with sub layer
# Source: Break-derived with added sub weight

class_name KBassKick
extends RefCounted

const SAMPLE_RATE = 44100.0

const PUNCH_HZ = 100.0            # Break punch frequency
const SUB_HZ = 50.0               # Sub layer
const PITCH_START_HZ = 120.0
const PITCH_END_HZ = 55.0
const PITCH_DECAY_S = 0.015       # Fast jungle transient
const BODY_DECAY_S = 0.15         # Medium body
const SUB_DECAY_S = 0.25          # Longer sub tail
const SATURATION = 1.4            # Break character
const LEVEL = 0.6


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.35:
		return 0.0
	
	# Pitch envelope for transient
	var pitch_env = exp(-dt / PITCH_DECAY_S)
	var freq = PITCH_END_HZ + (PITCH_START_HZ - PITCH_END_HZ) * pitch_env
	
	# Main body (break character)
	var body = sin(2.0 * PI * freq * dt) * exp(-dt / BODY_DECAY_S)
	
	# Sub layer for weight
	var sub = sin(2.0 * PI * SUB_HZ * dt) * exp(-dt / SUB_DECAY_S) * 0.6
	
	# Click transient
	var click = sin(2.0 * PI * 4000.0 * dt) * exp(-dt * 300.0) * 0.15
	
	var output = body + sub + click
	
	# Saturation for break character
	output = tanh(output * SATURATION)
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.35
