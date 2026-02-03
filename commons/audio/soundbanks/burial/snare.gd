# Burial Snare - Fuzzy 2-Step Style
# Research: burial.md
#
# Character: Covered in fuzz and phaser, like cobwebs on forgotten instruments
# Source: UK Garage with heavy processing
#
# FROM RESEARCH:
# "Snares and hi-hats covered in fuzz and phaser, like cobwebs"
# "Mix is rough and ready rather than endlessly polished"

class_name BurialSnare
extends RefCounted

const SAMPLE_RATE = 44100.0

const BODY_FREQ_HZ = 160.0        # Lower than techno
const BODY_DECAY_S = 0.05         # Medium decay
const NOISE_DECAY_S = 0.06        # Longer noise tail
const FUZZ_AMOUNT = 2.0           # Heavy saturation
const LEVEL = 0.2                 # Quieter in mix


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.3:
		return 0.0
	
	# Body
	var body = sin(2.0 * PI * BODY_FREQ_HZ * dt) * exp(-dt / BODY_DECAY_S) * 0.4
	
	# Noise with fuzz
	var noise = (randf() * 2.0 - 1.0) * exp(-dt / NOISE_DECAY_S) * 0.5
	
	var output = body + noise
	
	# "Covered in fuzz" - heavy saturation
	output = tanh(output * FUZZ_AMOUNT)
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.3
