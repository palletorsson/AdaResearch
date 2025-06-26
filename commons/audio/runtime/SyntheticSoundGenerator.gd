extends Node
class_name SyntheticSoundGenerator

# This class generates various synthetic sounds for the platform
# using PCM data generation to create unique queer-algorithmic audio

# Sound duration settings
const DETECTION_DURATION: float = 0.8
const LIFT_START_DURATION: float = 1.2
const LIFT_STOP_DURATION: float = 1.0
const WARNING_DURATION: float = 0.4
const AMBIENT_DURATION: float = 2.0

# Technical audio settings
const SAMPLE_RATE: int = 44100
const SAMPLE_SIZE: int = 16  # 16-bit
const MIX_RATE: int = 44100
const STEREO: bool = false

# Unique algorithmic variations
var entropy: float = 0.4  # Controls randomness/noise
var queer_factor: float = 0.7  # Controls harmonic shifting

# Create a detection sound (when player enters platform)
static func create_detection_sound(entropy: float = 0.4, queer_factor: float = 0.7) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	
	# Set audio format
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	
	# Calculate number of samples
	var sample_count = int(DETECTION_DURATION * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 2)  # 2 bytes per sample for 16-bit
	
	# Generate a rising chord with slight detuning for queer aesthetics
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var phase = t / DETECTION_DURATION
		
		# Base frequency that rises
		var base_freq = lerp(220.0, 880.0, phase)
		
		# Create a chord with detuned harmonics
		var sample = 0.0
		sample += 0.5 * sin(2.0 * PI * base_freq * t)
		sample += 0.3 * sin(2.0 * PI * (base_freq * 1.5 + sin(phase * 4.0) * queer_factor * 10.0) * t)
		sample += 0.2 * sin(2.0 * PI * (base_freq * 2.02) * t)  # Slightly detuned octave
		
		# Add noise that decreases over time
		sample += randf_range(-0.3, 0.3) * entropy * (1.0 - phase)
		
		# Apply envelope
		var envelope = sin(phase * PI) if phase < 1.0 else 0.0
		sample *= envelope
		
		# Convert to 16-bit and store
		var sample_int = int(clamp(sample * 32767.0, -32768.0, 32767.0))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	stream.data = data
	return stream

# Create lift start sound (mechanical startup)
static func create_lift_start_sound(entropy: float = 0.4, queer_factor: float = 0.7) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	
	# Set audio format
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	
	# Calculate samples
	var sample_count = int(LIFT_START_DURATION * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	# Generate a mechanical startup sound with accelerating pulse
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var phase = t / LIFT_START_DURATION
		
		# Motor starting frequencies
		var motor_speed = lerp(2.0, 40.0, pow(phase, 2))
		var motor_freq = lerp(40.0, 180.0, pow(phase, 0.5))
		
		# Create a motor-like sound
		var sample = 0.0
		
		# Base drone
		sample += 0.4 * sin(2.0 * PI * motor_freq * t)
		
		# Motor pulses that speed up
		sample += 0.3 * sin(2.0 * PI * motor_speed * t)
		
		# Mechanical clicks
		if fmod(t * motor_speed, 1.0) < 0.2:
			sample += 0.2
		
		# Add gear-like overtones
		sample += 0.2 * sin(2.0 * PI * (motor_freq * 2.7 + sin(phase * 3.0) * queer_factor * 15.0) * t)
		sample += 0.15 * sin(2.0 * PI * (motor_freq * 4.13) * t)
		
		# Add noise component (mechanical friction)
		sample += randf_range(-0.15, 0.15) * entropy * phase
		
		# Envelope: quick fade in, sustain
		var envelope = min(t * 10.0, 1.0)
		sample *= envelope
		
		# Convert to 16-bit
		var sample_int = int(clamp(sample * 32767.0, -32768.0, 32767.0))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	stream.data = data
	return stream

# Create lift loop sound (continuous mechanical movement)
static func create_lift_loop_sound(entropy: float = 0.4, queer_factor: float = 0.7) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	
	# Set audio format
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	
	# For loops, we want a seamless cycle
	var loop_duration = 1.0  # 1 second loop
	var sample_count = int(loop_duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	# Create the steady hum of a platform in motion
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var cycle = t / loop_duration
		
		# Create a consistent mechanical hum
		var sample = 0.0
		
		# Base motor tone
		sample += 0.3 * sin(2.0 * PI * 120.0 * t)
		
		# Harmonic content
		sample += 0.2 * sin(2.0 * PI * 240.0 * t)
		sample += 0.1 * sin(2.0 * PI * 360.0 * t)
		
		# Add slight rhythmic pulsing (for mechanical feel)
		var pulse_rate = 8.0
		sample *= 1.0 + 0.2 * sin(2.0 * PI * pulse_rate * t)
		
		# Queer harmonic modulation - subtle frequency shifts
		sample += 0.15 * sin(2.0 * PI * (130.0 + sin(t * 4.0) * queer_factor * 10.0) * t)
		
		# Add consistent mechanical noise
		sample += randf_range(-0.1, 0.1) * entropy
		
		# Convert to 16-bit
		var sample_int = int(clamp(sample * 32767.0 * 0.7, -32768.0, 32767.0))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	
	return stream

# Create lift stop sound (winding down mechanical sound)
static func create_lift_stop_sound(entropy: float = 0.4, queer_factor: float = 0.7) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	
	# Set audio format
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	
	# Calculate samples
	var sample_count = int(LIFT_STOP_DURATION * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	# Generate a winding down sound
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var phase = t / LIFT_STOP_DURATION
		
		# Decreasing motor frequency
		var motor_freq = lerp(180.0, 40.0, phase)
		var motor_pulse = lerp(20.0, 2.0, phase)
		
		# Create the sound of a motor winding down
		var sample = 0.0
		
		# Base tone that lowers in pitch
		sample += 0.35 * sin(2.0 * PI * motor_freq * t)
		
		# Slowing pulses
		sample += 0.25 * sin(2.0 * PI * motor_pulse * t)
		
		# Add gear-like overtones
		sample += 0.2 * sin(2.0 * PI * (motor_freq * 2.12) * t)
		sample += 0.15 * sin(2.0 * PI * (motor_freq * 3.74 + sin(phase * 2.0) * queer_factor * 12.0) * t)
		
		# Add a subtle thunk at the end
		if phase > 0.8:
			sample += 0.3 * sin(2.0 * PI * 80.0 * (phase - 0.8) / 0.2)
		
		# Add mechanical friction noise that increases then decreases
		var noise_env = sin(phase * PI)
		sample += randf_range(-0.2, 0.2) * entropy * noise_env
		
		# Envelope: sustain then fade out
		var envelope = 1.0 - pow(phase, 4) if phase > 0.7 else 1.0
		sample *= envelope
		
		# Convert to 16-bit
		var sample_int = int(clamp(sample * 32767.0, -32768.0, 32767.0))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	stream.data = data
	return stream

# Create warning sound (repeating alert beep)
static func create_warning_sound(entropy: float = 0.4, queer_factor: float = 0.7) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	
	# Set audio format
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	
	# Make a single beep cycle that will loop
	var sample_count = int(WARNING_DURATION * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	# Generate a warning beep with queer harmonics
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var phase = t / WARNING_DURATION
		
		# Create a warning beep with multiple tones
		var sample = 0.0
		
		# Different structure: first half beep, second half silence
		if phase < 0.5:
			# Main warning tone
			sample += 0.5 * sin(2.0 * PI * 880.0 * t)
			
			# Add dissonant harmonic for urgency
			sample += 0.3 * sin(2.0 * PI * 1046.5 * t)
			
			# Add queer modulation
			sample += 0.2 * sin(2.0 * PI * (933.0 + sin(t * 20.0) * queer_factor * 30.0) * t)
			
			# Brief envelope within the beep
			var beep_env = sin(phase * PI)
			sample *= beep_env
		
		
		# Add subtle noise throughout
		sample += randf_range(-0.1, 0.1) * entropy * (1.0 - phase)
		
		# Convert to 16-bit
		var sample_int = int(clamp(sample * 32767.0, -32768.0, 32767.0))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	
	return stream

# Create ambient sound (subtle electrical hum)
static func create_ambient_sound(entropy: float = 0.4, queer_factor: float = 0.7) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	
	# Set audio format
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	
	# Make a seamless loop
	var sample_count = int(AMBIENT_DURATION * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	# Generate an ambient electrical hum with queer harmonics
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var cycle = t / AMBIENT_DURATION
		
		# Create electrical hum
		var sample = 0.0
		
		# Base electrical tone (50/60Hz hum)
		sample += 0.15 * sin(2.0 * PI * 60.0 * t)
		
		# Harmonic content
		sample += 0.1 * sin(2.0 * PI * 120.0 * t)
		sample += 0.08 * sin(2.0 * PI * 180.0 * t)
		
		# Add electrical whine
		sample += 0.06 * sin(2.0 * PI * 440.0 * t)
		
		# Add queer harmonic modulation - very subtle pitch shifts
		var mod_freq = 3.0 + sin(t * 0.5) * queer_factor * 2.0
		sample += 0.07 * sin(2.0 * PI * (240.0 + sin(t * mod_freq) * 5.0) * t)
		
		# Add subtle electrical noise
		sample += randf_range(-0.05, 0.05) * entropy
		
		# Ensure smooth looping by fading at ends
		if i < MIX_RATE * 0.1:  # First 0.1 seconds
			sample *= float(i) / (MIX_RATE * 0.1)
		elif i > sample_count - MIX_RATE * 0.1:  # Last 0.1 seconds
			sample *= float(sample_count - i) / (MIX_RATE * 0.1)
		
		# Convert to 16-bit
		var sample_int = int(clamp(sample * 32767.0 * 0.8, -32768.0, 32767.0))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	
	return stream
