# Detroit Techno Sweep Up (Noise Riser)
# Research: detroit_techno brief.json
#
# Character: Clean digital noise riser, builds tension before drops
# Source: Filtered white noise with resonant sweep
# Processing: CLEAN - no tape, no saturation
#
# FROM RESEARCH:
# "Detroit techno is cleaner than Chicago house"
# "No tape saturation, no vinyl crackle"
# "Digital precision - technology as liberation"
# Risers mark transitions between sections

class_name DetroitSweepUp
extends RefCounted

const SAMPLE_RATE = 44100.0

# Sweep Up Parameters
const DURATION_S = 2.0            # Standard 2-beat riser at 120 BPM
const START_FREQ_HZ = 200.0       # Start low
const END_FREQ_HZ = 8000.0        # Sweep to bright
const RESONANCE = 0.45            # Moderate resonance
const ATTACK_S = 0.1              # Fade in
const LEVEL = 0.18

# Filter state
static var filter_state: float = 0.0
static var filter_state_2: float = 0.0


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > DURATION_S + 0.3:
		return 0.0

	# Envelope: fade in, sustain, quick fade out
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt > DURATION_S:
		var release_time = dt - DURATION_S
		env = maxf(0.0, 1.0 - release_time / 0.3)

	# Exponential frequency sweep (sounds more natural)
	var sweep_progress = clampf(dt / DURATION_S, 0.0, 1.0)
	var freq_ratio = START_FREQ_HZ / END_FREQ_HZ
	var cutoff_hz = END_FREQ_HZ * pow(freq_ratio, 1.0 - sweep_progress)

	# White noise source (deterministic for consistent playback)
	var noise = _noise(t)

	# Resonant lowpass filter
	var alpha = cutoff_hz / (cutoff_hz + SAMPLE_RATE / TAU)
	filter_state = filter_state + alpha * (noise - filter_state)

	# Second pass for steeper rolloff
	filter_state_2 = filter_state_2 + alpha * (filter_state - filter_state_2)

	# Add resonance peak
	var output = filter_state_2 + (filter_state - filter_state_2) * RESONANCE * 2.0

	# Intensity builds with sweep
	var intensity = 0.5 + sweep_progress * 0.5

	return clampf(output * env * intensity * LEVEL, -1.0, 1.0)


static func _noise(t: float) -> float:
	# Deterministic noise using sine combination
	var n = sin(t * 12345.6789)
	n += sin(t * 23456.789 + 0.5)
	n += sin(t * 34567.89 + 1.0)
	n += sin(t * 45678.9 + 1.5)
	return fmod(n * 43758.5453, 2.0) - 1.0


static func get_duration() -> float:
	return DURATION_S + 0.3
