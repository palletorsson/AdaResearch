# Dub House Hi-Hat - Soft metallic shimmer
#
# Character: Offbeat, low-intensity hat with gentle decay
# Source: 909-style metallic mix, softened
# Processing: Reduced brightness, longer tail

class_name DubHouseHihat
extends RefCounted

const SAMPLE_RATE = 44100.0

const METAL_FREQS = [258.0, 404.0, 431.0, 482.0, 592.0, 818.0]
const CLOSED_DECAY_S = 0.035
const OPEN_DECAY_S = 0.22
const NOISE_LEVEL = 0.35
const METAL_LEVEL = 0.55
const LEVEL = 0.16


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
