# FMPianoGenerator.gd
# Generates high-quality FM Electric Piano samples.
# Optimized for "Music for Airports" style ambient loops.
# Clean, bell-like tones floating in reverberant space.

extends RefCounted
class_name FMPianoGenerator

const SAMPLE_RATE = 44100

# FM Parameters - Gentle settings for ambient clarity
const MOD_RATIO = 2.0       # Lower ratio for warmer tone
const MOD_INDEX_BASE = 0.05  # Reduced base modulation
const MOD_INDEX_VEL = 0.25   # Less velocity sensitivity for consistency

static func generate_note(frequency: float, velocity: float = 0.7, sustain_time: float = 4.0) -> AudioStreamWAV:
	# "Music for Airports" style: long, gentle, floating tones
	# Allow extra time for natural exponential decay

	var duration = sustain_time + 2.0
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)

	# Gentle envelope for ambient style
	var attack = 0.08  # Slightly longer attack for softness
	var decay = sustain_time * 1.5  # Extended decay for floatiness

	var mod_decay = 0.8  # Longer modulator decay for warmth

	# Softer LPF for ambient warmth
	var last_lpf = 0.0
	var lp_alpha = 0.08  # Lower alpha = more filtering = warmer

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE

		# 1. Carrier Envelope - Exponential decay for natural piano feel
		var car_amp = 0.0
		if t < attack:
			# Smooth attack curve
			var x = t / attack
			car_amp = x * x * (3.0 - 2.0 * x)  # Smoothstep
		else:
			# Exponential decay - much more natural
			var dt = t - attack
			car_amp = exp(-dt / (decay * 0.5))  # Exponential falloff

		car_amp = maxf(car_amp, 0.0)

		# 2. Modulator Envelope - Controls brightness over time
		var mod_amp = 0.0
		if t < attack:
			var x = t / attack
			mod_amp = x * x * (3.0 - 2.0 * x)
		else:
			var dt = t - attack
			# Faster modulator decay = tone gets purer over time
			mod_amp = exp(-dt / (mod_decay * 0.3))

		mod_amp = maxf(mod_amp, 0.0)

		# 3. FM Synthesis - Clean bell-like tone
		var mod_idx = MOD_INDEX_BASE + (MOD_INDEX_VEL * velocity * 0.5)

		var phase = frequency * t
		var fm_phase = frequency * MOD_RATIO * t

		var mod_out = sin(fm_phase * TAU) * mod_idx * mod_amp
		var carrier = sin((phase * TAU) + mod_out)

		# Add subtle second harmonic for warmth
		var second_harmonic = sin(phase * TAU * 2.0) * 0.08 * car_amp

		var sample_mix = (carrier + second_harmonic) * car_amp * velocity * 0.7

		# 4. Gentle Low Pass Filter
		last_lpf = lerpf(last_lpf, sample_mix, lp_alpha)
		sample_mix = last_lpf

		# Soft saturation instead of hard clipping
		sample_mix = tanh(sample_mix * 1.2) * 0.8

		# Convert to 16-bit
		var sample_int = int(sample_mix * 32767.0)
		var byte_idx = i * 2
		data[byte_idx] = sample_int & 0xFF
		data[byte_idx + 1] = (sample_int >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

