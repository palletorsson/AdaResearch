# GridSystem.gd (Component-Based Version)
# Orchestrates grid components for modular map generation
# Replaces the monolithic 776-line version with clean component architecture

extends Node3D
class_name GridSystem

# Configuration
@export var cube_size: float = 1.0
@export var gutter: float = 0.0
@export var map_name: String = "Tutorial_Start"
@export var reload_map: bool = false : set = reload_map_setter

# Components
var data_component: GridDataComponent
var structure_component: GridStructureComponent
var utilities_component: GridUtilitiesComponent
var interactables_component: GridInteractablesComponent
var spawn_component: GridSpawnComponent

# Scene references
@onready var base_cube = $CubeScene

# State
var is_initialized: bool = false
var generation_in_progress: bool = false

# Signals
signal map_loaded(map_name: String, format: String)
signal map_generation_complete()
signal interactable_activated(object_id, position, data)

func _ready():
	print("GridSystem: Initializing component-based grid system...")
	
	if not base_cube:
		push_error("GridSystem: Base cube reference not found!")
		return
	
	# Check for scene data first (from AdaSceneManager)
	_check_for_scene_data()
	
	# Initialize components
	_initialize_components()
	
	# Load map data
	_load_map_data()

# Check for scene data and update map_name
func _check_for_scene_data():
	var scene_root = get_tree().current_scene
	var scene_data = scene_root.get_meta("scene_user_data", {})
	
	if scene_data.is_empty():
		scene_data = scene_root.get_meta("scene_data", {})
	
	if not scene_data.is_empty():
		print("GridSystem: Found scene data: %s" % scene_data)
		
		# Update map name from scene data
		if scene_data.has("map_name"):
			var new_map_name = scene_data["map_name"]
			print("GridSystem: Updating map_name from '%s' to '%s'" % [map_name, new_map_name])
			map_name = new_map_name
		
		if scene_data.has("initial_map"):
			var new_map_name = scene_data["initial_map"]
			print("GridSystem: Updating map_name from '%s' to '%s' (initial_map)" % [map_name, new_map_name])
			map_name = new_map_name
		
		# Store sequence data for reference
		if scene_data.has("sequence_data"):
			set_meta("current_sequence", scene_data["sequence_data"])
	else:
		print("GridSystem: No scene data found, using default map_name: %s" % map_name)

# Initialize all components
func _initialize_components():
	print("GridSystem: Initializing components...")
	
	# Create and add components as children
	data_component = GridDataComponent.new()
	data_component.name = "GridDataComponent"
	add_child(data_component)
	
	structure_component = GridStructureComponent.new()
	structure_component.name = "GridStructureComponent"
	add_child(structure_component)
	
	utilities_component = GridUtilitiesComponent.new()
	utilities_component.name = "GridUtilitiesComponent"
	add_child(utilities_component)
	
	interactables_component = GridInteractablesComponent.new()
	interactables_component.name = "GridInteractablesComponent"
	add_child(interactables_component)
	
	spawn_component = GridSpawnComponent.new()
	spawn_component.name = "GridSpawnComponent"
	add_child(spawn_component)
	
	# Connect component signals
	_connect_component_signals()
	
	print("GridSystem: ✅ All components initialized")

# Connect signals from components
func _connect_component_signals():
	# Data component signals
	data_component.data_loaded.connect(_on_data_loaded)
	data_component.data_load_failed.connect(_on_data_load_failed)
	
	# Structure component signals
	structure_component.structure_generation_complete.connect(_on_structure_complete)
	
	# Utilities component signals
	utilities_component.utility_generation_complete.connect(_on_utilities_complete)
	utilities_component.utility_activated.connect(_on_utility_activated)
	
	# Interactables component signals
	interactables_component.interactables_generation_complete.connect(_on_interactables_complete)
	interactables_component.interactable_activated.connect(_on_interactable_activated)
	
	# Spawn component signals
	spawn_component.spawn_positioning_complete.connect(_on_spawn_complete)

# Load map data using data component
func _load_map_data():
	print("GridSystem: Loading map data for '%s'" % map_name)
	
	if not data_component.load_map_data(map_name):
		push_error("GridSystem: Failed to load map data for '%s'" % map_name)

# Handle successful data loading
func _on_data_loaded(loaded_map_name: String, format: String):
	print("GridSystem: Data loaded successfully - %s (%s)" % [loaded_map_name, format])
	
	# Get settings from data and apply them
	var settings = data_component.get_settings()
	cube_size = settings.get("cube_size", cube_size)
	gutter = settings.get("gutter", gutter)
	
	# Initialize components with settings and references
	var component_settings = {
		"cube_size": cube_size,
		"gutter": gutter
	}
	
	structure_component.initialize(self, base_cube, component_settings)
	utilities_component.initialize(self, structure_component, component_settings)
	interactables_component.initialize(self, structure_component, utilities_component, data_component, component_settings)
	spawn_component.initialize(structure_component, utilities_component, data_component, component_settings)
	
	# Start grid generation
	_generate_grid()
	
	emit_signal("map_loaded", loaded_map_name, format)

# Handle data loading failure
func _on_data_load_failed(failed_map_name: String, error: String):
	push_error("GridSystem: CRITICAL FAILURE - Failed to load map '%s': %s" % [failed_map_name, error])
	
	# Stop here - no fallbacks, let it fail clearly
	generation_in_progress = false
	
	# Show error state for debugging
	_show_error_state(failed_map_name, error)
	
	# Emit failure signal for external systems to handle
	emit_signal("map_generation_complete")  # With error state

# Generate the complete grid using components
func _generate_grid():
	if generation_in_progress:
		print("GridSystem: Generation already in progress, skipping")
		return
	
	generation_in_progress = true
	print("GridSystem: Starting component-based grid generation...")
	
	base_cube.visible = false
	
	# Get grid dimensions from data
	var dimensions = data_component.get_grid_dimensions()
	print("GridSystem: Grid dimensions: %dx%dx%d" % [dimensions.x, dimensions.y, dimensions.z])
	
	# Generate structure first
	var structure_data = data_component.get_structure_data()
	structure_component.generate_structure(structure_data, dimensions)

# Handle structure generation completion
func _on_structure_complete(cube_count: int):
	print("GridSystem: Structure generation complete (%d cubes)" % cube_count)
	
	# Generate utilities
	var utility_data = data_component.get_utility_data()
	var utility_definitions = data_component.get_utility_definitions()
	utilities_component.generate_utilities(utility_data, utility_definitions)

# Handle utilities generation completion
func _on_utilities_complete(utility_count: int):
	print("GridSystem: Utilities generation complete (%d utilities)" % utility_count)
	
	# Generate interactables
	var interactable_data = data_component.get_interactable_data()
	interactables_component.generate_interactables(interactable_data)

# Handle interactables generation completion
func _on_interactables_complete(interactable_count: int):
	print("GridSystem: Interactables generation complete (%d interactables)" % interactable_count)
	
	# Handle player spawn positioning
	call_deferred("_handle_player_spawn")

# Handle player spawn positioning
func _handle_player_spawn():
	print("GridSystem: Handling player spawn positioning...")
	spawn_component.handle_player_spawn()

# Handle spawn positioning completion
func _on_spawn_complete(spawn_position: Vector3):
	print("GridSystem: Spawn positioning complete at %s" % spawn_position)
	
	generation_in_progress = false
	print("GridSystem: ✅ Grid generation completed successfully")
	emit_signal("map_generation_complete")

# Handle utility activation
func _on_utility_activated(utility_type: String, position: Vector3, data: Dictionary):
	print("GridSystem: 🎯 Utility activated - %s at %s" % [utility_type, position])
	
	# For teleporters, also try to find and notify SceneManager directly
	if utility_type == "t":
		print("GridSystem: 🚀 Teleporter activation detected - notifying SceneManager")
		_handle_teleporter_activation(position, data)
	
	# Forward to external systems if needed (for other integrations)
	# This maintains the existing signal for anything else that might be listening

# Handle teleporter activation by finding and notifying SceneManager
func _handle_teleporter_activation(position: Vector3, data: Dictionary):
	# Find SceneManager in the tree
	var scene_manager = _find_scene_manager()
	if scene_manager:
		print("GridSystem: ✅ Found SceneManager - requesting transition")
		
		# Check if we're in a sequence context
		var current_sequence = get_meta("current_sequence", {})
		var action = "load_map"  # Default action
		var destination = data.get("destination", "")
		var sequence = ""
		
		print("GridSystem: 🔍 DEBUG - Current sequence metadata: %s" % current_sequence)
		print("GridSystem: 🔍 DEBUG - Destination from teleporter: '%s'" % destination)
		print("GridSystem: 🔍 DEBUG - All metadata: %s" % get_meta_list())
		
		# NEW APPROACH: Use "next" action for empty destinations
		if destination.is_empty():
			action = "next"
			print("GridSystem: ✅ Empty destination - using 'next' action")
		# Check if destination is a sequence name
		elif destination in ["primitives", "array_tutorial", "randomness_exploration", "wavefunctions"]:
			action = "start_sequence"
			sequence = destination
			destination = ""
		# Otherwise it's a direct map load
		else:
			action = "load_map"
		
		print("GridSystem: Action: %s, Destination: %s, Sequence: %s" % [action, destination, sequence])
		print("GridSystem: Current sequence context: %s" % current_sequence.get("sequence_name", "none"))
		
		# Request transition with appropriate action
		var transition_request = {
			"type": 1, # TransitionType.TELEPORTER
			"action": action,
			"sequence": sequence,
			"destination": destination,
			"current_map_name": map_name,  # Pass current map name
			"source": "grid_teleporter",
			"position": position,
			"utility_data": data
		}
		
		# If we're in a sequence context, provide the sequence data to SceneManager
		if not current_sequence.is_empty():
			transition_request["current_sequence_context"] = current_sequence
			# Ensure SceneManager knows about the sequence
			if scene_manager.has_method("_restore_sequence_context"):
				scene_manager._restore_sequence_context(current_sequence)
			else:
				# Fallback: set the sequence data directly
				scene_manager.current_sequence_data = current_sequence
		
		scene_manager.request_transition(transition_request)
	else:
		print("GridSystem: ❌ WARNING - No SceneManager found for teleporter transition")
		print("GridSystem: 🔍 Available autoloads:")
		_debug_print_autoloads()

# Find SceneManager (check autoloads first, then scene tree)
func _find_scene_manager():
	# Check autoloads first (most common location)
	var autoload_managers = [
		get_node_or_null("/root/SceneManager"),
		get_node_or_null("/root/AdaSceneManager")
	]
	
	for manager in autoload_managers:
		if manager:
			print("GridSystem: Found SceneManager autoload: %s" % manager.name)
			return manager
	
	# Check scene tree
	var scene_managers = [
		get_tree().current_scene.find_child("SceneManager", true, false),
		get_tree().current_scene.find_child("AdaSceneManager", true, false)
	]
	
	for manager in scene_managers:
		if manager:
			print("GridSystem: Found SceneManager in scene: %s" % manager.get_path())
			return manager
	
	return null

# Debug: Print autoloads to help find SceneManager
func _debug_print_autoloads():
	print("GridSystem: Autoloads in /root/:")
	for child in get_tree().root.get_children():
		print("  → %s (%s)" % [child.name, child.get_class()])

# Handle interactable activation
func _on_interactable_activated(object_id: String, position: Vector3, data: Dictionary):
	print("GridSystem: Interactable activated - %s at %s" % [object_id, position])
	emit_signal("interactable_activated", object_id, position, data)

# Reload map setter
func reload_map_setter(value: bool):
	if value:
		reload_map = false
		call_deferred("_reload_current_map")

# Reload current map
func _reload_current_map():
	print("GridSystem: Reloading map '%s'" % map_name)
	
	# Clear all components
	_clear_all_components()
	
	# Wait one frame
	await get_tree().process_frame
	
	# Reload map data
	_load_map_data()

# Clear all components
func _clear_all_components():
	print("GridSystem: Clearing all components...")
	
	if structure_component:
		structure_component.clear_structure()
	
	if utilities_component:
		utilities_component.clear_utilities()
	
	if interactables_component:
		interactables_component.clear_interactables()
	
	generation_in_progress = false

# Public API methods

# Get current map information
func get_current_map_info() -> Dictionary:
	var info = {
		"name": map_name,
		"format": data_component.get_current_format() if data_component else "unknown",
		"dimensions": data_component.get_grid_dimensions() if data_component else Vector3i.ZERO,
		"objects": {
			"cubes": structure_component.get_cube_count() if structure_component else 0,
			"utilities": utilities_component.get_utility_count() if utilities_component else 0,
			"interactables": interactables_component.get_interactable_count() if interactables_component else 0
		},
		"generation_complete": not generation_in_progress
	}
	
	if data_component:
		info.merge(data_component.get_map_metadata())
	
	return info

# Get component references (for external access)
func get_data_component() -> GridDataComponent:
	return data_component

func get_structure_component() -> GridStructureComponent:
	return structure_component

func get_utilities_component() -> GridUtilitiesComponent:
	return utilities_component

func get_interactables_component() -> GridInteractablesComponent:
	return interactables_component

func get_spawn_component() -> GridSpawnComponent:
	return spawn_component

# Check if map is fully loaded and generated
func is_map_ready() -> bool:
	return data_component and data_component.is_data_loaded() and not generation_in_progress

# Get grid dimensions
func get_grid_dimensions() -> Vector3i:
	if data_component:
		return data_component.get_grid_dimensions()
	return Vector3i.ZERO

# Find highest Y position at X,Z coordinate (delegated to structure component)
func find_highest_y_at(x: int, z: int) -> int:
	if structure_component:
		return structure_component.find_highest_y_at(x, z)
	return 0

# Check if position has a cube (delegated to structure component)
func has_cube_at(x: int, y: int, z: int) -> bool:
	if structure_component:
		return structure_component.has_cube_at(x, y, z)
	return false

# Get utility at position (delegated to utilities component)
func get_utility_at(x: int, y: int, z: int) -> Node3D:
	if utilities_component:
		return utilities_component.get_utility_at(x, y, z)
	return null

# Get interactable at position (delegated to interactables component)
func get_interactable_at(x: int, y: int, z: int) -> Node3D:
	if interactables_component:
		return interactables_component.get_interactable_at(x, y, z)
	return null

# Debug: Print component status
func print_component_status():
	print("=== GridSystem Component Status ===")
	print("Map: %s" % map_name)
	print("Generation in progress: %s" % generation_in_progress)
	print("Data component: %s (loaded: %s)" % [
		"✓" if data_component else "✗",
		data_component.is_data_loaded() if data_component else false
	])
	print("Structure component: %s (cubes: %d)" % [
		"✓" if structure_component else "✗",
		structure_component.get_cube_count() if structure_component else 0
	])
	print("Utilities component: %s (utilities: %d)" % [
		"✓" if utilities_component else "✗",
		utilities_component.get_utility_count() if utilities_component else 0
	])
	print("Interactables component: %s (interactables: %d)" % [
		"✓" if interactables_component else "✗",
		interactables_component.get_interactable_count() if interactables_component else 0
	])
	print("Spawn component: %s" % ("✓" if spawn_component else "✗"))
	
	if data_component:
		print("Spawn info: %s" % spawn_component.get_spawn_info())
	
	print("==================================")

# Show error state when map loading fails completely
func _show_error_state(failed_map_name: String, error: String):
	print("GridSystem: 🔴 SHOWING ERROR STATE - MAP LOAD FAILED")
	print("GridSystem: Map: '%s'" % failed_map_name)
	print("GridSystem: Error: %s" % error)
	
	# Create a simple error display cube
	if base_cube:
		var error_cube = base_cube.duplicate()
		error_cube.position = Vector3.ZERO
		error_cube.visible = true
		add_child(error_cube)
		
		# Add error label
		var label = Label3D.new()
		label.text = "❌ MAP LOAD FAILED ❌\nMap: %s\nError: %s\n\nCHECK CONSOLE FOR DETAILS" % [failed_map_name, error]
		label.position = Vector3(0, 2, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color.RED
		add_child(label)
		
		print("GridSystem: 🔴 Error state displayed - check scene for red error message")
		print("GridSystem: 🔍 Run print_component_status() for detailed debugging info")

# Add explicit failure checking
func has_load_error() -> bool:
	return not is_map_ready() and not generation_in_progress

# Get error details for debugging
func get_error_info() -> Dictionary:
	return {
		"has_error": has_load_error(),
		"map_name": map_name,
		"data_loaded": data_component.is_data_loaded() if data_component else false,
		"generation_in_progress": generation_in_progress,
		"components_initialized": _are_components_initialized()
	}

# Check if all components are properly initialized
func _are_components_initialized() -> bool:
	return (data_component != null and 
			structure_component != null and 
			utilities_component != null and 
			interactables_component != null and 
			spawn_component != null)
