# Madonna 80s Kick - LinnDrum Pop Style
#
# Character: Punchy, tight, clean pop kick
# Source: LinnDrum LM-1/LM-2 (8-bit samples)
# Processing: Tight, punchy, room for bass

class_name MadonnaKick
extends RefCounted

const SAMPLE_RATE = 44100.0

# LinnDrum pop kick - punchy, not too sub-heavy
const PITCH_START_HZ = 120.0
const PITCH_END_HZ = 55.0
const PITCH_DECAY_S = 0.025
const BODY_DECAY_S = 0.1          # Tighter than rock
const CLICK_FREQ_HZ = 3500.0      # Pop click
const CLICK_DECAY_S = 0.003
const CLICK_LEVEL = 0.12
const LEVEL = 0.5


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.35:
		return 0.0
	
	var pitch_env = exp(-dt / PITCH_DECAY_S)
	var freq = PITCH_END_HZ + (PITCH_START_HZ - PITCH_END_HZ) * pitch_env
	
	var body = sin(2.0 * PI * freq * dt) * exp(-dt / BODY_DECAY_S)
	var click = sin(2.0 * PI * CLICK_FREQ_HZ * dt) * exp(-dt / CLICK_DECAY_S) * CLICK_LEVEL
	
	return clampf((body + click) * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.35
