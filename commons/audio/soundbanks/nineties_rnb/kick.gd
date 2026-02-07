# 90s R&B Kick - Authentic TR-808
# Character: Deep 808 with 80→50Hz pitch envelope, 600ms decay — Teddy Riley approved
# Reference: Guy "Piece of My Love", Bobby Brown "Every Little Step"

class_name NinetiesRnBKick
extends RefCounted

const SAMPLE_RATE = 44100.0
const LEVEL = 0.75


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.7:
		return 0.0
	
	# Authentic 808 pitch envelope: 80Hz → 50Hz over 40ms
	# This is THE New Jack Swing sound
	var pitch_t = clamp(dt / 0.04, 0.0, 1.0)
	var freq = 50.0 + (80.0 - 50.0) * pow(1.0 - pitch_t, 3.0)
	
	# Main sine oscillator with slight saturation
	var phase = 2.0 * PI * freq * dt
	var osc = sin(phase)
	
	# Slight harmonic distortion for warmth (808 character)
	osc = osc + 0.15 * sin(phase * 2.0) * exp(-dt * 8.0)
	
	# 600ms decay envelope - long sustaining sub
	var decay_time = 0.6
	var amp = pow(max(0.0, 1.0 - dt / decay_time), 1.2)
	
	# Punch transient (attack click) - subtle but present
	var click = 0.0
	if dt < 0.008:
		# Broadband click with quick decay
		var click_phase = 2.0 * PI * 1800.0 * dt
		click = sin(click_phase) * (1.0 - dt / 0.008) * 0.18
	
	# Sub weight boost in the 40-60Hz range
	var sub = sin(2.0 * PI * 45.0 * dt) * amp * 0.25
	
	return clampf((osc + click + sub) * amp * LEVEL, -1.0, 1.0)
