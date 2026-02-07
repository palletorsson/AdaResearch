# 90s R&B Bass - Moog Minimoog Sub
# Character: Deep, round sub bass with filter envelope — the Teddy Riley foundation
# Reference: Guy, Blackstreet, Boyz II Men — that fat bottom end

class_name NinetiesRnBBass
extends RefCounted

const SAMPLE_RATE = 44100.0
const LEVEL = 0.68


static func generate(t: float, freq: float, note_duration: float = 0.8, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > note_duration:
		return 0.0
	
	# Drop an octave for sub bass character
	if freq > 100.0:
		freq *= 0.5
	
	# === SQUARE WAVE (main Moog character) ===
	# Band-limited square approximation
	var phase = fmod(freq * t, 1.0)
	var square = 0.0
	# First 5 odd harmonics for smooth square
	for h in range(1, 10, 2):
		var harm_freq = freq * h
		if harm_freq > 8000.0:
			break
		square += sin(2.0 * PI * harm_freq * t) / h
	square *= 4.0 / PI * 0.4
	
	# === SUB SINE (one octave down) ===
	var sub = sin(2.0 * PI * freq * 0.5 * t) * 0.55
	
	# === FILTER ENVELOPE (Moog ladder character) ===
	# Attack 10ms, Decay 300ms, Sustain 0.4
	var filter_env = 0.0
	var attack_time = 0.01
	var decay_time = 0.3
	var filter_sustain = 0.4
	
	if dt < attack_time:
		filter_env = dt / attack_time
	elif dt < attack_time + decay_time:
		var decay_progress = (dt - attack_time) / decay_time
		filter_env = 1.0 - (1.0 - filter_sustain) * decay_progress
	else:
		filter_env = filter_sustain
	
	# Apply filter (cutoff modulation)
	# Higher filter_env = more harmonics pass through
	var brightness = 0.3 + filter_env * 0.5
	
	# Simple lowpass simulation via harmonic reduction
	var filtered_square = square * brightness
	
	# Mix: square provides presence, sub provides weight
	var mixed = filtered_square + sub
	
	# === AMP ENVELOPE ===
	# Soft attack, sustained, natural release
	var amp = 1.0
	var amp_attack = 0.012
	var release_start = note_duration - 0.15
	
	if dt < amp_attack:
		amp = dt / amp_attack
	elif dt > release_start:
		amp = pow(max(0.0, 1.0 - (dt - release_start) / 0.15), 0.8)
	
	# === SUBTLE GLIDE (Moog portamento feel) ===
	# Pitch slightly rises at attack for that Moog character
	var pitch_env = 1.0
	if dt < 0.02:
		pitch_env = 0.97 + 0.03 * (dt / 0.02)  # 3% pitch rise over 20ms
	
	return clampf(mixed * amp * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq: float) -> float:
	return generate(t, freq, 0.8, 0.0)
