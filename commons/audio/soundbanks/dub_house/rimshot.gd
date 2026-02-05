# Dub House Rimshot - The quintessential dub techno accent
#
# Character: Tight, clicky, minimal - the anti-snare
# Source: 808/909 rimshot with tape warmth
# Processing: Clean attack, no reverb (let the delay do the work)
# Reference: Basic Channel "Phylyps Trak", Maurizio "M-4"
#
# In dub house, the rimshot is THE percussive accent:
# - Tight and clicky (not boomy like a snare)
# - Sparse placement (every 2-4 bars)
# - The delay/echo creates the rhythm, not the hit itself

class_name DubHouseRimshot
extends RefCounted

const SAMPLE_RATE = 44100.0

# 808-style rimshot synthesis
const BODY_HZ = 340.0          # Higher pitch than snare - more "stick" character
const BODY_DECAY_S = 0.015     # VERY short - just a click
const CLICK_HZ = 1800.0        # High-frequency click transient
const CLICK_DECAY_S = 0.003    # Ultra-short click
const CLICK_LEVEL = 0.7        # Click dominant over body
const BODY_LEVEL = 0.3         # Body is subtle
const LEVEL = 0.28             # Moderate - cuts through but doesn't dominate


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.08:  # Very short sound - the space after is part of the sound
		return 0.0
	
	# Stick-on-rim body tone
	var body = sin(2.0 * PI * BODY_HZ * dt) * exp(-dt / BODY_DECAY_S) * BODY_LEVEL
	
	# Sharp click transient (the "tick" character)
	var click = sin(2.0 * PI * CLICK_HZ * dt) * exp(-dt / CLICK_DECAY_S) * CLICK_LEVEL
	
	# Small amount of high-frequency noise for texture
	var noise = (randf() * 2.0 - 1.0) * exp(-dt / 0.002) * 0.15
	
	var output = body + click + noise
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.08
