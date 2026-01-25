# GridInteractablesComponent.gd - IMPROVED with lookup_name validation
# Handles placement of interactable artifacts and objects
# Uses lookup_name as the central identifier system

extends Node
class_name GridInteractablesComponent

# Path constants
const DEFAULT_ARTIFACTS_JSON_PATH = "res://commons/artifacts/grid_artifacts.json"
const REGISTRY_DIR_PATH = "res://commons/artifacts/registry/"

# Known config parameter names (NOT to be treated as tutorial shorthand)
# These are artifact configuration keys that can have numeric values
const CONFIG_PARAM_NAMES = [
	"radial", "rings", "inner", "outer", "config", "height", "radius",
	"width", "depth", "segments", "sides", "rows", "cols", "count",
	"size", "scale", "speed", "delay", "duration", "intensity"
]

# References
var parent_node: Node3D
var structure_component: GridStructureComponent
var utilities_component: GridUtilitiesComponent
var map_data_component: GridDataComponent  # Add reference to data component

# Settings
var cube_size: float = 1.0
var gutter: float = 0.0
var current_palette: String = ""

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

# Get artifact registry paths from map data and registry directory
func _get_artifact_registry_paths() -> Array[String]:
	var paths: Array[String] = []
	
	# 1. Add the main default file
	paths.append(DEFAULT_ARTIFACTS_JSON_PATH)
	
	# 2. Add all JSON files from the registry directory
	var dir = DirAccess.open(REGISTRY_DIR_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".json"):
				paths.append(REGISTRY_DIR_PATH + file_name)
			file_name = dir.get_next()
	
	# 3. Try to get additional overrides from map's external references
	if map_data_component and map_data_component.json_loader:
		var external_refs = map_data_component.json_loader.map_data.get("external_references", {})
		var map_specific_registries = external_refs.get("artifact_registries", [])
		
		if map_specific_registries.size() > 0:
			print("GridInteractablesComponent: Adding map-specific registries: %s" % str(map_specific_registries))
			for path in map_specific_registries:
				if not paths.has(path):
					paths.append(str(path))
	
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
		
		#print("  → Registered artifact: %s ('%s')" % [lookup_name, artifact_data.get("name", "Unnamed")])
	
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
	current_palette = settings.get("palette", "")
	
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
				# Check for special prefixes BEFORE parsing (mc:, gridagent:, etc.)
				# These use the colon as part of their identifier, not as parameter separator
				
				# Check for custom Marching Cubes syntax mc:shape_name
				if token.begins_with("mc:"):
					var parsed = _parse_interactable_token(token)
					var overrides: Dictionary = parsed.get("overrides", {})
					var config_data: Dictionary = parsed.get("config_data", {})
					
					var y_pos = structure_component.find_highest_y_at(x, z)
					if utilities_component and utilities_component.has_utility_at(x, y_pos, z):
						y_pos += 1
						
					if _place_marching_cubes_object(x, y_pos, z, token, total_size, overrides, config_data):
						interactable_count += 1
					else:
						placement_errors.append("Failed to place Marching Cubes object '%s' at (%d,%d,%d)" % [token, x, y_pos, z])
					continue
				
				# Check for Grid Agent syntax gridagent:tier
				if token.begins_with("gridagent:"):
					var parsed = _parse_interactable_token(token)
					var overrides: Dictionary = parsed.get("overrides", {})
					var config_data: Dictionary = parsed.get("config_data", {})

					var y_pos = structure_component.find_highest_y_at(x, z)
					if utilities_component and utilities_component.has_utility_at(x, y_pos, z):
						y_pos += 1

					if _place_grid_agent(x, y_pos, z, token, total_size, overrides, config_data):
						interactable_count += 1
					else:
						placement_errors.append("Failed to place grid agent '%s' at (%d,%d,%d)" % [token, x, y_pos, z])
					continue

				# Check for Critical Info / Dialectic Panel syntax criticalinfo:name:rotation:scale
				if token.begins_with("criticalinfo:"):
					var parts = token.split(":")
					var dialectic_name = parts[1] if parts.size() > 1 else ""
					var rotation = float(parts[2]) if parts.size() > 2 else 0.0
					var scale_factor = float(parts[3]) if parts.size() > 3 else 1.0

					var y_pos = structure_component.find_highest_y_at(x, z)
					var origin = Vector3(x * total_size, y_pos * total_size, z * total_size)

					if _place_dialectic_panels(dialectic_name, origin, rotation, scale_factor):
						interactable_count += 1
						print("GridInteractablesComponent: ✅ Placed dialectic panels '%s' at (%d,%d,%d)" % [dialectic_name, x, y_pos, z])
					else:
						placement_errors.append("Failed to place dialectic panels '%s' at (%d,%d,%d)" % [dialectic_name, x, y_pos, z])
					continue

				# Normal artifact handling (parse token for regular artifacts)
				var parsed = _parse_interactable_token(token)
				var lookup_name: String = parsed.get("lookup_name", "")
				var overrides: Dictionary = parsed.get("overrides", {})
				var config_data: Dictionary = parsed.get("config_data", {})
				var tag: String = parsed.get("tag", "")
				var trigger_action: String = parsed.get("trigger_action", "")

				if has_artifact(lookup_name):
					var y_pos = structure_component.find_highest_y_at(x, z)
					
					# Adjust for utilities at same position
					if utilities_component and utilities_component.has_utility_at(x, y_pos, z):
						y_pos += 1
					
					if _place_artifact(x, y_pos, z, lookup_name, total_size, overrides, config_data, tag, trigger_action):
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

# Place a Marching Cubes object using API
func _place_marching_cubes_object(x: int, y: int, z: int, lookup_name: String, total_size: float, overrides: Dictionary = {}, config_data: Dictionary = {}) -> bool:
	var position = Vector3(x, y, z) * total_size
	
	# Determine if object should be pickable/grabbable
	var is_pickable = false
	if config_data.has("pickable"):
		var val = config_data["pickable"]
		is_pickable = (str(val).to_lower() == "true")
	elif config_data.has("grab"):
		var val = config_data["grab"]
		is_pickable = (str(val).to_lower() == "true")
	
	# Create object using API
	var mc_object = MarchingCubesAPI.create(lookup_name, position, 1.0, is_pickable)
	if not mc_object:
		return false
		
	# Apply common transforms
	if overrides.has("y_position"):
		mc_object.position.y += float(overrides.get("y_position", 0.0))
		
	if overrides.has("uniform_scale"):
		var s = float(overrides.get("uniform_scale", 1.0))
		mc_object.scale = Vector3.ONE * s
		print("GridInteractables: Applied uniform scale %f -> Final scale: %s" % [s, str(mc_object.scale)])
		
	# Apply rotation
	if overrides.has("rotation_y_degrees"):
		mc_object.rotation_degrees.y = float(overrides.get("rotation_y_degrees", 0.0))
	if overrides.has("rotation_x_degrees"):
		mc_object.rotation_degrees.x = float(overrides.get("rotation_x_degrees", 0.0))
	if overrides.has("rotation_z_degrees"):
		mc_object.rotation_degrees.z = float(overrides.get("rotation_z_degrees", 0.0))

	# Apply material if specified
	if config_data.has("material"):
		print("GridInteractables: Applying material '%s' to '%s'" % [str(config_data.get("material")), lookup_name])
		MarchingCubesAPI.apply_material(mc_object, str(config_data.get("material")))
	else:
		print("GridInteractables: No material in config_data for '%s'. Data keys: %s" % [lookup_name, config_data.keys()])

	parent_node.add_child(mc_object)
	interactable_objects[Vector3i(x, y, z)] = mc_object
	
	print("  ✅ Placed Marching Cubes object '%s' at (%d,%d,%d)" % [lookup_name, x, y, z])
	return true

# Place a Grid Agent using gridagent:tier syntax
func _place_grid_agent(x: int, y: int, z: int, lookup_name: String, total_size: float, overrides: Dictionary = {}, config_data: Dictionary = {}) -> bool:
	# Parse: gridagent:tier
	var parts = lookup_name.split(":")
	if parts.size() < 2:
		print("GridInteractablesComponent: Invalid grid agent format: %s" % lookup_name)
		return false
	
	var tier = parts[1].to_lower()  # copy, translate, rotate, scale, color, array, sine, random, ca
	
	# Load appropriate agent scene based on tier
	var scene_path = "res://commons/hazards/gridagent/variants/grid_agent_%s.tscn" % tier
	if not ResourceLoader.exists(scene_path):
		# Fallback to base agent
		scene_path = "res://commons/hazards/gridagent/grid_agent_base.tscn"
		print("GridInteractablesComponent: Tier-specific scene not found, using base agent: %s" % scene_path)
	
	if not ResourceLoader.exists(scene_path):
		print("GridInteractablesComponent: Grid agent base scene not found: %s" % scene_path)
		return false
	
	var agent_scene = load(scene_path)
	var agent = agent_scene.instantiate()
	
	# Position
	var position = Vector3(x, y, z) * total_size
	agent.position = position
	
	# Apply overrides (rotation, y_offset, scale)
	if overrides.has("rotation_y_degrees"):
		agent.rotation_degrees.y = float(overrides.get("rotation_y_degrees", 0.0))
	if overrides.has("y_position"):
		agent.position.y += float(overrides.get("y_position", 0.0))
	if overrides.has("uniform_scale"):
		var s = float(overrides.get("uniform_scale", 1.0))
		agent.scale = Vector3.ONE * s
	
	# Set agent tier via metadata
	agent.set_meta("agent_tier", tier)
	agent.set_meta("spawn_position", Vector3i(x, y, z))
	
	# Initialize agent if it has setup method
	if agent.has_method("set_tier"):
		agent.set_tier(tier)
	
	# Add to scene
	parent_node.add_child(agent)
	interactable_objects[Vector3i(x, y, z)] = agent
	
	print("  ✅ Placed grid agent '%s' (tier: %s) at (%d,%d,%d)" % [lookup_name, tier, x, y, z])
	return true

# Place dialectic panels using DialecticPanelGenerator
func _place_dialectic_panels(dialectic_name: String, origin: Vector3, rotation: float, scale_factor: float) -> bool:
	if dialectic_name.is_empty():
		push_error("GridInteractablesComponent: Empty dialectic name provided")
		return false

	# Create the generator node
	var generator = DialecticPanelGenerator.new()
	generator.name = "DialecticPanels_%s" % dialectic_name

	# Add to parent first so it's in the scene tree
	parent_node.add_child(generator)

	# Generate panels from the dialectic JSON
	var success = generator.generate_from_dialectic(dialectic_name, origin, rotation, scale_factor)

	if not success:
		generator.queue_free()
		return false

	print("GridInteractablesComponent: ✅ Generated %d dialectic panels for '%s'" % [generator.get_panel_count(), dialectic_name])
	return true

# Place a single artifact using lookup_name
func _place_artifact(x: int, y: int, z: int, lookup_name: String, total_size: float, overrides: Dictionary = {}, config_data: Dictionary = {}, tag: String = "", trigger_action: String = "") -> bool:
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
	
	# Handle visibility override from artifact_definitions
	if artifact_info.has("visible"):
		var should_be_visible = artifact_info.get("visible", true)
		if "visible" in artifact_object:
			artifact_object.visible = should_be_visible
			if not should_be_visible:
				print("    Set artifact '%s' to invisible (from artifact_definitions)" % lookup_name)
	
	# Handle different node types (Node3D vs Control)
	if artifact_object is Node3D:
		# Position the 3D artifact (base grid position)
		artifact_object.position = position
		
		# Apply position/rotation/scale from artifact definition
		_apply_artifact_transform(artifact_object, artifact_info)

		# Apply per-instance overrides for 3D objects
		
		# Apply Y position override (e.g., random_number_book_page_1955:0:2.5:1.2 → Y offset +2.5)
		if overrides.has("y_position"):
			var y_offset = float(overrides.get("y_position", 0.0))
			artifact_object.position.y += y_offset
			print("    Applied Y position offset: +%s" % str(y_offset))
		
		# Apply uniform scale override (e.g., random_number_book_page_1955:0:2.5:1.2 → scale all axes by 1.2)
		if overrides.has("uniform_scale"):
			var scale_factor = float(overrides.get("uniform_scale", 1.0))
			artifact_object.scale *= scale_factor
			print("    Applied uniform scale: %s" % str(scale_factor))
		
		# Apply rotation overrides (Z, X, Y axes)
		var rotation_changed = false
		var current_rotation = artifact_object.rotation_degrees

		if overrides.has("rotation_z_degrees"):
			current_rotation.z = float(overrides.get("rotation_z_degrees", 0.0))
			rotation_changed = true
		if overrides.has("rotation_x_degrees"):
			current_rotation.x = float(overrides.get("rotation_x_degrees", 0.0))
			rotation_changed = true
		if overrides.has("rotation_y_degrees"):
			# Use rotate_y() to properly rotate around Y-axis, adding to existing rotation
			# This works correctly even when the scene has a transform matrix
			var y_rotation = float(overrides.get("rotation_y_degrees", 0.0))
			artifact_object.rotate_y(deg_to_rad(y_rotation))
			rotation_changed = true
			# Also try to set an exported yaw property if available (legacy support)
			_try_set_property(artifact_object, "yaw_degrees", artifact_object.rotation_degrees.y)

		if rotation_changed:
			# Only update rotation_degrees if we changed Z or X (Y is handled by rotate_y above)
			if overrides.has("rotation_z_degrees") or overrides.has("rotation_x_degrees"):
				artifact_object.rotation_degrees = current_rotation
			print("    Applied rotation: Z=%s X=%s Y=%s" % [artifact_object.rotation_degrees.z, artifact_object.rotation_degrees.x, artifact_object.rotation_degrees.y])

		# Apply continuous rotation flags
		if overrides.has("continuous_rotation_z") or overrides.has("continuous_rotation_x") or overrides.has("continuous_rotation_y"):
			var cont_z = overrides.get("continuous_rotation_z", false)
			var cont_x = overrides.get("continuous_rotation_x", false)
			var cont_y = overrides.get("continuous_rotation_y", false)

			# Add continuous rotation script
			_add_continuous_rotation(artifact_object, cont_z, cont_x, cont_y)
			print("    Applied continuous rotation: Z=%s X=%s Y=%s" % [cont_z, cont_x, cont_y])
			
	elif artifact_object is Control:
		# Handle 2D/UI artifacts (like the algorithm overview)
		# For Control nodes, position them to fill the screen or use anchors
		artifact_object.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		print("    Applied fullscreen preset for Control artifact")
		
		# Apply scale override for Control nodes differently
		if overrides.has("uniform_scale"):
			var scale_factor = float(overrides.get("uniform_scale", 1.0))
			artifact_object.scale = Vector2(scale_factor, scale_factor)
			print("    Applied uniform scale for Control: %s" % str(scale_factor))
	else:
		print("GridInteractablesComponent: WARNING - Unknown artifact node type: %s" % artifact_object.get_class())

	# Apply per-instance label text if provided (e.g., level_entrance:90|Level 3)
	if overrides.has("label_text"):
		var label_text = str(overrides.get("label_text", ""))
		_try_set_property(artifact_object, "label_text", label_text)
		# Fallback: update a Label3D child if present
		var label_node = artifact_object.find_child("Label3D", true, false)
		if label_node and (label_node is Label3D):
			label_node.text = label_text
		print("    Applied label text: '%s'" % label_text)
	
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
	
	if not config_data.is_empty():
		_apply_artifact_config(artifact_object, config_data, lookup_name)
	
	# Apply map-wide palette if available
	if current_palette != "":
		_try_set_property(artifact_object, "default_palette", current_palette)
		print("    Applied map palette: '%s'" % current_palette)
	
	# Handle tag system registration
	# Only register ENTITIES (with #group:tag), not PUZZLES (with #tag:action)
	# Puzzles set trigger_tag/trigger_action properties but don't register themselves
	if tag != "" and trigger_action == "":
		# This is an entity (e.g., cube_scene:0:0:0#group:fillhole)
		TagSystem.register_tagged_node(tag, artifact_object)
		print("    Registered entity with tag: '%s'" % tag)
	
	# Handle puzzle trigger setup
	if trigger_action != "":
		# Set properties on puzzle to trigger action on tag (e.g., cross_line_puzzle#fillhole:reveal)
		if "trigger_tag" in artifact_object:
			artifact_object.trigger_tag = tag
			print("    Set puzzle trigger_tag: '%s'" % tag)
		if "trigger_action" in artifact_object:
			artifact_object.trigger_action = trigger_action
			print("    Set puzzle trigger_action: '%s'" % trigger_action)

	parent_node.add_child(artifact_object)
	
	# Set owner for editor
	if parent_node.get_tree() and parent_node.get_tree().edited_scene_root:
		artifact_object.owner = parent_node.get_tree().edited_scene_root
	
# Handle successful placement
	var display_name = artifact_info.get("name", lookup_name)
	print("  ✅ Placed artifact '%s' (%s) at (%d,%d,%d)" % [display_name, lookup_name, x, y, z])
	
	return true



# COLON (:) SYNTAX - For rotation and position/scale:
#   "object"                                   → No overrides
#   "object:45"                                → Y-axis rotation 45°
#   "object:45|Label"                          → Y rotation 45° + label text
#   "object:45:2.5"                            → Y rotation 45° + Y position offset +2.5
#   "object:45:2.5:1.2"                        → Y rotation 45° + Y offset +2.5 + scale 1.2
#   "object:45:30:0"                           → 3-axis rotation (Z=45°, X=30°, Y=0°)
#   "object:45:30:0:true:false:true"           → 3-axis rotation + continuous (Z spin, Y spin)
#
# HASH (#) SYNTAX - For complex configuration (RECOMMENDED for non-rotation configs):
#   "pickup_gate#pickups:5"                    → Config parameter
#   "pickup_gate#pickups:3#color:blue"         → Multiple configs
#
# IMPORTANT: 4-param format is AMBIGUOUS:
#   - Could be: rot_y:y_pos:scale:? (legacy) OR rot_z:rot_x:rot_y (new 3-axis)
#   - System assumes 3-axis rotation if all 4 params are numeric
#   - For position/scale, use 3-param format OR # syntax instead
# Helper function to parse token parameters (without the tag part)
func _parse_token_params(token: String, result: Dictionary) -> Dictionary:
	# Handle legacy : syntax for overrides
	if token.find(":") == -1:
		result.lookup_name = token
		return result
	
	var parts = token.split(":", false)

	# SPECIAL HANDLING FOR MARCHING CUBES (mc:) OBJECTS
	# Format: mc:id:rot_y:y_pos:scale
	if parts.size() >= 2 and parts[0] == "mc":
		result.lookup_name = "mc:" + parts[1].strip_edges()
		
		# Parse parameters if present
		# parts[0]=mc, parts[1]=id
		
		if parts.size() >= 3:
			var p = parts[2].strip_edges()
			if p.is_valid_float():
				result.overrides["rotation_y_degrees"] = float(p)
			else:
				print("GridInteractables: Param 2 (rot) invalid float: '%s'" % p)
			
		if parts.size() >= 4:
			var p = parts[3].strip_edges()
			if p.is_valid_float():
				result.overrides["y_position"] = float(p)
			else:
				print("GridInteractables: Param 3 (pos) invalid float: '%s'" % p)
			
		if parts.size() >= 5:
			var p = parts[4].strip_edges()
			if p.is_valid_float():
				result.overrides["uniform_scale"] = float(p)
				print("GridInteractables: Found scale param in token: %f" % float(p))
			else:
				print("GridInteractables: Param 4 (scale) invalid float: '%s'" % p)
			
		return result
	
	if parts.size() < 2:
		result.lookup_name = token
		return result
		
	var name = parts[0].strip_edges()
	result.lookup_name = name
	
	# Handle different parameter formats:
	# Format 1: name:rot_y|label         (legacy Y rotation + label)
	# Format 2: name:rot_y:y_pos:scale   (legacy Y rotation + position + scale)
	# Format 3: name:rot_z:rot_x:rot_y   (3-axis rotation) - ONLY if all params are numeric
	# Format 4: name:rot_z:rot_x:rot_y:cont_z:cont_x:cont_y  (full rotation + continuous)

	if parts.size() == 2:
		# Legacy format: name:param where param could be rotation or rotation|label
		var param = parts[1].strip_edges()
		var rot_part = param
		var label_part = ""

		if param.find("|") != -1:
			var p2 = param.split("|", false)
			rot_part = p2[0].strip_edges()
			if p2.size() > 1:
				label_part = p2[1].strip_edges()

		# rotation part (Y-axis only for legacy compatibility)
		if rot_part.is_valid_float():
			result.overrides["rotation_y_degrees"] = float(rot_part)
		else:
			# If it's not numeric and no explicit label part, treat rot_part as label text
			if label_part == "" and rot_part != "":
				label_part = rot_part

		# label part
		if label_part != "":
			result.overrides["label_text"] = label_part

	elif parts.size() == 4:
		# Ambiguous: Could be legacy (rot_y:y_pos:scale) OR new 3-axis rotation (rot_z:rot_x:rot_y)
		var param1 = parts[1].strip_edges()
		var param2 = parts[2].strip_edges()
		var param3 = parts[3].strip_edges()

		var all_numeric = param1.is_valid_float() and param2.is_valid_float() and param3.is_valid_float()

		if all_numeric:
			var val1 = float(param1)
			var val2 = float(param2)
			var val3 = float(param3)

			# Heuristic: If 3rd value is a typical scale (0-10 range), assume legacy format
			# Scale of 0 means "use default scale" (1.0)
			# Otherwise (val3 >= 10), assume it's 3-axis rotation
			if val3 < 10.0:
				# Legacy: name:rot_y:y_pos:scale
				result.overrides["rotation_y_degrees"] = val1
				result.overrides["y_position"] = val2
				# Scale of 0 means use default (1.0), otherwise use the value
				if val3 > 0.0:
					result.overrides["uniform_scale"] = val3
			else:
				# NEW: 3-axis rotation: name:rot_z:rot_x:rot_y
				result.overrides["rotation_z_degrees"] = val1
				result.overrides["rotation_x_degrees"] = val2
				result.overrides["rotation_y_degrees"] = val3

	elif parts.size() == 3:
		# Legacy format: name:rot_y:y_pos
		var rot_str = parts[1].strip_edges()
		var y_pos_str = parts[2].strip_edges()

		if rot_str.is_valid_float():
			result.overrides["rotation_y_degrees"] = float(rot_str)

		if y_pos_str.is_valid_float():
			result.overrides["y_position"] = float(y_pos_str)

	return result

func _parse_interactable_token(token: String) -> Dictionary:
	var result := {"lookup_name": token, "overrides": {}, "config_data": {}, "tag": "", "trigger_action": ""}
	
	# Handle # configuration syntax first - could be tag OR config
	# Tag syntax: artifact:params#group:tagname OR artifact:params#tagname:action
	if token.find("#") != -1:
		# Check if it's a tag (group:tagname or tagname:action) or config (other # usage)
		var parts = token.split("#", false, 1)  # Split on first # only
		if parts.size() == 2:
			var before_hash = parts[0]
			var after_hash = parts[1]
			
			# Check if after_hash looks like a tag: "group:tagname" or "tagname:action"
			if after_hash.begins_with("group:"):
				# Entity tag: artifact:params#group:tagname
				result.lookup_name = before_hash
				result.tag = after_hash.substr(6)  # Remove "group:" prefix
				# Continue parsing the before_hash part for params
				return _parse_token_params(before_hash, result)
			elif after_hash.find(":") != -1:
				# Could be puzzle trigger: artifact:params#tagname:action
				var tag_parts = after_hash.split(":", false, 1)
				if tag_parts.size() == 2:
					var tag_name = tag_parts[0].strip_edges()
					var action_name = tag_parts[1].strip_edges()
					# Validate that action_name looks like an action (not a number/param)
					if action_name in ["remove", "reveal", "hide", "freeze", "unfreeze", "enable_physics", "disable_physics"]:
						result.lookup_name = before_hash
						result.tag = tag_name
						result.trigger_action = action_name
						# Continue parsing the before_hash part for params
						return _parse_token_params(before_hash, result)
			
			# Otherwise, treat as config syntax (clipboard#pages:point,line,triangle)
			return _parse_config_token(token)
	
	# Handle legacy : syntax for overrides (no # found)
	return _parse_token_params(token, result)

# Parse configuration token syntax with # (e.g., "clipboard#pages:point,line,triangle")
# Format: "artifact_name[:rotation:height:scale]#config_key:config_value[#config_key2:config_value2]..."
# Supports combining : overrides with # config syntax
# Examples:
#   "clipboard#pages:point,line,triangle"                    → { lookup_name: "clipboard", config_data: { pages: "point,line,triangle" } }
#   "clipboard#title:Getting Started"                        → { lookup_name: "clipboard", config_data: { title: "Getting Started" } }
#   "clipboard#pages:point,line#title:My Clips"              → { lookup_name: "clipboard", config_data: { pages: "point,line", title: "My Clips" } }
#   "code_display:90:0.5:0.2#tutorial:line_axioms"           → { lookup_name: "code_display", overrides: {rotation_y: 90, y_pos: 0.5, scale: 0.2}, config_data: { tutorial: "line_axioms" } }
#   "infokiosk:180:-0.5#message:Hello World#color:red"      → { lookup_name: "infokiosk", overrides: {rotation_y: 180, y_pos: -0.5}, config_data: { message: "Hello World", color: "red" } }
func _parse_config_token(token: String) -> Dictionary:
	var result := {"lookup_name": "", "overrides": {}, "config_data": {}}

	# Split on # to separate artifact name from config parts
	var hash_parts = token.split("#", false)
	if hash_parts.size() < 2:
		result.lookup_name = token
		return result

	var artifact_name_part = hash_parts[0].strip_edges()

	# Parse the artifact name part which may contain : overrides
	# Format: "artifact_name:rotation:height:scale"
	
	# Handle Marching Cubes (mc:) prefix within config token
	# Format: mc:id:rot_y:y_pos:scale#config...
	if artifact_name_part.begins_with("mc:"):
		var name_parts = artifact_name_part.split(":", false)
		if name_parts.size() >= 2:
			result.lookup_name = "mc:" + name_parts[1].strip_edges()
			
			if name_parts.size() >= 3 and name_parts[2].is_valid_float():
				result.overrides["rotation_y_degrees"] = float(name_parts[2])
				
			if name_parts.size() >= 4 and name_parts[3].is_valid_float():
				result.overrides["y_position"] = float(name_parts[3])
				
			if name_parts.size() >= 5 and name_parts[4].is_valid_float():
				result.overrides["uniform_scale"] = float(name_parts[4])
				print("GridInteractables: (Config token) Found mc scale: %f" % result.overrides["uniform_scale"])
				
	elif artifact_name_part.find(":") != -1:
		var name_parts = artifact_name_part.split(":", false)
		result.lookup_name = name_parts[0].strip_edges()

		# Parse positional overrides (rotation, height, scale)
		if name_parts.size() >= 2 and name_parts[1].is_valid_float():
			result.overrides["rotation_y_degrees"] = float(name_parts[1])

		if name_parts.size() >= 3 and name_parts[2].is_valid_float():
			result.overrides["y_position"] = float(name_parts[2])

		if name_parts.size() >= 4 and name_parts[3].is_valid_float():
			result.overrides["uniform_scale"] = float(name_parts[3])

		if not result.overrides.is_empty():
			print("GridInteractablesComponent: Parsed combined syntax - artifact='%s', overrides=%s" % [result.lookup_name, result.overrides])
	else:
		result.lookup_name = artifact_name_part

	# Process all config parts (supports multiple # configs)
	for i in range(1, hash_parts.size()):
		var config_part = hash_parts[i].strip_edges()

		# Parse config part (format: "key:value" or "tutorial_id:rot:height:scale")
		if config_part.find(":") != -1:
			# Check if this is a shorthand with transform params (e.g., "point_zero:15:-0.3:1.1")
			var parts = config_part.split(":", false)

			# If we have numeric params after first part, treat as tutorial_id with transforms
			# Check for shorthand syntax: either single rotation or multiple transform params
			# e.g., "vr_scale_controls:190" (rotation only) or "point_zero:15:-0.3:1.1" (all transforms)
			# BUT NOT config params like "radial:9" or "rings:4" - those are key:value pairs
			var is_shorthand = false
			var first_part_lower = parts[0].strip_edges().to_lower()

			# Skip shorthand detection if first part is a known config parameter name
			if first_part_lower not in CONFIG_PARAM_NAMES:
				# Case 1: Single numeric param (rotation only) - e.g., "tutorial_id:180"
				if parts.size() == 2 and parts[1].is_valid_float():
					is_shorthand = true
				# Case 2: Multiple numeric params - e.g., "tutorial_id:180:0.5:1.0"
				elif parts.size() >= 3:
					var has_numeric_params = true
					for j in range(1, min(parts.size(), 4)):  # Check up to 3 transform params
						if not parts[j].is_valid_float():
							has_numeric_params = false
							break
					is_shorthand = has_numeric_params

			if is_shorthand:
					# This is shorthand syntax: tutorial_id:rotation:height:scale
					var tutorial_id = parts[0].strip_edges()
					result.config_data[tutorial_id] = true

					# Extract transform overrides
					if parts.size() >= 2 and parts[1].is_valid_float():
						result.overrides["rotation_y_degrees"] = float(parts[1])
					if parts.size() >= 3 and parts[2].is_valid_float():
						result.overrides["y_position"] = float(parts[2])
					if parts.size() >= 4 and parts[3].is_valid_float():
						result.overrides["uniform_scale"] = float(parts[3])

					print("GridInteractablesComponent: Parsed config shorthand - tutorial='%s', transforms=%s" % [tutorial_id, result.overrides])
					continue

			# Otherwise, treat as regular key:value config
			var config_parts = config_part.split(":", false, 1)  # Split only on first ":"
			if config_parts.size() == 2:
				var config_key = config_parts[0].strip_edges()
				var config_value = config_parts[1].strip_edges()
				result.config_data[config_key] = config_value
			else:
				# No value provided, just key
				result.config_data[config_part] = true
		else:
			# No colon, treat entire config_part as a key with true value
			result.config_data[config_part] = true

	return result

# Apply configuration data to an artifact using the # syntax
# This is a general system that allows any artifact to receive custom configuration
func _apply_artifact_config(artifact_object: Node, config_data: Dictionary, lookup_name: String):
	print("GridInteractablesComponent: Applying config to '%s': %s" % [lookup_name, config_data])
	
	# Set config data as metadata for the artifact to read
	for config_key in config_data.keys():
		var config_value = config_data[config_key]
		var meta_key = "config_%s" % config_key
		artifact_object.set_meta(meta_key, config_value)
		print("  → Set metadata '%s' = '%s'" % [meta_key, str(config_value)])
	
	# Try to call a configuration method on the artifact if it exists
	# This allows artifacts to handle their own configuration logic
	if artifact_object.has_method("apply_grid_config"):
		artifact_object.call_deferred("apply_grid_config", config_data)
		print("  → Called apply_grid_config() method")
	elif artifact_object.has_method("configure"):
		artifact_object.call_deferred("configure", config_data)
		print("  → Called configure() method")
	else:
		print("  → No configuration method found, using metadata only")

# Safely set a property if the node exposes it
func _try_set_property(obj: Object, prop: String, value) -> void:
	if obj == null:
		return
	var props = obj.get_property_list()
	for p in props:
		if typeof(p) == TYPE_DICTIONARY and p.has("name") and str(p["name"]) == prop:
			obj.set(prop, value)
			return

# Add continuous rotation to an object
func _add_continuous_rotation(obj: Node3D, rotate_z: bool, rotate_x: bool, rotate_y: bool) -> void:
	if not obj:
		return

	# Create a simple script that rotates the object
	var script_text = """
extends Node3D

@export var rotation_speed_z: float = %s
@export var rotation_speed_x: float = %s
@export var rotation_speed_y: float = %s

func _process(delta: float) -> void:
	if rotation_speed_z != 0.0:
		rotate_z(deg_to_rad(rotation_speed_z * delta))
	if rotation_speed_x != 0.0:
		rotate_x(deg_to_rad(rotation_speed_x * delta))
	if rotation_speed_y != 0.0:
		rotate_y(deg_to_rad(rotation_speed_y * delta))
""" % [
		"30.0" if rotate_z else "0.0",
		"30.0" if rotate_x else "0.0",
		"30.0" if rotate_y else "0.0"
	]

	var script = GDScript.new()
	script.source_code = script_text
	script.reload()

	obj.set_script(script)

# Apply transform data from artifact definition
func _apply_artifact_transform(artifact_object: Node, artifact_info: Dictionary):
	if artifact_object is Node3D:
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
	elif artifact_object is Control:
		# For Control nodes, handle scale differently
		if artifact_info.has("scale"):
			var scale_data = artifact_info["scale"]
			if scale_data is Array and scale_data.size() >= 2:
				artifact_object.scale = Vector2(scale_data[0], scale_data[1])
			elif scale_data is float or scale_data is int:
				artifact_object.scale = Vector2.ONE * scale_data

# Load and instantiate artifact scene
func _load_and_instantiate_artifact(scene_path: String) -> Node:
	var scene_resource = _load_scene_cached(scene_path)
	if scene_resource:
		# Log which scene is being instantiated (helps debug convex hull errors)
		print("GridInteractablesComponent: Instantiating artifact: %s" % scene_path)
		return scene_resource.instantiate()
	return null

# Update artifact labels with information
func _update_artifact_labels(artifact_object: Node, lookup_name: String, artifact_info: Dictionary):
	if artifact_object is Node3D:
		# Look for common 3D label names
		var label_names = ["id_info_Label3D", "Label3D", "InfoLabel"]
		
		for label_name in label_names:
			var label = artifact_object.find_child(label_name)
			if label and label is Label3D:
				var display_name = artifact_info.get("name", lookup_name)
				label.text = "%s: %s" % [lookup_name, display_name]
				print("  Updated 3D label: %s" % label.text)
				break
	elif artifact_object is Control:
		# Look for common 2D label names
		var label_names = ["Label", "TitleLabel", "InfoLabel"]
		
		for label_name in label_names:
			var label = artifact_object.find_child(label_name)
			if label and label is Label:
				var display_name = artifact_info.get("name", lookup_name)
				label.text = "%s: %s" % [lookup_name, display_name]
				print("  Updated 2D label: %s" % label.text)
				break

# Connect artifact signals using lookup_name
func _connect_artifact_signals(artifact_object: Node, lookup_name: String):
	# Connect common interaction signals
	if artifact_object.has_signal("interact"):
		artifact_object.interact.connect(_on_artifact_interact.bind(lookup_name, artifact_object))
	
	if artifact_object.has_signal("activated"):
		artifact_object.activated.connect(_on_artifact_activated.bind(lookup_name, artifact_object))
	
	if artifact_object.has_signal("artifact_activated"):
		artifact_object.artifact_activated.connect(_on_artifact_activated.bind(lookup_name, artifact_object))

	# Connect TELEPORTER signals (for Portal artifacts)
	if artifact_object.has_signal("teleporter_activated"):
		artifact_object.teleporter_activated.connect(_on_teleporter_artifact_activated.bind(lookup_name, artifact_object))
		print("GridInteractables: Connected teleporter signal for '%s'" % lookup_name)

func _on_teleporter_artifact_activated(lookup_name: String, artifact_object: Node):
	print("GridInteractables: 🚀 Teleporter Artifact activated: %s" % lookup_name)
	
	var destination = artifact_object.get_meta("destination", "")
	var action = artifact_object.get_meta("action", "")
	
	# If no explicit destination/action, default to 'next_in_sequence'
	if destination == "" and action == "":
		action = "next_in_sequence"
		print("GridInteractables: No destination/action found, defaulting to 'next_in_sequence'")
	elif destination != "" and action == "":
		action = "load_map" # Default action if map name is provided
	
	# Find SceneManager (it's an Autoload, usually 'SceneManager' or accessible via tree)
	# Assuming 'SceneManager' singleton exists as per your project structure
	var scene_manager = get_node_or_null("/root/SceneManager") 
	if not scene_manager and utilities_component:
		# Try to find it via utilities component helper if available
		if utilities_component.has_method("_find_scene_manager"):
			scene_manager = utilities_component._find_scene_manager()
			
	if scene_manager:
		scene_manager.request_transition({
			"type": 1, # TRANSITION_TYPE.TELEPORT (assuming index 1)
			"action": action,
			"destination": destination,
			"source": "teleporter_artifact",
			"position": artifact_object.global_position
		})
		print("GridInteractables: Requested transition to '%s' (action: %s)" % [destination, action])
	else:
		printerr("GridInteractables: ❌ Could not find SceneManager to trigger teleport!")

# Handle artifact interaction
func _on_artifact_interact(lookup_name: String, artifact_object: Node):
	var artifact_info = get_artifact_info(lookup_name)
	var position = Vector3.ZERO
	
	# Get position based on node type
	if artifact_object is Node3D:
		position = artifact_object.global_position
	elif artifact_object is Control:
		# For Control nodes, use a default position or convert from 2D
		position = Vector3(artifact_object.global_position.x, 0, artifact_object.global_position.y)
	
	var artifact_data = {
		"lookup_name": lookup_name,
		"position": position,
		"name": artifact_info.get("name", lookup_name),
		"artifact_type": artifact_info.get("artifact_type", "unknown"),
		"description": artifact_info.get("description", ""),
		"sequence": artifact_info.get("sequence", "")
	}
	
	print("GridInteractablesComponent: Artifact interaction - %s ('%s')" % [lookup_name, artifact_info.get("name", "")])
	interactable_activated.emit(lookup_name, position, artifact_data)

# Handle artifact activation
func _on_artifact_activated(lookup_name: String, artifact_object: Node):
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
