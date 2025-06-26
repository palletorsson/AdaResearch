# quick_test_fix.gd
# Quick test to verify parameter loading works correctly

extends Node

func _ready():
	print("🧪 Quick test of parameter loading fix...")
	
	# Test different parameter file formats
	var test_sounds = ["basic_sine_wave", "dark_808_kick", "moog_bass_lead"]
	
	for sound_name in test_sounds:
		print("\n📊 Testing %s:" % sound_name)
		var params = EnhancedParameterLoader.get_sound_parameters(sound_name)
		
		if params.size() == 0:
			print("  ❌ No parameters loaded!")
			continue
		
		var param_count = 0
		for param_name in params.keys():
			if param_count >= 3:  # Just show first 3 params
				break
			var param_config = params[param_name]
			
			# Test accessing the 'value' key
			if param_config is Dictionary and param_config.has("value"):
				print("  ✅ %s: %s" % [param_name, param_config["value"]])
			else:
				print("  ❌ %s: Invalid structure - %s" % [param_name, param_config])
			param_count += 1
		
		print("  📈 Total parameters: %d" % params.size())
	
	print("\n🎛️ All formats should now work in interfaces!")
	
	# Cleanup
	queue_free() 