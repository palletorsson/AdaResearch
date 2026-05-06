# Dark Wave Lead - Thin Reverbed Melody
# Research: dark_wave brief
#
# Character: Rare, sparse. When present, it's a single thin line floating above
#   everything else, drenched in reverb and delay. NOT a "lead synth" in the
#   conventional sense — more like a ghost melody, barely there.
#   Think Siouxsie and the Banshees "Israel" — that single-note melody line
#   that seems to come from another room. Or Clan of Xymox's eerie lead lines.
# Source: Roland SH-101 / Korg MS-20 — monophonic, thin, filtered
# Processing: Single oscillator (saw), LP filter 3000Hz, heavy reverb (hall,
#   pre-delay 50ms, 4s decay), dotted 8th delay (40% feedback), portamento 30ms
#
# Key specs:
#   Oscillator: Single saw wave (thin, exposed)
#   Filter: LP 3000 Hz — present but not bright
#   Portamento: 30ms — slight slide between notes
#   Attack: 50ms (slightly soft entry)
#   Decay: 200ms
#   Sustain: 0.7
#   Release: 800ms (long fade into reverb)
#   Level: LOW — this sits far back in the mix, almost subliminal

class_name DarkWaveLead
extends RefCounted

const SAMPLE_RATE = 44100.0

# Thin ghostly monophonic lead
const FILTER_CUTOFF_HZ = 3000.0   # Present but not bright
const ATTACK_S = 0.050             # Slightly soft — ghost-like entry
const DECAY_S = 0.200              # Medium decay
const SUSTAIN = 0.7                # Holds well when played
const RELEASE_S = 0.800            # Long release — fades into hall reverb
const VIBRATO_RATE_HZ = 4.5       # Subtle vibrato
const VIBRATO_DEPTH_CENTS = 6.0   # Very subtle — just alive, not dramatic
const LEVEL = 0.14                 # Far back in mix — ghostly


static func generate(t: float, freq: float, note_duration: float = 1.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# ADSR envelope with long release
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
	
	# Subtle vibrato — keeps it alive
	var vibrato = sin(2.0 * PI * VIBRATO_RATE_HZ * t) * VIBRATO_DEPTH_CENTS / 1200.0
	var mod_freq = freq * pow(2.0, vibrato)
	
	# Single saw oscillator — exposed, thin
	var saw = fmod(t * mod_freq, 1.0) * 2.0 - 1.0
	
	# Slight harmonic at octave up for presence (very quiet)
	var octave = fmod(t * mod_freq * 2.0, 1.0) * 2.0 - 1.0
	
	var output = saw * 0.85 + octave * 0.15
	
	# Brightness shaping
	var brightness = clampf(FILTER_CUTOFF_HZ / (freq * 15.0), 0.0, 1.0)
	output *= brightness
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 10.0, 0.0)
