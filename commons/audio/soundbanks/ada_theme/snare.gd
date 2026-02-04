# Ada Theme Snare - Soft Brush Snare
#
# Character: Gentle brush sweep, not a crack
# Whispered presence

class_name AdaSnare
extends RefCounted

const SAMPLE_RATE = 44100.0

const DECAY = 0.15
const TONE_FREQ = 180.0
const LEVEL = 0.2

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.3:
		return 0.0
	
	# Soft envelope
	var env = 0.0
	if dt < 0.02:
		env = dt / 0.02
	else:
		env = exp(-dt / DECAY)
	
	# Filtered noise (brush character)
	var rng = RandomNumberGenerator.new()
	rng.seed = int(t * SAMPLE_RATE) % 100000
	var noise = rng.randf_range(-1.0, 1.0)
	
	# Subtle tone underneath
	var tone = sin(2.0 * PI * TONE_FREQ * dt) * 0.2
	
	# Mix: mostly filtered noise
	var output = noise * 0.8 + tone
	
	# Simple lowpass approximation
	output *= 0.6
	
	return clampf(output * env * LEVEL, -1.0, 1.0)
