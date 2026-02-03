# Detroit Techno Chord Stab
# Research: detroit_techno.md
#
# Character: Short, punchy, percussive chord hits
# Source: Yamaha DX7 / Juno-106 style
# Processing: Light reverb only
#
# FROM RESEARCH:
# "Chord stab: filter 2000Hz, resonance 0.5"
# "Very fast attack (0.001s), very short decay (0.08s)"
# "ZERO sustain - purely percussive"
# "Light reverb (0.2)"

class_name DetroitStab
extends RefCounted

const SAMPLE_RATE = 44100.0

# Chord Stab Parameters (from research)
const CUTOFF_HZ = 2000.0          # Mid-range filter
const RESONANCE = 0.5             # Moderate resonance for bite
const ATTACK_S = 0.001            # Instant attack
const DECAY_S = 0.08              # Very short decay
const SUSTAIN = 0.0               # ZERO sustain - purely percussive
const REVERB_TAIL_S = 0.15        # Light reverb tail
const REVERB_MIX = 0.2            # 20% reverb
const LEVEL = 0.30


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
		env = 1.0 - decay_progress  # Decay to zero
	else:
		env = 0.0
	
	var output = 0.0
	
	for freq in chord_freqs:
		# Bright saw for stab character
		var saw = fmod(t * freq, 1.0) * 2.0 - 1.0
		
		# Add slight resonance peak simulation
		var res_freq = CUTOFF_HZ
		var resonance = sin(2.0 * PI * res_freq * t) * RESONANCE * 0.1
		
		output += saw + resonance
	
	output /= chord_freqs.size()
	
	# Main stab
	var stab = output * env
	
	# Light reverb tail (simulated)
	var reverb = 0.0
	if dt > ATTACK_S + DECAY_S * 0.5:
		var rev_time = dt - (ATTACK_S + DECAY_S * 0.5)
		reverb = output * exp(-rev_time / REVERB_TAIL_S) * REVERB_MIX * 0.3
	
	return clampf((stab + reverb) * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.4
