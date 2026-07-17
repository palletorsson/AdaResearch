# GridDataComponent.gd
# Handles loading and parsing map data from JSON files
# Provides data access for other grid components

extends Node
class_name GridDataComponent

# Path constants - CORRECTED TO MATCH ACTUAL PROJECT STRUCTURE
const MAPS_PATH = "res://commons/maps/"

# Configuration
@export var prefer_json_format: bool = true
# When true, and a sibling map_data.corridor.json exists, load THAT instead.
# Used by SpineRunner to consume procedurally-generated 16x8 layouts.
@export var prefer_corridor_variant: bool = false

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


# Android dev loop: prefer an adb-pushed override of this map (no APK rebuild). Returns the override
# path if one exists for `name`, else the original res:// path. NO-OP on desktop, so the normal
# editor / PCVR flow is unchanged. Pairs with tools/push_map_to_quest.ps1.
func _map_override_path(original: String, name: String) -> String:
	if not OS.has_feature("android"):
		return original
	var rel := "override_map/%s/map_data.json" % name
	var candidates: Array = ["user://" + rel]   # internal files/ (adb run-as writes)
	var udir := OS.get_user_data_dir().replace("\\", "/")   # /data/user/0/<pkg>/files
	var segs := udir.split("/", false)
	var fi := segs.find("files")
	if fi > 0:
		# app-private external dir — adb-pushable without root: /sdcard/Android/data/<pkg>/files/...
		candidates.append("/storage/emulated/0/Android/data/%s/files/%s" % [segs[fi - 1], rel])
	for c in candidates:
		if FileAccess.file_exists(c):
			print("GridDataComponent: PUSHED override map → %s" % c)
			return c
	return original

# Load JSON format map data
func _load_json_map() -> bool:
	var json_path = ""
	
	print("🔍 DEBUG: GridDataComponent._load_json_map() called")
	print("🔍 DEBUG: map_name = '%s'" % map_name)
	
	# Handle Lab subfolder structure
	if map_name.begins_with("Lab/"):
		# For Lab progressive maps: res://commons/maps/Lab/map_data_init.json
		var lab_map_file = map_name.substr(4)  # Remove "Lab/" prefix
		json_path = MAPS_PATH + "Lab/" + lab_map_file + ".json"
		print("🔍 DEBUG: Lab progressive map detected")
		print("🔍 DEBUG: lab_map_file = '%s'" % lab_map_file)
		print("🔍 DEBUG: json_path = '%s'" % json_path)
	elif map_name == "Lab":
		# For base Lab map: res://commons/maps/Lab/map_data.json  
		json_path = MAPS_PATH + "Lab/map_data.json"
		print("🔍 DEBUG: Base Lab map")
		print("🔍 DEBUG: json_path = '%s'" % json_path)
	else:
		# For regular maps: res://commons/maps/Tutorial_Start/map_data.json
		json_path = MAPS_PATH + map_name + "/map_data.json"
		print("🔍 DEBUG: Regular map")
		print("🔍 DEBUG: json_path = '%s'" % json_path)

	# Spine-runner corridor variant: prefer map_data.corridor.json when present
	# and prefer_corridor_variant is set. Falls back silently if not generated yet.
	if prefer_corridor_variant and not map_name.begins_with("Lab"):
		var corridor_path = MAPS_PATH + map_name + "/map_data.corridor.json"
		if FileAccess.file_exists(corridor_path):
			print("GridDataComponent: loading CORRIDOR variant: %s" % corridor_path)
			json_path = corridor_path
		else:
			print("GridDataComponent: corridor variant not found, using base map_data.json")
	
	# Android: an adb-pushed override of this map wins over the baked res:// copy (no-op on desktop).
	json_path = _map_override_path(json_path, map_name)
	print("🔍 DEBUG: Final json_path = '%s'" % json_path)
	print("🔍 DEBUG: File exists check: %s" % FileAccess.file_exists(json_path))
	
	# List what files actually exist in the Lab folder
	print("🔍 DEBUG: Files in Lab folder:")
	var lab_dir = DirAccess.open(MAPS_PATH + "Lab/")
	if lab_dir:
		lab_dir.list_dir_begin()
		var file_name = lab_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				print("🔍 DEBUG:   → %s" % file_name)
			file_name = lab_dir.get_next()
	else:
		print("🔍 DEBUG: Could not open Lab folder!")
	
	if not JsonMapLoader.is_json_map_file(json_path):
		var error = "No JSON map data found for '%s' at path: %s" % [map_name, json_path]
		print("GridDataComponent: ERROR - %s" % error)
		
		# Try to find available maps
		_list_available_maps()
		
		data_load_failed.emit(map_name, error)
		return false
	
	print("GridDataComponent: Loading JSON map from '%s'" % json_path)
	
	# Rest of the method stays the same...
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
		print("  Map name from JSON: %s" % json_loader.get_map_name())
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

## Optional 4th layer for biome-density hints. See
## algorithms/nature_system/systems/biome_paint_tokens.gd for the token
## language. Returns [] when the map has no biome_paint layer.
func get_biome_paint_layer() -> Array:
	if json_loader:
		return json_loader.get_biome_paint_layer()
	return []


## Optional 5th layer: per-cell ground TYPE. See
## commons/biome_layers/ground_types.json for the catalog. Returns []
## when the map has no ground_paint layer (backward-compatible).
func get_ground_paint_layer() -> Array:
	if json_loader:
		return json_loader.get_ground_paint_layer()
	return []


## Per-map biome AUTHORING: paint-layer specs (element × distribution ×
## density). See doc/PAINT_LAYERS.md. Returns [] when the map has none.
func get_paint_layers() -> Array:
	if json_loader and json_loader.has_method("get_paint_layers"):
		return json_loader.get_paint_layers()
	return []

# Get lighting settings from loaded data
func get_lighting_settings() -> Dictionary:
	if json_loader:
		return json_loader.get_lighting_settings()
	return {}

# Get per-map environment overrides (from map_data.json "environment" block)
func get_environment_overrides() -> Dictionary:
	if json_loader:
		return json_loader.get_environment_overrides()
	return {}

# Get the resolved environment config for this map.
# Merges: soft_stages defaults (from sequence) + per-map overrides.
# Returns: { terrain_mode, vegetation_density, ambient_energy, fog_density, ... }
func get_environment_config() -> Dictionary:
	# Stage defaults come from EcosystemManager (reads soft_stages.json)
	var eco = Engine.get_singleton("EcosystemManager") if Engine.has_singleton("EcosystemManager") else null
	var defaults: Dictionary = {}
	if eco and eco.has_method("get_current_ecosystem_config"):
		defaults = eco.get_current_ecosystem_config()
	else:
		# Fallback defaults when EcosystemManager isn't available
		defaults = {
			"terrain_mode": "flat",
			"vegetation_density": 0.0,
			"nature_kingdoms": [],
			"ambient_preset": "empty_lab",
		}

	# Merge per-map overrides on top of defaults
	var overrides: Dictionary = get_environment_overrides()
	for key in overrides:
		defaults[key] = overrides[key]

	return defaults

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

# Get the optional interior wall-segments layer (additive).
# Returns layers.walls (grid of edge-code strings: n/e/s/w = wall on that
# edge, uppercase = doorway). Empty array if absent — maps without a walls
# layer are unaffected. See GridWallSegmentsComponent.
func get_walls_layer() -> Array:
	if json_loader and json_loader.map_data is Dictionary:
		var layers = json_loader.map_data.get("layers", {})
		if layers is Dictionary:
			var walls = layers.get("walls", [])
			if walls is Array:
				return walls
	return []

# Get the optional living-biome layer (additive; P-8 grammar, see
# BiomeGridTokens / doc/plans/biome_grid_redesign.md). Empty array if absent —
# maps without a biome layer are unaffected. See GridBiomeComponent.
func get_biome_layer() -> Array:
	if json_loader and json_loader.map_data is Dictionary:
		var layers = json_loader.map_data.get("layers", {})
		if layers is Dictionary:
			var biome = layers.get("biome", [])
			if biome is Array:
				return biome
	return []

# Raw structure layer grid (strings), for components that need per-cell
# heights without the parsed instance (e.g. wall segment base elevation).
func get_structure_layer_raw() -> Array:
	if json_loader and json_loader.map_data is Dictionary:
		var layers = json_loader.map_data.get("layers", {})
		if layers is Dictionary:
			var st = layers.get("structure", [])
			if st is Array:
				return st
	return []

# Get the modifier op-stack from the loaded map (additive).
# Returns the map_data.json top-level `modifiers` array (a list of op dicts;
# see doc/BRACELET_GARDEN_MODIFIERS.md). Empty array if the key is absent —
# existing maps without modifiers are unaffected.
func get_modifiers() -> Array:
	if json_loader and json_loader.map_data is Dictionary:
		var mods = json_loader.map_data.get("modifiers", [])
		if mods is Array:
			return mods
	return []

# Get current map name
func get_current_map_name() -> String:
	return map_name

# Get map name from loaded data (for display)
func get_map_name() -> String:
	if json_loader:
		return json_loader.get_map_name()
	return map_name

# Get map description from loaded data
func get_description() -> String:
	if json_loader:
		return json_loader.get_map_description()
	return ""

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
