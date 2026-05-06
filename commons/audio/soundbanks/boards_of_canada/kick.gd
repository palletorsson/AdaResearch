# Boards of Canada Kick - Lo-Fi Breakbeat Style
# Research: boards_of_canada.md
#
# Character: Dusty, lo-fi, hip-hop influenced
# Source: Sampled breakbeats through tape/bitcrush
#
# FROM RESEARCH:
# "Hip-hop influenced tempo (~100 BPM)"
# "Bit crushing 12-bit, moderate distortion 0.2"
# "High shelf cut -3dB"

class_name BoCKick
extends RefCounted

const SAMPLE_RATE = 44100.0

const PITCH_START_HZ = 100.0
const PITCH_END_HZ = 50.0
const PITCH_DECAY_S = 0.025
const BODY_DECAY_S = 0.12
const BITCRUSH_LEVELS = 2048.0    # 12-bit simulation
const DISTORTION = 1.2            # Moderate saturation
const LEVEL = 0.42


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.5:
		return 0.0
	
	var pitch_env = exp(-dt / PITCH_DECAY_S)
	var freq = PITCH_END_HZ + (PITCH_START_HZ - PITCH_END_HZ) * pitch_env
	
	var body = sin(2.0 * PI * freq * dt) * exp(-dt / BODY_DECAY_S)
	
	# 12-bit quantization
	body = floor(body * BITCRUSH_LEVELS) / BITCRUSH_LEVELS
	
	# Tape saturation
	body = tanh(body * DISTORTION)
	
	return clampf(body * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.5
