extends Node3D
class_name DesktopMapTester

## Desktop Map Tester - Load and test maps without VR
## Use this for quick desktop testing of map sequences

@export var start_sequence: String = "wavefunctions"  ## Which sequence to start (wavefunctions, noise, etc.)
@export var start_map_index: int = 0  ## Which map in sequence to start at (0 = first map)
@export var auto_load_on_ready: bool = true  ## Auto-load map on scene ready

@onready var grid_system = $GridSystem
@onready var player = $DesktopPlayer

var current_sequence_name: String = ""
var current_sequence_data: Dictionary = {}
var current_map_index: int = 0

func _ready():
	print("DesktopMapTester: Initializing...")

	# Connect to AdaSceneManager if available
	if AdaSceneManager.is_available():
		var scene_manager = AdaSceneManager.get_instance()
		print("DesktopMapTester: Connected to AdaSceneManager")

	if auto_load_on_ready:
		call_deferred("_auto_load_sequence")

func _auto_load_sequence():
	if start_sequence.is_empty():
		print("DesktopMapTester: No start sequence specified")
		return

	load_sequence(start_sequence, start_map_index)

func load_sequence(sequence_name: String, map_index: int = 0):
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
	var maps = current_sequence_data.get("maps", [])

	if maps.is_empty():
		push_error("DesktopMapTester: No maps in sequence '%s'" % sequence_name)
		return

	if map_index >= maps.size():
		push_error("DesktopMapTester: Map index %d out of range (max: %d)" % [map_index, maps.size() - 1])
		return

	var map_name = maps[map_index]
	print("DesktopMapTester: Loading sequence '%s', map %d/%d: %s" % [sequence_name, map_index + 1, maps.size(), map_name])

	load_map(map_name)

func load_map(map_name: String):
	"""Load a specific map"""
	if not grid_system:
		push_error("DesktopMapTester: GridSystem not found!")
		return

	var map_path = "res://commons/maps/%s/map_data.json" % map_name

	if not FileAccess.file_exists(map_path):
		push_error("DesktopMapTester: Map file not found: %s" % map_path)
		return

	print("DesktopMapTester: Loading map from: %s" % map_path)

	# Load map data
	var file = FileAccess.open(map_path, FileAccess.READ)
	if not file:
		push_error("DesktopMapTester: Could not open map file: %s" % map_path)
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)

	if parse_result != OK:
		push_error("DesktopMapTester: Failed to parse map JSON: %s" % json.get_error_message())
		return

	var map_data = json.data

	# Build the map
	if grid_system.has_method("build_from_data"):
		grid_system.build_from_data(map_data)
		print("DesktopMapTester: ✅ Map loaded successfully: %s" % map_name)
		_position_player_at_spawn(map_data)
	else:
		push_error("DesktopMapTester: GridSystem doesn't have build_from_data method!")

func _position_player_at_spawn(map_data: Dictionary):
	"""Position player at spawn point"""
	if not player:
		return

	# Look for spawn point in utilities layer
	var layers = map_data.get("layers", {})
	var utilities = layers.get("utilities", [])

	# Find 's' spawn marker
	for z in range(utilities.size()):
		var row = utilities[z]
		for x in range(row.size()):
			var cell = row[x]
			if typeof(cell) == TYPE_STRING and cell.begins_with("s"):
				# Position player at spawn (convert grid coords to world)
				var spawn_pos = Vector3(x, 1.8, z)
				player.global_position = spawn_pos
				print("DesktopMapTester: Player spawned at grid position (%d, %d) = %s" % [x, z, spawn_pos])
				return

	print("DesktopMapTester: No spawn point found, using default position")

func next_map():
	"""Load next map in sequence"""
	if current_sequence_data.is_empty():
		print("DesktopMapTester: No sequence loaded")
		return

	var maps = current_sequence_data.get("maps", [])
	if current_map_index + 1 >= maps.size():
		print("DesktopMapTester: End of sequence reached")
		return

	current_map_index += 1
	load_sequence(current_sequence_name, current_map_index)

func previous_map():
	"""Load previous map in sequence"""
	if current_map_index <= 0:
		print("DesktopMapTester: Already at first map")
		return

	current_map_index -= 1
	load_sequence(current_sequence_name, current_map_index)

func _input(event):
	"""Handle input for map navigation"""
	if event.is_action_pressed("ui_page_down"):
		next_map()
	elif event.is_action_pressed("ui_page_up"):
		previous_map()
	elif event.is_action_pressed("ui_home"):
		# Reload current map
		load_sequence(current_sequence_name, current_map_index)
	
	# Game Mode controls (F1-F3)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				_set_game_mode(GameManager.GameMode.STORY)
			KEY_F2:
				_set_game_mode(GameManager.GameMode.TEST)
			KEY_F3:
				_set_game_mode(GameManager.GameMode.EXPLORER)
			KEY_F4:
				_print_debug_info()
			KEY_F5:
				_skip_to_sequence_end()

func _set_game_mode(mode: GameManager.GameMode):
	"""Set game mode with feedback"""
	GameManager.set_game_mode(mode)
	print("═══════════════════════════════════════")
	print("  GAME MODE: %s" % GameManager.get_game_mode_name())
	print("═══════════════════════════════════════")
	
	if mode == GameManager.GameMode.EXPLORER:
		MapProgressionManager.unlock_all_sequences()
		print("  All sequences unlocked!")

func _skip_to_sequence_end():
	"""Skip to last map of current sequence"""
	if current_sequence_name.is_empty():
		print("DesktopMapTester: No sequence loaded")
		return
	
	var last_map = MapProgressionManager.skip_to_sequence_end(current_sequence_name)
	if not last_map.is_empty():
		load_map(last_map)
		print("DesktopMapTester: Skipped to last map: %s" % last_map)

func _print_debug_info():
	"""Print debug information"""
	print("═══════════════════════════════════════")
	print("  DEBUG INFO")
	print("═══════════════════════════════════════")
	print("  Game Mode: %s" % GameManager.get_game_mode_name())
	print("  Current Sequence: %s" % current_sequence_name)
	print("  Current Map Index: %d" % current_map_index)
	print("  Completed Maps: %d" % MapProgressionManager.get_completed_maps().size())
	print("  Unlocked Maps: %d" % MapProgressionManager.get_unlocked_maps().size())
	print("───────────────────────────────────────")
	print("  CONTROLS:")
	print("    F1 = Story Mode")
	print("    F2 = Test Mode (skip sequences)")
	print("    F3 = Explorer Mode (unlock all)")
	print("    F4 = Debug Info")
	print("    F5 = Skip to sequence end")
	print("    PageUp/Down = Prev/Next map")
	print("═══════════════════════════════════════")
