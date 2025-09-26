extends RefCounted

class_name CodeSnippetLibrary

var _regex: RegEx
var _snippets: Dictionary = {}
var _snippets_file_path: String = "res://commons/context/clipboard/snippets.json"

func _init() -> void:
	_regex = RegEx.new()
	# Updated regex to support both "code:key" and "code#key" syntax
	_regex.compile("code[:#]([A-Za-z0-9_]+)")
	_load_snippets_from_file()

func _load_snippets_from_file() -> void:
	if not FileAccess.file_exists(_snippets_file_path):
		print("Warning: Snippets file not found at: ", _snippets_file_path)
		_load_fallback_snippets()
		return
	
	var file = FileAccess.open(_snippets_file_path, FileAccess.READ)
	if file == null:
		print("Error: Could not open snippets file: ", _snippets_file_path)
		_load_fallback_snippets()
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("Error: Failed to parse snippets JSON: ", json.get_error_message())
		_load_fallback_snippets()
		return
	
	var data = json.data
	if data.has("snippets") and typeof(data.snippets) == TYPE_DICTIONARY:
		_snippets = data.snippets
		print("Loaded ", _snippets.size(), " snippets from JSON file")
	else:
		print("Error: Invalid snippets JSON structure")
		_load_fallback_snippets()

func _load_fallback_snippets() -> void:
	print("Loading fallback snippets...")
	_snippets = {
		"point": {
			"title": "Create a Point",
			"summary": "Instantiate a point and place it in 3D space:",
			"code": "var point := Node3D.new()\npoint.name = \"Point\"\npoint.position = Vector3.ZERO\nadd_child(point)"
		},
		"line": {
			"title": "Connect Two Points", 
			"summary": "Generate a MeshInstance3D line segment between two positions:",
			"code": "func create_line(start: Vector3, finish: Vector3) -> MeshInstance3D:\n\tvar mesh := MeshInstance3D.new()\n\tvar st := SurfaceTool.new()\n\tst.begin(Mesh.PRIMITIVE_LINES)\n\tst.add_vertex(start)\n\tst.add_vertex(finish)\n\tmesh.mesh = st.commit()\n\treturn mesh"
		}
	}

func has_snippet(snippet_id: String) -> bool:
	return _snippets.has(snippet_id.to_lower())

func expand_text(text: String, as_bbcode: bool = true) -> String:
	if text.is_empty():
		return text
	var matches = _regex.search_all(text)
	if not matches:
		return text
	var builder := ""
	var last_index := 0
	for match in matches:
		var start := match.get_start()
		var end := match.get_end()
		builder += (text.substr(last_index, start - last_index))
		var snippet_id := match.get_string(1).to_lower()
		if has_snippet(snippet_id):
			builder += (_format_snippet(snippet_id, as_bbcode))
		else:
			builder += (match.get_string(0))
		last_index = end
	builder += (text.substr(last_index, text.length() - last_index))
	return builder

func expand_to_plain(text: String) -> String:
	return expand_text(text, false)

func get_snippet(snippet_id: String) -> Dictionary:
	"""Get a specific snippet by ID"""
	var id = snippet_id.to_lower()
	if _snippets.has(id):
		return _snippets[id]
	return {}

func get_all_snippet_ids() -> Array[String]:
	"""Get all available snippet IDs"""
	var ids: Array[String] = []
	for key in _snippets.keys():
		ids.append(key)
	return ids

func reload_snippets() -> void:
	"""Reload snippets from file"""
	_snippets.clear()
	_load_snippets_from_file()

func _load_text_from_file(file_path: String) -> String:
	"""Load text content from an external file"""
	if not FileAccess.file_exists(file_path):
		print("Warning: Code file not found: ", file_path)
		return ""
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Error: Could not open code file: ", file_path)
		return ""
	
	var content = file.get_as_text()
	file.close()
	return content

func _format_snippet(snippet_id: String, as_bbcode: bool) -> String:
	var snippet: Dictionary = _snippets[snippet_id]
	var title: String = snippet.get("title", snippet_id.capitalize())
	var description: String = snippet.get("summary", "")

	# Prefer external content when provided
	if snippet.has("code_file"):
		description = _load_text_from_file(snippet["code_file"])
		if description.is_empty():
			print("Clipboard: Snippet %s code file '%s' returned empty content" % [snippet_id, snippet["code_file"]])
	elif snippet.has("code"):
		description = str(snippet.get("code", ""))

	description = _normalize_line_endings(description)
	description = _strip_redundant_heading(title, description)

	var pieces: Array[String] = []
	if as_bbcode:
		if not title.is_empty():
			pieces.append("[b]" + _escape_bbcode(title) + "[/b]")
		if not description.is_empty():
			pieces.append(_convert_markdown_to_bbcode(description))
		return "\n" + "\n".join(pieces) + "\n"
	else:
		if not title.is_empty():
			pieces.append(title)
		if not description.is_empty():
			pieces.append(description)
		return "\n" + "\n".join(pieces) + "\n"

func _normalize_line_endings(text: String) -> String:
	return text.replace("\r\n", "\n").replace("\r", "\n").strip_edges()

func _strip_redundant_heading(title: String, content: String) -> String:
	if content.is_empty():
		return content
	var lines := content.split("\n")
	if lines.is_empty():
		return content
	var first_line := lines[0].strip_edges()
	if not first_line.begins_with("#"):
		return content
	var heading_text := first_line
	while heading_text.begins_with("#"):
		heading_text = heading_text.substr(1, heading_text.length() - 1)
		heading_text = heading_text.strip_edges()
	if heading_text.to_lower() != title.strip_edges().to_lower():
		return content
	lines.remove_at(0)
	while lines.size() > 0 and lines[0].strip_edges().is_empty():
		lines.remove_at(0)
	return "\n".join(lines).strip_edges()

func _escape_bbcode(text: String) -> String:
	var result := text.replace("\\", "\\\\")
	result = result.replace("[", "\\[")
	result = result.replace("]", "\\]")
	return result

func _convert_markdown_to_bbcode(markdown: String) -> String:
	var bold_regex := RegEx.new()
	if bold_regex.compile("\\*\\*(.+?)\\*\\*") != OK:
		return _escape_bbcode(markdown)
	var italic_regex := RegEx.new()
	if italic_regex.compile("(?<!\\*)\\*(?!\\s)(.+?)(?<!\\s)\\*(?!\\*)") != OK:
		return _escape_bbcode(markdown)
	var lines = markdown.split("\n")
	var converted: Array[String] = []
	var in_code := false
	var code_lang := ""
	var code_buffer: Array[String] = []
	for line in lines:
		var stripped_raw := line.strip_edges()
		if stripped_raw.begins_with("```"):
			if in_code:
				var code_text := "\n".join(code_buffer)
				var lang_tag := _escape_bbcode(code_lang)
				if lang_tag.is_empty():
					converted.append("[code]\n" + code_text + "\n[/code]")
				else:
					converted.append("[code=%s]\n%s\n[/code]" % [lang_tag, code_text])
				code_buffer.clear()
				in_code = false
				code_lang = ""
			else:
				in_code = true
				code_lang = stripped_raw.substr(3, stripped_raw.length() - 3).strip_edges()
			continue
		if in_code:
			code_buffer.append(line)
			continue
		if stripped_raw.is_empty():
			converted.append("")
			continue
		var processed := _escape_bbcode(line)
		processed = bold_regex.sub(processed, "[b]\\1[/b]", true)
		processed = italic_regex.sub(processed, "[i]\\1[/i]", true)
		if stripped_raw.begins_with("### "):
			converted.append("[b]" + _escape_bbcode(stripped_raw.substr(4)) + "[/b]")
		elif stripped_raw.begins_with("## "):
			converted.append("[b]" + _escape_bbcode(stripped_raw.substr(3)) + "[/b]")
		elif stripped_raw.begins_with("# "):
			converted.append("[b]" + _escape_bbcode(stripped_raw.substr(2)) + "[/b]")
		elif stripped_raw.begins_with("- ") and processed.length() >= 2:
			converted.append("- " + processed.substr(2, processed.length() - 2))
		else:
			converted.append(processed)
	if in_code:
		var code_text := "\n".join(code_buffer)
		var lang_tag := _escape_bbcode(code_lang)
		if lang_tag.is_empty():
			converted.append("[code]\n" + code_text + "\n[/code]")
		else:
			converted.append("[code=%s]\n%s\n[/code]" % [lang_tag, code_text])
	return "\n".join(converted)
