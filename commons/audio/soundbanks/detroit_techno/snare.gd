# Detroit Techno Snare - TR-909 Style
# Research: detroit_techno.md
#
# Character: Snappy, metallic, high-pitched, NO reverb
# Source: TR-909 hybrid circuit
# Processing: CLEAN - "+2dB high shelf for brightness"

class_name DetroitSnare
extends RefCounted

const SAMPLE_RATE = 44100.0

# 909 Snare Parameters (from research)
# "Snappy, metallic snare"
# "High shelf boost +2dB for brightness"
# "Minimal effects - Detroit techno is cleaner than Chicago house"
const BODY_FREQ_HZ = 220.0        # Snare body tone (higher than 808)
const BODY_DECAY_S = 0.035        # Fast body decay (snappy)
const NOISE_DECAY_S = 0.045       # Noise tail
const NOISE_LEVEL = 0.55          # Noise vs body balance
const BODY_LEVEL = 0.45           # Body level
const LEVEL = 0.35                # Output level


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.3:
		return 0.0
	
	# Body - pitched component (909 has distinct pitch)
	var body = sin(2.0 * PI * BODY_FREQ_HZ * dt)
	var body_env = exp(-dt / BODY_DECAY_S)
	body *= body_env * BODY_LEVEL
	
	# Noise - snare wires
	var noise = randf() * 2.0 - 1.0
	var noise_env = exp(-dt / NOISE_DECAY_S)
	noise *= noise_env * NOISE_LEVEL
	
	# Combine - NO reverb, NO processing (Detroit is DRY)
	var output = (body + noise) * LEVEL
	
	return clampf(output, -1.0, 1.0)


static func get_duration() -> float:
	return 0.3
