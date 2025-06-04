# GridUtilitiesComponent.gd  
# Handles utility object placement (teleports, lifts, doors, etc.)
# Uses UtilityRegistry for type definitions and validation

extends Node
class_name GridUtilitiesComponent

# Path constants - CORRECTED TO MATCH ACTUAL PROJECT STRUCTURE
const MAP_OBJECTS_PATH = "res://commons/scenes/mapobjects/"

# References
var parent_node: Node3D
var structure_component: GridStructureComponent

# Settings
var cube_size: float = 1.0
var gutter: float = 0.0

# Utility objects tracking
var utility_objects: Dictionary = {}
var scene_cache: Dictionary = {}

# Signals
signal utility_generation_complete(utility_count: int)
signal utility_activated(utility_type: String, position: Vector3, data: Dictionary)

func _ready():
	print("GridUtilitiesComponent: Initialized")

# Initialize with references and settings
func initialize(grid_parent: Node3D, struct_component: GridStructureComponent, settings: Dictionary = {}):
	parent_node = grid_parent
	structure_component = struct_component
	
	# Apply settings
	cube_size = settings.get("cube_size", 1.0)
	gutter = settings.get("gutter", 0.0)
	
	print("GridUtilitiesComponent: Initialized with cube_size=%f, gutter=%f" % [cube_size, gutter])

# Generate utilities from data
func generate_utilities(utility_data, utility_definitions: Dictionary = {}):
	if not utility_data:
		print("GridUtilitiesComponent: No utility data provided")
		return
		
	if not utility_data.layout_data:
		print("GridUtilitiesComponent: No layout_data in utility data")
		return
		
	print("GridUtilitiesComponent: Generating utilities")
	
	var utility_layout = utility_data.layout_data
	var total_size = cube_size + gutter
	var utility_count = 0
	
	# Get grid dimensions from structure component
	var dimensions = structure_component.get_grid_dimensions()
	
	# Validate utilities using UtilityRegistry
	var validation = UtilityRegistry.validate_utility_grid(utility_layout)
	if not validation.valid:
		print("GridUtilitiesComponent: WARNING - Utility validation issues:")
		for error in validation.errors:
			print("  ERROR: %s" % error)
		for warning in validation.warnings:
			print("  WARNING: %s" % warning)
	
	# Place utilities
	for z in range(min(dimensions.z, utility_layout.size())):
		var row = utility_layout[z]
		for x in range(min(dimensions.x, row.size())):
			var utility_cell = str(row[x]).strip_edges()
			
			if utility_cell.is_empty() or utility_cell == " ":
				continue
			
			# Parse utility cell with parameters
			var parsed = UtilityRegistry.parse_utility_cell(utility_cell)
			var utility_type = parsed.type
			var parameters = parsed.parameters
			
			if UtilityRegistry.is_valid_utility_type(utility_type) and utility_type != " ":
				var y_pos = structure_component.find_highest_y_at(x, z)
				
				# Get utility definition if available
				var utility_definition = utility_definitions.get(utility_type, {})
				
				_place_utility(x, y_pos, z, utility_type, parameters, utility_definition, total_size)
				utility_count += 1
	
	print("GridUtilitiesComponent: Added %d utilities" % utility_count)
	utility_generation_complete.emit(utility_count)

# Place a single utility object
func _place_utility(x: int, y: int, z: int, utility_type: String, parameters: Array, definition: Dictionary, total_size: float):
	var position = Vector3(x, y, z) * total_size
	
	var scene_path = UtilityRegistry.get_utility_scene_path(utility_type)
	if scene_path.is_empty():
		print("GridUtilitiesComponent: WARNING - No scene file for utility type '%s'" % utility_type)
		return
	
	var scene_resource = _load_scene_cached(UtilityRegistry.get_utility_info(utility_type).file)
	if not scene_resource:
		print("GridUtilitiesComponent: WARNING - Could not load scene for utility type '%s'" % utility_type)
		return
	
	var utility_object = scene_resource.instantiate()
	if utility_object:
		utility_object.position = position
		
		# Apply parameters if supported
		if parameters.size() > 0 and UtilityRegistry.supports_parameters(utility_type):
			_apply_utility_parameters(utility_object, utility_type, parameters)
		
		# Apply definition properties
		_apply_utility_definition(utility_object, utility_type, definition)
		
		# Connect signals if utility has them
		_connect_utility_signals(utility_object, utility_type)
		
		parent_node.add_child(utility_object)
		
		# Set owner for editor
		if parent_node.get_tree() and parent_node.get_tree().edited_scene_root:
			utility_object.owner = parent_node.get_tree().edited_scene_root
		
		utility_objects[Vector3i(x, y, z)] = utility_object
		
		var param_info = ""
		if parameters.size() > 0:
			param_info = " (params: %s)" % str(parameters)
		print("  Added %s at (%d,%d,%d)%s" % [UtilityRegistry.get_utility_name(utility_type), x, y, z, param_info])

# Apply utility parameters
func _apply_utility_parameters(utility_object: Node3D, utility_type: String, parameters: Array):
	match utility_type:
		"t":  # Teleport
			if parameters.size() > 0 and "destination" in utility_object:
				utility_object.destination = parameters[0]
		"l":  # Lift
			if parameters.size() > 0 and "height" in utility_object:
				utility_object.height = float(parameters[0])
		"s":  # Spawn point
			if parameters.size() > 0:
				utility_object.set_meta("spawn_name", parameters[0])

# Apply utility definition properties from JSON
func _apply_utility_definition(utility_object: Node3D, utility_type: String, definition: Dictionary):
	if definition.is_empty():
		return
		
	var properties = definition.get("properties", {})
	
	# Apply visual effects for teleporters
	if utility_type == "t" and properties.has("visual_effect"):
		_apply_teleporter_visual_effect(utility_object, properties["visual_effect"])
	
	# Apply spawn point properties
	if utility_type == "s":
		_apply_spawn_point_properties(utility_object, properties)
	
	# Apply generic properties
	for property_name in properties.keys():
		var property_value = properties[property_name]
		if property_name in utility_object:
			utility_object.set(property_name, property_value)
		else:
			# Store as metadata if property doesn't exist
			utility_object.set_meta(property_name, property_value)

# Apply spawn point specific properties
func _apply_spawn_point_properties(spawn_point: Node3D, properties: Dictionary):
	# Set spawn point metadata
	if properties.has("spawn_name"):
		spawn_point.set_meta("spawn_name", properties["spawn_name"])
	
	if properties.has("priority"):
		spawn_point.set_meta("priority", int(properties["priority"]))
	
	if properties.has("height"):
		spawn_point.set_meta("height", float(properties["height"]))
	
	if properties.has("player_rotation"):
		spawn_point.set_meta("player_rotation", float(properties["player_rotation"]))
	
	# Apply visual settings
	if properties.has("visible_in_game"):
		var visible = bool(properties["visible_in_game"])
		_set_spawn_point_visibility(spawn_point, visible)

# Set spawn point visual components visibility
func _set_spawn_point_visibility(spawn_point: Node3D, visible: bool):
	var components = ["Platform", "Indicator", "Label3D"]
	for component_name in components:
		var component = spawn_point.get_node_or_null(component_name)
		if component:
			component.visible = visible

# Apply teleporter visual effects
func _apply_teleporter_visual_effect(teleporter: Node3D, effect: String):
	# This would depend on the teleporter scene structure
	match effect:
		"portal_glow":
			if "active_beam_color" in teleporter:
				teleporter.active_beam_color = Color(0.2, 0.6, 1.0)
		"warning":
			if "active_beam_color" in teleporter:
				teleporter.active_beam_color = Color(1.0, 0.5, 0.0)
		"exit":
			if "active_beam_color" in teleporter:
				teleporter.active_beam_color = Color(0.0, 1.0, 0.3)

# Connect utility signals
func _connect_utility_signals(utility_object: Node3D, utility_type: String):
	# Connect common utility signals
	if utility_object.has_signal("activated"):
		utility_object.activated.connect(_on_utility_activated.bind(utility_type, utility_object))
	
	if utility_object.has_signal("teleporter_activated"):
		utility_object.teleporter_activated.connect(_on_teleporter_activated.bind(utility_object))
		print("GridUtilitiesComponent: ✅ Connected teleporter_activated signal for %s" % utility_type)

# Handle general utility activation
func _on_utility_activated(utility_type: String, utility_object: Node3D):
	var utility_data = {
		"position": utility_object.global_position,
		"name": utility_object.name,
		"type": utility_type
	}
	
	# Add utility-specific data
	if "destination" in utility_object:
		utility_data["destination"] = utility_object.destination
	
	utility_activated.emit(utility_type, utility_object.global_position, utility_data)

# Handle teleporter activation specifically - connect to SceneManager
func _on_teleporter_activated(utility_object: Node3D):
	print("GridUtilitiesComponent: 🚀 Teleporter activated - requesting scene transition")
	
	# Find the SceneManager in the tree
	var scene_manager = _find_scene_manager()
	if scene_manager:
		print("GridUtilitiesComponent: ✅ Found SceneManager - requesting transition")
		
		# Tell SceneManager to advance the current sequence
		scene_manager.request_transition({
			"type": 1, # SceneManager.TransitionType.TELEPORTER
			"action": "next_in_sequence",
			"source": "teleporter",
			"position": utility_object.global_position
		})
	else:
		print("GridUtilitiesComponent: ❌ ERROR - Could not find SceneManager for teleporter transition")
		print("GridUtilitiesComponent: Available nodes in tree:")
		_debug_print_scene_tree()

# Find SceneManager in the scene tree
func _find_scene_manager():
	# Try common locations for SceneManager
	var potential_managers = [
		get_node_or_null("/root/SceneManager"),
		get_node_or_null("/root/AdaSceneManager"),
		get_tree().current_scene.find_child("SceneManager", true, false),
		get_tree().current_scene.find_child("AdaSceneManager", true, false)
	]
	
	for manager in potential_managers:
		if manager:
			print("GridUtilitiesComponent: Found SceneManager at: %s" % manager.get_path())
			return manager
	
	return null

# Debug: Print scene tree to help find SceneManager
func _debug_print_scene_tree():
	print("GridUtilitiesComponent: Scene tree structure:")
	_print_node_tree(get_tree().current_scene, 0)

func _print_node_tree(node: Node, depth: int):
	var indent = "  ".repeat(depth)
	print("%s%s (%s)" % [indent, node.name, node.get_class()])
	
	if depth < 3:  # Limit depth to avoid spam
		for child in node.get_children():
			_print_node_tree(child, depth + 1)

# Load scene with caching
func _load_scene_cached(scene_filename: String) -> PackedScene:
	if scene_filename.is_empty():
		return null
	
	if scene_cache.has(scene_filename):
		return scene_cache[scene_filename]
	
	var scene_path = MAP_OBJECTS_PATH + scene_filename
	print("GridUtilitiesComponent: Attempting to load scene: %s" % scene_path)
	
	if ResourceLoader.exists(scene_path):
		var scene = ResourceLoader.load(scene_path)
		scene_cache[scene_filename] = scene
		print("GridUtilitiesComponent: ✅ Successfully loaded scene: %s" % scene_filename)
		return scene
	else:
		print("GridUtilitiesComponent: ❌ ERROR - Scene file not found: %s" % scene_path)
		
		# Try to find what files actually exist
		_list_available_scenes()
		
		return null

# Debug: List available utility scenes
func _list_available_scenes():
	print("GridUtilitiesComponent: Listing available scenes in %s:" % MAP_OBJECTS_PATH)
	
	var dir = DirAccess.open(MAP_OBJECTS_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tscn"):
				print("  → %s" % file_name)
			file_name = dir.get_next()
	else:
		print("GridUtilitiesComponent: Could not open scenes directory: %s" % MAP_OBJECTS_PATH)

# Get utility at position
func get_utility_at(x: int, y: int, z: int) -> Node3D:
	var key = Vector3i(x, y, z)
	return utility_objects.get(key, null)

# Check if position has utility
func has_utility_at(x: int, y: int, z: int) -> bool:
	return utility_objects.has(Vector3i(x, y, z))

# Clear all utilities
func clear_utilities():
	print("GridUtilitiesComponent: Clearing all utilities")
	
	for key in utility_objects.keys():
		var utility = utility_objects[key]
		if is_instance_valid(utility):
			utility.queue_free()
	
	utility_objects.clear()

# Get utility count
func get_utility_count() -> int:
	return utility_objects.size()

# Get all utility positions
func get_all_utility_positions() -> Array:
	return utility_objects.keys()
