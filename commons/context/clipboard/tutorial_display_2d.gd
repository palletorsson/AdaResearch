extends Control

const TutorialTextLibrary := preload("res://commons/context/clipboard/tutorial_text_library.gd")
const TutorialTextDock := preload("res://addons/tutorial_text_editor/tutorial_text_dock.gd")

const TUTORIAL_JSON_PATH := "res://commons/context/clipboard/tutorial_text.json"
const SEQUENCE_ORDER: Array = TutorialTextDock.SEQUENCE_ORDER

@onready var _book_window: PanelContainer = %BookWindow
@onready var _example_list: ItemList = %ExampleList
@onready var _book_title: Label = %BookTitle
@onready var _book_meta: Label = %BookMeta
@onready var _book_content: RichTextLabel = %BookContent
@onready var _book_scroll: ScrollContainer = %BookScroll
@onready var _prev_button: Button = %PrevButton
@onready var _next_button: Button = %NextButton
@onready var _page_label: Label = %PageLabel

var _tutorial_library: TutorialTextLibrary
var _book_entries: Array = []
var _book_index: int = 0
var _sequence_index_cache: Dictionary = {}
var _next_sequence_index: int = 0

func _ready() -> void:
	_tutorial_library = TutorialTextLibrary.new()
	_sequence_index_cache.clear()
	_next_sequence_index = SEQUENCE_ORDER.size()
	_book_entries = _load_book_entries()

	_book_window.visible = true
	# Force centered 800px wide book window
	_book_window.anchor_left = 0.5
	_book_window.anchor_right = 0.5
	_book_window.offset_left = -400.0
	_book_window.offset_right = 400.0
	_book_window.anchor_top = 0.03
	_book_window.anchor_bottom = 0.97
	_book_window.offset_top = 0.0
	_book_window.offset_bottom = 0.0
	_book_window.custom_minimum_size.x = 800
	_prev_button.pressed.connect(_on_prev_page_pressed)
	_next_button.pressed.connect(_on_next_page_pressed)
	_example_list.item_selected.connect(_on_example_selected)

	_populate_example_list()
	_update_book_controls()

func _populate_example_list() -> void:
	_example_list.clear()
	if _book_entries.is_empty():
		_example_list.add_item("No tutorial examples found")
		_example_list.select(0)
	else:
		for entry in _book_entries:
			_example_list.add_item(_format_entry_label(entry))
		_example_list.select(0)

func _update_book_controls() -> void:
	var has_entries := _book_entries.size() > 0
	_prev_button.disabled = not has_entries
	_next_button.disabled = not has_entries

	if has_entries:
		_set_book_page(_book_index)
	else:
		_book_title.text = "No tutorials"
		_book_meta.text = "Add entries to tutorial_text.json to enable book mode"
		_book_content.bbcode_text = "[i]Book mode is empty.[/i]"
		_page_label.text = "Page 0 / 0"

func _on_prev_page_pressed() -> void:
	if _book_entries.is_empty():
		return
	_book_index = wrapi(_book_index - 1, 0, _book_entries.size())
	_set_book_page(_book_index)

func _on_next_page_pressed() -> void:
	if _book_entries.is_empty():
		return
	_book_index = wrapi(_book_index + 1, 0, _book_entries.size())
	_set_book_page(_book_index)

func _on_example_selected(index: int) -> void:
	if _book_entries.is_empty():
		return
	if index < 0 or index >= _book_entries.size():
		return
	_book_index = index
	_set_book_page(_book_index)

func _set_book_page(index: int) -> void:
	if _book_entries.is_empty():
		return
	_book_index = clamp(index, 0, _book_entries.size() - 1)
	var entry: Dictionary = _book_entries[_book_index]
	var tutorial_id: String = str(entry.get("id", ""))
	var readable_title := _prettify_id(tutorial_id)
	var order_value := float(entry.get("order", 0.0))
	var order_prefix := _format_order_prefix(order_value)
	if order_prefix.is_empty():
		_book_title.text = readable_title
	else:
		_book_title.text = "%s %s" % [order_prefix, readable_title]

	var sequence_text := str(entry.get("sequence", ""))
	var meta_bits: Array[String] = []
	meta_bits.append("Example ID: %s" % tutorial_id)
	if not order_prefix.is_empty():
		meta_bits.append("Order %s" % order_prefix)
	if not sequence_text.is_empty():
		meta_bits.append("Sequence: %s" % sequence_text)
	_book_meta.text = "    -    ".join(meta_bits)

	var content := _tutorial_library.get_tutorial_content(tutorial_id)
	if content.is_empty():
		_book_content.bbcode_text = "[i]No content found for %s[/i]" % tutorial_id
	else:
		_book_content.bbcode_text = content

	_page_label.text = _format_page_label(_book_index + 1, _book_entries.size(), order_value)
	if _example_list.item_count > _book_index:
		_example_list.select(_book_index)
		_example_list.ensure_current_is_visible()
	_book_scroll.scroll_vertical = 0

func _format_entry_label(entry: Dictionary) -> String:
	var tutorial_id: String = str(entry.get("id", ""))
	var pretty_name := _prettify_id(tutorial_id)
	var sequence_text := str(entry.get("sequence", ""))
	var order_value := float(entry.get("order", 0.0))
	var prefix := _format_order_prefix(order_value)
	var label: String
	if prefix.is_empty():
		label = pretty_name
	else:
		label = "%s %s" % [prefix, pretty_name]
	if sequence_text.is_empty():
		return label
	return "%s (%s)" % [label, sequence_text]

func _prettify_id(raw_id: String) -> String:
	if raw_id.is_empty():
		return "Untitled Example"
	var parts := raw_id.split("_")
	for i in range(parts.size()):
		var piece: String = parts[i]
		if piece.length() == 0:
			continue
		parts[i] = piece.substr(0, 1).to_upper() + piece.substr(1).to_lower()
	return " ".join(parts)

func _format_order_prefix(order_value: float) -> String:
	if is_zero_approx(order_value):
		return ""
	var rounded := int(round(order_value))
	if abs(order_value - float(rounded)) < 0.001:
		return "#%02d" % rounded
	return "#%s" % String.num(order_value, 2)

func _format_page_label(page_number: int, page_count: int, order_value: float) -> String:
	var base := "Page %d / %d" % [page_number, page_count]
	var prefix := _format_order_prefix(order_value)
	if prefix.is_empty():
		return base
	return "%s    %s" % [base, prefix]

func _load_book_entries() -> Array:
	var entries: Array = []
	var file := FileAccess.open(TUTORIAL_JSON_PATH, FileAccess.READ)
	if file == null:
		push_warning("BookMode: Cannot open %s" % TUTORIAL_JSON_PATH)
		return entries

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_text)
	if parse_result != OK:
		push_warning("BookMode: Failed to parse tutorial JSON (%s)" % json.get_error_message())
		return entries

	var data = json.data
	if not data.has("tutorials") or typeof(data.tutorials) != TYPE_DICTIONARY:
		push_warning("BookMode: tutorial_text.json missing 'tutorials' dictionary")
		return entries

	var tutorials: Dictionary = data.tutorials
	var position := 0
	for tutorial_id in tutorials.keys():
		var entry = tutorials[tutorial_id]
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var sequence_name := str(entry.get("sequence", ""))
		var order_value := float(entry.get("order", position))
		entries.append({
			"id": tutorial_id,
			"sequence": sequence_name,
			"order": order_value,
			"position": position
		})
		position += 1

	entries.sort_custom(Callable(self, "_compare_book_entries"))
	return entries

func _compare_book_entries(a: Dictionary, b: Dictionary) -> bool:
	var seq_a := _get_sequence_index(str(a.get("sequence", "")))
	var seq_b := _get_sequence_index(str(b.get("sequence", "")))
	if seq_a == seq_b:
		var order_a := float(a.get("order", 0.0))
		var order_b := float(b.get("order", 0.0))
		if is_equal_approx(order_a, order_b):
			var pos_a := int(a.get("position", 0))
			var pos_b := int(b.get("position", 0))
			if pos_a == pos_b:
				return str(a.get("id", "")) < str(b.get("id", ""))
			return pos_a < pos_b
		return order_a < order_b
	return seq_a < seq_b

func _get_sequence_index(sequence_name: String) -> int:
	var normalized := sequence_name.to_lower()
	if _sequence_index_cache.has(normalized):
		return int(_sequence_index_cache[normalized])

	var idx := SEQUENCE_ORDER.find(normalized)
	if idx == -1:
		idx = _next_sequence_index
		_next_sequence_index += 1
	_sequence_index_cache[normalized] = idx
	return idx
