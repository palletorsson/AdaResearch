# Moroder Disco Kick - CR-78 style, punchy but not overpowering
# Character: Clean, tight, 4-on-floor foundation
# Source: Roland CR-78 / electronic

class_name MoroderKick
extends RefCounted

const SAMPLE_RATE = 44100.0
const LEVEL = 0.18

static func generate(t: float, freq: float = 0.0, duration: float = 0.2, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.2:
		return 0.0
	
	# Pitch envelope: 120Hz -> 50Hz
	var pitch_env = exp(-dt * 25.0)
	var kick_freq = 50.0 + 70.0 * pitch_env
	
	# Clean sine body
	var body = sin(TAU * kick_freq * dt)
	
	# Click transient
	var click = 0.0
	if dt < 0.005:
		click = sin(TAU * 2500.0 * dt) * (1.0 - dt / 0.005)
	
	# Amplitude envelope
	var env = exp(-dt * 15.0)
	
	return clampf((body * 0.8 + click * 0.3) * env * LEVEL, -1.0, 1.0)

static func get_duration() -> float:
	return 0.2
