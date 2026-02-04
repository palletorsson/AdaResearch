# Aphex Twin Texture - Tape noise and field recording vibe
#
# Character: Warm noise floor, nostalgic, intimate
# Source: Tape hiss + filtered noise

class_name AphexTexture
extends RefCounted

const SAMPLE_RATE = 44100.0

const LEVEL = 0.06


static func generate(t: float, _trigger_time: float = 0.0) -> float:
	# Continuous texture
	var rng = RandomNumberGenerator.new()
	rng.seed = int(t * SAMPLE_RATE) % 1000000
	
	# Pink-ish noise (low frequencies emphasized)
	var white = rng.randf_range(-1.0, 1.0)
	
	# Simple lowpass via weighted average with previous
	var filtered = white * 0.3
	
	# Add some gentle crackle
	var crackle = 0.0
	if rng.randf() > 0.998:
		crackle = rng.randf_range(0.2, 0.5)
	
	var output = filtered + crackle
	
	return clampf(output * LEVEL, -1.0, 1.0)
