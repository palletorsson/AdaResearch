# Dub House Clap - Soft, roomy, delayed
#
# Character: Short clap with a light room tail
# Source: 909 clap / sampled handclap
# Processing: Small room tail, subtle decay

class_name DubHouseClap
extends RefCounted

const SAMPLE_RATE = 44100.0

const BURST_COUNT = 3
const BURST_SPACING_S = 0.012
const REVERB_MIX = 0.25
const LEVEL = 0.24


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.3:
		return 0.0
	
	var output = 0.0
	
	for i in range(BURST_COUNT):
		var burst_time = dt - (i * BURST_SPACING_S)
		if burst_time >= 0.0 and burst_time < 0.02:
			var burst_env = exp(-burst_time / 0.006)
			output += (randf() * 2.0 - 1.0) * burst_env * (1.0 - float(i) * 0.2)
	
	# Light room tail
	if dt > 0.04:
		output += (randf() * 2.0 - 1.0) * exp(-dt / 0.14) * REVERB_MIX
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.3
