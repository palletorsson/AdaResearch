extends SceneTree

var changed_files: Array = []
var missing_resources: Array = []

func _init():
	_process_directory("res://")
	print("Updated %d scenes" % changed_files.size())
	if missing_resources.size() > 0:
		print("Missing resources:")
		for res_path in missing_resources:
			print("  - %s" % res_path)
	quit()

func _process_directory(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("Could not open directory: %s" % dir_path)
		return
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name == "":
			break
		if name.begins_with("."):
			continue
		var sub_path := dir_path.trim_suffix("/") + "/" + name
		if dir.current_is_dir():
			_process_directory(sub_path)
		else:
			if not name.ends_with(".tscn"):
				continue
			if sub_path.find("_vr") != -1 or sub_path.find("VR") != -1:
				continue
			if _fix_scene(sub_path):
				changed_files.append(sub_path)
	dir.list_dir_end()

func _fix_scene(scene_path: String) -> bool:
	var file := FileAccess.open(scene_path, FileAccess.READ)
	if file == null:
		push_warning("Could not open scene: %s" % scene_path)
		return false
	var original_text := file.get_as_text()
	file.close()
	var newline := "\n"
	if original_text.find("\r\n") != -1:
		newline = "\r\n"
	var lines := original_text.split("\n")
	var changed := false
	for i in range(lines.size()):
		var line := lines[i]
		var trimmed := _trim_suffix(line, "\r")
		if not trimmed.begins_with("[ext_resource"):
			continue
		var resource_path := _get_attr(trimmed, "path")
		if resource_path == "" or not resource_path.begins_with("res://"):
			continue
		if not ResourceLoader.exists(resource_path):
			if resource_path not in missing_resources:
				missing_resources.append(resource_path)
			continue
		var uid := ResourceLoader.get_resource_uid(resource_path)
		if uid == 0:
			continue
		var uid_text := ResourceUID.id_to_text(uid)
		var existing_uid := _get_attr(trimmed, "uid")
		if existing_uid == uid_text:
			continue
		trimmed = _set_attr(trimmed, "uid", uid_text)
		changed = true
		if line.ends_with("\r"):
			lines[i] = trimmed + "\r"
		else:
			lines[i] = trimmed
	if not changed:
		return false
	var updated_text := ""
	for j in range(lines.size()):
		updated_text += lines[j]
		if j < lines.size() - 1:
			updated_text += newline
	var out_file := FileAccess.open(scene_path, FileAccess.WRITE)
	if out_file == null:
		push_warning("Could not write scene: %s" % scene_path)
		return false
	out_file.store_string(updated_text)
	out_file.close()
	return true

func _get_attr(line: String, attr_name: String) -> String:
	var pattern := attr_name + "=\""
	var start := line.find(pattern)
	if start == -1:
		return ""
	start += pattern.length()
	var end := line.find("\"", start)
	if end == -1:
		return ""
	return line.substr(start, end - start)

func _set_attr(line: String, attr_name: String, value: String) -> String:
	var pattern := attr_name + "=\""
	var start := line.find(pattern)
	if start == -1:
		var insert_at := line.length() - 1
		return line.substr(0, insert_at) + " " + attr_name + "=\"" + value + "\"" + line.substr(insert_at)
	start += pattern.length()
	var end := line.find("\"", start)
	if end == -1:
		return line
	return line.substr(0, start) + value + line.substr(end)

func _trim_suffix(text: String, suffix: String) -> String:
	if text.ends_with(suffix):
		return text.substr(0, text.length() - suffix.length())
	return text
