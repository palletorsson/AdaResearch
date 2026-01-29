class_name ArtifactSpawnManager
extends Node

## Manages artifact spawning with beam effects
## Handles instantiation, positioning, and visual effects

signal artifact_spawned(lookup_name: String, artifact: Node)
signal spawn_failed(lookup_name: String, error: String)

@export var spawn_offset_distance: float = 2.0  # Distance in front of player/spawn point
@export var beam_duration: float = 0.5  # Duration of spawn beam effect

var _current_spawned_artifact: Node = null
var _grid_system: Node = null


func _ready():
	_find_grid_system()


## Find and cache GridSystem reference
func _find_grid_system():
	var scene_tree = get_tree()
	if not scene_tree:
		push_error("ArtifactSpawnManager: No scene tree available")
		return

	# Try to find GridSystem or LabGridSystem
	var grid_systems = scene_tree.get_nodes_in_group("grid_system")
	if grid_systems.size() > 0:
		_grid_system = grid_systems[0]
		return

	# Fallback: search by class name
	var root = scene_tree.current_scene
	if root:
		for child in root.get_children():
			if child.has_method("get_class") and "GridSystem" in str(child.get_class()):
				_grid_system = child
				return

	push_warning("ArtifactSpawnManager: GridSystem not found")


## Spawn an artifact by lookup_name
func spawn_artifact(lookup_name: String) -> bool:
	# Clear existing spawned artifact
	_cleanup_current_artifact()

	# Validate grid system
	if not _grid_system:
		_find_grid_system()
		if not _grid_system:
			spawn_failed.emit(lookup_name, "GridSystem not found")
			return false

	# Get spawn position
	var spawn_pos = _calculate_spawn_position()

	# Get artifact info from registry
	var artifact_info = _get_artifact_info(lookup_name)
	if artifact_info.is_empty():
		spawn_failed.emit(lookup_name, "Artifact not found in registry")
		return false

	# Check if unlocked
	if not ArtifactCatalogDataProvider.is_artifact_unlocked(lookup_name):
		spawn_failed.emit(lookup_name, "Artifact is locked")
		return false

	# Load and instantiate artifact
	var scene_path = artifact_info.get("scene", "")
	if scene_path == "":
		spawn_failed.emit(lookup_name, "No scene path in artifact definition")
		return false

	if not ResourceLoader.exists(scene_path):
		spawn_failed.emit(lookup_name, "Scene file not found: " + scene_path)
		return false

	var artifact = ResourceLoader.load(scene_path).instantiate()
	if not artifact:
		spawn_failed.emit(lookup_name, "Failed to instantiate artifact")
		return false

	# Position artifact
	artifact.position = spawn_pos

	# Apply rotation from artifact definition
	if artifact_info.has("rotation"):
		var rotation_deg = artifact_info.get("rotation", 0.0)
		artifact.rotation_degrees.y = rotation_deg

	# Apply scale from artifact definition
	if artifact_info.has("scale"):
		var scale_data = artifact_info.get("scale")
		if scale_data is Array and scale_data.size() >= 3:
			artifact.scale = Vector3(scale_data[0], scale_data[1], scale_data[2])
		elif scale_data is float or scale_data is int:
			var s = float(scale_data)
			artifact.scale = Vector3(s, s, s)

	# Add to scene
	get_tree().current_scene.add_child(artifact)
	_current_spawned_artifact = artifact

	# Beam effect
	_spawn_beam_effect(artifact)

	# Emit success signal
	artifact_spawned.emit(lookup_name, artifact)

	print("ArtifactSpawnManager: Spawned '%s' at %s" % [lookup_name, spawn_pos])
	return true


## Calculate spawn position based on mode (VR or desktop)
func _calculate_spawn_position() -> Vector3:
	# Check if in VR mode
	if _is_vr_mode():
		var xr_camera = get_viewport().get_camera_3d()
		if xr_camera:
			# Spawn in front of camera
			var forward = -xr_camera.global_transform.basis.z
			return xr_camera.global_position + forward * spawn_offset_distance

	# Desktop mode: use Lab spawn point + forward offset
	var lab_system = _find_lab_system()
	if lab_system and lab_system.has_method("get_spawn_point"):
		var spawn_data = lab_system.get_spawn_point()
		# Offset forward from spawn point
		return spawn_data.position + Vector3(0, 0, spawn_offset_distance)

	# Fallback: spawn at origin with offset
	return Vector3(0, 1, spawn_offset_distance)


## Check if running in VR mode
func _is_vr_mode() -> bool:
	var xr_interface = XRServer.get_primary_interface()
	return xr_interface != null and xr_interface.is_initialized()


## Find LabGridSystem
func _find_lab_system() -> Node:
	var scene_tree = get_tree()
	if not scene_tree:
		return null

	var lab_systems = scene_tree.get_nodes_in_group("lab_system")
	if lab_systems.size() > 0:
		return lab_systems[0]

	return null


## Get artifact info from GridInteractablesComponent registry
func _get_artifact_info(lookup_name: String) -> Dictionary:
	if not _grid_system:
		return {}

	if not _grid_system.has_node("GridInteractablesComponent"):
		return {}

	var interactables = _grid_system.get_node("GridInteractablesComponent")
	if not "grid_artifact_registry" in interactables:
		return {}

	var registry = interactables.grid_artifact_registry
	if registry.has(lookup_name):
		return registry[lookup_name]

	return {}


## Cleanup currently spawned artifact
func _cleanup_current_artifact():
	if _current_spawned_artifact and is_instance_valid(_current_spawned_artifact):
		print("ArtifactSpawnManager: Removing previous artifact")
		_current_spawned_artifact.queue_free()
		_current_spawned_artifact = null


## Spawn beam effect (scale-up animation with elastic easing)
func _spawn_beam_effect(artifact: Node):
	if not artifact or not is_instance_valid(artifact):
		return

	# Store original scale
	var original_scale = artifact.scale

	# Start at zero scale
	artifact.scale = Vector3.ZERO

	# Create tween for smooth scale-up
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(artifact, "scale", original_scale, beam_duration)

	# Optional: Add slight rotation during spawn
	var current_rotation = artifact.rotation
	artifact.rotation.y += deg_to_rad(360)
	tween.parallel().tween_property(artifact, "rotation", current_rotation, beam_duration)


## Public API: Clear currently spawned artifact
func clear_spawned_artifact():
	_cleanup_current_artifact()


## Public API: Get currently spawned artifact
func get_spawned_artifact() -> Node:
	return _current_spawned_artifact
