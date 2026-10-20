extends Node
## Optional recording support. The introductory lesson is direct_randomness.gd.
@export_multiline var observation := ""
@export_multiline var next_change := ""
@export var load_path := ""
@onready var shelf = get_parent()

func capture() -> Dictionary:
	var number: int = shelf.get_sample_seed() if shelf.has_method("get_sample_seed") else shelf.SEED
	return {"schema":"randomness-shelf/1", "seed":number,
		"values":shelf.values.duplicate(), "cursor":shelf.cursor,
		"x_extent":shelf.x_extent, "mapping":"four-directions/1"}

func save_trial() -> String:
	var state := capture()
	var entry := {"engine":Engine.get_version_info().string, "record":state,
		"record_bytes":Marshalls.raw_to_base64(var_to_bytes(state)),
		"observation":observation, "next_change":next_change}
	var stem := "user://randomness-shelf-%d-%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	var path := stem + ".json"
	var serial := 0
	while FileAccess.file_exists(path):
		serial += 1
		path = "%s-%d.json" % [stem, serial]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open the shelf recording for writing.")
		return ""
	file.store_string(JSON.stringify(entry,"\t",true,true))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		push_error("Could not finish writing the shelf recording.")
		return ""
	load_path = path
	shelf.get_node("Status").text = "Kept. File location is in Godot Output."
	print("Shelf recording: ", ProjectSettings.globalize_path(path))
	return path

func restore(state: Variant) -> bool:
	if not state is Dictionary: return false
	if state.get("schema") != "randomness-shelf/1" or state.get("mapping") != "four-directions/1": return false
	if not state.get("seed") is int: return false
	if shelf.has_method("accepts_sample_seed"):
		if not shelf.accepts_sample_seed(state.seed): return false
	elif state.seed != shelf.SEED: return false
	if not state.get("values") is Array or state.values.size() != shelf.COUNT: return false
	for value in state.values:
		if not (value is int or value is float) or not is_finite(value) or value<0 or value>1: return false
	if not state.get("cursor") is int or state.cursor<0 or state.cursor>=shelf.COUNT: return false
	if not (state.get("x_extent") is int or state.get("x_extent") is float): return false
	if not is_finite(state.x_extent) or state.x_extent<0.05 or state.x_extent>0.4: return false
	# Validate the whole record before changing either this shelf or the shared hall.
	if shelf.has_method("restore_sample_seed") and not shelf.restore_sample_seed(state.seed): return false
	shelf.values.assign(state.values)
	shelf.cursor = state.cursor
	shelf.x_extent = state.x_extent
	shelf.show_sample()
	return true

func load_trial() -> bool:
	if not FileAccess.file_exists(load_path):
		shelf.get_node("Status").text = "Choose a saved file in Notebook's load_path."
		return false
	var entry = JSON.parse_string(FileAccess.get_file_as_string(load_path))
	if not entry is Dictionary or not entry.get("record_bytes") is String: return false
	if not restore(bytes_to_var(Marshalls.base64_to_raw(entry.record_bytes))):
		shelf.get_node("Status").text = "Incompatible record; current study retained."
		return false
	observation = str(entry.get("observation",""))
	next_change = str(entry.get("next_change",""))
	shelf.get_node("Status").text = "Loaded saved values, sample and X range."
	return true
