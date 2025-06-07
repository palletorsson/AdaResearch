# SimpleVRAudioTest.gd
# Quick diagnostic script to test if your audio system works in VR
# Attach this to any node in your VR scene and run

extends Node

func _ready():
	print("=== VR AUDIO QUICK TEST ===")
	
	# Wait for scene to initialize
	await get_tree().create_timer(1.0).timeout
	
	print("Testing audio systems...")
	test_audio_systems()

func test_audio_systems():
	"""Test different audio approaches"""
	
	# Test 1: Your working synthetic sound
	print("Test 1: Synthetic Sound (known working)...")
	test_synthetic_sound()
	
	# Test 2: AudioManager if it exists
	print("Test 2: AudioManager...")
	test_audio_manager()
	
	# Test 3: Direct AudioStreamPlayer
	print("Test 3: Direct AudioStreamPlayer...")
	test_direct_audio()
	
	# Test 4: Check audio buses
	print("Test 4: Audio Bus Info...")
	check_audio_buses()

func test_synthetic_sound():
	"""Test your working synthetic sound"""
	var synth_sound = SyntheticSoundGenerator.create_detection_sound()
	var player = AudioStreamPlayer.new()
	player.stream = synth_sound
	add_child(player)
	player.play()
	
	print("  ✅ Synthetic sound should be audible")
	
	# Clean up after 2 seconds
	await get_tree().create_timer(2.0).timeout
	player.queue_free()

func test_audio_manager():
	"""Test if AudioManager exists and works"""
	var audio_manager = get_node_or_null("/root/AudioManager")
	
	if not audio_manager:
		print("  ❌ AudioManager not found - check if it's in autoloads")
		return
	
	print("  ✅ AudioManager found: %s" % audio_manager.name)
	
	# Test if it has the play methods
	if audio_manager.has_method("play_ui_sound"):
		print("  ✅ AudioManager has play_ui_sound method")
		
		# Try to play a test sound if audio clips exist
		if "audio_clips" in audio_manager and audio_manager.audio_clips.size() > 0:
			var first_sound = audio_manager.audio_clips.keys()[0]
			print("  🔊 Testing sound: %s" % first_sound)
			audio_manager.play_ui_sound(first_sound)
		else:
			print("  ⚠️  AudioManager has no audio clips loaded")
	else:
		print("  ❌ AudioManager missing play_ui_sound method")

func test_direct_audio():
	"""Test direct AudioStreamPlayer"""
	# Create a simple beep programmatically
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100
	
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -10.0  # Not too loud
	add_child(player)
	
	print("  🔊 Testing direct AudioStreamPlayer...")
	player.play()
	
	# Clean up
	await get_tree().create_timer(1.0).timeout
	player.queue_free()

func check_audio_buses():
	"""Check audio bus configuration"""
	print("  Audio Bus Configuration:")
	var bus_count = AudioServer.get_bus_count()
	print("    Total buses: %d" % bus_count)
	
	for i in range(bus_count):
		var bus_name = AudioServer.get_bus_name(i)
		var volume_db = AudioServer.get_bus_volume_db(i)
		var is_muted = AudioServer.is_bus_mute(i)
		print("    Bus %d: '%s' - Volume: %.1f dB - Muted: %s" % [i, bus_name, volume_db, is_muted])

# Call this from your VR scene to test
func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space or Enter
		print("Manual audio test triggered...")
		test_audio_systems()

# Quick access methods
func test_audiostream_from_file(file_path: String):
	"""Test loading and playing an audio file directly"""
	if not ResourceLoader.exists(file_path):
		print("  ❌ Audio file not found: %s" % file_path)
		return
	
	var audio_stream = load(file_path)
	if not audio_stream:
		print("  ❌ Failed to load audio: %s" % file_path)
		return
	
	var player = AudioStreamPlayer.new()
	player.stream = audio_stream
	player.volume_db = -5.0
	add_child(player)
	
	print("  🔊 Testing file: %s" % file_path)
	player.play()
	
	# Auto cleanup
	player.finished.connect(player.queue_free)

# Test specific audio files if you know their paths
func test_known_audio_files():
	"""Test common audio file locations"""
	var test_paths = [
		"res://commons/audio/sfx/test.ogg",
		"res://commons/audio/sfx/test.wav", 
		"res://commons/audio/music/test.ogg",
		"res://audio/test.wav"
	]
	
	for path in test_paths:
		test_audiostream_from_file(path)
		await get_tree().create_timer(1.0).timeout
