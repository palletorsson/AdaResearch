# Kraftwerk Arpeggio - "Computer Love" (1981) Style
# Research: COMPUTER_LOVE_RESEARCH.md
#
# Character: Clean, bell-like, machine-precise arpeggio
# Source: ARP Odyssey / Minimoog - MONO configuration
# The iconic descending/ascending pattern from "Computer Love"
#
# RESEARCH NOTES:
# - Pulse/square wave oscillator (50% duty)
# - ZERO detune (single oscillator, machine precision)
# - Filter at ~2500Hz, minimal resonance
# - Very fast attack (1ms), short decay (60-80ms)
# - NO modulation - Kraftwerk's signature is static precision
#
# "The arpeggio is what Coldplay sampled for 'Talk'"
# - Clean, cold, yet emotionally evocative

class_name KraftwerkArp
extends RefCounted

const SAMPLE_RATE = 44100.0

# === SYNTHESIS PARAMETERS ===
# Source: ARP Odyssey technical specs + Kraftwerk production analysis

# Oscillator - Pure pulse wave, NO detune
const DETUNE_CENTS = 0.0         # MONO - machine precision (Research: zero modulation philosophy)
const PULSE_WIDTH = 0.5          # 50% = square wave

# Filter - Moderate brightness, minimal resonance
const FILTER_CUTOFF_HZ = 2500.0  # Bell-like brightness (Research: ~2500Hz for arp tones)
const FILTER_RESONANCE = 0.15    # Minimal peak (clean, not squelchy)

# Envelope - Short, percussive
const ATTACK_MS = 1.0            # Instant attack (Research: 1ms for arp stabs)
const DECAY_MS = 70.0            # Short decay for rhythmic definition
const SUSTAIN = 0.0              # No sustain - percussive envelope
const RELEASE_MS = 50.0          # Quick release

# Output
const LEVEL = 0.20               # Moderate level in mix


static func generate(t: float, freq: float, note_duration: float = 0.15, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# === ENVELOPE ===
	# Fast AD envelope, no sustain (percussive arp character)
	var attack_s = ATTACK_MS / 1000.0
	var decay_s = DECAY_MS / 1000.0
	var release_s = RELEASE_MS / 1000.0
	
	var env = 0.0
	if dt < attack_s:
		# Attack phase
		env = dt / attack_s
	elif dt < attack_s + decay_s:
		# Decay phase
		var decay_progress = (dt - attack_s) / decay_s
		env = 1.0 - (1.0 - SUSTAIN) * decay_progress
	elif dt < note_duration:
		# Sustain phase (minimal for this sound)
		env = SUSTAIN
	else:
		# Release phase
		var release_progress = (dt - note_duration) / release_s
		env = SUSTAIN * maxf(0.0, 1.0 - release_progress)
	
	# === OSCILLATOR ===
	# Pulse wave - THE Kraftwerk arp sound
	# No detune - single oscillator, machine precision
	var phase = fmod(t * freq, 1.0)
	var pulse = 1.0 if phase < PULSE_WIDTH else -1.0
	
	# === SIMPLE LOWPASS FILTER APPROXIMATION ===
	# Remove harsh high harmonics from pulse wave
	# Using additive synthesis to simulate filtered pulse
	var filtered = 0.0
	var nyquist = SAMPLE_RATE / 2.0
	var num_harmonics = int(minf(FILTER_CUTOFF_HZ / freq, nyquist / freq))
	num_harmonics = clampi(num_harmonics, 1, 16)  # Limit for performance
	
	# Pulse wave Fourier series (odd harmonics, amplitude varies with duty cycle)
	for h in range(1, num_harmonics + 1):
		if h % 2 == 1:  # Odd harmonics for 50% pulse
			var harmonic_freq = freq * h
			var harmonic_amp = 1.0 / h
			# Filter rolloff
			var filter_factor = 1.0 / (1.0 + pow(harmonic_freq / FILTER_CUTOFF_HZ, 2.0))
			filtered += sin(TAU * harmonic_freq * t) * harmonic_amp * filter_factor
	
	# Normalize
	filtered *= 0.8
	
	return clampf(filtered * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 0.15, 0.0)


static func get_duration() -> float:
	return 0.15  # Short arp notes
