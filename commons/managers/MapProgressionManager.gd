# MapProgressionManager.gd
# Central manager for map progression and sequencing
# Loads sequence files from commons/maps/sequences and optional legacy metadata

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

const CURRICULUM_SPINE_FILE = "res://commons/maps/curriculum_spine.json"
const SEQUENCE_DIR = "res://commons/maps/sequences/"
const DEFAULT_STARTING_MAP = "Minimal_Test"
const DEFAULT_MAIN_MENU_MAP = "menu"
const DEFAULT_FALLBACK_MAP = "default"
const SAVE_FILE = "user://map_progress.json"
var default_sequence_id: String = "primitives"
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

	# Sequence-first defaults.
	progression_config = {}
	sequences = {}
	map_metadata = {}
	navigation_config = {
		"starting_map": "",
		"main_menu": DEFAULT_MAIN_MENU_MAP,
		"fallback_map": DEFAULT_FALLBACK_MAP
	}
	settings = {
		"enforce_progression": true,
		"allow_map_skipping": false,
		"auto_unlock_next": true,
		"save_progress": true
	}
	default_sequence_id = "primitives"

	# Load canonical sequence definitions.
	_load_external_sequences(SEQUENCE_DIR)
	_synthesize_map_metadata_from_sequences()
	_resolve_default_sequence()
	_resolve_starting_map()

	print(
		"MapProgressionManager: Loaded %d sequences and synthesized %d map metadata entries"
		% [sequences.size(), map_metadata.size()]
	)

	progression_loaded.emit()
	return true

func _synthesize_map_metadata_from_sequences() -> void:
	var prior_metadata: Dictionary = map_metadata.duplicate(true)
	map_metadata.clear()

	for seq_id in sequences.keys():
		var sequence_data: Dictionary = sequences[seq_id]
		if not sequence_data.has("maps") or not (sequence_data.maps is Array):
			continue

		var seq_maps: Array[String] = []
		for map_entry in sequence_data.maps:
			var map_name := str(map_entry).strip_edges()
			if map_name.is_empty():
				continue
			if not seq_maps.has(map_name):
				seq_maps.append(map_name)

		for i in range(seq_maps.size()):
			var map_name := seq_maps[i]
			var metadata_entry: Dictionary = {}
			if prior_metadata.has(map_name) and prior_metadata[map_name] is Dictionary:
				metadata_entry = (prior_metadata[map_name] as Dictionary).duplicate(true)

			if not metadata_entry.has("difficulty"):
				metadata_entry["difficulty"] = str(sequence_data.get("difficulty", "unknown"))
			if not metadata_entry.has("estimated_time"):
				metadata_entry["estimated_time"] = str(sequence_data.get("estimated_time", "unknown"))

			var prerequisites: Array[String] = []
			var raw_prerequisites = metadata_entry.get("prerequisites", [])
			if metadata_entry.has("prerequisites") and raw_prerequisites is Array:
				for prereq in raw_prerequisites:
					var prereq_name := str(prereq).strip_edges()
					if not prereq_name.is_empty():
						prerequisites.append(prereq_name)
			elif i > 0:
				prerequisites.append(seq_maps[i - 1])
			metadata_entry["prerequisites"] = prerequisites

			var unlocks: Array[String] = []
			var raw_unlocks = metadata_entry.get("unlocks", [])
			if metadata_entry.has("unlocks") and raw_unlocks is Array:
				for unlock in raw_unlocks:
					var unlock_name := str(unlock).strip_edges()
					if not unlock_name.is_empty():
						unlocks.append(unlock_name)
			elif i < seq_maps.size() - 1:
				unlocks.append(seq_maps[i + 1])
			metadata_entry["unlocks"] = unlocks

			map_metadata[map_name] = metadata_entry

func _resolve_default_sequence() -> void:
	if sequences.has(default_sequence_id):
		return

	if FileAccess.file_exists(CURRICULUM_SPINE_FILE):
		var file = FileAccess.open(CURRICULUM_SPINE_FILE, FileAccess.READ)
		if file:
			var spine_text = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(spine_text) == OK and json.data is Dictionary:
				var spine = json.data.get("spine", {})
				if spine is Dictionary and spine.has("sequences") and spine.sequences is Array:
					for sequence_entry in spine.sequences:
						if sequence_entry is Dictionary:
							var candidate := str(sequence_entry.get("name", "")).strip_edges()
							if sequences.has(candidate):
								default_sequence_id = candidate
								return

	if sequences.has("primitives"):
		default_sequence_id = "primitives"
	elif sequences.has("array_tutorial"):
		default_sequence_id = "array_tutorial"
	elif sequences.size() > 0:
		default_sequence_id = str(sequences.keys()[0])

func _resolve_starting_map() -> void:
	var configured_start := str(navigation_config.get("starting_map", "")).strip_edges()
	if not configured_start.is_empty() and map_metadata.has(configured_start):
		return

	var sequence_maps := get_sequence_maps(default_sequence_id)
	if not sequence_maps.is_empty():
		navigation_config["starting_map"] = sequence_maps[0]
	elif map_metadata.has(DEFAULT_STARTING_MAP):
		navigation_config["starting_map"] = DEFAULT_STARTING_MAP
	elif map_metadata.size() > 0:
		navigation_config["starting_map"] = str(map_metadata.keys()[0])
	else:
		navigation_config["starting_map"] = DEFAULT_STARTING_MAP

	if str(navigation_config.get("main_menu", "")).strip_edges().is_empty():
		navigation_config["main_menu"] = DEFAULT_MAIN_MENU_MAP
	if str(navigation_config.get("fallback_map", "")).strip_edges().is_empty():
		navigation_config["fallback_map"] = DEFAULT_FALLBACK_MAP

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
						if data is Dictionary and data.has("sequences") and data.sequences is Dictionary:
							for seq_id in data.sequences.keys():
								var seq_data = data.sequences[seq_id]
								if seq_data is Dictionary and seq_data.has("maps") and seq_data.maps is Array:
									var normalized_id := str(seq_id)
									sequences[normalized_id] = seq_data
									print("  - Loaded sequence: " + normalized_id)
								else:
									print("  - Skipped non-sequence entry '%s' in %s" % [str(seq_id), file_name])
						else:
							print("  - Skipped file (no valid sequences dictionary): " + file_name)
					else:
						print("  - Failed to parse JSON in %s: %s" % [file_name, json.get_error_message()])
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
	return default_sequence_id

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

# =============================================================================
# GAME MODE HELPERS (Test Mode / Explorer Mode)
# =============================================================================

# Get the last map in a sequence (for test mode - skip to end)
func get_last_map_in_sequence(sequence_name: String) -> String:
	var maps = get_sequence_maps(sequence_name)
	if maps.size() > 0:
		return maps[maps.size() - 1]
	return ""

# Skip to the last map of a sequence (test mode)
func skip_to_sequence_end(sequence_name: String) -> String:
	var last_map = get_last_map_in_sequence(sequence_name)
	if last_map.is_empty():
		print("MapProgressionManager: No maps in sequence '%s'" % sequence_name)
		return ""
	
	# Mark all maps except the last as completed
	var maps = get_sequence_maps(sequence_name)
	for i in range(maps.size() - 1):
		if not maps[i] in completed_maps:
			completed_maps.append(maps[i])
	
	# Unlock the last map
	if not last_map in unlocked_maps:
		unlocked_maps.append(last_map)
	
	save_player_progress()
	print("MapProgressionManager: Skipped to last map '%s' in sequence '%s'" % [last_map, sequence_name])
	return last_map

# Get the lab map to return to after completing a sequence
func get_sequence_lab_map(sequence_name: String) -> String:
	if not sequences.has(sequence_name):
		return "Lab/map_data"
	
	var sequence = sequences[sequence_name]
	return sequence.get("lab_map", "Lab/map_data")

# Unlock all maps in all sequences (explorer mode)
func unlock_all_sequences() -> void:
	print("MapProgressionManager: Unlocking all sequences (Explorer Mode)")
	
	for seq_name in sequences.keys():
		var maps = get_sequence_maps(seq_name)
		for map_name in maps:
			if not map_name in unlocked_maps:
				unlocked_maps.append(map_name)
				map_unlocked.emit(map_name)
	
	save_player_progress()
	print("MapProgressionManager: All %d maps unlocked" % unlocked_maps.size())

# Check if we should skip to end based on game mode
func should_skip_sequence() -> bool:
	if not is_instance_valid(GameManager):
		return false
	if GameManager.is_test_mode():
		return true
	if GameManager.is_testplus_mode():
		return not GameManager.testplus_full_sequence_active
	return false

# Get next map considering game mode
func get_next_map_for_mode(current_map_name: String) -> String:
	# Check game mode
	if is_instance_valid(GameManager) and (GameManager.is_test_mode() or GameManager.should_testplus_sample_sequence()):
		# In test/testplus sample mode, check if this is the last map in sequence
		for seq_name in sequences.keys():
			var maps = get_sequence_maps(seq_name)
			var idx = maps.find(current_map_name)
			if idx >= 0:
				# In TestPlus, excluded sequences should immediately return to lab
				if GameManager.is_testplus_mode() and GameManager.is_sequence_excluded_in_testplus(seq_name):
					return get_sequence_lab_map(seq_name)
				# If not last map, skip to last
				if idx < maps.size() - 1:
					return maps[maps.size() - 1]
				else:
					# Already at last map, go to lab
					return get_sequence_lab_map(seq_name)
	
	# Default behavior
	return get_next_map(current_map_name)

# Get all available sequences
func get_all_sequence_names() -> Array[String]:
	var result: Array[String] = []
	for seq_name in sequences.keys():
		result.append(str(seq_name))
	return result

# Get sequence info for UI display
func get_sequence_info(sequence_name: String) -> Dictionary:
	if not sequences.has(sequence_name):
		return {}
	
	var seq = sequences[sequence_name]
	var maps = get_sequence_maps(sequence_name)
	
	return {
		"name": seq.get("name", sequence_name),
		"description": seq.get("description", ""),
		"difficulty": seq.get("difficulty", "unknown"),
		"estimated_time": seq.get("estimated_time", "unknown"),
		"map_count": maps.size(),
		"completed_count": _count_completed_in_sequence(sequence_name),
		"completion_percentage": get_sequence_completion_percentage(sequence_name),
		"is_completed": is_sequence_completed(sequence_name),
		"lab_map": seq.get("lab_map", "Lab/map_data")
	}

func _count_completed_in_sequence(sequence_name: String) -> int:
	var maps = get_sequence_maps(sequence_name)
	var count = 0
	for map_name in maps:
		if map_name in completed_maps:
			count += 1
	return count

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
