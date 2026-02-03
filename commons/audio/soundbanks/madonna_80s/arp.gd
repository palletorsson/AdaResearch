# Madonna 80s Arp - Sequenced Synth Arpeggio
#
# Character: Bright, bubbly, driving
# Source: Sequential Circuits / Oberheim

class_name MadonnaArp
extends RefCounted

const SAMPLE_RATE = 44100.0

const ATTACK_S = 0.003
const DECAY_S = 0.1
const SUSTAIN = 0.4
const DETUNE_CENTS = 5.0
const LEVEL = 0.18


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.5:
		return 0.0
	
	# Bubbly envelope
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		env = 1.0 - (1.0 - SUSTAIN) * (dt - ATTACK_S) / DECAY_S
	else:
		env = SUSTAIN * exp(-(dt - ATTACK_S - DECAY_S) * 4.0)
	
	# Bright saw
	var detune = pow(2.0, DETUNE_CENTS / 1200.0)
	var saw1 = fmod(t * freq * detune, 1.0) * 2.0 - 1.0
	var saw2 = fmod(t * freq / detune, 1.0) * 2.0 - 1.0
	
	var output = (saw1 + saw2) * 0.5
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.5
