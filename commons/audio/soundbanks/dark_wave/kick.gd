# Dark Wave Kick - Post-Punk Tight Punch
# Research: dark_wave brief
#
# Character: Tight, punchy, dry. More post-punk than electronic.
#   Think Joy Division / Bauhaus - a REAL kick, not a synth kick.
#   Short, defined, sits in the mix without dominating the low end.
# Source: Acoustic drum emulation with slight compression character.
#   Closer to a LinnDrum or Simmons SDS-V than a TR-808/909.
# Processing: Minimal reverb, tight envelope, slight saturation for presence
#
# Key specs:
#   Pitch start: 120 Hz (not too high — no clicky techno transient)
#   Pitch end: 55 Hz (above sub territory — has body, not boom)
#   Pitch decay: 25ms (fast drop, defined pitch)
#   Body decay: 90ms (SHORT — this is not a boomy kick)
#   Click transient: brief noise burst, 2ms
#   Overall level: moderate — kick serves the groove, bass owns the low end

class_name DarkWaveKick
extends RefCounted

const SAMPLE_RATE = 44100.0

# Post-punk kick — tight and punchy
const PITCH_START_HZ = 120.0      # Medium attack pitch
const PITCH_END_HZ = 55.0         # Body, not sub
const PITCH_DECAY_S = 0.025       # Fast pitch sweep
const BODY_DECAY_S = 0.09         # Short body — tight, not boomy
const CLICK_DECAY_S = 0.002       # Very brief transient click
const CLICK_LEVEL = 0.3           # Subtle click for definition
const LEVEL = 0.4


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.25:
		return 0.0
	
	# Pitch envelope — fast drop from 120 to 55 Hz
	var pitch_env = exp(-dt / PITCH_DECAY_S)
	var freq = PITCH_END_HZ + (PITCH_START_HZ - PITCH_END_HZ) * pitch_env
	
	# Body — sine wave with exponential decay
	var body = sin(2.0 * PI * freq * dt) * exp(-dt / BODY_DECAY_S)
	
	# Click transient — brief filtered noise for attack definition
	var click = (sin(2.0 * PI * 3500.0 * dt) * 0.5 + sin(2.0 * PI * 1800.0 * dt) * 0.5)
	click *= exp(-dt / CLICK_DECAY_S) * CLICK_LEVEL
	
	# Slight saturation for analog character
	var output = body + click
	output = tanh(output * 1.3)
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.25
