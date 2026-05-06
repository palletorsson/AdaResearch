# Burial Vocal Sample - Pitched Down R&B
# Research: burial.md
#
# Character: Ghostly, pitched-down, timestretched R&B vocal samples
# Source: Sampled R&B vocals with heavy processing
#
# FROM RESEARCH:
# "Pitched Vocal Sample: pitch shift -5 semitones"
# "Timestretch artifacts intentional"
# "Filter cutoff ~2500Hz, low resonance (0.2)"
# "Heavy reverb (0.5 mix), delay 0.5s 30% mix"
# "Bit crushing 14-bit for slight degradation"

class_name BurialVocal
extends RefCounted

const SAMPLE_RATE = 44100.0

# Pitched vocal parameters
const PITCH_SHIFT_SEMITONES = -5  # Pitched DOWN
const PITCH_RATIO = 0.749         # pow(2, -5/12) ≈ 0.749
const CUTOFF_HZ = 2500.0
const REVERB_MIX = 0.5
const LEVEL = 0.12


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 2.0:
		return 0.0
	
	# Envelope - slow attack, long tail
	var env = 1.0
	if dt < 0.3:
		env = dt / 0.3
	elif dt > 1.5:
		env = 1.0 - (dt - 1.5) / 0.5
	
	# Pitched down frequency
	var pitched_freq = freq * PITCH_RATIO
	
	# Simulate vocal formants with multiple sines
	var vocal = 0.0
	vocal += sin(2.0 * PI * pitched_freq * t) * 0.5
	vocal += sin(2.0 * PI * pitched_freq * 1.5 * t) * 0.3  # First formant
	vocal += sin(2.0 * PI * pitched_freq * 2.5 * t) * 0.2  # Second formant
	
	# Add some breathiness
	vocal += (randf() * 2.0 - 1.0) * 0.05
	
	# Bit crushing (14-bit simulation)
	vocal = floor(vocal * 8192.0) / 8192.0
	
	return clampf(vocal * env * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 2.0
