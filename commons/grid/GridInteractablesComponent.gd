# GridInteractablesComponent.gd
# Handles placement of interactable artifacts and objects
# Uses grid_artifact_registry for simple object placement

extends Node
class_name GridInteractablesComponent

# Path constants - CORRECTED TO MATCH ACTUAL PROJECT STRUCTURE
const ARTIFACTS_JSON_PATH = "res://commons/artifacts/grid_artifacts.json"

# References
var parent_node: Node3D
var structure_component: GridStructureComponent
var utilities_component: GridUtilitiesComponent

# Settings
var cube_size: float = 1.0
var gutter: float = 0.0

# Interactable objects tracking
var interactable_objects: Dictionary = {}
var scene_cache: Dictionary = {}

# Artifact registry loaded from JSON
var grid_artifact_registry: Dictionary = {}


# Signals
signal interactables_generation_complete(interactable_count: int)
signal interactable_activated(object_id: String, position: Vector3, data: Dictionary)

func _ready():
	print("GridInteractablesComponent: Initialized")
	_load_artifact_registry()

# Load artifact registry from JSON file
func _load_artifact_registry():
	print("GridInteractablesComponent: Loading artifact registry from JSON...")
	
	if not FileAccess.file_exists(ARTIFACTS_JSON_PATH):
		push_error("GridInteractablesComponent: Artifacts JSON file not found: %s" % ARTIFACTS_JSON_PATH)
		return
	
	var file = FileAccess.open(ARTIFACTS_JSON_PATH, FileAccess.READ)
	if not file:
		push_error("GridInteractablesComponent: Could not open artifacts file: %s" % ARTIFACTS_JSON_PATH)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		push_error("GridInteractablesComponent: Failed to parse artifacts JSON: %s" % json.get_error_message())
		return
	
	var json_data = json.data
	grid_artifact_registry = json_data.get("artifacts", {})
	
	if grid_artifact_registry.is_empty():
		push_warning("GridInteractablesComponent: No artifacts found in JSON file")
		return
	
	print("GridInteractablesComponent: Loaded %d artifact definitions from JSON" % grid_artifact_registry.size())
	
	# Log loaded artifacts for verification
	for artifact_id in grid_artifact_registry.keys():
		var artifact = grid_artifact_registry[artifact_id]
		print("  → %s: %s" % [artifact_id, artifact.get("name", "Unnamed")])

# Get artifact info by ID
func get_artifact_info(artifact_id: String) -> Dictionary:
	return grid_artifact_registry.get(artifact_id, {})

# Check if artifact exists in registry
func has_artifact(artifact_id: String) -> bool:
	return grid_artifact_registry.has(artifact_id)

# Initialize with references and settings
func initialize(grid_parent: Node3D, struct_component: GridStructureComponent, util_component: GridUtilitiesComponent, settings: Dictionary = {}):
	parent_node = grid_parent
	structure_component = struct_component
	utilities_component = util_component
	
	# Apply settings
	cube_size = settings.get("cube_size", 1.0)
	gutter = settings.get("gutter", 0.0)
	
	print("GridInteractablesComponent: Initialized with cube_size=%f, gutter=%f" % [cube_size, gutter])

# Generate interactables from data
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
	
	print("GridInteractablesComponent: Generating interactables")
	
	var total_size = cube_size + gutter
	var interactable_count = 0
	
	# Get grid dimensions from structure component
	var dimensions = structure_component.get_grid_dimensions()
	
	for z in range(min(dimensions.z, interactable_layout.size())):
		var row = interactable_layout[z]
		for x in range(min(dimensions.x, row.size())):
			var artifact_id = str(row[x]).strip_edges()
			
			if artifact_id != " " and not artifact_id.is_empty():
				if has_artifact(artifact_id):
					var y_pos = structure_component.find_highest_y_at(x, z)
					
					# Adjust for utilities at same position
					if utilities_component and utilities_component.has_utility_at(x, y_pos, z):
						y_pos += 1
					
					_place_artifact(x, y_pos, z, artifact_id, total_size)
					interactable_count += 1
				else:
					print("GridInteractablesComponent: WARNING - Artifact '%s' not found in registry" % artifact_id)
	
	print("GridInteractablesComponent: Added %d interactables" % interactable_count)
	interactables_generation_complete.emit(interactable_count)

# Place a single artifact
func _place_artifact(x: int, y: int, z: int, artifact_id: String, total_size: float):
	var position = Vector3(x, y, z) * total_size
	
	var artifact_info = get_artifact_info(artifact_id)
	var scene_path = artifact_info.get("scene", "")
	
	if scene_path.is_empty():
		print("GridInteractablesComponent: WARNING - No scene path for artifact '%s'" % artifact_id)
		return
	
	var artifact_object = _load_and_instantiate_artifact(scene_path)
	if artifact_object:
		artifact_object.position = position
		
		# Apply position/rotation/scale from artifact definition
		_apply_artifact_transform(artifact_object, artifact_info)
		
		# Set artifact metadata
		artifact_object.set_meta("artifact_id", artifact_id)
		artifact_object.set_meta("artifact_name", artifact_info.get("name", artifact_id))
		artifact_object.set_meta("category", artifact_info.get("category", "unknown"))
		artifact_object.set_meta("description", artifact_info.get("description", ""))
		
		# Update labels if they exist
		_update_artifact_labels(artifact_object, artifact_id, artifact_info)
		
		# Connect signals if artifact has them
		_connect_artifact_signals(artifact_object, artifact_id)
		
		parent_node.add_child(artifact_object)
		
		# Set owner for editor
		if parent_node.get_tree() and parent_node.get_tree().edited_scene_root:
			artifact_object.owner = parent_node.get_tree().edited_scene_root
		
		interactable_objects[Vector3i(x, y, z)] = artifact_object
		
		print("  Added artifact '%s' (%s) at (%d,%d,%d)" % [artifact_info.get("name", artifact_id), artifact_id, x, y, z])

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
func _update_artifact_labels(artifact_object: Node3D, artifact_id: String, artifact_info: Dictionary):
	# Look for common label names
	var label_names = ["id_info_Label3D", "Label3D", "InfoLabel"]
	
	for label_name in label_names:
		var label = artifact_object.find_child(label_name)
		if label and label is Label3D:
			var artifact_name = artifact_info.get("name", artifact_id)
			label.text = str(artifact_id) + ": " + str(artifact_name)
			print("  Updated label: %s" % label.text)
			break

# Connect artifact signals
func _connect_artifact_signals(artifact_object: Node3D, artifact_id: String):
	# Connect common interaction signals
	if artifact_object.has_signal("interact"):
		artifact_object.interact.connect(_on_artifact_interact.bind(artifact_id, artifact_object))
	
	if artifact_object.has_signal("activated"):
		artifact_object.activated.connect(_on_artifact_activated.bind(artifact_id, artifact_object))
	
	if artifact_object.has_signal("artifact_activated"):
		artifact_object.artifact_activated.connect(_on_artifact_activated.bind(artifact_id, artifact_object))

# Handle artifact interaction
func _on_artifact_interact(artifact_id: String, artifact_object: Node3D):
	var artifact_data = {
		"position": artifact_object.global_position,
		"name": artifact_object.get_meta("artifact_name", artifact_id),
		"category": artifact_object.get_meta("category", "unknown"),
		"description": artifact_object.get_meta("description", "")
	}
	
	interactable_activated.emit(artifact_id, artifact_object.global_position, artifact_data)

# Handle artifact activation
func _on_artifact_activated(artifact_id: String, artifact_object: Node3D):
	_on_artifact_interact(artifact_id, artifact_object)

# Load scene with caching
func _load_scene_cached(scene_path: String) -> PackedScene:
	if scene_cache.has(scene_path):
		return scene_cache[scene_path]
	
	print("GridInteractablesComponent: Attempting to load scene: %s" % scene_path)
	
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

# Get artifacts by category
func get_artifacts_by_category(category: String) -> Array:
	var result = []
	for artifact_id in grid_artifact_registry.keys():
		var artifact_info = grid_artifact_registry[artifact_id]
		if artifact_info.get("category", "") == category:
			result.append({
				"id": artifact_id,
				"info": artifact_info
			})
	return result

# Get all available artifact categories
func get_available_categories() -> Array:
	var categories = []
	for artifact_id in grid_artifact_registry.keys():
		var artifact_info = grid_artifact_registry[artifact_id]
		var category = artifact_info.get("category", "unknown")
		if not categories.has(category):
			categories.append(category)
	return categories
