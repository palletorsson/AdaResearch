# K-Bass Hi-Hat - Rolling Jungle
# Reference: Fast jungle hi-hats, metallic character
#
# Character: Crisp, metallic, rolling 16ths
# Source: Break-derived with added brightness

class_name KBassHihat
extends RefCounted

const SAMPLE_RATE = 44100.0

const FREQ_1 = 8000.0             # Primary metallic
const FREQ_2 = 10500.0            # Secondary ring
const FREQ_3 = 12000.0            # Shimmer
const DECAY_CLOSED_S = 0.03       # Tight closed hat
const DECAY_OPEN_S = 0.15         # Open hat sustain
const LEVEL = 0.35


static func generate(t: float, trigger_time: float = 0.0, open: bool = false) -> float:
	var dt = t - trigger_time
	var decay = DECAY_OPEN_S if open else DECAY_CLOSED_S
	var max_dur = 0.25 if open else 0.08
	
	if dt < 0.0 or dt > max_dur:
		return 0.0
	
	# Metallic components
	var metal1 = sin(2.0 * PI * FREQ_1 * dt) * 0.5
	var metal2 = sin(2.0 * PI * FREQ_2 * dt) * 0.3
	var metal3 = sin(2.0 * PI * FREQ_3 * dt) * 0.2
	
	# Noise component
	var noise_phase = dt * 15000.0
	var noise = sin(noise_phase) * sin(noise_phase * 1.3) * 0.4
	
	var output = (metal1 + metal2 + metal3 + noise) * exp(-dt / decay)
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func generate_closed(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, false)


static func generate_open(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, true)


static func get_duration() -> float:
	return 0.08
