# Synthwave Sweep Up (Noise Riser)
# Research: synthwave brief.json
#
# Character: Dramatic 80s-style noise riser building to a climax.
#   More theatrical than Detroit techno — this announces the chorus.
#   Filtered noise with resonance and a touch of pitch sweep.
# Source: Prophet VS / DX7 noise sweep with resonant filter
# Processing: White noise through resonant LP, longer build than techno
#
# FROM RESEARCH:
# "80s nostalgia, neon nights, VHS dreams"
# "Gated reverb" — impacts should feel cinematic
# "BPM 80-118" — risers are longer than techno
# Builds tension for 4 beats before the supersaw wall hits

class_name SynthwaveSweepUp
extends RefCounted

const SAMPLE_RATE = 44100.0

# Sweep Up Parameters (longer, more dramatic than techno)
const DURATION_S = 3.0            # 4-beat riser at ~80 BPM
const START_FREQ_HZ = 150.0       # Start very low
const END_FREQ_HZ = 10000.0       # Sweep to bright
const RESONANCE = 0.55            # Higher resonance for 80s character
const ATTACK_S = 0.15             # Gradual fade in
const PITCH_SWEEP_SEMIS = 12.0    # Octave pitch rise adds drama
const LEVEL = 0.16

# Filter state
static var filter_state: float = 0.0
static var filter_state_2: float = 0.0


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > DURATION_S + 0.4:
		return 0.0

	# Envelope: gradual build, quick release
	var env = 1.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt > DURATION_S:
		var release_time = dt - DURATION_S
		env = maxf(0.0, 1.0 - release_time / 0.4)

	# Exponential frequency sweep (dramatic 80s style)
	var sweep_progress = clampf(dt / DURATION_S, 0.0, 1.0)
	var freq_ratio = START_FREQ_HZ / END_FREQ_HZ
	var cutoff_hz = END_FREQ_HZ * pow(freq_ratio, 1.0 - sweep_progress)

	# Pitch-swept noise (adds drama)
	var pitch_mult = pow(2.0, sweep_progress * PITCH_SWEEP_SEMIS / 12.0)

	# White noise source with pitch character
	var noise = _noise(t * pitch_mult)

	# Resonant lowpass filter
	var alpha = cutoff_hz / (cutoff_hz + SAMPLE_RATE / TAU)
	filter_state = filter_state + alpha * (noise - filter_state)

	# Second pass for steeper rolloff
	filter_state_2 = filter_state_2 + alpha * (filter_state - filter_state_2)

	# Strong resonance peak (80s character)
	var output = filter_state_2 + (filter_state - filter_state_2) * RESONANCE * 2.5

	# Intensity curve: exponential build for drama
	var intensity = pow(sweep_progress, 1.5) * 0.7 + 0.3

	return clampf(output * env * intensity * LEVEL, -1.0, 1.0)


static func _noise(t: float) -> float:
	# Deterministic noise using sine combination
	var n = sin(t * 12345.6789)
	n += sin(t * 23456.789 + 0.5)
	n += sin(t * 34567.89 + 1.0)
	n += sin(t * 45678.9 + 1.5)
	return fmod(n * 43758.5453, 2.0) - 1.0


static func get_duration() -> float:
	return DURATION_S + 0.4
