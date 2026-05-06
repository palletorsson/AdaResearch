# Dub House Snare - Rimshot character with dub space
#
# Character: More rimshot than snare - tight, clicky, minimal body
# Source: 909 snare with snares OFF (rimshot mode)
# Processing: Tight, lets the delay tail do the work
# Reference: Rhythm & Sound sparse percussion, Basic Channel rimshots

class_name DubHouseSnare
extends RefCounted

const SAMPLE_RATE = 44100.0

const BODY_HZ = 240.0           # Higher = more rimshot character
const BODY_DECAY_S = 0.04       # SHORTER body - tighter, more click
const NOISE_DECAY_S = 0.10      # Shorter noise - space for delay echoes
const TONE_MIX = 0.60           # More tone = more rimshot character
const NOISE_MIX = 0.40          # Less noise = cleaner
const LEVEL = 0.22              # Subtle - dub house is about space


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.3:
		return 0.0
	
	var body = sin(2.0 * PI * BODY_HZ * dt) * exp(-dt / BODY_DECAY_S)
	var noise = (randf() * 2.0 - 1.0) * sin(2.0 * PI * 3000.0 * dt)
	noise *= exp(-dt / NOISE_DECAY_S)
	
	var output = body * TONE_MIX + noise * NOISE_MIX
	output = tanh(output * 1.2)
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.3
