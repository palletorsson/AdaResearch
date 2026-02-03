# Detroit Techno Pad - Clean Digital Style
# Research: detroit_techno.md
#
# Character: Cold, clean, precise - NO warmth processing
# Source: Roland Juno-106 style DCO (Digital Controlled Oscillator)
# Processing: CLEAN - no tape, no chorus, no heavy processing
#
# FROM RESEARCH:
# "Digital Pad: ZERO detune, ZERO drift, filter 3500Hz"
# "Attack 0.5s, sustain 0.7"
# "Reverb 40% mix, moderate stereo width (1.1x)"
# "Detroit techno is cleaner than Chicago house"

class_name DetroitPad
extends RefCounted

const SAMPLE_RATE = 44100.0

# Digital Pad Parameters (from research)
const VOICES = 4                  # 4-voice unison
const DETUNE_CENTS = 0.0          # ZERO detune - critical for Detroit
const DRIFT_CENTS = 0.0           # ZERO drift - stable digital
const CUTOFF_HZ = 3500.0          # Bright filter
const RESONANCE = 0.3             # Moderate resonance
const ATTACK_S = 0.5              # Slow attack
const DECAY_S = 0.3               # Short decay
const SUSTAIN = 0.7               # High sustain
const RELEASE_S = 0.8             # Moderate release
const REVERB_MIX = 0.4            # 40% reverb (simulated via slight detune in upper harmonics)
const LEVEL = 0.22


static func generate(t: float, chord_freqs: Array, note_duration: float = 4.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# Envelope
	var env = _get_envelope(dt, note_duration)
	if env <= 0.0:
		return 0.0
	
	var output = 0.0
	
	for freq in chord_freqs:
		# Multiple voices per note - but NO DETUNE (Detroit is precise)
		for v in range(VOICES):
			# All voices at EXACT same pitch (ZERO detune)
			# Only slight phase offset for width
			var phase_offset = float(v) * 0.1
			
			# Saw wave (Juno DCO character)
			var saw = fmod(t * freq + phase_offset, 1.0) * 2.0 - 1.0
			
			# Add octave up for brightness (subtle)
			var saw_oct = fmod(t * freq * 2.0 + phase_offset, 1.0) * 2.0 - 1.0
			
			output += saw * 0.8 + saw_oct * 0.2
	
	output /= chord_freqs.size() * VOICES
	
	# Simple lowpass at 3500Hz (simulated)
	# Just use the base sound - Detroit pads are bright
	
	# NO tape saturation, NO chorus, NO warming
	# Detroit is COLD and DIGITAL
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func _get_envelope(dt: float, note_duration: float) -> float:
	var env = 1.0
	
	# Attack
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	# Decay to sustain
	elif dt < ATTACK_S + DECAY_S:
		var decay_progress = (dt - ATTACK_S) / DECAY_S
		env = 1.0 - (1.0 - SUSTAIN) * decay_progress
	# Sustain
	elif dt < note_duration:
		env = SUSTAIN
	# Release
	else:
		var release_time = dt - note_duration
		env = SUSTAIN * (1.0 - minf(release_time / RELEASE_S, 1.0))
	
	return maxf(env, 0.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	# Simplified for continuous playback
	var env = 1.0
	if t < ATTACK_S:
		env = t / ATTACK_S
	
	var output = 0.0
	for freq in chord_freqs:
		for v in range(VOICES):
			var phase_offset = float(v) * 0.1
			var saw = fmod(t * freq + phase_offset, 1.0) * 2.0 - 1.0
			output += saw
	
	output /= chord_freqs.size() * VOICES
	return clampf(output * env * LEVEL, -1.0, 1.0)
