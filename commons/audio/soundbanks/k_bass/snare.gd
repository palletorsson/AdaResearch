# K-Bass Snare - Tight Jungle
# Reference: Classic jungle snares, minimal reverb
#
# Character: Tight, cracking, punchy
# Source: Break-derived snare, tight processing

class_name KBassSnare
extends RefCounted

const SAMPLE_RATE = 44100.0

const BODY_HZ = 180.0             # Snare body
const CRACK_HZ = 220.0            # Crack frequency
const NOISE_LEVEL = 0.4           # Noise component
const BODY_DECAY_S = 0.08         # Tight body
const NOISE_DECAY_S = 0.1         # Tight noise
const LEVEL = 0.55


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.2:
		return 0.0
	
	# Body tone
	var body = sin(2.0 * PI * BODY_HZ * dt) * exp(-dt / BODY_DECAY_S)
	
	# Crack transient
	var crack = sin(2.0 * PI * CRACK_HZ * dt) * exp(-dt * 80.0) * 0.6
	
	# Noise component (simple pseudo-noise)
	var noise_phase = dt * 8000.0
	var noise = (sin(noise_phase) * sin(noise_phase * 1.7) * sin(noise_phase * 2.3))
	noise *= exp(-dt / NOISE_DECAY_S) * NOISE_LEVEL
	
	var output = body + crack + noise
	
	# Slight saturation
	output = tanh(output * 1.2)
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.2
