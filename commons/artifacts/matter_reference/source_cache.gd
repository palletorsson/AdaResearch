extends RefCounted
## Cache plain source data on the running tree, not in a script static variable.
## Godot can otherwise retain an inherited script's preloaded XR/material assets.
static func read_json(path: String) -> Dictionary:
	var tree := Engine.get_main_loop();var key := "matter_reference_source_data"
	if not tree.has_meta(key):tree.set_meta(key,{})
	var cache: Dictionary = tree.get_meta(key)
	if not cache.has(path):cache[path] = JSON.parse_string(FileAccess.get_file_as_string(path))
	return cache[path]
