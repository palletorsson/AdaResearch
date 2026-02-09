# EMD House Recreation - Razor Formant Bass
# Character: Tearing mid-bass with moving vowel/formant bite
# Source: Modern EDM formant bass workflows (Vital/Serum style)
# Processing: Dual detuned saw core, moving formant peaks, heavy drive

class_name EmdRazorFormantBass
extends RefCounted

const SAMPLE_RATE = 44100.0

const DETUNE_CENTS = 14.0
const MOVEMENT_HZ = 2.6
const ATTACK_S = 0.003
const RELEASE_S = 0.26
const GATE_S = 0.70
const DRIVE = 2.4
const LEVEL = 0.31


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 1.2:
		return 0.0

	var env = _envelope(dt)
	if env <= 0.0:
		return 0.0

	var movement = _shape_lfo(dt)
	var core = _detuned_saw(t, freq)
	var sub = sin(TAU * freq * 0.5 * t) * 0.18
	var source = core * (0.22 + movement * 0.78) + sub

	# Two moving formants ("a" -> "e" style).
	var morph = 0.5 + 0.5 * sin(TAU * MOVEMENT_HZ * dt)
	var f1 = lerp(560.0, 980.0, morph)
	var f2 = lerp(1300.0, 2350.0, morph)
	var formant = _bandpass(source, f1, 5.5) * 0.58 + _bandpass(source, f2, 7.6) * 0.42

	var output = source * 0.32 + formant * 0.68
	output = tanh(output * DRIVE)
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func _detuned_saw(t: float, freq: float) -> float:
	var ratio = pow(2.0, DETUNE_CENTS / 1200.0)
	var saw_a = fmod(freq * ratio * t, 1.0) * 2.0 - 1.0
	var saw_b = fmod(freq / ratio * t, 1.0) * 2.0 - 1.0
	return (saw_a + saw_b) * 0.5


static func _bandpass(input: float, center_hz: float, q: float) -> float:
	var bw = center_hz / maxf(q, 0.1)
	var alpha = bw / (bw + SAMPLE_RATE / TAU)
	return input * alpha * q * 0.3


static func _shape_lfo(dt: float) -> float:
	var phase = fmod(dt * MOVEMENT_HZ, 1.0)
	if phase < 0.48:
		return pow(phase / 0.48, 0.7)
	var down = 1.0 - ((phase - 0.48) / 0.52)
	return pow(maxf(down, 0.0), 2.1)


static func _envelope(dt: float) -> float:
	if dt < ATTACK_S:
		return dt / ATTACK_S
	if dt < GATE_S:
		return 1.0
	return exp(-(dt - GATE_S) / RELEASE_S)


static func get_duration() -> float:
	return 1.2
