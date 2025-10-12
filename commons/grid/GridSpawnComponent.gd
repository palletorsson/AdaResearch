# GridSpawnComponent.gd
# Simplified spawn system - reads from JSON map data only
# Handles player spawn positioning and updates reset systems

extends Node
class_name GridSpawnComponent

# References
var data_component: GridDataComponent

# Default spawn position (fallback if no JSON spawn defined)
const DEFAULT_SPAWN_POSITION = Vector3(2.5, 1.8, 2.5)
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

	# Position the player
	_position_player(spawn_data)

	# Update reset systems
	_update_reset_systems(spawn_data.position)

 
	print("GridSpawnComponent: SPAWN POSITIONING COMPLETE")
 

# Get spawn data from JSON (or use defaults)
func _get_spawn_data_from_json() -> Dictionary:
	"""Returns spawn data with position and rotation"""

	# Try to get from map JSON
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

	# Fallback to default
	print("GridSpawnComponent: Using default spawn position: %s" % DEFAULT_SPAWN_POSITION)
	return {
		"position": DEFAULT_SPAWN_POSITION,
		"rotation": DEFAULT_SPAWN_ROTATION,
		"source": "default"
	}

# Position the player at spawn point
func _position_player(spawn_data: Dictionary):
	"""Set player position and rotation"""
	var vr_origin = _find_vr_origin()
	if not vr_origin:
		print("GridSpawnComponent: ERROR - Could not find VR origin")
		return

	var position = spawn_data.position
	var rotation = spawn_data.rotation

	print("GridSpawnComponent: VR Origin found: %s" % vr_origin.name)
	print("GridSpawnComponent: Current position BEFORE: %s" % vr_origin.global_position)

	vr_origin.global_position = position
	vr_origin.global_rotation_degrees = rotation

	print("GridSpawnComponent: Set position TO: %s" % position)
	print("GridSpawnComponent: Actual position AFTER: %s" % vr_origin.global_position)

	# Wait a frame and check if position stuck
	await get_tree().process_frame
	print("GridSpawnComponent: Position after 1 frame: %s" % vr_origin.global_position)

	print("GridSpawnComponent: ✓ Player spawned at %s (rotation: %s, source: %s)" % [position, rotation, spawn_data.source])

	# Emit completion signal
	spawn_positioning_complete.emit(position)

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
