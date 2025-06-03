# EnhancedUtilityHandler.gd
# Enhanced utility handler that integrates with MapProgressionManager
# Handles destination resolution for teleporters using central configuration

extends Node
class_name EnhancedUtilityHandler

var grid_system: Node3D
var progression_manager: MapProgressionManager

func _init(grid_system_ref: Node3D):
	grid_system = grid_system_ref

func _ready():
	# Get scene manager instance instead of MapProgressionManager
	var scene_manager = _find_scene_manager()
	
	if scene_manager:
		# Connect this handler to the scene manager
		scene_manager.connect_to_grid_system(grid_system)
		print("EnhancedUtilityHandler: Successfully connected to SceneManager")
	else:
		print("WARNING: EnhancedUtilityHandler: SceneManager not found!")
		print("  Teleporter transitions will use fallback destinations.")

func _find_scene_manager() -> SceneManager:
	# Try common locations
	var potential_managers = [
		get_node_or_null("/root/SceneManager"),
		get_tree().current_scene.find_child("SceneManager", true, false),
		grid_system.find_child("SceneManager", true, false)
	]
	
	for manager in potential_managers:
		if manager and manager is SceneManager:
			return manager as SceneManager
	
	return null


		
# Place utility objects with progression-aware destination handling
func place_utility(x: int, y: int, z: int, utility_type: String, definition: Dictionary, total_size: float) -> void:
	var position = Vector3(x, y, z) * total_size
	var utility_object = null
	
	# Skip if utility type is not recognized
	if not UtilityRegistry.UTILITY_TYPES.has(utility_type) or utility_type == " ":
		return
	
	# Get scene file name for this utility type
	var scene_file = UtilityRegistry.UTILITY_TYPES[utility_type].file
	
	# Load the scene
	var scene_resource = _load_scene(scene_file)
	if scene_resource:
		utility_object = scene_resource.instantiate()
	else:
		print("WARNING: Could not load scene for utility type '%s'" % utility_type)
		return
	
	if utility_object:
		utility_object.position = position
		
		# Apply utility-specific configuration
		_configure_utility_object(utility_object, utility_type, definition)
		
		grid_system.add_child(utility_object)
		
		# Set owner for editor
		if grid_system.get_tree() and grid_system.get_tree().edited_scene_root:
			utility_object.owner = grid_system.get_tree().edited_scene_root
		
		var utility_name = UtilityRegistry.get_utility_name(utility_type)
		print("  Added %s at (%d,%d,%d)" % [utility_name, x, y, z])

# Configure utility object based on type and definition
func _configure_utility_object(utility_object: Node3D, utility_type: String, definition: Dictionary) -> void:
	match utility_type:
		"t":  # Teleporter
			_configure_teleporter(utility_object, definition)
		"s":  # Spawn Point
			_configure_spawn_point(utility_object, definition)
		"p":  # Platform
			_configure_platform(utility_object, definition)
		"l":  # Lift
			_configure_lift(utility_object, definition)
		_:
			# Apply any generic properties
			_apply_generic_properties(utility_object, definition)

# Configure teleporter with progression-aware destination handling
# Updated teleporter configuration - simplified for SceneManager
func _configure_teleporter(teleporter: Node3D, definition: Dictionary) -> void:
	var properties = definition.get("properties", {})
	
	print("EnhancedUtilityHandler: Configuring teleporter with definition: %s" % definition)
	
	# Apply visual effects if specified
	if properties.has("visual_effect"):
		_apply_teleporter_visual_effect(teleporter, properties["visual_effect"])
	
	# DEFER signal router connection to ensure SceneManager exists
	call_deferred("_connect_teleporter_to_scene_manager", teleporter)
	
	print("    ✓ Teleporter configured to advance sequence on activation")

func _connect_teleporter_to_scene_manager(teleporter: Node3D):
	# Wait for SceneManager to be ready
	await get_tree().process_frame
	await get_tree().process_frame
	
	UtilitySignalRouter.add_to_utility(teleporter, "teleporter")
	print("    ✓ Teleporter connected to SceneManager")
	
# Configure spawn point utilities
func _configure_spawn_point(spawn_point: Node3D, definition: Dictionary) -> void:
	var properties = definition.get("properties", {})
	
	# Set spawn point name
	if definition.has("name") and "spawn_name" in spawn_point:
		spawn_point.spawn_name = definition["name"]
	elif properties.has("spawn_name") and "spawn_name" in spawn_point:
		spawn_point.spawn_name = properties["spawn_name"]
	
	# Set priority
	if properties.has("priority") and "priority" in spawn_point:
		spawn_point.priority = int(properties["priority"])
	
	# Set rotation
	if properties.has("rotation") and "spawn_rotation" in spawn_point:
		var rot = properties["rotation"]
		if rot is Array and rot.size() >= 3:
			spawn_point.spawn_rotation = Vector3(rot[0], rot[1], rot[2])
		elif rot is String:
			# Parse rotation from string format "x,y,z"
			var rot_parts = rot.split(",")
			if rot_parts.size() >= 3:
				spawn_point.spawn_rotation = Vector3(
					rot_parts[0].to_float(),
					rot_parts[1].to_float(),
					rot_parts[2].to_float()
				)
	
	# Set visual settings
	if properties.has("visible_in_game") and "visible_in_game" in spawn_point:
		spawn_point.visible_in_game = bool(properties["visible_in_game"])
	
	if properties.has("indicator_color") and "indicator_color" in spawn_point:
		var color = properties["indicator_color"]
		if color is Array and color.size() >= 3:
			var alpha = color[3] if color.size() > 3 else 0.8
			spawn_point.indicator_color = Color(color[0], color[1], color[2], alpha)
	
	# Set active state
	if properties.has("active") and "active" in spawn_point:
		spawn_point.active = bool(properties["active"])
	
	print("    Configured spawn point: %s (priority: %d)" % [spawn_point.get("spawn_name"), spawn_point.get("priority")])
	
	# Apply generic properties
	_apply_generic_properties(spawn_point, definition)

# Generate scene path for dynamic maps
func _generate_dynamic_scene_path(map_name: String) -> String:
	# This could be enhanced to use DynamicMapSystem directly
	# For now, return a recognizable path that the scene base can handle
	return "res://adaresearch/Common/Scenes/Maps/Dynamic/" + map_name + ".tscn"

# Configure platform utilities
func _configure_platform(platform: Node3D, definition: Dictionary) -> void:
	var properties = definition.get("properties", {})
	
	# Set height if specified
	if properties.has("height") and platform.has_method("set_height"):
		platform.set_height(properties["height"])
	
	# Set material if specified
	if properties.has("material") and platform.has_method("set_material_type"):
		platform.set_material_type(properties["material"])
	
	_apply_generic_properties(platform, definition)

# Configure lift utilities
func _configure_lift(lift: Node3D, definition: Dictionary) -> void:
	var properties = definition.get("properties", {})
	
	# Set lift height
	if properties.has("height") and "lift_height" in lift:
		lift.lift_height = properties["height"]
	
	# Set lift speed
	if properties.has("speed") and "lift_speed" in lift:
		lift.lift_speed = properties["speed"]
	
	_apply_generic_properties(lift, definition)

# Apply generic properties to any utility object
func _apply_generic_properties(utility_object: Node3D, definition: Dictionary) -> void:
	var properties = definition.get("properties", {})
	
	# Apply name if specified
	if definition.has("name"):
		utility_object.name = definition["name"]
	
	# Apply description as metadata
	if definition.has("description"):
		utility_object.set_meta("description", definition["description"])
	
	# Apply any direct property mappings
	for property_name in properties.keys():
		var property_value = properties[property_name]
		
		# Try to set the property directly if it exists using the 'in' operator
		if property_name in utility_object:
			utility_object.set(property_name, property_value)

# Apply visual effects to teleporter
func _apply_teleporter_visual_effect(teleporter: Node3D, effect: String) -> void:
	match effect:
		"portal_glow":
			# Apply portal glow effect (check if it's a Teleport instance)
			if teleporter is Teleport:
				teleporter.active_beam_color = Color(0.2, 0.6, 1.0)  # Blue glow
		"warning":
			# Apply warning effect
			if teleporter is Teleport:
				teleporter.active_beam_color = Color(1.0, 0.5, 0.0)  # Orange warning
		"exit":
			# Apply exit effect
			if teleporter is Teleport:
				teleporter.active_beam_color = Color(0.0, 1.0, 0.3)  # Green exit
		_:
			print("Unknown teleporter visual effect: %s" % effect)

# Load scene with caching
func _load_scene(scene_file: String):
	# Use grid system's scene cache if available
	if grid_system.has_method("_load_scene"):
		return grid_system._load_scene(scene_file)
	
	# Fallback to direct loading
	if ResourceLoader.exists(scene_file):
		return load(scene_file)
	else:
		print("WARNING: Scene file not found: %s" % scene_file)
		return null

# Get next map in progression for current map
func get_next_map_for_current() -> String:
	if not progression_manager:
		return ""
	
	var current_map = grid_system.map_name
	return progression_manager.get_next_map(current_map)

# Check if player can access a destination
func can_access_destination(destination_map: String) -> bool:
	if not progression_manager:
		return true  # Allow access if no progression manager
	
	return progression_manager.is_map_unlocked(destination_map)

# Mark current map as completed
func complete_current_map() -> Array[String]:
	if not progression_manager:
		return []
	
	var current_map = grid_system.map_name
	return progression_manager.complete_map(current_map)

# Get previous map for backtracking (simple implementation)
func _get_previous_map(current_map: String) -> String:
	if not progression_manager:
		return progression_manager.get_main_menu_map()
	
	# Find a map that unlocks the current map
	for map_name in progression_manager.map_metadata.keys():
		var metadata = progression_manager.map_metadata[map_name]
		var unlocks = metadata.get("unlocks", [])
		if current_map in unlocks:
			return map_name
	
	# If no previous map found, return to menu
	return progression_manager.get_main_menu_map() 
