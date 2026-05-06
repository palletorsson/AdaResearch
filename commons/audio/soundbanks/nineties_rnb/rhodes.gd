# 90s R&B Rhodes Electric Piano - The Signature Sound
# Character: Fender Rhodes Mark I with FM bell tones, 5.5Hz tremolo
# Reference: D'Angelo, Jodeci, Guy — THE 90s R&B keyboard sound

class_name NinetiesRnBRhodes
extends RefCounted

const SAMPLE_RATE = 44100.0
const ATTACK_S = 0.008
const DECAY_S = 0.4
const SUSTAIN = 0.35
const RELEASE_S = 1.0
const LEVEL = 0.28
const TREMOLO_RATE = 5.5  # Classic Rhodes tremolo speed


static func generate(t: float, chord_freqs: Array = [], trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 2.5:
		return 0.0
	
	if chord_freqs.is_empty():
		return 0.0
	
	# === ADSR ENVELOPE ===
	var env = 0.0
	if dt < ATTACK_S:
		env = dt / ATTACK_S
	elif dt < ATTACK_S + DECAY_S:
		var decay_progress = (dt - ATTACK_S) / DECAY_S
		env = 1.0 - (1.0 - SUSTAIN) * decay_progress
	else:
		var release_t = dt - ATTACK_S - DECAY_S
		env = SUSTAIN * exp(-release_t / RELEASE_S)
	
	# === TREMOLO (5.5Hz) ===
	# Asymmetric tremolo (more authentic Rhodes character)
	var tremolo_phase = 2.0 * PI * TREMOLO_RATE * t
	var tremolo = 0.82 + sin(tremolo_phase) * 0.18
	
	var output = 0.0
	var voice_count = mini(chord_freqs.size(), 5)  # Limit polyphony
	
	for i in range(voice_count):
		var freq = chord_freqs[i]
		if freq <= 0:
			continue
		
		# === FM SYNTHESIS (Rhodes tine + tone bar) ===
		# Modulator: higher partial with velocity-sensitive depth
		var mod_ratio = 1.0  # 1:1 for electric piano character
		var mod_freq = freq * mod_ratio
		var mod_index = 2.5 * exp(-dt * 4.0)  # Index decreases over time (bell decay)
		var modulator = sin(2.0 * PI * mod_freq * t) * mod_index
		
		# Carrier: fundamental with FM
		var carrier = sin(2.0 * PI * freq * t + modulator)
		
		# === BELL COMPONENT (tine attack) ===
		# Sharp bell overtone that decays quickly
		var bell_freq = freq * 2.0
		var bell = sin(2.0 * PI * bell_freq * t) * exp(-dt * 12.0) * 0.35
		
		# Second bell partial (adds shimmer)
		var bell2 = sin(2.0 * PI * freq * 3.0 * t) * exp(-dt * 18.0) * 0.15
		
		# === BARK (key noise on attack) ===
		var bark = 0.0
		if dt < 0.015:
			var bark_env = 1.0 - dt / 0.015
			bark = sin(2.0 * PI * freq * 7.0 * dt) * bark_env * 0.12
		
		# Combine with lower voices slightly louder (natural piano balance)
		var voice_level = 1.0 - (float(i) / voice_count) * 0.15
		output += (carrier * 0.55 + bell + bell2 + bark) * voice_level
	
	output /= voice_count * 1.1
	
	return clampf(output * env * tremolo * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 0.0)


static func get_duration() -> float:
	return 2.5
