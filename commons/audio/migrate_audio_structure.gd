# migrate_audio_structure.gd
# Automated script to restructure the audio folder
# Run this as a script in Godot to reorganize your audio folder

@tool
extends RefCounted

const AUDIO_PATH = "res://commons/audio/"

# File categorization for automated sorting
const RUNTIME_FILES = [
	"LeanAudioRuntime.gd",
	"CubeAudioPlayer.gd", 
	"SyntheticSoundGenerator.gd"
]

const INTERFACE_FILES = [
	"SoundDesignerInterface.gd",
	"sound_interface.tscn",
	"ModularSoundDesignerInterface.gd",
	"modular_sound_interface.tscn"
]

const GENERATOR_FILES = [
	"AudioSynthesizer.gd",
	"CustomSoundGenerator.gd",
	"test_parameter_connection.gd",
	"create_default_parameters.gd"
]

const TRACK_PLAYER_FILES = [
	"DarkGameTrackPlayer.gd",
	"DarkGameTrackPlayerJSON.gd", 
	"DarkBladeRunner128TrackPlayer.gd",
	"SyncopatedTrackPlayer.gd",
	"StructuredTrackPlayer.gd",
	"PolymeterTrackPlayer.gd"
]

const TRACK_SCENE_FILES = [
	"dark_game_track.tscn",
	"syncopated_track.tscn",
	"structured_track.tscn",
	"polymeter_track.tscn"
]

const TRACK_SYSTEM_FILES = [
	"EnhancedTrackSystem.gd",
	"EnhancedTrackExample.gd",
	"EnhancedDarkTrack.gd",
	"TrackLayer.gd",
	"PatternSequencer.gd",
	"EffectsRack.gd",
	"TrackConfigExample.gd",
	"TrackConfigLoader.gd"
]

const DOCUMENTATION_FILES = [
	"README.md",
	"README_SoundDesignerTutorial.md",
	"README_EnhancedTrackSystem.md",
	"AudioProjectStructure.md",
	"FOLDER_RESTRUCTURE_PLAN.md"
]

const TESTING_FILES = [
	"AudioTestScene.gd"
]

# Parameter file categorization
const BASIC_SOUNDS = [
	"basic_sine_wave.json",
	"pickup_mario.json",
	"teleport_drone.json",
	"ghost_drone.json",
	"lift_bass_pulse.json",
	"power_up_jingle.json",
	"laser_shot.json",
	"shield_hit.json",
	"explosion.json",
	"retro_jump.json",
	"ambient_wind.json"
]

const DRUM_SOUNDS = [
	"dark_808_kick.json",
	"acid_606_hihat.json",
	"tr909_kick.json",
	"linn_drum_kick.json",
	"synare_3_disco_tom.json",
	"synare_3_cosmic_fx.json"
]

const SYNTHESIZER_SOUNDS = [
	"moog_bass_lead.json",
	"tb303_acid_bass.json",
	"dx7_electric_piano.json",
	"jupiter_8_strings.json",
	"korg_m1_piano.json",
	"arp_2600_lead.json",
	"ppg_wave_pad.json",
	"moog_kraftwerk_sequencer.json"
]

const RETRO_SOUNDS = [
	"c64_sid_lead.json",
	"amiga_mod_sample.json",
	"gameboy_dmg_wav.json",
	"ambient_amiga_drone.json"
]

const EXPERIMENTAL_SOUNDS = [
	"aphex_twin_modular.json",
	"flying_lotus_sampler.json",
	"herbie_hancock_moog_fusion.json"
]

const AMBIENT_SOUNDS = [
	"dark_808_sub_bass.json",
	"melodic_drone.json"
]

# Main migration function
static func migrate_structure():
	print("🔄 Starting audio folder migration...")
	print("📁 Working directory: %s" % AUDIO_PATH)
	
	var migrator = new()
	
	# Phase 1: Create directory structure
	migrator._create_directory_structure()
	
	# Phase 2: Move files by category
	migrator._move_runtime_files()
	migrator._move_interface_files()
	migrator._move_generator_files()
	migrator._move_composition_files()
	migrator._move_parameter_files()
	migrator._move_documentation_files()
	migrator._move_testing_files()
	
	# Phase 3: Cleanup
	migrator._cleanup_empty_directories()
	
	print("✅ Migration complete!")
	print("🎯 Next steps:")
	print("   1. Update import paths in your scripts")
	print("   2. Test that everything still works")
	print("   3. Update project references")

func _create_directory_structure():
	print("📁 Creating new directory structure...")
	
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
	
	var dir_access = DirAccess.open(AUDIO_PATH)
	if not dir_access:
		print("❌ Cannot access audio directory!")
		return
		
	for dir in dirs:
		if dir_access.make_dir_recursive(dir) == OK:
			print("  ✅ Created: %s" % dir)
		else:
			print("  ⚠️ Failed to create: %s" % dir)

func _move_runtime_files():
	print("🎮 Moving runtime files...")
	_move_files_to_directory(RUNTIME_FILES, "runtime/")
	_move_tres_files_to_presets()

func _move_interface_files():
	print("🎛️ Moving interface files...")
	_move_files_to_directory(INTERFACE_FILES, "interfaces/")
	_move_components_folder()

func _move_generator_files():
	print("🔧 Moving generator files...")
	_move_files_to_directory(GENERATOR_FILES, "generators/")

func _move_composition_files():
	print("🎵 Moving composition files...")
	_move_files_to_directory(TRACK_PLAYER_FILES, "compositions/players/")
	_move_files_to_directory(TRACK_SCENE_FILES, "compositions/scenes/")
	_move_files_to_directory(TRACK_SYSTEM_FILES, "compositions/systems/")
	_move_configs_folder()

func _move_parameter_files():
	print("📊 Moving parameter files...")
	
	var sound_params_path = AUDIO_PATH + "sound_parameters/"
	if not DirAccess.dir_exists_absolute(sound_params_path):
		print("  ⚠️ sound_parameters/ folder not found")
		return
	
	# Move categorized JSON files
	_move_parameter_category(BASIC_SOUNDS, "basic/")
	_move_parameter_category(DRUM_SOUNDS, "drums/")
	_move_parameter_category(SYNTHESIZER_SOUNDS, "synthesizers/")
	_move_parameter_category(RETRO_SOUNDS, "retro/")
	_move_parameter_category(EXPERIMENTAL_SOUNDS, "experimental/")
	_move_parameter_category(AMBIENT_SOUNDS, "ambient/")
	
	# Move any remaining JSON files to basic category
	_move_remaining_json_files()
	
	# Move parameter documentation
	_move_file_if_exists("sound_parameters/README.md", "parameters/README.md")

func _move_documentation_files():
	print("📚 Moving documentation files...")
	_move_files_to_directory(DOCUMENTATION_FILES, "documentation/")

func _move_testing_files():
	print("🧪 Moving testing files...")
	_move_files_to_directory(TESTING_FILES, "testing/")

# Helper functions

func _move_files_to_directory(file_list: Array, target_dir: String):
	for file_name in file_list:
		var source = AUDIO_PATH + file_name
		var destination = AUDIO_PATH + target_dir + file_name
		_move_file_if_exists(file_name, target_dir + file_name)

func _move_file_if_exists(source_path: String, dest_path: String):
	var full_source = AUDIO_PATH + source_path
	var full_dest = AUDIO_PATH + dest_path
	
	if FileAccess.file_exists(full_source):
		var dir = DirAccess.open(AUDIO_PATH)
		if dir.rename(full_source, full_dest) == OK:
			print("  ✅ Moved: %s → %s" % [source_path, dest_path])
		else:
			print("  ❌ Failed to move: %s" % source_path)
	else:
		print("  ⚠️ Not found: %s" % source_path)

func _move_tres_files_to_presets():
	print("  📦 Moving .tres files to presets...")
	var dir = DirAccess.open(AUDIO_PATH)
	if not dir:
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var source = file_name
			var dest = "runtime/presets/" + file_name
			_move_file_if_exists(source, dest)
		file_name = dir.get_next()

func _move_components_folder():
	print("  🧩 Moving components folder...")
	var source = AUDIO_PATH + "components"
	var dest = AUDIO_PATH + "interfaces/components"
	
	if DirAccess.dir_exists_absolute(source):
		var dir = DirAccess.open(AUDIO_PATH)
		if dir.rename(source, dest) == OK:
			print("  ✅ Moved: components/ → interfaces/components/")
		else:
			print("  ❌ Failed to move components folder")
	else:
		print("  ⚠️ Components folder not found")

func _move_configs_folder():
	print("  ⚙️ Moving configs folder...")
	var source = AUDIO_PATH + "configs"
	var dest = AUDIO_PATH + "compositions/configs"
	
	if DirAccess.dir_exists_absolute(source):
		var dir = DirAccess.open(AUDIO_PATH)
		if dir.rename(source, dest) == OK:
			print("  ✅ Moved: configs/ → compositions/configs/")
		else:
			print("  ❌ Failed to move configs folder")
	else:
		print("  ⚠️ Configs folder not found")

func _move_parameter_category(file_list: Array, category: String):
	for file_name in file_list:
		var source = "sound_parameters/" + file_name
		var dest = "parameters/" + category + file_name
		_move_file_if_exists(source, dest)

func _move_remaining_json_files():
	print("  📋 Moving remaining JSON files to basic category...")
	var params_dir = DirAccess.open(AUDIO_PATH + "sound_parameters/")
	if not params_dir:
		return
		
	params_dir.list_dir_begin()
	var file_name = params_dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json"):
			var source = "sound_parameters/" + file_name
			var dest = "parameters/basic/" + file_name
			_move_file_if_exists(source, dest)
		file_name = params_dir.get_next()

func _cleanup_empty_directories():
	print("🧹 Cleaning up empty directories...")
	var dirs_to_remove = ["sound_parameters"]
	
	for dir_name in dirs_to_remove:
		var dir_path = AUDIO_PATH + dir_name
		if DirAccess.dir_exists_absolute(dir_path):
			var dir = DirAccess.open(dir_path)
			if dir and _is_directory_empty(dir):
				DirAccess.remove_absolute(dir_path)
				print("  🗑️ Removed empty directory: %s" % dir_name)

func _is_directory_empty(dir: DirAccess) -> bool:
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var is_empty = (file_name == "")
	dir.list_dir_end()
	return is_empty

# Call this function to start the migration
# You can run this script by calling: migrate_audio_structure.migrate_structure() 