extends Node
class_name SceneSlideshowManager

# Scene slideshow manager — cycles through algorithm scenes
# Persists ONLY filenames (no JSON/metadata) to user://scores/scored_files.txt

@export var starting_slide_index: int = 0
@export var scan_root: String = "res://algorithms"  # root to search for .tscn scenes

const SAVE_SUBDIR := "scores"
const SAVE_TXT := "scored_files.txt"

var scene_list: Array[String] = []
var scene_metadata: Array[Dictionary] = []          # aligned with scene_list (in-memory only)
var scene_scores: Dictionary[String, int] = {}      # scene_path -> score (in-memory only)
var current_scene_index: int = 0
var current_score: int = 0
var total_score: int = 0
var current_map_data: Dictionary[String, Variant] = {}
var scene_root: Node = null

func _ready() -> void:
	print("=== Scene Slideshow Manager (Filename-only persistence) ===")
	_print_controls()

	# Index scenes
	print("Indexing scenes under:", scan_root)
	_index_scenes(scan_root)
	print("Found ", scene_list.size(), " scenes.")

	# Show where user:// resolves on this machine
	var user_abs: String = ProjectSettings.globalize_path("user://")
	print("Save directory (user://) → ", user_abs)
	print("File will be:", user_abs, SAVE_SUBDIR, "/", SAVE_TXT)

	# Start
	if not scene_list.is_empty():
		current_scene_index = clamp(starting_slide_index, 0, scene_list.size() - 1)
		_load_scene_at_index(current_scene_index)
	else:
		print("No scenes found. Put .tscn files under:", scan_root)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_N:                                 next_scene()
			KEY_P:                                 previous_scene()
			KEY_PLUS, KEY_KP_ADD:                  increase_score()
			KEY_MINUS, KEY_KP_SUBTRACT:            decrease_score()
			KEY_R:                                 reset_score()
			KEY_X:                                 save_current_score_and_filename()   # save current filename only
			KEY_C:                                 _additional_control()
			KEY_J:                                 save_all_scored_filenames()         # write all scored filenames
			KEY_K:                                 save_complete_json_data()           # save complete JSON data

# ---------------------------
# Scene indexing & loading
# ---------------------------

func _index_scenes(root_path: String) -> void:
	var pending: Array[String] = [root_path]
	var found_paths: Array[String] = []

	while not pending.is_empty():
		var base: String = pending.pop_back()
		var d: DirAccess = DirAccess.open(base)
		if d == null:
			continue

		d.list_dir_begin()
		var _name: String = d.get_next()
		while _name != "":
			if _name.begins_with("."):
				_name = d.get_next()
				continue

			var full: String = base.path_join(_name)
			if d.current_is_dir():
				pending.push_back(full)
			else:
				if _name.ends_with(".tscn"):
					found_paths.append(full)
			_name = d.get_next()
		d.list_dir_end()

	found_paths.sort()

	scene_list.clear()
	scene_metadata.clear()
	for path in found_paths:
		scene_list.append(path)
		var m: Dictionary[String, Variant] = {
			"path": path,
			"name": path.get_file().get_basename(),   # filename without extension
			"filename": path.get_file(),              # filename with extension
			"directory": path.get_base_dir(),
			"score": 0,
			"map_data": {},
			"timestamp": Time.get_unix_time_from_system()
		}
		scene_metadata.append(m)

func _load_scene_at_index(index: int) -> void:
	if index < 0 or index >= scene_list.size():
		return

	var scene_path: String = scene_list[index]
	var metadata: Dictionary = scene_metadata[index] if index < scene_metadata.size() else {}

	print("\n=== Loading Scene ", index + 1, "/", scene_list.size(), " ===")
	print("Path: ", scene_path)
	print("Name: ", metadata.get("name", "Unknown"))
	print("Current Score (session): ", current_score)
	print("Saved Scene Score (in-memory): ", metadata.get("score", 0))

	if is_instance_valid(scene_root):
		scene_root.queue_free()
		scene_root = null

	if not ResourceLoader.exists(scene_path):
		print("ERROR: Scene does not exist:", scene_path)
		return

	var packed: PackedScene = load(scene_path)
	if packed == null:
		print("ERROR: Failed to load scene:", scene_path)
		return

	scene_root = packed.instantiate()
	if scene_root == null:
		print("ERROR: Failed to instantiate scene:", scene_path)
		return

	add_child(scene_root)

	_update_current_map_data(scene_path, metadata)

	print("✓ Scene loaded successfully")
	print("================================")

func next_scene() -> void:
	if scene_list.is_empty():
		print("No scenes to load")
		return
	current_scene_index = (current_scene_index + 1) % scene_list.size()
	_load_scene_at_index(current_scene_index)

func previous_scene() -> void:
	if scene_list.is_empty():
		print("No scenes to load")
		return
	current_scene_index -= 1
	if current_scene_index < 0:
		current_scene_index = scene_list.size() - 1
	_load_scene_at_index(current_scene_index)

# ---------------------------
# Scoring system (in-memory)
# ---------------------------

func increase_score() -> void:
	current_score += 1
	print("Score increased to:", current_score)

func decrease_score() -> void:
	current_score = max(0, current_score - 1)
	print("Score decreased to:", current_score)

func reset_score() -> void:
	current_score = 0
	print("Score reset to:", current_score)

func save_current_score_and_filename() -> void:
	# Save in-memory score for the current scene
	if current_scene_index < 0 or current_scene_index >= scene_metadata.size():
		print("No current scene to save")
		return
	scene_metadata[current_scene_index]["score"] = current_score
	scene_scores[scene_list[current_scene_index]] = current_score
	total_score = _calculate_total_score()

	print("Score saved (in-memory). Scene:", scene_metadata[current_scene_index]["name"], "→", current_score)
	print("Total score across all scenes:", total_score)

	# Persist ONLY the current scene's filename to text (no duplicates)
	var filename_only: String = scene_list[current_scene_index].get_file()  # e.g., "MyScene.tscn"
	_append_scored_filename_unique(filename_only)

func save_all_scored_filenames() -> void:
	# Write all scenes that have score > 0 as filenames with scores (one per line)
	var scored_data: Array[String] = []
	for path in scene_scores.keys():
		var sc: int = int(scene_scores[path])
		if sc > 0:
			var filename = String(path).get_file()
			scored_data.append(filename + " | Score: " + str(sc))
	
	# Sort by filename
	scored_data.sort()
	
	# Write to file
	var file_path = _resolved_save_path(SAVE_TXT)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("ERROR: Could not open file for writing:", file_path)
		return
	
	# Write header
	file.store_line("=== Scored Scenes ===")
	file.store_line("Total scenes: " + str(scene_list.size()))
	file.store_line("Scored scenes: " + str(scored_data.size()))
	file.store_line("Total score: " + str(_calculate_total_score()))
	file.store_line("Save timestamp: " + str(Time.get_unix_time_from_system()))
	file.store_line("")
	
	# Write scored scenes
	for line in scored_data:
		file.store_line(line)
	
	file.close()
	print("✓ Wrote", scored_data.size(), "scored scenes with scores to:", ProjectSettings.globalize_path(file_path))

func save_complete_json_data() -> void:
	# Save complete JSON data with all scores and metadata
	var save_data = {
		"version": "1.0",
		"save_timestamp": Time.get_unix_time_from_system(),
		"total_scenes": scene_list.size(),
		"total_score": _calculate_total_score(),
		"current_scene_index": current_scene_index,
		"current_score": current_score,
		"scene_scores": scene_scores,
		"scene_metadata": scene_metadata,
		"current_map_data": current_map_data
	}
	
	var json_string = JSON.stringify(save_data, "\t")
	var file_path = _resolved_save_path("scene_scores.json")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file == null:
		print("ERROR: Could not create file:", file_path)
		return
	
	file.store_string(json_string)
	file.close()
	
	print("✓ Complete JSON data saved to:", ProjectSettings.globalize_path(file_path))
	print("Total score saved:", _calculate_total_score())

func _calculate_total_score() -> int:
	var total: int = 0
	for s in scene_scores.values():
		total += int(s)
	return total

func _additional_control() -> void:
	print("C key — status")
	print("Scene:", current_scene_index + 1, "/", scene_list.size())
	print("Current score:", current_score)
	print("Total score (calc):", _calculate_total_score())
	print("Current map data:", current_map_data)

# ---------------------------
# Map data (in-memory)
# ---------------------------

func _update_current_map_data(scene_path: String, metadata: Dictionary) -> void:
	current_map_data = {
		"scene_path": scene_path,
		"scene_name": metadata.get("name", "Unknown"),
		"directory": metadata.get("directory", ""),
		"current_score": current_score,
		"saved_score": metadata.get("score", 0),
		"timestamp": Time.get_unix_time_from_system(),
		"scene_index": current_scene_index
	}
	print("Map data updated for:", current_map_data["scene_name"])

func get_current_map_data() -> Dictionary:
	return current_map_data

# ---------------------------
# Filename-only persistence
# ---------------------------

func _append_scored_filename_unique(filename_only: String) -> void:
	# Ensure dir exists
	var save_path: String = _resolved_save_path(SAVE_TXT)

	# Load existing (to avoid duplicates)
	var existing: Dictionary[String, bool] = {}
	var lines: Array[String] = []
	var rf := FileAccess.open(save_path, FileAccess.READ)
	if rf != null:
		while not rf.eof_reached():
			var line: String = rf.get_line().strip_edges()
			if line != "":
				existing[line] = true
				lines.append(line)
		rf.close()

	# Append if new
	if not existing.has(filename_only):
		lines.append(filename_only)
		lines.sort()
		_write_filenames_list(lines)
		print("✓ Appended filename:", filename_only, "→", ProjectSettings.globalize_path(save_path))
	else:
		print("Filename already present:", filename_only, "→", ProjectSettings.globalize_path(save_path))

func _write_filenames_list(filenames: Array[String]) -> void:
	var save_path: String = _resolved_save_path(SAVE_TXT)
	var wf := FileAccess.open(save_path, FileAccess.WRITE)
	if wf == null:
		push_error("ERROR: Could not open for write: " + save_path + " (" + str(FileAccess.get_open_error()) + ")")
		return
	for _name in filenames:
		wf.store_line(_name)
	wf.close()

# ---------------------------
# Save path helpers
# ---------------------------

func _resolved_save_dir() -> String:
	var dir_path: String = "user://%s" % SAVE_SUBDIR
	var dir := DirAccess.open(dir_path)
	if dir == null:
		var ok: int = DirAccess.make_dir_recursive_absolute(dir_path)
		if ok != OK:
			push_error("Could not create save directory: " + dir_path)
	return dir_path

func _resolved_save_path(filename: String) -> String:
	return "%s/%s" % [_resolved_save_dir(), filename]

# ---------------------------
# UI
# ---------------------------

func _print_controls() -> void:
	print("")
	print("Controls:")
	print("  N - Next scene")
	print("  P - Previous scene")
	print("  + / Numpad + - Increase score (in-memory)")
	print("  - / Numpad - - Decrease score (in-memory)")
	print("  R - Reset score (in-memory)")
	print("  X - Save current filename ONLY to text (append unique)")
	print("  C - Status/Info")
	print("  J - Write ALL scored filenames with scores to text (overwrite)")
	print("  K - Save complete JSON data with all scores and metadata")
	print("  ESC - Toggle mouse capture (engine default)")
	print("===============================")
	print("")
