extends Node

class_name BubbleSoundSynthesizer

# Parameters for sound synthesis
@export var sample_rate: int = 44100  # Standard audio sample rate
@export var min_bubble_duration: float = 0.1  # Minimum bubble sound duration in seconds
@export var max_bubble_duration: float = 0.4  # Maximum bubble sound duration in seconds
@export var min_frequency: float = 400.0  # Minimum bubble frequency (Hz)
@export var max_frequency: float = 1200.0  # Maximum bubble frequency (Hz)
@export var amplitude: float = 0.5  # Volume of the bubble sound (0.0 to 1.0)
@export var release_time: float = 0.1  # Envelope release time in seconds

# Generates a bubble sound effect and returns it as an AudioStreamWAV
func generate_bubble_sound(size_factor: float = 0.5) -> AudioStreamWAV:
	# Calculate parameters based on bubble size (0.0 = small, 1.0 = large)
	var duration = lerp(min_bubble_duration, max_bubble_duration, size_factor)
	var base_frequency = lerp(max_frequency, min_frequency, size_factor)  # Smaller bubbles have higher pitch
	
	# Create a new AudioStreamWAV
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	# Calculate number of samples needed
	var num_samples = int(duration * sample_rate)
	
	# Create PCM16 data array (2 bytes per sample)
	var data = PackedByteArray()
	data.resize(num_samples * 2)  # 16-bit = 2 bytes per sample
	
	# Generate bubble sound waveform
	for i in range(num_samples):
		var t = float(i) / sample_rate  # Current time in seconds
		var envelope = 1.0
		
		# Apply release envelope
		if t > (duration - release_time):
			envelope = 1.0 - (t - (duration - release_time)) / release_time
			
		# Add some frequency modulation to simulate bubble "pop" or wobble
		var freq_mod = 1.0 + 0.2 * exp(-t * 10.0) * sin(t * 15.0)
		var freq = base_frequency * freq_mod
		
		# Apply bubbling effect using frequency modulation
		var bubble_effect = sin(t * 30.0) * exp(-t * 5.0) * 0.2
		
		# Combine sine wave with noise and bubbling effect
		var sample_value = sin(TAU * freq * t) * amplitude * envelope
		sample_value += randf_range(-0.05, 0.05) * envelope  # Add a little noise
		sample_value += bubble_effect * envelope
		
		# Apply some distortion for more "bubbly" character
		sample_value = tanh(sample_value * 1.5) * 0.7
		
		# Convert to 16-bit PCM
		var sample_int = int(clamp(sample_value, -1.0, 1.0) * 32767)
		
		# Set PCM16 data (little-endian)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	# Set the PCM data to the stream
	stream.data = data
	
	return stream

# Generate and return multiple variations of bubble sounds
func generate_bubble_sound_set(count: int = 5) -> Array[AudioStreamWAV]:
	var sound_set: Array[AudioStreamWAV] = []
	
	for i in range(count):
		var size_factor = float(i) / float(count - 1) if count > 1 else 0.5
		var variation_factor = randf_range(-0.2, 0.2)  # Add some randomness
		var effective_size = clamp(size_factor + variation_factor, 0.0, 1.0)
		
		sound_set.append(generate_bubble_sound(effective_size))
	
	return sound_set
