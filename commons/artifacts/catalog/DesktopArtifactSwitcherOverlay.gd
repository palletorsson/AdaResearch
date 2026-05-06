class_name DesktopArtifactSwitcherOverlay
extends CanvasLayer

## 2D desktop sidebar for browsing artifacts — same layout as DesktopMapSwitcherOverlay.
## Groups artifacts by sequence, collapsible sections, click to preview in 3D.

signal artifact_selected(lookup_name: String)

const COMMENT_DEFAULT_MARKDOWN_PATH := "res://ada_run/desktop_feedback.md"

@export var toggle_key: Key = KEY_M
@export var open_on_start: bool = true

var _root: Control
var _panel: PanelContainer
var _comment_panel: PanelContainer
var _filter_edit: LineEdit
var _status_label: Label
var _count_label: Label
var _hint_label: Label
var _catalog_scroll: ScrollContainer
var _catalog_content: VBoxContainer
var _quick_buttons: Dictionary = {}  # "seq|lookup" -> Button
var _sequence_sections: Dictionary = {}  # seq_name -> { "header": Button, "flow": VBoxContainer }
var _comment_context_label: Label
var _comment_text_edit: TextEdit
var _comment_status_label: Label

static var last_comment_draft: String = ""

static var last_filter_text: String = ""
static var last_collapsed_sequences: Dictionary = {}
static var last_selected_lookup: String = ""

var _artifacts_by_sequence: Dictionary = {}  # seq_name -> Array[Dictionary]
var _all_artifacts: Array = []
var _sequence_names: Array[String] = []

func _ready() -> void:
	layer = 120
	visible = true
	_build_ui()
	_reload_data()
	if _panel:
		_panel.visible = open_on_start

func _input(event: InputEvent) -> void:
	if _is_text_input_focused():
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == toggle_key or key_event.physical_keycode == toggle_key:
				_toggle_overlay()
				get_viewport().set_input_as_handled()

func _is_text_input_focused() -> bool:
	var viewport := get_viewport()
	if not viewport:
		return false
	var focused := viewport.gui_get_focus_owner()
	return focused is LineEdit or focused is TextEdit

func _toggle_overlay() -> void:
	if _panel:
		_panel.visible = not _panel.visible
		if _comment_panel:
			_comment_panel.visible = _panel.visible
		if _panel.visible:
			_reload_data()

## Returns true when the mouse cursor is over the sidebar or comment panel.
func is_mouse_over_panel() -> bool:
	if _panel and _panel.visible:
		var mouse_pos := _panel.get_global_mouse_position()
		if _panel.get_global_rect().has_point(mouse_pos):
			return true
	if _comment_panel and _comment_panel.visible:
		var mouse_pos := _comment_panel.get_global_mouse_position()
		if _comment_panel.get_global_rect().has_point(mouse_pos):
			return true
	return false

# ---------------------------------------------------------------------------
# UI BUILD
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_left_panel()
	_build_comment_panel()

func _build_left_panel() -> void:
	_panel = PanelContainer.new()
	_panel.name = "ArtifactPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	# 250px sidebar, full height
	_panel.anchor_left = 0.0
	_panel.anchor_top = 0.0
	_panel.anchor_right = 0.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 0
	_panel.offset_top = 0
	_panel.offset_right = 250
	_panel.offset_bottom = 0
	_root.add_child(_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.06, 0.10, 0.92)
	panel_style.set_border_width_all(0)
	panel_style.border_width_right = 1
	panel_style.border_color = Color(0.22, 0.66, 0.98, 0.6)
	panel_style.set_corner_radius_all(0)
	_panel.add_theme_stylebox_override("panel", panel_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	_panel.add_child(margin)

	var outer_vb = VBoxContainer.new()
	outer_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vb.add_theme_constant_override("separation", 4)
	margin.add_child(outer_vb)

	# ---- Title ----
	var title = Label.new()
	title.text = "Artifacts"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.82, 0.90, 1.0, 1.0))
	outer_vb.add_child(title)

	# ---- Filter / search ----
	var filter_row = HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 4)
	outer_vb.add_child(filter_row)

	_filter_edit = LineEdit.new()
	_filter_edit.placeholder_text = "Filter..."
	_filter_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter_edit.custom_minimum_size = Vector2(0, 26)
	_filter_edit.text = last_filter_text
	_filter_edit.text_changed.connect(_on_filter_text_changed)
	filter_row.add_child(_filter_edit)

	var clear_filter_btn = Button.new()
	clear_filter_btn.text = "✕"
	clear_filter_btn.custom_minimum_size = Vector2(26, 26)
	clear_filter_btn.pressed.connect(_on_clear_filter_pressed)
	_style_button(clear_filter_btn)
	filter_row.add_child(clear_filter_btn)

	# ---- Count label ----
	_count_label = Label.new()
	_count_label.text = ""
	_count_label.add_theme_font_size_override("font_size", 11)
	_count_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.78, 1.0))
	outer_vb.add_child(_count_label)

	# ---- Catalog scroll area ----
	_catalog_scroll = ScrollContainer.new()
	_catalog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_catalog_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_catalog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer_vb.add_child(_catalog_scroll)

	_catalog_content = VBoxContainer.new()
	_catalog_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_catalog_content.add_theme_constant_override("separation", 1)
	_catalog_scroll.add_child(_catalog_content)

	# ---- Status line ----
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_font_size_override("font_size", 10)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_color", Color(0.55, 0.68, 0.82, 1.0))
	outer_vb.add_child(_status_label)

	# ---- Hint label ----
	_hint_label = Label.new()
	_hint_label.text = "M toggle | Click to preview | Scroll zoom"
	_hint_label.add_theme_font_size_override("font_size", 10)
	_hint_label.modulate = Color(0.50, 0.58, 0.70, 1.0)
	outer_vb.add_child(_hint_label)

# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------

func _reload_data() -> void:
	_artifacts_by_sequence.clear()
	_sequence_names.clear()
	_all_artifacts = ArtifactCatalogDataProvider.get_all_artifacts()

	# Group artifacts by their primary sequence
	var unsorted: Array = []
	for art in _all_artifacts:
		if not (art is Dictionary):
			continue
		var seq: String = str(art.get("sequence", "")).strip_edges()
		if seq.is_empty():
			# Try first entry of map_sequences
			var seqs = art.get("map_sequences", [])
			if seqs is Array and seqs.size() > 0:
				seq = str(seqs[0]).strip_edges()
		if seq.is_empty():
			seq = "ungrouped"
		if not _artifacts_by_sequence.has(seq):
			_artifacts_by_sequence[seq] = []
		(_artifacts_by_sequence[seq] as Array).append(art)

	# Collect and sort sequence names
	for key in _artifacts_by_sequence.keys():
		_sequence_names.append(str(key))
	_sequence_names.sort()
	# Move "ungrouped" to end
	if _sequence_names.has("ungrouped"):
		_sequence_names.erase("ungrouped")
		_sequence_names.append("ungrouped")

	_rebuild_catalog_buttons()
	_count_label.text = "%d artifacts · %d groups" % [_all_artifacts.size(), _sequence_names.size()]
	_status_label.text = "Loaded %d artifacts" % _all_artifacts.size()

# ---------------------------------------------------------------------------
# Catalog buttons (collapsible sections, same style as DesktopMapSwitcherOverlay)
# ---------------------------------------------------------------------------

func _rebuild_catalog_buttons() -> void:
	if not _catalog_content:
		return

	for child_candidate in _catalog_content.get_children():
		if child_candidate is Node:
			(child_candidate as Node).queue_free()

	_quick_buttons.clear()
	_sequence_sections.clear()

	for seq_name in _sequence_names:
		var arts: Array = _artifacts_by_sequence.get(seq_name, [])
		if arts.is_empty():
			continue

		# Sort artifacts by name within each sequence
		arts.sort_custom(func(a, b):
			var a_name := str((a as Dictionary).get("name", (a as Dictionary).get("lookup_name", ""))).to_lower()
			var b_name := str((b as Dictionary).get("name", (b as Dictionary).get("lookup_name", ""))).to_lower()
			return a_name < b_name
		)

		var section = VBoxContainer.new()
		section.add_theme_constant_override("separation", 0)
		_catalog_content.add_child(section)

		# Collapsible header
		var is_collapsed: bool = last_collapsed_sequences.get(seq_name, true)
		var header_btn = Button.new()
		header_btn.text = "%s %s (%d)" % ["▾" if not is_collapsed else "▸", _format_name(seq_name), arts.size()]
		header_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		header_btn.pressed.connect(_on_section_header_pressed.bind(seq_name))
		_style_section_header(header_btn)
		section.add_child(header_btn)

		# Artifact list
		var art_list = VBoxContainer.new()
		art_list.add_theme_constant_override("separation", 0)
		art_list.visible = not is_collapsed
		section.add_child(art_list)

		_sequence_sections[seq_name] = {"header": header_btn, "flow": art_list, "section": section}

		for art in arts:
			var lookup_name: String = str(art.get("lookup_name", ""))
			var display_name: String = str(art.get("name", lookup_name))
			if lookup_name.is_empty():
				continue

			var art_btn = Button.new()
			art_btn.text = display_name
			art_btn.tooltip_text = str(art.get("description", ""))
			art_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			art_btn.custom_minimum_size = Vector2(0, 20)
			art_btn.pressed.connect(_on_artifact_button_pressed.bind(lookup_name))
			_style_map_item(art_btn, lookup_name == last_selected_lookup)
			art_list.add_child(art_btn)
			_quick_buttons["%s|%s" % [seq_name, lookup_name]] = art_btn

	_apply_filter(last_filter_text)

# ---------------------------------------------------------------------------
# Callbacks
# ---------------------------------------------------------------------------

func _on_artifact_button_pressed(lookup_name: String) -> void:
	last_selected_lookup = lookup_name
	_update_button_highlights()
	_refresh_comment_context()
	artifact_selected.emit(lookup_name)

func _on_section_header_pressed(seq_name: String) -> void:
	if not _sequence_sections.has(seq_name):
		return

	var section_data: Dictionary = _sequence_sections[seq_name]
	var art_list: VBoxContainer = section_data.get("flow") as VBoxContainer
	var header_btn: Button = section_data.get("header") as Button
	if not art_list or not header_btn:
		return

	var arts: Array = _artifacts_by_sequence.get(seq_name, [])
	var is_now_collapsed := art_list.visible
	art_list.visible = not is_now_collapsed
	last_collapsed_sequences[seq_name] = is_now_collapsed
	header_btn.text = "%s %s (%d)" % ["▾" if not is_now_collapsed else "▸", _format_name(seq_name), arts.size()]

func _update_button_highlights() -> void:
	for key in _quick_buttons.keys():
		var btn: Button = _quick_buttons[key] as Button
		if not btn:
			continue
		var parts: PackedStringArray = str(key).split("|")
		if parts.size() == 2:
			var is_selected: bool = parts[1] == last_selected_lookup
			_style_map_item(btn, is_selected)

# ---------------------------------------------------------------------------
# Filter
# ---------------------------------------------------------------------------

func _on_filter_text_changed(new_text: String) -> void:
	last_filter_text = new_text
	_apply_filter(new_text)

func _on_clear_filter_pressed() -> void:
	_filter_edit.text = ""
	last_filter_text = ""
	_apply_filter("")

func _apply_filter(text: String) -> void:
	var search := text.strip_edges().to_lower()
	var visible_count := 0

	for seq_name in _sequence_sections.keys():
		var section_data: Dictionary = _sequence_sections[seq_name]
		var art_list: VBoxContainer = section_data.get("flow") as VBoxContainer
		var header_btn: Button = section_data.get("header") as Button
		var section: VBoxContainer = section_data.get("section") as VBoxContainer
		if not art_list or not section:
			continue

		var any_visible := false
		for child in art_list.get_children():
			if child is Button:
				var btn := child as Button
				if search.is_empty():
					btn.visible = true
					any_visible = true
					visible_count += 1
				else:
					var matches := btn.text.to_lower().find(search) >= 0 or btn.tooltip_text.to_lower().find(search) >= 0
					btn.visible = matches
					if matches:
						any_visible = true
						visible_count += 1

		section.visible = any_visible or search.is_empty()
		# Auto-expand sections that have matches when filtering
		if not search.is_empty() and any_visible and art_list:
			art_list.visible = true
			if header_btn:
				var arts: Array = _artifacts_by_sequence.get(seq_name, [])
				header_btn.text = "▾ %s (%d)" % [_format_name(seq_name), arts.size()]

	if not search.is_empty():
		_count_label.text = "%d matching" % visible_count

# ---------------------------------------------------------------------------
# Styling (matches DesktopMapSwitcherOverlay)
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

	button.add_theme_color_override("font_color", Color(0.91, 0.97, 1.0, 1.0))
	button.custom_minimum_size = Vector2(0, 30)

func _style_section_header(button: Button) -> void:
	var bg := Color(0.06, 0.10, 0.16, 1.0)
	var hover_bg := Color(0.08, 0.13, 0.20, 1.0)

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_border_width_all(0)
	normal.set_corner_radius_all(0)
	normal.set_content_margin_all(2)
	button.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = hover_bg
	hover.set_border_width_all(0)
	hover.set_corner_radius_all(0)
	hover.set_content_margin_all(2)
	button.add_theme_stylebox_override("hover", hover)

	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_stylebox_override("focus", hover)

	button.add_theme_color_override("font_color", Color(0.55, 0.72, 0.92, 1.0))
	button.add_theme_font_size_override("font_size", 12)
	button.custom_minimum_size = Vector2(0, 22)

func _style_map_item(button: Button, is_selected: bool = false) -> void:
	var bg := Color(0.0, 0.0, 0.0, 0.0)
	var hover_bg := Color(0.12, 0.20, 0.30, 0.8)
	var selected_bg := Color(0.10, 0.28, 0.48, 0.9)

	var normal := StyleBoxFlat.new()
	normal.bg_color = selected_bg if is_selected else bg
	normal.set_border_width_all(0)
	normal.set_corner_radius_all(2)
	normal.set_content_margin(SIDE_LEFT, 14)
	normal.set_content_margin(SIDE_RIGHT, 2)
	normal.set_content_margin(SIDE_TOP, 1)
	normal.set_content_margin(SIDE_BOTTOM, 1)
	button.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = hover_bg
	hover.set_border_width_all(0)
	hover.set_corner_radius_all(2)
	hover.set_content_margin(SIDE_LEFT, 14)
	hover.set_content_margin(SIDE_RIGHT, 2)
	hover.set_content_margin(SIDE_TOP, 1)
	hover.set_content_margin(SIDE_BOTTOM, 1)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)

	button.add_theme_color_override("font_color", Color(0.82, 0.90, 0.98, 1.0) if is_selected else Color(0.72, 0.80, 0.90, 1.0))
	button.add_theme_font_size_override("font_size", 12)
	button.custom_minimum_size = Vector2(0, 20)

# ---------------------------------------------------------------------------
# Comment panel
# ---------------------------------------------------------------------------

func _build_comment_panel() -> void:
	_comment_panel = PanelContainer.new()
	_comment_panel.name = "CommentPanel"
	_comment_panel.anchor_left = 0.5
	_comment_panel.anchor_right = 0.5
	_comment_panel.anchor_top = 1.0
	_comment_panel.anchor_bottom = 1.0
	_comment_panel.offset_left = -380
	_comment_panel.offset_right = 380
	_comment_panel.offset_top = -220
	_comment_panel.offset_bottom = -20
	_comment_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_comment_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.07, 0.115, 0.74)
	panel_style.set_border_width_all(1)
	panel_style.border_color = Color(0.3, 0.72, 1.0, 0.8)
	panel_style.set_corner_radius_all(14)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	panel_style.shadow_size = 10
	_comment_panel.add_theme_stylebox_override("panel", panel_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_comment_panel.add_child(margin)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	margin.add_child(vb)

	var comment_title = Label.new()
	comment_title.text = "Comment Writer"
	comment_title.add_theme_color_override("font_color", Color(0.9, 0.97, 1.0, 1.0))
	comment_title.add_theme_font_size_override("font_size", 14)
	comment_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(comment_title)

	_comment_context_label = Label.new()
	_comment_context_label.text = "Artifact: (none selected)"
	_comment_context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_comment_context_label.add_theme_font_size_override("font_size", 12)
	_comment_context_label.add_theme_color_override("font_color", Color(0.72, 0.85, 0.98, 1.0))
	vb.add_child(_comment_context_label)

	_comment_text_edit = TextEdit.new()
	_comment_text_edit.custom_minimum_size = Vector2(0, 68)
	_comment_text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_comment_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_comment_text_edit.placeholder_text = "Write feedback, bug reports, or ideas about this artifact..."
	_comment_text_edit.add_theme_font_size_override("font_size", 12)
	_comment_text_edit.text = last_comment_draft
	_comment_text_edit.text_changed.connect(_on_comment_text_changed)
	vb.add_child(_comment_text_edit)

	var action_row = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 4)
	vb.add_child(action_row)

	var insert_btn = Button.new()
	insert_btn.text = "Insert Artifact"
	insert_btn.add_theme_font_size_override("font_size", 12)
	insert_btn.pressed.connect(_on_insert_artifact_pressed)
	_style_button(insert_btn)
	action_row.add_child(insert_btn)

	var save_btn = Button.new()
	save_btn.text = "Save"
	save_btn.add_theme_font_size_override("font_size", 12)
	save_btn.pressed.connect(_on_save_comment_pressed)
	_style_button(save_btn, true)
	action_row.add_child(save_btn)

	_comment_status_label = Label.new()
	_comment_status_label.text = ""
	_comment_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_comment_status_label.add_theme_font_size_override("font_size", 10)
	_comment_status_label.add_theme_color_override("font_color", Color(0.55, 0.68, 0.82, 1.0))
	vb.add_child(_comment_status_label)

func _refresh_comment_context() -> void:
	if not _comment_context_label:
		return
	if last_selected_lookup.is_empty():
		_comment_context_label.text = "Artifact: (none selected)"
		return
	var art := ArtifactCatalogDataProvider.get_artifact_by_lookup_name(last_selected_lookup)
	var scene_path := str(art.get("scene", "")).strip_edges()
	var seq := str(art.get("sequence", "")).strip_edges()
	_comment_context_label.text = "Artifact: %s | Seq: %s" % [last_selected_lookup, seq if not seq.is_empty() else "—"]

func _on_comment_text_changed() -> void:
	if _comment_text_edit:
		last_comment_draft = _comment_text_edit.text

func _on_insert_artifact_pressed() -> void:
	if not _comment_text_edit:
		return
	if last_selected_lookup.is_empty():
		_set_comment_status("Select an artifact first.")
		return
	var art := ArtifactCatalogDataProvider.get_artifact_by_lookup_name(last_selected_lookup)
	var scene_path := str(art.get("scene", "")).strip_edges()
	var token := "[artifact:%s]" % last_selected_lookup
	if not scene_path.is_empty():
		token += " [scene:%s]" % scene_path
	if not _comment_text_edit.text.is_empty() and not _comment_text_edit.text.ends_with(" ") and not _comment_text_edit.text.ends_with("\n"):
		_comment_text_edit.text += " "
	_comment_text_edit.text += token
	_comment_text_edit.grab_focus()
	_set_comment_status("Inserted artifact token.")

func _on_save_comment_pressed() -> void:
	if not _comment_text_edit:
		return
	var comment_text := _comment_text_edit.text.strip_edges()
	if comment_text.is_empty():
		_set_comment_status("Write a comment first.")
		return

	var art := ArtifactCatalogDataProvider.get_artifact_by_lookup_name(last_selected_lookup)
	var scene_path := str(art.get("scene", "")).strip_edges()
	var seq := str(art.get("sequence", "")).strip_edges()

	var lines: Array[String] = []
	lines.append("")
	lines.append("## %s | Artifact Catalog" % Time.get_datetime_string_from_system())
	if not last_selected_lookup.is_empty():
		lines.append("- Artifact: `%s`" % last_selected_lookup)
	if not scene_path.is_empty():
		lines.append("- Scene: `%s`" % scene_path)
	if not seq.is_empty():
		lines.append("- Sequence: `%s`" % seq)
	lines.append("- Source: `ArtifactCatalogDesktop3D`")
	lines.append("")
	lines.append(comment_text)
	lines.append("")
	lines.append("---")

	var block := "\n".join(lines)
	if _append_text_to_file(COMMENT_DEFAULT_MARKDOWN_PATH, block):
		_set_comment_status("Saved comment to %s" % COMMENT_DEFAULT_MARKDOWN_PATH)
		_comment_text_edit.text = ""
		last_comment_draft = ""
		return

	var fallback_path := "user://desktop_feedback/desktop_feedback.md"
	if _append_text_to_file(fallback_path, block):
		_set_comment_status("res:// not writable. Saved to %s" % fallback_path)
		_comment_text_edit.text = ""
		last_comment_draft = ""
		return

	_set_comment_status("Failed to save comment.")

func _append_text_to_file(path: String, content: String) -> bool:
	var base_dir := path.get_base_dir()
	if not base_dir.is_empty():
		var absolute_dir := ProjectSettings.globalize_path(base_dir)
		if not DirAccess.dir_exists_absolute(absolute_dir):
			DirAccess.make_dir_recursive_absolute(absolute_dir)

	var file: FileAccess = null
	if FileAccess.file_exists(path):
		file = FileAccess.open(path, FileAccess.READ_WRITE)
		if not file:
			return false
		file.seek_end()
	else:
		file = FileAccess.open(path, FileAccess.WRITE)
		if not file:
			return false

	file.store_string(content)
	file.close()
	return true

func _set_comment_status(text: String) -> void:
	if _comment_status_label:
		_comment_status_label.text = text

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _format_name(raw_name: String) -> String:
	return raw_name.replace("_", " ").capitalize()

func _set_status(text: String) -> void:
	if _status_label:
		_status_label.text = text
