# MapProgressionManager.gd
# Central manager for map progression and sequencing
# Loads configuration from map_progression.json and provides progression logic

extends Node

# Map Progression Manager - Handles centralized map progression, unlocks, and save data
# This singleton manages the educational flow through tutorial sequences

var progression_config = {}
var sequences = {}
var map_metadata = {}
var navigation_config = {}
var settings = {}

var completed_maps: Array[String] = []
var current_map: String = ""
var current_target_map: String = ""  # Map that should be loaded next
var unlocked_maps: Array[String] = []

# Signals
signal map_completed(map_name: String)
signal map_unlocked(map_name: String)
signal sequence_completed(sequence_name: String)
signal progression_loaded()

const PROGRESSION_FILE = "res://commons/maps/map_progression.json"
const SAVE_FILE = "user://map_progress.json"
var instance 
func _init():
	instance = self

func _ready():
	print("MapProgressionManager: Starting initialization...")
	
	# Try to load progression config, but don't hang if it fails
	var config_loaded = load_progression_config()
	if not config_loaded:
		print("MapProgressionManager: Failed to load progression config, using defaults")
		# Set up minimal defaults
		sequences = {}
		map_metadata = {}
		navigation_config = {"starting_map": "Minimal_Test", "fallback_map": "default"}
		settings = {"save_progress": true}
	
	# Try to load player progress
	load_player_progress()
	
	# Update unlocked maps
	update_unlocked_maps()
	
	print("MapProgressionManager: Initialized with %d completed maps" % completed_maps.size())
	
	# Check for ada CLI launch intent
	call_deferred("_check_ada_launch_intent")

# Check if ada CLI requested a specific map/sequence launch
func _check_ada_launch_intent():
	const LAUNCH_FILE = "user://ada_launch.json"
	
	if not FileAccess.file_exists(LAUNCH_FILE):
		return
	
	var file = FileAccess.open(LAUNCH_FILE, FileAccess.READ)
	if not file:
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	# Delete the file so we don't re-trigger on next launch
	DirAccess.remove_absolute(ProjectSettings.globalize_path(LAUNCH_FILE))
	
	var json = JSON.new()
	if json.parse(json_text) != OK:
		print("MapProgressionManager: Invalid ada launch file")
		return
	
	var launch_data: Dictionary = json.data
	var map_name: String = launch_data.get("map", "")
	var sequence_name: String = launch_data.get("sequence", "")
	
	# Check timestamp - ignore if older than 30 seconds
	var timestamp: float = launch_data.get("timestamp", 0)
	var age = Time.get_unix_time_from_system() - timestamp
	if age > 30:
		print("MapProgressionManager: Stale ada launch intent (%.1fs old), ignoring" % age)
		return
	
	print("MapProgressionManager: Ada launch intent - map: '%s', sequence: '%s'" % [map_name, sequence_name])
	
	if not map_name.is_empty():
		# Direct map launch
		current_target_map = map_name
		call_deferred("_navigate_to_target_map")
	elif not sequence_name.is_empty():
		# Sequence launch - go to first map
		var seq_maps = get_sequence_maps(sequence_name)
		if seq_maps.size() > 0:
			current_target_map = seq_maps[0]
			call_deferred("_navigate_to_target_map")
		else:
			print("MapProgressionManager: Sequence '%s' not found or empty" % sequence_name)

func _navigate_to_target_map():
	if current_target_map.is_empty():
		return
	print("MapProgressionManager: Navigating to target map: %s" % current_target_map)
	SceneManager.load_map(current_target_map)

# Load the central progression configuration
func load_progression_config() -> bool:
	print("MapProgressionManager: Loading progression configuration...")
	
	if not FileAccess.file_exists(PROGRESSION_FILE):
		print("MapProgressionManager: Configuration file not found: " + PROGRESSION_FILE)
		return false
	
	var file = FileAccess.open(PROGRESSION_FILE, FileAccess.READ)
	if not file:
		print("MapProgressionManager: Could not open configuration file")
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	if json_text.is_empty():
		print("MapProgressionManager: Configuration file is empty")
		return false
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		print("MapProgressionManager: Failed to parse JSON: " + json.get_error_message())
		return false
	
	progression_config = json.data
	
	# Extract sections with defaults
	sequences = progression_config.get("sequences", {})
	map_metadata = progression_config.get("map_metadata", {})
	navigation_config = progression_config.get("navigation", {})
	settings = progression_config.get("settings", {})
	
	print("MapProgressionManager: Loaded %d sequences and %d maps from core config" % [sequences.size(), map_metadata.size()])
	
	# Load external sequences from commons/maps/sequences/
	_load_external_sequences("res://commons/maps/sequences/")
	
	progression_loaded.emit()
	return true

func _load_external_sequences(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				print("MapProgressionManager: Loading sequence file: " + file_name)
				var file = FileAccess.open(path + "/" + file_name, FileAccess.READ)
				if file:
					var json = JSON.new()
					var err = json.parse(file.get_as_text())
					if err == OK:
						var data = json.data
						if data.has("sequences"):
							for seq_id in data.sequences:
								sequences[seq_id] = data.sequences[seq_id]
								print("  - Loaded sequence: " + seq_id)
			file_name = dir.get_next()
	else:
		print("MapProgressionManager: Could not open sequences directory: " + path)

func _check_audio_for_map(map_name: String):
	# Find which sequence this map belongs to
	for seq_id in sequences:
		var seq = sequences[seq_id]
		if seq.has("maps") and map_name in seq.maps:
			# Check for ambient preset
			if seq.has("ambient_preset"):
				var preset = seq.ambient_preset
				print("MapProgressionManager: Map '%s' implies ambient preset '%s'" % [map_name, preset])
				# Trigger audio change via SoundBank
				if is_instance_valid(SoundBank) and SoundBank.has_method("trigger_ambient_change"):
					SoundBank.trigger_ambient_change(preset)
			return

# Hook into set_current_map to trigger audio check
func set_current_map(map_name: String):
	current_map = map_name
	
	# Check and trigger audio for this map/sequence
	_check_audio_for_map(map_name)
	
	if typeof(GameManager) != TYPE_NIL and GameManager.has_method("set_current_map"):
		GameManager.set_current_map(map_name)

# Load player progress from save file
func load_player_progress() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		# First time - start with starting map unlocked
		var starting_map = get_starting_map()
		if starting_map.is_empty():
			starting_map = "Minimal_Test"  # Safe fallback
		unlocked_maps = [starting_map]
		completed_maps = []
		save_player_progress()
		return
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not file:
		print("MapProgressionManager: Could not load progress file")
		# Use safe defaults
		unlocked_maps = ["Minimal_Test"]
		completed_maps = []
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result == OK:
		var progress_data = json.data
		
		# Convert generic Arrays to typed Array[String]
		var loaded_completed = progress_data.get("completed_maps", [])
		completed_maps.clear()
		for map in loaded_completed:
			completed_maps.append(str(map))
		
		var loaded_unlocked = progress_data.get("unlocked_maps", ["Minimal_Test"])
		unlocked_maps.clear()
		for map in loaded_unlocked:
			unlocked_maps.append(str(map))
		
		current_map = str(progress_data.get("current_map", ""))
		print("MapProgressionManager: Loaded progress - %d completed, %d unlocked" % [completed_maps.size(), unlocked_maps.size()])
	else:
		print("MapProgressionManager: Failed to parse progress file, starting fresh")
		unlocked_maps = ["Minimal_Test"]
		completed_maps = []

# Save player progress to file
func save_player_progress() -> void:
	if not settings.get("save_progress", true):
		return
	
	var progress_data = {
		"completed_maps": completed_maps,
		"unlocked_maps": unlocked_maps,
		"current_map": current_map,
		"last_saved": Time.get_datetime_string_from_system()
	}
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(progress_data))
		file.close()
		print("MapProgressionManager: Progress saved")

# Get the next map in sequence after completing current_map_name
func get_next_map(current_map_name: String) -> String:
	if not map_metadata.has(current_map_name):
		print("MapProgressionManager: Unknown map '%s'" % current_map_name)
		return ""
	
	var metadata = map_metadata[current_map_name]
	var unlocks = metadata.get("unlocks", [])
	
	if unlocks.is_empty():
		print("MapProgressionManager: No next map for '%s'" % current_map_name)
		return ""
	
	# Return first unlocked map (could be enhanced for choice)
	return unlocks[0]

# Get all maps that would be unlocked by completing map_name
func get_unlocked_by_completion(map_name: String) -> Array[String]:
	if not map_metadata.has(map_name):
		return []
	
	var metadata = map_metadata[map_name]
	var unlocks = metadata.get("unlocks", [])
	
	# Convert to typed array
	var result: Array[String] = []
	for unlock in unlocks:
		result.append(str(unlock))
	
	return result

# Check if a map is unlocked for the player
func is_map_unlocked(map_name: String) -> bool:
	return map_name in unlocked_maps

# Check if a map has been completed
func is_map_completed(map_name: String) -> bool:
	return map_name in completed_maps

# Mark a map as completed and unlock next maps
func complete_map(map_name: String) -> Array[String]:
	if map_name in completed_maps:
		print("MapProgressionManager: Map '%s' already completed" % map_name)
		return []

	print("MapProgressionManager: Completing map '%s'" % map_name)
	completed_maps.append(map_name)

	# Award XP for completing the map
	var xp_reward := get_map_xp_reward(map_name)
	if xp_reward > 0 and is_instance_valid(GameManager):
		GameManager.add_points(xp_reward)
		print("MapProgressionManager: Awarded %d XP for completing '%s'" % [xp_reward, map_name])
	
	# Get newly unlocked maps
	var newly_unlocked = get_unlocked_by_completion(map_name)
	var new_unlocks: Array[String] = []
	
	for unlock_map in newly_unlocked:
		if not is_map_unlocked(unlock_map) and can_unlock_map(unlock_map):
			unlocked_maps.append(unlock_map)
			new_unlocks.append(unlock_map)
			map_unlocked.emit(unlock_map)
			print("MapProgressionManager: Unlocked map '%s'" % unlock_map)
	
	map_completed.emit(map_name)
	
	# Check for completed sequences
	_check_sequence_completion()
	
	# Save progress
	save_player_progress()
	
	return new_unlocks

# Check if all prerequisites for a map are met
func can_unlock_map(map_name: String) -> bool:
	if not map_metadata.has(map_name):
		return false
	
	var metadata = map_metadata[map_name]
	var prerequisites = metadata.get("prerequisites", [])
	
	# Check if all prerequisites are completed
	for prereq in prerequisites:
		if not is_map_completed(prereq):
			return false
	
	return true

# Update unlocked maps based on current progress
func update_unlocked_maps() -> void:
	for map_name in map_metadata.keys():
		if not is_map_unlocked(map_name) and can_unlock_map(map_name):
			unlocked_maps.append(map_name)
			map_unlocked.emit(map_name)

# Get all maps in a sequence
func get_sequence_maps(sequence_name: String) -> Array[String]:
	if not sequences.has(sequence_name):
		return []
	
	var sequence = sequences[sequence_name]
	var maps = sequence.get("maps", [])
	
	# Convert to typed array
	var result: Array[String] = []
	for map in maps:
		result.append(str(map))
	
	return result

# Check if a sequence is completed
func is_sequence_completed(sequence_name: String) -> bool:
	var sequence_maps = get_sequence_maps(sequence_name)
	
	for map_name in sequence_maps:
		if not is_map_completed(map_name):
			return false
	
	return sequence_maps.size() > 0

# Get completion percentage for a sequence
func get_sequence_completion_percentage(sequence_name: String) -> float:
	var sequence_maps = get_sequence_maps(sequence_name)
	if sequence_maps.is_empty():
		return 0.0
	
	var completed_count = 0
	for map_name in sequence_maps:
		if is_map_completed(map_name):
			completed_count += 1
	
	return float(completed_count) / float(sequence_maps.size()) * 100.0

# Check for sequence completion and emit signals
func _check_sequence_completion() -> void:
	for sequence_name in sequences.keys():
		if is_sequence_completed(sequence_name):
			sequence_completed.emit(sequence_name)

# Get the starting map from configuration
func get_starting_map() -> String:
	if navigation_config.is_empty():
		return "Minimal_Test"
	return navigation_config.get("starting_map", "Minimal_Test")

# Get the main menu map
func get_main_menu_map() -> String:
	if navigation_config.is_empty():
		return "menu"
	return navigation_config.get("main_menu", "menu")

# Get the fallback map
func get_fallback_map() -> String:
	if navigation_config.is_empty():
		return "default"
	return navigation_config.get("fallback_map", "default")

# Get the default sequence
func get_default_sequence() -> String:
	if progression_config.is_empty():
		return "tutorial_progression"
	return progression_config.get("default_sequence", "tutorial_progression")

# Convert destination map name to scene path for teleporter
func get_scene_path_for_map(map_name: String) -> String:
	# Check if it should use dynamic generation or static scene
	var static_scene_path = "res://commons/scenes/maps/" + map_name + ".tscn"
	
	if ResourceLoader.exists(static_scene_path):
		return static_scene_path
	else:
		# Use DynamicMapSystem to generate scene
		print("MapProgressionManager: Map '%s' will be generated dynamically" % map_name)
		return "dynamic:" + map_name

# Get all unlocked maps
func get_unlocked_maps() -> Array[String]:
	return unlocked_maps.duplicate()

# Get all completed maps
func get_completed_maps() -> Array[String]:
	return completed_maps.duplicate()


# Get map difficulty
func get_map_difficulty(map_name: String) -> String:
	if not map_metadata.has(map_name):
		return "unknown"
	
	return map_metadata[map_name].get("difficulty", "unknown")

# Get estimated time for map
func get_map_estimated_time(map_name: String) -> String:
	if not map_metadata.has(map_name):
		return "unknown"
	
	return map_metadata[map_name].get("estimated_time", "unknown")

# Get prerequisites for a map
func get_map_prerequisites(map_name: String) -> Array[String]:
	if not map_metadata.has(map_name):
		return []

	var prerequisites = map_metadata[map_name].get("prerequisites", [])

	# Convert to typed array
	var result: Array[String] = []
	for prereq in prerequisites:
		result.append(str(prereq))

	return result

# Get XP reward for completing a map (default 10)
func get_map_xp_reward(map_name: String) -> int:
	const DEFAULT_XP_REWARD := 10
	if not map_metadata.has(map_name):
		return DEFAULT_XP_REWARD

	return map_metadata[map_name].get("xp_reward", DEFAULT_XP_REWARD)



# Check if the core array tutorial sequence is finished
func is_array_sequence_complete() -> bool:
	var array_sequence = ["Minimal_Test", "Tutorial_Row", "Tutorial_2D", "Tutorial_Disco"]
	for map in array_sequence:
		if not map in completed_maps:
			return false
	return true

# Get next destination with lab return logic
func get_next_destination(_current_map: String) -> String:
	# If we just completed the disco tutorial, return to lab
	if current_map == "Tutorial_Disco" and is_array_sequence_complete():
		return "res://adaresearch/Common/Scenes/ScienceLab/ScienceLab.tscn"
	
	# Otherwise use normal progression
	for sequence_name in sequences:
		var sequence = sequences[sequence_name]
		var maps = sequence.get("maps", [])
		
		var current_index = maps.find(current_map)
		if current_index >= 0 and current_index < maps.size() - 1:
			return maps[current_index + 1]
	
	return get_scene_path_for_map(navigation_config.get("main_menu", ""))

# Reset progress for new game
func reset_progress():
	completed_maps.clear()
	unlocked_maps.clear()
	current_map = ""
	# Always unlock the starting map
	# Always unlock the starting map
	var starting_map = get_starting_map()
	if starting_map:
		unlocked_maps.append(starting_map)
	save_player_progress()
	print("Progress reset for new game")

# Get the first map in a sequence
func get_first_map_in_sequence(sequence_name: String) -> String:
	if sequences.has(sequence_name):
		var sequence = sequences[sequence_name]
		if sequence.has("maps") and sequence.maps.size() > 0:
			return sequence.maps[0]
	return ""

# Set target map for next base scene load
func set_current_target_map(map_name: String):
	current_target_map = map_name
	print("MapProgressionManager: Target map set to: %s" % map_name)

# Get current target map
func get_current_target_map() -> String:
	var target = current_target_map
	current_target_map = ""  # Clear after reading
	return target

# Get previous map in sequence
func get_previous_map(current_map_name: String) -> String:
	# Find the sequence containing this map
	for sequence_name in sequences.keys():
		var sequence_maps = get_sequence_maps(sequence_name)
		var current_index = sequence_maps.find(current_map_name)
		
		if current_index > 0:
			return sequence_maps[current_index - 1]
	
	return ""

# Mark map as completed (alias for complete_map)
func mark_map_completed(map_name: String):
	complete_map(map_name)
