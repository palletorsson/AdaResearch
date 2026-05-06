# Synthwave Impact Hit
# Research: synthwave brief.json
#
# Character: Cinematic 80s impact — gated reverb tail on the hit.
#   Think Top Gun, Terminator, Drive. The drop that says "here comes the chorus."
#   More theatrical and sustained than Detroit techno impacts.
# Source: LinnDrum / Simmons SDS-V layered with gated reverb
# Processing: Layered transient + gated reverb simulation + sub
#
# FROM RESEARCH:
# "Gated reverb snare" — signature 80s sound
# "80s nostalgia, neon nights"
# "Big 80s snare hit, wide detuned synth, nostalgic"
# Impacts mark section boundaries with drama

class_name SynthwaveImpact
extends RefCounted

const SAMPLE_RATE = 44100.0

# Impact Parameters (cinematic 80s style)
const ATTACK_S = 0.001            # Instant attack
const BODY_DECAY_S = 0.08         # Quick initial decay
const GATE_LENGTH_S = 0.25        # Gated reverb sustain
const GATE_RELEASE_S = 0.05       # Abrupt gated cutoff
const SUB_DECAY_S = 0.35          # Sub tail
const NOISE_DECAY_S = 0.03        # Quick noise transient
const HIT_FREQ_HZ = 3500.0        # Bright transient
const SUB_FREQ_HZ = 50.0          # Cinematic sub
const LEVEL = 0.30


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > GATE_LENGTH_S + GATE_RELEASE_S + 0.1:
		return 0.0

	var output = 0.0

	# Layer 1: Bright transient click (Simmons-style)
	if dt < 0.02:
		var click_env = 1.0 - (dt / 0.02)
		var click_freq = HIT_FREQ_HZ * (1.0 - dt * 25.0)
		click_freq = maxf(click_freq, 400.0)
		output += sin(TAU * click_freq * dt) * click_env * 0.45

	# Layer 2: Body (pitched drum body)
	var body_env = exp(-dt / BODY_DECAY_S)
	var body_freq = 200.0 * exp(-dt * 10.0) + 80.0
	output += sin(TAU * body_freq * dt) * body_env * 0.4

	# Layer 3: Gated reverb simulation (sustained white noise burst)
	if dt < GATE_LENGTH_S + GATE_RELEASE_S:
		var gate_env = 1.0
		if dt > GATE_LENGTH_S:
			# Abrupt gated cutoff
			gate_env = 1.0 - (dt - GATE_LENGTH_S) / GATE_RELEASE_S
		# Early decay within the gate
		var reverb_shape = exp(-dt / 0.4) * 0.6 + 0.4
		var noise = _noise(t)
		# Filter the noise for reverb character
		var filtered_noise = noise * 0.7 + _noise(t * 0.5) * 0.3
		output += filtered_noise * gate_env * reverb_shape * 0.18

	# Layer 4: Sub impact
	var sub_env = exp(-dt / SUB_DECAY_S)
	output += sin(TAU * SUB_FREQ_HZ * dt) * sub_env * 0.35

	# Layer 5: Quick noise burst for presence
	if dt < NOISE_DECAY_S * 2.0:
		var noise_env = exp(-dt / NOISE_DECAY_S)
		output += _noise(t) * noise_env * 0.12

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
	return GATE_LENGTH_S + GATE_RELEASE_S + 0.1
