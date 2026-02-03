# Detroit Techno Bass - 808 Sub Style
# Research: detroit_techno.md
#
# Character: Sub-heavy, clean, controlled
# Source: TR-808 bass drum circuit adapted for bass
# Processing: CLEAN - no distortion, +3dB sub boost
#
# FROM RESEARCH:
# "808 sub bass: cutoff 150Hz, attack 0.001s, decay 0.3s, sustain 0.5"
# "Sub level boosted +3dB"

class_name DetroitBass
extends RefCounted

const SAMPLE_RATE = 44100.0

# 808 Bass Parameters (from research)
const CUTOFF_HZ = 150.0           # Very low cutoff - mostly sub
const ATTACK_S = 0.001            # Fast attack
const DECAY_S = 0.3               # Moderate decay
const SUSTAIN = 0.5               # Medium sustain
const SUB_BOOST_DB = 3.0          # +3dB sub boost
const SQUARE_MIX = 0.25           # Square wave adds harmonics above cutoff
const SINE_MIX = 0.75             # Mostly sine for sub
const LEVEL = 0.5

# Precompute sub boost as linear
const SUB_BOOST = 1.412           # ~+3dB


static func generate(t: float, freq: float, note_duration: float = 1.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# ADSR envelope
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		var decay_progress = (dt - ATTACK_S) / DECAY_S
		env = 1.0 - (1.0 - SUSTAIN) * decay_progress
	else:
		env = SUSTAIN
		# Release at end of note
		var release_start = note_duration - 0.1
		if dt > release_start:
			env = SUSTAIN * (1.0 - (dt - release_start) / 0.1)
	
	env = maxf(env, 0.0)
	
	# Oscillators
	# Sub sine (808 character)
	var sub = sin(2.0 * PI * freq * t) * SINE_MIX
	
	# Square for slight harmonics (still filtered low)
	var square = sign(sin(2.0 * PI * freq * t)) * SQUARE_MIX
	
	# Simple lowpass simulation (808 is very filtered)
	# Just reduce square wave contribution for low cutoff effect
	var cutoff_factor = minf(CUTOFF_HZ / freq, 1.0)
	square *= cutoff_factor * 0.5  # Heavily filtered
	
	var output = (sub * SUB_BOOST + square) * env * LEVEL
	
	# NO distortion, NO saturation - Detroit is CLEAN
	return clampf(output, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	# Simplified version for continuous playback
	return generate(t, freq, 10.0, 0.0)
