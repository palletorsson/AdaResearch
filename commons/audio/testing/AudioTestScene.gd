# ImmediateAudioTest.gd
# This will work immediately without any other scripts
# Attach to any Node3D and run - you'll hear 808/606 sounds right away

extends Node3D

const SAMPLE_RATE = 44100

enum TrackSound {
	DARK_808_KICK,
	ACID_606_HIHAT,
	DARK_808_SUB_BASS,
	AMBIENT_DRONE
}

func _ready():
	print("🎵 IMMEDIATE AUDIO TEST 🎵")
	print("Starting in 1 second...")
	
	await get_tree().create_timer(1.0).timeout
	
	# Test each sound with delays
	test_sound(TrackSound.DARK_808_KICK, "808 Kick")
	await get_tree().create_timer(2.0).timeout
	
	test_sound(TrackSound.ACID_606_HIHAT, "606 Hi-Hat")
	await get_tree().create_timer(1.5).timeout
	
	test_sound(TrackSound.DARK_808_SUB_BASS, "808 Sub Bass")
	await get_tree().create_timer(3.0).timeout
	
	test_sound(TrackSound.AMBIENT_DRONE, "Ambient Drone")
	
	print("🎵 All tests complete! 🎵")

func test_sound(sound_type: TrackSound, name: String):
	print("🔊 Playing: %s" % name)
	
	var player = AudioStreamPlayer.new()
	player.volume_db = 6.0  # Loud so you can hear it
	add_child(player)
	
	var stream = generate_sound(sound_type)
	player.stream = stream
	player.play()
	
	# Remove player after sound finishes
	var duration = get_sound_duration(sound_type)
	await get_tree().create_timer(duration + 0.5).timeout
	player.queue_free()

func generate_sound(sound_type: TrackSound) -> AudioStreamWAV:
	var duration = get_sound_duration(sound_type)
	var sample_count = int(SAMPLE_RATE * duration)
	
	# Create the audio stream
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	
	# Generate audio data
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	# Generate samples based on sound type
	match sound_type:
		TrackSound.DARK_808_KICK:
			generate_808_kick(data, sample_count)
		TrackSound.ACID_606_HIHAT:
			generate_606_hihat(data, sample_count)
		TrackSound.DARK_808_SUB_BASS:
			generate_808_sub_bass(data, sample_count)
		TrackSound.AMBIENT_DRONE:
			generate_ambient_drone(data, sample_count)
	
	stream.data = data
	return stream

func generate_808_kick(data: PackedByteArray, sample_count: int):
	"""Generate classic 808 kick drum"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Pitch envelope: 60Hz dropping to 35Hz
		var freq = 60.0 - (25.0 * pow(progress, 0.3))
		
		# Main sine wave
		var sine = sin(2.0 * PI * freq * t)
		
		# Click attack
		var click = sin(2.0 * PI * 1200.0 * t) * exp(-progress * 80.0) * 0.3
		
		# Envelope
		var envelope = exp(-progress * 4.0)
		
		# Combine and saturate
		var sample = (sine + click) * envelope * 0.7
		sample = tanh(sample * 1.5)  # Soft saturation
		
		# Convert to 16-bit
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func generate_606_hihat(data: PackedByteArray, sample_count: int):
	"""Generate 606-style hi-hat"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# High frequency noise
		var noise = (randf() - 0.5) * 2.0
		
		# Filter sweep
		var filter_freq = 8000.0 - (3000.0 * progress)
		var filtered = noise * sin(2.0 * PI * filter_freq * t / SAMPLE_RATE)
		
		# Sharp envelope
		var envelope = exp(-progress * 15.0)
		
		# Metallic ring
		var ring = sin(2.0 * PI * 12000.0 * t) * envelope * 0.2
		
		var sample = (filtered + ring) * envelope * 0.3
		
		# Convert to 16-bit
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func generate_808_sub_bass(data: PackedByteArray, sample_count: int):
	"""Generate deep 808 sub bass"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Very low frequency
		var freq = 35.0 + sin(2.0 * PI * 0.3 * t) * 5.0
		
		# Pure sine for clean sub
		var sub = sin(2.0 * PI * freq * t)
		
		# Add harmonics
		var harmonic2 = sin(2.0 * PI * freq * 2.0 * t) * 0.1
		var harmonic3 = sin(2.0 * PI * freq * 3.0 * t) * 0.05
		
		# Slow envelope
		var envelope = (1.0 - exp(-progress * 8.0)) * exp(-progress * 0.5)
		
		var sample = (sub + harmonic2 + harmonic3) * envelope * 0.5
		
		# Convert to 16-bit
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func generate_ambient_drone(data: PackedByteArray, sample_count: int):
	"""Generate atmospheric ambient drone"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Multiple frequency layers
		var freq1 = 45.0   # Fundamental
		var freq2 = 90.0   # Octave
		var freq3 = 67.5   # Perfect fifth
		
		# Slow modulation
		var mod = sin(2.0 * PI * 0.13 * t) * 0.3 + 0.7
		
		# Layer tones
		var layer1 = sin(2.0 * PI * freq1 * t) * 0.5
		var layer2 = sin(2.0 * PI * freq2 * t) * 0.3
		var layer3 = sin(2.0 * PI * freq3 * t) * 0.2
		
		# Detuning
		var detune = sin(2.0 * PI * (freq1 + 0.7) * t) * 0.1
		
		var sample = (layer1 + layer2 + layer3 + detune) * mod * 0.3
		
		# Convert to 16-bit
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func get_sound_duration(sound_type: TrackSound) -> float:
	match sound_type:
		TrackSound.DARK_808_KICK:
			return 1.5
		TrackSound.ACID_606_HIHAT:
			return 0.3
		TrackSound.DARK_808_SUB_BASS:
			return 4.0
		TrackSound.AMBIENT_DRONE:
			return 5.0
		_:
			return 1.0

# Manual test functions you can call from console
func play_kick():
	test_sound(TrackSound.DARK_808_KICK, "Manual 808 Kick")

func play_hihat():
	test_sound(TrackSound.ACID_606_HIHAT, "Manual 606 Hi-Hat")

func play_bass():
	test_sound(TrackSound.DARK_808_SUB_BASS, "Manual 808 Sub Bass")

func play_drone():
	test_sound(TrackSound.AMBIENT_DRONE, "Manual Ambient Drone")

func _input(event):
	# Hotkeys for manual testing
	if event.is_action_pressed("ui_accept"):      # Space = Kick
		play_kick()
	elif event.is_action_pressed("ui_select"):   # Enter = Hi-hat
		play_hihat()
	elif event.is_action_pressed("ui_cancel"):   # Escape = Bass
		play_bass()
	elif event.is_action_pressed("ui_left"):     # Left = Drone
		play_drone()
