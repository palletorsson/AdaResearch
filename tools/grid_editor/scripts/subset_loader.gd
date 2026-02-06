extends Node
class_name GridEditorSubsetLoader
## SubsetLoader - Manages subset definitions for Grid Editor
## Loads and caches all subset JSON files

signal subsets_loaded
signal subset_changed(subset_id: String)

var subsets: Dictionary = {}  # id -> Dictionary (parsed JSON)
var current_subset_id: String = ""
var current_subset: Dictionary:
	get:
		return subsets.get(current_subset_id, {})

func _ready() -> void:
	load_all_subsets()

func load_all_subsets() -> void:
	subsets.clear()
	
	var dir = DirAccess.open("res://tools/grid_editor/subsets")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var subset = _load_subset_file("res://tools/grid_editor/subsets/" + file_name)
				if subset and subset.has("id"):
					subsets[subset.id] = subset
					print("Loaded subset: ", subset.id)
			file_name = dir.get_next()
	
	subsets_loaded.emit()
	
	# Set default subset
	if subsets.size() > 0 and current_subset_id == "":
		set_current_subset(subsets.keys()[0])

func _load_subset_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Subset file not found: ", path)
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("Failed to parse subset: ", path, " - ", json.get_error_message())
		return {}
	
	return json.data

func set_current_subset(subset_id: String) -> void:
	if subsets.has(subset_id):
		current_subset_id = subset_id
		subset_changed.emit(subset_id)

func get_subset(id: String) -> Dictionary:
	return subsets.get(id, {})

func get_subset_ids() -> Array:
	return subsets.keys()

func get_subset_names() -> Dictionary:
	var names = {}
	for id in subsets:
		names[id] = subsets[id].get("name", id)
	return names

# Element access
func get_element(element_id: String, subset_id: String = "") -> Dictionary:
	var subset = subsets.get(subset_id if subset_id else current_subset_id, {})
	var elements = subset.get("elements", [])
	for element in elements:
		if element.get("id") == element_id:
			return element
	return {}

func get_elements_by_category(category_id: String, subset_id: String = "") -> Array:
	var subset = subsets.get(subset_id if subset_id else current_subset_id, {})
	var elements = subset.get("elements", [])
	var result = []
	for element in elements:
		if element.get("category") == category_id:
			result.append(element)
	return result

func get_categories(subset_id: String = "") -> Array:
	var subset = subsets.get(subset_id if subset_id else current_subset_id, {})
	return subset.get("categories", [])

# Orientation helpers
func get_orientation(subset_id: String = "") -> Dictionary:
	var subset = subsets.get(subset_id if subset_id else current_subset_id, {})
	return subset.get("orientation", {
		"plane": "XZ",
		"up_axis": "Y",
		"forward": "+Z",
		"grid_size": 1.0
	})

func get_grid_size(subset_id: String = "") -> float:
	var orientation = get_orientation(subset_id)
	return orientation.get("grid_size", 1.0)
