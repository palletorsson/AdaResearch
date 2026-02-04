# cr5000_kick.gd
# Roland CR-5000 CompuRhythm kick drum
# Character: Punchy, tight, analog but preset-based
# Source: Roland CR-5000 (1980)
# Processing: Minimal - fairly dry

# Technical anatomy:
# - Analog synthesis but preset sounds
# - Tighter than 808, less boomy
# - Good punch, medium decay
# - Sits well in mix without dominating

class_name CR5000Kick
extends RefCounted

const SAMPLE_RATE = 44100.0

# CR-5000 kick parameters
const PITCH_START_HZ = 120.0
const PITCH_END_HZ = 45.0
const PITCH_DECAY_MS = 25.0
const AMP_DECAY_MS = 180.0
const CLICK_LEVEL = 0.25
const CLICK_FREQ_HZ = 2500.0
const CLICK_DECAY_MS = 3.0


static func generate(t: float, freq: float = 0.0, params: Dictionary = {}) -> float:
	var tune = params.get("tune", 1.0)  # 0.8 - 1.2 range
	var decay = params.get("decay", AMP_DECAY_MS) / 1000.0
	var punch = params.get("punch", 0.6)
	
	# Pitch envelope (fast drop)
	var pitch_env = exp(-t / (PITCH_DECAY_MS / 1000.0))
	var current_freq = PITCH_END_HZ * tune + (PITCH_START_HZ - PITCH_END_HZ) * pitch_env
	
	# Body (sine wave with pitch envelope)
	var body = sin(TAU * current_freq * t)
	
	# Click transient
	var click = sin(TAU * CLICK_FREQ_HZ * t) * exp(-t / (CLICK_DECAY_MS / 1000.0)) * CLICK_LEVEL * punch
	
	# Amplitude envelope
	var amp_env = exp(-t / decay)
	
	# Add slight punch compression effect
	var punch_env = 1.0 + punch * exp(-t * 80.0)
	
	return clamp((body + click) * amp_env * punch_env * 0.9, -1.0, 1.0)


static func get_duration() -> float:
	return 0.4


static func get_description() -> String:
	return "CR-5000 Kick - Punchy, tight analog kick with fast pitch drop and subtle click transient."
