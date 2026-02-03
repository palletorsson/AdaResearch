# Synthwave Kick - LinnDrum Style
# Research: synthwave.md
#
# Character: Punchy electronic with click transient, works with gated reverb
# Source: LinnDrum (8-bit samples) / TR-707
# Processing: Clean with slight punch

class_name SynthwaveKick
extends RefCounted

const SAMPLE_RATE = 44100.0

# LinnDrum-style kick parameters
const PITCH_START_HZ = 110.0      # Higher start for click
const PITCH_END_HZ = 60.0         # 80s kick fundamental
const PITCH_DECAY_S = 0.03        # Medium pitch envelope
const BODY_DECAY_S = 0.15         # Longer body for 80s feel
const CLICK_FREQ_HZ = 2500.0      # Click transient
const CLICK_DECAY_S = 0.004       # Short click
const CLICK_LEVEL = 0.15          # Noticeable click
const LEVEL = 0.5


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.5:
		return 0.0
	
	# Pitch envelope
	var pitch_env = exp(-dt / PITCH_DECAY_S)
	var freq = PITCH_END_HZ + (PITCH_START_HZ - PITCH_END_HZ) * pitch_env
	
	# Body
	var body = sin(2.0 * PI * freq * dt) * exp(-dt / BODY_DECAY_S)
	
	# Click transient (LinnDrum character)
	var click = sin(2.0 * PI * CLICK_FREQ_HZ * dt) * exp(-dt / CLICK_DECAY_S) * CLICK_LEVEL
	
	return clampf((body + click) * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.5
