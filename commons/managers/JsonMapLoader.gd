# JsonMapLoader.gd
# Loads map data from JSON format files
# Provides compatibility layer between JSON maps and existing GDScript-based grid system

extends RefCounted
class_name JsonMapLoader

# Loaded map data
var map_data: Dictionary = {}
var is_loaded: bool = false

# Compatibility instances that mimic the GDScript data structure
var structure_data_instance
var utility_data_instance 
var interactable_data_instance
var task_data_instance

# Load JSON map file
func load_map(map_path: String) -> bool:
	var file = FileAccess.open(map_path, FileAccess.READ)
	if not file:
		push_error("JsonMapLoader: Could not open map file: %s" % map_path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("JsonMapLoader: Failed to parse JSON: %s" % json.error_string)
		return false
	
	map_data = json.data
	is_loaded = true
	
	# Create compatibility instances
	_create_compatibility_instances()
	
	print("JsonMapLoader: Successfully loaded map '%s'" % get_map_name())
	return true

# Create compatibility instances that mimic GDScript data files
func _create_compatibility_instances() -> void:
	# Structure data compatibility
	structure_data_instance = JsonStructureDataAdapter.new()
	structure_data_instance.layout_data = map_data.get("layers", {}).get("structure", [])
	
	# Utility data compatibility
	utility_data_instance = JsonUtilityDataAdapter.new()
	utility_data_instance.layout_data = map_data.get("layers", {}).get("utilities", [])
	utility_data_instance.map_name = get_map_name()
	utility_data_instance.description = get_map_description()
	
	# Interactable data compatibility
	interactable_data_instance = JsonInteractableDataAdapter.new()
	interactable_data_instance.interactable_data = map_data.get("layers", {}).get("interactables", [])
	
	# Task data compatibility
	task_data_instance = JsonTaskDataAdapter.new()
	task_data_instance.task_data = map_data.get("layers", {}).get("tasks", [])

# Get map information
func get_map_name() -> String:
	return map_data.get("map_info", {}).get("name", "unknown")

func get_map_description() -> String:
	return map_data.get("map_info", {}).get("description", "")

func get_map_version() -> String:
	return map_data.get("map_info", {}).get("version", "1.0")

func get_dimensions() -> Dictionary:
	return map_data.get("map_info", {}).get("dimensions", {"width": 0, "depth": 0, "max_height": 6})

func get_metadata() -> Dictionary:
	return map_data.get("map_info", {}).get("metadata", {})

# Get layer data
func get_structure_layer() -> Array:
	return map_data.get("layers", {}).get("structure", [])

func get_utilities_layer() -> Array:
	return map_data.get("layers", {}).get("utilities", [])

func get_interactables_layer() -> Array:
	return map_data.get("layers", {}).get("interactables", [])

func get_tasks_layer() -> Array:
	return map_data.get("layers", {}).get("tasks", [])

# Get definitions
func get_utility_definitions() -> Dictionary:
	return map_data.get("utility_definitions", {})

func get_task_definitions() -> Dictionary:
	return map_data.get("task_definitions", {})

# Get spawn points
func get_spawn_points() -> Dictionary:
	return map_data.get("spawn_points", {})

func get_default_spawn_point() -> Dictionary:
	var spawn_points = get_spawn_points()
	return spawn_points.get("default", {"position": [0, 0, 0], "rotation": [0, 0, 0]})

# Get lighting settings
func get_lighting_settings() -> Dictionary:
	return map_data.get("lighting", {})

# Get general settings
func get_settings() -> Dictionary:
	return map_data.get("settings", {})

func get_cube_size() -> float:
	return get_settings().get("cube_size", 1.0)

func get_gutter() -> float:
	return get_settings().get("gutter", 0.0)

func is_grid_visible() -> bool:
	return get_settings().get("show_grid", false)

# Validation
func validate() -> Dictionary:
	var validation = {
		"valid": true,
		"errors": [],
		"warnings": []
	}
	
	if not is_loaded:
		validation.valid = false
		validation.errors.append("Map not loaded")
		return validation
	
	# Check required sections
	var required_sections = ["map_info", "layers"]
	for section in required_sections:
		if not map_data.has(section):
			validation.valid = false
			validation.errors.append("Missing required section: %s" % section)
	
	# Check map_info required fields
	var map_info = map_data.get("map_info", {})
	var required_map_fields = ["name", "description", "version"]
	for field in required_map_fields:
		if not map_info.has(field):
			validation.warnings.append("Missing recommended map_info field: %s" % field)
	
	# Validate dimensions consistency
	var dimensions = get_dimensions()
	var structure = get_structure_layer()
	
	if structure.size() > 0:
		if structure.size() != dimensions.get("depth", 0):
			validation.warnings.append("Structure depth (%d) doesn't match declared depth (%d)" % [structure.size(), dimensions.depth])
		
		var max_width = 0
		for row in structure:
			if row.size() > max_width:
				max_width = row.size()
		
		if max_width != dimensions.get("width", 0):
			validation.warnings.append("Structure width (%d) doesn't match declared width (%d)" % [max_width, dimensions.width])
	
	# Validate utility data if utility layer exists
	var utilities = get_utilities_layer()
	if utilities.size() > 0:
		var utility_validation = UtilityRegistry.validate_utility_grid(utilities)
		if not utility_validation.valid:
			validation.valid = false
			validation.errors.append_array(utility_validation.errors)
			validation.warnings.append_array(utility_validation.warnings)
	
	return validation

# Generate map report
func generate_report() -> String:
	if not is_loaded:
		return "Map not loaded"
	
	var report = []
	report.append("=== JSON Map Report ===")
	report.append("Name: %s" % get_map_name())
	report.append("Description: %s" % get_map_description())
	report.append("Version: %s" % get_map_version())
	
	var dims = get_dimensions()
	report.append("Dimensions: %dx%dx%d" % [dims.width, dims.depth, dims.max_height])
	
	var metadata = get_metadata()
	if metadata.has("difficulty"):
		report.append("Difficulty: %s" % metadata.difficulty)
	if metadata.has("category"):
		report.append("Category: %s" % metadata.category)
	
	# Layer analysis
	report.append("\n--- Layer Analysis ---")
	report.append("Structure layer: %d rows" % get_structure_layer().size())
	report.append("Utilities layer: %d rows" % get_utilities_layer().size())
	report.append("Interactables layer: %d rows" % get_interactables_layer().size())
	report.append("Tasks layer: %d rows" % get_tasks_layer().size())
	
	# Utility analysis
	var utility_definitions = get_utility_definitions()
	if utility_definitions.size() > 0:
		report.append("\n--- Utilities Used ---")
		for code in utility_definitions.keys():
			var def = utility_definitions[code]
			report.append("%s: %s (%s)" % [code, def.get("name", "unknown"), def.get("category", "unknown")])
	
	# Task analysis
	var task_definitions = get_task_definitions()
	if task_definitions.size() > 0:
		report.append("\n--- Tasks Defined ---")
		for task_id in task_definitions.keys():
			var def = task_definitions[task_id]
			report.append("%s: %s" % [task_id, def.get("name", "unknown")])
	
	# Validation
	var validation = validate()
	report.append("\n--- Validation ---")
	report.append("Valid: %s" % ("✅" if validation.valid else "❌"))
	if validation.errors.size() > 0:
		report.append("Errors: %d" % validation.errors.size())
		for error in validation.errors:
			report.append("  - %s" % error)
	if validation.warnings.size() > 0:
		report.append("Warnings: %d" % validation.warnings.size())
		for warning in validation.warnings:
			report.append("  - %s" % warning)
	
	return "\n".join(report)

# Static helper to check if a file is a JSON map
static func is_json_map_file(file_path: String) -> bool:
	return file_path.ends_with(".json") and FileAccess.file_exists(file_path)

# Static loader for convenience
static func load_json_map(file_path: String) -> JsonMapLoader:
	var loader = JsonMapLoader.new()
	if loader.load_map(file_path):
		return loader
	else:
		return null

# Compatibility adapter classes
class JsonStructureDataAdapter extends RefCounted:
	var layout_data: Array = []

class JsonUtilityDataAdapter extends UtilityDataTemplate:
	pass

class JsonInteractableDataAdapter extends RefCounted:
	var interactable_data: Array = []

class JsonTaskDataAdapter extends RefCounted:
	var task_data: Array = [] 
