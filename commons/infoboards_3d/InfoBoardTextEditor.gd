@tool
extends Control

## InfoBoard Text Editor - Select board and slide by number

const JSON_PATH = "res://commons/infoboards_3d/content/infoboard_content.json"

var json_data: Dictionary = {}
var current_board_id: String = ""
var current_page_index: int = 0

var board_selector: OptionButton
var slide_selector: SpinBox
var title_edit: LineEdit
var visual_id_edit: LineEdit
var concepts_edit: TextEdit
var axiom_edit: TextEdit
var narrative_edit: TextEdit
var steps_edit: TextEdit
var code_id_edit: LineEdit
var code_purpose_edit: LineEdit
var code_block_edit: TextEdit
var poetics_edit: TextEdit
var asset_edit: TextEdit
var files_edit: TextEdit
var info_label: Label

func _ready():
	if not Engine.is_editor_hint():
		return

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_vbox)

	info_label = Label.new()
	info_label.text = "Select a board and slide number"
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(info_label)

	main_vbox.add_child(HSeparator.new())

	var center_margin = MarginContainer.new()
	center_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_margin.add_theme_constant_override("margin_left", 20)
	center_margin.add_theme_constant_override("margin_right", 20)
	center_margin.add_theme_constant_override("margin_top", 20)
	center_margin.add_theme_constant_override("margin_bottom", 20)
	main_vbox.add_child(center_margin)

	# Layout columns inside scroll container
	var editor_scroll = ScrollContainer.new()
	editor_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor_scroll.custom_minimum_size = Vector2(640, 820)
	editor_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	editor_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	center_margin.add_child(editor_scroll)

	var editor_hbox = HBoxContainer.new()
	editor_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor_hbox.add_theme_constant_override("separation", 24)
	editor_scroll.add_child(editor_hbox)

	var left_column = VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.custom_minimum_size = Vector2(360, 0)
	editor_hbox.add_child(left_column)

	var right_column = VBoxContainer.new()
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.custom_minimum_size = Vector2(360, 0)
	editor_hbox.add_child(right_column)

	# Title section
	var title_label = Label.new()
	title_label.text = "Slide Title:"
	title_label.add_theme_font_size_override("font_size", 16)
	left_column.add_child(title_label)

	title_edit = LineEdit.new()
	title_edit.custom_minimum_size = Vector2(280, 35)
	title_edit.placeholder_text = "Enter slide title..."
	title_edit.text_changed.connect(_on_title_changed)
	left_column.add_child(title_edit)

	left_column.add_child(HSeparator.new())

	var visual_label = Label.new()
	visual_label.text = "Visual ID:"
	visual_label.add_theme_font_size_override("font_size", 14)
	left_column.add_child(visual_label)

	visual_id_edit = LineEdit.new()
	visual_id_edit.custom_minimum_size = Vector2(280, 30)
	visual_id_edit.placeholder_text = "e.g. origin, line_definition"
	visual_id_edit.text_changed.connect(_on_visual_id_changed)
	left_column.add_child(visual_id_edit)

	left_column.add_child(HSeparator.new())

	var concepts_label = Label.new()
	concepts_label.text = "Concepts (one per line):"
	concepts_label.add_theme_font_size_override("font_size", 14)
	left_column.add_child(concepts_label)

	concepts_edit = TextEdit.new()
	concepts_edit.custom_minimum_size = Vector2(280, 90)
	concepts_edit.wrap_mode = TextEdit.LINE_WRAPPING_NONE
	concepts_edit.placeholder_text = "Vector3\norigin\ncoordinate system"
	concepts_edit.text_changed.connect(_on_concepts_changed)
	left_column.add_child(concepts_edit)

	left_column.add_child(HSeparator.new())

	var axiom_label = Label.new()
	axiom_label.text = "Axiom:"
	axiom_label.add_theme_font_size_override("font_size", 14)
	left_column.add_child(axiom_label)

	axiom_edit = TextEdit.new()
	axiom_edit.custom_minimum_size = Vector2(280, 90)
	axiom_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	axiom_edit.text_changed.connect(_on_axiom_changed)
	left_column.add_child(axiom_edit)

	left_column.add_child(HSeparator.new())

	var narrative_label = Label.new()
	narrative_label.text = "Narrative (paragraphs separated by blank line):"
	narrative_label.add_theme_font_size_override("font_size", 14)
	left_column.add_child(narrative_label)

	narrative_edit = TextEdit.new()
	narrative_edit.custom_minimum_size = Vector2(280, 120)
	narrative_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	narrative_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	narrative_edit.text_changed.connect(_on_narrative_changed)
	left_column.add_child(narrative_edit)

	# Steps and code
	var steps_label = Label.new()
	steps_label.text = "Steps (one per line):"
	steps_label.add_theme_font_size_override("font_size", 14)
	right_column.add_child(steps_label)

	steps_edit = TextEdit.new()
	steps_edit.custom_minimum_size = Vector2(280, 90)
	steps_edit.wrap_mode = TextEdit.LINE_WRAPPING_NONE
	steps_edit.text_changed.connect(_on_steps_changed)
	right_column.add_child(steps_edit)

	right_column.add_child(HSeparator.new())

	var code_header = HBoxContainer.new()
	code_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_column.add_child(code_header)

	var code_id_label = Label.new()
	code_id_label.text = "Code ID:"
	code_header.add_child(code_id_label)

	code_id_edit = LineEdit.new()
	code_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_id_edit.text_changed.connect(_on_code_id_changed)
	code_header.add_child(code_id_edit)

	var code_purpose_label = Label.new()
	code_purpose_label.text = "Purpose:"
	code_header.add_child(code_purpose_label)

	code_purpose_edit = LineEdit.new()
	code_purpose_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_purpose_edit.placeholder_text = "optional description"
	code_purpose_edit.text_changed.connect(_on_code_purpose_changed)
	code_header.add_child(code_purpose_edit)

	var code_block_label = Label.new()
	code_block_label.text = "Code Block:"
	code_block_label.add_theme_font_size_override("font_size", 14)
	right_column.add_child(code_block_label)

	code_block_edit = TextEdit.new()
	code_block_edit.custom_minimum_size = Vector2(280, 200)
	code_block_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	code_block_edit.wrap_mode = TextEdit.LINE_WRAPPING_NONE
	code_block_edit.text_changed.connect(_on_code_block_changed)
	right_column.add_child(code_block_edit)

	right_column.add_child(HSeparator.new())

	var poetics_label = Label.new()
	poetics_label.text = "Poetics:"
	poetics_label.add_theme_font_size_override("font_size", 14)
	right_column.add_child(poetics_label)

	poetics_edit = TextEdit.new()
	poetics_edit.custom_minimum_size = Vector2(280, 100)
	poetics_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	poetics_edit.text_changed.connect(_on_poetics_changed)
	right_column.add_child(poetics_edit)

	right_column.add_child(HSeparator.new())

	var asset_label = Label.new()
	asset_label.text = "Visualization Asset Notes:"
	asset_label.add_theme_font_size_override("font_size", 14)
	right_column.add_child(asset_label)

	asset_edit = TextEdit.new()
	asset_edit.custom_minimum_size = Vector2(280, 90)
	asset_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	asset_edit.placeholder_text = "Describe how the visualization manifests..."
	asset_edit.text_changed.connect(_on_asset_changed)
	right_column.add_child(asset_edit)

	right_column.add_child(HSeparator.new())

	var files_label = Label.new()
	files_label.text = "Visualization Files (one per line):"
	files_label.add_theme_font_size_override("font_size", 14)
	right_column.add_child(files_label)

	files_edit = TextEdit.new()
	files_edit.custom_minimum_size = Vector2(280, 90)
	files_edit.wrap_mode = TextEdit.LINE_WRAPPING_NONE
	files_edit.placeholder_text = "res://path/to/file.tscn\nres://path/to/file.gd"
	files_edit.text_changed.connect(_on_files_changed)
	right_column.add_child(files_edit)

	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(bottom_hbox)

	var board_label = Label.new()
	board_label.text = "Board:"
	board_label.custom_minimum_size = Vector2(90, 0)
	bottom_hbox.add_child(board_label)

	board_selector = OptionButton.new()
	board_selector.custom_minimum_size = Vector2(220, 30)
	board_selector.item_selected.connect(_on_board_selected)
	bottom_hbox.add_child(board_selector)

	var slide_label = Label.new()
	slide_label.text = "Slide:"
	slide_label.custom_minimum_size = Vector2(60, 0)
	bottom_hbox.add_child(slide_label)

	slide_selector = SpinBox.new()
	slide_selector.min_value = 1
	slide_selector.max_value = 1
	slide_selector.value = 1
	slide_selector.value_changed.connect(_on_slide_selected)
	bottom_hbox.add_child(slide_selector)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(spacer)

	var reload_btn = Button.new()
	reload_btn.text = "Reload JSON"
	reload_btn.pressed.connect(_on_reload)
	bottom_hbox.add_child(reload_btn)

	var save_btn = Button.new()
	save_btn.text = "Save JSON"
	save_btn.pressed.connect(_on_save)
	bottom_hbox.add_child(save_btn)

	load_json()
	populate_board_selector()
	
func _on_reload():
	load_json()
	populate_board_selector()
	if current_board_id.is_empty() and board_selector.item_count > 0:
		_on_board_selected(board_selector.selected)
	else:
		load_current_slide()
	info_label.text = "Reloaded content"

func load_json():
	var file = FileAccess.open(JSON_PATH, FileAccess.READ)
	if not file:
		push_error("Cannot open " + JSON_PATH)
		return

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()

	if error == OK:
		json_data = json.data
		print("Loaded JSON successfully")
	else:
		push_error("JSON parse error: " + json.get_error_message())

func populate_board_selector():
	if not json_data.has("boards"):
		return

	board_selector.clear()

	var boards = json_data["boards"]
	var progression = json_data.get("_meta", {}).get("progression", [])

	var index = 0
	for board_id in progression:
		if not boards.has(board_id):
			continue

		var board_data = boards[board_id]
		var pages = board_data.get("pages", [])
		if pages.is_empty():
			continue

		var title = board_data.get("title", board_id)
		board_selector.add_item(title + " (" + str(pages.size()) + " slides)")
		board_selector.set_item_metadata(index, board_id)
		index += 1

	if board_selector.item_count > 0:
		board_selector.selected = 0
		_on_board_selected(0)

func _on_board_selected(index: int):
	current_board_id = board_selector.get_item_metadata(index)

	var boards = json_data["boards"]
	var board_data = boards[current_board_id]
	var pages = board_data.get("pages", [])

	# Update slide selector range
	slide_selector.max_value = pages.size()
	slide_selector.value = 1
	current_page_index = 0

	# Update info
	info_label.text = "%s - %s" % [board_data.get("title", ""), board_data.get("subtitle", "")]

	load_current_slide()

func _on_slide_selected(value: float):
	current_page_index = int(value) - 1
	load_current_slide()

func load_current_slide():
	if current_board_id.is_empty():
		return

	var boards = json_data.get("boards", {})
	if not boards.has(current_board_id):
		return

	var board_data: Dictionary = boards[current_board_id]
	var pages: Array = board_data.get("pages", [])

	if current_page_index < 0 or current_page_index >= pages.size():
		return

	var page: Dictionary = pages[current_page_index]

	# Disconnect signals temporarily
	title_edit.text_changed.disconnect(_on_title_changed)
	visual_id_edit.text_changed.disconnect(_on_visual_id_changed)
	concepts_edit.text_changed.disconnect(_on_concepts_changed)
	axiom_edit.text_changed.disconnect(_on_axiom_changed)
	narrative_edit.text_changed.disconnect(_on_narrative_changed)
	steps_edit.text_changed.disconnect(_on_steps_changed)
	code_id_edit.text_changed.disconnect(_on_code_id_changed)
	code_purpose_edit.text_changed.disconnect(_on_code_purpose_changed)
	code_block_edit.text_changed.disconnect(_on_code_block_changed)
	poetics_edit.text_changed.disconnect(_on_poetics_changed)
	asset_edit.text_changed.disconnect(_on_asset_changed)
	files_edit.text_changed.disconnect(_on_files_changed)

	# Load data into UI
	title_edit.text = page.get("title", "")

	var visualization = page.get("visualization", {})
	var visual_id = page.get("visual_id", "")
	if visualization is Dictionary:
		visual_id = visualization.get("id", visual_id)
	visual_id_edit.text = visual_id

	var concepts = page.get("concepts", [])
	if concepts is Array:
		concepts_edit.text = _join_lines(concepts, "\n")
	else:
		concepts_edit.text = ""

	axiom_edit.text = page.get("axiom", "")

	var narrative_array = page.get("narrative", [])
	if narrative_array is Array:
		narrative_edit.text = _join_lines(narrative_array, "\n\n")
	else:
		narrative_edit.text = ""

	var steps_array = page.get("steps", [])
	if steps_array is Array:
		steps_edit.text = _join_lines(steps_array, "\n")
	else:
		steps_edit.text = ""

	var code_dict = page.get("code", {})
	var code_id = ""
	var code_purpose = ""
	var code_block = ""
	if code_dict is Dictionary:
		code_id = code_dict.get("id", "")
		code_purpose = code_dict.get("purpose", "")
		code_block = code_dict.get("block", "")
	code_id_edit.text = code_id
	code_purpose_edit.text = code_purpose
	code_block_edit.text = code_block

	poetics_edit.text = page.get("poetics", "")

	var asset_text = ""
	var files_list: Array = []
	if visualization is Dictionary:
		asset_text = visualization.get("asset", "")
		var files_value = visualization.get("files", [])
		if files_value is Array:
			files_list = files_value
	asset_edit.text = asset_text
	files_edit.text = _join_lines(files_list, "\n")

	# Reconnect signals
	title_edit.text_changed.connect(_on_title_changed)
	visual_id_edit.text_changed.connect(_on_visual_id_changed)
	concepts_edit.text_changed.connect(_on_concepts_changed)
	axiom_edit.text_changed.connect(_on_axiom_changed)
	narrative_edit.text_changed.connect(_on_narrative_changed)
	steps_edit.text_changed.connect(_on_steps_changed)
	code_id_edit.text_changed.connect(_on_code_id_changed)
	code_purpose_edit.text_changed.connect(_on_code_purpose_changed)
	code_block_edit.text_changed.connect(_on_code_block_changed)
	poetics_edit.text_changed.connect(_on_poetics_changed)
	asset_edit.text_changed.connect(_on_asset_changed)
	files_edit.text_changed.connect(_on_files_changed)

	print("Loaded slide %d: %s" % [current_page_index + 1, page.get("title", "")])

func _get_current_page() -> Dictionary:
	if current_board_id.is_empty():
		return {}
	var boards = json_data.get("boards", {})
	if not boards.has(current_board_id):
		return {}
	var pages: Array = boards[current_board_id].get("pages", [])
	if current_page_index < 0 or current_page_index >= pages.size():
		return {}
	return pages[current_page_index]

func _ensure_visualization_dict(page: Dictionary) -> Dictionary:
	var visualization = page.get("visualization", {})
	if not (visualization is Dictionary):
		visualization = {}
	if not visualization.has("id"):
		visualization["id"] = page.get("visual_id", "")
	if not visualization.has("asset"):
		visualization["asset"] = ""
	if not visualization.has("files"):
		visualization["files"] = []
	page["visualization"] = visualization
	return visualization

func _ensure_code_dict(page: Dictionary) -> Dictionary:
	var code_dict = page.get("code", {})
	if not (code_dict is Dictionary):
		code_dict = {}
	if not code_dict.has("language"):
		code_dict["language"] = "gdscript"
	if not code_dict.has("purpose"):
		code_dict["purpose"] = ""
	if not code_dict.has("id"):
		code_dict["id"] = ""
	if not code_dict.has("block"):
		code_dict["block"] = ""
	page["code"] = code_dict
	return code_dict

func _parse_paragraphs(source: String) -> Array:
	var paragraphs: Array = []
	var buffer: Array = []
	for line in source.split("\n"):
		var trimmed = line.strip_edges()
		if trimmed.is_empty():
			if buffer.size() > 0:
				paragraphs.append(_join_buffer(buffer))
				buffer.clear()
		else:
			buffer.append(trimmed)
	if buffer.size() > 0:
		paragraphs.append(_join_buffer(buffer))
	return paragraphs

func _join_buffer(buffer: Array) -> String:
	var result := ""
	for segment in buffer:
		var text_value = segment
		if typeof(text_value) != TYPE_STRING:
			text_value = str(text_value)
		if result.is_empty():
			result = text_value
		else:
			result += " " + text_value
	return result

func _parse_lines(source: String) -> Array:
	var items: Array = []
	for line in source.split("\n"):
		var trimmed = line.strip_edges()
		if not trimmed.is_empty():
			items.append(trimmed)
	return items

func _join_lines(items: Array, separator: String) -> String:
	var result := ""
	for segment in items:
		var text_value = segment
		if typeof(text_value) != TYPE_STRING:
			text_value = str(text_value)
		if result.is_empty():
			result = text_value
		else:
			result += separator + text_value
	return result

func _on_title_changed(new_text: String):
	var page = _get_current_page()
	if page.is_empty():
		return
	page["title"] = new_text

func _on_visual_id_changed(new_text: String):
	var page = _get_current_page()
	if page.is_empty():
		return
	page["visual_id"] = new_text
	var visualization = _ensure_visualization_dict(page)
	visualization["id"] = new_text

func _on_concepts_changed():
	var page = _get_current_page()
	if page.is_empty():
		return
	page["concepts"] = _parse_lines(concepts_edit.text)

func _on_axiom_changed():
	var page = _get_current_page()
	if page.is_empty():
		return
	page["axiom"] = axiom_edit.text

func _on_narrative_changed():
	var page = _get_current_page()
	if page.is_empty():
		return
	page["narrative"] = _parse_paragraphs(narrative_edit.text)

func _on_steps_changed():
	var page = _get_current_page()
	if page.is_empty():
		return
	page["steps"] = _parse_lines(steps_edit.text)

func _on_code_id_changed(new_text: String):
	var page = _get_current_page()
	if page.is_empty():
		return
	var code_dict = _ensure_code_dict(page)
	code_dict["id"] = new_text

func _on_code_purpose_changed(new_text: String):
	var page = _get_current_page()
	if page.is_empty():
		return
	var code_dict = _ensure_code_dict(page)
	code_dict["purpose"] = new_text

func _on_code_block_changed():
	var page = _get_current_page()
	if page.is_empty():
		return
	var code_dict = _ensure_code_dict(page)
	code_dict["block"] = code_block_edit.text

func _on_poetics_changed():
	var page = _get_current_page()
	if page.is_empty():
		return
	page["poetics"] = poetics_edit.text

func _on_asset_changed():
	var page = _get_current_page()
	if page.is_empty():
		return
	var visualization = _ensure_visualization_dict(page)
	visualization["asset"] = asset_edit.text

func _on_files_changed():
	var page = _get_current_page()
	if page.is_empty():
		return
	var visualization = _ensure_visualization_dict(page)
	var files_array: Array = []
	for line in files_edit.text.split("\n"):
		var trimmed = line.strip_edges()
		if not trimmed.is_empty():
			files_array.append(trimmed)
	visualization["files"] = files_array

func _on_save():
	var json_string = JSON.stringify(json_data, "\t")
	var file = FileAccess.open(JSON_PATH, FileAccess.WRITE)

	if file:
		file.store_string(json_string)
		file.close()
		info_label.text = "Ã¢Å“â€œ Saved successfully!"
		print("Saved successfully!")
	else:
		push_error("Cannot write to " + JSON_PATH)
		info_label.text = "Ã¢Å“â€” Error saving file"
