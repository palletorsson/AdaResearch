# Kraftwerk Kick - Custom Electronic Percussion
# Research: kraftwerk.md
#
# Character: Clean, pitched, electronic - NOT distorted
# Source: Custom-built electronic drums, pre-drum machine era
#
# FROM RESEARCH:
# "Electric Percussion: pitch envelope, zero distortion - CLEAN"
# "Resonant filter for pitched boing sounds"

class_name KraftwerkKick
extends RefCounted

const SAMPLE_RATE = 44100.0

# Clean electronic kick - NO distortion
const PITCH_START_HZ = 115.0
const PITCH_END_HZ = 65.0
const PITCH_DECAY_S = 0.03
const BODY_DECAY_S = 0.12
const LEVEL = 0.4                 # Moderate - clean


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.4:
		return 0.0
	
	var pitch_env = exp(-dt / PITCH_DECAY_S)
	var freq = PITCH_END_HZ + (PITCH_START_HZ - PITCH_END_HZ) * pitch_env
	
	var body = sin(2.0 * PI * freq * dt) * exp(-dt / BODY_DECAY_S)
	
	# NO distortion - Kraftwerk is CLEAN
	return clampf(body * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.4
