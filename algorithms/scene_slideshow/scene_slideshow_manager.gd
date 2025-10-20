extends Node
class_name SceneSlideshowManager

# Scene slideshow manager — cycles through algorithm scenes
# Persists ONLY filenames (no JSON/metadata) to user://scores/scored_files.txt

@export var starting_slide_index: int = 0
@export_dir var scan_root: String = "res://algorithms"  # root to search for .tscn scenes

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
var principal_list: Array[String] = []
var ui_layer: CanvasLayer
var folder_dropdown: OptionButton
var folder_paths: Array[String] = []
var comment_label: Label
var todo_label: Label

func _ready() -> void:
	print("=== Scene Slideshow Manager (Filename-only persistence) ===")
	_print_controls()

	# Build folder selector UI (dropdown)
	_build_folder_selector()

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
		print("Tip: Use the dropdown to choose a different folder.")

func _build_folder_selector() -> void:
	# Create UI layer and dropdown
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 100
	add_child(ui_layer)

	var root_ctrl := Control.new()
	root_ctrl.name = "FolderSelector"
	root_ctrl.anchor_left = 0.0
	root_ctrl.anchor_top = 0.0
	root_ctrl.anchor_right = 0.0
	root_ctrl.anchor_bottom = 0.0
	root_ctrl.offset_left = 0.0
	root_ctrl.offset_top = 0.0
	root_ctrl.offset_right = 0.0
	root_ctrl.offset_bottom = 0.0
	ui_layer.add_child(root_ctrl)

	folder_dropdown = OptionButton.new()
	folder_dropdown.position = Vector2(16, 16)
	folder_dropdown.size = Vector2(560, 28)
	root_ctrl.add_child(folder_dropdown)

	# Comment and Todo labels
	comment_label = Label.new()
	comment_label.position = Vector2(16, 52)
	comment_label.size = Vector2(700, 48)
	comment_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	comment_label.clip_text = false
	comment_label.text = ""
	root_ctrl.add_child(comment_label)

	todo_label = Label.new()
	todo_label.position = Vector2(16, 104)
	todo_label.size = Vector2(700, 64)
	todo_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	todo_label.clip_text = false
	todo_label.text = ""
	root_ctrl.add_child(todo_label)

	# Populate with algorithms root and immediate subdirectories
	folder_paths = _collect_algorithm_dirs("res://algorithms")
	# Ensure the base path is first
	if folder_paths.is_empty() or folder_paths[0] != "res://algorithms":
		folder_paths.insert(0, "res://algorithms")

	folder_dropdown.clear()
	for p in folder_paths:
		folder_dropdown.add_item(p)

	# Select current scan_root if present
	var idx := folder_paths.find(scan_root)
	if idx == -1:
		idx = 0
		scan_root = folder_paths[0]
	folder_dropdown.select(idx)

	folder_dropdown.item_selected.connect(_on_folder_selected)

func _collect_algorithm_dirs(base: String) -> Array[String]:
	var result: Array[String] = []
	var d := DirAccess.open(base)
	if d:
		d.list_dir_begin()
		var name := d.get_next()
		while name != "":
			if not name.begins_with(".") and d.current_is_dir():
				result.append(base.path_join(name))
			name = d.get_next()
		d.list_dir_end()
	result.sort()
	return result

func _on_folder_selected(index: int) -> void:
	if index < 0 or index >= folder_paths.size():
		return
	scan_root = folder_paths[index]
	print("→ Folder changed to:", scan_root)
	_index_scenes(scan_root)
	print("Found ", scene_list.size(), " scenes.")
	if not scene_list.is_empty():
		current_scene_index = 0
		_load_scene_at_index(current_scene_index)
	else:
		print("No scenes in:", scan_root)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_N:                                 next_scene()
			KEY_P:                                 previous_scene()
			KEY_PLUS, KEY_KP_ADD:                  increase_score()
			KEY_MINUS, KEY_KP_SUBTRACT:            decrease_score()
			KEY_R:                                 _principal_add_current()
			KEY_X:                                 save_current_score_and_filename()   # save current filename only
			KEY_C:                                 _additional_control()
			KEY_J:                                 save_all_scored_filenames()         # write all scored filenames
			KEY_K:                                 save_complete_json_data()           # save complete JSON data
			KEY_L:                                 _principal_print()   # L for List

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
		var name: String = d.get_next()
		while name != "":
			if name.begins_with("."):
				name = d.get_next()
				continue

			var full: String = base.path_join(name)
			if d.current_is_dir():
				pending.push_back(full)
			else:
				if name.ends_with(".tscn"):
					found_paths.append(full)
			name = d.get_next()
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

	# Instantiate the scene normally
	scene_root = packed.instantiate()
	if scene_root == null:
		print("ERROR: Failed to instantiate scene:", scene_path)
		return

	# Add scene to tree deferred to avoid parent path resolution issues
	call_deferred("add_child", scene_root)

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

func _principal_add_current() -> void:
	if current_scene_index < 0 or current_scene_index >= scene_list.size():
		print("No current scene to add to Principal list")
		return
	var path := scene_list[current_scene_index]
	if not principal_list.has(path):
		principal_list.append(path)
		print("Added to Principal list:", path)
	else:
		print("Already in Principal list:", path)

func _principal_print() -> void:
	print("=== Principal Scene List ===")
	if principal_list.is_empty():
		print("(empty)")
		return
	for i in range(principal_list.size()):
		print(str(i+1) + ") ", principal_list[i])

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
	# Lookup artifact comment for this scene path
	var comment := _lookup_artifact_comment(scene_path)
	var todo := _lookup_artifact_todo(scene_path)
	print("Comment:", (comment if comment != "" else "(none)"))
	print("Todo:", (todo if todo != "" else "(none)"))
	_update_comment_todo_ui(comment, todo)
	print("Map data updated for:", current_map_data["scene_name"])

func _lookup_artifact_comment(scene_path: String) -> String:
	var artifact_path := "res://commons/artifacts/grid_artifacts.json"
	if not ResourceLoader.exists(artifact_path):
		return ""
	var f := FileAccess.open(artifact_path, FileAccess.READ)
	if f == null:
		return ""
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return ""
	# File is a dictionary that likely has a top-level category mapping (e.g., "Procedural Generation" -> entries)
	# First, try direct keys: full path and basename at top level
	if parsed.has(scene_path):
		var entry = parsed[scene_path]
		if typeof(entry) == TYPE_DICTIONARY and entry.has("comment"):
			return String(entry["comment"])
	var key_name := String(scene_path.get_file().get_basename())
	if parsed.has(key_name):
		var entry2 = parsed[key_name]
		if typeof(entry2) == TYPE_DICTIONARY and entry2.has("comment"):
			return String(entry2["comment"])
	# Fallback: scan nested categories where values are dictionaries of entries
	for cat in parsed.keys():
		var group = parsed[cat]
		if typeof(group) == TYPE_DICTIONARY:
			# try direct key in this group
			if group.has(key_name):
				var e = group[key_name]
				if typeof(e) == TYPE_DICTIONARY and e.has("comment"):
					return String(e["comment"])
			# scan entries
			for k in group.keys():
				var v = group[k]
				if typeof(v) == TYPE_DICTIONARY:
					if v.has("scene") and String(v["scene"]) == scene_path and v.has("comment"):
						return String(v["comment"])
					if v.has("lookup_name") and String(v["lookup_name"]) == key_name and v.has("comment"):
						return String(v["comment"])
					if v.has("path") and String(v["path"]) == scene_path and v.has("comment"):
						return String(v["comment"])
	return ""

func _lookup_artifact_todo(scene_path: String) -> String:
	var artifact_path := "res://commons/artifacts/grid_artifacts.json"
	if not ResourceLoader.exists(artifact_path):
		return ""
	var f := FileAccess.open(artifact_path, FileAccess.READ)
	if f == null:
		return ""
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return ""
	# Try direct path key and file basename at top level
	if parsed.has(scene_path):
		var entry = parsed[scene_path]
		if typeof(entry) == TYPE_DICTIONARY and entry.has("todo"):
			return String(entry["todo"])
		if typeof(entry) == TYPE_STRING:
			return String(entry)
	var key_name := String(scene_path.get_file().get_basename())
	if parsed.has(key_name):
		var entry2 = parsed[key_name]
		if typeof(entry2) == TYPE_DICTIONARY:
			if entry2.has("todo"):
				return String(entry2["todo"])
			if entry2.has("notes"):
				return String(entry2["notes"]) # fallback
		if typeof(entry2) == TYPE_STRING:
			return String(entry2)
	# Fallback: scan nested categories
	for cat in parsed.keys():
		var group = parsed[cat]
		if typeof(group) == TYPE_DICTIONARY:
			if group.has(key_name):
				var e = group[key_name]
				if typeof(e) == TYPE_DICTIONARY:
					if e.has("todo"):
						return String(e["todo"])
					if e.has("notes"):
						return String(e["notes"]) # fallback
				if typeof(e) == TYPE_STRING:
					return String(e)
			for k in group.keys():
				var v = group[k]
				if typeof(v) == TYPE_DICTIONARY:
					var matches = (v.has("scene") and String(v["scene"]) == scene_path) or (v.has("path") and String(v["path"]) == scene_path)
					if matches and v.has("todo"):
						return String(v["todo"])
					if matches and v.has("notes"):
						return String(v["notes"]) # fallback
					if v.has("lookup_name") and String(v["lookup_name"]) == key_name:
						if v.has("todo"):
							return String(v["todo"])
						if v.has("notes"):
							return String(v["notes"]) # fallback
	return ""

func get_current_map_data() -> Dictionary:
	return current_map_data

func _update_comment_todo_ui(comment: String, todo: String) -> void:
	if comment_label:
		comment_label.text = ("" if comment == "" else ("Comment: " + comment))
	if todo_label:
		todo_label.text = ("" if todo == "" else ("Todo: " + todo))

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
	for name in filenames:
		wf.store_line(name)
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
	print("  R - Add current scene to Principal list")
	print("  X - Save current filename ONLY to text (append unique)")
	print("  C - Status/Info")
	print("  J - Write ALL scored filenames with scores to text (overwrite)")
	print("  K - Save complete JSON data with all scores and metadata")
	print("  L - Print Principal list to console")
	print("  ESC - Toggle mouse capture (engine default)")
	print("===============================")
	print("")
