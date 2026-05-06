# Madonna 80s Clap - Pop Handclap
#
# Character: Layered, bright, energetic
# Source: LinnDrum / sampled claps

class_name MadonnaClap
extends RefCounted

const SAMPLE_RATE = 44100.0

const BURST_COUNT = 3
const BURST_SPACING_S = 0.01
const BURST_DECAY_S = 0.006
const REVERB_MIX = 0.25
const LEVEL = 0.3


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.2:
		return 0.0
	
	var output = 0.0
	
	# Layered claps
	for i in range(BURST_COUNT):
		var burst_time = dt - (i * BURST_SPACING_S)
		if burst_time >= 0.0 and burst_time < 0.025:
			var burst_env = exp(-burst_time / BURST_DECAY_S)
			output += (randf() * 2.0 - 1.0) * burst_env * (1.0 - float(i) * 0.2)
	
	# Light reverb
	if dt > 0.03:
		output += (randf() * 2.0 - 1.0) * exp(-dt / 0.08) * REVERB_MIX
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.2
