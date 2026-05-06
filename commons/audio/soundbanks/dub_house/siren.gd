# Dub House Siren Drone - Cinematic, long-form warning tone
#
# Character: Slow, ominous siren drone with gentle pitch sweep
# Source: Filmic synth sirens + foghorn-style low layer
# Processing: Slow pitch LFO, breath LFO, soft saturation, lowpass

class_name DubHouseSiren
extends RefCounted

const SAMPLE_RATE = 44100.0

const ATTACK_S = 4.0
const DECAY_S = 1.5
const SUSTAIN = 0.7
const RELEASE_S = 6.0

const SWEEP_RATE = 0.035      # Hz - slow siren rise/fall
const SWEEP_CENTS = 32.0      # Pitch sweep range
const BREATH_RATE = 0.07      # Hz - slow amplitude breathing
const BREATH_DEPTH = 0.15
const DETUNE_CENTS = 4.0
const LOWPASS_HZ = 1800.0
const DRIVE = 1.15
const LEVEL = 0.16

static var filter_state: float = 0.0


static func generate(t: float, chord_freqs: Array, note_duration: float = 8.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0

	var env = _get_envelope(dt, note_duration)
	if env <= 0.0:
		return 0.0

	var root_freq = chord_freqs[0] if chord_freqs.size() > 0 else 110.0
	var fifth_freq = chord_freqs[2] if chord_freqs.size() > 2 else root_freq * 1.5
	var upper_freq = chord_freqs[1] if chord_freqs.size() > 1 else root_freq * 2.0

	var sweep = sin(TAU * SWEEP_RATE * t) * (SWEEP_CENTS / 1200.0)
	var sweep_ratio = pow(2.0, sweep)

	var detune_ratio = pow(2.0, DETUNE_CENTS / 1200.0)

	var output = 0.0

	# Low foghorn bed
	output += sin(TAU * (root_freq * 0.5) * sweep_ratio * t) * 0.35

	# Core siren tone (detuned sine + triangle)
	var sine1 = sin(TAU * root_freq * sweep_ratio * t)
	var sine2 = sin(TAU * root_freq * sweep_ratio * detune_ratio * t)
	var tri = 2.0 * abs(2.0 * fmod(t * root_freq * sweep_ratio, 1.0) - 1.0) - 1.0
	output += (sine1 + sine2) * 0.35 + tri * 0.18

	# Upper harmonic for presence
	var saw = fmod(t * upper_freq * sweep_ratio, 1.0) * 2.0 - 1.0
	output += saw * 0.12

	# Slight fifth reinforcement
	output += sin(TAU * fifth_freq * sweep_ratio * t) * 0.12

	# Lowpass filter
	var alpha = LOWPASS_HZ / (LOWPASS_HZ + SAMPLE_RATE / TAU)
	filter_state = filter_state + alpha * (output - filter_state)
	output = filter_state

	# Breathing amplitude movement
	var breath = 1.0 + sin(TAU * BREATH_RATE * t) * BREATH_DEPTH

	output = tanh(output * DRIVE)

	return clampf(output * env * breath * LEVEL, -1.0, 1.0)


static func _get_envelope(dt: float, note_duration: float) -> float:
	if dt < ATTACK_S:
		return dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		var decay_progress = (dt - ATTACK_S) / DECAY_S
		return 1.0 - (1.0 - SUSTAIN) * decay_progress
	elif dt < note_duration:
		return SUSTAIN
	else:
		var release_time = dt - note_duration
		return SUSTAIN * (1.0 - minf(release_time / RELEASE_S, 1.0))


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 10.0, 0.0)
