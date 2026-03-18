# Detroit Techno Impact Hit
# Research: detroit_techno brief.json
#
# Character: Clean, powerful transient for drops and transitions
# Source: Layered 909-style kick transient + noise burst + sub thump
# Processing: CLEAN - no distortion, no tape
#
# FROM RESEARCH:
# "909 drums + clean digital pad + 808 sub bass"
# "Crisp metallic snare, cold synth chord, deep sub"
# "Detroit techno is cleaner than Chicago house"
# Impact marks section boundaries and drops

class_name DetroitImpact
extends RefCounted

const SAMPLE_RATE = 44100.0

# Impact Parameters
const ATTACK_S = 0.001            # Instant attack
const BODY_DECAY_S = 0.15         # Main body decay
const SUB_DECAY_S = 0.4           # Sub tail decay
const NOISE_DECAY_S = 0.05        # Quick noise burst
const CLICK_FREQ_HZ = 4000.0      # Initial click frequency
const SUB_FREQ_HZ = 45.0          # Deep sub frequency
const LEVEL = 0.32


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > SUB_DECAY_S + 0.1:
		return 0.0

	var output = 0.0

	# Layer 1: Click transient (high frequency sine burst)
	if dt < 0.015:
		var click_env = 1.0 - (dt / 0.015)
		var click_freq = CLICK_FREQ_HZ * (1.0 - dt * 30.0)  # Pitch drop
		click_freq = maxf(click_freq, 500.0)
		output += sin(TAU * click_freq * dt) * click_env * 0.4

	# Layer 2: Body thump (pitched down sine)
	var body_env = exp(-dt / BODY_DECAY_S)
	var body_freq = 120.0 * exp(-dt * 8.0) + 50.0  # Pitch envelope
	output += sin(TAU * body_freq * dt) * body_env * 0.5

	# Layer 3: Sub tail
	var sub_env = exp(-dt / SUB_DECAY_S)
	output += sin(TAU * SUB_FREQ_HZ * dt) * sub_env * 0.35

	# Layer 4: Noise burst (adds air and presence)
	if dt < NOISE_DECAY_S * 2.0:
		var noise_env = exp(-dt / NOISE_DECAY_S)
		var noise = _noise(t)
		output += noise * noise_env * 0.15

	# Overall envelope
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S

	return clampf(output * env * LEVEL, -1.0, 1.0)


static func _noise(t: float) -> float:
	# Deterministic noise
	var n = sin(t * 12345.6789)
	n += sin(t * 23456.789 + 0.5)
	n += sin(t * 34567.89 + 1.0)
	return fmod(n * 43758.5453, 2.0) - 1.0


static func get_duration() -> float:
	return SUB_DECAY_S + 0.1
