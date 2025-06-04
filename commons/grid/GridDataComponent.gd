# GridDataComponent.gd
# Handles loading and parsing map data from JSON files
# Provides data access for other grid components

extends Node
class_name GridDataComponent

# Path constants - CORRECTED TO MATCH ACTUAL PROJECT STRUCTURE
const MAPS_PATH = "res://commons/maps/"

# Configuration
@export var prefer_json_format: bool = true

# Loaded data
var json_loader: JsonMapLoader
var current_map_format: String = "unknown"
var map_name: String = ""

# Data instances (unified interface)
var structure_data_instance
var utility_data_instance  
var interactable_data_instance

# Grid dimensions
var grid_dimensions: Vector3i = Vector3i.ZERO

# Signals
signal data_loaded(map_name: String, format: String)
signal data_load_failed(map_name: String, error: String)

func _ready():
	print("GridDataComponent: Initialized")

# Load map data
func load_map_data(target_map_name: String) -> bool:
	map_name = target_map_name
	print("GridDataComponent: Loading data for map '%s'" % map_name)
	
	if prefer_json_format:
		return _load_json_map()
	else:
		print("GridDataComponent: GDScript format not supported in component version")
		return false

# Load JSON format map data
func _load_json_map() -> bool:
	var json_path = MAPS_PATH + map_name + "/map_data.json"
	
	print("GridDataComponent: Attempting to load JSON from: %s" % json_path)
	print("GridDataComponent: File exists check: %s" % FileAccess.file_exists(json_path))
	
	if not JsonMapLoader.is_json_map_file(json_path):
		var error = "No JSON map data found for '%s' at path: %s" % [map_name, json_path]
		print("GridDataComponent: ERROR - %s" % error)
		
		# Try to find available maps
		_list_available_maps()
		
		data_load_failed.emit(map_name, error)
		return false
	
	print("GridDataComponent: Loading JSON map from '%s'" % json_path)
	
	json_loader = JsonMapLoader.new()
	if json_loader.load_map(json_path):
		current_map_format = "json"
		
		# Extract instances from JSON loader
		structure_data_instance = json_loader.structure_data_instance
		utility_data_instance = json_loader.utility_data_instance
		interactable_data_instance = json_loader.interactable_data_instance
		
		# Set grid dimensions from JSON
		var dimensions = json_loader.get_dimensions()
		grid_dimensions = Vector3i(
			dimensions.get("width", 0),
			dimensions.get("max_height", 6),
			dimensions.get("depth", 0)
		)
		
		print("GridDataComponent: JSON map loaded successfully")
		print("  Dimensions: %dx%dx%d" % [grid_dimensions.x, grid_dimensions.y, grid_dimensions.z])
		
		# Generate report
		print("\n" + json_loader.generate_report())
		
		data_loaded.emit(map_name, "json")
		return true
	else:
		var error = "Failed to parse JSON map data"
		print("GridDataComponent: ERROR - %s" % error)
		data_load_failed.emit(map_name, error)
		return false

# Get settings from loaded data
func get_settings() -> Dictionary:
	if json_loader:
		return json_loader.get_settings()
	return {}

# Get spawn points from loaded data
func get_spawn_points() -> Dictionary:
	if json_loader:
		return json_loader.get_spawn_points()
	return {}

# Get utility definitions from loaded data
func get_utility_definitions() -> Dictionary:
	if json_loader:
		return json_loader.get_utility_definitions()
	return {}

# Get lighting settings from loaded data
func get_lighting_settings() -> Dictionary:
	if json_loader:
		return json_loader.get_lighting_settings()
	return {}

# Get current map metadata
func get_map_metadata() -> Dictionary:
	if json_loader:
		return json_loader.get_metadata()
	return {}

# Get grid dimensions
func get_grid_dimensions() -> Vector3i:
	return grid_dimensions

# Get structure data
func get_structure_data():
	return structure_data_instance

# Get utility data  
func get_utility_data():
	return utility_data_instance

# Get interactable data
func get_interactable_data():
	return interactable_data_instance

# Check if data is loaded
func is_data_loaded() -> bool:
	return structure_data_instance != null

# Get current map name
func get_current_map_name() -> String:
	return map_name

# Get current format
func get_current_format() -> String:
	return current_map_format

# Debug: List available maps
func _list_available_maps():
	print("GridDataComponent: Listing available maps in %s:" % MAPS_PATH)
	
	var dir = DirAccess.open(MAPS_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				var map_data_path = MAPS_PATH + file_name + "/map_data.json"
				var exists = FileAccess.file_exists(map_data_path)
				print("  → %s: %s" % [file_name, "✅ map_data.json found" if exists else "❌ no map_data.json"])
			file_name = dir.get_next()
	else:
		print("GridDataComponent: Could not open maps directory: %s" % MAPS_PATH)
