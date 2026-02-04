# Moroder Disco Bass - Minimoog style, follows root
# Character: Round, pulsing, foundation
# Source: Minimoog

class_name MoroderBass
extends RefCounted

const SAMPLE_RATE = 44100.0
const LEVEL = 0.15

static func generate(t: float, freq: float, duration: float = 0.2, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > duration:
		return 0.0
	
	# Sub bass (sine)
	var sub = sin(TAU * freq * dt)
	
	# Filtered saw for body
	var saw = fmod(freq * 2.0 * dt, 1.0) * 2.0 - 1.0
	
	# Simple lowpass
	var cutoff = 400.0
	var alpha = cutoff / (cutoff + SAMPLE_RATE / TAU)
	saw = saw * alpha  # Rough approximation
	
	# Mix
	var output = sub * 0.7 + saw * 0.3
	
	# Envelope
	var env = 1.0
	if dt < 0.01:
		env = dt / 0.01
	elif dt > duration - 0.05:
		env = (duration - dt) / 0.05
	
	return clampf(output * env * LEVEL, -1.0, 1.0)

static func get_duration() -> float:
	return 0.5
