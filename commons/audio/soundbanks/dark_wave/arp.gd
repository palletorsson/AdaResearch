# Dark Wave Arp - Cold Hypnotic Sequence
# Research: dark_wave brief
#
# Character: Cold, repetitive, hypnotic 16th note arpeggios. THE pulse of dark wave.
#   Thin, filtered, slightly detuned. This is the mechanical heartbeat —
#   relentless, inhuman, mesmerizing. NOT bright like synthwave arps.
#   It's filtered DOWN, living in the mid-highs, cold and distant.
#   Reference: She Past Away "Kasvetli Kutlama" — that cold, relentless arp
#   Reference: Bauhaus "Bela Lugosi's Dead" — repetitive, hypnotic patterns
#   Reference: Clan of Xymox "Stranger" — thin, chorused sequence
# Source: Roland Juno-106 or SH-101 with chorus, through delay
# Processing: 3-voice detuned pulse, LP filter 2200Hz, BBD chorus,
#   very short notes (staccato), delay (dotted 8th)
#
# Key specs:
#   Oscillators: 3-voice detuned pulse wave (width 0.35)
#   Detune: 8 cents — slight coldness
#   Filter: LP 2200 Hz — filtered, not bright
#   Chorus: 0.4 Hz, depth 0.003 — shimmer
#   Attack: 1ms (instant)
#   Decay: 80ms
#   Sustain: 0.3 (the notes are mostly decay — staccato feel)
#   Duration per note: ~150ms (16th note at 120 BPM = 125ms)
#   Character: cold, thin, mechanical, hypnotic

class_name DarkWaveArp
extends RefCounted

const SAMPLE_RATE = 44100.0

# Cold hypnotic arpeggio
const VOICES = 3
const DETUNE_CENTS = 8.0           # Slight cold detune
const PULSE_WIDTH = 0.35           # Thin pulse — nasal, hollow
const FILTER_CUTOFF_HZ = 2200.0   # Filtered — not bright
const CHORUS_RATE_HZ = 0.4        # BBD chorus shimmer
const CHORUS_DEPTH = 0.003        # Subtle
const ATTACK_S = 0.001             # Instant attack
const DECAY_S = 0.080              # Fast decay — staccato
const SUSTAIN = 0.3                # Low sustain — notes die quickly
const RELEASE_S = 0.060            # Fast release
const LEVEL = 0.18                 # Sits behind bass and pad


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.5:
		return 0.0
	
	# Staccato envelope — notes are short, punchy, cold
	var env = 0.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		env = 1.0 - (1.0 - SUSTAIN) * ((dt - ATTACK_S) / DECAY_S)
	else:
		# Exponential fade from sustain
		env = SUSTAIN * exp(-(dt - ATTACK_S - DECAY_S) * 5.0)
	
	if env < 0.01:
		return 0.0
	
	# BBD chorus modulation
	var chorus = sin(2.0 * PI * CHORUS_RATE_HZ * t) * CHORUS_DEPTH
	
	var output = 0.0
	
	# 3-voice detuned pulse wave
	for i in range(VOICES):
		var detune = (float(i) - 1.0) * DETUNE_CENTS / 1200.0
		var voice_freq = freq * pow(2.0, detune) * (1.0 + chorus)
		var phase = fmod(t * voice_freq, 1.0)
		var pulse = 1.0 if phase < PULSE_WIDTH else -1.0
		output += pulse
	
	output /= VOICES
	
	# Brightness control — filter simulation
	var brightness = clampf(FILTER_CUTOFF_HZ / (freq * 12.0), 0.0, 1.0)
	output *= brightness
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.5
