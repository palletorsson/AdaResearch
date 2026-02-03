# Synthwave Snare - Gated Reverb Style
# Research: synthwave.md
#
# Character: BIG 80s snare with gated reverb (Phil Collins / Power Station)
# Source: LinnDrum with heavy gated reverb processing
# Processing: Reverb with hard gate at ~150ms
#
# FROM RESEARCH:
# "Heavy reverb (0.6 mix), reverb decay 1.5s (longer than normal, then gated)"
# "Gated reverb style: reverb cut short"

class_name SynthwaveSnare
extends RefCounted

const SAMPLE_RATE = 44100.0

# Gated reverb snare parameters
const BODY_FREQ_HZ = 200.0        # Snare body
const BODY_DECAY_S = 0.03         # Fast initial decay
const NOISE_DECAY_S = 0.04        # Noise envelope
const GATE_LENGTH_S = 0.15        # Gate cuts reverb here
const REVERB_DECAY_S = 0.08       # Reverb decay before gate
const REVERB_MIX = 0.6            # 60% reverb (BIG)
const LEVEL = 0.35


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.4:
		return 0.0
	
	# Dry snare
	var body = sin(2.0 * PI * BODY_FREQ_HZ * dt) * exp(-dt / BODY_DECAY_S) * 0.4
	var noise = (randf() * 2.0 - 1.0) * exp(-dt / NOISE_DECAY_S) * 0.5
	var dry = body + noise
	
	# Gated reverb - builds up then cuts hard
	var reverb = 0.0
	if dt < GATE_LENGTH_S:
		# Reverb builds then stays
		var rev_env = (1.0 - exp(-dt * 15.0)) * (1.0 - dt / GATE_LENGTH_S)
		reverb = (randf() * 2.0 - 1.0) * rev_env * REVERB_MIX
	# After gate: hard cut (reverb = 0)
	
	return clampf((dry + reverb) * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.4
