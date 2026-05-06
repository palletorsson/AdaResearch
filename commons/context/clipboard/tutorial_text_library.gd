extends RefCounted

class_name TutorialTextLibrary

var _regex: RegEx
var _tutorials: Dictionary = {}
var _tutorials_file_path: String = "res://commons/context/clipboard/tutorial_text.json"

func _init() -> void:
	_regex = RegEx.new()
	# Parse tt:name format
	_regex.compile("tt:([A-Za-z0-9_]+)")
	_load_tutorials_from_file()

func _load_tutorials_from_file() -> void:
	if not FileAccess.file_exists(_tutorials_file_path):
		print("Warning: Tutorial text file not found at: ", _tutorials_file_path)
		_load_fallback_tutorials()
		return
	
	var file = FileAccess.open(_tutorials_file_path, FileAccess.READ)
	if file == null:
		print("Error: Could not open tutorial text file: ", _tutorials_file_path)
		_load_fallback_tutorials()
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("Error: Failed to parse tutorial text JSON: ", json.get_error_message())
		_load_fallback_tutorials()
		return
	
	var data = json.data
	if data.has("tutorials") and typeof(data.tutorials) == TYPE_DICTIONARY:
		_tutorials = data.tutorials
		print("Loaded ", _tutorials.size(), " tutorial texts from JSON file")
	else:
		print("Error: Invalid tutorial text JSON structure")
		_load_fallback_tutorials()

func _load_fallback_tutorials() -> void:
	print("Loading fallback tutorial texts...")
	_tutorials = {
		"welcome": {
			"content": "Welcome to the tutorial!"
		}
	}

func has_tutorial(tutorial_id: String) -> bool:
	return _tutorials.has(tutorial_id.to_lower())

func get_tutorial_content(tutorial_id: String) -> String:
	"""Get tutorial content by ID, supports both inline content and content_file"""
	var id = tutorial_id.to_lower()
	print("TutorialTextLibrary: get_tutorial_content() called for '%s'" % id)

	if not _tutorials.has(id):
		print("TutorialTextLibrary: Tutorial ID '%s' not found in library" % id)
		print("TutorialTextLibrary: Available IDs: %s" % str(_tutorials.keys()))
		return ""

	var tutorial_data = _tutorials[id]
	print("TutorialTextLibrary: Found tutorial data: %s" % str(tutorial_data))

	# Check if content_file is specified
	if tutorial_data.has("content_file") and typeof(tutorial_data.content_file) == TYPE_STRING:
		var file_path = tutorial_data.content_file
		print("TutorialTextLibrary: Loading from external file: %s" % file_path)
		var content = _load_text_from_file(file_path)
		print("TutorialTextLibrary: Loaded %d characters from file" % content.length())
		return content

	# Check if inline content is specified
	if tutorial_data.has("content") and typeof(tutorial_data.content) == TYPE_STRING:
		print("TutorialTextLibrary: Using inline content (%d chars)" % tutorial_data.content.length())
		return tutorial_data.content

	print("TutorialTextLibrary: WARNING - Tutorial '%s' has neither content_file nor content" % id)
	return ""

func expand_text(text: String) -> String:
	"""Expand tt:name references in text, similar to CodeSnippetLibrary"""
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
		builder += text.substr(last_index, start - last_index)
		
		var tutorial_id := match.get_string(1).to_lower()
		if has_tutorial(tutorial_id):
			builder += get_tutorial_content(tutorial_id)
		else:
			# Keep original tt:name if not found
			builder += match.get_string(0)
		
		last_index = end
	
	builder += text.substr(last_index, text.length() - last_index)
	return builder

func _load_text_from_file(file_path: String) -> String:
	"""Load text content from an external file
	Supports both .gd files (loaded as resources) and .txt files (filesystem access)
	"""
	print("TutorialTextLibrary: _load_text_from_file() called for: %s" % file_path)

	# Check if it's a .gd file - use resource loading (MUCH better for Godot!)
	if file_path.ends_with(".gd"):
		print("TutorialTextLibrary: Loading as GDScript resource")
		var script = load(file_path)
		if script == null:
			print("TutorialTextLibrary: ERROR - Could not load script: %s" % file_path)
			return ""

		# Instantiate the script to access its variables
		var instance = script.new()
		if instance == null:
			print("TutorialTextLibrary: ERROR - Could not instantiate script")
			return ""

		# Try to get the text variable
		if "text" in instance:
			var content = instance.text
			print("TutorialTextLibrary: Successfully loaded %d characters from .gd file" % content.length())
			return content
		elif instance.has_method("get_content"):
			var content = instance.get_content()
			print("TutorialTextLibrary: Successfully loaded %d characters via get_content()" % content.length())
			return content
		else:
			print("TutorialTextLibrary: ERROR - Script has no 'text' variable or 'get_content()' method")
			return ""

	# For .txt files, use filesystem access
	print("TutorialTextLibrary: Loading as text file from filesystem")

	# Build absolute path manually
	var absolute_path = file_path
	if file_path.begins_with("res://"):
		var project_path = ProjectSettings.globalize_path("res://")
		print("TutorialTextLibrary: Project path: %s" % project_path)

		var relative_path = file_path.substr(6)  # Remove "res://"
		absolute_path = project_path + relative_path
		print("TutorialTextLibrary: Constructed absolute path: %s" % absolute_path)

	# Check if file exists
	if not FileAccess.file_exists(absolute_path):
		print("TutorialTextLibrary: ERROR - File does not exist: %s" % absolute_path)
		return ""

	# Open and read file
	var file = FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		var error_code = FileAccess.get_open_error()
		print("TutorialTextLibrary: ERROR - Could not open file (error %d): %s" % [error_code, absolute_path])
		return ""

	var content = file.get_as_text()
	file.close()
	print("TutorialTextLibrary: Successfully loaded %d characters from .txt file" % content.length())
	return content

func get_all_tutorial_ids() -> Array[String]:
	"""Get all available tutorial IDs"""
	var ids: Array[String] = []
	for key in _tutorials.keys():
		ids.append(key)
	return ids

func reload_tutorials() -> void:
	"""Reload tutorials from file"""
	_tutorials.clear()
	_load_tutorials_from_file()
