# Detroit Techno Clap - TR-909 Style
# Research: detroit_techno.md
#
# Character: Layered, tight, punchy
# Source: TR-909 clap circuit (multiple triggers)
# Processing: CLEAN - minimal reverb

class_name DetroitClap
extends RefCounted

const SAMPLE_RATE = 44100.0

# 909 Clap Parameters
# Layered noise bursts (909 clap is multiple triggers)
const BURST_COUNT = 4             # Number of noise bursts
const BURST_SPACING_S = 0.012     # Time between bursts
const BURST_DECAY_S = 0.008       # Individual burst decay
const TAIL_DECAY_S = 0.08         # Final tail decay
const REVERB_AMOUNT = 0.15        # Very light reverb (Detroit is dry)
const LEVEL = 0.28


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.25:
		return 0.0
	
	var output = 0.0
	
	# Multiple noise bursts (909 clap characteristic)
	for i in range(BURST_COUNT):
		var burst_time = dt - (i * BURST_SPACING_S)
		if burst_time >= 0.0 and burst_time < 0.03:
			var burst_env = exp(-burst_time / BURST_DECAY_S)
			var noise = randf() * 2.0 - 1.0
			output += noise * burst_env * (1.0 - float(i) * 0.15)  # Each burst slightly quieter
	
	# Tail
	var tail_start = BURST_COUNT * BURST_SPACING_S
	if dt > tail_start:
		var tail_time = dt - tail_start
		var tail_env = exp(-tail_time / TAIL_DECAY_S)
		var tail_noise = randf() * 2.0 - 1.0
		output += tail_noise * tail_env * 0.4
	
	# Very subtle reverb tail (Detroit is mostly dry)
	if dt > 0.05:
		var rev_noise = randf() * 2.0 - 1.0
		output += rev_noise * exp(-dt / 0.12) * REVERB_AMOUNT
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.25
