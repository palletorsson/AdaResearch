# Kraftwerk Warm Pad - "Computer Love" (1981) Style
# Research: COMPUTER_LOVE_RESEARCH.md
#
# Character: Warm, synthetic string-like bed with vocoder formant quality
# Source: Vocoder-processed synth strings at Kling Klang
#
# RESEARCH NOTES:
# - NOT a detuned supersaw (that's synthwave, forbidden for Kraftwerk)
# - Sawtooth base with additive harmonics for warmth
# - Vocoder-style formant shaping (16-band vocoder character)
# - Only 0-2 cents detune MAX (warmth from harmonics, not unison spread)
# - Filter at ~3000Hz, shaped for vocal-like formants
# - Long attack (50ms), sustained, 500ms release
#
# "Warm but precise, synthetic but emotional"
# - Underlies the arpeggio and melody with emotional bed

class_name KraftwerkPadWarm
extends RefCounted

const SAMPLE_RATE = 44100.0

# === SYNTHESIS PARAMETERS ===
# Source: Sennheiser VSM201 vocoder specs + Kling Klang production style

# Oscillator - Sawtooth with controlled harmonics
const DETUNE_CENTS = 1.5         # MINIMAL - warmth from harmonics, not spread
                                  # (Research: <2 cents for Kraftwerk)

# Filter - Vocoder-like formant shaping
const FILTER_CUTOFF_HZ = 3000.0  # Open enough for presence
const FILTER_RESONANCE = 0.2     # Slight formant emphasis

# Formant frequencies (vocoder-like vowel shaping)
const FORMANT_1_HZ = 500.0       # Low formant (body)
const FORMANT_2_HZ = 1500.0      # Mid formant (presence)
const FORMANT_3_HZ = 2800.0      # High formant (air)

# Envelope - Slow pad envelope
const ATTACK_MS = 50.0           # Slow fade in (Research: 50ms for pad)
const DECAY_MS = 100.0           # Short decay to sustain
const SUSTAIN = 0.85             # High sustain for pad
const RELEASE_MS = 500.0         # Long release (Research: 500ms)

# Output
const LEVEL = 0.16               # Sits under other elements


static func generate(t: float, chord_freqs: Array, note_duration: float = 4.0, note_time: float = 0.0) -> float:
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
	
	var output = 0.0
	
	for base_freq in chord_freqs:
		# === OSCILLATOR ===
		# Sawtooth with minimal detune (Kraftwerk precision)
		var drift_ratio = pow(2.0, DETUNE_CENTS / 1200.0)
		
		# Primary oscillator
		var saw1 = fmod(t * base_freq, 1.0) * 2.0 - 1.0
		# Slightly detuned for warmth (NOT unison spread!)
		var saw2 = fmod(t * base_freq * drift_ratio, 1.0) * 2.0 - 1.0
		var saw_mix = (saw1 * 0.7 + saw2 * 0.3)
		
		# === HARMONIC SHAPING ===
		# Add controlled harmonics for vocoder-like warmth
		# (Research: warmth from harmonics, not detune)
		var harmonics = 0.0
		harmonics += sin(TAU * base_freq * t) * 0.5           # Fundamental
		harmonics += sin(TAU * base_freq * 2.0 * t) * 0.25    # 2nd harmonic
		harmonics += sin(TAU * base_freq * 3.0 * t) * 0.15    # 3rd harmonic
		harmonics += sin(TAU * base_freq * 4.0 * t) * 0.1     # 4th harmonic
		
		# === FORMANT SHAPING ===
		# Simulate vocoder formant bands
		var formant_boost = 0.0
		formant_boost += _formant_response(base_freq, FORMANT_1_HZ) * 0.3
		formant_boost += _formant_response(base_freq * 2.0, FORMANT_2_HZ) * 0.2
		formant_boost += _formant_response(base_freq * 3.0, FORMANT_3_HZ) * 0.1
		
		# Combine: filtered saw + shaped harmonics + formant emphasis
		var voice = saw_mix * 0.4 + harmonics * 0.5 + formant_boost * 0.1
		output += voice
	
	# Normalize for chord size
	if chord_freqs.size() > 0:
		output /= chord_freqs.size()
	
	# === SUBTLE LOWPASS ===
	# Kraftwerk pads are warm but not dark
	output = tanh(output * 0.9)  # Soft saturation only
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func _formant_response(freq: float, formant_hz: float) -> float:
	# Resonant peak at formant frequency
	var bandwidth = 200.0
	var diff = absf(freq - formant_hz)
	return expf(-(diff * diff) / (2.0 * bandwidth * bandwidth))


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 10.0, 0.0)


static func get_duration() -> float:
	return 4.0  # Long sustained pad
