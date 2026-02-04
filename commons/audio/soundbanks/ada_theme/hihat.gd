# Ada Theme Hi-Hat - Gentle Whisper Hats
#
# Character: Soft, filtered, almost like breathing
# Not metallic or sharp

class_name AdaHihat
extends RefCounted

const SAMPLE_RATE = 44100.0

const CLOSED_DECAY = 0.03
const OPEN_DECAY = 0.15
const LEVEL = 0.12


static func generate(t: float, trigger_time: float = 0.0, open: bool = false) -> float:
	var dt = t - trigger_time
	if dt < 0.0:
		return 0.0
	
	var decay = OPEN_DECAY if open else CLOSED_DECAY
	if dt > decay * 5.0:
		return 0.0
	
	# Soft envelope
	var env = exp(-dt / decay)
	
	# High-frequency noise
	var rng = RandomNumberGenerator.new()
	rng.seed = int(t * SAMPLE_RATE) % 100000
	var noise = rng.randf_range(-1.0, 1.0)
	
	# Bandpass effect (keep only highs, but soft)
	var hp_freq = 6000.0
	var tone1 = sin(2.0 * PI * hp_freq * dt)
	var tone2 = sin(2.0 * PI * (hp_freq * 1.3) * dt)
	
	var output = noise * 0.5 + (tone1 + tone2) * 0.25
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_closed(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, false)


static func generate_open(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, true)
