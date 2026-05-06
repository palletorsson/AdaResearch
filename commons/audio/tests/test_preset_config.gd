extends SceneTree

func _init():
	print("🧪 Testing 'half_life_science' preset configuration...")
	
	# 1. Load Manifest
	var file = FileAccess.open("res://commons/audio/presets_manifest.json", FileAccess.READ)
	if not file:
		print("❌ Could not open presets_manifest.json")
		quit(1)
		return
		
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error != OK:
		print("❌ JSON Parse Error in manifest: ", json.get_error_message())
		quit(1)
		return
		
	var data = json.data
	if not "presets" in data:
		print("❌ 'presets' key missing in manifest")
		quit(1)
		return
		
	# 2. Check Preset Exists in Manifest
	if not "half_life_science" in data["presets"]:
		print("❌ 'half_life_science' preset NOT found in manifest!")
		quit(1)
		return
	
	print("✅ 'half_life_science' found in manifest.")
	
	# 3. Load Specific Preset File
	var p_file = FileAccess.open("res://commons/audio/presets/half_life_science.json", FileAccess.READ)
	if not p_file:
		print("❌ Could not open presets/half_life_science.json")
		quit(1)
		return
		
	var p_json = JSON.new()
	if p_json.parse(p_file.get_as_text()) != OK:
		print("❌ JSON Parse Error in preset file")
		quit(1)
		return
		
	var preset = p_json.data
	
	# 3. Verify Structure
	if not "continuous_layers" in preset:
		print("❌ 'continuous_layers' missing")
		quit(1)
	if not "random_events" in preset:
		print("❌ 'random_events' missing")
		quit(1)
		
	# 4. Verify Sound IDs
	var sound_ids = []
	for layer in preset["continuous_layers"]:
		sound_ids.append(layer["sound_id"])
	for event in preset["random_events"]:
		for sound in event["sound_pool"]:
			sound_ids.append(sound)
			
	print("🔍 Verifying %d sound IDs..." % sound_ids.size())
	
	# We need to check against AudioSynthesizer enum
	# Since we can't easily access the enum names dynamically in a standalone script without instantiating,
	# we will check if the script parses and constants exist.
	
	var synth_script = load("res://commons/audio/generators/AudioSynthesizer.gd")
	if not synth_script:
		print("❌ Could not load AudioSynthesizer.gd")
		quit(1)
		return
		
	var synth_instance = synth_script.new()
	
	for sound_id in sound_ids:
		if sound_id.begins_with("AudioSynthesizer."):
			var enum_name = sound_id.split(".")[1]
			if enum_name in synth_script.SoundType:
				print("   ✅ Verified: %s" % sound_id)
			else:
				print("   ❌ INVALID SOUND ID: %s (Enum %s not found)" % [sound_id, enum_name])
				quit(1)
		else:
			print("   ⚠️ Skipping verification for non-AudioSynthesizer ID: %s" % sound_id)
			
	print("\n🎉 Verification Successful! The preset is valid.")
	quit(0)
