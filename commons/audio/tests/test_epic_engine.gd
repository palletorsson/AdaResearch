extends SceneTree

func _init():
	print("🧪 Testing EpicSynthEngine (Analog Domain)...")
	
	var EpicGen = load("res://commons/audio/engines/EpicSynthEngine.gd")
	if not EpicGen:
		print("❌ Could not load EpicSynthEngine.gd")
		quit(1)
		return
		
	var patches_to_test = [
		"cs80_pad_1",
		"cs80_lead_1",
		"sub_bass"
	]
	
	for patch_name in patches_to_test:
		print("   Testing generation of '%s'..." % patch_name)
		var stream = EpicGen.generate_patch(patch_name, {"duration": 1.0})
		
		if stream and stream is AudioStreamWAV:
			var data = stream.data
			if data.size() > 0:
				print("   ✅ Generated %d bytes." % data.size())
				if stream.stereo:
					print("      (Stereo confirmed)")
				else:
					print("      ❌ Error: Not stereo!")
					quit(1)
			else:
				print("   ❌ Generated empty data!")
				quit(1)
		else:
			print("   ❌ Failed to generate AudioStreamWAV")
			quit(1)
			
	print("\n🎉 EpicSynthEngine verification successful!")
	quit(0)
