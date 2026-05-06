# Dark Wave Tom Low - Tribal Deep Resonant
# Research: dark_wave_cathedral.json sound_design.drums.tom_low
#
# Character: THE dark wave signature. She Past Away "Ritüel" tom — deep,
#   resonant, with a slight pitch drop. Felt physically — sub territory.
#   The 30-cent pitch sweep gives it a "doom" quality.
#   220ms decay means overlapping hits create a droning, ritualistic quality.
# Source: TR-606 low tom / tribal drum emulation
# Processing: Slight saturation, no reverb (room handles that)

class_name DarkWaveTomLow
extends RefCounted

const SAMPLE_RATE = 44100.0

const FUNDAMENTAL_HZ = 85.0       # Deep, sub territory
const OVERTONE_HZ = 170.0         # First overtone (2x fundamental)
const OVERTONE_LEVEL = 0.25       # Subtle harmonic color
const RESONANCE = 0.45            # Rings but doesn't feedback
const PITCH_SWEEP_CENTS = 30.0    # Slight pitch drop — the "doom" quality
const PITCH_SWEEP_MS = 40.0       # 40ms sweep time
const DECAY_S = 0.22              # 220ms — overlaps create drone effect
const BODY_LEVEL = 0.9
const SATURATION = 1.3
const LEVEL = 0.38


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.5:
		return 0.0
	
	# Pitch envelope — slight drop for "doom" character
	var sweep_factor = pow(2.0, PITCH_SWEEP_CENTS / 1200.0)  # cents to ratio
	var pitch_env = exp(-dt / (PITCH_SWEEP_MS / 1000.0))
	var freq = FUNDAMENTAL_HZ * (1.0 + (sweep_factor - 1.0) * pitch_env)
	var overtone_freq = freq * 2.0
	
	# Amplitude envelope — resonant decay
	var amp_env = exp(-dt / DECAY_S)
	# Add slight resonance bump (ring)
	var resonance_env = amp_env * (1.0 + RESONANCE * sin(2.0 * PI * 3.0 * dt))
	
	# Body — fundamental sine
	var body = sin(2.0 * PI * freq * dt) * BODY_LEVEL
	
	# Overtone — adds tonal color
	var overtone = sin(2.0 * PI * overtone_freq * dt) * OVERTONE_LEVEL
	
	var output = (body + overtone) * resonance_env
	
	# Slight saturation for analog warmth
	output = tanh(output * SATURATION)
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.5
