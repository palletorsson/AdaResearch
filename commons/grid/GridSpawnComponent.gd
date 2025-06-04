# GridSpawnComponent.gd
# Handles player spawn positioning based on map data
# Uses spawn points from utilities or JSON spawn definitions

extends Node
class_name GridSpawnComponent

# References
var structure_component: GridStructureComponent
var utilities_component: GridUtilitiesComponent
var data_component: GridDataComponent

# Settings
var cube_size: float = 1.0
var gutter: float = 0.0

# Signals
signal spawn_positioning_complete(spawn_position: Vector3)

func _ready():
	print("GridSpawnComponent: Initialized")

# Initialize with references and settings
func initialize(struct_component: GridStructureComponent, util_component: GridUtilitiesComponent, data_comp: GridDataComponent, settings: Dictionary = {}):
	structure_component = struct_component
	utilities_component = util_component
	data_component = data_comp
	
	# Apply settings
	cube_size = settings.get("cube_size", 1.0)
	gutter = settings.get("gutter", 0.0)
	
	print("GridSpawnComponent: Initialized with cube_size=%f, gutter=%f" % [cube_size, gutter])

# Handle player spawn positioning after map generation
func handle_player_spawn():
	print("GridSpawnComponent: Handling player spawn positioning...")
	
	# Wait for VR system to be ready
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	
	# Try grid-based spawn points first (utility "s" type)
	var spawn_point_position = _find_grid_spawn_point()
	
	if spawn_point_position != Vector3.ZERO:
		print("GridSpawnComponent: Found grid spawn point at: %s" % spawn_point_position)
		_position_player_at_grid_spawn(spawn_point_position)
	else:
		# Fallback to JSON spawn points
		_handle_json_spawn_points()

# Find spawn points from utility grid (type "s")
func _find_grid_spawn_point() -> Vector3:
	if not utilities_component:
		return Vector3.ZERO
	
	# Look for spawn point utilities in the grid
	var utility_positions = utilities_component.get_all_utility_positions()
	
	for pos in utility_positions:
		var utility = utilities_component.get_utility_at(pos.x, pos.y, pos.z)
		if utility and utility.get_meta("spawn_name", "") != "":
			# Found a spawn point utility
			return Vector3(pos.x, pos.y, pos.z)
	
	return Vector3.ZERO

# Position player at grid-based spawn point
func _position_player_at_grid_spawn(grid_position: Vector3):
	var vr_origin = _find_vr_origin()
	if not vr_origin:
		print("GridSpawnComponent: WARNING - Could not find VR origin")
		return
	
	# Get spawn properties from utility or JSON
	var spawn_height = _get_spawn_height_from_data()
	var spawn_rotation = _get_spawn_rotation_from_data()
	
	# Convert grid coordinates to world coordinates
	var total_size = cube_size + gutter
	var world_position = grid_position * total_size
	
	# Apply reasonable height constraints
	spawn_height = clamp(spawn_height, 1.5, 3.0)
	var final_position = Vector3(world_position.x, spawn_height, world_position.z)
	
	# Apply position and rotation
	vr_origin.global_position = final_position
	vr_origin.global_rotation_degrees = Vector3(0, spawn_rotation, 0)
	
	print("GridSpawnComponent: ✓ Player positioned at grid spawn")
	print("  Grid position: %s" % grid_position)
	print("  World position: %s (height: %f)" % [final_position, spawn_height])
	print("  Rotation: %f degrees" % spawn_rotation)
	
	_apply_spawn_transition_effect(vr_origin)
	spawn_positioning_complete.emit(final_position)

# Handle JSON-defined spawn points as fallback
func _handle_json_spawn_points():
	print("GridSpawnComponent: No grid spawn points found, checking JSON spawn points...")
	
	if not data_component:
		_apply_default_spawn_position()
		return
	
	var spawn_points = data_component.get_spawn_points()
	if spawn_points.is_empty():
		print("GridSpawnComponent: No JSON spawn points defined, using default")
		_apply_default_spawn_position()
		return
	
	# Use default spawn point from JSON
	var default_spawn = spawn_points.get("default", {})
	if not default_spawn.is_empty():
		_position_player_at_json_spawn(default_spawn)
	else:
		_apply_default_spawn_position()

# Position player at JSON-defined spawn point
func _position_player_at_json_spawn(spawn_data: Dictionary):
	var spawn_position = spawn_data.get("position", [0, 1.5, 0])
	var spawn_rotation = spawn_data.get("rotation", [0, 0, 0])
	
	# Convert arrays to Vector3
	var world_position = Vector3(spawn_position[0], spawn_position[1], spawn_position[2])
	var world_rotation = Vector3(spawn_rotation[0], spawn_rotation[1], spawn_rotation[2])
	
	print("GridSpawnComponent: Positioning player at JSON spawn - Position: %s, Rotation: %s" % [world_position, world_rotation])
	
	var vr_origin = _find_vr_origin()
	if not vr_origin:
		print("GridSpawnComponent: WARNING - Could not find VR origin")
		return
	
	# Apply position (spawn points are in world coordinates)
	vr_origin.global_position = world_position
	vr_origin.global_rotation_degrees = world_rotation
	
	print("GridSpawnComponent: ✓ Player positioned at JSON spawn")
	
	_apply_spawn_transition_effect(vr_origin)
	spawn_positioning_complete.emit(world_position)

# Apply default spawn position when no spawn points are defined
func _apply_default_spawn_position():
	var vr_origin = _find_vr_origin()
	if not vr_origin:
		return
	
	# Position player at a reasonable default location
	var default_position = Vector3(0, 2, 3)  # Slightly elevated and back from center
	vr_origin.global_position = default_position
	vr_origin.global_rotation_degrees = Vector3.ZERO
	
	print("GridSpawnComponent: Applied default spawn position: %s" % default_position)
	spawn_positioning_complete.emit(default_position)

# Get spawn height from utility metadata or JSON
func _get_spawn_height_from_data() -> float:
	# Try to get from utility definition first
	if data_component:
		var utility_definitions = data_component.get_utility_definitions()
		var spawn_def = utility_definitions.get("s", {})
		var properties = spawn_def.get("properties", {})
		
		if properties.has("height"):
			return float(properties["height"])
	
	return 1.8  # Default VR player height

# Get spawn rotation from utility metadata or JSON
func _get_spawn_rotation_from_data() -> float:
	# Try to get from utility definition first
	if data_component:
		var utility_definitions = data_component.get_utility_definitions()
		var spawn_def = utility_definitions.get("s", {})
		var properties = spawn_def.get("properties", {})
		
		if properties.has("player_rotation"):
			return float(properties["player_rotation"])
	
	return 0.0  # Default rotation

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
			print("GridSpawnComponent: Found VR origin: %s" % origin.name)
			return origin as Node3D
	
	print("GridSpawnComponent: Could not find VR origin")
	return null

# Apply spawn transition effect
func _apply_spawn_transition_effect(vr_origin: Node3D):
	# Wait for everything to settle
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Add a gentle camera movement to help orient the player
	_apply_gentle_orientation_cue(vr_origin)
	
	print("GridSpawnComponent: Spawn transition complete")

# Gentle orientation cue for player
func _apply_gentle_orientation_cue(vr_origin: Node3D):
	var tween = create_tween()
	var original_position = vr_origin.global_position
	
	# Gentle up-down motion to indicate spawn
	tween.tween_property(vr_origin, "global_position", original_position + Vector3(0, 0.1, 0), 0.3)
	tween.tween_property(vr_origin, "global_position", original_position, 0.3)
	
	print("GridSpawnComponent: Applied orientation cue")

# Get spawn point info for debugging
func get_spawn_info() -> Dictionary:
	var info = {
		"grid_spawn_found": _find_grid_spawn_point() != Vector3.ZERO,
		"json_spawn_available": false,
		"spawn_height": _get_spawn_height_from_data(),
		"spawn_rotation": _get_spawn_rotation_from_data()
	}
	
	if data_component:
		var spawn_points = data_component.get_spawn_points()
		info["json_spawn_available"] = not spawn_points.is_empty()
		info["json_spawn_points"] = spawn_points.keys()
	
	return info
