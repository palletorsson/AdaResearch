# Detroit Techno Kick - TR-909 Style
# Research: detroit_techno.md
#
# Character: Punchy, fast attack (faster than 808), sub-heavy but controlled
# Source: TR-909 hybrid analog/digital circuit
# Processing: CLEAN - no distortion, no saturation

class_name DetroitKick
extends RefCounted

const SAMPLE_RATE = 44100.0

# 909 Kick Parameters (from research)
# "Punchy kick (faster attack than 808)"
# "High shelf boost +2dB for brightness"
const PITCH_START_HZ = 130.0      # Starting pitch (higher than 808)
const PITCH_END_HZ = 50.0         # Ending pitch (sub)
const PITCH_DECAY_S = 0.025       # Fast pitch drop (909 is snappier than 808)
const BODY_DECAY_S = 0.12         # Body envelope
const CLICK_LEVEL = 0.08          # 909 has slight click transient
const CLICK_FREQ_HZ = 4000.0      # Click frequency
const CLICK_DECAY_S = 0.003       # Very fast click decay
const LEVEL = 0.55                # Output level (+2dB brightness)


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.5:
		return 0.0
	
	# Pitch envelope - fast exponential drop
	var pitch_env = exp(-dt / PITCH_DECAY_S)
	var freq = PITCH_END_HZ + (PITCH_START_HZ - PITCH_END_HZ) * pitch_env
	
	# Body - sine wave with pitch envelope
	var phase = 2.0 * PI * freq * dt
	var body = sin(phase)
	
	# Amplitude envelope
	var amp_env = exp(-dt / BODY_DECAY_S)
	body *= amp_env
	
	# 909 click transient (subtle)
	var click = sin(2.0 * PI * CLICK_FREQ_HZ * dt) * exp(-dt / CLICK_DECAY_S) * CLICK_LEVEL
	
	# Combine - NO distortion, NO saturation (Detroit is CLEAN)
	var output = (body + click) * LEVEL
	
	return clampf(output, -1.0, 1.0)


static func get_duration() -> float:
	return 0.5
