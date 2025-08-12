# GridInteractablesComponent.gd - IMPROVED with lookup_name validation
# Handles placement of interactable artifacts and objects
# Uses lookup_name as the central identifier system

extends Node
class_name GridInteractablesComponent

# Path constants
const DEFAULT_ARTIFACTS_JSON_PATH = "res://commons/artifacts/grid_artifacts.json"

# References
var parent_node: Node3D
var structure_component: GridStructureComponent
var utilities_component: GridUtilitiesComponent
var map_data_component: GridDataComponent  # Add reference to data component

# Settings
var cube_size: float = 1.0
var gutter: float = 0.0

# Interactable objects tracking
var interactable_objects: Dictionary = {}
var scene_cache: Dictionary = {}

# Artifact registry loaded from JSON - indexed by lookup_name
var grid_artifact_registry: Dictionary = {}

# Signals
signal interactables_generation_complete(interactable_count: int)
signal interactable_activated(object_id: String, position: Vector3, data: Dictionary)

func _ready():
	print("GridInteractablesComponent: Initialized with lookup_name validation")
	# Artifact registry will be loaded during initialization with map data

# Load artifact registries based on map configuration
func _load_artifact_registries():
	print("GridInteractablesComponent: Loading artifact registries with lookup_name validation...")
	
	# Get artifact registries from map external references
	var artifact_paths = _get_artifact_registry_paths()
	
	var total_loaded = 0
	var validation_errors = []
	var validation_warnings = []
	
	for registry_path in artifact_paths:
		var loaded_count = _load_single_artifact_registry(registry_path, validation_errors, validation_warnings)
		total_loaded += loaded_count
	
	# Report validation results
	if validation_errors.size() > 0:
		push_error("GridInteractablesComponent: VALIDATION ERRORS in artifact registries:")
		for error in validation_errors:
			push_error("  - %s" % error)
	
	if validation_warnings.size() > 0:
		print("GridInteractablesComponent: Validation warnings:")
		for warning in validation_warnings:
			print("  - %s" % warning)
	
	print("GridInteractablesComponent: ✅ Loaded %d validated artifacts from %d registries" % [total_loaded, artifact_paths.size()])

# Get artifact registry paths from map data
func _get_artifact_registry_paths() -> Array[String]:
	var paths: Array[String] = []
	
	# Try to get from map's external references
	if map_data_component and map_data_component.json_loader:
		var external_refs = map_data_component.json_loader.map_data.get("external_references", {})
		var artifact_registries = external_refs.get("artifact_registries", [])
		
		if artifact_registries.size() > 0:
			print("GridInteractablesComponent: Using artifact registries from map: %s" % str(artifact_registries))
			for path in artifact_registries:
				paths.append(str(path))
			return paths
	
	# Fallback to default
	print("GridInteractablesComponent: Using default artifact registry")
	paths.append(DEFAULT_ARTIFACTS_JSON_PATH)
	return paths

# Load a single artifact registry file
func _load_single_artifact_registry(registry_path: String, validation_errors: Array, validation_warnings: Array) -> int:
	print("GridInteractablesComponent: Loading registry: %s" % registry_path)
	
	if not FileAccess.file_exists(registry_path):
		push_error("GridInteractablesComponent: Artifacts JSON file not found: %s" % registry_path)
		return 0
	
	var file = FileAccess.open(registry_path, FileAccess.READ)
	if not file:
		push_error("GridInteractablesComponent: Could not open artifacts file: %s" % registry_path)
		return 0
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		push_error("GridInteractablesComponent: Failed to parse artifacts JSON: %s" % json.get_error_message())
		return 0
	
	var json_data = json.data
	var raw_artifacts = json_data.get("artifacts", {})
	
	if raw_artifacts.is_empty():
		push_warning("GridInteractablesComponent: No artifacts found in JSON file: %s" % registry_path)
		return 0
	
	var loaded_count = 0
	
	# Process and validate each artifact with lookup_name
	for artifact_key in raw_artifacts.keys():
		var artifact_data = raw_artifacts[artifact_key]
		
		# Validate required fields
		if not artifact_data.has("lookup_name"):
			validation_errors.append("Artifact '%s' missing required 'lookup_name' field in %s" % [artifact_key, registry_path])
			continue
		
		if not artifact_data.has("scene"):
			validation_errors.append("Artifact '%s' missing required 'scene' field in %s" % [artifact_key, registry_path])
			continue
		
		var lookup_name = artifact_data["lookup_name"]
		
		# Validate lookup_name consistency
		if lookup_name != artifact_key:
			validation_errors.append("Artifact key '%s' doesn't match lookup_name '%s' in %s" % [artifact_key, lookup_name, registry_path])
			continue
		
		# Check for duplicates
		if grid_artifact_registry.has(lookup_name):
			validation_warnings.append("Duplicate artifact '%s' found in %s (overriding previous definition)" % [lookup_name, registry_path])
		
		# Validate lookup_name format
		if not _is_valid_lookup_name(lookup_name):
			validation_warnings.append("Artifact '%s' has non-standard lookup_name format (prefer snake_case) in %s" % [lookup_name, registry_path])
		
		# Store using lookup_name as key
		grid_artifact_registry[lookup_name] = artifact_data
		loaded_count += 1
		
		print("  → Registered artifact: %s ('%s')" % [lookup_name, artifact_data.get("name", "Unnamed")])
	
	return loaded_count

# Validate lookup_name format (prefer snake_case)
func _is_valid_lookup_name(lookup_name: String) -> bool:
	# Check for snake_case pattern: lowercase letters, numbers, underscores only
	var regex = RegEx.new()
	regex.compile("^[a-z][a-z0-9_]*$")
	return regex.search(lookup_name) != null

# Get artifact info by lookup_name
func get_artifact_info(lookup_name: String) -> Dictionary:
	if not grid_artifact_registry.has(lookup_name):
		push_warning("GridInteractablesComponent: Unknown artifact lookup_name: '%s'" % lookup_name)
		print("GridInteractablesComponent: Available artifacts: %s" % str(grid_artifact_registry.keys()))
		return {}
	
	return grid_artifact_registry[lookup_name]

# Check if artifact exists by lookup_name
func has_artifact(lookup_name: String) -> bool:
	return grid_artifact_registry.has(lookup_name)

# Initialize with references and settings
func initialize(grid_parent: Node3D, struct_component: GridStructureComponent, util_component: GridUtilitiesComponent, data_component: GridDataComponent, settings: Dictionary = {}):
	parent_node = grid_parent
	structure_component = struct_component
	utilities_component = util_component
	map_data_component = data_component
	
	# Apply settings
	cube_size = settings.get("cube_size", 1.0)
	gutter = settings.get("gutter", 0.0)
	
	# Load artifact registries based on map configuration
	_load_artifact_registries()
	
	print("GridInteractablesComponent: Initialized with cube_size=%f, gutter=%f" % [cube_size, gutter])

# Generate interactables from data using lookup_name system
func generate_interactables(interactable_data):
	if not interactable_data:
		print("GridInteractablesComponent: No interactable data provided")
		return
	
	# Check for different property names (layout_data vs interactable_data)
	var interactable_layout = null
	if interactable_data.has_method("get") and interactable_data.get("layout_data"):
		interactable_layout = interactable_data.layout_data
	elif interactable_data.has_method("get") and interactable_data.get("interactable_data"):
		interactable_layout = interactable_data.interactable_data
	
	if not interactable_layout:
		print("GridInteractablesComponent: No interactable layout found")
		return
	
	print("GridInteractablesComponent: Generating interactables using lookup_name system")
	
	var total_size = cube_size + gutter
	var interactable_count = 0
	var placement_errors = []
	
	# Get grid dimensions from structure component
	var dimensions = structure_component.get_grid_dimensions()
	
	for z in range(min(dimensions.z, interactable_layout.size())):
		var row = interactable_layout[z]
		for x in range(min(dimensions.x, row.size())):
			var token = str(row[x]).strip_edges()
			
			if token != " " and not token.is_empty():
				var parsed = _parse_interactable_token(token)
				var lookup_name: String = parsed.get("lookup_name", "")
				var overrides: Dictionary = parsed.get("overrides", {})
				
				if has_artifact(lookup_name):
					var y_pos = structure_component.find_highest_y_at(x, z)
					
					# Adjust for utilities at same position
					if utilities_component and utilities_component.has_utility_at(x, y_pos, z):
						y_pos += 1
					
					if _place_artifact(x, y_pos, z, lookup_name, total_size, overrides):
						interactable_count += 1
					else:
						placement_errors.append("Failed to place artifact '%s' at (%d,%d,%d)" % [lookup_name, x, y_pos, z])
				else:
					placement_errors.append("Unknown artifact lookup_name '%s' at grid position (%d,%d)" % [lookup_name, x, z])
	
	# Report results
	if placement_errors.size() > 0:
		print("GridInteractablesComponent: Placement errors:")
		for error in placement_errors:
			print("  - %s" % error)
		print("GridInteractablesComponent: Available artifacts: %s" % str(grid_artifact_registry.keys()))
	
	print("GridInteractablesComponent: ✅ Successfully placed %d interactables" % interactable_count)
	interactables_generation_complete.emit(interactable_count)

# Place a single artifact using lookup_name
func _place_artifact(x: int, y: int, z: int, lookup_name: String, total_size: float, overrides: Dictionary = {}) -> bool:
	var position = Vector3(x, y, z) * total_size
	
	var artifact_info = get_artifact_info(lookup_name)
	if artifact_info.is_empty():
		return false
	
	var scene_path = artifact_info.get("scene", "")
	if scene_path.is_empty():
		print("GridInteractablesComponent: WARNING - No scene path for artifact '%s'" % lookup_name)
		return false
	
	var artifact_object = _load_and_instantiate_artifact(scene_path)
	if not artifact_object:
		print("GridInteractablesComponent: WARNING - Failed to load scene for artifact '%s'" % lookup_name)
		return false
	
	# Position the artifact
	artifact_object.position = position
	
	# Apply position/rotation/scale from artifact definition
	_apply_artifact_transform(artifact_object, artifact_info)

	# Apply per-instance overrides (e.g., scifi_panel_wall:45 → rotate Y by 45 degrees)
	if overrides.has("rotation_y_degrees"):
		var ry = float(overrides.get("rotation_y_degrees", 0.0))
		var current = artifact_object.rotation_degrees
		current.y = ry
		artifact_object.rotation_degrees = current
	
	# Set artifact metadata using both lookup_name and display name
	artifact_object.set_meta("artifact_lookup_name", lookup_name)
	artifact_object.set_meta("artifact_id", lookup_name)  # For compatibility
	artifact_object.set_meta("artifact_name", artifact_info.get("name", lookup_name))
	artifact_object.set_meta("artifact_type", artifact_info.get("artifact_type", "unknown"))
	artifact_object.set_meta("description", artifact_info.get("description", ""))
	artifact_object.set_meta("sequence", artifact_info.get("sequence", ""))
	
	# Update labels if they exist
	_update_artifact_labels(artifact_object, lookup_name, artifact_info)
	
	# Connect signals if artifact has them
	_connect_artifact_signals(artifact_object, lookup_name)
	
	parent_node.add_child(artifact_object)
	
	# Set owner for editor
	if parent_node.get_tree() and parent_node.get_tree().edited_scene_root:
		artifact_object.owner = parent_node.get_tree().edited_scene_root
	
	interactable_objects[Vector3i(x, y, z)] = artifact_object
	
	var display_name = artifact_info.get("name", lookup_name)
	print("  ✅ Placed artifact '%s' (%s) at (%d,%d,%d)" % [display_name, lookup_name, x, y, z])
	
	return true

# Parse compact token syntax from map JSON cells.
# Examples:
#   "scifi_panel_wall"           → { lookup_name: "scifi_panel_wall", overrides: {} }
#   "scifi_panel_wall:45"        → { lookup_name: "scifi_panel_wall", overrides: { rotation_y_degrees: 45 } }
func _parse_interactable_token(token: String) -> Dictionary:
	var result := {"lookup_name": token, "overrides": {}}
	if token.find(":") == -1:
		return result
	var parts = token.split(":", false)
	if parts.size() < 2:
		return result
	var name = parts[0].strip_edges()
	var param = parts[1].strip_edges()
	result.lookup_name = name
	# If numeric param, treat as yaw degrees
	if param.is_valid_float():
		result.overrides["rotation_y_degrees"] = float(param)
	return result

# Apply transform data from artifact definition
func _apply_artifact_transform(artifact_object: Node3D, artifact_info: Dictionary):
	# Apply rotation if specified in artifact definition
	if artifact_info.has("rotation"):
		var rotation_data = artifact_info["rotation"]
		if rotation_data is Array and rotation_data.size() >= 3:
			artifact_object.rotation_degrees = Vector3(rotation_data[0], rotation_data[1], rotation_data[2])
	
	# Apply scale if specified in artifact definition
	if artifact_info.has("scale"):
		var scale_data = artifact_info["scale"]
		if scale_data is Array and scale_data.size() >= 3:
			artifact_object.scale = Vector3(scale_data[0], scale_data[1], scale_data[2])
		elif scale_data is float or scale_data is int:
			artifact_object.scale = Vector3.ONE * scale_data

# Load and instantiate artifact scene
func _load_and_instantiate_artifact(scene_path: String) -> Node3D:
	var scene_resource = _load_scene_cached(scene_path)
	if scene_resource:
		return scene_resource.instantiate()
	return null

# Update artifact labels with information
func _update_artifact_labels(artifact_object: Node3D, lookup_name: String, artifact_info: Dictionary):
	# Look for common label names
	var label_names = ["id_info_Label3D", "Label3D", "InfoLabel"]
	
	for label_name in label_names:
		var label = artifact_object.find_child(label_name)
		if label and label is Label3D:
			var display_name = artifact_info.get("name", lookup_name)
			label.text = "%s: %s" % [lookup_name, display_name]
			print("  Updated label: %s" % label.text)
			break

# Connect artifact signals using lookup_name
func _connect_artifact_signals(artifact_object: Node3D, lookup_name: String):
	# Connect common interaction signals
	if artifact_object.has_signal("interact"):
		artifact_object.interact.connect(_on_artifact_interact.bind(lookup_name, artifact_object))
	
	if artifact_object.has_signal("activated"):
		artifact_object.activated.connect(_on_artifact_activated.bind(lookup_name, artifact_object))
	
	if artifact_object.has_signal("artifact_activated"):
		artifact_object.artifact_activated.connect(_on_artifact_activated.bind(lookup_name, artifact_object))

# Handle artifact interaction
func _on_artifact_interact(lookup_name: String, artifact_object: Node3D):
	var artifact_info = get_artifact_info(lookup_name)
	var artifact_data = {
		"lookup_name": lookup_name,
		"position": artifact_object.global_position,
		"name": artifact_info.get("name", lookup_name),
		"artifact_type": artifact_info.get("artifact_type", "unknown"),
		"description": artifact_info.get("description", ""),
		"sequence": artifact_info.get("sequence", "")
	}
	
	print("GridInteractablesComponent: Artifact interaction - %s ('%s')" % [lookup_name, artifact_info.get("name", "")])
	interactable_activated.emit(lookup_name, artifact_object.global_position, artifact_data)

# Handle artifact activation
func _on_artifact_activated(lookup_name: String, artifact_object: Node3D):
	_on_artifact_interact(lookup_name, artifact_object)

# Load scene with caching
func _load_scene_cached(scene_path: String) -> PackedScene:
	if scene_cache.has(scene_path):
		return scene_cache[scene_path]
	
	print("GridInteractablesComponent: Loading scene: %s" % scene_path)
	
	if ResourceLoader.exists(scene_path):
		var scene = ResourceLoader.load(scene_path)
		scene_cache[scene_path] = scene
		print("GridInteractablesComponent: ✅ Successfully loaded scene: %s" % scene_path)
		return scene
	else:
		print("GridInteractablesComponent: ❌ ERROR - Scene file not found: %s" % scene_path)
		return null

# Get interactable at position
func get_interactable_at(x: int, y: int, z: int) -> Node3D:
	var key = Vector3i(x, y, z)
	return interactable_objects.get(key, null)

# Check if position has interactable
func has_interactable_at(x: int, y: int, z: int) -> bool:
	return interactable_objects.has(Vector3i(x, y, z))

# Clear all interactables
func clear_interactables():
	print("GridInteractablesComponent: Clearing all interactables")
	
	for key in interactable_objects.keys():
		var interactable = interactable_objects[key]
		if is_instance_valid(interactable):
			interactable.queue_free()
	
	interactable_objects.clear()

# Get interactable count
func get_interactable_count() -> int:
	return interactable_objects.size()

# Get all interactable positions
func get_all_interactable_positions() -> Array:
	return interactable_objects.keys()

# Get artifacts by type using lookup_name system
func get_artifacts_by_type(artifact_type: String) -> Array:
	var result = []
	for lookup_name in grid_artifact_registry.keys():
		var artifact_info = grid_artifact_registry[lookup_name]
		if artifact_info.get("artifact_type", "") == artifact_type:
			result.append({
				"lookup_name": lookup_name,
				"info": artifact_info
			})
	return result

# Get all available artifact types
func get_available_artifact_types() -> Array:
	var types = []
	for lookup_name in grid_artifact_registry.keys():
		var artifact_info = grid_artifact_registry[lookup_name]
		var artifact_type = artifact_info.get("artifact_type", "unknown")
		if not types.has(artifact_type):
			types.append(artifact_type)
	return types

# Debug: Print artifact registry status
func print_artifact_registry_status():
	print("=== GridInteractablesComponent Artifact Registry ===")
	print("Total artifacts loaded: %d" % grid_artifact_registry.size())
	print("Artifacts by lookup_name:")
	
	for lookup_name in grid_artifact_registry.keys():
		var artifact_info = grid_artifact_registry[lookup_name]
		var display_name = artifact_info.get("name", "Unnamed")
		var scene_path = artifact_info.get("scene", "No scene")
		var artifact_type = artifact_info.get("artifact_type", "unknown")
		print("  → %s: '%s' (%s) - %s" % [lookup_name, display_name, artifact_type, scene_path])
	
	print("Available artifact types: %s" % str(get_available_artifact_types()))
	print("================================================")
