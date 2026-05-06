# Detroit Techno Arpeggio Sequence
# Research: detroit_techno brief.json
#
# Character: Cold, precise, mechanical FM arpeggio
# Source: DX7-style FM synthesis, Yamaha digital character
# Processing: CLEAN - no drift, no humanization
#
# FROM RESEARCH:
# "Sequencer Lines: FM synthesis, attack <10ms, decay 50-100ms"
# "ZERO humanization - Detroit techno is machine-perfect"
# "Digital precision, stable pitch, cold character"
# "Afrofuturist machine funk - technology as liberation"

class_name DetroitSequence
extends RefCounted

const SAMPLE_RATE = 44100.0

# FM Sequence Parameters (DX7-style digital character)
const MOD_RATIO = 2.0             # Modulator frequency ratio
const MOD_INDEX = 1.8             # FM modulation depth (creates metallic shimmer)
const ATTACK_S = 0.005            # Very fast attack (<10ms)
const DECAY_S = 0.065             # Short decay (Detroit is percussive)
const SUSTAIN = 0.0               # Zero sustain - purely rhythmic
const RELEASE_S = 0.08            # Short release
const LEVEL = 0.22


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.25:
		return 0.0

	# Fast percussive envelope - attack + decay only
	var env = 0.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		var decay_progress = (dt - ATTACK_S) / DECAY_S
		env = 1.0 - decay_progress
	else:
		var release_time = dt - (ATTACK_S + DECAY_S)
		env = maxf(0.0, 1.0 - release_time / RELEASE_S) * 0.1

	# FM modulator envelope (decays faster for DX7 character)
	var mod_env = exp(-dt / (DECAY_S * 0.4))

	# FM Synthesis - clean digital character
	var mod_freq = freq * MOD_RATIO
	var modulator = sin(TAU * mod_freq * t)

	# Carrier with FM modulation
	var mod_amount = MOD_INDEX * mod_env
	var carrier = sin(TAU * freq * t + modulator * mod_amount)

	# Add slight octave harmonic for brightness (Detroit shimmer)
	var carrier_oct = sin(TAU * freq * 2.0 * t + modulator * mod_amount * 0.5)

	var output = carrier * 0.75 + carrier_oct * 0.25

	# NO processing - Detroit is clean and digital
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_chord(t: float, chord_freqs: Array, trigger_time: float = 0.0) -> float:
	var output = 0.0
	for freq in chord_freqs:
		output += generate(t, freq, trigger_time)
	return clampf(output / maxf(1.0, chord_freqs.size()), -1.0, 1.0)


static func get_duration() -> float:
	return 0.25
