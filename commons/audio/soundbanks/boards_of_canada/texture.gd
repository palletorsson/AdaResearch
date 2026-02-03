# Boards of Canada Texture Layer
# Research: boards_of_canada.md
#
# Character: VHS crackle, tape noise, lo-fi atmosphere
#
# FROM RESEARCH:
# "Texture: 10-bit, distortion 0.25"
# "VHS crackle occasional pops"

class_name BoCTexture
extends RefCounted

const SAMPLE_RATE = 44100.0

const BASE_LEVEL = 0.012          # Subtle background noise
const POP_CHANCE = 0.002          # VHS pops
const POP_LEVEL = 0.08


static func generate(t: float, _trigger_time: float = 0.0) -> float:
	# Base tape noise
	var noise = (randf() * 2.0 - 1.0) * BASE_LEVEL
	
	# VHS pops
	if randf() < POP_CHANCE:
		noise += (randf() * 2.0 - 1.0) * POP_LEVEL
	
	return clampf(noise, -1.0, 1.0)


static func get_duration() -> float:
	return 999999.0
