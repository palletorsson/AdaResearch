# Aphex Twin Snare - Lo-fi breakbeat style
#
# Character: Crunchy, lo-fi, slightly compressed
# Source: Sampled breakbeat + processing

class_name AphexSnare
extends RefCounted

const SAMPLE_RATE = 44100.0

const TONE_HZ = 200.0
const DECAY_MS = 120.0
const NOISE_DECAY_MS = 100.0
const LEVEL = 0.35


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.25:
		return 0.0
	
	# Tone envelope
	var tone_env = exp(-dt / (DECAY_MS / 1000.0))
	
	# Noise envelope (faster)
	var noise_env = exp(-dt / (NOISE_DECAY_MS / 1000.0))
	
	# Tonal body
	var tone = sin(TAU * TONE_HZ * dt) * 0.4
	tone += sin(TAU * TONE_HZ * 1.5 * dt) * 0.2
	
	# Noise (using time-based pseudo-random)
	var rng = RandomNumberGenerator.new()
	rng.seed = int(t * SAMPLE_RATE) % 100000
	var noise = rng.randf_range(-1.0, 1.0)
	
	var output = tone * tone_env + noise * noise_env * 0.6
	
	# Lo-fi crunch (bit reduction simulation)
	output = round(output * 16.0) / 16.0
	
	return clampf(output * LEVEL, -1.0, 1.0)
