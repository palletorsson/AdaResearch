# Dark Wave Bass - Deep Analog Round Bass with Midrange Presence
# Research: dark_wave brief
#
# Character: THE defining sound of dark wave. Deep, round, analog-style bass
#   with significant midrange presence. Think Juno-106 or Moog — NOT a sub bass.
#   You can HEAR the note clearly on laptop speakers. Warm, enveloping, slightly
#   growling. Slow attack gives it that "breathing" quality.
#   Reference: She Past Away "Kasvetli Kutlama" — the bass IS the song.
#   Reference: Boy Harsher "Pain" — pulsing, round, ever-present.
# Source: Roland Juno-106 bass patch / Moog Minimoog Model D
# Processing: Saw + pulse oscillators, low-pass filter ~400Hz with slow LFO,
#   Juno-style BBD chorus for width, slight saturation
#
# Key specs:
#   Oscillators: Saw + pulse (40% width) layered
#   Detune: 7 cents between oscillators
#   Filter: LP at 450 Hz, resonance 0.35, LFO modulation ±150 Hz at 0.2 Hz
#   Chorus: BBD-style, 0.3 Hz rate, 0.003 depth
#   Attack: 30ms (slow — breathing quality)
#   Decay: 100ms to sustain 0.85
#   Release: 150ms
#   Saturation: tanh(x * 1.5) for analog warmth

class_name DarkWaveBass
extends RefCounted

const SAMPLE_RATE = 44100.0

# Moog/Juno analog bass
const DETUNE_CENTS = 7.0           # Slight detune — thickness, not width
const FILTER_BASE_HZ = 450.0      # Low-mid filter — keeps midrange presence
const FILTER_LFO_HZ = 0.2         # Very slow filter sweep
const FILTER_LFO_DEPTH_HZ = 150.0 # Subtle movement
const FILTER_RESONANCE = 0.35     # Moderate resonance — slight growl
const CHORUS_RATE_HZ = 0.3        # Juno BBD chorus rate
const CHORUS_DEPTH = 0.003        # Subtle chorus
const PULSE_WIDTH = 0.40          # Pulse oscillator width
const ATTACK_S = 0.030            # 30ms — slow enough to breathe
const DECAY_S = 0.100             # 100ms decay
const SUSTAIN = 0.85              # High sustain — the bass holds
const RELEASE_S = 0.150           # Short-ish release
const SATURATION = 1.5            # Analog warmth
const LEVEL = 0.42


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
	
	# Juno BBD chorus modulation
	var chorus = sin(2.0 * PI * CHORUS_RATE_HZ * t) * CHORUS_DEPTH
	
	# Oscillator 1: Saw wave
	var detune_ratio = pow(2.0, DETUNE_CENTS / 1200.0)
	var freq_1 = freq * detune_ratio * (1.0 + chorus)
	var saw = fmod(t * freq_1, 1.0) * 2.0 - 1.0
	
	# Oscillator 2: Pulse wave (40% width) — slightly detuned opposite direction
	var freq_2 = freq / detune_ratio * (1.0 - chorus)
	var pulse_phase = fmod(t * freq_2, 1.0)
	var pulse = 1.0 if pulse_phase < PULSE_WIDTH else -1.0
	
	# Mix oscillators
	var output = saw * 0.55 + pulse * 0.45
	
	# Sub-octave sine for low-end weight (subtle)
	output += sin(2.0 * PI * freq * 0.5 * t) * 0.2
	
	# Low-pass filter with LFO modulation (simulated via envelope shaping)
	# The LFO slowly opens and closes the brightness
	var filter_lfo = sin(2.0 * PI * FILTER_LFO_HZ * t) * FILTER_LFO_DEPTH_HZ
	var _cutoff = FILTER_BASE_HZ + filter_lfo
	# Simple brightness control via harmonic content shaping
	var brightness = clampf((_cutoff) / (freq * 8.0), 0.0, 1.0)
	output = output * brightness + sin(2.0 * PI * freq * t) * (1.0 - brightness) * 0.5
	
	# Analog saturation — tanh soft clipping
	output = tanh(output * SATURATION)
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 10.0, 0.0)
