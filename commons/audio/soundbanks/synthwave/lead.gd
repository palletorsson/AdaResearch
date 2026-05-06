# Synthwave Lead - Juno-Style PWM Melody
# Research: synthwave brief.json
#
# Character: Bright, warm monophonic lead with chorus and modulation.
#   Sits above the supersaw wall, cutting through with PWM shimmer.
#   Think Kavinsky, Perturbator, Carpenter Brut — the hook that sticks.
# Source: Roland Juno-106 / Jupiter-8 — PWM lead with chorus
# Processing: Pulse wave with PWM, slight unison detune, chorus shimmer
#
# FROM RESEARCH:
# "JP-8000 supersaw + Juno chorus arp"
# "80s nostalgia, neon nights, VHS dreams"
# "Scales: minor, dorian — 80s pop voicings"
#
# Key specs:
#   Oscillator: Pulse wave with PWM (50-70% width modulation)
#   Filter: LP 6000 Hz — bright and present
#   Attack: 15ms — snappy but not harsh
#   Sustain: 0.85
#   Release: 400ms — moderate tail
#   Vibrato: 5Hz, 8 cents — subtle life
#   Level: Medium-high — this is the hook

class_name SynthwaveLead
extends RefCounted

const SAMPLE_RATE = 44100.0

# Juno-style PWM lead parameters
const FILTER_CUTOFF_HZ = 6000.0   # Bright and present
const ATTACK_S = 0.015             # Snappy lead attack
const DECAY_S = 0.1                # Quick decay to sustain
const SUSTAIN = 0.85               # High sustain for melodic lines
const RELEASE_S = 0.4              # Moderate release
const VIBRATO_RATE_HZ = 5.0       # Classic vibrato speed
const VIBRATO_DEPTH_CENTS = 8.0   # Subtle but audible
const PWM_RATE_HZ = 0.8           # Slow PWM modulation
const PWM_DEPTH = 0.2             # PWM range 30-70%
const DETUNE_CENTS = 5.0          # Slight unison thickening
const LEVEL = 0.22


static func generate(t: float, freq: float, note_duration: float = 1.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0

	# ADSR envelope
	var env = 0.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		env = 1.0 - (1.0 - SUSTAIN) * ((dt - ATTACK_S) / DECAY_S)
	elif dt < note_duration:
		env = SUSTAIN
	else:
		env = SUSTAIN * maxf(0.0, 1.0 - (dt - note_duration) / RELEASE_S)

	if env <= 0.0:
		return 0.0

	# Vibrato
	var vibrato = sin(2.0 * PI * VIBRATO_RATE_HZ * t) * VIBRATO_DEPTH_CENTS / 1200.0
	var mod_freq = freq * pow(2.0, vibrato)

	# PWM modulation (pulse width varies over time)
	var pulse_width = 0.5 + sin(2.0 * PI * PWM_RATE_HZ * t) * PWM_DEPTH

	# Main pulse wave with PWM
	var phase = fmod(t * mod_freq, 1.0)
	var pulse = 1.0 if phase < pulse_width else -1.0

	# Slight detune for thickness (2 voices)
	var detune = DETUNE_CENTS / 1200.0
	var phase2 = fmod(t * mod_freq * pow(2.0, detune), 1.0)
	var pulse2 = 1.0 if phase2 < pulse_width else -1.0

	var phase3 = fmod(t * mod_freq * pow(2.0, -detune), 1.0)
	var pulse3 = 1.0 if phase3 < pulse_width else -1.0

	var output = (pulse + pulse2 * 0.5 + pulse3 * 0.5) / 2.0

	# Brightness envelope - slightly darker on sustain
	var brightness = 0.7 + env * 0.3
	output *= brightness

	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 10.0, 0.0)
