# Gypsy Woman House Clap - House Handclap
#
# Character: Room clap, slightly reverbed
# Source: TR-909 / sampled

class_name GypsyClap
extends RefCounted

const SAMPLE_RATE = 44100.0

const BURST_COUNT = 4
const BURST_SPACING_S = 0.008
const REVERB_MIX = 0.2
const LEVEL = 0.28


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.2:
		return 0.0
	
	var output = 0.0
	
	for i in range(BURST_COUNT):
		var burst_time = dt - (i * BURST_SPACING_S)
		if burst_time >= 0.0 and burst_time < 0.02:
			var burst_env = exp(-burst_time / 0.005)
			output += (randf() * 2.0 - 1.0) * burst_env * (1.0 - float(i) * 0.15)
	
	# Room reverb
	if dt > 0.035:
		output += (randf() * 2.0 - 1.0) * exp(-dt / 0.1) * REVERB_MIX
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.2
