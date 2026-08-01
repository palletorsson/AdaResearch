@tool
class_name ElementSubsetData
extends RefCounted
## Loads and provides access to element subset definitions from JSON files.

const SUBSET_DIR = "res://tools/grid_editor/subsets/"
const SUBSET_FILES = [
	"audio_rack.json",
	"glass_rack.json",
	"big_pipes.json",
	"lab_items_horizontal.json",
	"facade_elements.json"
]

var subsets: Dictionary = {}  # id -> subset data
var _loaded := false


func load_all() -> void:
	"""Load all subset JSON files."""
	if _loaded:
		print("[ElementSubsetData] Already loaded, subsets: ", subsets.keys())
		return
	
	print("[ElementSubsetData] Loading subsets from: ", SUBSET_DIR)
	for filename in SUBSET_FILES:
		var path = SUBSET_DIR + filename
		print("[ElementSubsetData] Trying to load: ", path)
		var data = _load_json(path)
		if data and data.has("id"):
			subsets[data.id] = data
			print("[ElementSubsetData] Loaded subset: ", data.id, " with ", data.get("elements", []).size(), " elements")
		else:
			print("[ElementSubsetData] FAILED to load: ", path)
	
	_loaded = true
	print("[ElementSubsetData] Final subsets: ", subsets.keys())


func _load_json(path: String) -> Dictionary:
	"""Load a JSON file and return its contents."""
	if not FileAccess.file_exists(path):
		push_warning("[ElementSubsetData] File not found: " + path)
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("[ElementSubsetData] Cannot open: " + path)
		return {}
	
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		push_warning("[ElementSubsetData] JSON parse error in " + path + ": " + json.get_error_message())
		return {}
	
	return json.data


func get_subset(id: String) -> Dictionary:
	"""Get a subset by ID."""
	load_all()
	return subsets.get(id, {})


func get_subset_ids() -> Array:
	"""Get all loaded subset IDs."""
	load_all()
	return subsets.keys()


func get_element(subset_id: String, element_id: String) -> Dictionary:
	"""Get a specific element from a subset."""
	var subset = get_subset(subset_id)
	if subset.is_empty():
		return {}
	
	for element in subset.get("elements", []):
		if element.get("id") == element_id:
			return element
	return {}


func get_elements_by_category(subset_id: String, category_id: String) -> Array:
	"""Get all elements in a category."""
	var subset = get_subset(subset_id)
	if subset.is_empty():
		return []
	
	var result = []
	for element in subset.get("elements", []):
		if element.get("category") == category_id:
			result.append(element)
	return result


func get_categories(subset_id: String) -> Array:
	"""Get all categories for a subset."""
	var subset = get_subset(subset_id)
	return subset.get("categories", [])


func get_grid_size(subset_id: String) -> float:
	"""Get the grid size for a subset."""
	var subset = get_subset(subset_id)
	var orientation = subset.get("orientation", {})
	return orientation.get("grid_size", 0.1)


func get_orientation_plane(subset_id: String) -> String:
	"""Get the orientation plane for a subset (XY, YZ, XZ)."""
	var subset = get_subset(subset_id)
	var orientation = subset.get("orientation", {})
	return orientation.get("plane", "XY")


func get_element_world_size(subset_id: String, element_id: String) -> Vector3:
	"""Get the world size of an element in meters."""
	var subset = get_subset(subset_id)
	var element = get_element(subset_id, element_id)
	if element.is_empty():
		return Vector3.ONE
	
	var grid_size = get_grid_size(subset_id)
	var size = element.get("size", [1, 1])
	var plane = get_orientation_plane(subset_id)
	
	match plane:
		"XY":  # width, height on wall
			return Vector3(size[0] * grid_size, size[1] * grid_size, 0.1)
		"YZ":  # side view
			return Vector3(0.1, size[1] * grid_size, size[0] * grid_size)
		"XZ":  # top down
			return Vector3(size[0] * grid_size, 0.1, size[1] * grid_size)
	
	return Vector3(size[0] * grid_size, size[1] * grid_size, 0.1)


func get_audio_config(subset_id: String) -> Dictionary:
	"""Get audio configuration for a subset."""
	var subset = get_subset(subset_id)
	return subset.get("audio", {})


func has_audio_support(subset_id: String) -> bool:
	"""Check if a subset has audio controller support."""
	var audio = get_audio_config(subset_id)
	return not audio.is_empty()


func get_element_control(subset_id: String, element_id: String) -> Dictionary:
	"""Get control configuration for an element."""
	var element = get_element(subset_id, element_id)
	return element.get("control", {})


func get_element_display(subset_id: String, element_id: String) -> Dictionary:
	"""Get display configuration for an element."""
	var element = get_element(subset_id, element_id)
	return element.get("display", {})


func is_control_element(subset_id: String, element_id: String) -> bool:
	"""Check if element is a control (slider, knob, button)."""
	var element = get_element(subset_id, element_id)
	return element.has("control")


func is_display_element(subset_id: String, element_id: String) -> bool:
	"""Check if element is a display (waveform, spectrum, meter)."""
	var element = get_element(subset_id, element_id)
	return element.has("display")


func get_elements_with_parameter(subset_id: String, param_name: String) -> Array:
	"""Get all elements that control or bind to a specific parameter."""
	var result = []
	var subset = get_subset(subset_id)
	if subset.is_empty():
		return result
	
	for element in subset.get("elements", []):
		# Check control parameter
		var control = element.get("control", {})
		if control.get("parameter", "") == param_name:
			result.append(element)
			continue
		
		# Check display bindings
		var display = element.get("display", {})
		if display.get("freq_param", "") == param_name:
			result.append(element)
		elif display.get("amp_param", "") == param_name:
			result.append(element)
	
	return result


func get_all_parameters(subset_id: String) -> Array:
	"""Get all unique parameter names used in a subset."""
	var params = {}
	var subset = get_subset(subset_id)
	if subset.is_empty():
		return []
	
	for element in subset.get("elements", []):
		var control = element.get("control", {})
		var param = control.get("parameter", "")
		if param != "":
			params[param] = true
	
	return params.keys()
