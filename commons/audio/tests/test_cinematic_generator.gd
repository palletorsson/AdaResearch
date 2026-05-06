extends SceneTree

func _init():
	print("🧪 Testing CinematicMusicGenerator...")
	
	var CinematicGen = load("res://commons/audio/generators/CinematicMusicGenerator.gd")
	if not CinematicGen:
		print("❌ Could not load CinematicMusicGenerator.gd")
		quit(1)
		return
		
	var sounds_to_test = [
		"blade_runner_pad",
		"vangelis_brass_lead",
		"cyber_rain_texture"
	]
	
	for sound_name in sounds_to_test:
		print("   Testing generation of '%s'..." % sound_name)
		var stream = CinematicGen.generate_sound(sound_name, {"duration": 1.0}) # Short duration for test
		
		if stream and stream is AudioStreamWAV:
			var data = stream.data
			if data.size() > 0:
				print("   ✅ Generated %d bytes." % data.size())
			else:
				print("   ❌ Generated empty data!")
				quit(1)
		else:
			print("   ❌ Failed to generate AudioStreamWAV")
			quit(1)
			
	print("\n🎉 CinematicMusicGenerator verification successful!")
	quit(0)
