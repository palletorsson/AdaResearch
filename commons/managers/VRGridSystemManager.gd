# VRGridSystemManager.gd
# Manages VR experiences using grid systems directly without progression requirements
# Provides a clean interface for starting VR with specific maps/grid configurations

extends Node
class_name VRGridSystemManager

# References
var staging: XRToolsStaging
var current_scene: Node
var current_grid_system: Node

# Configuration
@export var default_map: String = ""  # Will be auto-determined if empty
@export var use_enhanced_grid: bool = true
@export var auto_configure_grid: bool = true
@export var vr_scene_path: String = "res://adaresearch/Common/Scenes/Maps/base.tscn"
@export var auto_determine_starting_map: bool = true  # Automatically find the first map

# Grid settings
@export var cube_size: float = 1.0
@export var gutter: float = 0.0
@export var show_grid: bool = false
@export var prefer_json_format: bool = true

# Map ordering for determining "first" map
const MAP_ORDER_PRIORITY = [
	"Tutorial_Start", "Intro_0", "Preface_0", 
	"Tutorial_Single", "Tutorial_Row", "Tutorial_Room",
	"Intro_1", "Preface_1", "Random_0", "Random_1", 
	"Random_2", "Random_3", "Random_4"
]

# Signals
signal grid_system_loaded(grid_system: Node)
signal map_loaded(map_name: String)
signal grid_configured()

func _ready():
	print("VRGridSystemManager: Initialized")
	
	# Auto-determine starting map if not set
	if auto_determine_starting_map and default_map.is_empty():
		default_map = determine_starting_map()
		print("VRGridSystemManager: Auto-determined starting map: %s" % default_map)

# Initialize with staging reference
func initialize_with_staging(staging_ref: XRToolsStaging):
	staging = staging_ref
	if staging:
		staging.scene_loaded.connect(_on_vr_scene_loaded)
		staging.scene_visible.connect(_on_vr_scene_visible)
		print("VRGridSystemManager: Connected to staging system")

# Load a map directly into VR with grid system
func load_map_in_vr(map_name: String, options: Dictionary = {}):
	if not staging:
		push_error("VRGridSystemManager: No staging reference available")
		return
	
	print("VRGridSystemManager: Loading map '%s' in VR" % map_name)
	
	# Prepare scene data
	var scene_user_data = {
		"map_name": map_name,
		"grid_manager": self,
		"use_enhanced_grid": options.get("use_enhanced_grid", use_enhanced_grid),
		"cube_size": options.get("cube_size", cube_size),
		"gutter": options.get("gutter", gutter),
		"show_grid": options.get("show_grid", show_grid),
		"prefer_json_format": options.get("prefer_json_format", prefer_json_format),
		"auto_configure": options.get("auto_configure", auto_configure_grid)
	}
	
	staging.load_scene(vr_scene_path, scene_user_data)

# Load default map (now uses determined starting map)
func load_default_map():
	var starting_map = default_map
	if starting_map.is_empty():
		starting_map = determine_starting_map()
	
	print("VRGridSystemManager: Loading starting map: %s" % starting_map)
	load_map_in_vr(starting_map)

# Switch to a different map
func switch_to_map(map_name: String, options: Dictionary = {}):
	load_map_in_vr(map_name, options)

# Configure grid system for progression-aware operation
func _configure_grid_system(grid_system: Node, map_name: String):
	if not grid_system:
		return
	
	print("VRGridSystemManager: Configuring grid system for map: %s" % map_name)
	
	# Set map name
	if "map_name" in grid_system:
		grid_system.map_name = map_name
	
	# Configure grid settings
	if "cube_size" in grid_system:
		grid_system.cube_size = cube_size
	if "gutter" in grid_system:
		grid_system.gutter = gutter
	if "showgrid" in grid_system:
		grid_system.showgrid = show_grid
	elif "show_grid" in grid_system:
		grid_system.show_grid = show_grid
	
	# Enable JSON format preference
	if "prefer_json_format" in grid_system:
		grid_system.prefer_json_format = prefer_json_format
	
	# Enable enhanced utility handler for progression support
	if grid_system.has_method("enable_enhanced_utility_handler"):
		grid_system.enable_enhanced_utility_handler()
		print("VRGridSystemManager: Enabled enhanced utility handler")
	elif grid_system.has_method("set_utility_handler_type"):
		grid_system.set_utility_handler_type("enhanced")
		print("VRGridSystemManager: Set utility handler to enhanced")
	
	# Generate/reload the grid
	if grid_system.has_method("generate_layout"):
		grid_system.generate_layout()
		print("VRGridSystemManager: Grid layout generated")

# Find and configure grid system in scene
func _find_and_configure_grid_system(scene: Node, map_name: String, options: Dictionary = {}):
	# Look for different grid system types
	var grid_names = ["GridSystem"]
	var grid_system = null
	
	for grid_name in grid_names:
		grid_system = scene.find_child(grid_name, true, false)
		if grid_system:
			print("VRGridSystemManager: Found grid system: %s" % grid_name)
			break
	
	if not grid_system:
		# Try finding by class
		grid_system = _find_node_by_class(scene, "GridSystem")
	
	if grid_system:
		_configure_grid_system(grid_system, map_name)
		grid_system_loaded.emit(grid_system)
	else:
		print("VRGridSystemManager: WARNING - No grid system found in scene")

# Find node by class name
func _find_node_by_class(parent: Node, _class_name: String) -> Node:
	for child in parent.get_children():
		if child.get_script() and child.get_script().get_global_name() == _class_name:
			return child
		var found = _find_node_by_class(child, _class_name)
		if found:
			return found
	return null

# Event handlers
func _on_vr_scene_loaded(scene: Node, user_data):
	print("VRGridSystemManager: VR scene loaded")
	current_scene = scene
	
	# Configure grid system if requested
	if user_data and typeof(user_data) == TYPE_DICTIONARY:
		var map_name = user_data.get("map_name", default_map)
		var auto_configure = user_data.get("auto_configure", auto_configure_grid)
		
		if auto_configure:
			_find_and_configure_grid_system(scene, map_name, user_data)
		
		map_loaded.emit(map_name)

func _on_vr_scene_visible(scene: Node, user_data):
	print("VRGridSystemManager: VR scene visible")

# Public API
func get_current_grid_system() -> Node:
	return current_grid_system

func get_current_scene() -> Node:
	return current_scene

func restart_current_map():
	if current_grid_system and "map_name" in current_grid_system:
		var map_name = current_grid_system.map_name
		load_map_in_vr(map_name)

# Development helpers
func list_available_maps() -> Array[String]:
	"""Get list of available maps from the data directory"""
	var maps: Array[String] = []
	var maps_dir = "res://commons/maps/"  # Updated to match actual project structure
	var dir = DirAccess.open(maps_dir)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				# Check if the directory contains map_data.json
				var map_data_path = maps_dir + file_name + "/map_data.json"
				if ResourceLoader.exists(map_data_path):
					maps.append(file_name)
					print("VRGridSystemManager: Found map: %s" % file_name)
				else:
					print("VRGridSystemManager: Skipping directory '%s' - no map_data.json found" % file_name)
			file_name = dir.get_next()
	else:
		print("VRGridSystemManager: Could not open maps directory: %s" % maps_dir)
	
	maps.sort()
	print("VRGridSystemManager: Total maps found: %d" % maps.size())
	return maps

func quick_test_map(map_name: String):
	"""Quickly test a map with default settings"""
	load_map_in_vr(map_name, {
		"show_grid": true,
		"prefer_json_format": true
	}) 

# Determine the appropriate starting map
func determine_starting_map() -> String:
	"""
	Determine the first/starting map based on available maps and priority order
	"""
	var available_maps = list_available_maps()
	
	if available_maps.is_empty():
		print("VRGridSystemManager: WARNING - No maps found, using fallback")
		return "Lab"  # Changed fallback to Lab since that's what exists
	
	# Check if Lab is available first (since it's the main hub)
	if "Lab" in available_maps:
		print("VRGridSystemManager: Using Lab as starting map (main hub)")
		return "Lab"
	
	# Try to find maps in priority order
	for priority_map in MAP_ORDER_PRIORITY:
		if priority_map in available_maps:
			print("VRGridSystemManager: Found priority starting map: %s" % priority_map)
			return priority_map
	
	# If no priority maps found, use the first alphabetically
	available_maps.sort()
	var first_map = available_maps[0]
	print("VRGridSystemManager: Using first available map: %s" % first_map)
	return first_map

# Get the determined starting map
func get_starting_map() -> String:
	if default_map.is_empty():
		return determine_starting_map()
	return default_map 

# Load VR scene with grid system
func load_vr_scene_with_grid(map_name: String) -> bool:
	print("VRGridSystemManager: Loading VR scene with grid for map: %s" % map_name)
	
	# Load the VR base scene
	var scene_instance = staging.load_scene_instance(vr_scene_path)
	if not scene_instance:
		print("ERROR: VRGridSystemManager: Failed to load VR scene: %s" % vr_scene_path)
		return false
	
	current_scene = scene_instance
	
	# Find or create grid system
	var grid_system = _find_or_create_grid_system(scene_instance, map_name)
	if not grid_system:
		print("ERROR: VRGridSystemManager: Failed to set up grid system for map: %s" % map_name)
		return false
	
	current_grid_system = grid_system
	
	# Configure grid system
	_configure_grid_system(grid_system, map_name)
	
	# Load the map
	var success = _load_map_into_grid_system(grid_system, map_name)
	if success:
		# Handle spawn points after grid is loaded
		call_deferred("_handle_spawn_points", scene_instance)
		print("VRGridSystemManager: Successfully loaded map '%s' in VR" % map_name)
	else:
		print("ERROR: VRGridSystemManager: Failed to load map '%s' into grid system" % map_name)
	
	return success

func _find_or_create_grid_system(scene: Node, map_name: String) -> Node:
	# Look for different grid system types
	var grid_names = ["GridSystem"]
	var grid_system = null
	
	for grid_name in grid_names:
		grid_system = scene.find_child(grid_name, true, false)
		if grid_system:
			print("VRGridSystemManager: Found grid system: %s" % grid_name)
			break
	
	if not grid_system:
		# Try finding by class
		grid_system = _find_node_by_class(scene, "GridSystem")
	
	if grid_system:
		_configure_grid_system(grid_system, map_name)
		grid_system_loaded.emit(grid_system)
	else:
		print("VRGridSystemManager: WARNING - No grid system found in scene")
	
	return grid_system

func _load_map_into_grid_system(grid_system: Node, map_name: String) -> bool:
	if not grid_system:
		return false
	
	# Configure grid system
	_configure_grid_system(grid_system, map_name)
	
	# Load the map
	var success = _load_map_into_grid_system(grid_system, map_name)
	if success:
		# Handle spawn points after grid is loaded
		call_deferred("_handle_spawn_points", current_scene)
		print("VRGridSystemManager: Successfully loaded map '%s' into grid system" % map_name)
	else:
		print("ERROR: VRGridSystemManager: Failed to load map '%s' into grid system" % map_name)
	
	return success

# Handle spawn points after grid is loaded
func _handle_spawn_points(scene: Node):
	if not scene:
		return
	
	print("VRGridSystemManager: Setting up default player positioning")
	
	# Wait a frame for grid to be fully initialized
	await get_tree().process_frame
	
	# Use default positioning instead of spawn points
	_position_player_at_default_location()

# Position player at a default location
func _position_player_at_default_location():
	# Find the VR origin/staging in the scene
	var vr_origin = _find_vr_origin()
	if not vr_origin:
		print("VRGridSystemManager: WARNING - Could not find VR origin to position player")
		return
	
	# Set default position (slightly elevated and back from center)
	var default_position = Vector3(0.5, 4, 0.5)  # Custom spawn position
	var default_rotation = Vector3(0, 0, 0)    # Facing forward
	
	# Position the VR origin
	vr_origin.global_position = default_position
	vr_origin.global_rotation_degrees = default_rotation
	
	print("VRGridSystemManager: Positioned player at default location - Position: %s" % default_position)

# Find VR origin in the scene
func _find_vr_origin() -> Node3D:
	if not current_scene:
		return null
	
	# Look for common VR origin node names
	var origin_names = ["XROrigin3D", "VROrigin", "ARVROrigin", "Origin", "XRPlayer"]
	
	for name in origin_names:
		var origin = current_scene.find_child(name, true, false)
		if origin and origin is Node3D:
			return origin as Node3D
	
	# Try finding by class
	return _find_node_by_class(current_scene, "XROrigin3D")

# Simplified spawn point methods (no longer dependent on SpawnPoint class)
func get_spawn_point(spawn_name: String) -> Dictionary:
	# Return default spawn info as a dictionary
	return {
		"name": spawn_name,
		"position": Vector3(0, 1.8, 3),
		"rotation": Vector3(0, 0, 0),
		"exists": false
	}

# Position player at specific location by name (simplified)
func position_player_at_spawn(spawn_name: String) -> bool:
	print("VRGridSystemManager: Using default positioning (spawn system not available)")
	_position_player_at_default_location()
	return true

# Get all available spawn points (simplified)
func get_all_spawn_points() -> Array:
	# Return empty array since spawn system is not available
	return []

# Debug: List all spawn points (simplified)
func list_spawn_points():
	print("VRGridSystemManager: Spawn point system not available - using default positioning")
