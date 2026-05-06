# Burial Kick - UK Garage Style (NOT on beat 1!)
# Research: burial.md
#
# Character: Soft, sub-heavy, avoids beat 1 (2-step pattern)
# Source: UK Garage production
# Processing: NOT quantized - "fishbone look" in waveform
#
# FROM RESEARCH:
# "Kick avoids beat 1" 
# "NOT quantized - minute hesitations"
# "Drums look like a nice fishbone"

class_name BurialKick
extends RefCounted

const SAMPLE_RATE = 44100.0

# UK Garage kick - softer than techno
const PITCH_START_HZ = 90.0       # Lower start
const PITCH_END_HZ = 48.0         # Deep sub
const PITCH_DECAY_S = 0.035       # Slower pitch drop
const BODY_DECAY_S = 0.15         # Longer body
const LEVEL = 0.45                # Softer than techno


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.5:
		return 0.0
	
	# Pitch envelope
	var pitch_env = exp(-dt / PITCH_DECAY_S)
	var freq = PITCH_END_HZ + (PITCH_START_HZ - PITCH_END_HZ) * pitch_env
	
	# Soft body
	var body = sin(2.0 * PI * freq * dt) * exp(-dt / BODY_DECAY_S)
	
	# No click - UK garage kicks are rounder
	return clampf(body * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.5
