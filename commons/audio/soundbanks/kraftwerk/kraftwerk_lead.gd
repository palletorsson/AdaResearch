# Kraftwerk Melodic Lead - "Computer Love" (1981) Style
# Research: COMPUTER_LOVE_RESEARCH.md
#
# Character: Clean, slightly nasal, vocal-like lead for main melody
# Source: ARP Odyssey or Minimoog - single voice, mono
# The "I call this number..." melody line
#
# RESEARCH NOTES:
# - Triangle wave primary (soft, vocal-like)
# - Touch of square wave for nasal character
# - ZERO detune (perfectly mono, machine precision)
# - Filter at ~1800Hz base with slight envelope modulation
# - Some portamento/glide between notes (~50ms)
# - Clean, expressive but robotic
#
# "Vocal-like quality while remaining synthetic"
# - Emotional melody through cold electronic means

class_name KraftwerkLead
extends RefCounted

const SAMPLE_RATE = 44100.0

# === SYNTHESIS PARAMETERS ===
# Source: ARP Odyssey/Minimoog + Kraftwerk production style

# Oscillator - Triangle-dominant, touch of square for nasal character
const TRIANGLE_MIX = 0.75        # Primary tone (soft, vocal-like)
const SQUARE_MIX = 0.25          # Adds nasal/reedy quality
const DETUNE_CENTS = 0.0         # ZERO - mono precision (Research: 0 cents)

# Filter - Moderate with envelope modulation
const FILTER_CUTOFF_HZ = 1800.0  # Base cutoff (Research: ~1800Hz)
const FILTER_ENV_DEPTH_HZ = 600.0  # Filter opens on attack
const FILTER_RESONANCE = 0.2     # Slight emphasis

# Envelope - Melodic lead envelope
const ATTACK_MS = 5.0            # Quick but not instant (Research: 5ms)
const DECAY_MS = 200.0           # Medium decay
const SUSTAIN = 0.7              # Good sustain for melody (Research: 0.7)
const RELEASE_MS = 150.0         # Clean release

# Portamento - Kraftwerk used glide sparingly
const GLIDE_TIME_MS = 50.0       # Subtle glide (Research: ~50ms)

# Output
const LEVEL = 0.22               # Prominent in mix


# State for portamento (needs to be tracked between notes)
static var _last_freq: float = 0.0


static func generate(t: float, freq: float, note_duration: float = 0.5, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# === PORTAMENTO ===
	# Smooth frequency transition (Kraftwerk's expressive glide)
	var glide_s = GLIDE_TIME_MS / 1000.0
	var actual_freq = freq
	if _last_freq > 0.0 and dt < glide_s:
		var glide_progress = dt / glide_s
		# Exponential glide (more musical)
		actual_freq = _last_freq * pow(freq / _last_freq, glide_progress)
	
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
	
	# === FILTER ENVELOPE ===
	# Filter opens on attack, settles to base cutoff
	var filter_env = 1.0
	if dt < attack_s + decay_s:
		filter_env = 1.0 + (FILTER_ENV_DEPTH_HZ / FILTER_CUTOFF_HZ) * (1.0 - dt / (attack_s + decay_s))
	var current_cutoff = FILTER_CUTOFF_HZ * filter_env
	
	# === OSCILLATOR ===
	# Triangle wave - soft, vocal-like fundamental
	var phase = fmod(t * actual_freq, 1.0)
	var triangle = 4.0 * absf(phase - 0.5) - 1.0
	
	# Square wave - adds nasal/reedy character
	var square = 1.0 if phase < 0.5 else -1.0
	
	# Mix
	var osc = triangle * TRIANGLE_MIX + square * SQUARE_MIX
	
	# === LOWPASS FILTER ===
	# Simple filter simulation with resonance
	var filtered = 0.0
	var nyquist = SAMPLE_RATE / 2.0
	var num_harmonics = int(minf(current_cutoff / actual_freq, nyquist / actual_freq))
	num_harmonics = clampi(num_harmonics, 1, 12)
	
	# Build filtered sound from harmonics
	for h in range(1, num_harmonics + 1):
		var harmonic_freq = actual_freq * h
		var harmonic_amp: float
		
		# Triangle harmonic series (odd harmonics, 1/n² amplitude)
		if h % 2 == 1:
			harmonic_amp = TRIANGLE_MIX / (h * h)
		else:
			harmonic_amp = 0.0
		
		# Add square wave harmonics (odd harmonics, 1/n amplitude)
		if h % 2 == 1:
			harmonic_amp += SQUARE_MIX / h
		
		# Filter rolloff with slight resonance bump
		var freq_ratio = harmonic_freq / current_cutoff
		var filter_factor = 1.0 / (1.0 + pow(freq_ratio, 2.0))
		# Resonance peak
		if freq_ratio > 0.8 and freq_ratio < 1.2:
			filter_factor *= (1.0 + FILTER_RESONANCE * 2.0)
		
		filtered += sin(TAU * harmonic_freq * t) * harmonic_amp * filter_factor
	
	return clampf(filtered * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 0.5, 0.0)


static func get_duration() -> float:
	return 0.5  # Melodic note duration


static func set_last_freq(freq: float) -> void:
	# Call this when a new note starts to enable portamento
	_last_freq = freq
