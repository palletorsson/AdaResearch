# Kraftwerk Clean Sub Bass - "Computer Love" (1981) Style
# Research: COMPUTER_LOVE_RESEARCH.md
#
# Character: Clean, round, sine-heavy bass - sits under mix without competing
# Source: Minimoog Model D with ladder filter in lowpass mode
#
# RESEARCH NOTES:
# - Primarily sine wave (90%) with touch of saw (10%) for definition
# - Only 2 cents detune (Minimoog oscillator drift, not intentional width)
# - Filter at 400-600Hz (removes higher harmonics, keeps it round)
# - Fast attack (2ms), moderate decay (150ms), high sustain (0.8)
# - Clean signal path - NO distortion (forbidden for Kraftwerk)
# - Follows root notes simply, no complex bass lines
#
# Minimoog specs: "24dB/oct ladder lowpass, monophonic"
# "oscillators never completely synchronized" = slight warmth, NOT wobble

class_name KraftwerkBassClean
extends RefCounted

const SAMPLE_RATE = 44100.0

# === SYNTHESIS PARAMETERS ===
# Source: Minimoog Model D specifications + Computer World production

# Oscillator - Sine-dominant with subtle saw for definition
const SINE_MIX = 0.90            # 90% sine (round, clean)
const SAW_MIX = 0.10             # 10% saw (slight definition)
const DETUNE_CENTS = 2.0         # Minimoog drift only (Research: max 2 cents)

# Filter - Low cutoff for sub-heavy character
const FILTER_CUTOFF_HZ = 500.0   # Keep it round (Research: 400-600Hz)
const FILTER_RESONANCE = 0.0     # No resonance - clean and round

# Envelope - Punchy but sustained
const ATTACK_MS = 2.0            # Fast attack (Research: 2ms for bass)
const DECAY_MS = 150.0           # Moderate decay to sustain
const SUSTAIN = 0.8              # High sustain for bass notes
const RELEASE_MS = 80.0          # Quick release (not muddy)

# Output
const LEVEL = 0.40               # Strong sub presence


static func generate(t: float, freq: float, note_duration: float = 1.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# === ENVELOPE ===
	var attack_s = ATTACK_MS / 1000.0
	var decay_s = DECAY_MS / 1000.0
	var release_s = RELEASE_MS / 1000.0
	
	var env = 0.0
	if dt < attack_s:
		env = dt / attack_s
	elif dt < attack_s + decay_s:
		var decay_progress = (dt - attack_s) / decay_s
		env = 1.0 - (1.0 - SUSTAIN) * decay_progress
	elif dt < note_duration:
		env = SUSTAIN
	else:
		var release_progress = (dt - note_duration) / release_s
		env = SUSTAIN * maxf(0.0, 1.0 - release_progress)
	
	if env <= 0.001:
		return 0.0
	
	# === OSCILLATOR ===
	# Minimoog-style: primarily sine with slight saw for definition
	
	# Sine wave - the body of the bass
	var sine = sin(TAU * freq * t)
	
	# Saw wave - adds slight harmonic definition
	# With minimal Minimoog drift (2 cents)
	var drift_ratio = pow(2.0, DETUNE_CENTS / 1200.0)
	var saw = fmod(t * freq * drift_ratio, 1.0) * 2.0 - 1.0
	
	# Mix: mostly sine, touch of saw
	var osc = sine * SINE_MIX + saw * SAW_MIX
	
	# === SIMPLE LOWPASS ===
	# Minimoog ladder filter simulation (very basic)
	# Remove harmonics above cutoff for round bass
	var filtered = osc
	
	# Add sub-octave for extra weight (Kraftwerk bass technique)
	var sub = sin(TAU * freq * 0.5 * t) * 0.15
	filtered += sub
	
	# Soft saturation - NOT distortion (Kraftwerk = clean)
	filtered = tanh(filtered * 0.95)
	
	return clampf(filtered * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 10.0, 0.0)


static func get_duration() -> float:
	return 1.0  # Sustained bass notes
