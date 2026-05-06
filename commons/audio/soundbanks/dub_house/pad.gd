# Dub House Pad - Warm, slow, spacious
#
# Character: Slow-moving pad that supports the dub chord
# Source: Detuned saws + triangle, low brightness
# Processing: Gentle movement, long release

class_name DubHousePad
extends RefCounted

const SAMPLE_RATE = 44100.0

const VOICES = 3
const DETUNE_CENTS = 9.0
const ATTACK_S = 1.2
const DECAY_S = 0.8
const SUSTAIN = 0.7
const RELEASE_S = 1.5
const LFO_RATE = 0.08
const LEVEL = 0.2


static func generate(t: float, chord_freqs: Array, note_duration: float = 4.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	var env = _get_envelope(dt, note_duration)
	if env <= 0.0:
		return 0.0
	
	var output = 0.0
	var detune_ratio = pow(2.0, DETUNE_CENTS / 1200.0)
	var lfo = sin(2.0 * PI * LFO_RATE * t) * 0.003
	
	for freq in chord_freqs:
		for v in range(VOICES):
			var f1 = freq * (1.0 + lfo)
			var f2 = freq * detune_ratio * (1.0 - lfo)
			var f3 = freq / detune_ratio
			
			var saw1 = fmod(t * f1 + float(v) * 0.1, 1.0) * 2.0 - 1.0
			var saw2 = fmod(t * f2 + float(v) * 0.13, 1.0) * 2.0 - 1.0
			var tri = 2.0 * abs(2.0 * fmod(t * f3, 1.0) - 1.0) - 1.0
			
			output += saw1 * 0.45 + saw2 * 0.35 + tri * 0.25
	
	output /= chord_freqs.size() * VOICES
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func _get_envelope(dt: float, note_duration: float) -> float:
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		var decay_progress = (dt - ATTACK_S) / DECAY_S
		env = 1.0 - (1.0 - SUSTAIN) * decay_progress
	elif dt < note_duration:
		env = SUSTAIN
	else:
		var release_time = dt - note_duration
		env = SUSTAIN * (1.0 - minf(release_time / RELEASE_S, 1.0))
	
	return maxf(env, 0.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 10.0, 0.0)
