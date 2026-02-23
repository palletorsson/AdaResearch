# GridSpawnComponent.gd
# Simplified spawn system - reads from JSON map data only
# Handles player spawn positioning and updates reset systems

extends Node
class_name GridSpawnComponent

# References
var data_component: GridDataComponent

# Default spawn position (fallback if no JSON spawn defined)
const DEFAULT_SPAWN_POSITION = Vector3(0.0, 1.8, 0.0)
const DEFAULT_SPAWN_ROTATION = Vector3(0.0, 0.0, 0.0)

# Signals
signal spawn_positioning_complete(spawn_position: Vector3)

func _ready():
	print("GridSpawnComponent: Initialized (simplified)")

# Initialize with data component only
func initialize(data_comp: GridDataComponent, settings: Dictionary = {}):
	data_component = data_comp
	print("GridSpawnComponent: Ready to handle spawning")

# Handle player spawn positioning after map generation
func handle_player_spawn():
 
	print("GridSpawnComponent: STARTING SPAWN POSITIONING")
	 

	# Wait for VR system to be ready
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	# Get spawn data from map JSON
	var spawn_data = _get_spawn_data_from_json()

	print("GridSpawnComponent: Spawn data retrieved:")
	print("  Position: %s" % spawn_data.position)
	print("  Rotation: %s" % spawn_data.rotation)
	print("  Source: %s" % spawn_data.source)

	# Position the player (if available in this runtime mode)
	var player_positioned: bool = _position_player(spawn_data)

	# Update reset systems
	_update_reset_systems(spawn_data.position)

 
	print("GridSpawnComponent: SPAWN POSITIONING COMPLETE (player_positioned=%s)" % str(player_positioned))

	# Always emit completion so desktop/headless runs don't stall on missing VR origin.
	spawn_positioning_complete.emit(spawn_data.position)
 

# Get spawn data from JSON (or use defaults)
func _get_spawn_data_from_json() -> Dictionary:
	"""Returns spawn data with position and rotation"""

	# PRIORITY 1: Check for utility-based spawn (s:x:z:y syntax)
	var utility_spawn = _check_utility_spawn()
	if utility_spawn:
		return utility_spawn

	# PRIORITY 2: Try to get from map JSON spawn_points
	if data_component:
		var spawn_points = data_component.get_spawn_points()
		if spawn_points and not spawn_points.is_empty():
			var default_spawn = spawn_points.get("default", {})
			if not default_spawn.is_empty():
				var pos_array = default_spawn.get("position", [DEFAULT_SPAWN_POSITION.x, DEFAULT_SPAWN_POSITION.y, DEFAULT_SPAWN_POSITION.z])
				var rot_array = default_spawn.get("rotation", [DEFAULT_SPAWN_ROTATION.x, DEFAULT_SPAWN_ROTATION.y, DEFAULT_SPAWN_ROTATION.z])

				var spawn_data = {
					"position": Vector3(pos_array[0], pos_array[1], pos_array[2]),
					"rotation": Vector3(rot_array[0], rot_array[1], rot_array[2]),
					"source": "json"
				}
				print("GridSpawnComponent: Using JSON spawn point: %s" % spawn_data.position)
				return spawn_data

	# PRIORITY 3: Fallback to default
	print("GridSpawnComponent: Using default spawn position: %s" % DEFAULT_SPAWN_POSITION)
	return {
		"position": DEFAULT_SPAWN_POSITION,
		"rotation": DEFAULT_SPAWN_ROTATION,
		"source": "default"
	}

# Check for utility-based spawn coordinates (s:x:y:z)
func _check_utility_spawn() -> Dictionary:
	"""Check if any spawn utility has coordinates set"""
	var parent_node = get_parent()
	if not parent_node:
		print("GridSpawnComponent: No parent node found")
		return {}

	# Find GridUtilitiesComponent
	var utilities_component = parent_node.find_child("GridUtilitiesComponent", false, false)
	if not utilities_component:
		print("GridSpawnComponent: No GridUtilitiesComponent found")
		return {}

	# Get all utility positions from the utilities component
	var utility_positions = utilities_component.get_all_utility_positions()
	print("GridSpawnComponent: 🔍 Checking %d utilities for spawn_coordinates..." % utility_positions.size())

	# Check each utility for spawn_coordinates metadata
	for pos in utility_positions:
		var utility = utilities_component.get_utility_at(pos.x, pos.y, pos.z)
		if utility:
			print("GridSpawnComponent:   - Checking utility at grid(%d,%d,%d): %s" % [pos.x, pos.y, pos.z, utility.name])
			if utility.has_meta("spawn_coordinates"):
				var coords = utility.get_meta("spawn_coordinates")

				# Get cube_size and gutter from data component
				var cube_size = 1.0
				var gutter = 0.0
				if data_component:
					var settings = data_component.get_settings()
					cube_size = settings.get("cube_size", 1.0)
					gutter = settings.get("gutter", 0.0)

				# Convert grid coordinates to world position
				# coords is Vector3(x, y, z) where y is already world height
				var world_pos = Vector3(
					coords.x * (cube_size + gutter),
					coords.y,  # Y is already in world space (height)
					coords.z * (cube_size + gutter)
				)

				var spawn_data = {
					"position": world_pos,
					"rotation": DEFAULT_SPAWN_ROTATION,
					"source": "utility_coordinates"
				}

				print("GridSpawnComponent: ✅ Using utility spawn coordinates: grid(%.1f, %.1f, %.1f) → world%s" % [coords.x, coords.y, coords.z, world_pos])
				return spawn_data

	print("GridSpawnComponent: No spawn_coordinates metadata found on any utility")
	return {}

# Position the player at spawn point
func _position_player(spawn_data: Dictionary) -> bool:
	"""Set player position and rotation"""
	var vr_origin = _find_vr_origin()
	if not vr_origin:
		print("GridSpawnComponent: ERROR - Could not find VR origin")
		return false

	var position = spawn_data.position
	var rotation = spawn_data.rotation

	print("GridSpawnComponent: VR Origin found: %s" % vr_origin.name)
	print("GridSpawnComponent: Current position BEFORE: %s" % vr_origin.global_position)

	vr_origin.global_position = position
	vr_origin.global_rotation_degrees = rotation

	print("GridSpawnComponent: Set position TO: %s" % position)
	print("GridSpawnComponent: Actual position AFTER: %s" % vr_origin.global_position)

	print("GridSpawnComponent: ✓ Player spawned at %s (rotation: %s, source: %s)" % [position, rotation, spawn_data.source])
	return true

# Find VR origin in the scene
func _find_vr_origin() -> Node3D:
	var scene_root = get_tree().current_scene
	if not scene_root:
		return null

	# Look for common VR origin node names
	var origin_names = ["XROrigin3D", "VROrigin", "ARVROrigin", "Origin", "XRPlayer"]

	for name in origin_names:
		var origin = scene_root.find_child(name, true, false)
		if origin and origin is Node3D:
			return origin as Node3D

	return null

# Update reset systems with new spawn position
func _update_reset_systems(spawn_position: Vector3):
	"""Update all reset systems to use this spawn position"""
	var scene_root = get_tree().current_scene
	if not scene_root:
		return

	# Find and update reset systems
	var reset_nodes = [
		scene_root.find_child("ResetArea", true, false),
		scene_root.find_child("ResetArea3D", true, false),
		scene_root.find_child("Reset", true, false),
	]

	for reset_node in reset_nodes:
		if reset_node and reset_node.has_method("set_reset_position"):
			reset_node.set_reset_position(spawn_position)
			print("GridSpawnComponent: Updated %s to spawn position" % reset_node.name)
			return

	print("GridSpawnComponent: No reset system found (this is okay)")
