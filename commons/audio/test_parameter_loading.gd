# test_parameter_loading.gd
# Test script to verify parameter loading after restructure

extends Node

func _ready():
	print("🧪 Testing parameter loading after restructure...")
	test_enhanced_parameter_loader()
	test_basic_parameter_access()

func test_enhanced_parameter_loader():
	print("\n📂 Testing EnhancedParameterLoader...")
	
	# Test loading all parameters
	var all_params = EnhancedParameterLoader.load_all_parameters()
	print("📊 Total parameters loaded: %d" % all_params.size())
	
	# Test getting available sounds
	var available_sounds = EnhancedParameterLoader.get_available_sounds()
	print("🎵 Available sounds: %s" % available_sounds)
	
	# Test getting specific sound parameters
	if available_sounds.size() > 0:
		var first_sound = available_sounds[0]
		var params = EnhancedParameterLoader.get_sound_parameters(first_sound)
		print("🎛️ Parameters for '%s': %d params" % [first_sound, params.size()])
		
		# Show first few parameters
		var param_names = params.keys()
		for i in range(min(3, param_names.size())):
			var param_name = param_names[i]
			var param_value = params[param_name]
			print("   - %s: %s" % [param_name, param_value])
	
	# Test category detection
	print("\n📁 Testing category detection...")
	for sound in available_sounds.slice(0, 5):  # Test first 5 sounds
		var category = EnhancedParameterLoader.find_sound_category(sound)
		print("   %s → %s category" % [sound, category])

func test_basic_parameter_access():
	print("\n🔍 Testing basic parameter file access...")
	
	# Test if key parameter files exist in new locations
	var test_files = [
		"res://commons/audio/parameters/basic/pickup_mario.json",
		"res://commons/audio/parameters/basic/teleport_drone.json",
		"res://commons/audio/parameters/drums/dark_808_kick.json",
		"res://commons/audio/parameters/synthesizers/moog_bass_lead.json"
	]
	
	for file_path in test_files:
		if FileAccess.file_exists(file_path):
			print("   ✅ Found: %s" % file_path.get_file())
			
			# Try to load the JSON
			var file = FileAccess.open(file_path, FileAccess.READ)
			if file:
				var json_string = file.get_as_text()
				file.close()
				
				var json = JSON.new()
				if json.parse(json_string) == OK:
					var data = json.data
					print("      📄 JSON valid, keys: %s" % data.keys())
				else:
					print("      ❌ JSON parse error")
			else:
				print("      ❌ Could not read file")
		else:
			print("   ❌ Missing: %s" % file_path.get_file())

func test_interface_compatibility():
	print("\n🎛️ Testing interface compatibility...")
	
	# Test if the ModularSoundDesignerInterface can load parameters
	var interface = preload("res://commons/audio/interfaces/ModularSoundDesignerInterface.gd").new()
	
	# This should trigger parameter loading
	add_child(interface)
	
	await get_tree().process_frame
	
	print("   Interface loaded successfully!")
	interface.queue_free() 