# AudioSynthesizer.gd
# Path: res://commons/audio/AudioSynthesizer.gd
# Chapter: Audio - Procedural Sound Generation
# Creates and saves synthesized sounds for the cube system

extends RefCounted
class_name AudioSynthesizer

# Audio configuration
const SAMPLE_RATE = 44100
const CHANNELS = 1

# Sound type definitions
enum SoundType {
	PICKUP_MARIO,      # Mario-style pickup sound
	TELEPORT_DRONE,    # Electrostatic synth drone
	LIFT_BASS_PULSE,   # Bass pulse for lifts
	GHOST_DRONE,       # Ghostly atmospheric drone
	MELODIC_DRONE      # Beautiful melodic drone
}

# Sound generation functions
static func generate_sound(type: SoundType, duration: float = 1.0) -> AudioStreamWAV:
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	match type:
		SoundType.PICKUP_MARIO:
			_generate_pickup_sound(data, sample_count)
		SoundType.TELEPORT_DRONE:
			_generate_teleport_drone(data, sample_count)
		SoundType.LIFT_BASS_PULSE:
			_generate_bass_pulse(data, sample_count)
		SoundType.GHOST_DRONE:
			_generate_ghost_drone(data, sample_count)
		SoundType.MELODIC_DRONE:
			_generate_melodic_drone(data, sample_count)
	
	return _create_audio_stream(data)

static func _generate_pickup_sound(data: PackedFloat32Array, sample_count: int):
	# Mario-style pickup: rising frequency with envelope
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Rising frequency from 440Hz to 880Hz
		var freq = 440.0 + (440.0 * progress)
		
		# Sharp attack, quick decay envelope
		var envelope = exp(-progress * 8.0)
		
		# Square wave for retro feel
		var wave = 1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0
		
		data[i] = wave * envelope * 0.3

static func _generate_teleport_drone(data: PackedFloat32Array, sample_count: int):
	# Electrostatic drone with modulation - harsh sawtooth with noise
	var duration = float(sample_count) / SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Base frequency with slow modulation
		var base_freq = 220.0
		var mod_freq = 0.5
		var freq = base_freq + sin(2.0 * PI * mod_freq * t) * 30.0
		
		# Sawtooth wave for harsh sound
		var wave = 2.0 * (freq * t - floor(freq * t)) - 1.0
		
		# Add deterministic noise for electrostatic feel (not random for looping)
		var noise_t = t * 1000.0  # High frequency noise
		var noise = sin(noise_t) * 0.3 + sin(noise_t * 1.7) * 0.2 + sin(noise_t * 2.3) * 0.1
		noise = noise * 0.2
		
		# Smooth envelope: fade in -> stay -> fade out -> silence
		var envelope = 0.0
		if progress < 0.05:  # Quick fade in first 5%
			envelope = progress / 0.05
		elif progress < 0.9:  # Stay steady for most of the time
			envelope = 1.0
		elif progress < 0.98:  # Quick fade out
			envelope = (0.98 - progress) / 0.08
		else:  # Silent for last 2%
			envelope = 0.0
		
		# Apply smooth curve to envelope to avoid clicks
		envelope = envelope * envelope * (3.0 - 2.0 * envelope)  # Smoothstep
		
		data[i] = (wave + noise) * 0.2 * envelope

static func _generate_bass_pulse(data: PackedFloat32Array, sample_count: int):
	# Deep bass pulse for lifts
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Very low frequency
		var freq = 60.0
		
		# Pulse envelope - sharp attack, slow decay
		var pulse_rate = 2.0  # 2 Hz pulse
		var pulse = abs(sin(2.0 * PI * pulse_rate * t))
		var envelope = exp(-t * 2.0)
		
		# Sine wave for smooth bass
		var wave = sin(2.0 * PI * freq * t)
		
		data[i] = wave * pulse * envelope * 0.4

static func _generate_ghost_drone(data: PackedFloat32Array, sample_count: int):
	# Ghostly atmospheric drone - designed for seamless looping
	var duration = float(sample_count) / SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Multiple frequency layers
		var freq1 = 110.0
		var freq2 = 165.0  # Perfect fifth
		var freq3 = 220.0  # Octave
		
		# Slow amplitude modulation that completes full cycles
		var mod_freq = 2.0 / duration  # 2 complete modulation cycles per loop
		var mod = sin(2.0 * PI * mod_freq * t) * 0.3 + 0.7
		
		# Layered sine waves
		var wave = sin(2.0 * PI * freq1 * t) * 0.4
		wave += sin(2.0 * PI * freq2 * t) * 0.3
		wave += sin(2.0 * PI * freq3 * t) * 0.2
		
		data[i] = wave * mod * 0.15

static func _generate_melodic_drone(data: PackedFloat32Array, sample_count: int):
	# Beautiful melodic drone with harmony
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Harmonic series based on 220Hz
		var fundamental = 220.0
		var wave = 0.0
		
		# Add harmonics with decreasing amplitude
		wave += sin(2.0 * PI * fundamental * t) * 0.4        # Fundamental
		wave += sin(2.0 * PI * fundamental * 1.5 * t) * 0.3  # Perfect fifth
		wave += sin(2.0 * PI * fundamental * 2.0 * t) * 0.2  # Octave
		wave += sin(2.0 * PI * fundamental * 3.0 * t) * 0.1  # Perfect fifth above
		
		# Gentle tremolo
		var tremolo = sin(2.0 * PI * 4.0 * t) * 0.1 + 0.9
		
		data[i] = wave * tremolo * 0.2

static func _create_audio_stream(data: PackedFloat32Array) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD  # Enable looping
	stream.loop_begin = 0
	stream.loop_end = data.size()
	
	# Convert float data to 16-bit integers (use PackedByteArray directly)
	var byte_array = PackedByteArray()
	byte_array.resize(data.size() * 2)  # 2 bytes per 16-bit sample
	
	for i in range(data.size()):
		var sample = int(clamp(data[i], -1.0, 1.0) * 32767.0)  # Clamp and convert to 16-bit
		var byte_index = i * 2
		
		# Little-endian 16-bit encoding
		byte_array[byte_index] = sample & 0xFF          # Low byte
		byte_array[byte_index + 1] = (sample >> 8) & 0xFF  # High byte
	
	stream.data = byte_array
	return stream

# Save sounds to disk for reuse in the same directory
static func generate_and_save_all_sounds():
	print("AudioSynthesizer: Generating all sounds...")
	
	var sounds = {
		"pickup_mario": generate_sound(SoundType.PICKUP_MARIO, 0.5),
		"teleport_drone": generate_sound(SoundType.TELEPORT_DRONE, 3.0),
		"lift_bass_pulse": generate_sound(SoundType.LIFT_BASS_PULSE, 2.0),
		"ghost_drone": generate_sound(SoundType.GHOST_DRONE, 4.0),
		"melodic_drone": generate_sound(SoundType.MELODIC_DRONE, 5.0)
	}
	
	# Save in the same directory as this script (res://commons/audio/)
	var script_path = "res://commons/audio/"
	
	# Ensure the audio directory exists
	var dir = DirAccess.open("res://commons/")
	if not dir:
		print("AudioSynthesizer: ERROR - Cannot access res://commons/ directory")
		return
		
	if not dir.dir_exists("audio"):
		dir.make_dir("audio")
		print("AudioSynthesizer: Created audio directory at res://commons/audio/")
	
	for sound_name in sounds.keys():
		var file_path = script_path + sound_name + ".tres"
		var save_result = ResourceSaver.save(sounds[sound_name], file_path)
		if save_result == OK:
			print("  ✅ Saved: %s" % file_path)
		else:
			print("  ❌ Failed to save: %s (Error: %d)" % [file_path, save_result])
	
	print("AudioSynthesizer: All sounds generated and saved as .tres resources to res://commons/audio/!")

# Utility function to get all available sound types for UI/debugging
static func get_all_sound_types() -> Array[SoundType]:
	return [
		SoundType.PICKUP_MARIO,
		SoundType.TELEPORT_DRONE, 
		SoundType.LIFT_BASS_PULSE,
		SoundType.GHOST_DRONE,
		SoundType.MELODIC_DRONE
	]

# Get human-readable name for a sound type
static func get_sound_type_name(type: SoundType) -> String:
	match type:
		SoundType.PICKUP_MARIO:
			return "Mario Pickup"
		SoundType.TELEPORT_DRONE:
			return "Teleport Drone"
		SoundType.LIFT_BASS_PULSE:
			return "Bass Pulse"
		SoundType.GHOST_DRONE:
			return "Ghost Drone"
		SoundType.MELODIC_DRONE:
			return "Melodic Drone"
		_:
			return "Unknown Sound"
