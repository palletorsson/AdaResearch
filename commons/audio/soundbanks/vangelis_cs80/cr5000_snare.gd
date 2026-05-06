# cr5000_snare.gd
# Roland CR-5000 CompuRhythm snare drum
# Character: Crisp, snappy, vintage drum machine
# Source: Roland CR-5000 (1980)
# Processing: Minimal processing

# Technical anatomy:
# - Noise + tone body
# - Brighter than 808 snare
# - Snappy, good transient
# - Medium body, not too long

class_name CR5000Snare
extends RefCounted

const SAMPLE_RATE = 44100.0

# CR-5000 snare parameters
const TONE_FREQ_HZ = 200.0
const TONE_DECAY_MS = 80.0
const NOISE_DECAY_MS = 120.0
const TONE_LEVEL = 0.4
const NOISE_LEVEL = 0.6
const HPF_CUTOFF_HZ = 800.0


static func generate(t: float, freq: float = 0.0, params: Dictionary = {}) -> float:
	var tone = params.get("tone", TONE_LEVEL)
	var snappy = params.get("snappy", NOISE_LEVEL)
	var tune = params.get("tune", 1.0)
	
	# Tone body (pitched component)
	var tone_signal = sin(TAU * TONE_FREQ_HZ * tune * t)
	var tone_env = exp(-t / (TONE_DECAY_MS / 1000.0))
	
	# Noise (snare wires)
	var noise = randf() * 2.0 - 1.0
	var noise_env = exp(-t / (NOISE_DECAY_MS / 1000.0))
	
	# High-pass the noise for brightness
	# Simplified: just reduce low frequency content
	noise *= 0.7 + 0.3 * sin(TAU * 4000.0 * t)
	
	# Mix
	var output = tone_signal * tone_env * tone + noise * noise_env * snappy
	
	return clamp(output * 0.8, -1.0, 1.0)


static func get_duration() -> float:
	return 0.25


static func get_description() -> String:
	return "CR-5000 Snare - Crisp, snappy analog snare with pitched tone body and bright noise component."
