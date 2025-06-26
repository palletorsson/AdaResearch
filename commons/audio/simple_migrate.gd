# simple_migrate.gd
# Simple standalone migration script
# Can be run directly in Godot console or as a scene script

extends Node

func _ready():
	print("🚀 Starting simple audio folder migration...")
	migrate_audio_structure()

func migrate_audio_structure():
	var audio_path = "res://commons/audio/"
	print("📁 Working with path: %s" % audio_path)
	
	# Create directories
	create_directories(audio_path)
	
	# Move files
	move_files_by_category(audio_path)
	
	print("✅ Migration completed!")

func create_directories(base_path: String):
	print("📁 Creating directory structure...")
	
	var dirs = [
		"runtime/presets",
		"interfaces/components",
		"generators",
		"compositions/players",
		"compositions/scenes", 
		"compositions/systems",
		"compositions/configs",
		"parameters/basic",
		"parameters/drums",
		"parameters/synthesizers",
		"parameters/retro",
		"parameters/experimental",
		"parameters/ambient",
		"testing/test_scenes",
		"documentation/guides"
	]
	
	var dir_access = DirAccess.open(base_path)
	if not dir_access:
		print("❌ Cannot access audio directory!")
		return
		
	for dir in dirs:
		if dir_access.make_dir_recursive(dir) == OK:
			print("  ✅ Created: %s" % dir)
		else:
			print("  ⚠️ Directory already exists or failed: %s" % dir)

func move_files_by_category(base_path: String):
	print("📦 Moving files to new locations...")
	
	# Define file mappings
	var file_moves = {
		# Runtime files
		"LeanAudioRuntime.gd": "runtime/",
		"CubeAudioPlayer.gd": "runtime/",
		"SyntheticSoundGenerator.gd": "runtime/",
		
		# Interface files
		"SoundDesignerInterface.gd": "interfaces/",
		"sound_interface.tscn": "interfaces/",
		"ModularSoundDesignerInterface.gd": "interfaces/",
		"modular_sound_interface.tscn": "interfaces/",
		
		# Generator files
		"AudioSynthesizer.gd": "generators/",
		"CustomSoundGenerator.gd": "generators/",
		"test_parameter_connection.gd": "generators/",
		"create_default_parameters.gd": "generators/",
		
		# Track player files
		"DarkGameTrackPlayer.gd": "compositions/players/",
		"DarkGameTrackPlayerJSON.gd": "compositions/players/",
		"DarkBladeRunner128TrackPlayer.gd": "compositions/players/",
		"SyncopatedTrackPlayer.gd": "compositions/players/",
		"StructuredTrackPlayer.gd": "compositions/players/",
		"PolymeterTrackPlayer.gd": "compositions/players/",
		
		# Track scenes
		"dark_game_track.tscn": "compositions/scenes/",
		"syncopated_track.tscn": "compositions/scenes/",
		"structured_track.tscn": "compositions/scenes/",
		"polymeter_track.tscn": "compositions/scenes/",
		
		# Track systems
		"EnhancedTrackSystem.gd": "compositions/systems/",
		"EnhancedTrackExample.gd": "compositions/systems/",
		"EnhancedDarkTrack.gd": "compositions/systems/",
		"TrackLayer.gd": "compositions/systems/",
		"PatternSequencer.gd": "compositions/systems/",
		"EffectsRack.gd": "compositions/systems/",
		"TrackConfigExample.gd": "compositions/systems/",
		"TrackConfigLoader.gd": "compositions/systems/",
		
		# Documentation
		"README.md": "documentation/",
		"README_SoundDesignerTutorial.md": "documentation/",
		"README_EnhancedTrackSystem.md": "documentation/",
		"AudioProjectStructure.md": "documentation/",
		"FOLDER_RESTRUCTURE_PLAN.md": "documentation/",
		"PATH_UPDATE_GUIDE.md": "documentation/",
		
		# Testing
		"AudioTestScene.gd": "testing/"
	}
	
	# Move individual files
	for file_name in file_moves:
		var dest_dir = file_moves[file_name]
		move_file_if_exists(base_path, file_name, dest_dir + file_name)
	
	# Move special folders
	move_folder_if_exists(base_path, "components/", "interfaces/components/")
	move_folder_if_exists(base_path, "configs/", "compositions/configs/")
	
	# Move .tres files to presets
	move_tres_files(base_path)
	
	# Move parameter files by category
	move_parameter_files(base_path)

func move_file_if_exists(base_path: String, source_file: String, dest_path: String):
	var full_source = base_path + source_file
	var full_dest = base_path + dest_path
	
	if FileAccess.file_exists(full_source):
		var dir = DirAccess.open(base_path)
		if dir.rename(full_source, full_dest) == OK:
			print("  ✅ Moved: %s → %s" % [source_file, dest_path])
		else:
			print("  ❌ Failed to move: %s" % source_file)
	else:
		print("  ⚠️ Not found: %s" % source_file)

func move_folder_if_exists(base_path: String, source_folder: String, dest_path: String):
	var full_source = base_path + source_folder
	var full_dest = base_path + dest_path
	
	if DirAccess.dir_exists_absolute(full_source):
		var dir = DirAccess.open(base_path)
		if dir.rename(full_source, full_dest) == OK:
			print("  ✅ Moved folder: %s → %s" % [source_folder, dest_path])
		else:
			print("  ❌ Failed to move folder: %s" % source_folder)
	else:
		print("  ⚠️ Folder not found: %s" % source_folder)

func move_tres_files(base_path: String):
	print("  📦 Moving .tres files to presets...")
	var dir = DirAccess.open(base_path)
	if not dir:
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			move_file_if_exists(base_path, file_name, "runtime/presets/" + file_name)
		file_name = dir.get_next()

func move_parameter_files(base_path: String):
	print("  📊 Moving parameter files...")
	
	var sound_params_path = base_path + "sound_parameters/"
	if not DirAccess.dir_exists_absolute(sound_params_path):
		print("  ⚠️ sound_parameters/ folder not found")
		return
	
	# Parameter categorization
	var basic_sounds = [
		"basic_sine_wave.json", "pickup_mario.json", "teleport_drone.json",
		"ghost_drone.json", "lift_bass_pulse.json", "power_up_jingle.json",
		"laser_shot.json", "shield_hit.json", "explosion.json",
		"retro_jump.json", "ambient_wind.json"
	]
	
	var drum_sounds = [
		"dark_808_kick.json", "acid_606_hihat.json", "tr909_kick.json",
		"linn_drum_kick.json", "synare_3_disco_tom.json", "synare_3_cosmic_fx.json"
	]
	
	var synth_sounds = [
		"moog_bass_lead.json", "tb303_acid_bass.json", "dx7_electric_piano.json",
		"jupiter_8_strings.json", "korg_m1_piano.json", "arp_2600_lead.json",
		"ppg_wave_pad.json", "moog_kraftwerk_sequencer.json"
	]
	
	var retro_sounds = [
		"c64_sid_lead.json", "amiga_mod_sample.json", "gameboy_dmg_wav.json",
		"ambient_amiga_drone.json"
	]
	
	var experimental_sounds = [
		"aphex_twin_modular.json", "flying_lotus_sampler.json",
		"herbie_hancock_moog_fusion.json"
	]
	
	var ambient_sounds = [
		"dark_808_sub_bass.json", "melodic_drone.json"
	]
	
	# Move categorized files
	move_parameter_category(base_path, basic_sounds, "basic/")
	move_parameter_category(base_path, drum_sounds, "drums/")
	move_parameter_category(base_path, synth_sounds, "synthesizers/")
	move_parameter_category(base_path, retro_sounds, "retro/")
	move_parameter_category(base_path, experimental_sounds, "experimental/")
	move_parameter_category(base_path, ambient_sounds, "ambient/")
	
	# Move any remaining JSON files to basic
	move_remaining_json_files(base_path)
	
	# Move documentation
	move_file_if_exists(base_path, "sound_parameters/README.md", "parameters/README.md")

func move_parameter_category(base_path: String, file_list: Array, category: String):
	for file_name in file_list:
		var source = "sound_parameters/" + file_name
		var dest = "parameters/" + category + file_name
		move_file_if_exists(base_path, source, dest)

func move_remaining_json_files(base_path: String):
	print("    📋 Moving remaining JSON files to basic category...")
	var params_dir = DirAccess.open(base_path + "sound_parameters/")
	if not params_dir:
		return
		
	params_dir.list_dir_begin()
	var file_name = params_dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json"):
			var source = "sound_parameters/" + file_name
			var dest = "parameters/basic/" + file_name
			move_file_if_exists(base_path, source, dest)
		file_name = params_dir.get_next()
	
	# Try to remove empty sound_parameters directory
	var dir = DirAccess.open(base_path)
	if dir:
		dir.remove("sound_parameters/")
		print("  🗑️ Removed empty sound_parameters directory") 