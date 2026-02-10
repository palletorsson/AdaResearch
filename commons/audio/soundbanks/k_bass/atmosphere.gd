# K-Bass Atmosphere - Tension Drone
# Reference: Seoul underground, urban industrial
#
# Character: Dark, textural, urban
# Source: Filtered noise + sub drone
#
# USAGE: Sustained through sections, creates negative space context

class_name KBassAtmosphere
extends RefCounted

const SAMPLE_RATE = 44100.0

const DRONE_HZ = 55.0             # Low drone fundamental
const FILTER_LP_HZ = 400.0        # Lowpass for darkness
const FILTER_HP_HZ = 60.0         # Highpass to clean sub
const LFO_RATE = 0.15             # Very slow movement
const NOISE_LEVEL = 0.15          # Subtle texture
const DRONE_LEVEL = 0.3
const ATTACK_S = 0.5              # Slow fade in
const RELEASE_S = 0.8             # Slow fade out
const LEVEL = 0.25


static func generate(t: float, note_duration: float = 4.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# Envelope
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt > note_duration - RELEASE_S:
		env = maxf(0.0, 1.0 - (dt - (note_duration - RELEASE_S)) / RELEASE_S)
	
	if dt > note_duration:
		return 0.0
	
	# LFO for subtle movement
	var lfo = sin(2.0 * PI * LFO_RATE * t) * 0.5 + 0.5
	
	# Low drone
	var drone = sin(2.0 * PI * DRONE_HZ * t)
	drone += sin(2.0 * PI * DRONE_HZ * 1.5 * t) * 0.3  # Fifth
	drone *= DRONE_LEVEL
	
	# Textural noise (pseudo-noise)
	var noise_phase = t * 3000.0
	var noise = sin(noise_phase) * sin(noise_phase * 1.3) * sin(noise_phase * 0.7)
	noise *= lfo * NOISE_LEVEL
	
	var output = drone + noise
	
	# Gentle saturation
	output = tanh(output * 1.1)
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, _unused = 0.0) -> float:
	return generate(t, 100.0, 0.0)


static func get_duration() -> float:
	return 4.0
