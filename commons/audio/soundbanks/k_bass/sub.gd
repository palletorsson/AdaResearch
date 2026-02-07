# K-Bass Sub - Reese Bass as Lead Instrument
# Reference: K-Bass philosophy - sub IS the hook
#
# Character: Physical pressure, weighted, detuned saws into lowpass
# Source: Reese bass tradition (Kevin Saunderson lineage)
#
# THE SUB IS THE LEAD INSTRUMENT — not melody, not harmony — PRESSURE

class_name KBassSub
extends RefCounted

const SAMPLE_RATE = 44100.0

# Reese character - detuned saws
const VOICES = 2
const DETUNE_CENTS = 15.0         # Reese detune (not as extreme as hoover)
const FILTER_CUTOFF_HZ = 150.0    # Sub-focused
const FILTER_LFO_RATE = 0.5       # Slow modulation for movement
const FILTER_LFO_DEPTH = 70.0     # Hz of modulation
const ATTACK_S = 0.02
const RELEASE_S = 0.15
const SUB_FUNDAMENTAL = 40.0      # Physical pressure at 40Hz
const SATURATION = 1.3            # Harmonic content
const LEVEL = 0.5


static func generate(t: float, freq: float, note_duration: float = 1.0, note_time: float = 0.0) -> float:
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
	
	# Filter LFO for slow movement
	var filter_mod = sin(2.0 * PI * FILTER_LFO_RATE * t) * FILTER_LFO_DEPTH
	var current_cutoff = FILTER_CUTOFF_HZ + filter_mod
	
	var output = 0.0
	
	# Detuned saw voices
	for i in range(VOICES):
		var detune = (float(i) - 0.5) * DETUNE_CENTS / 1200.0
		var voice_freq = freq * pow(2.0, detune)
		var saw = fmod(t * voice_freq, 1.0) * 2.0 - 1.0
		output += saw
	
	output /= VOICES
	
	# Add pure sub fundamental for physical weight
	var sub_sine = sin(2.0 * PI * SUB_FUNDAMENTAL * t) * 0.4
	output += sub_sine
	
	# Simple lowpass approximation (single pole)
	# In reality would use proper filter, but this adds character
	var filter_amt = current_cutoff / (current_cutoff + 500.0)
	output *= filter_amt
	
	# Saturation for harmonics (heard on mids, not sub)
	output = tanh(output * SATURATION)
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 10.0, 0.0)


static func get_duration() -> float:
	return 2.0  # Long sustain possible
