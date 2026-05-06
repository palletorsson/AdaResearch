extends Node3D

# Test script for TTS integration

const SPEAKER_SCENE = preload("res://commons/scenes/mapobjects/tts_speaker.tscn")

func _ready():
	print("--- Starting TTS Test ---")
	
	# Test 1: Direct Instantiation
	print("Test 1: Direct Instantiation")
	var speaker = SPEAKER_SCENE.instantiate()
	speaker.message = "Hello, this is a test of the text to speech system."
	add_child(speaker)
	print("Speaker added with message: '%s'" % speaker.message)
	
	# Test 2: Simulating Grid Parsing via UtilityRegistry (Manual Check)
	print("\nTest 2: Registry Check")
	var registry_info = UtilityRegistry.get_utility_info("tts")
	if not registry_info.is_empty():
		print("✅ Registry found 'tts': %s" % registry_info)
	else:
		print("❌ Registry missing 'tts'")
	
	print("\nPlease listen for audio...")
