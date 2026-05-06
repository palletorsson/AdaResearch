# Akayo Recreation - Wub Synth
# Character: Detuned saw wub with LFO-shaped amplitude and mild grit
# Source: "How To Create ANY Sound from ANY Song" chapter "Wub synth"
# Processing: Unison saw core, LFO amp shape ("wow"), slight distortion, sub support

class_name AkayoWubSynth
extends RefCounted

const SAMPLE_RATE = 44100.0

const UNISON_VOICES = 3
const DETUNE_CENTS = 13.0
const WUB_RATE_HZ = 2.2
const ATTACK_S = 0.004
const RELEASE_S = 0.22
const GATE_S = 0.72
const DRIVE = 1.75
const LEVEL = 0.30


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 1.2:
		return 0.0
	
	var env = _envelope(dt)
	if env <= 0.0:
		return 0.0
	
	var wub = _wub_lfo(dt)
	var saw_core = _unison_saw(t, freq)
	var sub = sin(TAU * freq * 0.5 * t) * 0.22
	
	var body = saw_core * (0.32 + wub * 0.68) + sub
	var output = tanh(body * DRIVE)
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


static func _wub_lfo(dt: float) -> float:
	var phase = fmod(dt * WUB_RATE_HZ, 1.0)
	if phase < 0.52:
		return pow(phase / 0.52, 0.58)
	var fall = 1.0 - ((phase - 0.52) / 0.48)
	return pow(maxf(fall, 0.0), 2.3)


static func _envelope(dt: float) -> float:
	if dt < ATTACK_S:
		return dt / ATTACK_S
	if dt < GATE_S:
		return 1.0
	return exp(-(dt - GATE_S) / RELEASE_S)


static func get_duration() -> float:
	return 1.2
