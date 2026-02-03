# Kraftwerk Vocoder - Robot Voice
# Research: kraftwerk.md
#
# Character: Robotic, synthesized voice texture
# Source: Sennheiser VSM201 Vocoder
#
# FROM RESEARCH:
# "Sennheiser VSM201 Vocoder - Signature robot voice sound"

class_name KraftwerkVocoder
extends RefCounted

const SAMPLE_RATE = 44100.0

const BANDS = 8                   # Vocoder bands
const LEVEL = 0.12


static func generate(t: float, freq: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 1.0:
		return 0.0
	
	# Envelope
	var env = 1.0
	if dt < 0.1:
		env = dt / 0.1
	elif dt > 0.8:
		env = (1.0 - dt) / 0.2
	
	var output = 0.0
	
	# Simulate vocoder bands with harmonics
	for i in range(BANDS):
		var harmonic = float(i + 1)
		var band_freq = freq * harmonic
		
		# Each band has slight different envelope timing
		var band_env = sin(dt * (2.0 + i * 0.3)) * 0.3 + 0.7
		
		output += sin(2.0 * PI * band_freq * t) * band_env / harmonic
	
	output /= BANDS * 0.5
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 1.0
