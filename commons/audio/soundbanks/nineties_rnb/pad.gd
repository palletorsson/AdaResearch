# 90s R&B Pad - JV-1080 Warm Strings
# Character: 6-voice detuned sawtooth with ±8 cents spread, 400ms attack
# Reference: Roland JV-1080 "Warm Strings" — sits underneath, never dominates

class_name NinetiesRnBPad
extends RefCounted

const SAMPLE_RATE = 44100.0
const LEVEL = 0.22
const DEFAULT_DURATION = 4.0
const ATTACK_TIME = 0.4
const RELEASE_TIME = 1.2
const NUM_VOICES = 6
# Detune spread: ±8 cents
const DETUNE_CENTS = [-8.0, -5.0, -2.0, 2.0, 5.0, 8.0]


static func generate(t: float, chord_freqs: Array = [], trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > DEFAULT_DURATION:
		return 0.0
	
	if chord_freqs.is_empty():
		return 0.0
	
	var output = 0.0
	var voice_count = mini(chord_freqs.size(), 4)  # Limit chord voices for clarity
	
	for chord_idx in range(voice_count):
		var base_freq = chord_freqs[chord_idx]
		if base_freq <= 0:
			continue
		
		# === 6 DETUNED VOICES PER NOTE ===
		for voice_idx in range(NUM_VOICES):
			var detune = DETUNE_CENTS[voice_idx]
			var detune_ratio = pow(2.0, detune / 1200.0)
			var freq = base_freq * detune_ratio
			
			# Sawtooth wave via phase
			var phase = fmod(freq * t, 1.0)
			var saw = phase * 2.0 - 1.0
			
			# Reduce higher harmonics for warmth (simple lowpass)
			# Higher voices get slightly more filtered
			var brightness = 0.6 - abs(detune) * 0.02
			saw *= brightness
			
			output += saw
		
		# Slight stereo-like width simulation via phase offset
		var width_mod = sin(2.0 * PI * 0.1 * t + chord_idx * 0.5) * 0.02
		output += width_mod
	
	# Normalize by voice count
	output /= voice_count * NUM_VOICES * 0.7
	
	# === ENVELOPE: 400ms attack, long release ===
	var env = 1.0
	if dt < ATTACK_TIME:
		# Smooth attack curve (not linear)
		env = pow(dt / ATTACK_TIME, 0.7)
	
	var release_start = DEFAULT_DURATION - RELEASE_TIME
	if dt > release_start:
		var release_progress = (dt - release_start) / RELEASE_TIME
		env *= pow(max(0.0, 1.0 - release_progress), 0.8)
	
	# === SUBTLE SLOW CHORUS (JV-1080 character) ===
	var chorus = 1.0 + sin(2.0 * PI * 0.3 * t) * 0.03
	
	return clampf(output * env * chorus * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 0.0)
