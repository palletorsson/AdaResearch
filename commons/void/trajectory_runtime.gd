extends RefCounted
## Published from the editable trajectory outline. Source artifact layouts and
## authored scores remain separate; this selects which encounters are in play.
const FILE := "res://commons/data/encounters/trajectory_runtime.json"
static var file := FILE
static var _loaded := false
static var _data: Dictionary = {}

static func reread() -> void:
	_loaded = false
	_data = {}

static func data() -> Dictionary:
	if not _loaded:
		_loaded = true
		if FileAccess.file_exists(file):
			var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(file))
			if value is Dictionary and value.get("version") == 1: _data = value
	return _data

static func coins(base: Array) -> Array:
	var published := data()
	if published.is_empty(): return base
	var managed: Array = published.get("managed_maps", [])
	var result: Array = base.filter(func(c): return not str(c.get("floor", "")) in managed)
	result.append_array(published.get("coins", []))
	return result

static func bindings(base: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	var published := data()
	for map in published.get("managed_maps", []):
		result[map] = published.get("maps", {}).get(map, {})
	return result
