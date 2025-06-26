# run_migration.gd
# Simple script to execute the audio folder restructure
# Add this as a tool script and run it in the editor

@tool
extends EditorScript

func _run():
	print("🚀 Starting audio folder restructure...")
	
	# Load and run the migration script
	var migrate_script_class = load("res://commons/audio/migrate_audio_structure.gd")
	if migrate_script_class:
		# Call the static function directly
		migrate_script_class.migrate_structure()
		print("🎉 Migration completed successfully!")
		print("")
		print("📋 TODO - Update these import paths in your files:")
		print("   AudioSynthesizer.gd → generators/AudioSynthesizer.gd")
		print("   CustomSoundGenerator.gd → generators/CustomSoundGenerator.gd") 
		print("   components/* → interfaces/components/*")
		print("   sound_parameters/* → parameters/basic/* (or other categories)")
		print("   configs/* → compositions/configs/*")
		print("")
		print("🔍 Search your project for 'res://commons/audio/' to find files that need updating")
	else:
		print("❌ Could not load migration script!") 