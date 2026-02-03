# Madonna 80s Snare - Gated Pop Snare
#
# Character: BIG but tighter than rock, gated reverb
# Source: LinnDrum with gated room
# Processing: Punchy with controlled verb

class_name MadonnaSnare
extends RefCounted

const SAMPLE_RATE = 44100.0

const BODY_FREQ_HZ = 200.0
const BODY_DECAY_S = 0.03
const NOISE_DECAY_S = 0.04
const GATE_LENGTH_S = 0.12        # Tighter gate than synthwave
const REVERB_MIX = 0.4            # Less reverb than synthwave
const LEVEL = 0.38


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.3:
		return 0.0
	
	# Dry snare
	var body = sin(2.0 * PI * BODY_FREQ_HZ * dt) * exp(-dt / BODY_DECAY_S) * 0.4
	var noise = (randf() * 2.0 - 1.0) * exp(-dt / NOISE_DECAY_S) * 0.5
	var dry = body + noise
	
	# Gated reverb (tighter than synthwave)
	var reverb = 0.0
	if dt < GATE_LENGTH_S:
		var rev_env = (1.0 - exp(-dt * 20.0)) * (1.0 - dt / GATE_LENGTH_S)
		reverb = (randf() * 2.0 - 1.0) * rev_env * REVERB_MIX
	
	return clampf((dry + reverb) * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.3
