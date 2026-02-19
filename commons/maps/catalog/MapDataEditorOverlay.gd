class_name MapDataEditorOverlay
extends CanvasLayer

## Slide-down overlay for editing the current map's map_data.json.
## Toggle with J key. Loads the JSON when opened, saves on Ctrl+S.

@export var toggle_key: Key = KEY_J
@export var slide_duration: float = 0.25
@export var panel_height_ratio: float = 0.65  ## fraction of screen height

signal map_data_saved(map_name: String)

var _root: Control
var _backdrop: ColorRect
var _panel: PanelContainer
var _title_label: Label
var _path_label: Label
var _text_edit: TextEdit
var _status_label: Label
var _save_btn: Button
var _reload_btn: Button
var _close_btn: Button
var _format_btn: Button
var _search_bar: HBoxContainer
var _search_edit: LineEdit
var _current_map_name: String = ""
var _current_file_path: String = ""
var _is_open: bool = false
var _is_animating: bool = false
var _is_dirty: bool = false
var _tween: Tween = null

# Undo tracking — TextEdit has built-in undo but we also track the
# original text so we can show "dirty" state.
var _original_text: String = ""


func _ready() -> void:
	layer = 130  # above the map switcher overlay (120)
	visible = true
	_build_ui()
	_set_panel_hidden_immediate()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return

	# Don't intercept toggle when user is typing in another field
	if _is_foreign_text_focused():
		return

	# Toggle open/close
	if key.keycode == toggle_key or key.physical_keycode == toggle_key:
		_toggle()
		get_viewport().set_input_as_handled()
		return

	# Shortcuts only when open and our text edit has focus
	if not _is_open:
		return

	# Ctrl+S → save
	if key.ctrl_pressed and (key.keycode == KEY_S or key.physical_keycode == KEY_S):
		_save()
		get_viewport().set_input_as_handled()
		return

	# Ctrl+F → focus search
	if key.ctrl_pressed and (key.keycode == KEY_F or key.physical_keycode == KEY_F):
		if _search_edit:
			_search_edit.grab_focus()
			_search_edit.select_all()
		get_viewport().set_input_as_handled()
		return

	# Escape → close
	if key.keycode == KEY_ESCAPE:
		_toggle()
		get_viewport().set_input_as_handled()
		return


# ---------------------------------------------------------------------------
# Public API — called from MapCatalogDesktop3D / DesktopMapSwitcherOverlay
# ---------------------------------------------------------------------------

## Notify the editor which map is currently previewed.
## If already open, reloads the new map's data.
func set_current_map(map_name: String) -> void:
	if map_name == _current_map_name:
		return

	_current_map_name = map_name
	_current_file_path = _resolve_map_data_path(map_name)

	if _is_open:
		_load_file()


## Toggle overlay visibility.
func toggle() -> void:
	_toggle()


## Whether the overlay is currently shown.
func is_open() -> bool:
	return _is_open


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "EditorRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# Semi-transparent backdrop
	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.0, 0.0, 0.0, 0.45)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.gui_input.connect(_on_backdrop_clicked)
	_backdrop.visible = false
	_root.add_child(_backdrop)

	# Main panel — full width, slides down from top
	_panel = PanelContainer.new()
	_panel.name = "EditorPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.anchor_left = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 0.0
	_panel.offset_left = 0
	_panel.offset_right = 0
	_panel.offset_top = 0
	_panel.offset_bottom = 0
	_root.add_child(_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.055, 0.09, 0.96)
	panel_style.set_border_width_all(0)
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.22, 0.66, 0.98, 0.8)
	panel_style.set_corner_radius_all(0)
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	panel_style.shadow_size = 12
	_panel.add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 12)
	_panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 6)
	margin.add_child(vb)

	# --- Header row ---
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vb.add_child(header)

	_title_label = Label.new()
	_title_label.text = "map_data.json Editor"
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color(0.82, 0.93, 1.0))
	header.add_child(_title_label)

	_path_label = Label.new()
	_path_label.text = "(no map loaded)"
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_label.add_theme_font_size_override("font_size", 12)
	_path_label.add_theme_color_override("font_color", Color(0.5, 0.65, 0.8))
	_path_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(_path_label)

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(30, 30)
	_close_btn.pressed.connect(_toggle)
	_style_button(_close_btn)
	header.add_child(_close_btn)

	# --- Search bar ---
	_search_bar = HBoxContainer.new()
	_search_bar.add_theme_constant_override("separation", 6)
	vb.add_child(_search_bar)

	var search_label := Label.new()
	search_label.text = "Find:"
	search_label.add_theme_font_size_override("font_size", 12)
	search_label.add_theme_color_override("font_color", Color(0.6, 0.72, 0.85))
	_search_bar.add_child(search_label)

	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = "Search in JSON... (Enter=next, Shift+Enter=prev)"
	_search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_edit.custom_minimum_size = Vector2(0, 26)
	_search_edit.text_submitted.connect(_on_search_submitted)
	_search_bar.add_child(_search_edit)

	# --- Text editor ---
	_text_edit = TextEdit.new()
	_text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_NONE
	_text_edit.scroll_smooth = true
	_text_edit.syntax_highlighter = _create_json_highlighter()
	_text_edit.add_theme_font_size_override("font_size", 13)
	_text_edit.text_changed.connect(_on_text_changed)
	# Monospace feel via override (uses default monospace if available)
	_text_edit.add_theme_color_override("font_color", Color(0.88, 0.93, 0.98))
	_text_edit.add_theme_color_override("background_color", Color(0.02, 0.035, 0.06, 1.0))
	_text_edit.add_theme_color_override("current_line_color", Color(0.08, 0.12, 0.18, 1.0))
	_text_edit.add_theme_color_override("caret_color", Color(0.4, 0.8, 1.0))
	_text_edit.add_theme_color_override("selection_color", Color(0.15, 0.35, 0.55, 0.7))
	_text_edit.add_theme_constant_override("line_spacing", 2)
	vb.add_child(_text_edit)

	# --- Bottom action bar ---
	var action_bar := HBoxContainer.new()
	action_bar.add_theme_constant_override("separation", 8)
	vb.add_child(action_bar)

	_reload_btn = Button.new()
	_reload_btn.text = "↻ Reload"
	_reload_btn.pressed.connect(_load_file)
	_style_button(_reload_btn)
	action_bar.add_child(_reload_btn)

	_format_btn = Button.new()
	_format_btn.text = "{ } Format"
	_format_btn.pressed.connect(_format_json)
	_style_button(_format_btn)
	action_bar.add_child(_format_btn)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_bar.add_child(spacer)

	_status_label = Label.new()
	_status_label.text = "J to toggle | Ctrl+S save | Ctrl+F find"
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.5, 0.62, 0.75))
	action_bar.add_child(_status_label)

	# Spacer
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_bar.add_child(spacer2)

	_save_btn = Button.new()
	_save_btn.text = "💾 Save (Ctrl+S)"
	_save_btn.pressed.connect(_save)
	_style_button(_save_btn, true)
	action_bar.add_child(_save_btn)


# ---------------------------------------------------------------------------
# Slide animation
# ---------------------------------------------------------------------------

func _get_panel_height() -> float:
	var viewport_size := get_viewport().get_visible_rect().size
	return viewport_size.y * panel_height_ratio


func _set_panel_hidden_immediate() -> void:
	if not _panel:
		return
	var h := _get_panel_height()
	_panel.offset_top = -h
	_panel.offset_bottom = 0
	_panel.visible = false
	if _backdrop:
		_backdrop.visible = false


func _toggle() -> void:
	if _is_animating:
		return
	if _is_open:
		_slide_up()
	else:
		_slide_down()


func _slide_down() -> void:
	_is_open = true
	_is_animating = true
	var h := _get_panel_height()

	# Load data for current map
	_load_file()

	# Start hidden above
	_panel.offset_top = -h
	_panel.offset_bottom = 0
	_panel.visible = true
	if _backdrop:
		_backdrop.visible = true
		_backdrop.color.a = 0.0

	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.set_parallel(true)
	_tween.tween_property(_panel, "offset_top", 0.0, slide_duration)
	_tween.tween_property(_panel, "offset_bottom", h, slide_duration)
	if _backdrop:
		_tween.tween_property(_backdrop, "color:a", 0.45, slide_duration)
	_tween.set_parallel(false)
	_tween.tween_callback(func():
		_is_animating = false
		if _text_edit:
			_text_edit.grab_focus()
	)


func _slide_up() -> void:
	_is_open = false
	_is_animating = true
	var h := _get_panel_height()

	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.set_parallel(true)
	_tween.tween_property(_panel, "offset_top", -h, slide_duration)
	_tween.tween_property(_panel, "offset_bottom", 0.0, slide_duration)
	if _backdrop:
		_tween.tween_property(_backdrop, "color:a", 0.0, slide_duration)
	_tween.set_parallel(false)
	_tween.tween_callback(func():
		_is_animating = false
		_panel.visible = false
		if _backdrop:
			_backdrop.visible = false
	)


# ---------------------------------------------------------------------------
# File I/O
# ---------------------------------------------------------------------------

func _resolve_map_data_path(map_name: String) -> String:
	if map_name.is_empty():
		return ""

	var primary := "res://commons/maps/%s/map_data.json" % map_name
	if FileAccess.file_exists(primary):
		return primary

	var flat := "res://commons/maps/%s.json" % map_name
	if FileAccess.file_exists(flat):
		return flat

	return primary  # default even if not found yet


func _load_file() -> void:
	if _current_file_path.is_empty():
		_path_label.text = "(no map loaded)"
		_text_edit.text = ""
		_original_text = ""
		_is_dirty = false
		_update_title()
		_set_editor_status("No map selected. Load a map from the sidebar.")
		return

	_path_label.text = _current_file_path

	if not FileAccess.file_exists(_current_file_path):
		_text_edit.text = ""
		_original_text = ""
		_is_dirty = false
		_update_title()
		_set_editor_status("File not found: %s" % _current_file_path)
		return

	var file := FileAccess.open(_current_file_path, FileAccess.READ)
	if not file:
		_text_edit.text = ""
		_original_text = ""
		_is_dirty = false
		_update_title()
		_set_editor_status("Cannot read: %s" % _current_file_path)
		return

	var content := file.get_as_text()
	file.close()

	_text_edit.text = content
	_original_text = content
	_is_dirty = false
	_text_edit.clear_undo_history()
	_update_title()

	var line_count := content.count("\n") + 1
	_set_editor_status("Loaded %d lines from %s" % [line_count, _current_map_name])


func _save() -> void:
	if _current_file_path.is_empty():
		_set_editor_status("No file to save.")
		return

	var content := _text_edit.text

	# Validate JSON before saving
	var parser := JSON.new()
	if parser.parse(content) != OK:
		var err_line := parser.get_error_line()
		var err_msg := parser.get_error_message()
		_set_editor_status("JSON error line %d: %s — not saved!" % [err_line, err_msg])
		# Jump to error line
		if _text_edit and err_line > 0:
			_text_edit.set_caret_line(err_line - 1)
			_text_edit.center_viewport_to_caret()
		return

	var file := FileAccess.open(_current_file_path, FileAccess.WRITE)
	if not file:
		# Try globalizing
		var global_path := ProjectSettings.globalize_path(_current_file_path)
		file = FileAccess.open(global_path, FileAccess.WRITE)
		if not file:
			_set_editor_status("Cannot write to %s" % _current_file_path)
			return

	file.store_string(content)
	file.close()

	_original_text = content
	_is_dirty = false
	_update_title()
	_set_editor_status("Saved ✓ — %s" % _current_map_name)
	map_data_saved.emit(_current_map_name)


func _format_json() -> void:
	var content := _text_edit.text
	if content.strip_edges().is_empty():
		return

	var parser := JSON.new()
	if parser.parse(content) != OK:
		_set_editor_status("Cannot format: %s (line %d)" % [parser.get_error_message(), parser.get_error_line()])
		return

	var formatted := JSON.stringify(parser.data, "\t")
	# Compact leaf arrays onto single lines for readability
	formatted = _compact_inner_arrays(formatted)
	_text_edit.text = formatted
	_on_text_changed()
	_set_editor_status("Formatted JSON")


# ---------------------------------------------------------------------------
# Search
# ---------------------------------------------------------------------------

func _on_search_submitted(query: String) -> void:
	if query.is_empty() or not _text_edit:
		return

	var flags := 0  # case-insensitive
	var reverse := Input.is_key_pressed(KEY_SHIFT)

	var caret_line := _text_edit.get_caret_line()
	var caret_col := _text_edit.get_caret_column()

	# Start search from caret position
	var start_line := caret_line
	var start_col := caret_col + (0 if reverse else 1)

	var result: Vector2i
	if reverse:
		result = _search_backwards(query, start_line, start_col)
	else:
		result = _search_forward(query, start_line, start_col)

	if result.x >= 0:
		_text_edit.set_caret_line(result.x)
		_text_edit.set_caret_column(result.y)
		_text_edit.select(result.x, result.y, result.x, result.y + query.length())
		_text_edit.center_viewport_to_caret()
		_set_editor_status("Found at line %d" % (result.x + 1))
	else:
		_set_editor_status("'%s' not found" % query)


func _search_forward(query: String, from_line: int, from_col: int) -> Vector2i:
	var q := query.to_lower()
	var total := _text_edit.get_line_count()

	for i in range(total):
		var line_idx := (from_line + i) % total
		var line_text := _text_edit.get_line(line_idx).to_lower()
		var start := from_col if i == 0 else 0
		var found := line_text.find(q, start)
		if found >= 0:
			return Vector2i(line_idx, found)

	return Vector2i(-1, -1)


func _search_backwards(query: String, from_line: int, from_col: int) -> Vector2i:
	var q := query.to_lower()
	var total := _text_edit.get_line_count()

	for i in range(total):
		var line_idx := (from_line - i + total) % total
		var line_text := _text_edit.get_line(line_idx).to_lower()
		var end := from_col if i == 0 else line_text.length()
		var search_region := line_text.substr(0, end)
		var found := search_region.rfind(q)
		if found >= 0:
			return Vector2i(line_idx, found)

	return Vector2i(-1, -1)


# ---------------------------------------------------------------------------
# Change tracking
# ---------------------------------------------------------------------------

func _on_text_changed() -> void:
	_is_dirty = _text_edit.text != _original_text
	_update_title()


func _update_title() -> void:
	if not _title_label:
		return
	var dirty_marker := " •" if _is_dirty else ""
	if _current_map_name.is_empty():
		_title_label.text = "map_data.json Editor%s" % dirty_marker
	else:
		_title_label.text = "%s — map_data.json%s" % [_current_map_name, dirty_marker]


# ---------------------------------------------------------------------------
# Backdrop click closes
# ---------------------------------------------------------------------------

func _on_backdrop_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_toggle()


# ---------------------------------------------------------------------------
# JSON syntax highlighter (lightweight)
# ---------------------------------------------------------------------------

func _create_json_highlighter() -> CodeHighlighter:
	var hl := CodeHighlighter.new()
	hl.number_color = Color(0.72, 0.88, 0.55)       # green numbers
	hl.symbol_color = Color(0.55, 0.65, 0.78)        # grey symbols: { } [ ] , :
	hl.function_color = Color(0.55, 0.65, 0.78)      # not really used for JSON
	hl.member_variable_color = Color(0.55, 0.65, 0.78)

	# Strings — key vs value gets same color in CodeHighlighter;
	# we use color regions to distinguish.
	hl.add_color_region("\"", "\"", Color(0.8, 0.7, 0.5), false)  # warm gold for strings

	# true/false/null keywords
	hl.add_keyword_color("true", Color(0.6, 0.82, 1.0))
	hl.add_keyword_color("false", Color(0.6, 0.82, 1.0))
	hl.add_keyword_color("null", Color(0.75, 0.55, 0.75))

	return hl


# ---------------------------------------------------------------------------
# Compact inner arrays helper (same as MapCatalogDesktop3D)
# ---------------------------------------------------------------------------

static func _compact_inner_arrays(json: String) -> String:
	var regex := RegEx.new()
	regex.compile("\\[([^\\[\\]{}]+)\\]")
	var result := json
	var prev := ""
	while result != prev:
		prev = result
		for m in regex.search_all(result):
			var full_match: String = m.get_string()
			var inner: String = m.get_string(1)
			var compacted := inner.replace("\n", "").replace("\t", "").strip_edges()
			while compacted.contains("  "):
				compacted = compacted.replace("  ", " ")
			compacted = compacted.replace(", ", ",")
			result = result.replace(full_match, "[" + compacted + "]")
		break
	return result


# ---------------------------------------------------------------------------
# Styling (matches DesktopMapSwitcherOverlay theme)
# ---------------------------------------------------------------------------

func _style_button(button: Button, is_primary: bool = false) -> void:
	var base_bg := Color(0.08, 0.13, 0.2, 0.96)
	var hover_bg := Color(0.11, 0.18, 0.27, 0.98)
	var pressed_bg := Color(0.07, 0.12, 0.19, 0.98)
	var border := Color(0.2, 0.55, 0.82, 0.86)

	if is_primary:
		base_bg = Color(0.11, 0.3, 0.5, 0.98)
		hover_bg = Color(0.16, 0.39, 0.62, 0.98)
		pressed_bg = Color(0.09, 0.23, 0.38, 0.98)
		border = Color(0.44, 0.82, 1.0, 1.0)

	var normal := StyleBoxFlat.new()
	normal.bg_color = base_bg
	normal.set_border_width_all(1)
	normal.border_color = border
	normal.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = hover_bg
	hover.set_border_width_all(1)
	hover.border_color = border
	hover.set_corner_radius_all(8)
	button.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = pressed_bg
	pressed.set_border_width_all(1)
	pressed.border_color = border
	pressed.set_corner_radius_all(8)
	button.add_theme_stylebox_override("pressed", pressed)

	var focus := StyleBoxFlat.new()
	focus.bg_color = hover_bg
	focus.set_border_width_all(1)
	focus.border_color = Color(0.5, 0.86, 1.0, 1.0)
	focus.set_corner_radius_all(8)
	button.add_theme_stylebox_override("focus", focus)

	button.add_theme_color_override("font_color", Color(0.91, 0.97, 1.0))
	button.custom_minimum_size = Vector2(0, 30)
	button.add_theme_font_size_override("font_size", 12)


func _set_editor_status(text: String) -> void:
	if _status_label:
		_status_label.text = text


## Check if a text input OUTSIDE this overlay has focus.
func _is_foreign_text_focused() -> bool:
	var vp := get_viewport()
	if not vp:
		return false
	var focused := vp.gui_get_focus_owner()
	if focused == null:
		return false
	if focused is LineEdit or focused is TextEdit:
		# If it's our own controls, not foreign
		if focused == _text_edit or focused == _search_edit:
			return false
		return true
	return false
