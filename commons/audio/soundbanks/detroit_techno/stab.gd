# Detroit Techno Chord Stab
# Research: detroit_techno_deep_research.md
#
# Character: Short, punchy, percussive, METALLIC chord hits
# Source: Yamaha DX7 FM synthesis (Algorithm 5)
# Processing: Light reverb only
#
# DEEP RESEARCH NOTES (DX7 "Strings of Life" style):
# The Detroit stab uses FM synthesis for its cold, metallic character
# Algorithm 5: Parallel carriers with shared modulator
# Key: The modulator creates inharmonic sidebands = bell-like, metallic
# Attack: <10ms, Decay: 50-100ms, Sustain: 0 (purely percussive)
# The modulator ratio of 3.00 with feedback creates the "bite"

class_name DetroitStab
extends RefCounted

const SAMPLE_RATE = 44100.0

# FM Stab Parameters (from deep research - DX7 algorithm analysis)
# Modeled on classic Detroit DX7 patches
const MOD_RATIO = 3.0             # Modulator frequency ratio (creates metallic sidebands)
const MOD_INDEX = 2.5             # FM modulation depth (higher = more metallic)
const MOD_FEEDBACK = 0.15         # Self-modulation for "bite"
const ATTACK_S = 0.003            # Very fast attack (<10ms)
const DECAY_S = 0.070             # Short decay (50-100ms)
const SUSTAIN = 0.0               # ZERO sustain - purely percussive
const REVERB_TAIL_S = 0.12        # Light reverb tail
const REVERB_MIX = 0.15           # 15% reverb (Detroit is dry)
const LEVEL = 0.28


static func generate(t: float, chord_freqs: Array, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.4:
		return 0.0
	
	# Very fast envelope - attack to decay only (no sustain)
	var env = 0.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		var decay_progress = (dt - ATTACK_S) / DECAY_S
		env = 1.0 - decay_progress  # Linear decay to zero
	else:
		env = 0.0
	
	# Modulation envelope (decays faster than carrier for DX7 character)
	var mod_env = exp(-dt / (DECAY_S * 0.5))
	
	var output = 0.0
	
	for freq in chord_freqs:
		# FM Synthesis (DX7 Algorithm 5 simplified)
		# Modulator with feedback
		var mod_freq = freq * MOD_RATIO
		var modulator = sin(2.0 * PI * mod_freq * t)
		# Add feedback (self-modulation for metallic bite)
		modulator += sin(2.0 * PI * mod_freq * t + modulator * MOD_FEEDBACK)
		modulator *= 0.5  # Normalize after feedback
		
		# Carrier modulated by modulator (FM)
		var mod_amount = MOD_INDEX * mod_env  # Mod depth decreases over time
		var carrier = sin(2.0 * PI * freq * t + modulator * mod_amount)
		
		# Add second carrier at octave (DX7 character - fuller sound)
		var carrier2 = sin(2.0 * PI * freq * 2.0 * t + modulator * mod_amount * 0.5)
		
		output += carrier * 0.7 + carrier2 * 0.3
	
	output /= chord_freqs.size()
	
	# Main stab
	var stab = output * env
	
	# Light reverb tail (simulated - Detroit is mostly dry)
	var reverb = 0.0
	if dt > ATTACK_S + DECAY_S * 0.5:
		var rev_time = dt - (ATTACK_S + DECAY_S * 0.5)
		reverb = output * exp(-rev_time / REVERB_TAIL_S) * REVERB_MIX * 0.3
	
	return clampf((stab + reverb) * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.4
