# grid_editor_board.gd
# Interactive grid layout editor — Godot VR mirror of the web grid-editor,
# starting with the Control Board subset (Black Mesa aesthetic).
# Upright XY panel with a 24×14 cell grid, category-coloured element palette,
# preset loaders, and placement tools.
#
# Algorithm: 2D occupancy-grid placement system. Each element has a width×height
# in grid cells. Placement checks a boolean occupancy array for collisions,
# stamps the instance ID into occupied cells, and renders category-coloured quads
# on an upright XY back-panel. Grid lines use MultiMesh for GPU instancing.
#
# Layout: XY back-panel (like control_board / pattern_maker_station).
# Elements rendered as category-coloured rectangles with name labels.
extends Node3D
class_name GridEditorBoard

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")
const CBS = preload("res://commons/artifacts/grid_editor_board/control_board_subset.gd")

# ── Colours ────────────────────────────────────────────────────────────
const COL_PANEL     := Color(0.08, 0.08, 0.10)
const COL_BEZEL     := Color(0.12, 0.12, 0.14)
const COL_GRID_BG   := Color(0.04, 0.04, 0.06)
const COL_GRID_LINE := Color(0.18, 0.18, 0.22, 0.5)
const COL_HIGHLIGHT := Color(0.0, 0.8, 1.0)

# ── Layout constants ──────────────────────────────────────────────────
const RAIL_WIDTH := 0.025
const PANEL_DEPTH := 0.04
const RAIL_DEPTH := 0.06
const LINE_THICKNESS := 0.0008
const LINE_DEPTH := 0.001
const GRID_LINE_Z := 0.004
const GRID_BG_Z := 0.002
const FRAME_WIDTH := 0.005
const FRAME_DEPTH := 0.008
const ELEMENT_PADDING := 0.003
const ELEMENT_Z := 0.006
const HIGHLIGHT_Z := 0.009

# ── Config ─────────────────────────────────────────────────────────────
## Width of the back panel in metres
@export_range(0.5, 5.0, 0.1) var panel_width: float = 2.8
## Height of the back panel in metres
@export_range(0.3, 3.0, 0.1) var panel_height: float = 1.4
## Size of each grid cell in metres
@export_range(0.02, 0.2, 0.01) var cell_size: float = 0.06
## Left margin before the grid starts
@export_range(0.0, 0.5, 0.01) var grid_margin_left: float = 0.08
## Default number of grid columns
@export_range(4, 48) var default_grid_w: int = 24
## Default number of grid rows
@export_range(4, 32) var default_grid_h: int = 14

# ── State ──────────────────────────────────────────────────────────────
var _grid_w: int = 24
var _grid_h: int = 14
var _occupancy: Array = []       # 2D [_grid_h][_grid_w] of String ("" = empty)
var _placements: Dictionary = {} # instance_id → {element, gx, gy, node}
var _next_id: int = 0
var _active_element: String = "" # element id being placed ("" = select mode)
var _selected_id: String = ""    # selected placement instance
var _current_preset_name: String = ""

# ── Refs ───────────────────────────────────────────────────────────────
var _grid_container: Node3D
var _placement_container: Node3D
var _status_label: Label3D
var _count_label: Label3D
var _grid_left: float            # local X of grid left edge
var _grid_bottom: float          # local Y of grid bottom edge
var _touch_area: Area3D
var _last_touch_cell: Vector2i = Vector2i(-1, -1)
var _highlight_rect: MeshInstance3D

# ── Shared materials ──────────────────────────────────────────────────
var _base_mat: StandardMaterial3D
var _bezel_mat: StandardMaterial3D
var _line_mat: StandardMaterial3D
var _frame_mat: StandardMaterial3D
var _highlight_mat: StandardMaterial3D

# ── Signal tracking ───────────────────────────────────────────────────
var _connected_buttons: Array = [] # [{area, callable}]

# ═══════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_init_materials()
	_init_occupancy(default_grid_w, default_grid_h)
	_build_back_panel()
	_build_grid()
	_build_palette()
	_build_presets()
	_build_tools()
	_build_status_label()
	_build_touch_area()
	_build_capture_camera()
	_load_preset(CBS.PRESET_MISSION_CONTROL)
	print("[GridEditorBoard] Built — %dx%d grid, cell %.3fm" % [
		_grid_w, _grid_h, cell_size])

func _process(_delta: float) -> void:
	_check_touch()

func _exit_tree() -> void:
	for entry in _connected_buttons:
		var area = entry["area"]
		var cb = entry["callable"]
		if is_instance_valid(area) and area.button_pressed.is_connected(cb):
			area.button_pressed.disconnect(cb)
	_connected_buttons.clear()

## Applies grid configuration from map_data config_data dictionary.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("preset"):
		var preset_id: String = str(config_data["preset"])
		for p in CBS.get_presets():
			if p["id"] == preset_id:
				_load_preset(p)
				break
	elif config_data.has("placements"):
		_clear_board()
		if config_data.has("grid_size"):
			var gs: Array = config_data["grid_size"]
			if gs.size() >= 2:
				_init_occupancy(int(gs[0]), int(gs[1]))
		var placements: Array = config_data["placements"]
		for p in placements:
			var pos: Array = p.get("position", [0, 0])
			_place_element(str(p["element"]), int(pos[0]), int(pos[1]))

# ═══════════════════════════════════════════════════════════════════════
# MATERIALS
# ═══════════════════════════════════════════════════════════════════════

func _init_materials() -> void:
	_base_mat = StandardMaterial3D.new()
	_base_mat.roughness = 0.7

	_bezel_mat = _mat(COL_BEZEL, 0.5, 0.5)

	_line_mat = StandardMaterial3D.new()
	_line_mat.albedo_color = COL_GRID_LINE
	_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_frame_mat = _mat(COL_BEZEL, 0.5, 0.5)

	_highlight_mat = StandardMaterial3D.new()
	_highlight_mat.albedo_color = Color(0.0, 0.8, 1.0, 0.3)
	_highlight_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight_mat.emission_enabled = true
	_highlight_mat.emission = COL_HIGHLIGHT
	_highlight_mat.emission_energy_multiplier = 1.5
	_highlight_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

# ═══════════════════════════════════════════════════════════════════════
# DATA
# ═══════════════════════════════════════════════════════════════════════

func _init_occupancy(w: int, h: int) -> void:
	_grid_w = w
	_grid_h = h
	_occupancy.clear()
	_occupancy.resize(_grid_h)
	for y in _grid_h:
		var row: Array = []
		row.resize(_grid_w)
		for x in _grid_w:
			row[x] = ""
		_occupancy[y] = row

## Removes all placed elements and resets state.
func _clear_board() -> void:
	for id in _placements:
		var p: Dictionary = _placements[id]
		if is_instance_valid(p["node"]):
			p["node"].queue_free()
	_placements.clear()
	_init_occupancy(_grid_w, _grid_h)
	_selected_id = ""
	_active_element = ""
	_next_id = 0
	_update_status()

# ═══════════════════════════════════════════════════════════════════════
# BUILDERS
# ═══════════════════════════════════════════════════════════════════════

func _build_back_panel() -> void:
	var plate := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(panel_width, panel_height, PANEL_DEPTH)
	plate.mesh = mesh
	plate.material_override = _mat(COL_PANEL, 0.3, 0.7)
	plate.position = Vector3(0, panel_height * 0.5, -0.02)
	add_child(plate)

	# Side trim rails
	var rail_mesh := BoxMesh.new()
	rail_mesh.size = Vector3(RAIL_WIDTH, panel_height, RAIL_DEPTH)
	for side in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		rail.mesh = rail_mesh
		rail.material_override = _bezel_mat
		rail.position = Vector3(side * panel_width * 0.5, panel_height * 0.5, -0.02)
		add_child(rail)

func _build_grid() -> void:
	_grid_container = Node3D.new()
	_grid_container.name = "GridContainer"
	add_child(_grid_container)

	_placement_container = Node3D.new()
	_placement_container.name = "Placements"
	add_child(_placement_container)

	var grid_w_m: float = _grid_w * cell_size
	var grid_h_m: float = _grid_h * cell_size

	_grid_left = -panel_width * 0.5 + grid_margin_left
	_grid_bottom = (panel_height - grid_h_m) * 0.5 - 0.03

	var cx := _grid_left + grid_w_m * 0.5
	var cy := _grid_bottom + grid_h_m * 0.5

	_build_grid_background(cx, cy, grid_w_m, grid_h_m)
	_build_grid_lines(cx, cy, grid_w_m, grid_h_m)
	_build_grid_frame(cx, cy, grid_w_m, grid_h_m)
	_build_grid_highlight()
	_build_grid_title()

## Grid background quad.
func _build_grid_background(cx: float, cy: float, grid_w_m: float, grid_h_m: float) -> void:
	var bg := MeshInstance3D.new()
	var bgm := QuadMesh.new()
	bgm.size = Vector2(grid_w_m, grid_h_m)
	bg.mesh = bgm
	bg.material_override = _mat(COL_GRID_BG, 0.0, 0.9)
	bg.position = Vector3(cx, cy, GRID_BG_Z)
	_grid_container.add_child(bg)

## Grid lines rendered via two MultiMeshInstance3D nodes (vertical + horizontal).
func _build_grid_lines(cx: float, cy: float, grid_w_m: float, grid_h_m: float) -> void:
	# Vertical lines
	var v_count := _grid_w + 1
	var v_mesh := BoxMesh.new()
	v_mesh.size = Vector3(LINE_THICKNESS, grid_h_m, LINE_DEPTH)

	var v_mm := MultiMesh.new()
	v_mm.transform_format = MultiMesh.TRANSFORM_3D
	v_mm.mesh = v_mesh
	v_mm.instance_count = v_count
	for i in v_count:
		var xf := Transform3D()
		xf.origin = Vector3(_grid_left + i * cell_size, cy, GRID_LINE_Z)
		v_mm.set_instance_transform(i, xf)

	var v_mmi := MultiMeshInstance3D.new()
	v_mmi.multimesh = v_mm
	v_mmi.material_override = _line_mat
	_grid_container.add_child(v_mmi)

	# Horizontal lines
	var h_count := _grid_h + 1
	var h_mesh := BoxMesh.new()
	h_mesh.size = Vector3(grid_w_m, LINE_THICKNESS, LINE_DEPTH)

	var h_mm := MultiMesh.new()
	h_mm.transform_format = MultiMesh.TRANSFORM_3D
	h_mm.mesh = h_mesh
	h_mm.instance_count = h_count
	for j in h_count:
		var xf := Transform3D()
		xf.origin = Vector3(cx, _grid_bottom + j * cell_size, GRID_LINE_Z)
		h_mm.set_instance_transform(j, xf)

	var h_mmi := MultiMeshInstance3D.new()
	h_mmi.multimesh = h_mm
	h_mmi.material_override = _line_mat
	_grid_container.add_child(h_mmi)

## Four frame bars around the grid area.
func _build_grid_frame(cx: float, cy: float, grid_w_m: float, grid_h_m: float) -> void:
	var fw := FRAME_WIDTH
	for data in [
		[Vector3(grid_w_m + fw * 2, fw, FRAME_DEPTH), Vector3(cx, cy + grid_h_m * 0.5 + fw * 0.5, 0.003)],
		[Vector3(grid_w_m + fw * 2, fw, FRAME_DEPTH), Vector3(cx, cy - grid_h_m * 0.5 - fw * 0.5, 0.003)],
		[Vector3(fw, grid_h_m, FRAME_DEPTH), Vector3(cx - grid_w_m * 0.5 - fw * 0.5, cy, 0.003)],
		[Vector3(fw, grid_h_m, FRAME_DEPTH), Vector3(cx + grid_w_m * 0.5 + fw * 0.5, cy, 0.003)],
	]:
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = data[0]
		bar.mesh = bm
		bar.material_override = _frame_mat
		bar.position = data[1]
		_grid_container.add_child(bar)

## Selection highlight quad, hidden until a placement is selected.
func _build_grid_highlight() -> void:
	_highlight_rect = MeshInstance3D.new()
	_highlight_rect.name = "Highlight"
	var hq := QuadMesh.new()
	hq.size = Vector2(cell_size, cell_size)
	_highlight_rect.mesh = hq
	_highlight_rect.material_override = _highlight_mat
	_highlight_rect.visible = false
	_highlight_rect.position.z = HIGHLIGHT_Z
	add_child(_highlight_rect)

func _build_grid_title() -> void:
	var title := Label3D.new()
	title.text = "GRID EDITOR — CONTROL BOARD"
	title.pixel_size = 0.0008
	title.font_size = 14
	title.modulate = Color(0.7, 0.7, 0.7)
	title.position = Vector3(_grid_left, panel_height - 0.025, 0.01)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(title)

func _build_palette() -> void:
	var palette_left: float = _grid_left + _grid_w * cell_size + 0.06
	var palette_right: float = panel_width * 0.5 - 0.04
	var palette_w: float = palette_right - palette_left
	var start_y: float = panel_height - 0.08
	var y_cursor: float = start_y
	var col_count: int = 3
	var tile_w: float = (palette_w - 0.02) / col_count
	var tile_h: float = 0.028
	var row_gap: float = 0.032
	var cat_gap: float = 0.012

	# "ELEMENTS" header
	var header := Label3D.new()
	header.text = "ELEMENTS"
	header.pixel_size = 0.0006
	header.font_size = 8
	header.modulate = Color(0.5, 0.5, 0.5)
	header.position = Vector3(palette_left, y_cursor, 0.01)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(header)
	y_cursor -= 0.025

	for cat in CBS.CATEGORIES:
		var cat_id: String = cat["id"]
		var cat_color: Color = CBS.get_category_color(cat_id)

		y_cursor = _build_palette_category_header(palette_left, y_cursor, cat, cat_color)

		var cat_elements: Array = []
		for el in CBS.ELEMENTS:
			if el["category"] == cat_id:
				cat_elements.append(el)

		y_cursor = _build_palette_tiles(
			palette_left, y_cursor, cat_elements, cat_color,
			col_count, tile_w, tile_h, row_gap, cat_gap)

## Builds the coloured dot + name header for a palette category. Returns updated y_cursor.
func _build_palette_category_header(palette_left: float, y_cursor: float, cat: Dictionary, cat_color: Color) -> float:
	var dot := MeshInstance3D.new()
	var dm := QuadMesh.new()
	dm.size = Vector2(0.01, 0.01)
	dot.mesh = dm
	var dot_mat := _base_mat.duplicate() as StandardMaterial3D
	dot_mat.albedo_color = cat_color
	dot_mat.emission_enabled = true
	dot_mat.emission = cat_color
	dot_mat.emission_energy_multiplier = 1.0
	dot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dot.material_override = dot_mat
	dot.position = Vector3(palette_left + 0.008, y_cursor, 0.008)
	add_child(dot)

	var cat_lbl := Label3D.new()
	cat_lbl.text = cat["name"]
	cat_lbl.pixel_size = 0.0005
	cat_lbl.font_size = 7
	cat_lbl.modulate = cat_color.lightened(0.3)
	cat_lbl.position = Vector3(palette_left + 0.02, y_cursor, 0.01)
	cat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(cat_lbl)
	return y_cursor - 0.018

## Lays out element tiles in rows for one category. Returns updated y_cursor.
func _build_palette_tiles(
	palette_left: float, y_cursor: float, cat_elements: Array, cat_color: Color,
	col_count: int, tile_w: float, _tile_h: float, row_gap: float, cat_gap: float
) -> float:
	var tile_mat := _base_mat.duplicate() as StandardMaterial3D
	tile_mat.albedo_color = cat_color.darkened(0.4)

	for i in cat_elements.size():
		var col_i: int = i % col_count
		var row_i: int = i / col_count
		var el: Dictionary = cat_elements[i]

		var tile := MeshInstance3D.new()
		var tm := QuadMesh.new()
		tm.size = Vector2(tile_w - 0.004, _tile_h - 0.004)
		tile.mesh = tm
		tile.material_override = tile_mat
		var tx: float = palette_left + col_i * tile_w + tile_w * 0.5
		var ty: float = y_cursor - row_i * row_gap
		tile.position = Vector3(tx, ty, 0.006)
		add_child(tile)

		var el_lbl := Label3D.new()
		el_lbl.text = el["name"]
		el_lbl.pixel_size = 0.0004
		el_lbl.font_size = 5
		el_lbl.modulate = Color(0.8, 0.8, 0.8)
		el_lbl.position = Vector3(tx, ty, 0.008)
		add_child(el_lbl)

		var size_lbl := Label3D.new()
		size_lbl.text = "%dx%d" % [el["w"], el["h"]]
		size_lbl.pixel_size = 0.0003
		size_lbl.font_size = 4
		size_lbl.modulate = Color(0.4, 0.4, 0.4)
		size_lbl.position = Vector3(tx, ty - 0.008, 0.008)
		add_child(size_lbl)

	var total_rows: int = ceili(float(cat_elements.size()) / maxf(col_count, 1))
	return y_cursor - total_rows * row_gap - cat_gap

func _build_presets() -> void:
	var presets: Array[Dictionary] = CBS.get_presets()
	var btn_labels: Array[String] = ["MC", "SRV", "COM", "CLR"]
	var btn_x_start: float = panel_width * 0.5 - 0.38
	var btn_y: float = panel_height - 0.03

	for i in presets.size():
		var btn := PUSH_BUTTON.instantiate()
		btn.name = "Preset_%s" % presets[i]["id"]
		btn.position = Vector3(btn_x_start + i * 0.08, btn_y, 0.02)
		btn.scale = Vector3(0.45, 0.45, 0.45)
		var is_empty: bool = presets[i]["id"] == "empty"
		btn.pressed_color = Color(0.7, 0.2, 0.2) if is_empty else Color(0.2, 0.5, 0.8)
		btn.released_color = Color(0.35, 0.1, 0.1) if is_empty else Color(0.1, 0.25, 0.4)
		add_child(btn)

		var preset: Dictionary = presets[i]
		_connect_btn(btn, func(): _load_preset(preset))

		var lbl := Label3D.new()
		lbl.text = btn_labels[i]
		lbl.pixel_size = 0.0005
		lbl.font_size = 6
		lbl.modulate = Color(0.6, 0.6, 0.6)
		lbl.position = Vector3(0, -0.025, 0)
		btn.add_child(lbl)

	var name_lbl := Label3D.new()
	name_lbl.text = "PRESETS"
	name_lbl.pixel_size = 0.0005
	name_lbl.font_size = 6
	name_lbl.modulate = Color(0.4, 0.4, 0.4)
	name_lbl.position = Vector3(btn_x_start + 0.12, btn_y + 0.025, 0.01)
	add_child(name_lbl)

func _build_tools() -> void:
	var tools_y: float = 0.04
	var tools_x: float = _grid_left + _grid_w * cell_size * 0.5

	var del_btn := PUSH_BUTTON.instantiate()
	del_btn.name = "DeleteBtn"
	del_btn.position = Vector3(tools_x + 0.15, tools_y, 0.02)
	del_btn.scale = Vector3(0.5, 0.5, 0.5)
	del_btn.pressed_color = Color(0.8, 0.2, 0.2)
	del_btn.released_color = Color(0.4, 0.1, 0.1)
	add_child(del_btn)
	_connect_btn(del_btn, _delete_selected)
	_add_btn_label(del_btn, "DELETE")

	var clr_btn := PUSH_BUTTON.instantiate()
	clr_btn.name = "ClearBtn"
	clr_btn.position = Vector3(tools_x + 0.30, tools_y, 0.02)
	clr_btn.scale = Vector3(0.5, 0.5, 0.5)
	clr_btn.pressed_color = Color(0.7, 0.3, 0.1)
	clr_btn.released_color = Color(0.35, 0.15, 0.05)
	add_child(clr_btn)
	_connect_btn(clr_btn, _clear_board)
	_add_btn_label(clr_btn, "CLEAR")

func _build_status_label() -> void:
	_status_label = Label3D.new()
	_status_label.text = "READY"
	_status_label.pixel_size = 0.0006
	_status_label.font_size = 8
	_status_label.modulate = Color(0.3, 0.7, 0.3)
	_status_label.position = Vector3(_grid_left + 0.02, 0.04, 0.01)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_status_label)

	_count_label = Label3D.new()
	_count_label.text = "0 elements"
	_count_label.pixel_size = 0.0005
	_count_label.font_size = 7
	_count_label.modulate = Color(0.5, 0.5, 0.5)
	_count_label.position = Vector3(_grid_left + 0.02, 0.02, 0.01)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_count_label)

func _build_touch_area() -> void:
	_touch_area = Area3D.new()
	_touch_area.name = "GridTouchArea"
	_touch_area.collision_layer = 1048576   # Bit 20
	_touch_area.collision_mask = 393216     # Bits 18+19
	_touch_area.monitoring = true
	_touch_area.monitorable = false

	var grid_w_m: float = _grid_w * cell_size
	var grid_h_m: float = _grid_h * cell_size
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(grid_w_m + 0.02, grid_h_m + 0.02, 0.06)
	collision.shape = shape
	collision.position = Vector3(
		_grid_left + grid_w_m * 0.5,
		_grid_bottom + grid_h_m * 0.5,
		0.01
	)
	_touch_area.add_child(collision)
	add_child(_touch_area)

func _build_capture_camera() -> void:
	var cam := Camera3D.new()
	cam.name = "CaptureCamera"
	cam.fov = 55.0
	add_child(cam)
	cam.position = Vector3(0.2, 1.0, 3.0)
	cam.look_at(Vector3(0.0, 0.65, 0.0), Vector3.UP)

# ═══════════════════════════════════════════════════════════════════════
# PRESET LOADING
# ═══════════════════════════════════════════════════════════════════════

func _load_preset(preset: Dictionary) -> void:
	_clear_board()
	_current_preset_name = preset.get("name", "")

	var pw: int = int(preset.get("grid_w", default_grid_w))
	var ph: int = int(preset.get("grid_h", default_grid_h))
	if pw != _grid_w or ph != _grid_h:
		_init_occupancy(pw, ph)

	var placements: Array = preset.get("placements", [])
	for p in placements:
		var el_id: String = str(p["element"])
		var gx: int = int(p["x"])
		var gy: int = int(p["y"])
		_place_element(el_id, gx, gy)

	_update_status()
	print("[GridEditorBoard] Loaded preset '%s' — %d elements" % [
		_current_preset_name, _placements.size()])

# ═══════════════════════════════════════════════════════════════════════
# PLACEMENT
# ═══════════════════════════════════════════════════════════════════════

func _place_element(el_id: String, gx: int, gy: int) -> void:
	var el: Dictionary = CBS.get_element(el_id)
	if el.is_empty():
		push_warning("[GridEditorBoard] Unknown element: %s" % el_id)
		return

	var ew: int = int(el["w"])
	var eh: int = int(el["h"])

	if not _can_place(gx, gy, ew, eh):
		return

	var inst_id: String = "p_%d" % _next_id
	_next_id += 1

	_stamp_occupancy(gx, gy, ew, eh, inst_id)

	var cat_color: Color = CBS.get_category_color(el["category"])
	var node := _create_element_visual(el_id, el, ew, eh, cat_color)
	node.name = inst_id
	node.position = _grid_cell_to_local_center(gx, gy, ew, eh)
	_placement_container.add_child(node)

	_placements[inst_id] = {
		"element": el_id,
		"gx": gx,
		"gy": gy,
		"node": node,
		"mat": node.get_child(0).material_override as StandardMaterial3D,
	}

## Checks bounds and occupancy for placing an element of size ew×eh at grid position gx, gy.
func _can_place(gx: int, gy: int, ew: int, eh: int) -> bool:
	if gx < 0 or gy < 0 or gx + ew > _grid_w or gy + eh > _grid_h:
		return false
	for dy in eh:
		for dx in ew:
			if _occupancy[gy + dy][gx + dx] != "":
				return false
	return true

## Writes inst_id into the occupancy grid for the given rectangle.
func _stamp_occupancy(gx: int, gy: int, ew: int, eh: int, inst_id: String) -> void:
	for dy in eh:
		for dx in ew:
			_occupancy[gy + dy][gx + dx] = inst_id

## Creates the Node3D visual for a placed element (rect + bezel + labels).
func _create_element_visual(el_id: String, el: Dictionary, ew: int, eh: int, cat_color: Color) -> Node3D:
	var node := Node3D.new()

	# Element rectangle
	var rect := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(ew * cell_size - ELEMENT_PADDING * 2, eh * cell_size - ELEMENT_PADDING * 2)
	rect.mesh = qm
	var rect_mat := _base_mat.duplicate() as StandardMaterial3D
	rect_mat.albedo_color = cat_color.darkened(0.2)
	rect_mat.emission_enabled = true
	rect_mat.emission = cat_color
	rect_mat.emission_energy_multiplier = 0.3
	rect_mat.roughness = 0.6
	rect.material_override = rect_mat
	node.add_child(rect)

	# Bezel
	var bezel := MeshInstance3D.new()
	var bm := QuadMesh.new()
	bm.size = Vector2(ew * cell_size, eh * cell_size)
	bezel.mesh = bm
	bezel.material_override = _mat(cat_color.darkened(0.5), 0.3, 0.6)
	bezel.position.z = -0.001
	node.add_child(bezel)

	# Name label
	var name_lbl := Label3D.new()
	name_lbl.text = el["name"]
	name_lbl.pixel_size = 0.0004
	name_lbl.font_size = 5
	name_lbl.modulate = Color(0.9, 0.9, 0.9)
	name_lbl.position.z = 0.001
	if eh > 2:
		name_lbl.position.y = -0.01
	node.add_child(name_lbl)

	# ID label
	var id_lbl := Label3D.new()
	id_lbl.text = el_id
	id_lbl.pixel_size = 0.0003
	id_lbl.font_size = 4
	id_lbl.modulate = Color(0.5, 0.5, 0.5, 0.7)
	id_lbl.position = Vector3(0, name_lbl.position.y - 0.012, 0.001)
	node.add_child(id_lbl)

	return node

func _grid_cell_to_local_center(gx: int, gy: int, w: int, h: int) -> Vector3:
	var x: float = _grid_left + (gx + w * 0.5) * cell_size
	var y: float = _grid_bottom + (_grid_h - gy - h * 0.5) * cell_size
	return Vector3(x, y, ELEMENT_Z)

func _grid_pos_from_local(local_pos: Vector3) -> Vector2i:
	var gx: int = int((local_pos.x - _grid_left) / maxf(cell_size, 0.0001))
	var gy: int = _grid_h - 1 - int((local_pos.y - _grid_bottom) / maxf(cell_size, 0.0001))
	return Vector2i(gx, gy)

# ═══════════════════════════════════════════════════════════════════════
# INTERACTIONS
# ═══════════════════════════════════════════════════════════════════════

func _check_touch() -> void:
	if not is_instance_valid(_touch_area):
		return
	var bodies := _touch_area.get_overlapping_bodies()
	if bodies.is_empty():
		_last_touch_cell = Vector2i(-1, -1)
		return

	for body in bodies:
		var local_pos := to_local(body.global_position)
		var cell := _grid_pos_from_local(local_pos)

		if cell.x < 0 or cell.x >= _grid_w or cell.y < 0 or cell.y >= _grid_h:
			continue

		if cell != _last_touch_cell:
			_last_touch_cell = cell
			_on_grid_touch(cell.x, cell.y)
		return

func _on_grid_touch(gx: int, gy: int) -> void:
	var occupant: String = _occupancy[gy][gx]
	if occupant != "":
		_select_placement(occupant)
	elif _active_element != "":
		_place_element(_active_element, gx, gy)
		_update_status()

func _select_placement(inst_id: String) -> void:
	if _selected_id != "" and _placements.has(_selected_id):
		var prev: Dictionary = _placements[_selected_id]
		var pmat: StandardMaterial3D = prev["mat"]
		pmat.emission_energy_multiplier = 0.3

	_selected_id = inst_id
	if _placements.has(inst_id):
		var sel: Dictionary = _placements[inst_id]
		var smat: StandardMaterial3D = sel["mat"]
		smat.emission_energy_multiplier = 1.5

		var el: Dictionary = CBS.get_element(sel["element"])
		if not el.is_empty():
			var ew: int = int(el["w"])
			var eh: int = int(el["h"])
			var hq: QuadMesh = _highlight_rect.mesh as QuadMesh
			hq.size = Vector2(ew * cell_size + 0.004, eh * cell_size + 0.004)
			_highlight_rect.position = _grid_cell_to_local_center(
				int(sel["gx"]), int(sel["gy"]), ew, eh)
			_highlight_rect.position.z = HIGHLIGHT_Z
			_highlight_rect.visible = true

	_update_status()
	print("[GridEditorBoard] Selected: %s (%s)" % [inst_id,
		_placements[inst_id]["element"] if _placements.has(inst_id) else "?"])

func _delete_selected() -> void:
	if _selected_id == "" or not _placements.has(_selected_id):
		return

	var sel: Dictionary = _placements[_selected_id]
	var el: Dictionary = CBS.get_element(sel["element"])
	var gx: int = int(sel["gx"])
	var gy: int = int(sel["gy"])
	var ew: int = int(el.get("w", 1))
	var eh: int = int(el.get("h", 1))

	for dy in eh:
		for dx in ew:
			if gy + dy < _grid_h and gx + dx < _grid_w:
				_occupancy[gy + dy][gx + dx] = ""

	if is_instance_valid(sel["node"]):
		sel["node"].queue_free()
	_placements.erase(_selected_id)
	_selected_id = ""
	_highlight_rect.visible = false
	_update_status()
	print("[GridEditorBoard] Deleted element")

func _update_status() -> void:
	if not is_instance_valid(_status_label):
		return
	if _selected_id != "" and _placements.has(_selected_id):
		var el_id: String = _placements[_selected_id]["element"]
		var el: Dictionary = CBS.get_element(el_id)
		_status_label.text = "SEL: %s" % el.get("name", el_id)
		_status_label.modulate = COL_HIGHLIGHT
	elif _active_element != "":
		var el: Dictionary = CBS.get_element(_active_element)
		_status_label.text = "PLACE: %s" % el.get("name", _active_element)
		_status_label.modulate = Color(0.8, 0.6, 0.2)
	else:
		_status_label.text = _current_preset_name if _current_preset_name != "" else "READY"
		_status_label.modulate = Color(0.3, 0.7, 0.3)

	if is_instance_valid(_count_label):
		_count_label.text = "%d elements" % _placements.size()

# ═══════════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════════

func _mat(color: Color, metallic: float = 0.0, roughness: float = 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m

func _connect_btn(btn: Node, callback: Callable) -> void:
	var area := btn.get_node_or_null("InteractableAreaButton")
	if area:
		var cb := func(_b): callback.call()
		area.button_pressed.connect(cb)
		_connected_buttons.append({"area": area, "callable": cb})

func _add_btn_label(btn: Node, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0005
	lbl.font_size = 6
	lbl.modulate = Color(0.6, 0.6, 0.6)
	lbl.position = Vector3(0, -0.025, 0)
	btn.add_child(lbl)
