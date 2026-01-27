# SoundBrowser.gd
# Tree-based sound browser with collapsible categories
# Used in AudioCatalogUI

extends Control
class_name SoundBrowser

signal sound_selected(sound_key: String)
signal sound_hovered(sound_key: String)

@export var category_color: Color = Color(0.6, 0.8, 1.0)
@export var sound_color: Color = Color(0.9, 0.9, 0.9)
@export var selected_color: Color = Color(0.2, 0.85, 1.0)

var _tree: Tree
var _category_items: Dictionary = {}  # category -> TreeItem
var _sound_items: Dictionary = {}     # sound_key -> TreeItem
var _current_selection: String = ""


func _ready():
	_setup_tree()


func _setup_tree():
	# Allow mouse events to pass to tree
	mouse_filter = Control.MOUSE_FILTER_PASS

	_tree = Tree.new()
	_tree.hide_root = true
	_tree.select_mode = Tree.SELECT_SINGLE
	_tree.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tree.item_selected.connect(_on_item_selected)
	_tree.item_activated.connect(_on_item_activated)
	# Enable scroll by click
	_tree.scroll_horizontal_enabled = false
	_tree.scroll_vertical_enabled = true

	# Style - scale up for larger viewport
	_tree.add_theme_color_override("font_color", sound_color)
	_tree.add_theme_color_override("font_selected_color", selected_color)
	_tree.add_theme_font_size_override("font_size", 24)

	add_child(_tree)


func populate(categories: Array[String]) -> void:
	_tree.clear()
	_category_items.clear()
	_sound_items.clear()

	var root := _tree.create_item()

	for category in categories:
		var cat_item := _tree.create_item(root)
		cat_item.set_text(0, category.capitalize())
		cat_item.set_custom_color(0, category_color)
		cat_item.set_collapsed(true)
		cat_item.set_selectable(0, false)  # Categories not selectable
		_category_items[category] = cat_item

		# Add sounds in this category
		var sounds := AudioCatalogDataProvider.get_sounds_by_category(category)
		for sound in sounds:
			var sound_item := _tree.create_item(cat_item)
			sound_item.set_text(0, sound.display_name)
			sound_item.set_metadata(0, sound.sound_key)
			_sound_items[sound.sound_key] = sound_item


func filter(query: String) -> void:
	if query.is_empty():
		# Show all, collapse categories
		for cat in _category_items:
			var cat_item: TreeItem = _category_items[cat]
			cat_item.visible = true
			cat_item.set_collapsed(true)
			var child := cat_item.get_first_child()
			while child:
				child.visible = true
				child = child.get_next()
		return

	# Filter by query
	var matching_sounds := AudioCatalogDataProvider.search_sounds(query)
	var matching_keys: Array[String] = []
	for sound in matching_sounds:
		matching_keys.append(sound.sound_key)

	# Hide non-matching sounds, expand categories with matches
	for cat in _category_items:
		var cat_item: TreeItem = _category_items[cat]
		var has_visible := false

		var child := cat_item.get_first_child()
		while child:
			var sound_key: String = child.get_metadata(0)
			var is_match := matching_keys.has(sound_key)
			child.visible = is_match
			if is_match:
				has_visible = true
			child = child.get_next()

		cat_item.visible = has_visible
		if has_visible:
			cat_item.set_collapsed(false)


func select_sound(sound_key: String) -> void:
	if _sound_items.has(sound_key):
		var item: TreeItem = _sound_items[sound_key]
		item.select(0)
		_current_selection = sound_key

		# Expand parent category
		var parent := item.get_parent()
		if parent:
			parent.set_collapsed(false)


func get_selected_sound() -> String:
	return _current_selection


func _on_item_selected() -> void:
	var selected := _tree.get_selected()
	if selected:
		var sound_key = selected.get_metadata(0)
		if sound_key:
			_current_selection = sound_key
			sound_selected.emit(sound_key)


func _on_item_activated() -> void:
	var selected := _tree.get_selected()
	if selected:
		var sound_key = selected.get_metadata(0)
		if sound_key:
			sound_selected.emit(sound_key)
		else:
			# Toggle category collapse
			selected.set_collapsed(not selected.is_collapsed())
