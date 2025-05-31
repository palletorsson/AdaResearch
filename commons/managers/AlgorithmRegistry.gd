extends Node

class_name AlgorithmRegistry

# Path to the JSON file containing algorithm definitions
const ALGORITHM_DATA_PATH = "res://adaresearch/Common/Data/algorithms.json"

# Main registry of algorithms
var algorithms: Dictionary = {}

# Cache of loaded scenes
var _loaded_scenes: Dictionary = {}

# Signal emitted when the registry is fully loaded
signal registry_loaded

func _ready():
	# Load the algorithm data on startup
	load_algorithm_data()

# Load algorithm data from JSON file
func load_algorithm_data() -> void:
	algorithms.clear()
	_loaded_scenes.clear()
	
	var file = FileAccess.open(ALGORITHM_DATA_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open algorithm data file: %s" % ALGORITHM_DATA_PATH)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("Failed to parse algorithm data JSON: %s at line %d" % [json.get_error_message(), json.get_error_line()])
		return
	
	var data = json.get_data()
	if not data is Dictionary:
		push_error("Algorithm data JSON does not contain a root object")
		return
	
	if not data.has("algorithms") or not data["algorithms"] is Array:
		push_error("Algorithm data JSON missing 'algorithms' array")
		return
	
	# Process each algorithm entry
	for algorithm in data["algorithms"]:
		if not algorithm is Dictionary:
			push_warning("Skipping invalid algorithm entry (not a Dictionary)")
			continue
		
		if not algorithm.has("id") or not algorithm.has("scene_path"):
			push_warning("Skipping algorithm entry missing required fields")
			continue
		
		var id = str(algorithm["id"])
		algorithms[id] = algorithm
	
	print("Loaded %d algorithm definitions from %s" % [algorithms.size(), ALGORITHM_DATA_PATH])
	emit_signal("registry_loaded")

# Get an algorithm's metadata by ID
func get_algorithm(id: String) -> Dictionary:
	if algorithms.has(id):
		return algorithms[id]
	return {}

# Get an algorithm's scene instance by ID
func get_algorithm_scene(id: String) -> Node:
	# Return from cache if already loaded
	if _loaded_scenes.has(id) and is_instance_valid(_loaded_scenes[id]):
		return _loaded_scenes[id]
	
	# Try to load the scene
	if algorithms.has(id):
		var algorithm = algorithms[id]
		if algorithm.has("scene_path"):
			var scene_path = algorithm["scene_path"]
			if ResourceLoader.exists(scene_path):
				var scene_resource = load(scene_path)
				if scene_resource is PackedScene:
					var instance = scene_resource.instantiate()
					
					# Store in cache
					_loaded_scenes[id] = instance
					
					# Add metadata to the instance
					if instance.has_method("set_algorithm_metadata"):
						instance.set_algorithm_metadata(algorithm)
					else:
						# Add basic properties directly
						instance.set("algorithm_id", id)
						instance.set("algorithm_name", algorithm.get("name", "Unknown Algorithm"))
						
					return instance
	
	push_warning("Failed to load algorithm scene with ID: %s" % id)
	return null

# Get an array of all algorithm IDs
func get_all_algorithm_ids() -> Array:
	return algorithms.keys()

# Get an array of algorithm IDs filtered by category
func get_algorithm_ids_by_category(category: String) -> Array:
	var result = []
	for id in algorithms.keys():
		var algorithm = algorithms[id]
		if algorithm.has("category") and algorithm["category"] == category:
			result.append(id)
	return result

# Get all available categories
func get_all_categories() -> Array:
	var categories = {}
	for id in algorithms.keys():
		var algorithm = algorithms[id]
		if algorithm.has("category"):
			categories[algorithm["category"]] = true
	return categories.keys()
