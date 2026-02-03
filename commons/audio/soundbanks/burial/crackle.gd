# Burial Vinyl Crackle - ALWAYS PRESENT
# Research: burial.md
#
# Character: Constant vinyl surface noise with pops and clicks
# Source: Vinyl records, deliberate lo-fi aesthetic
#
# FROM RESEARCH:
# "Vinyl crackle: pink noise -15dB, always present"
# "Density 0.004 for pops"
# "Ever-present surface noise and atmosphere"

class_name BurialCrackle
extends RefCounted

const SAMPLE_RATE = 44100.0

# Vinyl crackle parameters
const BASE_LEVEL = 0.018          # -15dB base crackle
const POP_CHANCE = 0.004          # Chance of pop per sample
const BIG_POP_CHANCE = 0.001      # Chance of big pop
const POP_LEVEL = 0.12            # Pop volume
const BIG_POP_LEVEL = 0.25        # Big pop volume


static func generate(t: float, _trigger_time: float = 0.0) -> float:
	# Base crackle - always present
	var crackle = (randf() * 2.0 - 1.0) * BASE_LEVEL
	
	# Random pops
	if randf() < POP_CHANCE:
		crackle += (randf() * 2.0 - 1.0) * POP_LEVEL
	
	# Occasional big pops
	if randf() < BIG_POP_CHANCE:
		crackle += (randf() * 2.0 - 1.0) * BIG_POP_LEVEL
	
	return clampf(crackle, -1.0, 1.0)


# Crackle is continuous - no duration limit
static func get_duration() -> float:
	return 999999.0
