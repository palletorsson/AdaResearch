class_name MapLayerEditorPanel
extends CanvasLayer

## Right-side picker panel for interactables and utilities layer editing.
## Shows artifact search + selection when editing interactables layer,
## or utility code presets + free text when editing utilities layer.

signal brush_selected(value: String)

const ArtifactDataProvider = preload("res://commons/artifacts/catalog/ArtifactCatalogDataProvider.gd")

# Panel state
var _current_mode: String = "interactables"  # "interactables" or "utilities"
var _selected_brush: String = ""

# UI nodes
var _root: Control
var _panel: PanelContainer
var _title_label: Label
var _filter_edit: LineEdit
var _scroll: ScrollContainer
var _content: VBoxContainer
var _count_label: Label
var _selected_label: Label
var _utility_input: LineEdit

# Data
var _all_artifacts: Array = []
var _artifacts_by_sequence: Dictionary = {}
var _sequence_sections: Dictionary = {}  # seq_name -> { "header": Button, "list": VBoxContainer, "section": VBoxContainer }
var _artifact_buttons: Dictionary = {}   # lookup_name -> Button

# Common utility presets
const UTILITY_PRESETS: Array = [
	{"code": "t", "label": "Teleporter (next)", "desc": "Teleport to next map in sequence"},
	{"code": "s", "label": "Spawn point", "desc": "Player spawn location"},
	{"code": "an", "label": "Annotator", "desc": "Sign/annotation marker"},
	{"code": "m", "label": "Music trigger", "desc": "Ambient music zone"},
	{"code": "f", "label": "Fog zone", "desc": "Fog area trigger"},
]


func _ready() -> void:
	layer = 125
	visible = false
	_build_ui()
	_load_artifact_data()


func show_for_layer(layer_name: String) -> void:
	_current_mode = layer_name
	visible = true
	_selected_brush = ""
	_update_panel_for_mode()


func hide_panel() -> void:
	visible = false
	_selected_brush = ""


func get_selected_brush() -> String:
	return _selected_brush


func is_mouse_over_panel() -> bool:
	if not visible or not _panel:
		return false
	return _panel.get_global_rect().has_point(_panel.get_global_mouse_position())


# ════════════════════════════════════════════════════════════════════
#  UI CONSTRUCTION
# ════════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "LayerEditorRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# Right-side panel
	_panel = PanelContainer.new()
	_panel.name = "PickerPanel"
	_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_panel.offset_left = -280
	_panel.offset_top = 10
	_panel.offset_bottom = -10
	_panel.offset_right = -10
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_style_panel(_panel)
	_root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Title
	_title_label = Label.new()
	_title_label.text = "ARTIFACT PICKER"
	_title_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	_title_label.add_theme_font_size_override("font_size", 14)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_label)

	# Search / filter
	_filter_edit = LineEdit.new()
	_filter_edit.placeholder_text = "Search..."
	_filter_edit.clear_button_enabled = true
	_filter_edit.custom_minimum_size = Vector2(0, 28)
	_style_line_edit(_filter_edit)
	_filter_edit.text_changed.connect(_on_filter_changed)
	vbox.add_child(_filter_edit)

	# Count
	_count_label = Label.new()
	_count_label.text = ""
	_count_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	_count_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_count_label)

	# Selected brush label
	_selected_label = Label.new()
	_selected_label.text = "Brush: (none)"
	_selected_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	_selected_label.add_theme_font_size_override("font_size", 12)
	_selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_selected_label)

	# Utility text input (hidden by default, shown in utilities mode)
	_utility_input = LineEdit.new()
	_utility_input.placeholder_text = "Custom utility code..."
	_utility_input.custom_minimum_size = Vector2(0, 28)
	_utility_input.visible = false
	_style_line_edit(_utility_input)
	_utility_input.text_submitted.connect(_on_utility_text_submitted)
	vbox.add_child(_utility_input)

	# Scroll area
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(_scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 2)
	_scroll.add_child(_content)


# ════════════════════════════════════════════════════════════════════
#  DATA LOADING
# ════════════════════════════════════════════════════════════════════

func _load_artifact_data() -> void:
	_all_artifacts = ArtifactDataProvider.get_all_artifacts()

	# Group by sequence
	_artifacts_by_sequence.clear()
	for artifact in _all_artifacts:
		var seq: String = str(artifact.get("sequence", "ungrouped"))
		if seq.is_empty():
			seq = "ungrouped"
		if not _artifacts_by_sequence.has(seq):
			_artifacts_by_sequence[seq] = []
		_artifacts_by_sequence[seq].append(artifact)

	# Sort sequences alphabetically
	var seq_names: Array = _artifacts_by_sequence.keys()
	seq_names.sort()


func _update_panel_for_mode() -> void:
	# Clear existing content
	for child in _content.get_children():
		child.queue_free()
	_sequence_sections.clear()
	_artifact_buttons.clear()

	if _current_mode == "interactables":
		_title_label.text = "ARTIFACT PICKER"
		_filter_edit.visible = true
		_filter_edit.placeholder_text = "Search artifacts..."
		_utility_input.visible = false
		_build_artifact_list()
	elif _current_mode == "utilities":
		_title_label.text = "UTILITY PICKER"
		_filter_edit.visible = true
		_filter_edit.placeholder_text = "Filter utilities..."
		_utility_input.visible = true
		_build_utility_list()

	_selected_brush = ""
	_selected_label.text = "Brush: (none)"


func _build_artifact_list() -> void:
	var seq_names: Array = _artifacts_by_sequence.keys()
	seq_names.sort()

	var total := 0
	for seq_name in seq_names:
		var artifacts: Array = _artifacts_by_sequence[seq_name]
		if artifacts.is_empty():
			continue

		# Section container
		var section := VBoxContainer.new()
		section.add_theme_constant_override("separation", 1)
		_content.add_child(section)

		# Collapsible header
		var header := Button.new()
		header.text = "%s (%d)" % [seq_name, artifacts.size()]
		header.alignment = HORIZONTAL_ALIGNMENT_LEFT
		header.toggle_mode = true
		header.button_pressed = true  # start collapsed
		_style_section_header(header)
		section.add_child(header)

		# Artifact list
		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 1)
		list.visible = false  # collapsed
		section.add_child(list)

		header.toggled.connect(_on_section_toggled.bind(list))

		# Sort artifacts by name
		artifacts.sort_custom(func(a, b): return str(a.get("name", "")).to_lower() < str(b.get("name", "")).to_lower())

		for artifact in artifacts:
			var lookup: String = str(artifact.get("lookup_name", ""))
			var display_name: String = str(artifact.get("name", lookup))
			var desc: String = str(artifact.get("description", ""))

			var btn := Button.new()
			btn.text = display_name
			btn.tooltip_text = "%s\n%s" % [lookup, desc]
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.custom_minimum_size = Vector2(0, 24)
			_style_item_button(btn)
			btn.pressed.connect(_on_artifact_selected.bind(lookup, btn))
			list.add_child(btn)
			_artifact_buttons[lookup] = btn
			total += 1

		_sequence_sections[seq_name] = {"header": header, "list": list, "section": section}

	_count_label.text = "%d artifacts" % total


func _build_utility_list() -> void:
	var total := 0
	for preset in UTILITY_PRESETS:
		var btn := Button.new()
		btn.text = "%s — %s" % [preset.code, preset.label]
		btn.tooltip_text = preset.desc
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 30)
		_style_item_button(btn)
		btn.pressed.connect(_on_utility_selected.bind(str(preset.code), btn))
		_content.add_child(btn)
		total += 1

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.2, 0.3, 0.4, 0.5))
	_content.add_child(sep)

	# Hint label
	var hint := Label.new()
	hint.text = "Or type custom code above\ne.g. t:randomness  an:-90  m:0.1"
	hint.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6))
	hint.add_theme_font_size_override("font_size", 11)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	_content.add_child(hint)

	_count_label.text = "%d presets" % total


# ════════════════════════════════════════════════════════════════════
#  FILTERING
# ════════════════════════════════════════════════════════════════════

func _on_filter_changed(text: String) -> void:
	if _current_mode == "interactables":
		_apply_artifact_filter(text)
	elif _current_mode == "utilities":
		_apply_utility_filter(text)


func _apply_artifact_filter(text: String) -> void:
	var search := text.strip_edges().to_lower()

	for seq_name in _sequence_sections.keys():
		var section_data: Dictionary = _sequence_sections[seq_name]
		var list: VBoxContainer = section_data["list"]
		var header: Button = section_data["header"]
		var section: VBoxContainer = section_data["section"]
		var any_visible := false

		for child in list.get_children():
			if child is Button:
				var matches: bool
				if search.is_empty():
					matches = true
				else:
					matches = child.text.to_lower().find(search) >= 0 or child.tooltip_text.to_lower().find(search) >= 0
				child.visible = matches
				if matches:
					any_visible = true

		section.visible = any_visible or search.is_empty()

		# Auto-expand sections with matches when filtering
		if not search.is_empty() and any_visible:
			list.visible = true
			header.button_pressed = false


func _apply_utility_filter(text: String) -> void:
	var search := text.strip_edges().to_lower()
	for child in _content.get_children():
		if child is Button:
			if search.is_empty():
				child.visible = true
			else:
				child.visible = child.text.to_lower().find(search) >= 0 or child.tooltip_text.to_lower().find(search) >= 0


# ════════════════════════════════════════════════════════════════════
#  SELECTION CALLBACKS
# ════════════════════════════════════════════════════════════════════

func _on_section_toggled(is_pressed: bool, list: VBoxContainer) -> void:
	list.visible = not is_pressed  # pressed = collapsed


func _on_artifact_selected(lookup_name: String, btn: Button) -> void:
	_selected_brush = lookup_name
	_selected_label.text = "Brush: %s" % lookup_name
	# Highlight selected button
	_unhighlight_all_buttons()
	_highlight_button(btn)
	brush_selected.emit(lookup_name)


func _on_utility_selected(code: String, btn: Button) -> void:
	_selected_brush = code
	_selected_label.text = "Brush: %s" % code
	_unhighlight_all_buttons()
	_highlight_button(btn)
	brush_selected.emit(code)


func _on_utility_text_submitted(text: String) -> void:
	var code := text.strip_edges()
	if code.is_empty():
		return
	_selected_brush = code
	_selected_label.text = "Brush: %s" % code
	_unhighlight_all_buttons()
	brush_selected.emit(code)


func _unhighlight_all_buttons() -> void:
	for child in _content.get_children():
		if child is Button:
			_style_item_button(child)
		elif child is VBoxContainer:
			for sub in child.get_children():
				if sub is VBoxContainer:
					for btn in sub.get_children():
						if btn is Button:
							_style_item_button(btn)


func _highlight_button(btn: Button) -> void:
	var highlight := StyleBoxFlat.new()
	highlight.bg_color = Color(0.15, 0.35, 0.55, 0.98)
	highlight.set_border_width_all(1)
	highlight.border_color = Color(0.4, 0.85, 1.0, 1.0)
	highlight.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", highlight)


# ════════════════════════════════════════════════════════════════════
#  STYLING (matches DesktopMapSwitcherOverlay theme)
# ════════════════════════════════════════════════════════════════════

func _style_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.10, 0.92)
	style.set_border_width_all(1)
	style.border_color = Color(0.22, 0.66, 0.98, 0.6)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)


func _style_line_edit(edit: LineEdit) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.14, 0.95)
	style.set_border_width_all(1)
	style.border_color = Color(0.2, 0.4, 0.6, 0.5)
	style.set_corner_radius_all(4)
	edit.add_theme_stylebox_override("normal", style)
	edit.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	edit.add_theme_color_override("font_placeholder_color", Color(0.4, 0.5, 0.6))


func _style_section_header(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.06, 0.1, 0.16, 0.95)
	normal.set_border_width_all(0)
	normal.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.09, 0.15, 0.22, 0.95)
	hover.set_corner_radius_all(4)
	button.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.05, 0.08, 0.13, 0.95)
	pressed.set_corner_radius_all(4)
	button.add_theme_stylebox_override("pressed", pressed)

	button.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9))
	button.add_theme_font_size_override("font_size", 12)
	button.custom_minimum_size = Vector2(0, 26)


func _style_item_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.07, 0.11, 0.17, 0.9)
	normal.set_border_width_all(1)
	normal.border_color = Color(0.15, 0.25, 0.38, 0.5)
	normal.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.1, 0.17, 0.26, 0.95)
	hover.set_border_width_all(1)
	hover.border_color = Color(0.25, 0.5, 0.75, 0.7)
	hover.set_corner_radius_all(4)
	button.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.06, 0.1, 0.15, 0.95)
	pressed.set_border_width_all(1)
	pressed.border_color = Color(0.2, 0.4, 0.6, 0.5)
	pressed.set_corner_radius_all(4)
	button.add_theme_stylebox_override("pressed", pressed)

	button.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	button.add_theme_font_size_override("font_size", 11)
