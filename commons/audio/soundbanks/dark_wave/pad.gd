# Dark Wave Pad - Detuned Eerie Chorus Strings
# Research: dark_wave brief
#
# Character: Detuned, eerie, slow-evolving. Strings-like but unmistakably synthetic.
#   Think Juno-60 pads with chorus engaged — cold, wide, slightly unsettling.
#   This is NOT a warm pad. It's COLD. The detune creates unease, not comfort.
#   The chorus makes it wide but hollow, like sound echoing in an empty cathedral.
#   Reference: Clan of Xymox "A Day" — that hovering, cold string wash
#   Reference: Lebanon Hanover "Gallowdance" — icy, detuned, minimal pad
# Source: Roland Juno-60 with Chorus II engaged / Oberheim OB-X
# Processing: 5-voice saw, 12¢ detune, BBD chorus, LP filter 1800Hz with
#   slow LFO, long attack (1.2s), very long release (2.5s)
#
# Key specs:
#   Oscillators: 5-voice detuned saw (strings-like)
#   Detune: 12 cents — enough for unease, not chaos
#   Chorus: BBD at 0.25 Hz, depth 0.004 — essential Juno character
#   Filter: LP 1800 Hz, LFO 0.15 Hz ±400 Hz — slow breathing
#   Attack: 1.2s (glacial — the pad EMERGES)
#   Sustain: 0.6
#   Release: 2.5s (fades into the reverb tail)

class_name DarkWavePad
extends RefCounted

const SAMPLE_RATE = 44100.0

# Cold Juno-60 strings pad
const VOICES = 5
const DETUNE_CENTS = 12.0          # Eerie detune — cold, not lush
const CHORUS_RATE_HZ = 0.25        # Slow Juno BBD chorus
const CHORUS_DEPTH = 0.004         # Moderate chorus depth
const FILTER_BASE_HZ = 1800.0     # Dark — rolled off highs
const FILTER_LFO_HZ = 0.15        # Very slow filter movement
const FILTER_LFO_DEPTH_HZ = 400.0 # Subtle breathing
const ATTACK_S = 1.2               # Glacial attack — pad emerges from nothing
const SUSTAIN = 0.6                # Not full sustain — some decay
const RELEASE_S = 2.5              # Very long — fades into reverb
const LEVEL = 0.16                 # Bed, not foreground


static func generate(t: float, chord_freqs: Array, note_duration: float = 4.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# Slow envelope — the pad breathes
	var env = 0.0
	if dt < ATTACK_S:
		# Smooth (slightly exponential) attack curve
		var att_progress = dt / ATTACK_S
		env = att_progress * att_progress  # Quadratic — even slower start
	elif dt < note_duration:
		env = SUSTAIN + (1.0 - SUSTAIN) * exp(-(dt - ATTACK_S) * 0.5)
	else:
		var rel_progress = (dt - note_duration) / RELEASE_S
		env = SUSTAIN * maxf(0.0, 1.0 - rel_progress)
	
	if env <= 0.001:
		return 0.0
	
	# BBD chorus modulation
	var chorus = sin(2.0 * PI * CHORUS_RATE_HZ * t) * CHORUS_DEPTH
	
	# Filter LFO — slow breathing
	var filter_mod = sin(2.0 * PI * FILTER_LFO_HZ * t) * FILTER_LFO_DEPTH_HZ
	var cutoff = FILTER_BASE_HZ + filter_mod
	
	var output = 0.0
	
	for freq in chord_freqs:
		var chord_out = 0.0
		
		# 5-voice detuned saw — strings character
		for i in range(VOICES):
			var detune = (float(i) - 2.0) * DETUNE_CENTS / 1200.0
			var voice_freq = freq * pow(2.0, detune) * (1.0 + chorus)
			var saw = fmod(t * voice_freq, 1.0) * 2.0 - 1.0
			chord_out += saw
		
		chord_out /= VOICES
		
		# Simple brightness shaping based on filter cutoff
		var brightness = clampf(cutoff / (freq * 10.0), 0.0, 1.0)
		chord_out *= brightness
		
		output += chord_out
	
	output /= maxf(chord_freqs.size(), 1)
	
	# Slight phaser-like movement for extra eeriness
	output *= 0.9 + sin(2.0 * PI * 0.08 * t) * 0.1
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 10.0, 0.0)
