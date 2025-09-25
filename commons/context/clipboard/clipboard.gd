extends Node3D

const CodeSnippetLibrary := preload("res://commons/context/clipboard/code_snippet_library.gd")

@export var addxp: int = 20
@export var dessp: int = -2
@onready var title_node = $GrabCube/clipboard/ClipText/Title
@onready var description_label = $GrabCube/clipboard/ClipText/Description
@onready var description_rich_text: RichTextLabel = description_label as RichTextLabel
@onready var grab_cube = $GrabCube
@onready var label3D = $Label3D
@onready var pagenumber = $"GrabCube/clipboard/pagenumber"
@export var title = ""
@export var description_sets: Array[String] = []
@onready var grab_pos = $GrabCube
var current_index: int = 0
var is_executed = false
var _snippet_library := CodeSnippetLibrary.new()

var init_position: Vector3

func _ready() -> void:
	# Initialize rich text support
	if description_rich_text:
		description_rich_text.bbcode_enabled = true
	else:
		description_label.text = ""

	# Load pages from metadata or map data
	var map_pages := _extract_pages_from_metadata()
	if map_pages.size() > 0:
		description_sets = map_pages

	# Try to load from map data if no metadata found
	if description_sets.size() == 0:
		_load_from_map_data()

	init_position = grab_pos.position

	if grab_cube.has_signal("item_dropped"):
		grab_cube.connect("item_dropped", Callable(self, "_on_item_dropped"))
		label3D.text = "Grab me: " + str(init_position)
	else:
		print("GrabCube does not have 'item_dropped' signal!")
		if label3D:
			label3D.text = "Error: 'item_dropped' signal missing!"

	if description_sets.size() > 0:
		_update_display()
	
	# Set title from map data if available
	if title.is_empty():
		title = _get_title_from_map_data()
	title_node.text = title

func _on_item_dropped() -> void:
	if is_executed:
		label3D.text = "Already read them"
		return

	is_executed = true
	var health = GameManager.get_health() + dessp
	GameManager.set_health(health)
	var xp = GameManager.get_xp() + addxp
	GameManager.set_xp(xp)
	label3D.text = "XP/SP updated"

func _next_page() -> void:
	if description_sets.is_empty():
		return
	current_index = (current_index + 1) % description_sets.size()
	_update_display()

func _update_display() -> void:
	if description_sets.is_empty() or current_index >= description_sets.size():
		return

	var raw_text := description_sets[current_index]
	if description_rich_text:
		description_rich_text.bbcode_text = _snippet_library.expand_text(raw_text, true)
	else:
		description_label.text = _snippet_library.expand_to_plain(raw_text)

	pagenumber.text = "(Page: %d of %d pages)" % [current_index + 1, description_sets.size()]

func _extract_pages_from_metadata() -> Array[String]:
	# Prefer metadata provided by GridInteractables (set via set_meta).
	if has_meta("clipboard_pages") and typeof(get_meta("clipboard_pages")) == TYPE_ARRAY:
		var pages_meta = get_meta("clipboard_pages")
		var result: Array[String] = []
		for entry in pages_meta:
			result.append(str(entry))
		return result
	
	if description_sets.size() > 0:
		return description_sets
	
	return []

func _load_from_map_data() -> void:
	"""Load clipboard content from current map's JSON data"""
	var map_manager = get_node_or_null("/root/GameManager")
	if not map_manager or not map_manager.has_method("get_current_map_data"):
		print("Warning: Cannot access current map data")
		return
	
	var map_data = map_manager.get_current_map_data()
	if not map_data:
		return
	
	if map_data.has("interactable_data") and map_data.interactable_data.has("clipboard"):
		var clipboard_data = map_data.interactable_data.clipboard
		
		if clipboard_data.has("pages") and typeof(clipboard_data.pages) == TYPE_ARRAY:
			description_sets = clipboard_data.pages
			print("Loaded ", description_sets.size(), " pages from map data")
		
		if clipboard_data.has("title") and typeof(clipboard_data.title) == TYPE_STRING:
			title = clipboard_data.title

func _get_title_from_map_data() -> String:
	"""Get clipboard title from map data"""
	var map_manager = get_node_or_null("/root/GameManager")
	if not map_manager or not map_manager.has_method("get_current_map_data"):
		return "Code Snippets"
	
	var map_data = map_manager.get_current_map_data()
	if not map_data:
		return "Code Snippets"
	
	if map_data.has("interactable_data") and map_data.interactable_data.has("clipboard"):
		var clipboard_data = map_data.interactable_data.clipboard
		if clipboard_data.has("title"):
			return str(clipboard_data.title)
	
	return "Code Snippets"

func refresh_content() -> void:
	"""Refresh clipboard content from map data"""
	description_sets.clear()
	title = ""
	_load_from_map_data()
	if title.is_empty():
		title = _get_title_from_map_data()
	title_node.text = title
	current_index = 0
	if description_sets.size() > 0:
		_update_display()
	else:
		if description_rich_text:
			description_rich_text.bbcode_text = "[i]No content loaded[/i]"
		else:
			description_label.text = "No content loaded"

# Handle configuration from GridInteractablesComponent using # syntax
# This allows the clipboard to be configured directly from map layout
# Examples: "clipboard#pages:point,line,triangle" or "clipboard#title:My Title"
func apply_grid_config(config_data: Dictionary) -> void:
	print("Clipboard: Applying grid configuration: %s" % config_data)
	
	var needs_refresh = false
	
	# Handle pages configuration (comma-separated list of snippet keys)
	if config_data.has("pages"):
		var pages_config = str(config_data.pages)
		if pages_config.find(",") != -1:
			# Multiple pages specified as comma-separated list
			var page_keys = pages_config.split(",")
			description_sets.clear()
			for page_key in page_keys:
				var key = page_key.strip_edges()
				description_sets.append("Learn about %s: code#%s" % [key.capitalize(), key])
			print("  → Set pages from keys: %s" % str(page_keys))
		else:
			# Single page key
			description_sets.clear()
			description_sets.append("Learn about %s: code#%s" % [pages_config.capitalize(), pages_config])
			print("  → Set single page: %s" % pages_config)
		needs_refresh = true
	
	# Handle title configuration
	if config_data.has("title"):
		title = str(config_data.title)
		if title_node:
			title_node.text = title
		print("  → Set title: %s" % title)
	
	# Handle content configuration (raw content for pages)
	if config_data.has("content"):
		var content_config = str(config_data.content)
		if content_config.find("|") != -1:
			# Multiple pages separated by |
			description_sets = content_config.split("|")
			for i in range(description_sets.size()):
				description_sets[i] = description_sets[i].strip_edges()
		else:
			# Single content string
			description_sets = [content_config]
		print("  → Set content pages: %d" % description_sets.size())
		needs_refresh = true
	
	# Refresh display if needed
	if needs_refresh:
		current_index = 0
		if description_sets.size() > 0:
			_update_display()
		print("  → Refreshed clipboard display")
