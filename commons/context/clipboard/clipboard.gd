extends Node3D

const CodeSnippetLibrary := preload("res://commons/context/clipboard/code_snippet_library.gd")

@export var addxp: int = 20
@export var dessp: int = -2

@onready var title_node: Node = _first_existing_node([
	"GrabPlane/clipboard/ViewportDisplay/ContentViewport/ViewportRoot/Title",
	"GrabPlane/clipboard/page/Title"
])
@onready var description_plain_label: Node = _first_existing_node([
	"GrabPlane/clipboard/page/Description"
])
@onready var description_rich_text: RichTextLabel = _first_existing_node([
	"GrabPlane/clipboard/ViewportDisplay/ContentViewport/ViewportRoot/Description"
]) as RichTextLabel
@onready var grab_cube = $GrabPlane
@onready var label3D = $GrabPlane/clipboard/page/pagenumber
@onready var pagenumber = $GrabPlane/clipboard/page/pagenumber
@onready var grab_pos = grab_cube
@onready var _content_viewport: SubViewport = _first_existing_node([
	"GrabPlane/clipboard/ViewportDisplay/ContentViewport"
]) as SubViewport
@onready var _viewport_sprite: Sprite3D = _first_existing_node([
	"GrabPlane/clipboard/ViewportDisplay/ViewportSprite"
]) as Sprite3D

@export var title = ""
@export var description_sets: Array[String] = []
var current_index: int = 0
var is_executed = false
var _snippet_library := CodeSnippetLibrary.new()

var init_position: Vector3

func _ready() -> void:
	if _content_viewport and _viewport_sprite:
		_content_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_viewport_sprite.texture = _content_viewport.get_texture()

	if description_rich_text:
		description_rich_text.bbcode_enabled = true
		description_rich_text.fit_content = true
	else:
		_set_text(description_plain_label, "")

	var map_pages := _extract_pages_from_metadata()
	if map_pages.size() > 0:
		description_sets = map_pages

	if description_sets.size() == 0:
		_load_from_map_data()

	init_position = grab_pos.position

	if grab_cube.has_signal("item_dropped"):
		grab_cube.connect("item_dropped", Callable(self, "_on_item_dropped"))
		_set_text(label3D, "Grab me: " + str(init_position))
	else:
		print("GrabCube does not have 'item_dropped' signal!")
		if label3D:
			_set_text(label3D, "Error: 'item_dropped' signal missing!")

	if description_sets.size() > 0:
		_update_display()
	
	if title.is_empty():
		title = _get_title_from_map_data()
	_set_text(title_node, title)

func _on_item_dropped() -> void:
	if is_executed:
		_set_text(label3D, "Already read them")
		return

	is_executed = true
	var health = GameManager.get_health() + dessp
	GameManager.set_health(health)
	var xp = GameManager.get_xp() + addxp
	GameManager.set_xp(xp)
	_set_text(label3D, "XP/SP updated")

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
		_set_text(description_plain_label, _snippet_library.expand_to_plain(raw_text))

	_set_text(pagenumber, "(Page: %d of %d pages)" % [current_index + 1, description_sets.size()])

func _extract_pages_from_metadata() -> Array[String]:
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
			print("Loaded %d pages from map data" % description_sets.size())
		
		if clipboard_data.has("title") and typeof(clipboard_data.title) == TYPE_STRING:
			title = clipboard_data.title

func _get_title_from_map_data() -> String:
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
	description_sets.clear()
	title = ""
	_load_from_map_data()
	if title.is_empty():
		title = _get_title_from_map_data()
	_set_text(title_node, title)
	current_index = 0
	if description_sets.size() > 0:
		_update_display()
	else:
		if description_rich_text:
			description_rich_text.bbcode_text = "[i]No content loaded[/i]"
		else:
			_set_text(description_plain_label, "No content loaded")

func apply_grid_config(config_data: Dictionary) -> void:
	print("Clipboard: Applying grid configuration: %s" % config_data)
	var needs_refresh = false

	if config_data.has("pages"):
		var pages_config = str(config_data.pages)
		description_sets.clear()
		if pages_config.find(",") != -1:
			var page_keys = pages_config.split(",")
			for page_key in page_keys:
				var key = page_key.strip_edges()
				if key.is_empty():
					continue
				description_sets.append("code#%s" % key.to_lower())
			print("  -> Set pages from keys: %s" % str(page_keys))
		else:
			var single_key = pages_config.strip_edges()
			if not single_key.is_empty():
				description_sets.append("code#%s" % single_key.to_lower())
			print("  -> Set single page: %s" % pages_config)
		needs_refresh = true

	if config_data.has("title"):
		title = str(config_data.title)
		_set_text(title_node, title)
		print("  -> Set title: %s" % title)

	if config_data.has("content"):
		var content_config = str(config_data.content)
		if content_config.find("|") != -1:
			description_sets = content_config.split("|")
			for i in range(description_sets.size()):
				description_sets[i] = description_sets[i].strip_edges()
		else:
			description_sets = [content_config]
		print("  -> Set content pages: %d" % description_sets.size())
		needs_refresh = true

	if needs_refresh:
		current_index = 0
		if description_sets.size() > 0:
			_update_display()
		print("  -> Refreshed clipboard display")
func _first_existing_node(paths: Array[String]) -> Node:
	for path in paths:
		var node = get_node_or_null(path)
		if node:
			return node
	return null

func _set_text(target: Node, value: String) -> void:
	if target == null:
		return
	target.set("text", value)
