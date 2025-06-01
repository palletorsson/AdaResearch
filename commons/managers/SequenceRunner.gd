# SequenceRunner.gd - Simplified sequence execution for grid.tscn
extends Node3D
class_name SequenceRunner

# Scene references
@onready var grid_system = get_node("../multiLayerGrid")
@onready var fade_area = get_node("../FadeArea")

# Sequence state
var current_sequence: String = ""
var current_sequence_def: Dictionary = {}
var current_step: int = 0
var total_steps: int = 0
var sequence_maps: Array[String] = []

# Collected artifacts for return to lab
var collected_artifacts: Array = []

# Fade effect
var is_fading: bool = false
var fade_timer: float = 0.0
var fade_duration: float = 0.8

# Signals
signal sequence_completed(sequence_name: String, artifacts: Array)
signal map_transition_started(from_map: String, to_map: String)
signal map_transition_completed(map_name: String)

func _ready():
	print("SequenceRunner: Initializing")
	_setup_grid_connections()
	_start_sequence_from_metadata()

func _setup_grid_connections():
	if grid_system:
		# Connect to utility activation (teleports)
		if grid_system.has_signal("interactable_activated"):
			grid_system.interactable_activated.connect(_on_grid_interactable_activated)
		print("SequenceRunner: Connected to grid system")
	else:
		print("SequenceRunner: ERROR - Grid system not found")

func _start_sequence_from_metadata():
	# Get sequence data from staging metadata
	var staging = get_node("/root/VRStaging")
	if staging and staging.has_meta("sequence_data"):
		var sequence_data = staging.get_meta("sequence_data")
		var sequence_name = sequence_data.get("sequence_name", "")
		
		if not sequence_name.is_empty():
			_load_and_start_sequence(sequence_name)
		else:
			print("SequenceRunner: ERROR - No sequence name in metadata")
	else:
		print("SequenceRunner: ERROR - No sequence data in staging metadata")

func _load_and_start_sequence(sequence_name: String):
	print("SequenceRunner: Loading sequence '%s'" % sequence_name)
	
	# Load sequence definition
	if sequence_name == "array_tutorial":
		current_sequence_def = {
			"name": "Array Tutorial",
			"maps": ["Tutorial_Single", "Tutorial_Row", "Tutorial_2D", "Tutorial_Disco"],
			"description": "Learn array fundamentals through interactive visualization"
		}
	else:
		print("SequenceRunner: ERROR - Unknown sequence '%s'" % sequence_name)
		return
	
	current_sequence = sequence_name
	sequence_maps = current_sequence_def.maps
	total_steps = sequence_maps.size()
	current_step = 0
	
	print("SequenceRunner: Starting sequence with %d maps: %s" % [total_steps, str(sequence_maps)])
	
	# Start first map
	_advance_to_next_step()

func _advance_to_next_step():
	if current_step >= total_steps:
		_complete_sequence()
		return
	
	var map_name = sequence_maps[current_step]
	print("SequenceRunner: Step %d/%d - Loading map '%s'" % [current_step + 1, total_steps, map_name])
	
	# Load the map in grid system FIRST
	await _load_map_with_transition(map_name)
	
	# THEN position player after grid is fully created
	_position_player_for_map(map_name)
	
	current_step += 1

func _position_player_for_map(map_name: String):
	# Find spawn point in map data and position player
	var spawn_position = _get_spawn_position_from_map_data(map_name)
	_teleport_player_to_position(spawn_position)

func _get_spawn_position_from_map_data(map_name: String) -> Vector3:
	# Try to find spawn point from map utilities
	if grid_system:
		var spawn_pos = _find_spawn_point_in_grid()
		if spawn_pos != Vector3.ZERO:
			print("SequenceRunner: Found spawn point in grid at %s" % str(spawn_pos))
			return spawn_pos
	
	# Fallback to map-specific default positions
	return _get_default_spawn_position_for_map(map_name)

func _find_spawn_point_in_grid() -> Vector3:
	# Look for spawn point utility in the grid system
	if not grid_system:
		return Vector3.ZERO
	
	# Check if grid has utility objects
	if grid_system.has_method("get") and grid_system.get("utility_objects"):
		var utility_objects = grid_system.get("utility_objects")
		
		# Find spawn point utility
		for key in utility_objects.keys():
			var utility = utility_objects[key]
			if utility and utility.name.contains("spawn"):
				var grid_pos = key as Vector3i
				var world_pos = _grid_to_world_position(grid_pos)
				# Simple: use X and Z from spawn point, always Y=10 for drop
				return Vector3(world_pos.x, 10, world_pos.z)
	
	return Vector3.ZERO

func _grid_to_world_position(grid_pos: Vector3i) -> Vector3:
	# Convert grid coordinates to world position
	var cube_size = 1.0
	var gutter = 0.0
	if grid_system:
		if grid_system.has_method("get"):
			cube_size = grid_system.get("cube_size") if grid_system.get("cube_size") else 1.0
			gutter = grid_system.get("gutter") if grid_system.get("gutter") else 0.0
	
	var total_size = cube_size + gutter
	return Vector3(grid_pos.x, grid_pos.y, grid_pos.z) * total_size

func _get_default_spawn_position_for_map(map_name: String) -> Vector3:
	# Default spawn position - start much higher so player drops down safely
	var default_spawn = Vector3(0, 10, -2)
	
	# Map-specific spawn positions as fallback
	match map_name:
		"Tutorial_Single":
			return Vector3(0, 10, -1)
		"Tutorial_Row":
			return Vector3(-2, 10, 0)
		"Tutorial_2D":
			return Vector3(-3, 10, -3)
		"Tutorial_Disco":
			return Vector3(0, 10, -4)
		_:
			return default_spawn

func _teleport_player_to_position(position: Vector3):
	var xr_origin = get_node("../XROrigin3D")
	if xr_origin:
		xr_origin.position = position
		print("SequenceRunner: Player positioned at %s" % str(position))
	else:
		print("SequenceRunner: WARNING - Could not find XROrigin3D")

func _load_map_with_transition(map_name: String):
	map_transition_started.emit("", map_name)
	
	# Start fade effect
	_start_fade_transition()
	
	# Wait for fade, then load map
	await get_tree().create_timer(fade_duration * 0.5).timeout
	
	# Load map in grid system
	if grid_system and grid_system.has_method("generate_layout"):
		grid_system.map_name = map_name
		grid_system.generate_layout()
		print("SequenceRunner: Map '%s' loaded" % map_name)
	else:
		print("SequenceRunner: ERROR - Cannot load map")
	
	# Complete fade
	await get_tree().create_timer(fade_duration * 0.5).timeout
	_end_fade_transition()
	
	map_transition_completed.emit(map_name)

func _start_fade_transition():
	is_fading = true
	fade_timer = 0.0
	print("SequenceRunner: Starting fade transition")

func _end_fade_transition():
	is_fading = false
	print("SequenceRunner: Fade transition complete")

func _process(delta):
	if is_fading:
		fade_timer += delta
		var fade_progress = min(fade_timer / fade_duration, 1.0)
		_update_fade_effect(fade_progress)

func _update_fade_effect(progress: float):
	# Simple fade effect - can be improved with actual visual overlay
	var camera = get_node("../XROrigin3D/XRCamera3D")
	if camera and camera.has_method("set_environment"):
		# Adjust environment brightness for fade effect
		var fade_brightness = 1.0 - abs(progress * 2.0 - 1.0)  # Fade out then in
		# This is a placeholder - you'd want proper fade overlay in real implementation

func _on_grid_interactable_activated(object_id: String, position: Vector3i, data = null):
	print("SequenceRunner: Grid interactable activated: %s at %s" % [object_id, str(position)])
	
	# Handle exit portals and teleports
	if object_id == "exit_portal" or object_id == "teleporter" or object_id.begins_with("exit") or object_id == "e":
		_handle_teleport_activation()
	
	# Handle other interactables (collect artifacts, etc.)
	_handle_interactable_collection(object_id, position, data)

func _handle_teleport_activation():
	print("SequenceRunner: Teleport activated - advancing to next step")
	
	# Small delay for player to register the teleport
	await get_tree().create_timer(0.5).timeout
	_advance_to_next_step()

func _handle_interactable_collection(object_id: String, position: Vector3i, data):
	# Collect artifacts/rewards from interactions
	var artifact = {
		"id": object_id,
		"map": sequence_maps[current_step - 1] if current_step > 0 else "",
		"position": position,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	collected_artifacts.append(artifact)
	print("SequenceRunner: Collected artifact: %s" % str(artifact))

func _complete_sequence():
	print("SequenceRunner: Sequence '%s' completed!" % current_sequence)
	print("SequenceRunner: Collected %d artifacts" % collected_artifacts.size())
	
	# Return to lab with artifacts
	_return_to_lab()

func _return_to_lab():
	print("SequenceRunner: Returning to lab with artifacts")
	
	# Store completion data
	var completion_data = {
		"sequence": current_sequence,
		"artifacts": collected_artifacts,
		"completion_time": Time.get_unix_time_from_system()
	}
	
	# Start fade transition back to lab
	_start_fade_transition()
	
	await get_tree().create_timer(fade_duration * 0.5).timeout
	
	# Load lab scene
	var staging = get_node("/root/VRStaging")
	if staging and staging.has_method("load_scene"):
		staging.set_meta("completion_data", completion_data)
		staging.load_scene("res://commons/scenes/lab.tscn")
	else:
		print("SequenceRunner: ERROR - Could not access VRStaging for return")

# Public API
func get_current_sequence_info() -> Dictionary:
	return {
		"sequence_name": current_sequence,
		"current_step": current_step,
		"total_steps": total_steps,
		"current_map": sequence_maps[current_step - 1] if current_step > 0 else "",
		"next_map": sequence_maps[current_step] if current_step < total_steps else "",
		"progress_percentage": float(current_step) / float(total_steps) * 100.0,
		"collected_artifacts": collected_artifacts.size()
	}

func force_complete_sequence():
	print("SequenceRunner: Force completing sequence")
	_complete_sequence()

func skip_to_step(step_number: int):
	if step_number >= 0 and step_number < total_steps:
		current_step = step_number
		_advance_to_next_step()
	else:
		print("SequenceRunner: Invalid step number %d" % step_number) 