# Dub House Clap - Sparse accent with dub space
#
# Character: Single sparse clap with long dub room tail
# Source: Handclap through spring reverb and tape delay
# Processing: Extended room, the tail IS the sound
# Reference: Basic Channel's sparse percussive accents

class_name DubHouseClap
extends RefCounted

const SAMPLE_RATE = 44100.0

const BURST_COUNT = 2           # Fewer bursts = tighter, less busy
const BURST_SPACING_S = 0.008   # Tighter spacing
const REVERB_MIX = 0.40         # MORE room tail - dub character!
const LEVEL = 0.20              # Subtle - accent, not main event


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.5:  # Extended duration for dub tail
		return 0.0
	
	var output = 0.0
	
	# Tight initial bursts
	for i in range(BURST_COUNT):
		var burst_time = dt - (i * BURST_SPACING_S)
		if burst_time >= 0.0 and burst_time < 0.015:  # Tighter bursts
			var burst_env = exp(-burst_time / 0.005)
			output += (randf() * 2.0 - 1.0) * burst_env * (1.0 - float(i) * 0.25)
	
	# Extended dub room tail - the signature sound
	if dt > 0.03:
		# Longer decay time for dub space (0.22s vs 0.14s)
		output += (randf() * 2.0 - 1.0) * exp(-dt / 0.22) * REVERB_MIX
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.5  # Longer to let the dub tail breathe
