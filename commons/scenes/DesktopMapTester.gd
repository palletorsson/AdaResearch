extends Node3D
class_name DesktopMapTester

## Desktop Map Tester - Load and test maps without VR
## Use this for quick desktop testing of map sequences

@export var start_map: String = ""  ## Load this single map by name directly (e.g. "Corridor_Point_One"). Overrides start_sequence when set — for testing standalone maps like the corridors.
@export var start_sequence: String = "wavefunctions"  ## Which sequence to start (wavefunctions, noise, etc.)
@export var start_map_index: int = 0  ## Which map in sequence to start at (0 = first map)
@export var auto_load_on_ready: bool = true  ## Auto-load map on scene ready

@onready var grid_system = $GridSystem
@onready var player = $DesktopPlayer

var current_sequence_name: String = ""
var current_sequence_data: Dictionary = {}
var current_map_index: int = 0

func _ready() -> void:
	print("DesktopMapTester: Initializing...")

	# MapToolEditor "Show in desktop" handoff: a one-shot start map in user://current_map.txt.
	if FileAccess.file_exists("user://current_map.txt"):
		var handoff := FileAccess.get_file_as_string("user://current_map.txt").strip_edges()
		if handoff != "":
			start_map = handoff
			print("DesktopMapTester: MapToolEditor handoff → '%s'" % start_map)
			var f := FileAccess.open("user://current_map.txt", FileAccess.WRITE)   # clear (one-shot)
			if f:
				f.store_string("")
				f.close()

	# Connect to AdaSceneManager if available
	if AdaSceneManager.is_available():
		AdaSceneManager.get_instance()
		print("DesktopMapTester: Connected to AdaSceneManager")

	if auto_load_on_ready:
		call_deferred("_auto_load_sequence")

func _auto_load_sequence() -> void:
	# A single map by name (e.g. a Corridor_* sibling) takes priority over the sequence path.
	if not start_map.is_empty():
		print("DesktopMapTester: Loading single map: %s" % start_map)
		load_map(start_map)
		return

	if start_sequence.is_empty():
		print("DesktopMapTester: No start sequence specified")
		return

	load_sequence(start_sequence, start_map_index)

func load_sequence(sequence_name: String, map_index: int = 0) -> void:
	"""Load a sequence and start at specific map"""
	current_sequence_name = sequence_name
	current_map_index = map_index

	# Get sequence config from AdaSceneManager
	if not AdaSceneManager.is_available():
		push_error("DesktopMapTester: AdaSceneManager not available!")
		return

	var scene_manager = AdaSceneManager.get_instance()
	if not scene_manager.sequence_configs.has(sequence_name):
		push_error("DesktopMapTester: Sequence '%s' not found!" % sequence_name)
		push_error("Available sequences: %s" % str(scene_manager.sequence_configs.keys()))
		return

	current_sequence_data = scene_manager.sequence_configs[sequence_name]
	var maps: Array = current_sequence_data.get("maps", [])

	if maps.is_empty():
		push_error("DesktopMapTester: No maps in sequence '%s'" % sequence_name)
		return

	if map_index >= maps.size():
		push_error("DesktopMapTester: Map index %d out of range (max: %d)" % [map_index, maps.size() - 1])
		return

	var map_name: String = str(maps[map_index])
	print("DesktopMapTester: Loading sequence '%s', map %d/%d: %s" % [sequence_name, map_index + 1, maps.size(), map_name])

	load_map(map_name)

func load_map(map_name: String) -> void:
	"""Load a specific map"""
	if not grid_system:
		push_error("DesktopMapTester: GridSystem not found!")
		return

	var map_path: String = _resolve_map_path(map_name)
	if map_path.is_empty():
		push_error("DesktopMapTester: Map file not found for id: %s" % map_name)
		return

	print("DesktopMapTester: Loading map from: %s" % map_path)

	# Load map data
	var file: FileAccess = FileAccess.open(map_path, FileAccess.READ)
	if not file:
		push_error("DesktopMapTester: Could not open map file: %s" % map_path)
		return

	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_result: int = json.parse(json_text)
	if parse_result != OK:
		push_error("DesktopMapTester: Failed to parse map JSON: %s" % json.get_error_message())
		return

	if not (json.data is Dictionary):
		push_error("DesktopMapTester: Parsed map is not a Dictionary: %s" % map_path)
		return

	var map_data: Dictionary = json.data

	# Build the map
	if grid_system.has_method("build_from_data"):
		grid_system.build_from_data(map_data)
		print("DesktopMapTester: Map loaded via build_from_data: %s" % map_name)
		_position_player_at_spawn(map_data)
	elif _reload_grid_system_map(map_name):
		print("DesktopMapTester: Map queued for GridSystem reload: %s" % map_name)
		_position_player_at_spawn(map_data)
	else:
		push_error("DesktopMapTester: GridSystem cannot load map with current API")

func _resolve_map_path(map_name: String) -> String:
	var candidate_paths: Array[String] = _build_map_candidate_paths(map_name)
	for candidate_path in candidate_paths:
		if FileAccess.file_exists(candidate_path):
			return candidate_path
	return ""

func _build_map_candidate_paths(map_name: String) -> Array[String]:
	var map_id: String = map_name.strip_edges()
	var paths: Array[String] = []
	if map_id.is_empty():
		return paths

	if map_id.begins_with("res://"):
		paths.append(map_id)
		if not map_id.ends_with(".json"):
			paths.append("%s/map_data.json" % map_id)
		return paths

	if map_id.ends_with(".json"):
		paths.append("res://commons/maps/%s" % map_id)
	else:
		paths.append("res://commons/maps/%s/map_data.json" % map_id)
		paths.append("res://commons/maps/%s.json" % map_id)

	return paths

func _reload_grid_system_map(map_name: String) -> bool:
	var grid_map_name: String = _normalize_map_identifier_for_grid_system(map_name)
	if "map_name" in grid_system:
		grid_system.map_name = grid_map_name
	else:
		return false

	if "reload_map" in grid_system:
		grid_system.reload_map = true
		return true

	if grid_system.has_method("_reload_current_map"):
		grid_system.call_deferred("_reload_current_map")
		return true

	return false

func _normalize_map_identifier_for_grid_system(map_name: String) -> String:
	var normalized: String = map_name.strip_edges()
	if normalized.begins_with("res://commons/maps/"):
		normalized = normalized.trim_prefix("res://commons/maps/")

	if normalized.ends_with("/map_data.json"):
		normalized = normalized.trim_suffix("/map_data.json")
	elif normalized.ends_with(".json"):
		normalized = normalized.trim_suffix(".json")

	return normalized

func _position_player_at_spawn(map_data: Dictionary) -> void:
	"""Position player at spawn point"""
	if not player:
		return

	# Look for spawn point in utilities layer
	var layers: Dictionary = map_data.get("layers", {})
	var utilities: Array = layers.get("utilities", [])

	# Find 's' spawn marker
	for z in range(utilities.size()):
		var row: Variant = utilities[z]
		if not (row is Array):
			continue
		var row_array: Array = row
		for x in range(row_array.size()):
			var cell: Variant = row_array[x]
			if typeof(cell) == TYPE_STRING and str(cell).begins_with("s"):
				# Position player at spawn (convert grid coords to world)
				var spawn_pos: Vector3 = Vector3(x, 3.0, z)  # above floor top; gravity settles the player
				player.global_position = spawn_pos
				print("DesktopMapTester: Player spawned at grid position (%d, %d) = %s" % [x, z, spawn_pos])
				return

	print("DesktopMapTester: No spawn point found, using default position")

func next_map() -> void:
	"""Load next map in sequence"""
	if current_sequence_data.is_empty():
		print("DesktopMapTester: No sequence loaded")
		return

	var maps: Array = current_sequence_data.get("maps", [])
	if current_map_index + 1 >= maps.size():
		print("DesktopMapTester: End of sequence reached")
		return

	current_map_index += 1
	load_sequence(current_sequence_name, current_map_index)

func previous_map() -> void:
	"""Load previous map in sequence"""
	if current_map_index <= 0:
		print("DesktopMapTester: Already at first map")
		return

	current_map_index -= 1
	load_sequence(current_sequence_name, current_map_index)

func _input(event: InputEvent) -> void:
	"""Handle input for map navigation"""
	if event.is_action_pressed("ui_page_down"):
		next_map()
	elif event.is_action_pressed("ui_page_up"):
		previous_map()
	elif event.is_action_pressed("ui_home"):
		# Reload current map
		load_sequence(current_sequence_name, current_map_index)

	# Game Mode controls
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				_set_game_mode(GameManager.GameMode.STORY)
			KEY_F2:
				_set_game_mode(GameManager.GameMode.TEST)
			KEY_F3:
				_set_game_mode(GameManager.GameMode.EXPLORER)
			KEY_F4:
				_set_game_mode(GameManager.GameMode.TESTPLUS)
			KEY_F5:
				_skip_to_sequence_end()
			KEY_F6:
				_print_debug_info()

func _set_game_mode(mode: GameManager.GameMode) -> void:
	"""Set game mode with feedback"""
	GameManager.set_game_mode(mode)
	print("=======================================")
	print("  GAME MODE: %s" % GameManager.get_game_mode_name())
	print("=======================================")

	if mode == GameManager.GameMode.EXPLORER:
		MapProgressionManager.unlock_all_sequences()
		print("  All sequences unlocked!")

func _skip_to_sequence_end() -> void:
	"""Skip to last map of current sequence"""
	if current_sequence_name.is_empty():
		print("DesktopMapTester: No sequence loaded")
		return

	var last_map: String = MapProgressionManager.skip_to_sequence_end(current_sequence_name)
	if not last_map.is_empty():
		load_map(last_map)
		print("DesktopMapTester: Skipped to last map: %s" % last_map)

func _print_debug_info() -> void:
	"""Print debug information"""
	print("=======================================")
	print("  DEBUG INFO")
	print("=======================================")
	print("  Game Mode: %s" % GameManager.get_game_mode_name())
	print("  Current Sequence: %s" % current_sequence_name)
	print("  Current Map Index: %d" % current_map_index)
	print("  Completed Maps: %d" % MapProgressionManager.get_completed_maps().size())
	print("  Unlocked Maps: %d" % MapProgressionManager.get_unlocked_maps().size())
	print("---------------------------------------")
	print("  CONTROLS:")
	print("    F1 = Story Mode")
	print("    F2 = Test Mode (skip sequences)")
	print("    F3 = Explorer Mode (unlock all)")
	print("    F4 = TestPlus Mode")
	print("    F5 = Skip to sequence end")
	print("    F6 = Debug Info")
	print("    PageUp/Down = Prev/Next map")
	print("=======================================")
