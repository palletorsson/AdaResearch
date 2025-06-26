# EnhancedParameterLoader.gd
# Enhanced parameter loader that searches all categorized parameter folders

extends RefCounted
class_name EnhancedParameterLoader

# All parameter directory categories
const PARAMETER_CATEGORIES = [
	"basic",
	"drums", 
	"synthesizers",
	"retro",
	"experimental",
	"ambient"
]

static var cached_parameters: Dictionary = {}
static var is_initialized: bool = false

# Load parameters from all categories
static func load_all_parameters() -> Dictionary:
	if is_initialized and cached_parameters.size() > 0:
		return cached_parameters
	
	print("🔄 Loading parameters from all categories...")
	cached_parameters.clear()
	
	var base_path = "res://commons/audio/parameters/"
	
	for category in PARAMETER_CATEGORIES:
		var category_path = base_path + category + "/"
		load_parameters_from_directory(category_path, category)
	
	is_initialized = true
	print("✅ Loaded %d sound parameter sets" % cached_parameters.size())
	return cached_parameters

# Load parameters from a specific directory
static func load_parameters_from_directory(dir_path: String, category: String):
	var dir = DirAccess.open(dir_path)
	if not dir:
		print("⚠️ Cannot access directory: %s" % dir_path)
		return
	
	print("📂 Loading from %s category..." % category)
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var count = 0
	
	while file_name != "":
		if file_name.ends_with(".json"):
			var full_path = dir_path + file_name
			var sound_key = file_name.get_basename()
			
			var params = load_json_parameters(full_path)
			if params.size() > 0:
				cached_parameters[sound_key] = params
				count += 1
				print("  ✅ %s" % sound_key)
			else:
				print("  ❌ Failed to load %s" % sound_key)
		
		file_name = dir.get_next()
	
	print("📊 Loaded %d parameters from %s category" % [count, category])

# Load a single JSON parameter file
static func load_json_parameters(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("❌ JSON parse error in %s" % file_path)
		return {}
	
	var data = json.data
	
	# Handle different JSON structures
	# Format 1: { "_metadata": {...}, "parameters": {...} }
	if data.has("parameters") and data.has("_metadata"):
		return data["parameters"]
	
	# Format 2: { "sound_name": { "_metadata": {...}, "parameters": {...} } }
	for key in data.keys():
		if not key.begins_with("_"):  # Skip metadata keys
			var sound_data = data[key]
			if sound_data is Dictionary and sound_data.has("parameters"):
				return sound_data["parameters"]
	
	# Format 3: Direct parameter format (fallback)
	# { "param1": {"value": ..., "min": ...}, "param2": {...} }
	var has_param_structure = false
	for key in data.keys():
		if data[key] is Dictionary and data[key].has("value"):
			has_param_structure = true
			break
	
	if has_param_structure:
		return data
	
	# No valid format found
	print("⚠️ Unknown JSON format in %s" % file_path)
	return {}

# Get parameters for a specific sound
static func get_sound_parameters(sound_key: String) -> Dictionary:
	if not is_initialized:
		load_all_parameters()
	
	return cached_parameters.get(sound_key, {})

# Get all available sound keys
static func get_available_sounds() -> Array:
	if not is_initialized:
		load_all_parameters()
	
	return cached_parameters.keys()

# Find which category a sound belongs to
static func find_sound_category(sound_key: String) -> String:
	var base_path = "res://commons/audio/parameters/"
	
	for category in PARAMETER_CATEGORIES:
		var file_path = base_path + category + "/" + sound_key + ".json"
		if FileAccess.file_exists(file_path):
			return category
	
	return "unknown"

# Get all sounds from a specific category
static func get_sounds_by_category(category: String) -> Array:
	if not is_initialized:
		load_all_parameters()
	
	var sounds = []
	var base_path = "res://commons/audio/parameters/" + category + "/"
	var dir = DirAccess.open(base_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".json"):
				var sound_key = file_name.get_basename()
				if cached_parameters.has(sound_key):
					sounds.append(sound_key)
			file_name = dir.get_next()
	
	return sounds

# Refresh the parameter cache
static func refresh_parameters():
	cached_parameters.clear()
	is_initialized = false
	load_all_parameters() 