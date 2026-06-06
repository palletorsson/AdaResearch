extends Control
## Biome Brush menu — the Tilt-Brush-style 2D panel rendered on the left hand via
## viewport_2d_in_3d. Two pages, swapped with the top toggle (pointer-driven, no
## keyboard): BRUSH (element grid + size + pressure) and ARTIFACTS (browse the
## unlocked palette by category, click to toggle into the active element's list).
## Signals drive BiomeBrushController. See doc/VR_EDITING_SYSTEM.md, doc/PAINT_LAYERS.md.

signal element_selected(element_name: String)
signal size_changed(radius: int)
signal pressure_changed(strength: float)
signal artifact_toggle_requested(artifact_name: String)

const BiomeElementsLib = preload("res://commons/biome_layers/biome_elements.gd")
const ArtifactPaletteLib = preload("res://commons/biome_layers/artifact_palette.gd")
const ELEMENTS: Array = BiomeElementsLib.NAMES   # single source of truth (BiomeElements)

const ART_PER_PAGE := 8   # artifact buttons per page on the ARTIFACTS page

var _buttons: Array = []
var _selected: int = 0
var _size_label: Label = null
var _pressure_label: Label = null

# Artifact picker state
var _page_brush: VBoxContainer = null
var _page_art: VBoxContainer = null
var _cats: Array = []
var _cat_idx: int = 0
var _art_page: int = 0
var _art_buttons: Array = []
var _art_grid: GridContainer = null
var _art_header: Label = null
var _cat_label: Label = null
var _page_label: Label = null
var _picker_selected: Array = []   # the active element's chosen artifacts (✓ marks)


func _ready() -> void:
	custom_minimum_size = Vector2(520, 470)

	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.10, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 18; root.offset_top = 14
	root.offset_right = -18; root.offset_bottom = -14
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var title := Label.new()
	title.text = "◆  BIOME  BRUSH"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.45, 0.85, 0.55))
	root.add_child(title)

	# Page toggle (BRUSH ⇄ ARTIFACTS).
	var toggle := Button.new()
	toggle.text = "ARTIFACTS  ▸"
	toggle.custom_minimum_size = Vector2(0, 40)
	toggle.add_theme_font_size_override("font_size", 18)
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.pressed.connect(_toggle_page.bind(toggle))
	root.add_child(toggle)

	_page_brush = VBoxContainer.new()
	_page_brush.add_theme_constant_override("separation", 12)
	root.add_child(_page_brush)
	_build_brush_page(_page_brush)

	_page_art = VBoxContainer.new()
	_page_art.add_theme_constant_override("separation", 8)
	_page_art.visible = false
	root.add_child(_page_art)
	_build_art_page(_page_art)

	_refresh()
	call_deferred("emit_signal", "element_selected", str(ELEMENTS[_selected]))


# ── BRUSH page ────────────────────────────────────────────────────────
func _build_brush_page(parent: VBoxContainer) -> void:
	var sub := Label.new()
	sub.text = "LAYER"
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_color_override("font_color", Color(0.6, 0.64, 0.72))
	parent.add_child(sub)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	parent.add_child(grid)
	for i in ELEMENTS.size():
		var b := Button.new()
		b.text = BiomeElementsLib.label(str(ELEMENTS[i]))
		b.custom_minimum_size = Vector2(146, 78)
		b.add_theme_font_size_override("font_size", 18)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_on_pick.bind(i))
		grid.add_child(b)
		_buttons.append(b)

	_size_label = _build_slider_row(parent, "SIZE", 1, 6, 1, 2, _on_size, "r2")
	_pressure_label = _build_slider_row(parent, "PRESS", 0.1, 1.0, 0.1, 0.6, _on_pressure, "0.6")


func _build_slider_row(parent: VBoxContainer, cap: String, lo: float, hi: float, step: float, val: float, cb: Callable, init_txt: String) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var c := Label.new()
	c.text = cap
	c.add_theme_font_size_override("font_size", 15)
	c.add_theme_color_override("font_color", Color(0.6, 0.64, 0.72))
	c.custom_minimum_size = Vector2(58, 0)
	row.add_child(c)
	var slider := HSlider.new()
	slider.min_value = lo; slider.max_value = hi; slider.step = step; slider.value = val
	slider.custom_minimum_size = Vector2(300, 40)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(cb)
	row.add_child(slider)
	var lbl := Label.new()
	lbl.text = init_txt
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.93, 0.96, 1.0))
	lbl.custom_minimum_size = Vector2(48, 0)
	row.add_child(lbl)
	return lbl


# ── ARTIFACTS page ────────────────────────────────────────────────────
func _build_art_page(parent: VBoxContainer) -> void:
	_art_header = Label.new()
	_art_header.add_theme_font_size_override("font_size", 16)
	_art_header.add_theme_color_override("font_color", Color(0.85, 0.55, 0.95))
	parent.add_child(_art_header)

	# Category cycle: [◀] category [▶]
	var cat_row := HBoxContainer.new()
	cat_row.add_theme_constant_override("separation", 8)
	parent.add_child(cat_row)
	cat_row.add_child(_arrow_button("◀", _cat_prev))
	_cat_label = Label.new()
	_cat_label.add_theme_font_size_override("font_size", 16)
	_cat_label.add_theme_color_override("font_color", Color(0.93, 0.96, 1.0))
	_cat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cat_row.add_child(_cat_label)
	cat_row.add_child(_arrow_button("▶", _cat_next))

	# Artifact grid (2 cols).
	_art_grid = GridContainer.new()
	_art_grid.columns = 2
	_art_grid.add_theme_constant_override("h_separation", 8)
	_art_grid.add_theme_constant_override("v_separation", 8)
	parent.add_child(_art_grid)

	# Page cycle: [◀] page x/y [▶]
	var page_row := HBoxContainer.new()
	page_row.add_theme_constant_override("separation", 8)
	parent.add_child(page_row)
	page_row.add_child(_arrow_button("◀", _page_prev))
	_page_label = Label.new()
	_page_label.add_theme_font_size_override("font_size", 14)
	_page_label.add_theme_color_override("font_color", Color(0.6, 0.64, 0.72))
	_page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_row.add_child(_page_label)
	page_row.add_child(_arrow_button("▶", _page_next))


func _arrow_button(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(54, 38)
	b.add_theme_font_size_override("font_size", 20)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b


func _toggle_page(toggle: Button) -> void:
	var show_art := not _page_art.visible
	_page_art.visible = show_art
	_page_brush.visible = not show_art
	toggle.text = "◂  BRUSH" if show_art else "ARTIFACTS  ▸"
	if show_art:
		if _cats.is_empty():
			_cats = ArtifactPaletteLib.categories()
		_refresh_artifacts()


func _cat_prev() -> void:
	if _cats.is_empty(): return
	_cat_idx = wrapi(_cat_idx - 1, 0, _cats.size())
	_art_page = 0
	_refresh_artifacts()

func _cat_next() -> void:
	if _cats.is_empty(): return
	_cat_idx = wrapi(_cat_idx + 1, 0, _cats.size())
	_art_page = 0
	_refresh_artifacts()

func _page_prev() -> void:
	_art_page = maxi(0, _art_page - 1)
	_refresh_artifacts()

func _page_next() -> void:
	_art_page += 1
	_refresh_artifacts()


## Rebuild the artifact grid for the current category + page, marking the ones in
## the active element's list. Pointer clicks request a toggle.
func _refresh_artifacts() -> void:
	if _art_grid == null:
		return
	var el := str(ELEMENTS[_selected])
	_art_header.text = "ARTIFACTS  ·  %s" % el.to_upper()
	var cat := str(_cats[_cat_idx]) if _cat_idx < _cats.size() else "misc"
	_cat_label.text = "%s  (%d/%d)" % [cat, _cat_idx + 1, maxi(1, _cats.size())]
	var names: Array = ArtifactPaletteLib.names_in_category(cat)
	var pages: int = maxi(1, int(ceil(float(names.size()) / float(ART_PER_PAGE))))
	_art_page = clampi(_art_page, 0, pages - 1)
	_page_label.text = "page %d / %d   ·   %d in category" % [_art_page + 1, pages, names.size()]
	for c in _art_grid.get_children():
		c.queue_free()
	_art_buttons.clear()
	var start := _art_page * ART_PER_PAGE
	for i in range(start, mini(start + ART_PER_PAGE, names.size())):
		var nm := str(names[i])
		var b := Button.new()
		b.text = ("✓ " if nm in _picker_selected else "") + nm
		b.custom_minimum_size = Vector2(232, 50)
		b.add_theme_font_size_override("font_size", 13)
		b.focus_mode = Control.FOCUS_NONE
		b.clip_text = true
		b.pressed.connect(_on_art_pick.bind(nm))
		_art_grid.add_child(b)
		_art_buttons.append(b)


func _on_art_pick(nm: String) -> void:
	artifact_toggle_requested.emit(nm)


## Called back by the controller after a toggle, with the active element's list.
func refresh_artifact_marks(selected: Array) -> void:
	_picker_selected = selected.duplicate()
	if _page_art and _page_art.visible:
		_refresh_artifacts()


func _on_pick(i: int) -> void:
	_selected = clampi(i, 0, ELEMENTS.size() - 1)
	_refresh()
	element_selected.emit(str(ELEMENTS[_selected]))
	if _page_art and _page_art.visible:
		_refresh_artifacts()


func _on_size(v: float) -> void:
	var r := int(v)
	if _size_label:
		_size_label.text = "r%d" % r
	size_changed.emit(r)


func _on_pressure(v: float) -> void:
	if _pressure_label:
		_pressure_label.text = "%.1f" % v
	pressure_changed.emit(v)


## Called by the 3D wrapper when the brush cycles element via Ax, to keep the
## panel highlight in sync with the actual active element.
func set_selected_element(element_name: String) -> void:
	var idx := ELEMENTS.find(element_name)
	if idx >= 0:
		_selected = idx
		_refresh()
		if _page_art and _page_art.visible:
			_refresh_artifacts()


func _refresh() -> void:
	for i in _buttons.size():
		var b: Button = _buttons[i]
		var c: Color = BiomeElementsLib.ui_color(str(ELEMENTS[i]))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(c.r, c.g, c.b, 0.30 if i != _selected else 0.85)
		sb.corner_radius_top_left = 8; sb.corner_radius_top_right = 8
		sb.corner_radius_bottom_left = 8; sb.corner_radius_bottom_right = 8
		if i == _selected:
			sb.border_width_left = 3; sb.border_width_right = 3
			sb.border_width_top = 3; sb.border_width_bottom = 3
			sb.border_color = Color(1.0, 1.0, 1.0, 0.9)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		b.add_theme_color_override("font_color", Color(0.05, 0.06, 0.09) if i == _selected else Color(0.93, 0.96, 1.0))
