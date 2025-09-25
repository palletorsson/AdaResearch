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

func _format_snippet(snippet_id: String, as_bbcode: bool) -> String:
	var snippet: Dictionary = _snippets[snippet_id]
	var title: String = snippet.get("title", snippet_id.capitalize())
	var summary: String = snippet.get("summary", "")
	var code: String = snippet.get("code", "")
	var pieces: Array[String] = []
	if as_bbcode:
		if not title.is_empty():
			pieces.append("[b]" + title + "[/b]")
		if not summary.is_empty():
			pieces.append(summary)
		if not code.is_empty():
			pieces.append("[code=gdscript]\n" + code + "\n[/code]")
		return "\n" + "\n".join(pieces) + "\n"
	else:
		if not title.is_empty():
			pieces.append(title)
		if not summary.is_empty():
			pieces.append(summary)
		if not code.is_empty():
			pieces.append(code)
		return "\n" + "\n".join(pieces) + "\n"
