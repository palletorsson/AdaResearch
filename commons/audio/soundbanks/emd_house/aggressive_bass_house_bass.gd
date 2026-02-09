# Akayo Recreation - Aggressive Bass House Bass
# Character: Harsh modern bass with layered oscillators, +7 interval trick, and heavy processing
# Source: "How To Create ANY Sound from ANY Song" chapter "Aggressive bass house preset"
# Processing: Complex harmonic wave, +7 semitone layer, LFO-shape amplitude, distortion + pseudo multiband

class_name AkayoAggressiveBassHouseBass
extends RefCounted

const SAMPLE_RATE = 44100.0

const INTERVAL_SEMITONES = 7.0
const WUB_RATE_HZ = 2.35
const ATTACK_S = 0.003
const RELEASE_S = 0.24
const GATE_S = 0.72
const DRIVE = 3.3
const COMP_GAIN = 1.65
const LEVEL = 0.31


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 1.2:
		return 0.0
	
	var env = _envelope(dt)
	if env <= 0.0:
		return 0.0
	
	var lfo = _wub_lfo(dt)
	var ratio = pow(2.0, INTERVAL_SEMITONES / 12.0)
	
	var osc_a = _spectral_wave(t, freq)
	var osc_b = _spectral_wave(t, freq * ratio)
	var sub = sin(TAU * freq * 0.5 * t) * 0.20
	var noise = _noise(t) * 0.018
	
	var mix = osc_a * 0.54 + osc_b * 0.34 + sub + noise
	mix *= 0.14 + lfo * 0.86
	
	var distorted = tanh(mix * (DRIVE + lfo * 1.1))
	var compressed = _pseudo_multiband(distorted)
	return clampf(compressed * env * LEVEL, -1.0, 1.0)


static func _spectral_wave(t: float, freq: float) -> float:
	var phase = fmod(freq * t, 1.0)
	var saw = phase * 2.0 - 1.0
	var pulse = 1.0 if phase < 0.42 else -1.0
	var fold = abs(saw) * 2.0 - 1.0
	
	var fm = sin(TAU * freq * t + sin(TAU * freq * 2.03 * t) * 1.2)
	var metallic = sin(TAU * freq * 3.0 * t + saw * 1.4)
	
	return saw * 0.40 + fold * 0.23 + pulse * 0.16 + fm * 0.13 + metallic * 0.08


static func _pseudo_multiband(x: float) -> float:
	var low = x * 0.65
	var mid = x * abs(x) * 0.35
	var hi = _sign(x) * pow(abs(x), 1.8) * 0.22
	return tanh((low + mid + hi) * COMP_GAIN)


static func _sign(x: float) -> float:
	if x > 0.0:
		return 1.0
	if x < 0.0:
		return -1.0
	return 0.0


static func _wub_lfo(dt: float) -> float:
	var phase = fmod(dt * WUB_RATE_HZ, 1.0)
	if phase < 0.46:
		return pow(phase / 0.46, 0.65)
	var fall = 1.0 - ((phase - 0.46) / 0.54)
	return pow(maxf(fall, 0.0), 1.9)


static func _noise(t: float) -> float:
	var n = sin((t + 1.7) * 15431.129) * 43758.5453
	return (n - floor(n)) * 2.0 - 1.0


static func _envelope(dt: float) -> float:
	if dt < ATTACK_S:
		return dt / ATTACK_S
	if dt < GATE_S:
		return 1.0
	return exp(-(dt - GATE_S) / RELEASE_S)


static func get_duration() -> float:
	return 1.2
