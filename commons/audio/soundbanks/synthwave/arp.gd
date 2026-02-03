# Synthwave Arp - Juno-60 Style Arpeggio
# Research: synthwave.md
#
# Character: Shimmering chorused arpeggio, quintessential 80s sound
# Source: Roland Juno-60/106 with BBD chorus
#
# FROM RESEARCH:
# "Arpeggio (Juno-60 Style): 4-voice unison, 12 cent detune"
# "Bright filter (3000Hz), low resonance (0.3)"
# "Fast attack (0.001s), short decay (0.2s), moderate sustain (0.5)"
# "Chorus (0.4 depth) - essential for Juno sound"
# "Delay: 0.375s (dotted eighth), 25% mix"

class_name SynthwaveArp
extends RefCounted

const SAMPLE_RATE = 44100.0

# Juno arp parameters
const VOICES = 4
const DETUNE_CENTS = 12.0         # Moderate detune
const CUTOFF_HZ = 3000.0          # Bright
const ATTACK_S = 0.001            # Instant attack
const DECAY_S = 0.2               # Short decay
const SUSTAIN = 0.5               # Medium sustain
const CHORUS_RATE_HZ = 0.5        # Juno chorus LFO
const CHORUS_DEPTH = 0.004        # Chorus amount (pitch modulation)
const LEVEL = 0.2


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.8:
		return 0.0
	
	# Envelope
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		env = 1.0 - (1.0 - SUSTAIN) * (dt - ATTACK_S) / DECAY_S
	else:
		env = SUSTAIN * exp(-(dt - ATTACK_S - DECAY_S) * 3.0)  # Fade out
	
	# Juno BBD chorus - pitch modulation
	var chorus_mod = sin(2.0 * PI * CHORUS_RATE_HZ * t) * CHORUS_DEPTH
	
	var output = 0.0
	
	# 4-voice detuned
	for i in range(VOICES):
		var detune = (float(i) - 1.5) * DETUNE_CENTS / 1200.0
		var voice_freq = freq * pow(2.0, detune) * (1.0 + chorus_mod)
		var saw = fmod(t * voice_freq, 1.0) * 2.0 - 1.0
		output += saw
	
	output /= VOICES
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.8
