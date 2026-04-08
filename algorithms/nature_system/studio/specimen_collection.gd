# SpecimenCollection.gd — Persistent library of player's collected DNA specimens
#
# Saves and loads CritterDNA as JSON files for the Pokemon Studio.
# JSON format chosen over .tres so the web editor can read/write directly.
#
# Stored at: user://pokemon_studio/specimens/<id>.json
#
# Usage:
#   var collection := SpecimenCollection.new()
#   var id: String = collection.add(my_dna, "Blue Oak")
#   var dna: CritterDNA = collection.get_dna(id)
#   collection.save_all()

class_name SpecimenCollection
extends RefCounted

## Maximum number of specimens the collection can hold.
const MAX_SPECIMENS: int = 200

## Base directory for specimen storage.
const STORAGE_DIR: String = "user://pokemon_studio/specimens/"

## Index file listing all specimens.
const INDEX_FILE: String = "user://pokemon_studio/collection.json"


# ─────────────────────────────────────────────────────────────
#  Runtime state
# ─────────────────────────────────────────────────────────────

## All specimens. Key: id (String), Value: Dictionary with metadata + DNA.
var _specimens: Dictionary = {}

## Auto-increment counter for IDs.
var _next_id: int = 1

## Whether anything changed since last save.
var _dirty: bool = false


# ═══════════════════════════════════════════════════════════════
# INITIALIZATION
# ═══════════════════════════════════════════════════════════════

func _init() -> void:
	_ensure_directory()
	load_all()


## Create the storage directory if it doesn't exist.
func _ensure_directory() -> void:
	DirAccess.make_dir_recursive_absolute(STORAGE_DIR)


# ═══════════════════════════════════════════════════════════════
# ADD / REMOVE
# ═══════════════════════════════════════════════════════════════

## Add a new specimen to the collection. Returns its ID.
## Returns empty string if at capacity.
func add(dna: CritterDNA, display_name: String = "") -> String:
	if _specimens.size() >= MAX_SPECIMENS:
		push_warning("[SpecimenCollection] At capacity (%d), cannot add" % MAX_SPECIMENS)
		return ""

	var id: String = "specimen_%04d" % _next_id
	_next_id += 1

	var auto_name: String = display_name
	if auto_name.is_empty():
		auto_name = "%s_%d" % [dna.get_kingdom_name(), dna.generation]

	_specimens[id] = {
		"id": id,
		"name": auto_name,
		"kingdom": dna.get_kingdom_name(),
		"body_type": dna.body_type,
		"generation": dna.generation,
		"parent_a_id": dna.parent_a_id,
		"parent_b_id": dna.parent_b_id,
		"hybridity": dna.get_hybridity(),
		"created_at": Time.get_datetime_string_from_system(),
		"released": false,
		"dna": _dna_to_json_dict(dna),
	}

	_dirty = true
	return id


## Remove a specimen by ID. Returns true if found and removed.
func remove(id: String) -> bool:
	if id not in _specimens:
		return false
	_specimens.erase(id)
	_dirty = true

	# Remove the individual file too
	var path: String = STORAGE_DIR + id + ".json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	return true


## Mark a specimen as released (cannot be used for lab breeding anymore).
func mark_released(id: String) -> void:
	if id in _specimens:
		(_specimens[id] as Dictionary)["released"] = true
		_dirty = true


# ═══════════════════════════════════════════════════════════════
# QUERIES
# ═══════════════════════════════════════════════════════════════

## Get the CritterDNA for a specimen. Returns null if not found.
func get_dna(id: String) -> CritterDNA:
	if id not in _specimens:
		return null
	var data: Dictionary = _specimens[id] as Dictionary
	return _json_dict_to_dna(data["dna"] as Dictionary)


## Get metadata for a specimen (without creating a full DNA object).
func get_metadata(id: String) -> Dictionary:
	if id not in _specimens:
		return {}
	var data: Dictionary = (_specimens[id] as Dictionary).duplicate()
	data.erase("dna")  # Don't include full DNA in metadata
	return data


## List all specimen IDs.
func list_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in _specimens:
		ids.append(key as String)
	return ids


## List all specimen metadata (without DNA data).
func list_all() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in _specimens:
		var meta: Dictionary = (_specimens[key] as Dictionary).duplicate()
		meta.erase("dna")
		result.append(meta)
	return result


## Get specimens filtered by kingdom.
func get_by_kingdom(kingdom_name: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in _specimens:
		var data: Dictionary = _specimens[key] as Dictionary
		if data["kingdom"] == kingdom_name:
			var meta: Dictionary = data.duplicate()
			meta.erase("dna")
			result.append(meta)
	return result


## Get specimens within a generation range (inclusive).
func get_by_generation_range(min_gen: int, max_gen: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in _specimens:
		var data: Dictionary = _specimens[key] as Dictionary
		var gen: int = data["generation"] as int
		if gen >= min_gen and gen <= max_gen:
			var meta: Dictionary = data.duplicate()
			meta.erase("dna")
			result.append(meta)
	return result


## Get only unreleased specimens (available for lab work).
func get_available() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in _specimens:
		var data: Dictionary = _specimens[key] as Dictionary
		if not (data["released"] as bool):
			var meta: Dictionary = data.duplicate()
			meta.erase("dna")
			result.append(meta)
	return result


## How many specimens are stored.
func get_count() -> int:
	return _specimens.size()


## How many slots remain.
func get_remaining_capacity() -> int:
	return MAX_SPECIMENS - _specimens.size()


# ═══════════════════════════════════════════════════════════════
# PERSISTENCE
# ═══════════════════════════════════════════════════════════════

## Save all specimens to disk.
func save_all() -> void:
	_ensure_directory()

	# Save each specimen as an individual JSON file
	for id in _specimens:
		var path: String = STORAGE_DIR + (id as String) + ".json"
		var json_str: String = JSON.stringify(_specimens[id], "\t")
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(json_str)
			file.close()

	# Save the index
	_save_index()
	_dirty = false


## Load all specimens from disk.
func load_all() -> void:
	_specimens.clear()
	_next_id = 1

	if not DirAccess.dir_exists_absolute(STORAGE_DIR):
		return

	var dir := DirAccess.open(STORAGE_DIR)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var path: String = STORAGE_DIR + file_name
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				var json_str: String = file.get_as_text()
				file.close()
				var parsed = JSON.parse_string(json_str)
				if parsed is Dictionary:
					var data: Dictionary = parsed as Dictionary
					var id: String = data.get("id", "") as String
					if not id.is_empty():
						_specimens[id] = data
						# Update next ID counter
						var num_part: String = id.trim_prefix("specimen_")
						if num_part.is_valid_int():
							_next_id = maxi(_next_id, num_part.to_int() + 1)
		file_name = dir.get_next()
	dir.list_dir_end()

	_dirty = false


## Save a lightweight index file (for the web editor to quickly list specimens).
func _save_index() -> void:
	var index: Array[Dictionary] = list_all()
	var json_str: String = JSON.stringify(index, "\t")
	var file := FileAccess.open(INDEX_FILE, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()


# ═══════════════════════════════════════════════════════════════
# DNA ↔ JSON CONVERSION
# ═══════════════════════════════════════════════════════════════

## Convert CritterDNA to a JSON-safe dictionary.
static func _dna_to_json_dict(dna: CritterDNA) -> Dictionary:
	var result: Dictionary = dna.to_dict()

	# Convert Color values to hex strings for JSON compatibility
	for key in result:
		if result[key] is Color:
			result[key] = (result[key] as Color).to_html(false)

	# Include lineage metadata
	result["generation"] = dna.generation
	result["parent_a_id"] = dna.parent_a_id
	result["parent_b_id"] = dna.parent_b_id
	result["mutations"] = dna.mutations.duplicate()

	return result


## Convert a JSON dictionary back to CritterDNA.
static func _json_dict_to_dna(data: Dictionary) -> CritterDNA:
	var dna := CritterDNA.new()

	# Identify which keys are colors by checking against a fresh DNA's property types
	var color_keys: Array[String] = ["primary_color", "secondary_color", "tertiary_color"]

	for key in data:
		if key in ["generation", "parent_a_id", "parent_b_id", "mutations"]:
			continue

		var val = data[key]
		if key in color_keys and val is String:
			dna.set(key, Color.html(val as String))
		elif val is float or val is int:
			# JSON parses numbers as float, GDScript property might expect float
			dna.set(key, float(val))
		else:
			dna.set(key, val)

	# Restore lineage
	dna.generation = int(data.get("generation", 0))
	dna.parent_a_id = str(data.get("parent_a_id", ""))
	dna.parent_b_id = str(data.get("parent_b_id", ""))
	if "mutations" in data and data["mutations"] is Array:
		for m in data["mutations"]:
			dna.mutations.append(str(m))

	return dna
