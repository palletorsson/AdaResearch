# DuoSynthGenerator.gd
# Generates high-quality Dual-Voice samples (Sawtooth + Sine).
# Reference-matched to Tone.js DuoSynth logic.

extends RefCounted
class_name DuoSynthGenerator

const SAMPLE_RATE = 44100

# Oscillator harmonics and vibrato
const VIBRATO_RATE = 0.5
const VIBRATO_AMOUNT = 0.1
const HARMONICITY = 1.0

# EQ Bands (Centers from user snippet)
const EQ_FREQS = [
	100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250,
	1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000
]

static func generate_note(frequency: float, velocity: float = 0.7, sustain_time: float = 4.0, attack_time: float = 0.1) -> AudioStreamWAV:
	var attack = attack_time
	var release = sustain_time 
	var duration = attack + release + 1.0
	var sample_count = int(SAMPLE_RATE * duration)
	
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	# EQ Coefficients Calculation (Peaking Filters)
	var filters = []
	var Q = 4.31
	var GAIN_DB = 1.0 # Subtle boost per band for "Better Harmonics"
	var A = pow(10.0, GAIN_DB / 40.0)
	
	for freq in EQ_FREQS:
		var omega = 2.0 * PI * freq / SAMPLE_RATE
		var sn = sin(omega)
		var cs = cos(omega)
		var alpha = sn / (2.0 * Q)
		
		var b0 = 1.0 + alpha * A
		var b1 = -2.0 * cs
		var b2 = 1.0 - alpha * A
		var a0 = 1.0 + alpha / A
		var a1 = -2.0 * cs
		var a2 = 1.0 - alpha / A
		
		filters.append({
			"b0": b0/a0, "b1": b1/a0, "b2": b2/a0,
			"a1": a1/a0, "a2": a2/a0,
			"x1": 0.0, "x2": 0.0, "y1": 0.0, "y2": 0.0
		})

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# 1. Envelopes (Using power curves for "Ephemeral" quality)
		var env = 0.0
		if t < attack:
			# Quadratic onset (slow start)
			var x = t / attack
			env = x * x
		else:
			# Cubic decay for ghostly tail
			var release_t = t - attack
			var decay_factor = release_t / release
			env = pow(max(0.0, 1.0 - decay_factor), 3.0)
		
		# 2. Vibrato
		var vib = sin(t * VIBRATO_RATE * TAU) * VIBRATO_AMOUNT
		var current_freq = frequency * (1.0 + vib)
		
		# 3. Oscillators
		# Voice 0: Sawtooth
		var phase0 = fmod(t * current_freq, 1.0)
		var v0 = (phase0 * 2.0) - 1.0
		
		# Voice 1: Sine
		var v1 = sin(t * current_freq * HARMONICITY * TAU)
		
		# Initial Mix
		var sample_mix = (v0 * 0.4 + v1 * 0.6) * env * velocity
		
		# 4. Apply 21-Band EQ Peaking Filters
		for f in filters:
			var out = f.b0 * sample_mix + f.b1 * f.x1 + f.b2 * f.x2 - f.a1 * f.y1 - f.a2 * f.y2
			f.x2 = f.x1
			f.x1 = sample_mix
			f.y2 = f.y1
			f.y1 = out
			sample_mix = out
		
		# Final Warmth LPF (Gentle)
		# last_y = lerp(last_y, sample_mix, 0.2)
		
		# Convert to 16-bit
		var sample_int = int(clamp(sample_mix, -1.0, 1.0) * 32767.0)
		var byte_idx = i * 2
		data[byte_idx] = sample_int & 0xFF
		data[byte_idx + 1] = (sample_int >> 8) & 0xFF
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
