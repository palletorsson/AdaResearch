extends Control
## The ONE unified editor interface — a minimal wrist panel (rendered via
## viewport_2d_in_3d) with THREE tabs: GRID · ARTIFACTS · BIOME. Same flat,
## pointer-driven (FOCUS_NONE) style as the artifact/biome wrist interfaces.
## GRID folds structure-height ops AND paint (colorize) into one tab. Tapping a
## tab emits tab_changed; tool buttons emit their own signals. See doc/VR_EDITING_SYSTEM.md.

signal tab_changed(tab_id: String)
# GRID — structure
signal grid_op_selected(op: String)
signal brush_size_changed(size: int)
signal level_changed(level: int)
# GRID — paint (folded-in modifier)
signal modifier_op_selected(op: String)
signal color_selected(color: Color)
# BIOME
signal element_selected(element_name: String)
signal size_changed(radius: int)
signal pressure_changed(strength: float)
# ARTIFACTS
signal artifact_action(action: String)
signal artifact_sequence_changed(seq: String)

const BiomeElementsLib = preload("res://commons/biome_layers/biome_elements.gd")

const TABS: Array = ["GRID", "ARTIFACTS", "BIOME"]
const TAB_COLORS: Array = [Color(0.45, 0.75, 1.0), Color(0.95, 0.7, 0.35), Color(0.5, 0.9, 0.6)]
const GRID_OPS: Array = ["add", "remove", "fill", "raise", "randomize", "ground", "checker", "frame", "ring", "smooth"]
const PAINT_OPS: Array = ["colorize", "random", "clear"]
const PALETTE: Array = ["#e08a2a", "#d23b3b", "#2a8ae0", "#3bcf6a", "#c33bd2", "#e0d02a", "#888c95", "#101216"]

const BG := Color(0.07, 0.08, 0.11, 1.0)
const FG := Color(0.90, 0.93, 1.0)
const DIM := Color(0.55, 0.60, 0.70)

var _tab_buttons: Array = []
var _pages: Array = []
var _active_tab: int = 0
var _grid_op_buttons: Array = []
var _grid_op_active: int = 2   # default FILL (paint the selected level), not ADD (+1)
var _paint_op_buttons: Array = []
var _brush_label: Label = null
var _level_label: Label = null
var _elem_buttons: Array = []
var _elem_active: int = 0

# ARTIFACTS — sequence filter (cycled by ◀/▶) + the live preview label.
var _artifact_sequences: Array = ["ALL"]   # set by the host via set_artifact_sequences()
var _seq_idx: int = 0
var _seq_label: Label = null
var _artifact_preview: Label = null


func _ready() -> void:
	custom_minimum_size = Vector2(540, 540)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 18; root.offset_top = 14; root.offset_right = -18; root.offset_bottom = -14
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	root.add_child(tab_row)
	for i in TABS.size():
		var b := Button.new()
		b.text = str(TABS[i])
		b.custom_minimum_size = Vector2(160, 50)
		b.add_theme_font_size_override("font_size", 19)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_on_tab.bind(i))
		tab_row.add_child(b)
		_tab_buttons.append(b)

	for i in TABS.size():
		var page := VBoxContainer.new()
		page.add_theme_constant_override("separation", 10)
		page.visible = (i == 0)
		root.add_child(page)
		_pages.append(page)
	_build_grid_page(_pages[0])
	_build_artifact_page(_pages[1])
	_build_biome_page(_pages[2])

	_refresh_tabs()
	_refresh_grid_ops()


# ── GRID tab: structure heights + paint ───────────────────────────────
func _build_grid_page(parent: VBoxContainer) -> void:
	_section(parent, "STRUCTURE", TAB_COLORS[0])
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	parent.add_child(grid)
	for i in GRID_OPS.size():
		var b := _tool_button(str(GRID_OPS[i]).to_upper(), Vector2(158, 50))
		b.pressed.connect(_on_grid_op.bind(i))
		grid.add_child(b)
		_grid_op_buttons.append(b)
	_brush_label = _slider_row(parent, "BRUSH", 1, 4, 1, 2, _on_brush, "2x2")
	_level_label = _slider_row(parent, "LEVEL", 1, 6, 1, 1, _on_level, "1")

	_section(parent, "PAINT", Color(0.7, 0.6, 1.0))
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 8)
	parent.add_child(prow)
	for i in PAINT_OPS.size():
		var pb := _tool_button(str(PAINT_OPS[i]).to_upper(), Vector2(158, 46))
		pb.pressed.connect(func(): _on_paint_op(i))
		prow.add_child(pb)
		_paint_op_buttons.append(pb)
	var pal := GridContainer.new()
	pal.columns = 8
	pal.add_theme_constant_override("h_separation", 6)
	parent.add_child(pal)
	for hexc in PALETTE:
		var sw := Button.new()
		sw.custom_minimum_size = Vector2(54, 46)
		sw.focus_mode = Control.FOCUS_NONE
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color.html(str(hexc))
		sb.set_corner_radius_all(6)
		sw.add_theme_stylebox_override("normal", sb)
		sw.add_theme_stylebox_override("hover", sb)
		sw.add_theme_stylebox_override("pressed", sb)
		sw.pressed.connect(func(): color_selected.emit(Color.html(str(hexc))))
		pal.add_child(sw)


func _on_grid_op(i: int) -> void:
	_grid_op_active = i
	_refresh_grid_ops()
	grid_op_selected.emit(str(GRID_OPS[i]))


func _on_paint_op(i: int) -> void:
	_highlight(_paint_op_buttons, i, Color(0.7, 0.55, 1.0))
	modifier_op_selected.emit(str(PAINT_OPS[i]))


func _on_brush(v: float) -> void:
	var s := clampi(int(v), 1, 4)
	if _brush_label:
		_brush_label.text = "%dx%d" % [s, s]
	brush_size_changed.emit(s)


func _on_level(v: float) -> void:
	var n := int(v)
	if _level_label:
		_level_label.text = "%d" % n
	level_changed.emit(n)


func _refresh_grid_ops() -> void:
	_highlight(_grid_op_buttons, _grid_op_active, TAB_COLORS[0])


# ── BIOME tab ─────────────────────────────────────────────────────────
func _build_biome_page(parent: VBoxContainer) -> void:
	_section(parent, "LAYER", TAB_COLORS[2])
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	parent.add_child(grid)
	var names: Array = BiomeElementsLib.NAMES
	for i in names.size():
		var b := _tool_button(BiomeElementsLib.label(str(names[i])), Vector2(158, 56))
		b.pressed.connect(_on_elem.bind(i))
		grid.add_child(b)
		_elem_buttons.append(b)
	_slider_row(parent, "SIZE", 1, 6, 1, 2, func(v): size_changed.emit(int(v)), "r2")
	_slider_row(parent, "PRESS", 0.1, 1.0, 0.1, 0.6, func(v): pressure_changed.emit(v), "0.6")


func _on_elem(i: int) -> void:
	_elem_active = i
	_highlight(_elem_buttons, _elem_active, TAB_COLORS[2])
	element_selected.emit(str(BiomeElementsLib.NAMES[i]))


# ── ARTIFACTS tab ─────────────────────────────────────────────────────
func _build_artifact_page(parent: VBoxContainer) -> void:
	_section(parent, "PALETTE", TAB_COLORS[1])
	var note := Label.new()
	note.text = "Browse the registered artifacts, then PLACE\non the cell you point at — grabbable, re-snapping."
	note.add_theme_font_size_override("font_size", 15)
	note.add_theme_color_override("font_color", DIM)
	parent.add_child(note)

	# SEQUENCE selector row — [◀] <sequence> [▶] cycles the filter (mirrors the web
	# /editor's sequence dropdown). The host fills the list via set_artifact_sequences.
	_section(parent, "SEQUENCE", DIM)
	var seq_row := HBoxContainer.new()
	seq_row.add_theme_constant_override("separation", 8)
	parent.add_child(seq_row)
	var seq_prev := _tool_button("◀", Vector2(56, 50))
	seq_prev.pressed.connect(func(): _cycle_sequence(-1))
	seq_row.add_child(seq_prev)
	_seq_label = Label.new()
	_seq_label.text = "ALL"
	_seq_label.add_theme_font_size_override("font_size", 18)
	_seq_label.add_theme_color_override("font_color", TAB_COLORS[1])
	_seq_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_seq_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_seq_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seq_label.custom_minimum_size = Vector2(160, 50)
	seq_row.add_child(_seq_label)
	var seq_next := _tool_button("▶", Vector2(56, 50))
	seq_next.pressed.connect(func(): _cycle_sequence(1))
	seq_row.add_child(seq_next)

	# PREVIEW — the currently selected artifact's name + index, set by the host on
	# every PREV/NEXT/filter change via set_artifact_preview(). The hover ghost in the
	# 3D view previews placement; this names what's about to drop.
	_section(parent, "SELECTED", TAB_COLORS[1])
	_artifact_preview = Label.new()
	_artifact_preview.text = "—"
	_artifact_preview.add_theme_font_size_override("font_size", 20)
	_artifact_preview.add_theme_color_override("font_color", FG)
	_artifact_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_artifact_preview.custom_minimum_size = Vector2(0, 56)
	parent.add_child(_artifact_preview)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	for action in ["◀ PREV", "NEXT ▶", "PLACE"]:
		var b := _tool_button(action, Vector2(158, 56))
		b.pressed.connect(func(): artifact_action.emit(action))
		row.add_child(b)


## Host API — set the cycleable sequence list (e.g. ["ALL", "forces", "color", …]).
## Always keeps "ALL" first; resets the active index to it.
func set_artifact_sequences(seqs: Array) -> void:
	var list: Array = ["ALL"]
	for s in seqs:
		var seq_name := str(s).strip_edges()
		if seq_name != "" and seq_name.to_upper() != "ALL" and not list.has(seq_name):
			list.append(seq_name)
	_artifact_sequences = list
	_seq_idx = 0
	if _seq_label:
		_seq_label.text = str(_artifact_sequences[_seq_idx])


## Host API — update the live preview to the selected artifact (name + n/total).
func set_artifact_preview(art_name: String, idx: int, total: int) -> void:
	if _artifact_preview == null:
		return
	if total <= 0 or art_name.strip_edges() == "":
		_artifact_preview.text = "—"
		return
	_artifact_preview.text = "%s\n(%d/%d)" % [art_name, idx + 1, total]


## Cycle the sequence filter and emit the new selection so the host re-filters.
func _cycle_sequence(delta: int) -> void:
	if _artifact_sequences.is_empty():
		return
	_seq_idx = wrapi(_seq_idx + delta, 0, _artifact_sequences.size())
	if _seq_label:
		_seq_label.text = str(_artifact_sequences[_seq_idx])
	artifact_sequence_changed.emit(str(_artifact_sequences[_seq_idx]))


# ── shared helpers ────────────────────────────────────────────────────
func _tool_button(txt: String, sz: Vector2) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = sz
	b.add_theme_font_size_override("font_size", 16)
	b.focus_mode = Control.FOCUS_NONE
	return b


func _section(parent: VBoxContainer, txt: String, col: Color) -> void:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)


func _slider_row(parent: VBoxContainer, cap: String, lo: float, hi: float, step: float, val: float, cb: Callable, init_txt: String) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var c := Label.new()
	c.text = cap
	c.add_theme_font_size_override("font_size", 14)
	c.add_theme_color_override("font_color", DIM)
	c.custom_minimum_size = Vector2(64, 0)
	row.add_child(c)
	var slider := HSlider.new()
	slider.min_value = lo; slider.max_value = hi; slider.step = step; slider.value = val
	slider.custom_minimum_size = Vector2(300, 38)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(cb)
	row.add_child(slider)
	var lbl := Label.new()
	lbl.text = init_txt
	lbl.add_theme_font_size_override("font_size", 19)
	lbl.add_theme_color_override("font_color", FG)
	lbl.custom_minimum_size = Vector2(56, 0)
	row.add_child(lbl)
	return lbl


func _on_tab(i: int) -> void:
	_active_tab = clampi(i, 0, TABS.size() - 1)
	for p in _pages.size():
		_pages[p].visible = (p == _active_tab)
	_refresh_tabs()
	tab_changed.emit(str(TABS[_active_tab]))


func _refresh_tabs() -> void:
	for i in _tab_buttons.size():
		_style(_tab_buttons[i], TAB_COLORS[i], i == _active_tab)


func _highlight(buttons: Array, active: int, col: Color) -> void:
	for i in buttons.size():
		_style(buttons[i], col, i == active)


func _style(b: Button, col: Color, on: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col.r, col.g, col.b, 0.85 if on else 0.20)
	sb.set_corner_radius_all(7)
	if on:
		sb.set_border_width_all(3)
		sb.border_color = Color(1, 1, 1, 0.9)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_color_override("font_color", Color(0.05, 0.06, 0.09) if on else FG)


## 3D wrapper → keep the active tab in sync when a reach-stone selects a mode.
func set_active_tab(tab_id: String) -> void:
	var idx := TABS.find(tab_id.to_upper())
	if idx >= 0:
		_on_tab(idx)
