# Detroit Techno Snare - TR-909 Style
# Research: detroit_techno_deep_research.md
#
# Character: Snappy, metallic, ring-mod character, NO reverb
# Source: TR-909 hybrid circuit - TWO bridged-T oscillators
# Processing: CLEAN - "+2dB high shelf for brightness"
#
# DEEP RESEARCH NOTES:
# The 909 snare uses TWO tone oscillators at 180Hz and 330Hz
# These interact to create the distinctive "ring-mod" character
# Noise is digital 6-bit LFSR through analog envelope
# Bandpass filtered around 5-8kHz for crisp wire sound

class_name DetroitSnare
extends RefCounted

const SAMPLE_RATE = 44100.0

# 909 Snare Parameters (from deep research - TR-909 service manual analysis)
# Two bridged-T oscillators create the distinctive ring-mod tone
const BODY_FREQ_1_HZ = 180.0      # First tone oscillator
const BODY_FREQ_2_HZ = 330.0      # Second tone oscillator (ring-mod interaction)
const BODY_DECAY_S = 0.040        # Tone decay (30-50ms measured)
const NOISE_BANDPASS_HZ = 6500.0  # Noise filtered around 5-8kHz
const NOISE_DECAY_S = 0.050       # Noise tail (40-60ms for snappy setting)
const NOISE_LEVEL = 0.55          # Noise vs body balance
const BODY_LEVEL = 0.45           # Body level
const LEVEL = 0.35                # Output level (+2dB implied via mix)


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.3:
		return 0.0
	
	# Body - TWO pitched components that interact (909 ring-mod character)
	var tone1 = sin(2.0 * PI * BODY_FREQ_1_HZ * dt)
	var tone2 = sin(2.0 * PI * BODY_FREQ_2_HZ * dt)
	# Mix creates the metallic "ring" of the 909
	var body = (tone1 * 0.6 + tone2 * 0.4) + (tone1 * tone2 * 0.2)  # Subtle ring-mod
	var body_env = exp(-dt / BODY_DECAY_S)
	body *= body_env * BODY_LEVEL
	
	# Noise - snare wires (bandpass filtered character)
	# 909 uses 6-bit digital noise, giving it slight graininess
	var noise = randf() * 2.0 - 1.0
	# Simulate bandpass by mixing with high-frequency sine for brightness
	noise += sin(2.0 * PI * NOISE_BANDPASS_HZ * dt) * (randf() * 0.3)
	var noise_env = exp(-dt / NOISE_DECAY_S)
	noise *= noise_env * NOISE_LEVEL
	
	# Combine - NO reverb, NO processing (Detroit is DRY)
	var output = (body + noise) * LEVEL
	
	return clampf(output, -1.0, 1.0)


static func get_duration() -> float:
	return 0.3
