# Dub House Stab - Filtered chord with tape-delay tail
#
# Character: Offbeat dub chord, warm and spacious
# Source: Detuned saws + pulse through lowpass
# Processing: Pseudo tape delay (fixed taps)

class_name DubHouseStab
extends RefCounted

const SAMPLE_RATE = 44100.0

const DETUNE_CENTS = 7.0
const ATTACK_S = 0.004
const DECAY_S = 0.18
const SUSTAIN = 0.2
const RELEASE_S = 0.35

const DELAY_TAP_S = 0.12
const DELAY_TAP2_S = 0.24
const DELAY_FEEDBACK = 0.35

const DRIVE = 1.2
const LEVEL = 0.28


static func generate(t: float, chord_freqs: Array, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 1.0:
		return 0.0
	
	var env = _get_envelope(dt)
	if env <= 0.0:
		return 0.0
	
	var dry = _chord_source(t, chord_freqs) * env
	var wet = 0.0
	
	if dt > DELAY_TAP_S:
		var echo_env = exp(-(dt - DELAY_TAP_S) / 0.35)
		wet += _chord_source(t - DELAY_TAP_S, chord_freqs) * echo_env * DELAY_FEEDBACK
	if dt > DELAY_TAP2_S:
		var echo_env2 = exp(-(dt - DELAY_TAP2_S) / 0.35)
		wet += _chord_source(t - DELAY_TAP2_S, chord_freqs) * echo_env2 * (DELAY_FEEDBACK * 0.6)
	
	var output = (dry + wet) * DRIVE
	output = tanh(output)
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func _chord_source(t: float, chord_freqs: Array) -> float:
	if chord_freqs.is_empty():
		return 0.0
	
	var detune_ratio = pow(2.0, DETUNE_CENTS / 1200.0)
	var output = 0.0
	
	for freq in chord_freqs:
		var saw1 = fmod(t * freq * detune_ratio, 1.0) * 2.0 - 1.0
		var saw2 = fmod(t * freq / detune_ratio, 1.0) * 2.0 - 1.0
		var pulse = 1.0 if fmod(t * freq, 1.0) < 0.45 else -1.0
		var sine = sin(2.0 * PI * freq * t)
		
		output += (saw1 + saw2) * 0.35 + pulse * 0.1 + sine * 0.35
	
	output /= chord_freqs.size()
	return output


static func _get_envelope(dt: float) -> float:
	var env = 1.0
	
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		var decay_progress = (dt - ATTACK_S) / DECAY_S
		env = 1.0 - (1.0 - SUSTAIN) * decay_progress
	else:
		env = SUSTAIN * exp(-(dt - ATTACK_S - DECAY_S) / RELEASE_S)
	
	return maxf(env, 0.0)


static func get_duration() -> float:
	return 1.0
