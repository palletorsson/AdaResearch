## Factory that maps Panel Layout JSON elements to Godot Control widgets.
##
## Given a panel definition (Dictionary from parsed JSON) and a
## DraftDataStore, builds a Control tree with positioned widgets.
##
## Element types handled:
##   "binary_grid"   → BinaryGridWidget (threading, tieup, treadling)
##   "canvas"        → DrawdownWidget (drawdown)
##   "color_grid"    → ColorGridWidget (pattern maker domain editor)
##   "button_group"  → OperationsBarWidget (if metadata has "actions") or styled buttons
##   "dropdown"      → OptionButton
##   "text_input"    → LineEdit
##   "form_group"    → VBox of Label+SpinBox pairs
##   "color_palette" → Row of color swatch buttons
##   "button_grid"   → GridContainer of toggle buttons
##   "slider"        → HSlider with label
##   "thumbnail_grid"→ Scrollable placeholder grid
class_name PanelContentBuilder
extends RefCounted

const P = preload("res://commons/ui/ada_palette.gd")

# ── Main entry point ────────────────────────────────────────────

## Build a Control tree for one panel from its JSON definition.
## [param panel_def] is a Dictionary with keys: id, role, viewport_px, elements.
## [param data_store] is the shared DraftDataStore (null for pattern_maker pages).
## Returns the root Control sized to viewport_px.
static func build_panel(panel_def: Dictionary, data_store = null) -> Control:
	var viewport_px: Array = panel_def.get("viewport_px", [640, 480])
	var vp_w: float = float(viewport_px[0])
	var vp_h: float = float(viewport_px[1])

	# Root control — fills the SubViewport
	var root := Control.new()
	root.name = "PanelRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.custom_minimum_size = Vector2(vp_w, vp_h)

	# Panel background — brighter for VR readability
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.14, 0.15, 0.20)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	# Panel title label
	var panel_id: String = panel_def.get("id", "panel")
	var title := Label.new()
	title.name = "PanelTitle"
	title.text = _humanize(panel_id)
	title.add_theme_color_override("font_color", P.ACCENT_CYAN)
	title.add_theme_font_size_override("font_size", P.FONT_SIZE_SMALL)
	title.position = Vector2(4, 2)
	root.add_child(title)

	# Build each element
	var elements: Array = panel_def.get("elements", [])
	for elem_dict in elements:
		var widget := _build_element(elem_dict, data_store)
		if widget:
			root.add_child(widget)

	return root


# ── Element factory ─────────────────────────────────────────────

static func _build_element(elem: Dictionary, data_store = null) -> Control:
	var elem_type: String = elem.get("type", "")
	var elem_id: String = elem.get("id", "element")
	var rect_arr: Array = elem.get("rect", [0, 0, 100, 100])
	var metadata: Dictionary = elem.get("metadata", {})

	var x: float = float(rect_arr[0])
	var y: float = float(rect_arr[1])
	var w: float = float(rect_arr[2])
	var h: float = float(rect_arr[3])

	var widget: Control = null

	match elem_type:
		"binary_grid":
			widget = _build_binary_grid(metadata, data_store, w, h)
		"canvas":
			var data_path: String = metadata.get("data_path", "")
			if data_path == "drawdown":
				widget = _build_drawdown(metadata, data_store, w, h)
			else:
				widget = _build_placeholder(elem_id, elem_type, w, h)
		"color_grid":
			widget = _build_color_grid(metadata, w, h)
		"button_group":
			if metadata.has("actions"):
				widget = _build_operations_bar(metadata, w, h)
			elif metadata.has("options"):
				widget = _build_option_buttons(elem_id, metadata, w, h)
			else:
				widget = _build_label_buttons(elem_id, metadata, w, h)
		"dropdown":
			widget = _build_dropdown(elem_id, metadata, w, h)
		"text_input":
			widget = _build_text_input(elem_id, metadata, w, h)
		"form_group":
			widget = _build_form_group(metadata, w, h)
		"color_palette":
			widget = _build_color_palette(metadata, w, h)
		"button_grid":
			widget = _build_button_grid(metadata, w, h)
		"slider":
			widget = _build_slider(metadata, w, h)
		"thumbnail_grid":
			widget = _build_thumbnail_grid(elem_id, w, h)
		_:
			widget = _build_placeholder(elem_id, elem_type, w, h)

	if widget:
		widget.name = elem_id
		widget.position = Vector2(x, y)
		widget.size = Vector2(w, h)

	return widget


# ── Binary grid builder ─────────────────────────────────────────

static func _build_binary_grid(metadata: Dictionary, data_store,
		w: float, h: float) -> BinaryGridWidget:
	var grid := BinaryGridWidget.new()

	var rows: int = int(metadata.get("rows", 4))
	var cols: int = int(metadata.get("cols", 24))
	var flip_y: bool = metadata.get("flip_y", false)
	var transposed: bool = metadata.get("transposed", false)
	var click_mode: String = str(metadata.get("click_mode", "toggle"))
	var data_path: String = str(metadata.get("data_path", "threading"))

	grid.custom_minimum_size = Vector2(w, h)
	grid.setup(data_store, data_path, rows, cols, flip_y, transposed, click_mode)

	return grid


# ── Drawdown builder ────────────────────────────────────────────

static func _build_drawdown(metadata: Dictionary, data_store,
		w: float, h: float) -> DrawdownWidget:
	var dd := DrawdownWidget.new()

	var rows: int = int(metadata.get("rows", 24))
	var cols: int = int(metadata.get("cols", 24))

	dd.custom_minimum_size = Vector2(w, h)
	dd.setup(data_store, rows, cols, true)

	return dd


# ── Color grid builder (Pattern Maker domain editor) ─────────────

static func _build_color_grid(metadata: Dictionary, w: float, h: float) -> ColorGridWidget:
	var grid := ColorGridWidget.new()

	var rows: int = int(metadata.get("rows", 8))
	var cols: int = int(metadata.get("cols", 8))
	var click_mode: String = str(metadata.get("click_mode", "paint"))
	var is_read_only: bool = metadata.get("read_only", false)

	# Parse palette from hex color array in metadata
	var palette_hex: Array = metadata.get("palette_colors", [])
	var pal := PackedColorArray()
	for hex in palette_hex:
		pal.append(Color.from_string(str(hex), Color(0.2, 0.2, 0.2)))

	grid.custom_minimum_size = Vector2(w, h)
	grid.setup(rows, cols, pal, is_read_only, click_mode)

	# Load initial data if provided
	var initial_data: Array = metadata.get("data", [])
	if not initial_data.is_empty():
		grid.load_from_2d(initial_data)

	return grid


# ── Operations bar builder ───────────────────────────────────────

static func _build_operations_bar(metadata: Dictionary,
		w: float, h: float) -> OperationsBarWidget:
	var bar := OperationsBarWidget.new()
	var actions_arr: Array = metadata.get("actions", [])

	bar.custom_minimum_size = Vector2(w, h)
	# Target is wired later by wire_operations_to_target()
	bar.setup(actions_arr, null)

	return bar


## Post-build wiring: connect all OperationsBarWidgets in a panel tree
## to a target ColorGridWidget.  Call after build_panel() on each panel.
##
## [param panel_roots] — array of root Controls returned by build_panel().
## Scans all panels for the first editable ColorGridWidget (the domain editor),
## then connects every OperationsBarWidget to it.
static func wire_operations_to_target(panel_roots: Array) -> void:
	# Find the first editable ColorGridWidget across all panels
	var target: ColorGridWidget = null
	for root in panel_roots:
		if not root:
			continue
		target = _find_first_color_grid(root)
		if target:
			break

	if not target:
		return  # no editable color grid found, nothing to wire

	# Connect all OperationsBarWidgets to this target
	for root in panel_roots:
		if not root:
			continue
		_wire_bars_in_tree(root, target)


static func _find_first_color_grid(node: Node) -> ColorGridWidget:
	if node is ColorGridWidget:
		var cg := node as ColorGridWidget
		if not cg.read_only:
			return cg
	for child in node.get_children():
		var found := _find_first_color_grid(child)
		if found:
			return found
	return null


static func _wire_bars_in_tree(node: Node, target: ColorGridWidget) -> void:
	if node is OperationsBarWidget:
		(node as OperationsBarWidget).target_widget = target
	for child in node.get_children():
		_wire_bars_in_tree(child, target)


# ── Dropdown builder ─────────────────────────────────────────────

static func _build_dropdown(elem_id: String, metadata: Dictionary,
		w: float, h: float) -> Control:
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(w, h)
	option.clip_text = true

	# Add display items based on data_path context
	var data_path: String = metadata.get("data_path", "")
	var items := _dropdown_items_for(data_path, metadata)
	for i in items.size():
		option.add_item(items[i], i)

	# Select current value if available
	var current: String = metadata.get("current_zone", metadata.get("current_group", ""))
	if not current.is_empty():
		for i in option.item_count:
			if option.get_item_text(i) == current:
				option.selected = i
				break

	# Dark theme styling
	_apply_dark_button_style(option)
	option.add_theme_font_size_override("font_size", P.FONT_SIZE_SMALL)

	return option


static func _dropdown_items_for(data_path: String, metadata: Dictionary) -> PackedStringArray:
	match data_path:
		"loom.id":
			return PackedStringArray(["4-shaft", "8-shaft", "12-shaft", "16-shaft"])
		"periodId":
			return PackedStringArray(["All Periods", "Ancient", "Medieval", "Renaissance", "Modern"])
		"zone":
			return PackedStringArray(["field", "border", "corner", "center"])
		_:
			return PackedStringArray([_humanize(data_path)])


# ── Text input builder ───────────────────────────────────────────

static func _build_text_input(elem_id: String, metadata: Dictionary,
		w: float, h: float) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(w, h)

	# Label above
	var label := Label.new()
	label.text = _humanize(elem_id)
	label.add_theme_color_override("font_color", P.TEXT_ON_DARK)
	label.add_theme_font_size_override("font_size", P.FONT_SIZE_SMALL)
	label.position = Vector2(6, 2)
	container.add_child(label)

	# LineEdit below
	var edit := LineEdit.new()
	edit.placeholder_text = _humanize(metadata.get("data_path", ""))
	edit.position = Vector2(4, 18)
	edit.size = Vector2(w - 8, h - 22)
	_apply_dark_lineedit_style(edit)
	container.add_child(edit)

	return container


# ── Form group builder ───────────────────────────────────────────

static func _build_form_group(metadata: Dictionary,
		w: float, h: float) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(w, h)

	var fields: Array = metadata.get("fields", [])
	var row_h: float = mini(36, h / maxi(fields.size(), 1))
	var label_w: float = w * 0.45
	var input_w: float = w * 0.50

	for i in fields.size():
		var field_name: String = str(fields[i])
		var y_pos: float = i * row_h + 4

		# Label
		var label := Label.new()
		label.text = _humanize(field_name)
		label.add_theme_color_override("font_color", P.TEXT_ON_DARK)
		label.add_theme_font_size_override("font_size", P.FONT_SIZE_SMALL)
		label.position = Vector2(6, y_pos + 4)
		label.size = Vector2(label_w, row_h - 4)
		container.add_child(label)

		# SpinBox
		var spin := SpinBox.new()
		spin.min_value = 1
		spin.max_value = 100
		spin.value = _default_value_for(field_name)
		spin.position = Vector2(label_w + 8, y_pos)
		spin.size = Vector2(input_w - 8, row_h - 6)
		_apply_dark_spinbox_style(spin)
		container.add_child(spin)

	return container


static func _default_value_for(field_name: String) -> float:
	match field_name:
		"warps": return 24.0
		"picks": return 24.0
		"preview_repeats": return 3.0
		_: return 1.0


# ── Color palette builder ────────────────────────────────────────

static func _build_color_palette(metadata: Dictionary,
		w: float, h: float) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(w, h)

	# Parse palette colors
	var palette_hex: Array = metadata.get("palette_colors", [])
	var colors: PackedColorArray = PackedColorArray()
	if palette_hex.size() > 0:
		for hex in palette_hex:
			colors.append(Color.from_string(str(hex), Color(0.5, 0.5, 0.5)))
	else:
		# Default loom palette from DraftDataStore defaults
		colors = PackedColorArray([
			Color.from_string("#1e3a5f", Color.GRAY),
			Color.from_string("#c4a35a", Color.GRAY),
			Color.from_string("#8b2500", Color.GRAY),
			Color.from_string("#2d5a27", Color.GRAY),
			Color.from_string("#f5f0e6", Color.GRAY),
			Color.from_string("#4a2d6b", Color.GRAY),
			Color.from_string("#c67b30", Color.GRAY),
			Color.from_string("#1a1a2e", Color.GRAY),
		])

	var count := colors.size()
	if count == 0:
		return container

	var gap := 3.0
	var swatch_w := (w - gap * (count - 1)) / count
	var swatch_h := minf(h, swatch_w)  # keep square-ish
	var y_offset := (h - swatch_h) * 0.5

	for i in count:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(swatch_w, swatch_h)
		btn.position = Vector2(i * (swatch_w + gap), y_offset)
		btn.size = Vector2(swatch_w, swatch_h)

		var style := StyleBoxFlat.new()
		style.bg_color = colors[i]
		style.set_border_width_all(2)
		style.border_color = Color(0.3, 0.32, 0.38)
		style.set_corner_radius_all(P.CORNER_RADIUS_SM)
		btn.add_theme_stylebox_override("normal", style)

		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = colors[i].lightened(0.15)
		hover_style.set_border_width_all(2)
		hover_style.border_color = P.ACCENT_CYAN
		hover_style.set_corner_radius_all(P.CORNER_RADIUS_SM)
		btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style := StyleBoxFlat.new()
		pressed_style.bg_color = colors[i].darkened(0.1)
		pressed_style.set_border_width_all(2)
		pressed_style.border_color = P.ACCENT_CYAN
		pressed_style.set_corner_radius_all(P.CORNER_RADIUS_SM)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		btn.tooltip_text = "Color %d" % i
		container.add_child(btn)

	return container


# ── Button grid builder (wallpaper groups etc.) ──────────────────

static func _build_button_grid(metadata: Dictionary,
		w: float, h: float) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(w, h)

	var current_group: String = metadata.get("current_group", "")

	# Standard wallpaper groups organized by category
	var groups := [
		["P1", "P2", "PM", "PG", "CM"],
		["PMM", "PMG", "PGG", "CMM"],
		["P4", "P4M", "P4G"],
		["P3", "P3M1", "P31M"],
		["P6", "P6M"],
	]

	var grid := GridContainer.new()
	grid.columns = 5
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	container.add_child(grid)

	for row in groups:
		for group_name in row:
			var btn := Button.new()
			btn.text = group_name
			btn.custom_minimum_size = Vector2(48, 32)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.toggle_mode = true
			btn.button_pressed = (group_name == current_group)
			_apply_dark_toggle_style(btn, group_name == current_group)
			btn.add_theme_font_size_override("font_size", P.FONT_SIZE_SMALL)
			grid.add_child(btn)

	return container


# ── Slider builder ───────────────────────────────────────────────

static func _build_slider(metadata: Dictionary,
		w: float, h: float) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(w, h)

	var min_val: float = float(metadata.get("min", 0))
	var max_val: float = float(metadata.get("max", 100))
	var current: float = float(metadata.get("current", min_val))
	var data_path: String = metadata.get("data_path", "value")

	# Label
	var label := Label.new()
	label.text = "%s: %d" % [_humanize(data_path), int(current)]
	label.add_theme_color_override("font_color", P.TEXT_ON_DARK)
	label.add_theme_font_size_override("font_size", P.FONT_SIZE_SMALL)
	label.position = Vector2(6, 0)
	label.size = Vector2(w - 12, 14)
	container.add_child(label)

	# Slider
	var slider := HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = current
	slider.step = 1.0
	slider.position = Vector2(4, 16)
	slider.size = Vector2(w - 8, h - 18)

	# Update label on change
	slider.value_changed.connect(func(val: float):
		label.text = "%s: %d" % [_humanize(data_path), int(val)]
	)

	container.add_child(slider)

	return container


# ── Option buttons (button_group with "options" array) ───────────

static func _build_option_buttons(elem_id: String, metadata: Dictionary,
		w: float, h: float) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(w, h)

	var options: Array = metadata.get("options", [])
	if options.is_empty():
		return _build_placeholder(elem_id, "button_group", w, h)

	var grid := GridContainer.new()
	grid.columns = mini(options.size(), 6)
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	container.add_child(grid)

	for opt in options:
		var btn := Button.new()
		btn.text = str(opt)
		btn.custom_minimum_size = Vector2(36, 28)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_dark_button_style(btn)
		btn.add_theme_font_size_override("font_size", P.FONT_SIZE_SMALL)
		grid.add_child(btn)

	return container


# ── Preset buttons (button_group without actions or options) ─────

static func _build_label_buttons(elem_id: String, metadata: Dictionary,
		w: float, h: float) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(w, h)

	var data_path: String = metadata.get("data_path", "")

	# Background panel
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.14, 0.18, 0.6)
	bg_style.border_color = Color(0.28, 0.30, 0.38)
	bg_style.set_border_width_all(1)
	bg_style.set_corner_radius_all(P.CORNER_RADIUS_SM)
	panel.add_theme_stylebox_override("panel", bg_style)
	container.add_child(panel)

	# Title label
	var title := Label.new()
	title.text = _humanize(elem_id)
	title.add_theme_color_override("font_color", P.ACCENT_CYAN)
	title.add_theme_font_size_override("font_size", P.FONT_SIZE_SMALL)
	title.position = Vector2(6, 4)
	container.add_child(title)

	# Build preset buttons from data_path context
	var presets := _preset_items_for(data_path)
	if presets.is_empty():
		# True fallback — single centered label only
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		return container

	var grid := GridContainer.new()
	grid.columns = 2
	grid.position = Vector2(6, 22)
	grid.size = Vector2(w - 12, h - 28)
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	container.add_child(grid)

	var btn_group := ButtonGroup.new()

	for preset_name in presets:
		var btn := Button.new()
		btn.text = preset_name
		btn.custom_minimum_size = Vector2((w - 20) / 2.0, 28)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.toggle_mode = true
		btn.button_group = btn_group
		_apply_dark_toggle_style(btn, false)
		btn.add_theme_font_size_override("font_size", P.FONT_SIZE_SMALL)
		grid.add_child(btn)

	# Select the first button by default
	if grid.get_child_count() > 0:
		(grid.get_child(0) as Button).button_pressed = true

	return container


## Return preset items for a given data_path.
static func _preset_items_for(data_path: String) -> PackedStringArray:
	match data_path:
		"structureId":
			return PackedStringArray([
				"Plain Weave", "Twill 2/2",
				"Twill 3/1", "Satin 5",
				"Basket", "Herringbone",
				"Huck Lace", "Overshot",
			])
		"siteId":
			return PackedStringArray([
				"Alhambra", "Iznik",
				"Roman", "Celtic",
				"Geometric", "Floral",
			])
		_:
			return PackedStringArray()


# ── Thumbnail grid builder ───────────────────────────────────────

static func _build_thumbnail_grid(elem_id: String,
		w: float, h: float) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(w, h)

	# Background panel
	var bg_panel := Panel.new()
	bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18, 0.8)
	style.border_color = Color(0.28, 0.30, 0.38)
	style.set_border_width_all(1)
	style.set_corner_radius_all(P.CORNER_RADIUS_SM)
	bg_panel.add_theme_stylebox_override("panel", style)
	container.add_child(bg_panel)

	# Grid of colored placeholder thumbnails
	var grid := GridContainer.new()
	grid.columns = 3
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)

	var thumb_w := (w - 16) / 3.0
	var thumb_h := thumb_w  # square
	var thumb_colors := [
		Color(0.20, 0.25, 0.35), Color(0.25, 0.20, 0.30),
		Color(0.30, 0.22, 0.20), Color(0.18, 0.28, 0.22),
		Color(0.28, 0.28, 0.18), Color(0.22, 0.18, 0.30),
		Color(0.25, 0.22, 0.28), Color(0.20, 0.26, 0.28),
		Color(0.28, 0.20, 0.24),
	]

	for i in 9:
		var thumb := ColorRect.new()
		thumb.color = thumb_colors[i]
		thumb.custom_minimum_size = Vector2(thumb_w, thumb_h)
		grid.add_child(thumb)

	container.add_child(grid)

	return container


# ── Shared dark theme helpers ─────────────────────────────────────

static func _apply_dark_button_style(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.22, 0.24, 0.32)
	normal.border_color = Color(0.40, 0.43, 0.52)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(P.CORNER_RADIUS_SM)
	normal.set_content_margin_all(4)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.28, 0.32, 0.42)
	hover.border_color = P.ACCENT_CYAN
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(P.CORNER_RADIUS_SM)
	hover.set_content_margin_all(4)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", P.TEXT_ON_DARK)
	btn.add_theme_color_override("font_hover_color", P.ACCENT_CYAN)


static func _apply_dark_toggle_style(btn: Button, active: bool) -> void:
	_apply_dark_button_style(btn)
	if active:
		var active_style := StyleBoxFlat.new()
		active_style.bg_color = Color(0.10, 0.30, 0.38)
		active_style.border_color = P.ACCENT_CYAN
		active_style.set_border_width_all(2)
		active_style.set_corner_radius_all(P.CORNER_RADIUS_SM)
		active_style.set_content_margin_all(3)
		btn.add_theme_stylebox_override("pressed", active_style)
		btn.add_theme_color_override("font_pressed_color", P.ACCENT_CYAN)


static func _apply_dark_lineedit_style(edit: LineEdit) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.18)
	style.border_color = Color(0.35, 0.38, 0.48)
	style.set_border_width_all(1)
	style.set_corner_radius_all(P.CORNER_RADIUS_SM)
	style.set_content_margin_all(4)
	edit.add_theme_stylebox_override("normal", style)

	var focus_style := style.duplicate()
	focus_style.border_color = P.ACCENT_CYAN
	edit.add_theme_stylebox_override("focus", focus_style)

	edit.add_theme_color_override("font_color", P.TEXT_ON_DARK)
	edit.add_theme_color_override("font_placeholder_color", Color(0.45, 0.48, 0.55))
	edit.add_theme_color_override("caret_color", P.ACCENT_CYAN)
	edit.add_theme_font_size_override("font_size", P.FONT_SIZE_SMALL)


static func _apply_dark_spinbox_style(spin: SpinBox) -> void:
	# SpinBox contains a LineEdit as child — style is applied at tree enter
	spin.add_theme_color_override("font_color", P.TEXT_ON_DARK)
	spin.add_theme_font_size_override("font_size", P.FONT_SIZE_SMALL)


# ── Placeholder for truly unimplemented element types ─────────────

static func _build_placeholder(elem_id: String, elem_type: String,
		w: float, h: float) -> Control:
	var container := Panel.new()
	container.custom_minimum_size = Vector2(w, h)

	# Placeholder background — visible in VR
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.20, 0.26, 0.9)
	style.border_color = Color(0.35, 0.38, 0.48)
	style.border_width_bottom = 1
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.corner_radius_top_left = P.CORNER_RADIUS_SM
	style.corner_radius_top_right = P.CORNER_RADIUS_SM
	style.corner_radius_bottom_left = P.CORNER_RADIUS_SM
	style.corner_radius_bottom_right = P.CORNER_RADIUS_SM
	container.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = "%s\n[%s]" % [_humanize(elem_id), elem_type]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.65, 0.68, 0.75))
	label.add_theme_font_size_override("font_size", P.FONT_SIZE_SMALL)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(label)

	return container


# ── Helpers ─────────────────────────────────────────────────────

## Convert snake_case id to Title Case display name.
static func _humanize(id: String) -> String:
	return id.replace("_", " ").capitalize()
