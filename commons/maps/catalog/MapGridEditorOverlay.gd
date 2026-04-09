class_name MapGridEditorOverlay
extends CanvasLayer

signal cell_selected(x: int, z: int)
signal cell_painted(layer: int, x: int, z: int, value: String)
signal artifact_placed(x: int, z: int, value: String)

const CELL_SIZE := 22
const HEIGHT_COLORS := {
	"0": Color(0.06, 0.06, 0.08), "1": Color(0.3, 0.3, 0.35),
	"2": Color(0.4, 0.4, 0.45), "3": Color(0.5, 0.5, 0.55),
	"4": Color(0.6, 0.6, 0.65), "5": Color(0.7, 0.7, 0.75),
	"6": Color(0.5, 0.12, 0.12),
}
const UTILITY_COLORS := {
	"sp": Color(0.2, 1.0, 0.3), "s": Color(0.2, 1.0, 0.3),
	"t": Color(0.2, 0.5, 1.0), "3t": Color(0.2, 0.5, 1.0),
	"r": Color(1.0, 0.8, 0.2), "wp": Color(1.0, 0.8, 0.2),
	"tc": Color(0.8, 0.4, 1.0), "m": Color(0.5, 0.5, 0.5),
	"ds": Color(1.0, 0.3, 0.3), "sub": Color(0.3, 0.8, 0.8),
}

var structure_layer: Array = []
var utilities_layer: Array = []
var interactables_layer: Array = []
var grid_width: int = 0
var grid_depth: int = 0
var active_layer: int = 0
var paint_value: String = "1"
var is_painting: bool = false
var selected_cell: Vector2i = Vector2i(-1, -1)

var _root: Control
var _panel: PanelContainer
var _grid_canvas: Control
var _layer_tabs: TabBar
var _palette: HBoxContainer
var _insp_panel: PanelContainer
var _insp_name: Label
var _insp_detail: RichTextLabel
var _artifact_input: LineEdit

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "GridEditorRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# Grid editor panel (top-right)
	_panel = PanelContainer.new()
	_panel.name = "GridPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 0.6
	_panel.offset_left = 5
	_panel.offset_top = 5
	_panel.offset_right = -5
	_root.add_child(_panel)

	var vbox := VBoxContainer.new()
	_panel.add_child(vbox)

	var toolbar := HBoxContainer.new()
	vbox.add_child(toolbar)

	var lbl := Label.new()
	lbl.text = "Grid Editor"
	lbl.add_theme_font_size_override("font_size", 14)
	toolbar.add_child(lbl)

	_layer_tabs = TabBar.new()
	_layer_tabs.add_tab("Structure")
	_layer_tabs.add_tab("Utilities")
	_layer_tabs.add_tab("Artifacts")
	_layer_tabs.tab_changed.connect(_on_layer_changed)
	toolbar.add_child(_layer_tabs)

	_palette = HBoxContainer.new()
	vbox.add_child(_palette)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_grid_canvas = Control.new()
	_grid_canvas.gui_input.connect(_on_grid_input)
	_grid_canvas.draw.connect(_on_grid_draw)
	scroll.add_child(_grid_canvas)

	# Inspector panel (bottom-right)
	_insp_panel = PanelContainer.new()
	_insp_panel.name = "InspPanel"
	_insp_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_insp_panel.anchor_left = 0.5
	_insp_panel.anchor_top = 0.6
	_insp_panel.anchor_right = 1.0
	_insp_panel.anchor_bottom = 1.0
	_insp_panel.offset_left = 5
	_insp_panel.offset_top = 5
	_insp_panel.offset_right = -5
	_insp_panel.offset_bottom = -5
	_root.add_child(_insp_panel)

	var ivbox := VBoxContainer.new()
	_insp_panel.add_child(ivbox)

	_insp_name = Label.new()
	_insp_name.text = "No cell"
	_insp_name.add_theme_font_size_override("font_size", 13)
	ivbox.add_child(_insp_name)

	var art_row := HBoxContainer.new()
	ivbox.add_child(art_row)
	var art_lbl := Label.new()
	art_lbl.text = "Artifact:"
	art_row.add_child(art_lbl)
	_artifact_input = LineEdit.new()
	_artifact_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_artifact_input.placeholder_text = "lookup:rot:y"
	_artifact_input.text_submitted.connect(_on_artifact_submitted)
	art_row.add_child(_artifact_input)

	_insp_detail = RichTextLabel.new()
	_insp_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_insp_detail.bbcode_enabled = true
	ivbox.add_child(_insp_detail)

	_build_palette()

func load_layers(structure: Array, utilities: Array, interactables: Array, w: int, d: int) -> void:
	structure_layer = structure
	utilities_layer = utilities
	interactables_layer = interactables
	grid_width = w
	grid_depth = d
	selected_cell = Vector2i(-1, -1)
	_grid_canvas.custom_minimum_size = Vector2(grid_width * CELL_SIZE + 1, grid_depth * CELL_SIZE + 1)
	_grid_canvas.queue_redraw()
	_update_inspector()

func _on_layer_changed(idx: int) -> void:
	active_layer = idx
	_build_palette()
	_grid_canvas.queue_redraw()

func _build_palette() -> void:
	for c in _palette.get_children(): c.queue_free()
	match active_layer:
		0:
			for h in range(7):
				var btn := Button.new()
				btn.text = str(h)
				btn.custom_minimum_size = Vector2(26, 22)
				var hstr := str(h)
				btn.pressed.connect(func(): paint_value = hstr)
				_palette.add_child(btn)
			paint_value = "1"
		1:
			for code in ["sp", "t", "r", "wp", "tc", "m", "ds", "sub", " "]:
				var btn := Button.new()
				btn.text = code if code != " " else "x"
				btn.custom_minimum_size = Vector2(30, 22)
				var c: String = code
				btn.pressed.connect(func(): paint_value = c)
				_palette.add_child(btn)
			paint_value = "sp"
		2:
			var l := Label.new()
			l.text = "Select cell → type in inspector"
			l.add_theme_font_size_override("font_size", 11)
			_palette.add_child(l)

func _on_grid_draw() -> void:
	if structure_layer.is_empty(): return
	var font: Font = ThemeDB.fallback_font
	for z in range(grid_depth):
		for x in range(grid_width):
			var rect := Rect2(x * CELL_SIZE, z * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			var h_str: String = str(structure_layer[z][x]) if z < structure_layer.size() and x < structure_layer[z].size() else "0"
			var bg: Color = HEIGHT_COLORS.get(h_str, Color(0.15, 0.15, 0.15))
			if active_layer != 0: bg = bg.darkened(0.3)
			_grid_canvas.draw_rect(rect, bg)

			var u: String = str(utilities_layer[z][x]).strip_edges() if z < utilities_layer.size() and x < utilities_layer[z].size() else ""
			if u != "" and u != " ":
				var code := u.split(":")[0]
				var uc: Color = UTILITY_COLORS.get(code, Color(0.7, 0.7, 0.7))
				if active_layer != 1: uc.a = 0.35
				_grid_canvas.draw_rect(rect.grow(-2), uc, false, 2.0)
				_grid_canvas.draw_string(font, rect.position + Vector2(2, 9), code, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, uc)

			var a: String = str(interactables_layer[z][x]).strip_edges() if z < interactables_layer.size() and x < interactables_layer[z].size() else ""
			if a != "" and a != " ":
				var ic := Color(1.0, 0.7, 0.2, 0.8 if active_layer == 2 else 0.25)
				_grid_canvas.draw_circle(rect.get_center(), CELL_SIZE * 0.3, ic)
				_grid_canvas.draw_string(font, rect.position + Vector2(1, CELL_SIZE - 2), a.split(":")[0].substr(0, 4), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, ic)

			_grid_canvas.draw_rect(rect, Color(0.18, 0.18, 0.22), false, 1.0)
			if Vector2i(x, z) == selected_cell:
				_grid_canvas.draw_rect(rect.grow(-1), Color(1.0, 1.0, 0.3, 0.7), false, 2.0)

func _on_grid_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_painting = event.pressed
		if event.pressed: _cell_action(event.position)
	elif event is InputEventMouseMotion and is_painting:
		_cell_action(event.position)

func _cell_action(pos: Vector2) -> void:
	var x := int(pos.x / CELL_SIZE)
	var z := int(pos.y / CELL_SIZE)
	if x < 0 or x >= grid_width or z < 0 or z >= grid_depth: return
	selected_cell = Vector2i(x, z)
	match active_layer:
		0:
			structure_layer[z][x] = paint_value
			cell_painted.emit(0, x, z, paint_value)
		1:
			utilities_layer[z][x] = paint_value
			cell_painted.emit(1, x, z, paint_value)
	_grid_canvas.queue_redraw()
	_update_inspector()
	cell_selected.emit(x, z)

func _on_artifact_submitted(text: String) -> void:
	if selected_cell.x < 0 or selected_cell.y < 0: return
	var val := text if text != "" else " "
	interactables_layer[selected_cell.y][selected_cell.x] = val
	_grid_canvas.queue_redraw()
	_update_inspector()
	artifact_placed.emit(selected_cell.x, selected_cell.y, val)

func _update_inspector() -> void:
	if selected_cell.x < 0:
		_insp_name.text = "No cell"
		_insp_detail.text = ""
		_artifact_input.text = ""
		return
	var x := selected_cell.x
	var z := selected_cell.y
	_insp_name.text = "[%d, %d]" % [x, z]
	var h: String = str(structure_layer[z][x]) if z < structure_layer.size() else "?"
	var u: String = str(utilities_layer[z][x]).strip_edges() if z < utilities_layer.size() else ""
	var a: String = str(interactables_layer[z][x]).strip_edges() if z < interactables_layer.size() else ""
	_artifact_input.text = a if a != " " else ""
	var t := "[b]H:[/b] %s" % h
	if u != "" and u != " ": t += "  [b]U:[/b] %s" % u
	if a != "" and a != " ": t += "\n[b]Art:[/b] %s" % a
	_insp_detail.text = t
