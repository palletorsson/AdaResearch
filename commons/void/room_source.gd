extends RefCounted
## Instance-scoped trials never replace the curated tower's data.
const TRIALS := "res://commons/void/trials/playable.json"

static func selected(explicit_id := "") -> String:
	if not explicit_id.is_empty(): return explicit_id
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--void-trial="): return arg.trim_prefix("--void-trial=")
	return ""

static func definition(id: String) -> Dictionary:
	if id.is_empty(): return {}
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TRIALS))
	assert(manifest.trials.has(id), "Unknown Void trial: " + id)
	return manifest.trials.get(id, {})

static func read_rooms(trial := "") -> Dictionary:
	var record := definition(selected(trial))
	var path: String = record.get("rooms", "res://commons/void/rooms.json")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--void-draft="): path = arg.trim_prefix("--void-draft=")
	return JSON.parse_string(FileAccess.get_file_as_string(path))

static func read_layout(trial := "") -> Dictionary:
	var record := definition(selected(trial))
	return JSON.parse_string(FileAccess.get_file_as_string(record.get("layout", "res://commons/void/layout.json")))
