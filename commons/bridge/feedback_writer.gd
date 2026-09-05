extends RefCounted
class_name FeedbackWriter

## ONE WRITER for the desktop feedback files (2026-09-05). Until today three
## desktop overlays each carried a private copy of this format, and a fourth copy
## inside the comment box would have been the "one rule, two readers drift" fault
## the museum taught us. The entry shape and the bytes written here match
## DesktopMapSwitcherOverlay._append_comment_markdown / _append_comment_json
## exactly - commons/testing/probe_comment_box.gd compares the two - plus two
## ADDITIVE lines a placed box needs: `- Source:` and `- Box:`.
##
## Readers: .claude/skills/ada-bridge-listener (the .md, by its `## <ts> | <Map>`
## headers and the bullet lines), tools/sequence_pipeline_scorer.py stage 6 (the
## `- Map:` line). Nothing reads the .json; it keeps the same shape anyway.
##
## Paths: res://ada_run/... is writable on the desktop working tree and READ-ONLY
## in a headset export, so a refused res:// write falls back to user://, as the
## overlay's does. The caller learns where it landed from save()'s return.

const MARKDOWN_PATH := "res://ada_run/desktop_feedback.md"
const JSON_PATH := "res://ada_run/desktop_feedback.json"
const FALLBACK_DIR := "user://desktop_feedback"


## The entry the overlay builds, with room for the additive keys.
static func make_entry(comment: String, map_name: String, sequence_name: String = "", extra: Dictionary = {}) -> Dictionary:
	var entry := {
		"timestamp": Time.get_datetime_string_from_system(),
		"sequence_name": sequence_name,
		"map_name": map_name,
		"artifacts": [],
		"artifact_scene_paths": {},
		"comment": comment,
	}
	for k in extra.keys():
		entry[k] = extra[k]
	return entry


## Write the entry. Returns the path it landed on, or "" when nothing was written.
static func save(entry: Dictionary, path: String = MARKDOWN_PATH, as_json: bool = false) -> String:
	if path.is_empty():
		return ""
	var ok: bool = append_json(path, entry) if as_json else append_markdown(path, entry)
	if ok:
		return path
	if path.begins_with("res://"):
		var fallback: String = "%s/%s" % [FALLBACK_DIR, path.get_file()]
		ok = append_json(fallback, entry) if as_json else append_markdown(fallback, entry)
		if ok:
			return fallback
	return ""


static func append_markdown(path: String, entry: Dictionary) -> bool:
	var timestamp := str(entry.get("timestamp", Time.get_datetime_string_from_system()))
	var sequence_name := str(entry.get("sequence_name", ""))
	var map_name := str(entry.get("map_name", ""))
	var comment_text := str(entry.get("comment", ""))
	var artifacts_text := format_artifacts(entry.get("artifacts", []))
	var artifact_paths_text := format_artifact_paths(entry.get("artifact_scene_paths", {}))

	var lines: Array[String] = []
	lines.append("")
	lines.append("## %s | %s" % [timestamp, map_name if not map_name.is_empty() else "(no map selected)"])
	if not sequence_name.is_empty():
		lines.append("- Sequence: `%s`" % sequence_name)
	if not map_name.is_empty():
		lines.append("- Map: `%s`" % map_name)
	if not artifacts_text.is_empty():
		lines.append("- Interactables: %s" % artifacts_text)
	if not artifact_paths_text.is_empty():
		lines.append("- Artifact Paths:")
		lines.append(artifact_paths_text)
	# additive: where it was said (absent from the overlay's entries, so the bytes
	# match whenever these keys are absent)
	var source := str(entry.get("source", "")).strip_edges()
	if not source.is_empty():
		lines.append("- Source: `%s`" % source)
	var box := str(entry.get("box", "")).strip_edges()
	if not box.is_empty():
		lines.append("- Box: `%s`" % box)
	lines.append("")
	lines.append(comment_text)
	lines.append("")
	lines.append("---")

	var markdown_block := "\n".join(lines)
	return append_text(path, markdown_block)


static func append_json(path: String, entry: Dictionary) -> bool:
	var payload: Dictionary = {"entries": []}
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var existing_text := file.get_as_text()
			file.close()
			if not existing_text.strip_edges().is_empty():
				var parser := JSON.new()
				var parse_result := parser.parse(existing_text)
				if parse_result != OK:
					parse_result = parser.parse(strip_trailing_commas(existing_text))
				if parse_result != OK:
					return false
				var data = parser.data
				if data is Dictionary:
					payload = data
				elif data is Array:
					payload = {"entries": data}
				else:
					return false

	var entries = payload.get("entries", [])
	if not (entries is Array):
		entries = []
	var entries_array: Array = entries
	entries_array.append(entry)
	payload["entries"] = entries_array

	if not ensure_parent_directory(path):
		return false
	var out_file := FileAccess.open(path, FileAccess.WRITE)
	if not out_file:
		return false
	out_file.store_string(JSON.stringify(payload, "\t"))
	out_file.close()
	return true


static func append_text(path: String, content: String) -> bool:
	if not ensure_parent_directory(path):
		return false
	var file: FileAccess = null
	if FileAccess.file_exists(path):
		file = FileAccess.open(path, FileAccess.READ_WRITE)
		if not file:
			return false
		file.seek_end()
	else:
		file = FileAccess.open(path, FileAccess.WRITE)
		if not file:
			return false
	file.store_string(content)
	file.close()
	return true


static func ensure_parent_directory(path: String) -> bool:
	var base_dir := path.get_base_dir()
	if base_dir.is_empty():
		return true
	var absolute_dir := ProjectSettings.globalize_path(base_dir)
	if DirAccess.dir_exists_absolute(absolute_dir):
		return true
	var make_result := DirAccess.make_dir_recursive_absolute(absolute_dir)
	return make_result == OK or DirAccess.dir_exists_absolute(absolute_dir)


static func format_artifacts(artifacts_value: Variant) -> String:
	if not (artifacts_value is Array):
		return ""
	var artifacts_array: Array = artifacts_value
	if artifacts_array.is_empty():
		return ""
	var formatted: Array[String] = []
	for artifact_name in artifacts_array:
		var token := str(artifact_name).strip_edges()
		if token.is_empty():
			continue
		formatted.append("`%s`" % token)
	return ", ".join(formatted)


static func format_artifact_paths(artifact_paths_value: Variant) -> String:
	if not (artifact_paths_value is Dictionary):
		return ""
	var artifact_paths: Dictionary = artifact_paths_value
	if artifact_paths.is_empty():
		return ""
	var artifact_names: Array[String] = []
	for artifact_name in artifact_paths.keys():
		artifact_names.append(str(artifact_name))
	artifact_names.sort()
	var lines: Array[String] = []
	for artifact_name in artifact_names:
		var scene_path := str(artifact_paths.get(artifact_name, "")).strip_edges()
		if scene_path.is_empty():
			continue
		lines.append("  - `%s`: `%s`" % [artifact_name, scene_path])
	return "\n".join(lines)


static func strip_trailing_commas(json_text: String) -> String:
	var result: Array[String] = []
	var in_string := false
	var escaped := false
	var i := 0
	var len := json_text.length()
	while i < len:
		var ch: String = json_text.substr(i, 1)
		if in_string:
			result.append(ch)
			if escaped:
				escaped = false
			elif ch == "\\":
				escaped = true
			elif ch == "\"":
				in_string = false
			i += 1
			continue
		if ch == "\"":
			in_string = true
			result.append(ch)
			i += 1
			continue
		if ch == ",":
			var j := i + 1
			while j < len and is_whitespace(json_text.substr(j, 1)):
				j += 1
			var next_char: String = json_text.substr(j, 1)
			if j < len and (next_char == "}" or next_char == "]"):
				i += 1
				continue
		result.append(ch)
		i += 1
	return "".join(result)


static func is_whitespace(ch: String) -> bool:
	return ch == " " or ch == "\n" or ch == "\r" or ch == "\t"


## The entries already in a feedback file, newest last, each as the raw block
## text after its `## ` header. A reader for "N comments left at this box".
static func read_blocks(path: String) -> Array[String]:
	var out: Array[String] = []
	if not FileAccess.file_exists(path):
		return out
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return out
	var parts := text.split("\n## ")
	for i in range(1, parts.size()):
		out.append(parts[i])
	return out
