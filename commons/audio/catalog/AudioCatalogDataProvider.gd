# AudioCatalogDataProvider.gd
# Provides a catalog of all audio presets from commons/audio/parameters/
# Scans directories recursively, parses JSON files, caches results

class_name AudioCatalogDataProvider
extends RefCounted

# Cached catalog data
static var _catalog: Dictionary = {}  # sound_key -> entry
static var _categories: Array[String] = []
static var _loaded: bool = false

# Supported JSON formats
enum JsonFormat {
	ROOT_METADATA,    # {_metadata: {...}, parameters: {...}}
	NESTED_METADATA,  # {sound_key: {_metadata: {...}, ...}}
	DIRECT            # {param1: {...}, param2: {...}}
}

const PARAMETERS_PATH := "res://commons/audio/parameters/"

# Entry structure
# {
#   id: String,
#   sound_key: String,
#   display_name: String,
#   category: String,
#   file_path: String,
#   metadata: Dictionary,
#   parameters: Dictionary,
#   format: JsonFormat
# }


static func load_catalog() -> void:
	if _loaded:
		return

	_catalog.clear()
	_categories.clear()

	_scan_directory(PARAMETERS_PATH, "")

	# Sort categories alphabetically
	_categories.sort()
	_loaded = true


static func reload_catalog() -> void:
	_loaded = false
	load_catalog()


static func _scan_directory(path: String, category: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		push_warning("AudioCatalogDataProvider: Could not open directory: " + path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with("."):
			# Recurse into subdirectory
			var sub_category := file_name if category.is_empty() else category + "/" + file_name
			_scan_directory(path + file_name + "/", sub_category)
		elif file_name.ends_with(".json"):
			# Parse JSON file
			_load_json_file(path + file_name, category)

		file_name = dir.get_next()

	dir.list_dir_end()


static func _load_json_file(file_path: String, category: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning("AudioCatalogDataProvider: Could not open file: " + file_path)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_warning("AudioCatalogDataProvider: JSON parse error in " + file_path + ": " + json.get_error_message())
		return

	var data: Dictionary = json.data
	if data.is_empty():
		return

	# Detect format and extract entry
	var entry := _parse_entry(data, file_path, category)
	if entry.is_empty():
		return

	# Add to catalog
	var sound_key: String = entry.sound_key
	_catalog[sound_key] = entry

	# Track category
	var cat: String = entry.category
	if not cat.is_empty() and not _categories.has(cat):
		_categories.append(cat)


static func _parse_entry(data: Dictionary, file_path: String, category: String) -> Dictionary:
	var entry := {}
	var format := JsonFormat.DIRECT
	var metadata := {}
	var parameters := {}
	var sound_key := ""

	# Format detection
	if data.has("_metadata") and data.has("parameters"):
		# ROOT_METADATA format
		format = JsonFormat.ROOT_METADATA
		metadata = data.get("_metadata", {})
		parameters = data.get("parameters", {})
		sound_key = metadata.get("sound_type", _file_to_key(file_path))
	elif data.size() == 1:
		# NESTED_METADATA format - data wrapped in sound key
		var first_key: String = data.keys()[0]
		var nested: Dictionary = data.get(first_key, {})
		if nested.has("_metadata") or nested.has("parameters"):
			format = JsonFormat.NESTED_METADATA
			metadata = nested.get("_metadata", {})
			parameters = nested.get("parameters", nested)
			sound_key = first_key

	if format == JsonFormat.DIRECT:
		# DIRECT format - plain parameters
		parameters = data
		# Remove _metadata if present
		if parameters.has("_metadata"):
			metadata = parameters.get("_metadata", {})
			parameters = parameters.duplicate()
			parameters.erase("_metadata")
		sound_key = metadata.get("sound_type", _file_to_key(file_path))

	if sound_key.is_empty():
		return {}

	# Build entry
	entry = {
		"id": file_path,
		"sound_key": sound_key,
		"display_name": _key_to_display(sound_key),
		"category": category.split("/")[0] if not category.is_empty() else "uncategorized",
		"subcategory": category,
		"file_path": file_path,
		"metadata": metadata,
		"parameters": parameters,
		"format": format
	}

	return entry


static func _file_to_key(file_path: String) -> String:
	var file_name := file_path.get_file().get_basename()
	return file_name


static func _key_to_display(key: String) -> String:
	# Convert snake_case to Title Case
	var words := key.replace("_", " ").split(" ")
	var display := ""
	for word in words:
		if not word.is_empty():
			display += word.capitalize() + " "
	return display.strip_edges()


# Public API

static func get_all_sounds() -> Array[Dictionary]:
	load_catalog()
	var sounds: Array[Dictionary] = []
	for key in _catalog:
		sounds.append(_catalog[key])
	return sounds


static func get_categories() -> Array[String]:
	load_catalog()
	return _categories.duplicate()


static func get_sounds_by_category(category: String) -> Array[Dictionary]:
	load_catalog()
	var sounds: Array[Dictionary] = []
	for key in _catalog:
		var entry: Dictionary = _catalog[key]
		if entry.category == category:
			sounds.append(entry)
	# Sort by display name
	sounds.sort_custom(func(a, b): return a.display_name < b.display_name)
	return sounds


static func get_sound(sound_key: String) -> Dictionary:
	load_catalog()
	return _catalog.get(sound_key, {})


static func search_sounds(query: String) -> Array[Dictionary]:
	load_catalog()
	var results: Array[Dictionary] = []
	var q := query.to_lower()

	for key in _catalog:
		var entry: Dictionary = _catalog[key]
		var search_blob: String = str(entry.sound_key) + " " + str(entry.display_name) + " " + str(entry.category) + " " + str(entry.metadata.get("description", "")) + " " + str(entry.metadata.get("tags", ""))
		search_blob = search_blob.to_lower()

		if search_blob.contains(q):
			results.append(entry)

	return results


static func get_sound_count() -> int:
	load_catalog()
	return _catalog.size()


static func get_category_count() -> int:
	load_catalog()
	return _categories.size()


static func save_sound_parameters(sound_key: String, new_values: Dictionary) -> bool:
	load_catalog()
	if not _catalog.has(sound_key):
		push_warning("AudioCatalogDataProvider: Sound not found: " + sound_key)
		return false

	var entry: Dictionary = _catalog[sound_key]
	var file_path: String = entry.get("file_path", "")
	if file_path.is_empty() or not FileAccess.file_exists(file_path):
		push_warning("AudioCatalogDataProvider: File not found: " + file_path)
		return false

	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning("AudioCatalogDataProvider: Could not open file: " + file_path)
		return false
	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_warning("AudioCatalogDataProvider: JSON parse error in " + file_path + ": " + json.get_error_message())
		return false

	var data: Dictionary = json.data
	if data.is_empty():
		return false

	var format: int = entry.get("format", JsonFormat.DIRECT)
	match format:
		JsonFormat.ROOT_METADATA:
			var params_root: Dictionary = data.get("parameters", {})
			_apply_values(params_root, new_values)
			data["parameters"] = params_root
		JsonFormat.NESTED_METADATA:
			var nested_key := sound_key
			if not data.has(nested_key):
				var keys := data.keys()
				if keys.size() == 0:
					return false
				nested_key = keys[0]
			var nested: Dictionary = data.get(nested_key, {})
			var params_nested: Dictionary = nested.get("parameters", nested)
			_apply_values(params_nested, new_values)
			nested["parameters"] = params_nested
			data[nested_key] = nested
		_:
			_apply_values(data, new_values)

	var write_file := FileAccess.open(file_path, FileAccess.WRITE)
	if not write_file:
		push_warning("AudioCatalogDataProvider: Could not write file: " + file_path)
		return false
	write_file.store_string(JSON.stringify(data, "\t"))
	write_file.close()

	# Update cached entry parameters
	var updated_params: Dictionary = entry.get("parameters", {}).duplicate(true)
	_apply_values(updated_params, new_values)
	entry["parameters"] = updated_params
	_catalog[sound_key] = entry

	return true


static func _apply_values(target: Dictionary, new_values: Dictionary) -> void:
	for key in new_values.keys():
		if target.has(key):
			var entry = target[key]
			if entry is Dictionary and entry.has("value"):
				entry["value"] = new_values[key]
				target[key] = entry
			else:
				target[key] = new_values[key]
		else:
			target[key] = new_values[key]
