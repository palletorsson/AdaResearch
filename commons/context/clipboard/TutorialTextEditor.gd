@tool
extends Control

# BBCode Tutorial Text Editor
# Creates/edits tutorial_text.json entries with live preview

const TUTORIAL_FILE = "res://commons/context/clipboard/tutorial_text.json"
const TUTORIAL_TEXT_DIR = "res://commons/context/clipboard/tutorial_text/"

# UI References
@onready var tutorial_list: ItemList = $VBox/HBox/LeftPanel/TutorialList
@onready var new_button: Button = $VBox/HBox/LeftPanel/Buttons/NewButton
@onready var delete_button: Button = $VBox/HBox/LeftPanel/Buttons/DeleteButton
@onready var prev_button: Button = $VBox/HBox/RightPanel/TopBar/PrevButton
@onready var next_button: Button = $VBox/HBox/RightPanel/TopBar/NextButton
@onready var tutorial_name: LineEdit = $VBox/HBox/RightPanel/TopBar/NameEdit
@onready var use_external_file: CheckBox = $VBox/HBox/RightPanel/TopBar/UseExternalFile
@onready var file_chooser: OptionButton = $VBox/HBox/RightPanel/FileChooser/FileDropdown
@onready var load_file_button: Button = $VBox/HBox/RightPanel/FileChooser/LoadFileButton
@onready var refresh_files_button: Button = $VBox/HBox/RightPanel/FileChooser/RefreshButton
@onready var content_edit: TextEdit = $VBox/HBox/RightPanel/VSplit/EditSection/ContentEdit
@onready var preview_label: RichTextLabel = $VBox/HBox/RightPanel/VSplit/PreviewSection/PreviewScroll/PreviewLabel
@onready var save_button: Button = $VBox/SaveBar/SaveButton
@onready var reload_button: Button = $VBox/SaveBar/ReloadButton
@onready var status_label: Label = $VBox/SaveBar/StatusLabel

# BBCode formatting buttons
@onready var bb_toolbar: HBoxContainer = $VBox/HBox/RightPanel/VSplit/EditSection/BBCodeToolbar

# Data
var tutorials: Dictionary = {}  # Stores tutorial objects with "content" or "content_file"
var current_key: String = ""
var modified: bool = false

func _ready() -> void:
	print("TutorialTextEditor: _ready() called")
	if not Engine.is_editor_hint():
		print("TutorialTextEditor: Not in editor, exiting")
		return

	print("TutorialTextEditor: Setting up UI...")
	_setup_ui()
	print("TutorialTextEditor: Loading tutorials...")
	_load_tutorials()
	print("TutorialTextEditor: Updating list...")
	_update_list()
	print("TutorialTextEditor: Ready complete")

func _setup_ui() -> void:
	"""Setup UI connections"""
	print("TutorialTextEditor: _setup_ui() - Checking UI nodes...")
	print("  - new_button: %s" % ("OK" if new_button else "NULL"))
	print("  - tutorial_list: %s" % ("OK" if tutorial_list else "NULL"))
	print("  - content_edit: %s" % ("OK" if content_edit else "NULL"))
	print("  - preview_label: %s" % ("OK" if preview_label else "NULL"))

	if new_button:
		new_button.pressed.connect(_on_new_tutorial)
	if delete_button:
		delete_button.pressed.connect(_on_delete_tutorial)
	if prev_button:
		prev_button.pressed.connect(_on_prev_tutorial)
	if next_button:
		next_button.pressed.connect(_on_next_tutorial)
	if save_button:
		save_button.pressed.connect(_on_save_tutorials)
	if reload_button:
		reload_button.pressed.connect(_on_reload_tutorials)
	if tutorial_list:
		tutorial_list.item_selected.connect(_on_tutorial_selected)
		print("TutorialTextEditor: Connected item_selected signal to tutorial_list")
	if tutorial_name:
		tutorial_name.text_changed.connect(_on_name_changed)
	if content_edit:
		content_edit.text_changed.connect(_on_content_changed)
	if use_external_file:
		use_external_file.toggled.connect(_on_external_file_toggled)
	if load_file_button:
		load_file_button.pressed.connect(_on_load_file_from_dropdown)
	if refresh_files_button:
		refresh_files_button.pressed.connect(_on_refresh_file_list)

	# Setup BBCode formatting buttons
	_setup_bbcode_buttons()

	# Populate file chooser dropdown
	_populate_file_chooser()

func _setup_bbcode_buttons() -> void:
	"""Setup BBCode formatting toolbar buttons"""
	if not bb_toolbar:
		return

	# Clear existing buttons
	for child in bb_toolbar.get_children():
		child.queue_free()

	# Define BBCode buttons
	var buttons = [
		{"text": "B", "tooltip": "Bold", "tag": "b"},
		{"text": "I", "tooltip": "Italic", "tag": "i"},
		{"text": "U", "tooltip": "Underline", "tag": "u"},
		{"text": "Code", "tooltip": "Code Block", "tag": "code"},
		{"text": "Center", "tooltip": "Center", "tag": "center"},
		{"text": "Red", "tooltip": "Red Color", "tag": "color=red"},
		{"text": "Cyan", "tooltip": "Cyan Color", "tag": "color=cyan"},
		{"text": "Yellow", "tooltip": "Yellow Color", "tag": "color=yellow"},
		{"text": "Lime", "tooltip": "Lime Color", "tag": "color=lime"},
		{"text": "Orange", "tooltip": "Orange Color", "tag": "color=orange"},
	]

	for btn_data in buttons:
		var btn = Button.new()
		btn.text = btn_data.text
		btn.tooltip_text = btn_data.tooltip
		btn.pressed.connect(_on_bbcode_button_pressed.bind(btn_data.tag))
		bb_toolbar.add_child(btn)

func _on_bbcode_button_pressed(tag: String) -> void:
	"""Insert BBCode tags around selected text"""
	if not content_edit:
		return

	var selection_start = content_edit.get_selection_from_line()
	var selection_end = content_edit.get_selection_to_line()
	var has_selection = content_edit.has_selection()

	if has_selection:
		var selected_text = content_edit.get_selected_text()
		var wrapped = "[%s]%s[/%s]" % [tag, selected_text, tag.split("=")[0]]
		content_edit.insert_text_at_caret(wrapped)
		content_edit.deselect()
	else:
		# No selection, just insert tags
		var tag_name = tag.split("=")[0]
		var insertion = "[%s][/%s]" % [tag, tag_name]
		content_edit.insert_text_at_caret(insertion)
		# Move caret between tags
		var caret_line = content_edit.get_caret_line()
		var caret_col = content_edit.get_caret_column()
		content_edit.set_caret_column(caret_col - tag_name.length() - 3)

	_on_content_changed()

func _on_external_file_toggled(_enabled: bool) -> void:
	"""Toggle between inline content and external file"""
	modified = true
	_set_status("Modified (unsaved)", Color.YELLOW)

func _populate_file_chooser() -> void:
	"""Populate the file chooser dropdown with available .txt files"""
	if not file_chooser:
		return

	file_chooser.clear()
	file_chooser.add_item("-- Select File --", -1)

	# Scan tutorial_text directory for .txt files
	var dir_path = TUTORIAL_TEXT_DIR
	if DirAccess.dir_exists_absolute(dir_path):
		var dir = DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			var file_list: Array[String] = []

			while file_name != "":
				if not dir.current_is_dir() and file_name.ends_with(".txt"):
					file_list.append(file_name)
				file_name = dir.get_next()

			dir.list_dir_end()

			# Sort files alphabetically
			file_list.sort()

			# Add to dropdown
			for file in file_list:
				file_chooser.add_item(file)

			print("TutorialTextEditor: Found %d .txt files in %s" % [file_list.size(), dir_path])
		else:
			print("TutorialTextEditor: Could not open directory: %s" % dir_path)
	else:
		print("TutorialTextEditor: Directory does not exist: %s" % dir_path)

func _on_load_file_from_dropdown() -> void:
	"""Load selected file from dropdown into editor"""
	if not file_chooser:
		return

	var selected_index = file_chooser.selected
	if selected_index <= 0:  # 0 is "-- Select File --"
		_set_status("Please select a file from dropdown", Color.ORANGE)
		return

	var file_name = file_chooser.get_item_text(selected_index)
	var file_path = TUTORIAL_TEXT_DIR + file_name

	if not FileAccess.file_exists(file_path):
		_set_status("File not found: %s" % file_name, Color.RED)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()

		content_edit.text = content
		_update_preview()
		modified = true

		# Check "Use External File" and update tutorial to use this file
		if use_external_file:
			use_external_file.button_pressed = true

		_set_status("Loaded file: %s (%d chars)" % [file_name, content.length()], Color.GREEN)
	else:
		_set_status("Could not open file: %s" % file_name, Color.RED)

func _on_refresh_file_list() -> void:
	"""Refresh the file chooser dropdown"""
	_populate_file_chooser()
	_set_status("File list refreshed", Color.CYAN)

func _load_tutorials() -> void:
	"""Load tutorials from JSON file with proper format support"""
	if not FileAccess.file_exists(TUTORIAL_FILE):
		tutorials = {}
		_set_status("No tutorial file found - will create on save", Color.YELLOW)
		return

	var file = FileAccess.open(TUTORIAL_FILE, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var error = json.parse(json_string)

		if error == OK:
			var data = json.data
			if typeof(data) == TYPE_DICTIONARY:
				# Handle new format with "tutorials" nested key
				if data.has("tutorials"):
					tutorials = data.tutorials
					_set_status("Loaded %d tutorials" % tutorials.size(), Color.GREEN)
				else:
					# Legacy format: direct key-value pairs
					tutorials = data
					_set_status("Loaded %d tutorials (legacy format)" % tutorials.size(), Color.GREEN)
			else:
				_set_status("Invalid JSON format", Color.RED)
		else:
			_set_status("JSON parse error: %s" % json.get_error_message(), Color.RED)
	else:
		_set_status("Could not open file", Color.RED)

func _save_tutorials() -> void:
	"""Save tutorials to JSON file with proper format"""
	# Save current tutorial first
	if not current_key.is_empty():
		_save_current_tutorial()

	# Build proper JSON structure
	var output_data = {
		"_metadata": {
			"description": "Tutorial text content for codeDisplay system",
			"version": "1.0",
			"format": "BBCode supported text"
		},
		"tutorials": tutorials
	}

	var file = FileAccess.open(TUTORIAL_FILE, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(output_data, "\t")
		file.store_string(json_string)
		file.close()
		modified = false
		_set_status("Saved %d tutorials to %s" % [tutorials.size(), TUTORIAL_FILE], Color.GREEN)
	else:
		_set_status("Failed to save file", Color.RED)

func _save_current_tutorial() -> void:
	"""Save the currently edited tutorial"""
	if current_key.is_empty():
		return

	var tutorial_obj = {}

	if use_external_file and use_external_file.button_pressed:
		# Save to external file
		var file_path = TUTORIAL_TEXT_DIR + current_key + ".txt"
		var dir_path = file_path.get_base_dir()

		# Ensure directory exists
		if not DirAccess.dir_exists_absolute(dir_path):
			DirAccess.make_dir_recursive_absolute(dir_path)

		var file = FileAccess.open(file_path, FileAccess.WRITE)
		if file:
			file.store_string(content_edit.text)
			file.close()
			tutorial_obj["content_file"] = file_path
			_set_status("Saved external file: %s" % file_path, Color.CYAN)
		else:
			_set_status("Failed to save external file", Color.RED)
			return
	else:
		# Save inline content
		tutorial_obj["content"] = content_edit.text

	tutorials[current_key] = tutorial_obj

func _update_list() -> void:
	"""Update the tutorial list"""
	print("TutorialTextEditor: _update_list() called with %d tutorials" % tutorials.size())
	tutorial_list.clear()
	var keys = tutorials.keys()
	keys.sort()

	for key in keys:
		tutorial_list.add_item(key)
		print("TutorialTextEditor: Added item to list: '%s'" % key)

	# Select current if exists
	if not current_key.is_empty():
		print("TutorialTextEditor: Looking for current_key '%s' in list" % current_key)
		for i in range(tutorial_list.item_count):
			if tutorial_list.get_item_text(i) == current_key:
				tutorial_list.select(i)
				print("TutorialTextEditor: Selected index %d" % i)
				break
	else:
		print("TutorialTextEditor: No current_key set, not selecting anything")

func _load_tutorial(key: String) -> void:
	"""Load a tutorial into the editor"""
	print("TutorialTextEditor: _load_tutorial() called for key: '%s'" % key)

	if not tutorials.has(key):
		print("TutorialTextEditor: ERROR - Tutorial key '%s' not found in tutorials dict" % key)
		return

	if not content_edit:
		print("TutorialTextEditor: ERROR - content_edit is null!")
		return

	current_key = key
	tutorial_name.text = key

	var tutorial_data = tutorials[key]
	print("TutorialTextEditor: tutorial_data type: %s, value: %s" % [typeof(tutorial_data), str(tutorial_data)])

	# Handle different formats
	if typeof(tutorial_data) == TYPE_DICTIONARY:
		print("TutorialTextEditor: Tutorial data is Dictionary")
		# New format with content or content_file
		if tutorial_data.has("content_file"):
			# Load from external file
			var file_path = tutorial_data.content_file
			print("TutorialTextEditor: Loading from external file: %s" % file_path)
			if FileAccess.file_exists(file_path):
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file:
					var file_content = file.get_as_text()
					file.close()
					content_edit.text = file_content
					print("TutorialTextEditor: Loaded %d characters from file" % file_content.length())
					if use_external_file:
						use_external_file.button_pressed = true
				else:
					var error_msg = "[ERROR: Could not open file: %s]" % file_path
					content_edit.text = error_msg
					print("TutorialTextEditor: %s" % error_msg)
			else:
				var error_msg = "[ERROR: File not found: %s]" % file_path
				content_edit.text = error_msg
				print("TutorialTextEditor: %s" % error_msg)
		elif tutorial_data.has("content"):
			# Inline content
			print("TutorialTextEditor: Using inline content (%d chars)" % tutorial_data.content.length())
			content_edit.text = tutorial_data.content
			if use_external_file:
				use_external_file.button_pressed = false
		else:
			var error_msg = "[ERROR: Tutorial has no content or content_file]"
			content_edit.text = error_msg
			print("TutorialTextEditor: %s" % error_msg)
	elif typeof(tutorial_data) == TYPE_STRING:
		# Legacy format: direct string content
		print("TutorialTextEditor: Using legacy string format (%d chars)" % tutorial_data.length())
		content_edit.text = tutorial_data
		if use_external_file:
			use_external_file.button_pressed = false
	else:
		var error_msg = "[ERROR: Unknown tutorial data format: %s]" % typeof(tutorial_data)
		content_edit.text = error_msg
		print("TutorialTextEditor: %s" % error_msg)

	print("TutorialTextEditor: content_edit.text length after load: %d" % content_edit.text.length())
	_update_preview()
	_update_navigation_buttons()

func _update_preview() -> void:
	"""Update the BBCode preview"""
	if preview_label:
		# Expand any tt: references for preview
		var expanded_text = _expand_text(content_edit.text)
		preview_label.parse_bbcode(expanded_text)

func _expand_text(text: String) -> String:
	"""Expand tt:name references in text"""
	var result = text
	var regex = RegEx.new()
	regex.compile("tt:([a-z_]+)")

	var matches = regex.search_all(result)
	for match_obj in matches:
		var ref_key = match_obj.get_string(1)
		if tutorials.has(ref_key):
			var tutorial_data = tutorials[ref_key]
			var replacement = ""

			# Handle different formats
			if typeof(tutorial_data) == TYPE_DICTIONARY:
				if tutorial_data.has("content"):
					replacement = tutorial_data.content
				elif tutorial_data.has("content_file"):
					# Load from external file
					var file_path = tutorial_data.content_file
					if FileAccess.file_exists(file_path):
						var file = FileAccess.open(file_path, FileAccess.READ)
						if file:
							replacement = file.get_as_text()
							file.close()
			elif typeof(tutorial_data) == TYPE_STRING:
				replacement = tutorial_data

			if not replacement.is_empty():
				result = result.replace(match_obj.get_string(), replacement)

	return result

func _update_navigation_buttons() -> void:
	"""Update prev/next button states"""
	if tutorial_list.item_count == 0:
		prev_button.disabled = true
		next_button.disabled = true
		return

	var current_index = -1
	for i in range(tutorial_list.item_count):
		if tutorial_list.get_item_text(i) == current_key:
			current_index = i
			break

	prev_button.disabled = (current_index <= 0)
	next_button.disabled = (current_index >= tutorial_list.item_count - 1)

func _set_status(message: String, color: Color = Color.WHITE) -> void:
	"""Set status message"""
	if status_label:
		status_label.text = message
		status_label.modulate = color

# === SIGNAL HANDLERS ===

func _on_new_tutorial() -> void:
	"""Create a new tutorial"""
	var new_name = "new_tutorial"
	var counter = 1

	# Find unique name
	while tutorials.has(new_name):
		new_name = "new_tutorial_%d" % counter
		counter += 1

	# Create new tutorial with inline content
	tutorials[new_name] = {
		"content": "[b]New Tutorial[/b]\n\nEdit this content..."
	}
	_update_list()
	_load_tutorial(new_name)
	modified = true
	_set_status("Created new tutorial: %s" % new_name, Color.CYAN)

	# Focus on name edit for renaming
	tutorial_name.grab_focus()
	tutorial_name.select_all()

func _on_delete_tutorial() -> void:
	"""Delete current tutorial"""
	if current_key.is_empty():
		return

	tutorials.erase(current_key)
	current_key = ""
	tutorial_name.text = ""
	content_edit.text = ""
	_update_list()
	_update_preview()
	modified = true
	_set_status("Deleted tutorial", Color.ORANGE)

func _on_prev_tutorial() -> void:
	"""Navigate to previous tutorial"""
	var current_index = -1
	for i in range(tutorial_list.item_count):
		if tutorial_list.get_item_text(i) == current_key:
			current_index = i
			break

	if current_index > 0:
		var prev_key = tutorial_list.get_item_text(current_index - 1)
		_load_tutorial(prev_key)
		tutorial_list.select(current_index - 1)

func _on_next_tutorial() -> void:
	"""Navigate to next tutorial"""
	var current_index = -1
	for i in range(tutorial_list.item_count):
		if tutorial_list.get_item_text(i) == current_key:
			current_index = i
			break

	if current_index < tutorial_list.item_count - 1:
		var next_key = tutorial_list.get_item_text(current_index + 1)
		_load_tutorial(next_key)
		tutorial_list.select(current_index + 1)

func _on_save_tutorials() -> void:
	"""Save button clicked"""
	_save_tutorials()

func _on_reload_tutorials() -> void:
	"""Reload button clicked"""
	if modified:
		# Could add confirmation dialog here
		pass

	_load_tutorials()
	_update_list()
	if not current_key.is_empty() and tutorials.has(current_key):
		_load_tutorial(current_key)
	_set_status("Reloaded from file", Color.CYAN)

func _on_tutorial_selected(index: int) -> void:
	"""Tutorial selected in list"""
	print("TutorialTextEditor: _on_tutorial_selected() called with index: %d" % index)

	# Save current before switching
	if not current_key.is_empty():
		print("TutorialTextEditor: Saving current tutorial: %s" % current_key)
		_save_current_tutorial()

	var key = tutorial_list.get_item_text(index)
	print("TutorialTextEditor: Selected tutorial key: '%s'" % key)
	_load_tutorial(key)

func _on_name_changed(new_name: String) -> void:
	"""Tutorial name changed (rename)"""
	if current_key.is_empty() or new_name == current_key:
		return

	# Check if name already exists
	if tutorials.has(new_name):
		_set_status("Name already exists!", Color.RED)
		return

	# Rename
	var content = tutorials[current_key]
	tutorials.erase(current_key)
	tutorials[new_name] = content
	current_key = new_name
	_update_list()
	modified = true
	_set_status("Renamed to: %s" % new_name, Color.CYAN)

func _on_content_changed() -> void:
	"""Content changed"""
	modified = true
	_update_preview()
	_set_status("Modified (unsaved)", Color.YELLOW)
