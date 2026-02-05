# Dub House Hi-Hat - Hypnotic offbeat shimmer
#
# Character: Dark, filtered, tape-saturated offbeat hat
# Source: 909 filtered through tape delay character
# Processing: Heavily filtered, longer shimmer, dub space
# Reference: Basic Channel "Quadrant Dub", Maurizio "Ploy"

class_name DubHouseHihat
extends RefCounted

const SAMPLE_RATE = 44100.0

# Lower frequencies = darker, more filtered sound (tape character)
const METAL_FREQS = [205.0, 320.0, 385.0, 440.0, 520.0, 680.0]  # Tuned DOWN for dub darkness
const CLOSED_DECAY_S = 0.055     # LONGER - more shimmer, hypnotic sustain
const OPEN_DECAY_S = 0.35        # Much longer open hat tail
const NOISE_LEVEL = 0.50         # More noise = softer, airier character
const METAL_LEVEL = 0.40         # Less metal = less harsh, more dub
const LEVEL = 0.14               # Subtle - sits back in the mix


static func generate(t: float, trigger_time: float = 0.0, open: bool = false) -> float:
	var dt = t - trigger_time
	var max_dur = 0.4 if open else 0.12
	if dt < 0.0 or dt > max_dur:
		return 0.0
	
	var decay = OPEN_DECAY_S if open else CLOSED_DECAY_S
	var env = exp(-dt / decay)
	
	var metal = 0.0
	for freq in METAL_FREQS:
		var sq = 1.0 if sin(2.0 * PI * freq * t) >= 0.0 else -1.0
		metal += sq
	metal /= METAL_FREQS.size()
	metal *= METAL_LEVEL
	
	var noise = (randf() * 2.0 - 1.0) * NOISE_LEVEL
	
	var output = (metal + noise) * env * LEVEL
	return clampf(output, -1.0, 1.0)


static func generate_closed(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, false)


static func generate_open(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, true)


static func get_duration(open: bool = false) -> float:
	return 0.4 if open else 0.12
