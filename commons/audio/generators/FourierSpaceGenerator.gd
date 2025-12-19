extends Node

# Generator for space-connected Fourier Transform sounds

func create_fourier_drone(wheels: Array) -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 2.0  # Length of the loop
	var num_samples = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples
	
	var data = PackedByteArray()
	data.resize(num_samples * 2) # 16-bit
	
	# Base frequency for mapping (Visual freq 1.0 -> 110Hz or similar)
	var base_carrier = 110.0
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var mixed_sample = 0.0
		
		# Sum visual harmonics
		for wheel in wheels:
			var freq = wheel.get("freq", 1.0)
			var radius = wheel.get("radius", 1.0)
			var phase = wheel.get("phase", 0.0)
			
			# Map visual frequency to audio range
			# We use the wheel frequency as a harmonic multiplier
			var audio_freq = base_carrier * freq
			
			# Additive synthesis
			# Amplitude is modulated by radius (larger wheels are louder/deeper)
			var amplitude = radius * 0.25 # Normalize to avoid clipping
			
			# Sine wave with phase offset
			mixed_sample += sin(2.0 * PI * audio_freq * t + phase) * amplitude
			
		# Complexity: Add a subtle LFO based on the sum of phases/rotation
		var space_lfo = sin(2.0 * PI * 0.5 * t) * 0.1
		mixed_sample *= (0.9 + space_lfo)
		
		# Clamp and convert to 16-bit PCM
		var int_sample = int(clamp(mixed_sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_sample)
		
	stream.data = data
	return stream

func create_nebula_pad() -> AudioStreamWAV:
	# A more ethereal fallback or complementary sound
	# Using tri-waves for a softer, breathier space feel
	var sample_rate = 44100
	var duration = 4.0
	var num_samples = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = num_samples
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var sample = 0.0
		
		# Harmonic series for "nebula" feel
		for h in [1, 1.5, 2.0, 3.01, 4.0]:
			var freq = 55.0 * h
			var tri = 2.0 * abs(2.0 * (freq * t - floor(freq * t + 0.5))) - 1.0
			sample += tri * (0.2 / h)
			
		# Slow filter-like modulation
		var mod = (sin(2.0 * PI * 0.2 * t) + 1.0) * 0.5
		sample *= mod
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_sample)
		
	stream.data = data
	return stream
