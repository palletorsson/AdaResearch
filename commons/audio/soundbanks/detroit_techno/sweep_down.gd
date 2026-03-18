# Detroit Techno Sweep Down (Noise Fall)
# Research: detroit_techno brief.json
#
# Character: Clean digital noise fall, releases tension after drops
# Source: Filtered white noise with downward resonant sweep
# Processing: CLEAN - no tape, no saturation
#
# FROM RESEARCH:
# "Detroit techno is cleaner than Chicago house"
# "No tape saturation, no vinyl crackle"
# "Digital precision - technology as liberation"
# Falls mark the release after impacts

class_name DetroitSweepDown
extends RefCounted

const SAMPLE_RATE = 44100.0

# Sweep Down Parameters
const DURATION_S = 1.5            # Slightly shorter than riser
const START_FREQ_HZ = 6000.0      # Start bright
const END_FREQ_HZ = 150.0         # Sweep to low
const RESONANCE = 0.4             # Moderate resonance
const ATTACK_S = 0.01             # Immediate attack (follows impact)
const LEVEL = 0.16

# Filter state
static var filter_state: float = 0.0
static var filter_state_2: float = 0.0


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > DURATION_S + 0.2:
		return 0.0

	# Envelope: quick attack, exponential decay
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	else:
		# Exponential decay
		env = exp(-(dt - ATTACK_S) / (DURATION_S * 0.6))

	# Exponential frequency sweep downward
	var sweep_progress = clampf(dt / DURATION_S, 0.0, 1.0)
	var freq_ratio = END_FREQ_HZ / START_FREQ_HZ
	var cutoff_hz = START_FREQ_HZ * pow(freq_ratio, sweep_progress)

	# White noise source
	var noise = _noise(t)

	# Resonant lowpass filter
	var alpha = cutoff_hz / (cutoff_hz + SAMPLE_RATE / TAU)
	filter_state = filter_state + alpha * (noise - filter_state)

	# Second pass for steeper rolloff
	filter_state_2 = filter_state_2 + alpha * (filter_state - filter_state_2)

	# Add resonance peak
	var output = filter_state_2 + (filter_state - filter_state_2) * RESONANCE * 2.0

	return clampf(output * env * LEVEL, -1.0, 1.0)


static func _noise(t: float) -> float:
	# Deterministic noise using sine combination
	var n = sin(t * 12345.6789)
	n += sin(t * 23456.789 + 0.5)
	n += sin(t * 34567.89 + 1.0)
	n += sin(t * 45678.9 + 1.5)
	return fmod(n * 43758.5453, 2.0) - 1.0


static func get_duration() -> float:
	return DURATION_S + 0.2
