# K-Bass Stab - Metallic Punctuation
# Reference: K-Bass aesthetic - textural, not melodic
#
# Character: Sharp, FM-metallic, short decay
# Source: FM synthesis for metallic character
#
# USAGE: Sparse, dramatic placement — impact moments only

class_name KBassStab
extends RefCounted

const SAMPLE_RATE = 44100.0

const CARRIER_RATIO = 1.0
const MODULATOR_RATIO = 3.5       # FM metallic ratio
const MOD_INDEX = 4.0             # FM intensity
const ATTACK_S = 0.001            # Instant
const DECAY_S = 0.08              # Short
const FILTER_HZ = 1500.0          # Bandpass center
const DISTORTION = 1.5
const LEVEL = 0.45


static func generate(t: float, freq_source = 220.0, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.15:
		return 0.0
	
	var freq = _resolve_freq(freq_source)
	if freq <= 0.0:
		return 0.0
	
	# Envelope
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	else:
		env = exp(-(dt - ATTACK_S) / DECAY_S)
	
	# FM synthesis
	var carrier_freq = freq * CARRIER_RATIO
	var mod_freq = freq * MODULATOR_RATIO
	
	# Modulator with decay
	var mod_env = exp(-dt * 15.0)  # Fast mod decay
	var modulator = sin(2.0 * PI * mod_freq * dt) * MOD_INDEX * mod_env
	
	# Carrier with FM
	var carrier = sin(2.0 * PI * carrier_freq * dt + modulator)
	
	# Add some harmonic content
	var harmonic = sin(2.0 * PI * carrier_freq * 2.0 * dt) * 0.3
	
	var output = carrier + harmonic
	
	# Distortion for edge
	output = tanh(output * DISTORTION)
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq_source = 220.0) -> float:
	return generate(t, freq_source, 0.0)


static func _resolve_freq(source) -> float:
	if source is Array:
		var values: Array = source
		if values.is_empty():
			return 220.0
		return maxf(float(values[0]), 1.0)
	return maxf(float(source), 1.0)


static func get_duration() -> float:
	return 0.15
