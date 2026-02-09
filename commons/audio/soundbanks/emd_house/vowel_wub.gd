# Akayo Recreation - Vowel Wub
# Character: "wow"-shaped wub with animated vowel/formant movement
# Source: "How To Create ANY Sound from ANY Song" chapter "Vowel effect"
# Processing: LFO-driven amp, moving formants, dual-peak emphasis, gentle distortion

class_name AkayoVowelWub
extends RefCounted

const SAMPLE_RATE = 44100.0

const UNISON_VOICES = 3
const DETUNE_CENTS = 10.0
const WUB_RATE_HZ = 2.0
const ATTACK_S = 0.004
const RELEASE_S = 0.24
const GATE_S = 0.74
const DRIVE = 2.0
const LEVEL = 0.31


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 1.2:
		return 0.0
	
	var env = _envelope(dt)
	if env <= 0.0:
		return 0.0
	
	var wub = _wub_lfo(dt)
	var source = _unison_saw(t, freq) * (0.25 + 0.75 * wub) + sin(TAU * freq * 0.5 * t) * 0.20
	
	# Vowel motion from two moving formant peaks.
	var vowel = 0.5 + 0.5 * sin(TAU * WUB_RATE_HZ * dt)
	var f1 = lerp(620.0, 940.0, vowel)
	var f2 = lerp(1200.0, 2150.0, vowel)
	var formants = _bandpass(source, f1, 5.5) * 0.62 + _bandpass(source, f2, 7.8) * 0.38
	
	# Extra EQ-like emphasis similar to moving twin peaks.
	var peaks = _bandpass(source, f1 * 1.18, 9.5) * 0.16 + _bandpass(source, f2 * 0.92, 9.5) * 0.14
	var filtered = source * 0.26 + formants * 0.66 + peaks
	
	var output = tanh(filtered * DRIVE)
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func _unison_saw(t: float, freq: float) -> float:
	var detune_ratio = pow(2.0, DETUNE_CENTS / 1200.0)
	var output = 0.0
	for i in range(UNISON_VOICES):
		var spread = float(i) - float(UNISON_VOICES - 1) * 0.5
		var voice_freq = freq * pow(detune_ratio, spread)
		var saw = fmod(voice_freq * t, 1.0) * 2.0 - 1.0
		output += saw
	return output / float(UNISON_VOICES)


static func _bandpass(input: float, center_hz: float, q: float) -> float:
	var bw = center_hz / maxf(q, 0.1)
	var alpha = bw / (bw + SAMPLE_RATE / TAU)
	return input * alpha * q * 0.3


static func _wub_lfo(dt: float) -> float:
	var phase = fmod(dt * WUB_RATE_HZ, 1.0)
	if phase < 0.5:
		return pow(phase / 0.5, 0.62)
	var fall = 1.0 - ((phase - 0.5) / 0.5)
	return pow(maxf(fall, 0.0), 2.0)


static func _envelope(dt: float) -> float:
	if dt < ATTACK_S:
		return dt / ATTACK_S
	if dt < GATE_S:
		return 1.0
	return exp(-(dt - GATE_S) / RELEASE_S)


static func get_duration() -> float:
	return 1.2
