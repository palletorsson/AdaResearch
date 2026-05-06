# Dark Wave Tom High - Tribal Pitched Percussive
# Research: dark_wave_cathedral.json sound_design.drums.tom_high
#
# Character: The "response" to tom_low's "call". Pitched clearly above the kick
#   but below the snare noise band. Shorter decay — more percussive, less droning.
#   Used for the upper voice in the tribal polyrhythm.
# Source: TR-606 high tom
# Processing: Tight, taut, minimal processing

class_name DarkWaveTomHigh
extends RefCounted

const SAMPLE_RATE = 44100.0

const FUNDAMENTAL_HZ = 145.0      # Above kick, below snare noise
const OVERTONE_HZ = 290.0         # First overtone
const OVERTONE_LEVEL = 0.2        # Subtle
const RESONANCE = 0.35            # Less ring than low tom — tighter
const PITCH_SWEEP_CENTS = 20.0    # Less sweep than low tom
const PITCH_SWEEP_MS = 25.0       # Faster sweep — punchier
const DECAY_S = 0.13              # 130ms — percussive, not droning
const BODY_LEVEL = 0.75
const LEVEL = 0.32


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.35:
		return 0.0
	
	# Pitch envelope
	var sweep_factor = pow(2.0, PITCH_SWEEP_CENTS / 1200.0)
	var pitch_env = exp(-dt / (PITCH_SWEEP_MS / 1000.0))
	var freq = FUNDAMENTAL_HZ * (1.0 + (sweep_factor - 1.0) * pitch_env)
	var overtone_freq = freq * 2.0
	
	# Amplitude envelope — tight decay
	var amp_env = exp(-dt / DECAY_S)
	
	# Body
	var body = sin(2.0 * PI * freq * dt) * BODY_LEVEL
	
	# Overtone
	var overtone = sin(2.0 * PI * overtone_freq * dt) * OVERTONE_LEVEL
	
	var output = (body + overtone) * amp_env
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.35
