extends Node3D

## Pattern Studio Plate — Full port of Three.js PatternMaker3D
##
## A cream plate (0.52 x 0.50m) with:
## - 4x4 interactive paint grid (top-left) with recess
## - 3x3 color palette (top-right) with copper selection indicators
## - 6 horizontal sliders: MOTIF, GROUP, PERIOD, SIZE, ZONE, SITE
## - Control buttons: CLEAR, MIRROR, ROTATE
## - Carpet output on floor (1.0 x 0.7m)
##
## Uses WallpaperGroups for 17 mathematical symmetry patterns.
## Slider handles are slider_horizontal.tscn for real VR interaction.
## Grid cells and palette swatches use push_button.tscn (hidden visuals).

const WallpaperGroups = preload("res://commons/primitives/arrays/wallpaper_groups.gd")

# ── Rams palette ─────────────────────────────────────────────────────
const CREAM := Color(0.90, 0.87, 0.80)
const CREAM_LIGHT := Color(0.93, 0.91, 0.85)
const WARM_DARK := Color(0.25, 0.23, 0.20)
const COPPER := Color(0.75, 0.38, 0.13)
const RECESS := Color(0.82, 0.79, 0.72)
const DARK := Color(0.12, 0.12, 0.12)
const DARK_RECESS := Color(0.16, 0.15, 0.12)
const TRACK_COLOR := Color(0.05, 0.05, 0.05)

# ── Layout ───────────────────────────────────────────────────────────
const PLATE_W := 0.52
const PLATE_H := 0.50
const PLATE_Y := 1.0
const CARPET_Y := -0.99
const CARPET_Z := -1.0
const GRID_SIZE := 4
const CELL_SIZE := 0.032
const GRID_TOTAL := GRID_SIZE * CELL_SIZE
const CARPET_W := 3.0
const CARPET_H := 2.1

# ── Tile palette (9 colors, matching Three.js PALETTE) ───────────────
var palette: Array[Color] = [
	Color(0.95, 0.92, 0.85),   # 0: Cream
	Color(0.80, 0.20, 0.15),   # 1: Vermilion
	Color(0.15, 0.25, 0.50),   # 2: Cobalt
	Color(0.70, 0.55, 0.20),   # 3: Ochre
	Color(0.20, 0.40, 0.25),   # 4: Viridian
	Color(0.40, 0.20, 0.15),   # 5: Umber
	Color(0.10, 0.10, 0.12),   # 6: Charcoal
	Color(0.60, 0.30, 0.50),   # 7: Mauve
	Color(0.50, 0.70, 0.80),   # 8: Sky
]

const PALETTE_NAMES: Array[String] = [
	"Cream", "Vermilion", "Cobalt", "Ochre",
	"Viridian", "Umber", "Charcoal", "Mauve", "Sky",
]

# ── Wallpaper group names ────────────────────────────────────────────
const GROUPS: Array[String] = [
	"P1","P2","PM","PG","PMM","PMG","PGG","CM","CMM",
	"P4","P4M","P4G","P3","P3M1","P31M","P6","P6M"
]

# ── Motif data (from ITALY_PACK) ────────────────────────────────────
# Each: {name, group, domain_size, data}
var MOTIFS: Array[Dictionary] = [
	{"name": "Checkerboard", "group": "P4M", "domain_size": 2, "data": [
		[0, 1], [1, 0]]},
	{"name": "Greek Key", "group": "PMM", "domain_size": 8, "data": [
		[1,1,1,1,1,1,1,0],[0,0,0,0,0,0,1,0],[0,1,1,1,1,0,1,0],[0,1,0,0,1,0,1,0],
		[0,1,0,1,1,0,1,0],[0,1,0,0,0,0,1,0],[0,1,1,1,1,1,1,0],[0,0,0,0,0,0,0,0]]},
	{"name": "Wave Scroll", "group": "PG", "domain_size": 6, "data": [
		[0,0,1,1,0,0],[0,1,0,0,1,0],[1,0,0,0,0,1],
		[1,0,0,0,0,1],[0,1,0,0,1,0],[0,0,1,1,0,0]]},
	{"name": "Guilloche", "group": "PM", "domain_size": 6, "data": [
		[0,1,1,1,1,0],[1,0,0,0,0,1],[1,0,2,2,0,1],
		[1,0,2,2,0,1],[1,0,0,0,0,1],[0,1,1,1,1,0]]},
	{"name": "Diamond Lozenge", "group": "CMM", "domain_size": 4, "data": [
		[0,0,1,0],[0,1,1,1],[1,1,0,1],[0,1,0,0]]},
	{"name": "Octagon Square", "group": "P4M", "domain_size": 6, "data": [
		[0,1,1,1,1,0],[1,1,0,0,1,1],[1,0,0,0,0,1],
		[1,0,0,0,0,1],[1,1,0,0,1,1],[0,1,1,1,1,0]]},
	{"name": "Perspective Cubes", "group": "P3M1", "domain_size": 6, "data": [
		[0,0,1,1,2,2],[0,0,1,1,2,2],[2,2,0,0,1,1],
		[2,2,0,0,1,1],[1,1,2,2,0,0],[1,1,2,2,0,0]]},
	{"name": "Hex Rosette", "group": "P6M", "domain_size": 8, "data": [
		[0,0,0,1,1,0,0,0],[0,0,1,2,2,1,0,0],[0,1,2,1,1,2,1,0],[1,2,1,0,0,1,2,1],
		[1,2,1,0,0,1,2,1],[0,1,2,1,1,2,1,0],[0,0,1,2,2,1,0,0],[0,0,0,1,1,0,0,0]]},
	{"name": "Eight-Pointed Star", "group": "P4M", "domain_size": 8, "data": [
		[0,0,0,1,1,0,0,0],[0,0,1,1,1,1,0,0],[0,1,1,0,0,1,1,0],[1,1,0,0,0,0,1,1],
		[1,1,0,0,0,0,1,1],[0,1,1,0,0,1,1,0],[0,0,1,1,1,1,0,0],[0,0,0,1,1,0,0,0]]},
	{"name": "Labyrinth", "group": "PM", "domain_size": 8, "data": [
		[1,1,1,1,1,1,1,1],[0,0,0,0,0,0,0,1],[1,1,1,1,1,1,0,1],[1,0,0,0,0,1,0,1],
		[1,0,1,1,0,1,0,1],[1,0,1,0,0,1,0,1],[1,0,1,1,1,1,0,1],[1,0,0,0,0,0,0,1]]},
]

# ── Period palettes (from ITALY_PACK) ────────────────────────────────
const PERIODS: Array[Dictionary] = [
	{"name": "Republican", "colors": ["#141418","#EBE6D9","#B8603C","#8B7355","#4A3728","#C4B99A","#6B4423","#2B1810"]},
	{"name": "Imperial", "colors": ["#141418","#EBE6D9","#B32719","#C09933","#267366","#D4A0A0","#5C3A1E","#8C7B6B"]},
	{"name": "Cosmatesque", "colors": ["#E8E0D4","#264D26","#8C1A26","#CCA329","#1A1A2E","#6B3A3A","#3D5C3D","#B8A88A"]},
	{"name": "Renaissance", "colors": ["#1F3380","#D9B333","#2D6633","#F0EAD6","#4D2666","#CC6644","#1A4D4D","#8C7B6B"]},
	{"name": "Baroque", "colors": ["#1A3399","#CCA329","#1A4D26","#CC6633","#F5F0E1","#0D0D0D","#8C1A3A","#5C4A32"]},
]

# Domain sizes
const SIZES: Array[int] = [2, 4, 6, 8]
const SIZE_NAMES: Array[String] = ["2x2", "4x4", "6x6", "8x8"]

# Zones
const ZONES: Array[String] = ["field", "border", "medallion", "threshold", "corner"]

# ── State ────────────────────────────────────────────────────────────
var selected_color: int = 1
var _grid_data: Array = []      # 2D array [y][x] of color indices
var wallpaper_group: int = 10   # P4M (index into GROUPS)
var _current_motif: int = 0
var _current_period: int = 1
var _current_size_idx: int = 1  # 4x4
var _current_zone: int = 0
var _current_site: int = 0
var _current_grid_size: int = 4

# ── Node references ──────────────────────────────────────────────────
var _grid_cells: Array = []
var _carpet_mesh: MeshInstance3D
var _palette_indicators: Array = []
var _cell_materials: Dictionary = {}
var _plate_parent: Node3D

# Slider references
var _motif_slider: Node = null
var _motif_value_label: Label3D = null
var _group_slider: Node = null
var _group_value_label: Label3D = null
var _period_slider: Node = null
var _period_value_label: Label3D = null
var _size_slider: Node = null
var _size_value_label: Label3D = null
var _zone_slider: Node = null
var _zone_value_label: Label3D = null
var _site_slider: Node = null
var _site_value_label: Label3D = null

# ── Signals ──────────────────────────────────────────────────────────
signal cell_changed(x: int, y: int, color_index: int)
signal group_changed(group_name: String)


func _ready() -> void:
	_initialize_grid_data()
	_load_motif(0)  # Load checkerboard as default

	# Plate container at eye height
	var plate_container := Node3D.new()
	plate_container.name = "PlateMount"
	plate_container.transform.origin = Vector3(0, PLATE_Y, 0)
	plate_container.rotation_degrees = Vector3(-15, 0, 0)
	add_child(plate_container)
	_plate_parent = plate_container

	_build_plate()
	_build_paint_grid()
	_build_palette()
	_build_sliders()
	_build_controls()
	_build_carpet()
	_update_carpet()


# ══════════════════════════════════════════════════════════════════════
# GRID DATA
# ══════════════════════════════════════════════════════════════════════

func _initialize_grid_data() -> void:
	_grid_data.clear()
	for y in _current_grid_size:
		var row: Array = []
		row.resize(_current_grid_size)
		for x in _current_grid_size:
			row[x] = 0
		_grid_data.append(row)


func set_cell(x: int, y: int, color_idx: int) -> void:
	if x < 0 or x >= _current_grid_size or y < 0 or y >= _current_grid_size:
		return
	_grid_data[y][x] = clampi(color_idx, 0, palette.size() - 1)
	var idx: int = y * _current_grid_size + x
	if idx < _grid_cells.size() and _grid_cells[idx]:
		_grid_cells[idx].material_override = _get_material(color_idx)
	_update_carpet()
	cell_changed.emit(x, y, color_idx)


func get_cell(x: int, y: int) -> int:
	if x < 0 or x >= _current_grid_size or y < 0 or y >= _current_grid_size:
		return 0
	return _grid_data[y][x]


# ══════════════════════════════════════════════════════════════════════
# BUILD PLATE — cream backing with dark frame and copper accent
# ══════════════════════════════════════════════════════════════════════

func _build_plate() -> void:
	# Dark frame
	var frame := MeshInstance3D.new()
	frame.name = "Frame"
	var fbox := BoxMesh.new()
	fbox.size = Vector3(PLATE_W + 0.006, PLATE_H + 0.006, 0.006)
	frame.mesh = fbox
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = WARM_DARK
	fmat.metallic = 0.2
	fmat.roughness = 0.6
	frame.material_override = fmat
	frame.transform.origin.z = -0.002
	_plate_parent.add_child(frame)

	# Cream panel
	var panel := MeshInstance3D.new()
	panel.name = "Panel"
	var pbox := BoxMesh.new()
	pbox.size = Vector3(PLATE_W, PLATE_H, 0.008)
	panel.mesh = pbox
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = CREAM
	pmat.metallic = 0.05
	pmat.roughness = 0.75
	panel.material_override = pmat
	_plate_parent.add_child(panel)

	# Copper accent strip at top
	var accent := MeshInstance3D.new()
	accent.name = "Accent"
	var abox := BoxMesh.new()
	abox.size = Vector3(PLATE_W * 0.5, 0.002, 0.002)
	accent.mesh = abox
	var amat := StandardMaterial3D.new()
	amat.albedo_color = COPPER
	amat.metallic = 0.6
	amat.roughness = 0.35
	amat.emission = COPPER
	amat.emission_energy_multiplier = 0.15
	accent.material_override = amat
	accent.transform.origin = Vector3(0, PLATE_H / 2.0 + 0.001, 0.002)
	_plate_parent.add_child(accent)

	# Title
	var title := Label3D.new()
	title.name = "Title"
	title.text = "PATTERN STUDIO"
	title.font_size = 16
	title.pixel_size = 0.0004
	title.modulate = Color(0.12, 0.12, 0.12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.transform.origin = Vector3(0, PLATE_H / 2.0 - 0.013, 0.006)
	_plate_parent.add_child(title)


# ══════════════════════════════════════════════════════════════════════
# PAINT GRID — 4x4 interactive cells (top-left of plate)
# ══════════════════════════════════════════════════════════════════════

func _build_paint_grid() -> void:
	var grid_root := Node3D.new()
	grid_root.name = "PaintGrid"
	# Top-left quadrant of the plate
	var grid_total: float = _current_grid_size * CELL_SIZE
	var gx0: float = -PLATE_W / 4.0
	var gy0: float = PLATE_H / 2.0 - 0.05 - grid_total / 2.0
	grid_root.transform.origin = Vector3(gx0, gy0, 0.005)
	_plate_parent.add_child(grid_root)

	# Recess behind grid
	var recess := MeshInstance3D.new()
	var rbox := BoxMesh.new()
	rbox.size = Vector3(grid_total + 0.008, grid_total + 0.008, 0.003)
	recess.mesh = rbox
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = RECESS
	rmat.roughness = 0.9
	recess.material_override = rmat
	recess.transform.origin.z = -0.002
	grid_root.add_child(recess)

	# Grid label
	var lbl := Label3D.new()
	lbl.text = "SOURCE"
	lbl.font_size = 10
	lbl.pixel_size = 0.0003
	lbl.modulate = Color(0.4, 0.4, 0.4)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.transform.origin = Vector3(0, grid_total / 2.0 + 0.008, 0.001)
	grid_root.add_child(lbl)

	# Build cells with push_buttons for VR interaction
	_grid_cells.clear()
	var btn_scene: PackedScene = load("res://commons/interactables/push_button.tscn")
	var start: float = -grid_total / 2.0 + CELL_SIZE / 2.0

	for y in _current_grid_size:
		for x in _current_grid_size:
			# Color swatch quad
			var cell := MeshInstance3D.new()
			cell.name = "Cell_%d_%d" % [x, y]
			var qmesh := QuadMesh.new()
			qmesh.size = Vector2(CELL_SIZE * 0.92, CELL_SIZE * 0.92)
			cell.mesh = qmesh
			var ci: int = 0
			if y < _grid_data.size() and x < _grid_data[y].size():
				ci = _grid_data[y][x]
			cell.material_override = _get_material(ci)
			cell.transform.origin = Vector3(
				start + x * CELL_SIZE,
				start + y * CELL_SIZE,
				0.002
			)
			grid_root.add_child(cell)
			_grid_cells.append(cell)

			# Interactive button overlay
			if btn_scene:
				var btn: Node = btn_scene.instantiate()
				btn.name = "GridBtn_%d_%d" % [x, y]
				btn.scale = Vector3.ONE * 0.35
				btn.transform.origin = Vector3(
					start + x * CELL_SIZE,
					start + y * CELL_SIZE,
					0.005
				)
				# Hide all visuals
				var base_mesh: Node = btn.find_child("BaseMesh", true, false)
				if base_mesh:
					base_mesh.visible = false
				var btn_mesh: Node = btn.find_child("ButtonMesh", true, false)
				if btn_mesh:
					btn_mesh.visible = false
				var acc: Node = btn.find_child("AccentRing", true, false)
				if acc:
					acc.visible = false
				grid_root.add_child(btn)

				# Connect paint action
				var gx: int = x
				var gy: int = y
				var area = btn.get_node_or_null("InteractableAreaButton")
				if area:
					area.button_pressed.connect(func(_b): set_cell(gx, gy, selected_color))


# ══════════════════════════════════════════════════════════════════════
# PALETTE — 3x3 color swatches with copper selection indicators
# ══════════════════════════════════════════════════════════════════════

func _build_palette() -> void:
	var palette_root := Node3D.new()
	palette_root.name = "Palette"
	# Top-right quadrant
	var grid_total: float = _current_grid_size * CELL_SIZE
	var pal_x: float = PLATE_W / 4.0 - 0.02
	var pal_y: float = PLATE_H / 2.0 - 0.05 - grid_total / 2.0 + 0.01
	palette_root.transform.origin = Vector3(pal_x, pal_y, 0.005)
	_plate_parent.add_child(palette_root)

	var swatch_size: float = 0.022
	var spacing: float = 0.030
	var grid_cols: int = 3
	var pal_grid_total: float = grid_cols * spacing
	var start: float = -pal_grid_total / 2.0 + spacing / 2.0

	_palette_indicators.clear()
	var pal_btn_scene: PackedScene = load("res://commons/interactables/push_button.tscn")

	for i in palette.size():
		var col: int = i % grid_cols
		var row: int = i / grid_cols
		var cx: float = start + col * spacing
		var cy: float = -start - row * spacing  # top to bottom

		# Dark border behind swatch
		var border := MeshInstance3D.new()
		var bq := QuadMesh.new()
		bq.size = Vector2(swatch_size + 0.003, swatch_size + 0.003)
		border.mesh = bq
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = DARK
		border.material_override = bmat
		border.transform.origin = Vector3(cx, cy, 0.002)
		palette_root.add_child(border)

		# Color swatch
		var swatch := MeshInstance3D.new()
		swatch.name = "Swatch_%d" % i
		var sq := QuadMesh.new()
		sq.size = Vector2(swatch_size, swatch_size)
		swatch.mesh = sq
		swatch.material_override = _get_material(i)
		swatch.transform.origin = Vector3(cx, cy, 0.003)
		palette_root.add_child(swatch)

		# Copper selection indicator (sphere)
		var indicator := MeshInstance3D.new()
		indicator.name = "Indicator_%d" % i
		var sphere := SphereMesh.new()
		sphere.radius = 0.003
		sphere.height = 0.006
		indicator.mesh = sphere
		var imat := StandardMaterial3D.new()
		imat.albedo_color = COPPER
		imat.emission = COPPER
		var emit_energy: float = 2.5 if i == selected_color else 0.0
		imat.emission_energy_multiplier = emit_energy
		indicator.material_override = imat
		indicator.transform.origin = Vector3(
			cx + swatch_size / 2.0 + 0.002,
			cy - swatch_size / 2.0 - 0.002,
			0.004
		)
		palette_root.add_child(indicator)
		_palette_indicators.append(indicator)

		# Interactive button on swatch (VR pressable)
		if pal_btn_scene:
			var btn: Node = pal_btn_scene.instantiate()
			btn.name = "PalBtn_%d" % i
			btn.scale = Vector3.ONE * 0.35
			btn.transform.origin = Vector3(cx, cy, 0.008)
			var base_m: Node = btn.find_child("BaseMesh", true, false)
			if base_m: base_m.visible = false
			var btn_m: Node = btn.find_child("ButtonMesh", true, false)
			if btn_m: btn_m.visible = false
			var ac: Node = btn.find_child("AccentRing", true, false)
			if ac: ac.visible = false
			palette_root.add_child(btn)

			var color_idx: int = i
			var area = btn.get_node_or_null("InteractableAreaButton")
			if area:
				area.button_pressed.connect(func(_b): _select_color(color_idx))

	# Palette label
	var lbl := Label3D.new()
	lbl.text = "PALETTE"
	lbl.font_size = 9
	lbl.pixel_size = 0.0003
	lbl.modulate = Color(0.4, 0.4, 0.4)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.transform.origin = Vector3(0, spacing + 0.018, 0.001)
	palette_root.add_child(lbl)


# ══════════════════════════════════════════════════════════════════════
# SLIDERS — 6 stacked horizontal sliders below grid/palette area
# ══════════════════════════════════════════════════════════════════════

func _build_sliders() -> void:
	var grid_total: float = _current_grid_size * CELL_SIZE
	var gy0: float = PLATE_H / 2.0 - 0.05 - grid_total / 2.0
	var divider_y: float = gy0 - grid_total / 2.0 - 0.015

	# Copper divider between design area and controls
	_build_copper_divider(PLATE_W * 0.85, Vector3(0, divider_y, 0.007))

	# Section label
	var ctrl_lbl := Label3D.new()
	ctrl_lbl.text = "CONTROLS"
	ctrl_lbl.font_size = 8
	ctrl_lbl.pixel_size = 0.0003
	ctrl_lbl.modulate = Color(0.45, 0.45, 0.45)
	ctrl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ctrl_lbl.transform.origin = Vector3(0, divider_y - 0.008, 0.008)
	_plate_parent.add_child(ctrl_lbl)

	var slider_y: float = divider_y - 0.025
	var slider_gap: float = 0.042

	# MOTIF slider
	var motif_names: Array[String] = []
	for m in MOTIFS:
		var mname: String = m["name"]
		motif_names.append(mname)
	var motif_result: Dictionary = _build_slider("MOTIF", motif_names, 0, slider_y)
	_motif_slider = motif_result["slider"]
	_motif_value_label = motif_result["value_label"]
	if _motif_slider:
		_motif_slider.slider_moved.connect(_on_motif_slider)
	slider_y -= slider_gap

	# GROUP slider (wallpaper groups)
	var group_result: Dictionary = _build_slider("GROUP", GROUPS, 10, slider_y)
	_group_slider = group_result["slider"]
	_group_value_label = group_result["value_label"]
	if _group_slider:
		_group_slider.slider_moved.connect(_on_group_slider)
	slider_y -= slider_gap

	# PERIOD slider
	var period_names: Array[String] = []
	for p in PERIODS:
		var pname: String = p["name"]
		period_names.append(pname)
	var period_result: Dictionary = _build_slider("PERIOD", period_names, 1, slider_y)
	_period_slider = period_result["slider"]
	_period_value_label = period_result["value_label"]
	if _period_slider:
		_period_slider.slider_moved.connect(_on_period_slider)
	slider_y -= slider_gap

	# SIZE slider
	var size_result: Dictionary = _build_slider("SIZE", SIZE_NAMES, 1, slider_y)
	_size_slider = size_result["slider"]
	_size_value_label = size_result["value_label"]
	if _size_slider:
		_size_slider.slider_moved.connect(_on_size_slider)
	slider_y -= slider_gap

	# ZONE slider
	var zone_result: Dictionary = _build_slider("ZONE", ZONES, 0, slider_y)
	_zone_slider = zone_result["slider"]
	_zone_value_label = zone_result["value_label"]
	if _zone_slider:
		_zone_slider.slider_moved.connect(_on_zone_slider)
	slider_y -= slider_gap

	# SITE slider (placeholder values)
	var site_names: Array[String] = ["Pompeii", "Herculaneum", "Ravenna", "Rome", "Florence"]
	var site_result: Dictionary = _build_slider("SITE", site_names, 0, slider_y)
	_site_slider = site_result["slider"]
	_site_value_label = site_result["value_label"]
	if _site_slider:
		_site_slider.slider_moved.connect(_on_site_slider)

	# Copper divider after sliders
	var divider_y2: float = slider_y - slider_gap * 0.5
	_build_copper_divider(PLATE_W * 0.85, Vector3(0, divider_y2, 0.007))


## Build a single horizontal slider row with label, recess, track, handle, and value display
func _build_slider(label_text: String, values: Array, default_idx: int, y_pos: float) -> Dictionary:
	var slider_root := Node3D.new()
	slider_root.name = "Slider_%s" % label_text
	slider_root.transform.origin = Vector3(0, y_pos, 0.005)
	_plate_parent.add_child(slider_root)

	var track_w: float = 0.12

	# Dark recess background
	var recess := MeshInstance3D.new()
	var rbox := BoxMesh.new()
	rbox.size = Vector3(track_w + 0.016, 0.032, 0.002)
	recess.mesh = rbox
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = DARK_RECESS
	rmat.roughness = 0.95
	recess.material_override = rmat
	recess.transform.origin = Vector3(0, -0.002, -0.002)
	slider_root.add_child(recess)

	# Track (thin dark line)
	var track := MeshInstance3D.new()
	var tbox := BoxMesh.new()
	tbox.size = Vector3(track_w, 0.0015, 0.002)
	track.mesh = tbox
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = TRACK_COLOR
	tmat.roughness = 0.7
	track.material_override = tmat
	track.transform.origin = Vector3(0, 0, 0.004)
	slider_root.add_child(track)

	# Tick marks
	var num_values: int = values.size()
	for i in num_values:
		var tn: float = float(i) / maxf(float(num_values - 1), 1.0)
		var tick_x: float = -track_w / 2.0 + tn * track_w
		var tick := MeshInstance3D.new()
		var tick_box := BoxMesh.new()
		tick_box.size = Vector3(0.0008, 0.004, 0.001)
		tick.mesh = tick_box
		var tick_mat := StandardMaterial3D.new()
		tick_mat.albedo_color = Color(0.35, 0.35, 0.35)
		tick.material_override = tick_mat
		tick.transform.origin = Vector3(tick_x, 0, 0.003)
		slider_root.add_child(tick)

	# VR slider handle
	var slider_scene: PackedScene = load("res://commons/interactables/slider_horizontal.tscn")
	var slider_node: Node = null
	if slider_scene:
		slider_node = slider_scene.instantiate()
		slider_node.name = "Handle_%s" % label_text
		slider_node.scale = Vector3.ONE * 0.6
		slider_node.transform.origin = Vector3(0, 0, 0.008)
		slider_root.add_child(slider_node)
		# Set initial normalized value
		if num_values > 1:
			var norm: float = float(default_idx) / float(num_values - 1)
			# Defer so the slider is ready
			slider_node.set_deferred("range_min", 0.0)
			slider_node.set_deferred("range_max", float(num_values - 1))
			call_deferred("_set_slider_initial", slider_node, norm)

	# Label above track
	var lbl := Label3D.new()
	lbl.text = label_text
	lbl.font_size = 7
	lbl.pixel_size = 0.0003
	lbl.modulate = Color(0.7, 0.7, 0.7)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.transform.origin = Vector3(0, 0.015, 0.003)
	slider_root.add_child(lbl)

	# Value display below track (copper)
	var value_label := Label3D.new()
	value_label.name = "ValueLabel_%s" % label_text
	value_label.font_size = 8
	value_label.pixel_size = 0.0003
	value_label.modulate = COPPER
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var display_text: String = "?"
	if default_idx >= 0 and default_idx < values.size():
		display_text = str(values[default_idx])
	value_label.text = display_text
	value_label.transform.origin = Vector3(0, -0.013, 0.003)
	slider_root.add_child(value_label)

	return {"slider": slider_node, "value_label": value_label, "values": values}


func _set_slider_initial(slider_node: Node, norm: float) -> void:
	if slider_node and slider_node.has_method("set_normalized_value"):
		slider_node.set_normalized_value(norm)


func _build_copper_divider(width: float, pos: Vector3) -> void:
	var divider := MeshInstance3D.new()
	var dbox := BoxMesh.new()
	dbox.size = Vector3(width, 0.001, 0.001)
	divider.mesh = dbox
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = COPPER
	dmat.metallic = 0.6
	dmat.roughness = 0.35
	dmat.emission = COPPER
	dmat.emission_energy_multiplier = 0.15
	divider.material_override = dmat
	divider.transform.origin = pos
	_plate_parent.add_child(divider)


# ══════════════════════════════════════════════════════════════════════
# CONTROLS — CLEAR, MIRROR, ROTATE buttons at bottom
# ══════════════════════════════════════════════════════════════════════

func _build_controls() -> void:
	var ctrl_root := Node3D.new()
	ctrl_root.name = "Controls"
	ctrl_root.transform.origin = Vector3(0, -PLATE_H / 2.0 + 0.025, 0.005)
	_plate_parent.add_child(ctrl_root)

	var btn_scene: PackedScene = load("res://commons/interactables/push_button.tscn")
	if not btn_scene:
		return

	var buttons: Array[Dictionary] = [
		{"label": "CLEAR", "x": -0.08, "action": "_clear_grid"},
		{"label": "MIRROR", "x": 0.0, "action": "_mirror_grid"},
		{"label": "ROTATE", "x": 0.08, "action": "_rotate_grid"},
	]

	for def in buttons:
		var btn: Node = btn_scene.instantiate()
		var btn_label: String = def["label"]
		btn.name = "Btn_%s" % btn_label
		btn.scale = Vector3.ONE * 0.45
		var btn_x: float = def["x"]
		btn.transform.origin = Vector3(btn_x, 0, 0.005)
		var base_mesh: Node = btn.find_child("BaseMesh", true, false)
		if base_mesh:
			base_mesh.visible = false
		ctrl_root.add_child(btn)

		# Label below button
		var lbl := Label3D.new()
		lbl.text = btn_label
		lbl.font_size = 8
		lbl.pixel_size = 0.0003
		lbl.modulate = Color(0.15, 0.15, 0.15)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.transform.origin = Vector3(btn_x, -0.025, 0.003)
		ctrl_root.add_child(lbl)

		var action: String = def["action"]
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): call(action))


# ══════════════════════════════════════════════════════════════════════
# CARPET — floor output below plate
# ══════════════════════════════════════════════════════════════════════

func _build_carpet() -> void:
	_carpet_mesh = MeshInstance3D.new()
	_carpet_mesh.name = "Carpet"
	_carpet_mesh.rotation_degrees = Vector3(-90, 0, 0)
	_carpet_mesh.transform.origin = Vector3(0, CARPET_Y, CARPET_Z)
	add_child(_carpet_mesh)

	# Carpet border (dark frame around rug)
	var border_w: float = 0.012
	var cbmat := StandardMaterial3D.new()
	cbmat.albedo_color = WARM_DARK
	cbmat.roughness = 0.8

	var positions: Array[Dictionary] = [
		{"size": Vector3(CARPET_W + border_w * 2, 0.003, border_w), "pos": Vector3(0, CARPET_Y, CARPET_Z + CARPET_H / 2.0 + border_w / 2.0)},
		{"size": Vector3(CARPET_W + border_w * 2, 0.003, border_w), "pos": Vector3(0, CARPET_Y, CARPET_Z - CARPET_H / 2.0 - border_w / 2.0)},
		{"size": Vector3(border_w, 0.003, CARPET_H), "pos": Vector3(-CARPET_W / 2.0 - border_w / 2.0, CARPET_Y, CARPET_Z)},
		{"size": Vector3(border_w, 0.003, CARPET_H), "pos": Vector3(CARPET_W / 2.0 + border_w / 2.0, CARPET_Y, CARPET_Z)},
	]
	for p in positions:
		var edge := MeshInstance3D.new()
		var ebox := BoxMesh.new()
		var edge_size: Vector3 = p["size"]
		ebox.size = edge_size
		edge.mesh = ebox
		edge.material_override = cbmat.duplicate()
		var edge_pos: Vector3 = p["pos"]
		edge.transform.origin = edge_pos
		add_child(edge)


# ══════════════════════════════════════════════════════════════════════
# CARPET UPDATE — regenerate texture from grid + wallpaper group
# ══════════════════════════════════════════════════════════════════════

func _update_carpet() -> void:
	if _grid_data.is_empty() or not _carpet_mesh:
		return

	var repeats: int = 6
	var gs: int = _current_grid_size
	var pw: int = repeats * gs
	var ph: int = repeats * gs
	var image := Image.create(pw, ph, false, Image.FORMAT_RGBA8)

	# Map group name to WallpaperGroups enum
	var group_enum: int = _get_wallpaper_enum()

	for py in ph:
		for px in pw:
			var color_idx: int = WallpaperGroups.get_symmetric_color(px, py, gs, _grid_data, group_enum)
			var color: Color = palette[color_idx] if color_idx < palette.size() else Color.WHITE
			image.set_pixel(px, py, color)

	var qmesh := QuadMesh.new()
	qmesh.size = Vector2(CARPET_W, CARPET_H)
	_carpet_mesh.mesh = qmesh

	var texture := ImageTexture.create_from_image(image)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 0.95
	_carpet_mesh.material_override = mat


func _get_wallpaper_enum() -> int:
	# Map wallpaper_group index (into GROUPS) to WallpaperGroups.Group enum
	if wallpaper_group < 0 or wallpaper_group >= GROUPS.size():
		return WallpaperGroups.Group.P4M
	return wallpaper_group  # enum values match GROUPS array indices


# ══════════════════════════════════════════════════════════════════════
# SLIDER CALLBACKS
# ══════════════════════════════════════════════════════════════════════

func _on_motif_slider(value) -> void:
	var norm: float = _get_slider_norm(value, _motif_slider)
	var idx: int = _norm_to_index(norm, MOTIFS.size())
	if idx != _current_motif:
		_current_motif = idx
		_load_motif(idx)
		if _motif_value_label and idx < MOTIFS.size():
			var mname: String = MOTIFS[idx]["name"]
			_motif_value_label.text = mname


func _on_group_slider(value) -> void:
	var norm: float = _get_slider_norm(value, _group_slider)
	var idx: int = _norm_to_index(norm, GROUPS.size())
	if idx != wallpaper_group:
		wallpaper_group = idx
		_update_carpet()
		if _group_value_label:
			_group_value_label.text = GROUPS[idx]
		group_changed.emit(GROUPS[idx])


func _on_period_slider(value) -> void:
	var norm: float = _get_slider_norm(value, _period_slider)
	var idx: int = _norm_to_index(norm, PERIODS.size())
	if idx != _current_period:
		_current_period = idx
		_apply_period_palette(idx)
		if _period_value_label and idx < PERIODS.size():
			var pname: String = PERIODS[idx]["name"]
			_period_value_label.text = pname


func _on_size_slider(value) -> void:
	var norm: float = _get_slider_norm(value, _size_slider)
	var idx: int = _norm_to_index(norm, SIZES.size())
	if idx != _current_size_idx:
		_current_size_idx = idx
		_change_grid_size(SIZES[idx])
		if _size_value_label:
			_size_value_label.text = SIZE_NAMES[idx]


func _on_zone_slider(value) -> void:
	var norm: float = _get_slider_norm(value, _zone_slider)
	var idx: int = _norm_to_index(norm, ZONES.size())
	_current_zone = idx
	if _zone_value_label:
		_zone_value_label.text = ZONES[idx]


func _on_site_slider(value) -> void:
	var norm: float = _get_slider_norm(value, _site_slider)
	var site_names: Array[String] = ["Pompeii", "Herculaneum", "Ravenna", "Rome", "Florence"]
	var idx: int = _norm_to_index(norm, site_names.size())
	_current_site = idx
	if _site_value_label:
		_site_value_label.text = site_names[idx]


func _get_slider_norm(value, slider_node: Node) -> float:
	if slider_node and slider_node.has_method("get_normalized_value"):
		return slider_node.get_normalized_value()
	if value is float:
		return value
	if value is Vector2:
		return value.x
	return 0.5


func _norm_to_index(norm: float, count: int) -> int:
	if count <= 0:
		return 0
	return clampi(roundi(norm * (count - 1)), 0, count - 1)


# ══════════════════════════════════════════════════════════════════════
# MOTIF LOADING
# ══════════════════════════════════════════════════════════════════════

func _load_motif(idx: int) -> void:
	if idx < 0 or idx >= MOTIFS.size():
		return
	var motif: Dictionary = MOTIFS[idx]
	var domain_size: int = motif["domain_size"]
	var data: Array = motif["data"]
	var group_name: String = motif["group"]

	# Pad/crop motif data to current grid size
	_grid_data.clear()
	for y in _current_grid_size:
		var row: Array = []
		for x in _current_grid_size:
			var val: int = 0
			if y < data.size() and x < data[y].size():
				val = data[y][x]
			elif domain_size > 0:
				var sy: int = y % domain_size
				var sx: int = x % domain_size
				if sy < data.size() and sx < data[sy].size():
					val = data[sy][sx]
			row.append(val)
		_grid_data.append(row)

	# Update grid cells visual
	for i in _grid_cells.size():
		var gy: int = i / _current_grid_size
		var gx: int = i % _current_grid_size
		if gy < _grid_data.size() and gx < _grid_data[gy].size():
			var ci: int = _grid_data[gy][gx]
			_grid_cells[i].material_override = _get_material(ci)

	# Set group to motif's recommended group
	var gidx: int = GROUPS.find(group_name)
	if gidx >= 0:
		wallpaper_group = gidx
		if _group_slider:
			var norm: float = float(gidx) / maxf(float(GROUPS.size() - 1), 1.0)
			call_deferred("_set_slider_initial", _group_slider, norm)
		if _group_value_label:
			_group_value_label.text = group_name

	_update_carpet()


func _apply_period_palette(idx: int) -> void:
	if idx < 0 or idx >= PERIODS.size():
		return
	var period: Dictionary = PERIODS[idx]
	var colors: Array = period["colors"]
	for i in palette.size():
		if i < colors.size():
			var hex_str: String = colors[i]
			palette[i] = Color.html(hex_str)

	# Refresh cell visuals
	_cell_materials.clear()
	for ci in _grid_cells.size():
		var gy: int = ci / _current_grid_size
		var gx: int = ci % _current_grid_size
		if gy < _grid_data.size() and gx < _grid_data[gy].size():
			var color_idx: int = _grid_data[gy][gx]
			_grid_cells[ci].material_override = _get_material(color_idx)

	# Refresh palette swatch visuals
	var pal_root: Node = _plate_parent.find_child("Palette", true, false)
	if pal_root:
		for i in palette.size():
			var swatch: Node = pal_root.find_child("Swatch_%d" % i, true, false)
			if swatch and swatch is MeshInstance3D:
				(swatch as MeshInstance3D).material_override = _get_material(i)

	_update_carpet()


func _change_grid_size(new_size: int) -> void:
	if new_size == _current_grid_size:
		return
	var old_grid: Array = _grid_data.duplicate(true)
	var old_size: int = _current_grid_size
	_current_grid_size = new_size
	_grid_data.clear()
	for y in new_size:
		var row: Array = []
		for x in new_size:
			var val: int = 0
			if y % old_size < old_grid.size() and x % old_size < old_grid[y % old_size].size():
				val = old_grid[y % old_size][x % old_size]
			row.append(val)
		_grid_data.append(row)

	# Rebuild the grid visually (remove old, build new)
	var grid_root: Node = _plate_parent.find_child("PaintGrid", true, false)
	if grid_root:
		grid_root.queue_free()
	_grid_cells.clear()
	# Defer rebuild so the old node is freed first
	call_deferred("_rebuild_paint_grid")
	_update_carpet()


func _rebuild_paint_grid() -> void:
	_build_paint_grid()


# ══════════════════════════════════════════════════════════════════════
# CONTROL ACTIONS
# ══════════════════════════════════════════════════════════════════════

func _clear_grid() -> void:
	for y in _current_grid_size:
		for x in _current_grid_size:
			_grid_data[y][x] = 0
	for i in _grid_cells.size():
		if _grid_cells[i]:
			_grid_cells[i].material_override = _get_material(0)
	_update_carpet()


func _mirror_grid() -> void:
	# Mirror horizontally
	var gs: int = _current_grid_size
	for y in gs:
		for x in gs / 2:
			var mirror_x: int = gs - 1 - x
			_grid_data[y][mirror_x] = _grid_data[y][x]
	_refresh_grid_visuals()
	_update_carpet()


func _rotate_grid() -> void:
	# Rotate 90 degrees clockwise
	var gs: int = _current_grid_size
	var new_data: Array = []
	for y in gs:
		var row: Array = []
		for x in gs:
			var src_y: int = gs - 1 - x
			var src_x: int = y
			var val: int = 0
			if src_y >= 0 and src_y < gs and src_x >= 0 and src_x < gs:
				val = _grid_data[src_y][src_x]
			row.append(val)
		new_data.append(row)
	_grid_data = new_data
	_refresh_grid_visuals()
	_update_carpet()


func _refresh_grid_visuals() -> void:
	for i in _grid_cells.size():
		var gy: int = i / _current_grid_size
		var gx: int = i % _current_grid_size
		if gy < _grid_data.size() and gx < _grid_data[gy].size():
			var ci: int = _grid_data[gy][gx]
			_grid_cells[i].material_override = _get_material(ci)


# ══════════════════════════════════════════════════════════════════════
# COLOR SELECTION
# ══════════════════════════════════════════════════════════════════════

func _select_color(idx: int) -> void:
	selected_color = clampi(idx, 0, palette.size() - 1)
	for i in _palette_indicators.size():
		var ind: MeshInstance3D = _palette_indicators[i]
		if ind and ind.material_override:
			var energy: float = 2.5 if i == selected_color else 0.0
			(ind.material_override as StandardMaterial3D).emission_energy_multiplier = energy


# ══════════════════════════════════════════════════════════════════════
# KEYBOARD INPUT
# ══════════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _select_color(0)
			KEY_2: _select_color(1)
			KEY_3: _select_color(2)
			KEY_4: _select_color(3)
			KEY_5: _select_color(4)
			KEY_6: _select_color(5)
			KEY_7: _select_color(6)
			KEY_8: _select_color(7)
			KEY_9: _select_color(8)
			KEY_Q: _prev_motif()
			KEY_E: _next_motif()
			KEY_TAB: _next_group()
			KEY_C: _clear_grid()


func _prev_motif() -> void:
	var idx: int = maxi(0, _current_motif - 1)
	_current_motif = idx
	_load_motif(idx)
	if _motif_slider:
		var norm: float = float(idx) / maxf(float(MOTIFS.size() - 1), 1.0)
		call_deferred("_set_slider_initial", _motif_slider, norm)
	if _motif_value_label and idx < MOTIFS.size():
		var mname: String = MOTIFS[idx]["name"]
		_motif_value_label.text = mname


func _next_motif() -> void:
	var idx: int = mini(MOTIFS.size() - 1, _current_motif + 1)
	_current_motif = idx
	_load_motif(idx)
	if _motif_slider:
		var norm: float = float(idx) / maxf(float(MOTIFS.size() - 1), 1.0)
		call_deferred("_set_slider_initial", _motif_slider, norm)
	if _motif_value_label and idx < MOTIFS.size():
		var mname: String = MOTIFS[idx]["name"]
		_motif_value_label.text = mname


func _next_group() -> void:
	wallpaper_group = (wallpaper_group + 1) % GROUPS.size()
	_update_carpet()
	if _group_slider:
		var norm: float = float(wallpaper_group) / maxf(float(GROUPS.size() - 1), 1.0)
		call_deferred("_set_slider_initial", _group_slider, norm)
	if _group_value_label:
		_group_value_label.text = GROUPS[wallpaper_group]
	group_changed.emit(GROUPS[wallpaper_group])


# ══════════════════════════════════════════════════════════════════════
# MATERIAL CACHE
# ══════════════════════════════════════════════════════════════════════

func _get_material(color_idx: int) -> StandardMaterial3D:
	if _cell_materials.has(color_idx):
		return _cell_materials[color_idx]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = palette[color_idx] if color_idx < palette.size() else Color.WHITE
	mat.roughness = 0.85
	_cell_materials[color_idx] = mat
	return mat


# ══════════════════════════════════════════════════════════════════════
# GRID CONFIG (map integration)
# ══════════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("wallpaper_group"):
		var g: String = str(config_data["wallpaper_group"]).to_upper()
		var gidx: int = GROUPS.find(g)
		if gidx >= 0:
			wallpaper_group = gidx
			_update_carpet()
	if config_data.has("motif"):
		var midx: int = int(config_data["motif"])
		if midx >= 0 and midx < MOTIFS.size():
			_load_motif(midx)
	if config_data.has("period"):
		var pidx: int = int(config_data["period"])
		if pidx >= 0 and pidx < PERIODS.size():
			_apply_period_palette(pidx)
	if config_data.has("grid_size"):
		var sz: int = int(config_data["grid_size"])
		if sz in SIZES:
			_change_grid_size(sz)
