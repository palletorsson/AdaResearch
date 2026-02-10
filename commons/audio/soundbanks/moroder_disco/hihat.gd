# Moroder Disco Hi-Hat - Crisp 16th notes
# Character: Electronic, driving, constant pulse
# Source: CR-78 / synthesized

class_name MoroderHihat
extends RefCounted

const SAMPLE_RATE = 44100.0
const LEVEL = 0.08

static func generate(t: float, freq: float = 0.0, duration_source = 0.05, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	var duration := 0.05
	if duration_source is bool:
		duration = 0.12 if duration_source else 0.05
	else:
		duration = clampf(float(duration_source), 0.02, 0.2)
	
	if dt < 0.0 or dt > (duration + 0.03):
		return 0.0
	
	# Noise source
	var noise = randf() * 2.0 - 1.0
	
	# Metallic component (high frequency)
	var metallic = sin(TAU * 8000.0 * dt) * 0.3
	metallic += sin(TAU * 10500.0 * dt) * 0.2
	
	# Mix
	var output = noise * 0.6 + metallic
	
	# Sharp envelope
	var env = exp(-dt * (80.0 if duration <= 0.06 else 45.0))
	
	return clampf(output * env * LEVEL, -1.0, 1.0)

static func get_duration() -> float:
	return 0.08
