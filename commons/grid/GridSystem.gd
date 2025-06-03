# GridSystem.gd
# Enhanced grid system that supports JSON map format with grid-based spawn points
# Unified interface for loading and managing map data from JSON files

extends Node3D
class_name GridSystem

# Configuration
@export var cube_size: float = 1.0
@export var gutter: float = 0.0
@export var grid_y: int = 6  # Maximum height
@export var showgrid: bool = false

# Map selection
@export var map_name: String = "Tutorial_Start"
@export var reload_map: bool = false : set = reload_map_setter

# Path constants
const MAPS_PATH = "res://commons/maps/"
const MAP_OBJECTS_PATH = "res://commons/scenes/mapobjects/"
const UTILITY_SCENE_BASE_PATH = "res://commons/scenes/mapobjects/"

# Grid properties
var grid_x: int
var grid_z: int
var grid: Array = []
var cube_map: Dictionary = {}
var utility_objects: Dictionary = {}
var interactable_objects: Dictionary = {}

# Enhanced utility handling
var use_enhanced_utility_handler: bool = true
var enhanced_utility_handler: EnhancedUtilityHandler

# Task registry for artifact lookup
var task_info_registry: Dictionary = {}

# Map loading system
var current_map_format: String = "json"
var json_loader: JsonMapLoader
var prefer_json_format: bool = true

# Data instances (unified interface)
var structure_data_instance
var utility_data_instance
var interactable_data_instance
var _scene_cache = {}

# Components
@onready var base_cube = $CubeScene
@onready var algorithm_registry = AlgorithmRegistry.new()

# Scene cache
var scene_cache = {}
var rng = RandomNumberGenerator.new()

# Signals
signal map_loaded(map_name: String, format: String)
signal map_generation_complete()
signal interactable_activated(object_id, position, data)

func _ready():
	if not base_cube:
		print("ERROR: Base cube reference not found!")
		return
	
	rng.randomize()
	print("GridSystem: Initializing...")
	
	# Initialize enhanced utility handler if enabled
	if use_enhanced_utility_handler:
		enhanced_utility_handler = EnhancedUtilityHandler.new(self)
		add_child(enhanced_utility_handler)
		print("GridSystem: Enhanced utility handler initialized")
	
	# Add algorithm registry
	add_child(algorithm_registry)
	algorithm_registry.connect("registry_loaded", _on_algorithm_registry_loaded)
	
	# CHECK FOR SCENE DATA FIRST - THIS IS THE KEY FIX!
	_check_for_scene_data()
	
	# Load the JSON map (will use updated map_name if scene data was found)
	_load_json_map()

# NEW METHOD: Check for scene data and update map_name
func _check_for_scene_data():
	"""Check if scene was loaded with specific map data"""
	var scene_root = get_tree().current_scene
	
	# Check for scene user data from AdaSceneManager
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
			print("GridSystem: Stored sequence data for reference")
	else:
		print("GridSystem: No scene data found, using default map_name: %s" % map_name)

func _load_json_map() -> void:
	var json_path = MAPS_PATH + map_name + "/map_data.json"
	
	if not JsonMapLoader.is_json_map_file(json_path):
		print("ERROR: No JSON map data found for '%s'" % map_name)
		return
	
	print("GridSystem: Loading JSON map from '%s'" % json_path)
	
	json_loader = JsonMapLoader.new()
	if json_loader.load_map(json_path):
		current_map_format = "json"
		
		# Extract instances from JSON loader
		structure_data_instance = json_loader.structure_data_instance
		utility_data_instance = json_loader.utility_data_instance
		interactable_data_instance = json_loader.interactable_data_instance
		
		# Apply JSON settings
		var settings = json_loader.get_settings()
		cube_size = settings.get("cube_size", cube_size)
		gutter = settings.get("gutter", gutter)
		showgrid = settings.get("show_grid", showgrid)
		
		# Set grid dimensions from JSON
		var dimensions = json_loader.get_dimensions()
		grid_x = dimensions.get("width", 0)
		grid_z = dimensions.get("depth", 0)
		grid_y = dimensions.get("max_height", grid_y)
		
		print("GridSystem: JSON map loaded successfully")
		print("  Dimensions: %dx%dx%d" % [grid_x, grid_z, grid_y])
		print("  Cube size: %f, Gutter: %f" % [cube_size, gutter])
		
		emit_signal("map_loaded", map_name, "json")
		
		# Generate report
		print("\n" + json_loader.generate_report())
		
		_finalize_map_loading()
	else:
		print("ERROR: Failed to load JSON map")

func _load_scene(p_scene_identifier: String) -> PackedScene:
	var resolved_path: String

	# 1. Resolve the full path to the scene file.
	if p_scene_identifier.begins_with("res://"):
		# Assume p_scene_identifier is already a full path.
		resolved_path = p_scene_identifier
	else:
		# Assume p_scene_identifier is a base filename; prepend the known base path.
		# This is where you ensure the correct directory is used.
		resolved_path = UTILITY_SCENE_BASE_PATH.path_join(p_scene_identifier)

	# 2. Check if the scene is already in the cache.
	if _scene_cache.has(resolved_path):
		print_debug("GridSystem: Loading scene from cache: %s" % resolved_path)
		return _scene_cache[resolved_path]

	# 3. If not in cache, attempt to load it from disk.
	if ResourceLoader.exists(resolved_path):
		print_debug("GridSystem: Loading scene from disk: %s" % resolved_path)
		var resource = ResourceLoader.load(resolved_path) # Use ResourceLoader for clarity

		if resource is PackedScene:
			_scene_cache[resolved_path] = resource # Add to cache for next time
			return resource
		else:
			# The file exists but it's not a PackedScene (or failed to load as one).
			printerr("GridSystem ERROR: Resource at path '%s' is not a PackedScene." % resolved_path)
			return null
	else:
		# The file does not exist at the resolved path.
		printerr("GridSystem ERROR: Scene file not found at resolved path: %s (Original identifier: '%s')" % [resolved_path, p_scene_identifier])
		return null

# Optional: A method to allow clearing the cache if necessary (e.g., on map changes).
func clear_scene_cache() -> void:
	_scene_cache.clear()
	print_debug("GridSystem: Scene cache cleared.")

# Optional: A method for preloading common scenes to populate the cache.
func preload_common_scenes(scene_identifiers: Array) -> void:
	for identifier in scene_identifiers:
		var scene = _load_scene(identifier) # Call _load_scene to load and cache it
		if scene == null:
			printerr("GridSystem WARNING: Failed to preload scene: %s" % identifier)
	print_debug("GridSystem: Finished preloading scenes.")

func _finalize_map_loading() -> void:
	# Wait for algorithm registry if needed
	if algorithm_registry.get_all_algorithm_ids().size() > 0:
		_on_algorithm_registry_loaded()
	else:
		# Registry is empty or not loaded yet, proceed anyway
		print("GridSystem: Algorithm registry empty, proceeding with grid generation...")
		_on_algorithm_registry_loaded()

func _on_algorithm_registry_loaded():
	print("GridSystem: Algorithm registry loaded, generating grid...")
	base_cube.visible = false
	_generate_grid()
	
	# NEW: Handle player spawn positioning after grid is generated
	call_deferred("_handle_player_spawn")

func _generate_grid() -> void:
	print("GridSystem: Starting grid generation")
	_initialize_grid()
	_apply_structure_data()
	_apply_utility_data()
	_apply_interactable_data()
	
	print("GridSystem: Grid generation completed")
	emit_signal("map_generation_complete")

func _initialize_grid() -> void:
	print("GridSystem: Initializing grid: %dx%dx%d" % [grid_x, grid_y, grid_z])
	grid = []
	cube_map.clear()
	utility_objects.clear()
	interactable_objects.clear()
	
	# Pre-allocate grid
	grid.resize(grid_x)
	for x in grid_x:
		var y_array = []
		y_array.resize(grid_y)
		grid[x] = y_array
		
		for y in grid_y:
			var z_array = []
			z_array.resize(grid_z)
			grid[x][y] = z_array
			
			for z in grid_z:
				grid[x][y][z] = false

func _apply_structure_data() -> void:
	if not structure_data_instance:
		print("WARNING: No structure data to apply")
		return
	
	print("GridSystem: Applying structure data")
	var structure_layout = structure_data_instance.layout_data
	var total_size = cube_size + gutter
	var cube_count = 0
	
	for z in grid_z:
		var row = structure_layout[z]
		for x in grid_x:
			var cell_value = str(row[x]).strip_edges()
			var stack_height = 0
			
			if cell_value.is_valid_int():
				stack_height = int(cell_value)
			
			# Create stacked cubes
			for y in range(0, min(stack_height, grid_y)):
				_add_cube(x, y, z, total_size)
				grid[x][y][z] = true
				cube_count += 1
	
	print("GridSystem: Added %d cubes" % cube_count)

func _apply_utility_data() -> void:
	if not utility_data_instance:
		print("WARNING: No utility data to apply")
		return
	
	print("GridSystem: Applying utility data")
	var total_size = cube_size + gutter
	var utility_count = 0
	
	# Check if we're using JSON format with utility definitions and enhanced handler
	if current_map_format == "json" and use_enhanced_utility_handler and enhanced_utility_handler:
		print("GridSystem: Using enhanced utility handler for JSON format")
		
		# Get utility definitions from JSON data
		var utility_definitions = {}
		if json_loader and json_loader.map_data.has("utility_definitions"):
			utility_definitions = json_loader.map_data["utility_definitions"]
		
		var utility_layout = utility_data_instance.layout_data
		
		for z in range(min(grid_z, utility_layout.size())):
			var row = utility_layout[z]
			for x in range(min(grid_x, row.size())):
				var utility_cell = str(row[x]).strip_edges()
				
				if utility_cell.is_empty() or utility_cell == " ":
					continue
				
				# Parse utility cell with parameters
				var parsed = UtilityRegistry.parse_utility_cell(utility_cell)
				var utility_type = parsed.type
				
				if UtilityRegistry.is_valid_utility_type(utility_type) and utility_type != " ":
					var y_pos = _find_highest_y_at(x, z)
					
					# Get utility definition if available
					var utility_definition = utility_definitions.get(utility_type, {})
					
					# Use enhanced handler to place utility
					enhanced_utility_handler.place_utility(x, y_pos, z, utility_type, utility_definition, total_size)
					utility_count += 1
		
		print("GridSystem: Added %d utilities via enhanced handler" % utility_count)
		return
	
	# Fallback to original utility placement for legacy format or when enhanced handler is disabled
	print("GridSystem: Using legacy utility placement")
	var utility_layout = utility_data_instance.layout_data
	
	# Validate utilities using UtilityRegistry
	var validation = UtilityRegistry.validate_utility_grid(utility_layout)
	if not validation.valid:
		print("WARNING: Utility validation issues found:")
		for error in validation.errors:
			print("  ERROR: %s" % error)
		for warning in validation.warnings:
			print("  WARNING: %s" % warning)
	
	for z in range(min(grid_z, utility_layout.size())):
		var row = utility_layout[z]
		for x in range(min(grid_x, row.size())):
			var utility_cell = str(row[x]).strip_edges()
			
			if utility_cell.is_empty() or utility_cell == " ":
				continue
			
			# Parse utility cell with parameters
			var parsed = UtilityRegistry.parse_utility_cell(utility_cell)
			var utility_type = parsed.type
			var parameters = parsed.parameters
			
			if UtilityRegistry.is_valid_utility_type(utility_type) and utility_type != " ":
				var y_pos = _find_highest_y_at(x, z)
				_place_utility(x, y_pos, z, utility_type, parameters, total_size)
				utility_count += 1
	
	print("GridSystem: Added %d utilities" % utility_count)

func _apply_interactable_data() -> void:
	if not interactable_data_instance:
		print("WARNING: No interactable data to apply")
		return
	
	print("GridSystem: Applying interactable data")
	
	# Check for different property names (layout_data vs interactable_data)
	var interactable_layout = null
	if interactable_data_instance.has_method("get") and interactable_data_instance.get("layout_data"):
		interactable_layout = interactable_data_instance.layout_data
	elif interactable_data_instance.has_method("get") and interactable_data_instance.get("interactable_data"):
		interactable_layout = interactable_data_instance.interactable_data
	
	if not interactable_layout:
		print("WARNING: No interactable layout found")
		return
	
	var total_size = cube_size + gutter
	var interactable_count = 0
	
	for z in range(min(grid_z, interactable_layout.size())):
		var row = interactable_layout[z]
		for x in range(min(grid_x, row.size())):
			var algorithm_id = str(row[x]).strip_edges()
			
			if algorithm_id != " " and not algorithm_id.is_empty():
				var algorithm_data = algorithm_registry.get_algorithm(algorithm_id)
				if algorithm_data and algorithm_data.size() > 0:
					var y_pos = _find_highest_y_at(x, z)
					
					# Adjust for utilities at same position
					var utility_key = Vector3i(x, y_pos, z)
					if utility_objects.has(utility_key):
						y_pos += 1
					
					_place_algorithm(x, y_pos, z, algorithm_id, total_size)
					interactable_count += 1
				else:
					print("WARNING: Algorithm '%s' not found in registry" % algorithm_id)
	
	print("GridSystem: Added %d interactables" % interactable_count)

# NEW METHOD: Handle player spawn positioning
func _handle_player_spawn():
	"""Position player at spawn point after map is loaded"""
	print("GridSystem: Handling player spawn positioning...")
	
	# Look for spawn point utilities in the grid first
	var spawn_point_position = _find_spawn_point_utility()
	
	if spawn_point_position != Vector3.ZERO:
		print("GridSystem: Found spawn point utility at grid position: %s" % spawn_point_position)
		_position_player_at_grid_spawn(spawn_point_position)
	else:
		# Fallback to JSON spawn points
		_handle_json_spawn_points()

# NEW METHOD: Find spawn point utilities in the grid
func _find_spawn_point_utility() -> Vector3:
	"""Find spawn point utilities placed in the grid"""
	if not utility_data_instance:
		return Vector3.ZERO
	
	var utility_layout = utility_data_instance.layout_data
	var total_size = cube_size + gutter
	
	for z in range(min(grid_z, utility_layout.size())):
		var row = utility_layout[z]
		for x in range(min(grid_x, row.size())):
			var utility_cell = str(row[x]).strip_edges()
			
			if utility_cell.is_empty() or utility_cell == " ":
				continue
			
			# Parse utility cell
			var parsed = UtilityRegistry.parse_utility_cell(utility_cell)
			var utility_type = parsed.type
			
			# Check if this is a spawn point
			if utility_type == "s":
				# Find the highest Y position at this grid location
				var y_pos = _find_highest_y_at(x, z)
				var world_position = Vector3(x, y_pos, z) * total_size
				
				print("GridSystem: Found spawn point 's' at grid(%d, %d, %d) -> world%s" % [x, y_pos, z, world_position])
				return world_position
	
	return Vector3.ZERO

# NEW METHOD: Position player at grid-based spawn point
func _position_player_at_grid_spawn(world_position: Vector3):
	"""Position player at a grid-based spawn point"""
	# Find the VR origin
	var vr_origin = _find_vr_origin()
	if not vr_origin:
		print("GridSystem: WARNING - Could not find VR origin for spawn positioning")
		return
	
	# Get spawn point properties from utility definition
	var spawn_height = _get_spawn_point_height()
	var final_position = world_position + Vector3(0, spawn_height, 0)
	
	# Apply position and default rotation
	vr_origin.global_position = final_position
	vr_origin.global_rotation_degrees = Vector3(0, 0, 0)  # Face forward by default
	
	print("GridSystem: ✓ Player positioned at grid spawn point")
	print("  Grid position: %s" % world_position)
	print("  Final position: %s (with height offset: %f)" % [final_position, spawn_height])
	
	# Apply spawn transition
	_apply_spawn_transition_effect(vr_origin, {"description": "Grid-based spawn point"})

# NEW METHOD: Get spawn point height from utility definition
func _get_spawn_point_height() -> float:
	"""Get spawn point height from utility definition"""
	if current_map_format == "json" and json_loader:
		var utility_definitions = json_loader.get_utility_definitions()
		var spawn_def = utility_definitions.get("s", {})
		var properties = spawn_def.get("properties", {})
		
		# Get height from properties (default to 1.8 for VR player height)
		var height = properties.get("height", 1.8)
		print("GridSystem: Using spawn height: %f" % height)
		return height
	
	return 1.8  # Default VR player height

# NEW METHOD: Handle JSON spawn points as fallback
func _handle_json_spawn_points():
	"""Handle JSON-defined spawn points as fallback"""
	print("GridSystem: No grid spawn points found, checking JSON spawn points...")
	
	if current_map_format != "json" or not json_loader:
		print("GridSystem: No JSON data available, using default position")
		_apply_default_spawn_position()
		return
	
	var spawn_points = json_loader.get_spawn_points()
	if spawn_points.is_empty():
		print("GridSystem: No JSON spawn points defined, using default position")
		_apply_default_spawn_position()
		return
	
	# Use default spawn point from JSON
	var default_spawn = spawn_points.get("default", {})
	if not default_spawn.is_empty():
		_position_player_at_spawn(default_spawn)
	else:
		_apply_default_spawn_position()

# NEW METHOD: Position player at JSON-defined spawn point
func _position_player_at_spawn(spawn_data: Dictionary):
	"""Position the VR player at specified spawn point"""
	var spawn_position = spawn_data.get("position", [0, 1.5, 0])
	var spawn_rotation = spawn_data.get("rotation", [0, 0, 0])
	
	# Convert arrays to Vector3
	var world_position = Vector3(spawn_position[0], spawn_position[1], spawn_position[2])
	var world_rotation = Vector3(spawn_rotation[0], spawn_rotation[1], spawn_rotation[2])
	
	print("GridSystem: Positioning player at JSON spawn - Position: %s, Rotation: %s" % [world_position, world_rotation])
	
	# Find the VR origin in the scene
	var vr_origin = _find_vr_origin()
	if not vr_origin:
		print("GridSystem: WARNING - Could not find VR origin to position player")
		return
	
	# Apply position (spawn points are in world coordinates, not grid coordinates)
	vr_origin.global_position = world_position
	vr_origin.global_rotation_degrees = world_rotation
	
	print("GridSystem: ✓ Player positioned at JSON spawn point - Position: %s, Rotation: %s" % [world_position, world_rotation])
	
	# Apply spawn transition effect
	_apply_spawn_transition_effect(vr_origin, spawn_data)

# NEW METHOD: Apply default spawn position when no spawn points are defined
func _apply_default_spawn_position():
	"""Apply a sensible default spawn position"""
	var vr_origin = _find_vr_origin()
	if not vr_origin:
		return
	
	# Position player at a reasonable default location
	var default_position = Vector3(0, 2, 3)  # Slightly elevated and back from center
	vr_origin.global_position = default_position
	vr_origin.global_rotation_degrees = Vector3.ZERO
	
	print("GridSystem: Applied default spawn position: %s" % default_position)

# NEW METHOD: Find VR origin in the scene
func _find_vr_origin() -> Node3D:
	"""Find the VR origin node for player positioning"""
	var scene_root = get_tree().current_scene
	if not scene_root:
		return null
	
	# Look for common VR origin node names
	var origin_names = ["XROrigin3D", "VROrigin", "ARVROrigin", "Origin", "XRPlayer"]
	
	for name in origin_names:
		var origin = scene_root.find_child(name, true, false)
		if origin and origin is Node3D:
			print("GridSystem: Found VR origin: %s" % origin.name)
			return origin as Node3D
	
	# Try finding by walking up the scene tree from grid system
	var current_node = self
	while current_node:
		for child in current_node.get_children():
			if child.name.to_lower().contains("origin") and child is Node3D:
				print("GridSystem: Found VR origin via tree walk: %s" % child.name)
				return child as Node3D
		current_node = current_node.get_parent()
	
	print("GridSystem: Could not find VR origin")
	return null

# NEW METHOD: Apply spawn transition effect
func _apply_spawn_transition_effect(vr_origin: Node3D, spawn_data: Dictionary):
	"""Apply a smooth transition effect when spawning"""
	# Wait for everything to settle
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Display welcome message if available
	var description = spawn_data.get("description", "")
	if not description.is_empty():
		print("GridSystem: Spawn description: %s" % description)
		# You could show this as a UI message or floating text
	
	# Add a gentle camera sway to help orient the player
	_apply_gentle_orientation_cue(vr_origin)
	
	print("GridSystem: Spawn transition complete")

# NEW METHOD: Gentle orientation cue for player
func _apply_gentle_orientation_cue(vr_origin: Node3D):
	"""Provide a subtle visual cue to help player understand their orientation"""
	# Create a simple tween to slightly adjust the camera
	var tween = create_tween()
	var original_position = vr_origin.global_position
	
	# Gentle up-down motion to indicate spawn
	tween.tween_property(vr_origin, "global_position", original_position + Vector3(0, 0.1, 0), 0.3)
	tween.tween_property(vr_origin, "global_position", original_position, 0.3)
	
	print("GridSystem: Applied orientation cue")

func _find_highest_y_at(x: int, z: int) -> int:
	for y in range(grid_y-1, -1, -1):
		if grid[x][y][z]:
			return y + 1
	return 0

func _add_cube(x: int, y: int, z: int, total_size: float) -> void:
	var position = Vector3(x, y, z) * total_size
	var new_cube = base_cube.duplicate()
	new_cube.position = position
	new_cube.visible = true
	add_child(new_cube)
	
	if get_tree() and get_tree().edited_scene_root:
		new_cube.owner = get_tree().edited_scene_root
	
	cube_map[Vector3i(x, y, z)] = new_cube

func _place_utility(x: int, y: int, z: int, utility_type: String, parameters: Array, total_size: float) -> void:
	var position = Vector3(x, y, z) * total_size
	
	var scene_path = UtilityRegistry.get_utility_scene_path(utility_type)
	if scene_path.is_empty():
		print("WARNING: No scene file for utility type '%s'" % utility_type)
		return
	
	var scene_resource = _load_scene_cached(UtilityRegistry.get_utility_info(utility_type).file)
	if not scene_resource:
		print("WARNING: Could not load scene for utility type '%s'" % utility_type)
		return
	
	var utility_object = scene_resource.instantiate()
	if utility_object:
		utility_object.position = position
		
		# Apply parameters if supported
		if parameters.size() > 0 and UtilityRegistry.supports_parameters(utility_type):
			_apply_utility_parameters(utility_object, utility_type, parameters)
		
		add_child(utility_object)
		
		if get_tree() and get_tree().edited_scene_root:
			utility_object.owner = get_tree().edited_scene_root
		
		utility_objects[Vector3i(x, y, z)] = utility_object
		
		var param_info = ""
		if parameters.size() > 0:
			param_info = " (params: %s)" % str(parameters)
		print("  Added %s at (%d,%d,%d)%s" % [UtilityRegistry.get_utility_name(utility_type), x, y, z, param_info])

func _apply_utility_parameters(utility_object: Node3D, utility_type: String, parameters: Array) -> void:
	# Basic parameter application - can be extended
	match utility_type:
		"t":  # Teleport
			if parameters.size() > 0 and utility_object.has_property("destination"):
				utility_object.destination = parameters[0]
		"l":  # Lift
			if parameters.size() > 0 and utility_object.has_property("height"):
				utility_object.height = float(parameters[0])

func _place_algorithm(x: int, y: int, z: int, algorithm_id: String, total_size: float) -> void:
	var position = Vector3(x, y, z) * total_size
	var algorithm_object = algorithm_registry.get_algorithm_scene(algorithm_id)
	
	if algorithm_object:
		algorithm_object.position = position
		
		# Update label if exists
		var label = algorithm_object.find_child("id_info_Label3D")
		if label and label is Label3D:
			var algorithm_metadata = algorithm_registry.get_algorithm(algorithm_id)
			var algorithm_name = algorithm_metadata.get("name", "Unknown")
			label.text = str(algorithm_id) + ": " + str(algorithm_name)
		
		# Connect signals
		if algorithm_object.has_signal("interact"):
			algorithm_object.connect("interact", _on_algorithm_interact.bind(algorithm_id, Vector3i(x, y, z)))
		
		if algorithm_object.has_signal("algorithm_event"):
			algorithm_object.connect("algorithm_event", _on_algorithm_event.bind(algorithm_id, Vector3i(x, y, z)))
		
		add_child(algorithm_object)
		
		if get_tree() and get_tree().edited_scene_root:
			algorithm_object.owner = get_tree().edited_scene_root
		
		interactable_objects[Vector3i(x, y, z)] = algorithm_object
		print("  Added algorithm '%s' at (%d,%d,%d)" % [algorithm_id, x, y, z])

func _load_scene_cached(scene_filename: String) -> PackedScene:
	if scene_filename.is_empty():
		return null
	
	if scene_cache.has(scene_filename):
		return scene_cache[scene_filename]
	
	var scene_path = MAP_OBJECTS_PATH + scene_filename
	if ResourceLoader.exists(scene_path):
		var scene = ResourceLoader.load(scene_path)
		scene_cache[scene_filename] = scene
		return scene
	else:
		print("ERROR: Scene file not found: %s" % scene_path)
		return null

func _on_algorithm_interact(algorithm_id: String, position: Vector3i, data = null) -> void:
	emit_signal("interactable_activated", algorithm_id, position, data)
	print("Algorithm interaction: %s at %s" % [algorithm_id, position])

func _on_algorithm_event(event_name: String, event_data, algorithm_id: String, position: Vector3i) -> void:
	print("Algorithm event: %s from %s at %s" % [event_name, algorithm_id, position])

func reload_map_setter(value: bool) -> void:
	if value:
		reload_map = false
		# Use call_deferred for async function since setters can't be async
		call_deferred("_reload_current_map")

func _reload_current_map() -> void:
	print("GridSystem: Reloading map '%s'" % map_name)
	
	# Clear existing objects completely
	_clear_all_objects()
	scene_cache.clear()
	
	# Reset data instances
	structure_data_instance = null
	utility_data_instance = null
	interactable_data_instance = null
	json_loader = null
	
	# Wait one frame to ensure cleanup is complete
	await get_tree().process_frame
	
	# Reload map
	_load_json_map()

# Public reload method that can be awaited
func reload_map_async() -> void:
	await _reload_current_map()

func _clear_all_objects() -> void:
	print("GridSystem: Clearing all objects...")
	
	# Stop all audio first
	_stop_all_audio()
	
	# Clear cubes immediately
	for key in cube_map.keys():
		var cube = cube_map[key]
		if is_instance_valid(cube):
			cube.remove_from_group("cubes") if cube.is_in_group("cubes") else null
			_stop_node_audio(cube)
			cube.queue_free()
	cube_map.clear()
	
	# Clear utilities immediately
	for key in utility_objects.keys():
		var utility = utility_objects[key]
		if is_instance_valid(utility):
			_stop_node_audio(utility)
			utility.queue_free()
	utility_objects.clear()
	
	# Clear interactables immediately
	for key in interactable_objects.keys():
		var interactable = interactable_objects[key]
		if is_instance_valid(interactable):
			_stop_node_audio(interactable)
			interactable.queue_free()
	interactable_objects.clear()
	
	# Clear the grid array
	grid.clear()
	
	print("GridSystem: All objects cleared")

# Stop all audio from a node and its children
func _stop_node_audio(node: Node) -> void:
	if not is_instance_valid(node):
		return
	
	# Stop AudioStreamPlayer nodes
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		node.stop()
	
	# Check all children recursively
	for child in node.get_children():
		_stop_node_audio(child)

# Stop all audio in the entire scene
func _stop_all_audio() -> void:
	print("GridSystem: Stopping all audio...")
	
	# Stop audio from the grid system and all its children
	_stop_node_audio(self)
	
	# Also stop any audio from the parent scene
	var root = get_tree().current_scene
	if root:
		_stop_node_audio(root)

# Get current map information
func get_current_map_info() -> Dictionary:
	var info = {
		"name": map_name,
		"format": current_map_format,
		"dimensions": {"x": grid_x, "y": grid_y, "z": grid_z},
		"objects": {
			"cubes": cube_map.size(),
			"utilities": utility_objects.size(),
			"interactables": interactable_objects.size()
		}
	}
	
	if current_map_format == "json" and json_loader:
		info.merge(json_loader.get_metadata())
	
	return info 

# Public API methods

# Enable enhanced utility handler for progression support
func enable_enhanced_utility_handler():
	use_enhanced_utility_handler = true
	if not enhanced_utility_handler:
		enhanced_utility_handler = EnhancedUtilityHandler.new(self)
		add_child(enhanced_utility_handler)
		print("GridSystem: Enhanced utility handler enabled")

# Disable enhanced utility handler 
func disable_enhanced_utility_handler():
	use_enhanced_utility_handler = false
	if enhanced_utility_handler:
		enhanced_utility_handler.queue_free()
		enhanced_utility_handler = null
		print("GridSystem: Enhanced utility handler disabled")

# Set utility handler type
func set_utility_handler_type(handler_type: String):
	match handler_type.to_lower():
		"enhanced":
			enable_enhanced_utility_handler()
		"legacy", "standard":
			disable_enhanced_utility_handler()
		_:
			print("GridSystem: Unknown utility handler type: %s" % handler_type)
