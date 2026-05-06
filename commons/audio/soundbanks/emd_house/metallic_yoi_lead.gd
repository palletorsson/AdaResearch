# EMD House Recreation - Metallic Yoi Lead
# Character: Metallic talking lead with fast FM and "yoi" contour
# Source: Modern bass house / color bass lead design techniques
# Processing: FM core, spectral tilt, aggressive distortion and macro envelope

class_name EmdMetallicYoiLead
extends RefCounted

const SAMPLE_RATE = 44100.0

const FM_RATIO = 2.8
const FM_INDEX = 4.2
const MOVEMENT_HZ = 3.0
const ATTACK_S = 0.002
const RELEASE_S = 0.22
const GATE_S = 0.62
const DRIVE = 2.7
const LEVEL = 0.27


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 1.1:
		return 0.0

	var env = _envelope(dt)
	if env <= 0.0:
		return 0.0

	var yoi = _yoi_curve(dt)
	var mod = sin(TAU * freq * FM_RATIO * t) * FM_INDEX * (0.3 + yoi * 0.7)
	var carrier = sin(TAU * freq * t + mod)
	var metallic = sin(TAU * freq * 5.0 * t + carrier * 1.2)
	var ring = carrier * metallic
	var source = carrier * 0.56 + metallic * 0.24 + ring * 0.20

	# Pseudo moving high-mid emphasis.
	var moving_hp = 0.65 + 0.35 * sin(TAU * MOVEMENT_HZ * dt)
	var shaped = source * moving_hp + sin(TAU * freq * 0.5 * t) * 0.08

	var output = tanh(shaped * DRIVE)
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func _yoi_curve(dt: float) -> float:
	var phase = fmod(dt * MOVEMENT_HZ, 1.0)
	if phase < 0.42:
		return pow(phase / 0.42, 0.52)
	var down = 1.0 - ((phase - 0.42) / 0.58)
	return pow(maxf(down, 0.0), 2.5)


static func _envelope(dt: float) -> float:
	if dt < ATTACK_S:
		return dt / ATTACK_S
	if dt < GATE_S:
		return 1.0
	return exp(-(dt - GATE_S) / RELEASE_S)


static func get_duration() -> float:
	return 1.1
