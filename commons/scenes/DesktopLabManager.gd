extends Node3D
class_name DesktopLabManager

# Simple desktop lab manager for testing sequences without VR/SceneManager

@onready var lab_grid_system = $"../LabGridSystem"
@onready var desktop_player = $"../DesktopPlayer"

var current_sequence: String = ""
var current_map_index: int = 0

func _ready():
	print("DesktopLabManager: Initializing desktop lab manager...")

	# Wait a frame for LabGridSystem to initialize
	await get_tree().process_frame

	# Connect to LabGridSystem signals
	if lab_grid_system:
		print("DesktopLabManager: Found LabGridSystem")

		if lab_grid_system.has_signal("lab_sequence_triggered"):
			lab_grid_system.lab_sequence_triggered.connect(_on_sequence_triggered)
			print("DesktopLabManager: Connected to lab_sequence_triggered")

		if lab_grid_system.has_signal("lab_artifact_activated"):
			lab_grid_system.lab_artifact_activated.connect(_on_artifact_activated)
			print("DesktopLabManager: Connected to lab_artifact_activated")

		# Connect to utilities component for teleporter activations
		if lab_grid_system.utilities_component:
			lab_grid_system.utilities_component.utility_activated.connect(_on_utility_activated)
			print("DesktopLabManager: Connected to utility_activated")
	else:
		push_error("DesktopLabManager: LabGridSystem not found!")

	print("DesktopLabManager: Ready")

func _on_artifact_activated(artifact_id: String):
	"""Handle artifact activation"""
	print("DesktopLabManager: Artifact activated: %s" % artifact_id)

	# Map artifacts to sequences
	var sequence_map = {
		"rotating_cube": "array_tutorial",
		"randomness_sign": "randomness",
		"xyz_coordinates": "vectors",
		"grid_display": "noise",
		"probability_sphere": "wavefunctions"
	}

	if artifact_id in sequence_map:
		var sequence = sequence_map[artifact_id]
		print("DesktopLabManager: Starting sequence: %s" % sequence)
		_start_sequence(sequence)

func _on_sequence_triggered(sequence_name: String):
	"""Handle sequence trigger from lab"""
	print("DesktopLabManager: Sequence triggered: %s" % sequence_name)
	_start_sequence(sequence_name)

func _on_utility_activated(utility_type: String, position: Vector3, data: Dictionary):
	"""Handle utility activation (teleporters)"""
	print("DesktopLabManager: ⚡ Utility activated signal received - type: %s, data: %s" % [utility_type, data])

	if utility_type == "t":
		# Teleporter activated
		var destination = data.get("destination", "")
		print("DesktopLabManager: Teleporter to: %s" % destination)

		# If we're already in a sequence, just advance to next map instead of starting over
		if not current_sequence.is_empty():
			print("DesktopLabManager: Already in sequence - advancing to next map instead")
			_next_map_in_sequence()
			return

		# Check if destination is a sequence name
		if _is_sequence_name(destination):
			_start_sequence(destination)
		else:
			# It's a direct map name
			_load_map(destination)

func _is_sequence_name(name: String) -> bool:
	"""Check if name is a known sequence"""
	var known_sequences = [
		"array_tutorial", "primitives", "transformation", "color", "randomness",
		"wavefunctions", "noise", "vectors", "fractals", "forces", "softbodies",
		"meshestextures", "joints", "cellularautomata", "particles", "oscillation",
		"physics", "proceduralaudio", "physicssimulation", "recursiveemergence",
		"lsystems", "swarmintelligence", "patterngeneration", "proceduralgeneration",
		"searchpathfinding", "topology", "graphtheory", "computationalgeometry",
		"machinelearning", "criticalalgorithms", "speculativecomputation",
		"resourcemanagement", "advancedlaboratory", "testmaps"
	]
	return name in known_sequences

func _load_map(map_name: String):
	"""Load a single map directly"""
	print("DesktopLabManager: Loading single map: %s" % map_name)

	if lab_grid_system:
		lab_grid_system.map_name = map_name
		lab_grid_system.reload_map = true

func _start_sequence(sequence_name: String):
	"""Start a sequence by loading its first map"""
	current_sequence = sequence_name
	current_map_index = 0

	# Get sequence configuration from AdaSceneManager
	if not AdaSceneManager.is_available():
		push_error("DesktopLabManager: AdaSceneManager not available!")
		_fallback_load_sequence(sequence_name)
		return

	var scene_manager = AdaSceneManager.get_instance()
	if not scene_manager.sequence_configs.has(sequence_name):
		push_error("DesktopLabManager: Sequence '%s' not found!" % sequence_name)
		return

	var sequence_data = scene_manager.sequence_configs[sequence_name]
	var maps = sequence_data.get("maps", [])

	if maps.is_empty():
		push_error("DesktopLabManager: No maps in sequence '%s'" % sequence_name)
		return

	# Get first map name
	var first_map = maps[0]
	print("DesktopLabManager: Loading first map of '%s': %s" % [sequence_name, first_map])

	# Load the map in the lab grid system
	if lab_grid_system:
		lab_grid_system.map_name = first_map
		lab_grid_system.reload_map = true

		# Wait for map to generate, then move player to spawn
		if lab_grid_system.has_signal("map_generation_complete"):
			if not lab_grid_system.map_generation_complete.is_connected(_on_map_loaded):
				lab_grid_system.map_generation_complete.connect(_on_map_loaded)
				print("DesktopLabManager: Connected to map_generation_complete signal")
			else:
				print("DesktopLabManager: Already connected to map_generation_complete signal")

func _fallback_load_sequence(sequence_name: String):
	"""Fallback method if AdaSceneManager not available"""
	print("DesktopLabManager: Using fallback sequence loading for '%s'" % sequence_name)

	# Simple hardcoded first maps for common sequences
	var first_maps = {
		"array_tutorial": "Tutorial_Single",
		"primitives": "Primitives_Cube",
		"randomness": "Random_Define",
		"wavefunctions": "Wavefunctions_Intro",
		"noise": "Noise_Perlin",
		"vectors": "Vectors_Basic"
	}

	var map_name = first_maps.get(sequence_name, "")
	if map_name.is_empty():
		push_error("DesktopLabManager: No fallback map for sequence '%s'" % sequence_name)
		return

	print("DesktopLabManager: Loading fallback map: %s" % map_name)
	if lab_grid_system:
		lab_grid_system.map_name = map_name
		lab_grid_system.reload_map = true

func _input(event):
	"""Handle keyboard input for quick testing"""
	# R key - return to lab
	if event.is_action_pressed("ui_text_backspace") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
		print("DesktopLabManager: R key pressed - returning to lab")
		_return_to_lab()

	# N key - next map in sequence (if in a sequence)
	if event is InputEventKey and event.pressed and event.keycode == KEY_N and not current_sequence.is_empty():
		print("DesktopLabManager: N key pressed - next map")
		_next_map_in_sequence()

	# P key - previous map in sequence
	if event is InputEventKey and event.pressed and event.keycode == KEY_P and not current_sequence.is_empty():
		print("DesktopLabManager: P key pressed - previous map")
		_previous_map_in_sequence()

func _return_to_lab():
	"""Return to the lab"""
	print("DesktopLabManager: Returning to lab")
	current_sequence = ""
	current_map_index = 0

	if lab_grid_system:
		lab_grid_system.map_name = "Lab"
		lab_grid_system.reload_map = true

func _next_map_in_sequence():
	"""Load next map in current sequence"""
	if current_sequence.is_empty():
		return

	if not AdaSceneManager.is_available():
		print("DesktopLabManager: Cannot navigate sequence - AdaSceneManager not available")
		return

	var scene_manager = AdaSceneManager.get_instance()
	if not scene_manager.sequence_configs.has(current_sequence):
		return

	var sequence_data = scene_manager.sequence_configs[current_sequence]
	var maps = sequence_data.get("maps", [])

	if current_map_index < maps.size() - 1:
		current_map_index += 1
		var next_map = maps[current_map_index]
		print("DesktopLabManager: Loading next map [%d/%d]: %s" % [current_map_index + 1, maps.size(), next_map])

		if lab_grid_system:
			lab_grid_system.map_name = next_map
			lab_grid_system.reload_map = true

			# Wait for map to generate, then move player to spawn
			if lab_grid_system.has_signal("map_generation_complete"):
				if not lab_grid_system.map_generation_complete.is_connected(_on_map_loaded):
					lab_grid_system.map_generation_complete.connect(_on_map_loaded)
	else:
		print("DesktopLabManager: Already at last map in sequence")

func _previous_map_in_sequence():
	"""Load previous map in current sequence"""
	if current_sequence.is_empty():
		return

	if current_map_index > 0:
		current_map_index -= 1

		if not AdaSceneManager.is_available():
			return

		var scene_manager = AdaSceneManager.get_instance()
		if not scene_manager.sequence_configs.has(current_sequence):
			return

		var sequence_data = scene_manager.sequence_configs[current_sequence]
		var maps = sequence_data.get("maps", [])

		var prev_map = maps[current_map_index]
		print("DesktopLabManager: Loading previous map [%d/%d]: %s" % [current_map_index + 1, maps.size(), prev_map])

		if lab_grid_system:
			lab_grid_system.map_name = prev_map
			lab_grid_system.reload_map = true

			# Wait for map to generate, then move player to spawn
			if lab_grid_system.has_signal("map_generation_complete"):
				if not lab_grid_system.map_generation_complete.is_connected(_on_map_loaded):
					lab_grid_system.map_generation_complete.connect(_on_map_loaded)
	else:
		print("DesktopLabManager: Already at first map in sequence")

func _on_map_loaded():
	"""Called when a map finishes generating - move player to spawn point"""
	print("DesktopLabManager: Map generation complete - moving player to spawn")

	# Wait for spawn component and physics to be ready
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout

	if not lab_grid_system or not desktop_player:
		print("DesktopLabManager: Missing lab_grid_system or desktop_player")
		return

	# Get spawn position using the same method as GridSpawnComponent
	var spawn_pos = _get_spawn_position()

	# Move player to spawn position with extra height clearance
	var final_pos = spawn_pos + Vector3(0, 0.5, 0)  # Small offset above spawn point
	desktop_player.global_position = final_pos

	# Reset velocity to prevent falling through
	desktop_player.velocity = Vector3.ZERO

	print("DesktopLabManager: Moved player to spawn at: %s" % final_pos)

func _get_spawn_position() -> Vector3:
	"""Get spawn position from the map data (mimics GridSpawnComponent logic)"""

	# Check for utility-based spawn (s marker in utilities layer)
	var utilities_component = lab_grid_system.utilities_component
	if utilities_component and utilities_component.has_method("get_all_utility_positions"):
		var utility_positions = utilities_component.get_all_utility_positions()
		print("DesktopLabManager: Checking %d utilities for spawn markers" % utility_positions.size())
		for pos in utility_positions:
			var utility = utilities_component.get_utility_at(pos.x, pos.y, pos.z)
			if utility:
				# Check if this is a spawn utility
				if utility.name.begins_with("Spawn") or utility.has_meta("spawn_coordinates"):
					if utility.has_meta("spawn_coordinates"):
						var coords = utility.get_meta("spawn_coordinates")
						# coords is already in world space
						var world_pos = Vector3(coords.x, coords.y, coords.z)
						print("DesktopLabManager: ✓ Found spawn utility at: %s" % world_pos)
						return world_pos
					else:
						# Use the utility's position
						var world_pos = utility.global_position
						print("DesktopLabManager: ✓ Found spawn utility (using position): %s" % world_pos)
						return world_pos

	# Check data component for spawn points
	var data_component = lab_grid_system.data_component
	if data_component and data_component.has_method("get_spawn_points"):
		var spawn_points = data_component.get_spawn_points()
		if spawn_points and not spawn_points.is_empty():
			var default_spawn = spawn_points.get("default", {})
			if not default_spawn.is_empty():
				var pos_array = default_spawn.get("position", [0.0, 1.8, 0.0])
				var spawn_pos = Vector3(pos_array[0], pos_array[1], pos_array[2])
				print("DesktopLabManager: ✓ Using JSON spawn point: %s" % spawn_pos)
				return spawn_pos

	# Fallback to default - elevated position to avoid getting stuck
	var default_pos = Vector3(0.0, 3.0, 0.0)
	print("DesktopLabManager: ⚠ Using fallback spawn position: %s" % default_pos)
	return default_pos
