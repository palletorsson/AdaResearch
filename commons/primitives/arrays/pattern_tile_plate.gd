extends Node3D

## Pattern Tile Plate - Dieter Rams integrated interface
##
## A single cream panel containing:
## - 4x4 interactive paint grid (left)
## - Tiled preview showing carpet output (right)
## - 9-color palette row with selection indicator
## - Symmetry controls (lattice, group, mode, clear)
## - Carpet output on floor below
##
## Uses RackTemplates palette (CREAM, WARM_DARK, COPPER) and
## WallpaperGroups for the 17 mathematical symmetry patterns.

const WallpaperGroups = preload("res://commons/primitives/arrays/wallpaper_groups.gd")

# ── Rams palette ─────────────────────────────────────────────────────
const CREAM := Color(0.90, 0.87, 0.80)
const CREAM_LIGHT := Color(0.93, 0.91, 0.85)
const WARM_DARK := Color(0.25, 0.23, 0.20)
const COPPER := Color(0.75, 0.38, 0.13)
const RECESS := Color(0.82, 0.79, 0.72)
const DARK := Color(0.12, 0.12, 0.12)

# ── Layout constants ─────────────────────────────────────────────────
const PLATE_W := 0.34         # Grid + gutter + palette + margins
const PLATE_H := 0.32         # Taller for stacked layout
const GRID_SIZE := 4          # 4x4 paint grid
const CELL_SIZE := 0.032      # Cell size in meters
const GRID_TOTAL := GRID_SIZE * CELL_SIZE  # 0.128m
const PREVIEW_REPEATS := Vector2i(6, 4)  # Wider than tall, like a real carpet
const PAD := 0.016
const BTN_SCALE := 0.45

# ── Tile palette ─────────────────────────────────────────────────────
var palette: Array[Color] = [
	Color(0.95, 0.92, 0.85),  # 0: Cream
	Color(0.8, 0.2, 0.15),    # 1: Deep red
	Color(0.15, 0.25, 0.5),   # 2: Navy blue
	Color(0.7, 0.55, 0.2),    # 3: Gold/ochre
	Color(0.2, 0.4, 0.25),    # 4: Forest green
	Color(0.4, 0.2, 0.15),    # 5: Brown
	Color(0.1, 0.1, 0.12),    # 6: Near black
	Color(0.6, 0.3, 0.5),     # 7: Dusty purple
	Color(0.5, 0.7, 0.8),     # 8: Sky blue
]

# ── State ────────────────────────────────────────────────────────────
var selected_color: int = 1
var _grid_data: Array = []     # 2D array [y][x] of color indices
var wallpaper_group: int = 11  # P4M default (WallpaperGroups.Group.P4M)
var _current_lattice_index: int = 3  # square

# ── Nodes ────────────────────────────────────────────────────────────
var _grid_cells: Array = []    # Array of MeshInstance3D
var _preview_mesh: MeshInstance3D
var _carpet_mesh: MeshInstance3D
var _mode_label: Label3D
var _palette_indicators: Array = []
var _cell_materials: Dictionary = {}
var _plate_parent: Node3D  # Container at eye height

# ── Signals ──────────────────────────────────────────────────────────
signal cell_changed(x: int, y: int, color_index: int)
signal group_changed(group_name: String)


const PLATE_Y := 1.0    # Interface at ~1.5m (origin at ~0.5 + 1.0)
const CARPET_Y := -0.5  # Carpet at floor (origin at ~0.5 - 0.5 = ~0.01)
const CARPET_Z := -1.0  # Carpet 1m in front of plate (toward player)

func _ready() -> void:
	_initialize_grid_data()
	_paint_demo_pattern()

	# Plate container at eye height
	var plate_container := Node3D.new()
	plate_container.name = "PlateMount"
	plate_container.transform.origin = Vector3(0, PLATE_Y, 0)
	plate_container.rotation_degrees = Vector3(-15, 0, 0)  # Slight tilt toward player
	add_child(plate_container)
	_plate_parent = plate_container

	_build_plate()
	_build_paint_grid()
	_build_palette()
	_build_controls()
	_build_carpet()
	_update_preview()
	_update_mode_label()


## Paint an initial demo pattern so the preview isn't blank
func _paint_demo_pattern() -> void:
	# Simple cross pattern in red/blue/gold
	var pattern := [
		[0, 1, 1, 0],
		[2, 3, 3, 2],
		[2, 3, 3, 2],
		[0, 1, 1, 0],
	]
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			if y < pattern.size() and x < pattern[y].size():
				_grid_data[y][x] = pattern[y][x]


# ══════════════════════════════════════════════════════════════════════
# GRID DATA
# ══════════════════════════════════════════════════════════════════════

func _initialize_grid_data() -> void:
	_grid_data.clear()
	for y in GRID_SIZE:
		var row: Array = []
		row.resize(GRID_SIZE)
		for x in GRID_SIZE:
			row[x] = 0
		_grid_data.append(row)


func set_cell(x: int, y: int, color_idx: int) -> void:
	if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
		return
	print("PatternPlate: paint cell (%d,%d) color %d" % [x, y, color_idx])
	_grid_data[y][x] = clampi(color_idx, 0, palette.size() - 1)
	# Update cell visual
	var idx: int = y * GRID_SIZE + x
	if idx < _grid_cells.size() and _grid_cells[idx]:
		_grid_cells[idx].material_override = _get_material(color_idx)
	_update_preview()
	cell_changed.emit(x, y, color_idx)


func get_cell(x: int, y: int) -> int:
	if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
		return 0
	return _grid_data[y][x]


# ══════════════════════════════════════════════════════════════════════
# BUILD PLATE - cream backing with frame
# ══════════════════════════════════════════════════════════════════════

func _build_plate() -> void:
	var p: Node3D = _plate_parent
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

	# Copper accent strip
	var accent := MeshInstance3D.new()
	accent.name = "Accent"
	var abox := BoxMesh.new()
	abox.size = Vector3(PLATE_W * 0.6, 0.002, 0.002)
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
# PAINT GRID - 4x4 interactive cells
# ══════════════════════════════════════════════════════════════════════

func _build_paint_grid() -> void:
	var grid_root := Node3D.new()
	grid_root.name = "PaintGrid"
	# Position: left side with padding from edge
	var gutter := 0.02  # gap between grid and palette
	grid_root.transform.origin = Vector3(-GRID_TOTAL / 2.0 - gutter / 2.0, PLATE_H / 2.0 - 0.04 - GRID_TOTAL / 2.0, 0.005)
	_plate_parent.add_child(grid_root)

	# Recess behind grid
	var recess := MeshInstance3D.new()
	var rbox := BoxMesh.new()
	rbox.size = Vector3(GRID_TOTAL + 0.008, GRID_TOTAL + 0.008, 0.003)
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
	lbl.transform.origin = Vector3(0, GRID_TOTAL / 2.0 + 0.008, 0.001)
	grid_root.add_child(lbl)

	# Build cells as push_buttons (VR interactive)
	_grid_cells.clear()
	var btn_scene: PackedScene = load("res://commons/interactables/push_button.tscn")
	var start := -GRID_TOTAL / 2.0 + CELL_SIZE / 2.0

	for y in GRID_SIZE:
		for x in GRID_SIZE:
			# Color swatch quad behind button
			var cell := MeshInstance3D.new()
			cell.name = "Cell_%d_%d" % [x, y]
			var qmesh := QuadMesh.new()
			qmesh.size = Vector2(CELL_SIZE * 0.92, CELL_SIZE * 0.92)
			cell.mesh = qmesh
			cell.material_override = _get_material(_grid_data[y][x])
			cell.transform.origin = Vector3(
				start + x * CELL_SIZE,
				start + y * CELL_SIZE,
				0.002
			)
			grid_root.add_child(cell)
			_grid_cells.append(cell)

			# Interactive button on top of each cell
			if btn_scene:
				var btn: Node = btn_scene.instantiate()
				btn.name = "GridBtn_%d_%d" % [x, y]
				btn.scale = Vector3.ONE * 0.35
				btn.transform.origin = Vector3(
					start + x * CELL_SIZE,
					start + y * CELL_SIZE,
					0.005
				)
				# Hide base mesh and button mesh — only keep interaction area
				var base_mesh: Node = btn.find_child("BaseMesh", true, false)
				if base_mesh:
					base_mesh.visible = false
				var btn_mesh: Node = btn.find_child("ButtonMesh", true, false)
				if btn_mesh:
					btn_mesh.visible = false
				var accent: Node = btn.find_child("AccentRing", true, false)
				if accent:
					accent.visible = false
				grid_root.add_child(btn)

				# Connect — paint this cell with selected color
				var gx: int = x
				var gy: int = y
				var area = btn.get_node_or_null("InteractableAreaButton")
				if area:
					area.button_pressed.connect(func(_b): set_cell(gx, gy, selected_color))


# ══════════════════════════════════════════════════════════════════════

func _build_preview() -> void:
	var preview_root := Node3D.new()
	preview_root.name = "Preview"
	# Match paint grid size so both fit side by side
	var preview_w := GRID_TOTAL + 0.02  # Same width as paint grid
	var preview_h := GRID_TOTAL          # Same height
	preview_root.transform.origin = Vector3(PLATE_W / 4.0 - 0.01, PLATE_H / 2.0 - 0.04 - preview_h / 2.0, 0.005)
	_plate_parent.add_child(preview_root)

	# Recess (dark background for preview)
	var recess := MeshInstance3D.new()
	var rbox := BoxMesh.new()
	rbox.size = Vector3(preview_w + 0.008, preview_h + 0.008, 0.003)
	recess.mesh = rbox
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.06, 0.06, 0.06)
	rmat.roughness = 0.9
	recess.material_override = rmat
	recess.transform.origin.z = -0.002
	preview_root.add_child(recess)

	# Preview label
	var lbl := Label3D.new()
	lbl.text = "PREVIEW"
	lbl.font_size = 10
	lbl.pixel_size = 0.0003
	lbl.modulate = Color(0.4, 0.4, 0.4)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.transform.origin = Vector3(0, preview_h / 2.0 + 0.008, 0.001)
	preview_root.add_child(lbl)

	# Preview mesh (texture updated dynamically)
	_preview_mesh = MeshInstance3D.new()
	_preview_mesh.name = "PreviewMesh"
	var qmesh := QuadMesh.new()
	qmesh.size = Vector2(preview_w, preview_h)
	_preview_mesh.mesh = qmesh
	_preview_mesh.transform.origin.z = 0.002
	preview_root.add_child(_preview_mesh)


# ══════════════════════════════════════════════════════════════════════
# PALETTE - 9 color buttons with selection indicator
# ══════════════════════════════════════════════════════════════════════

func _build_palette() -> void:
	var palette_root := Node3D.new()
	palette_root.name = "Palette"
	# Position to the right of the paint grid with gutter
	var gutter := 0.02
	var palette_3x3_size := 3 * 0.028  # 3 cols x spacing
	palette_root.transform.origin = Vector3(palette_3x3_size / 2.0 + gutter / 2.0, PLATE_H / 2.0 - 0.04 - GRID_TOTAL / 2.0, 0.005)
	_plate_parent.add_child(palette_root)

	# 3x3 grid of color swatches
	var swatch_size := 0.022
	var spacing := 0.028
	var grid_cols := 3
	var grid_total := grid_cols * spacing
	var start := -grid_total / 2.0 + spacing / 2.0

	_palette_indicators.clear()
	var pal_btn_scene: PackedScene = load("res://commons/interactables/push_button.tscn")

	for i in palette.size():
		var col: int = i % grid_cols
		var row: int = i / grid_cols
		var cx: float = start + col * spacing
		var cy: float = -start - row * spacing  # top to bottom

		# Color swatch quad
		var swatch := MeshInstance3D.new()
		swatch.name = "Swatch_%d" % i
		var sq := QuadMesh.new()
		sq.size = Vector2(swatch_size, swatch_size)
		swatch.mesh = sq
		swatch.material_override = _get_material(i)
		swatch.transform.origin = Vector3(cx, cy, 0.003)
		palette_root.add_child(swatch)

		# Dark border
		var border := MeshInstance3D.new()
		var bq := QuadMesh.new()
		bq.size = Vector2(swatch_size + 0.003, swatch_size + 0.003)
		border.mesh = bq
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = DARK
		border.material_override = bmat
		border.transform.origin = Vector3(cx, cy, 0.002)
		palette_root.add_child(border)

		# Selection indicator (copper corner dot)
		var indicator := MeshInstance3D.new()
		indicator.name = "Indicator_%d" % i
		var sphere := SphereMesh.new()
		sphere.radius = 0.003
		sphere.height = 0.006
		indicator.mesh = sphere
		var imat := StandardMaterial3D.new()
		imat.albedo_color = COPPER
		imat.emission = COPPER
		imat.emission_energy_multiplier = 2.5 if i == selected_color else 0.0
		indicator.material_override = imat
		indicator.transform.origin = Vector3(cx + swatch_size / 2.0 + 0.002, cy - swatch_size / 2.0 - 0.002, 0.004)
		palette_root.add_child(indicator)
		_palette_indicators.append(indicator)

		# Interactive button on top of swatch (VR pressable)
		if pal_btn_scene:
			var btn: Node = pal_btn_scene.instantiate()
			btn.name = "PalBtn_%d" % i
			btn.scale = Vector3.ONE * 0.35  # Big enough for VR finger press
			btn.transform.origin = Vector3(cx, cy, 0.008)
			# Hide all visuals — swatch IS the visual
			var base_m: Node = btn.find_child("BaseMesh", true, false)
			if base_m: base_m.visible = false
			var btn_m: Node = btn.find_child("ButtonMesh", true, false)
			if btn_m: btn_m.visible = false
			var acc: Node = btn.find_child("AccentRing", true, false)
			if acc: acc.visible = false
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
	lbl.transform.origin = Vector3(0, 0.022, 0.001)
	palette_root.add_child(lbl)


# ══════════════════════════════════════════════════════════════════════
# CONTROLS - symmetry navigation buttons
# ══════════════════════════════════════════════════════════════════════

func _build_controls() -> void:
	var ctrl_root := Node3D.new()
	ctrl_root.name = "Controls"
	ctrl_root.transform.origin = Vector3(0, -0.08, 0.005)
	_plate_parent.add_child(ctrl_root)

	var btn_scene: PackedScene = load("res://commons/interactables/push_button.tscn")
	if not btn_scene:
		return

	var buttons := [
		{"label": "◄LAT", "x": -0.12, "action": "_prev_lattice"},
		{"label": "GRP►", "x": -0.06, "action": "_next_group"},
		{"label": "MODE", "x": 0.0, "action": "_toggle_mode"},
		{"label": "CLEAR", "x": 0.06, "action": "_clear_grid"},
		{"label": "CARPET", "x": 0.12, "action": "_spawn_carpet_below"},
	]

	for def in buttons:
		var btn: Node = btn_scene.instantiate()
		btn.name = "Btn_%s" % def["label"]
		btn.scale = Vector3.ONE * BTN_SCALE
		btn.transform.origin = Vector3(def["x"], 0, 0.005)
		# Hide base mesh (same as RackTemplates)
		var base_mesh: Node = btn.find_child("BaseMesh", true, false)
		if base_mesh:
			base_mesh.visible = false
		ctrl_root.add_child(btn)

		# Label below button
		var lbl := Label3D.new()
		lbl.text = def["label"]
		lbl.font_size = 8
		lbl.pixel_size = 0.0003
		lbl.modulate = Color(0.15, 0.15, 0.15)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.transform.origin = Vector3(def["x"], -0.025, 0.003)
		ctrl_root.add_child(lbl)

		# Connect
		var action: String = def["action"]
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): call(action))

	# Mode label (shows current group)
	_mode_label = Label3D.new()
	_mode_label.name = "ModeLabel"
	_mode_label.text = "P4M"
	_mode_label.font_size = 14
	_mode_label.pixel_size = 0.0004
	_mode_label.modulate = COPPER
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_label.transform.origin = Vector3(0, -0.05, 0.006)
	_plate_parent.add_child(_mode_label)


# ══════════════════════════════════════════════════════════════════════
# CARPET - floor output below plate
# ══════════════════════════════════════════════════════════════════════

func _build_carpet() -> void:
	_carpet_mesh = MeshInstance3D.new()
	_carpet_mesh.name = "Carpet"
	# Lay flat on the floor in front of the plate
	# X rotation -90 makes the quad face up (floor)
	_carpet_mesh.rotation_degrees = Vector3(-90, 0, 0)
	# Floor level (y=0.01), 1m in front (z=1.0)
	_carpet_mesh.transform.origin = Vector3(0, CARPET_Y, CARPET_Z)
	add_child(_carpet_mesh)


# ══════════════════════════════════════════════════════════════════════
# PREVIEW & CARPET UPDATE
# ══════════════════════════════════════════════════════════════════════

func _update_preview() -> void:
	if _grid_data.is_empty():
		return

	var pw: int = PREVIEW_REPEATS.x * GRID_SIZE
	var ph: int = PREVIEW_REPEATS.y * GRID_SIZE
	var image := Image.create(pw, ph, false, Image.FORMAT_RGBA8)

	for py in ph:
		for px in pw:
			var color_idx: int = _get_tiled_color(px, py)
			var color: Color = palette[color_idx] if color_idx < palette.size() else Color.WHITE
			image.set_pixel(px, py, color)

	# Update carpet directly (no on-plate preview)
	_update_carpet(image)


func _update_carpet(image: Image) -> void:
	if not _carpet_mesh:
		return
	# Real carpet proportions - rectangular, like a rug on the floor
	var carpet_w := 1.2   # 120cm wide
	var carpet_h := 0.8   # 80cm deep (3:2 ratio)
	var qmesh := QuadMesh.new()
	qmesh.size = Vector2(carpet_w, carpet_h)
	_carpet_mesh.mesh = qmesh

	var texture := ImageTexture.create_from_image(image)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 0.95
	_carpet_mesh.material_override = mat


func _get_tiled_color(px: int, py: int) -> int:
	return WallpaperGroups.get_symmetric_color(px, py, GRID_SIZE, _grid_data, wallpaper_group)


# ══════════════════════════════════════════════════════════════════════
# INTERACTION
# ══════════════════════════════════════════════════════════════════════

func _select_color(idx: int) -> void:
	selected_color = clampi(idx, 0, palette.size() - 1)
	print("PatternPlate: selected color %d" % selected_color)
	for i in _palette_indicators.size():
		var ind: MeshInstance3D = _palette_indicators[i]
		if ind and ind.material_override:
			(ind.material_override as StandardMaterial3D).emission_energy_multiplier = 2.5 if i == selected_color else 0.0


## Grid cells and palette are now push_button instances - VR interaction works automatically


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
			KEY_Q: _prev_lattice()
			KEY_E: _next_group()
			KEY_TAB: _toggle_mode()
			KEY_C: _clear_grid()
			KEY_SPACE: _spawn_carpet_below()


# ══════════════════════════════════════════════════════════════════════
# SYMMETRY NAVIGATION
# ══════════════════════════════════════════════════════════════════════

const LATTICE_ORDER: Array = ["oblique", "rectangular", "rhombic", "square", "hexagonal"]

func _prev_lattice() -> void:
	_current_lattice_index = (_current_lattice_index - 1 + LATTICE_ORDER.size()) % LATTICE_ORDER.size()
	var groups: Array = WallpaperGroups.get_groups_for_lattice(LATTICE_ORDER[_current_lattice_index])
	if groups.size() > 0:
		wallpaper_group = groups[0]
	_update_preview()
	_update_mode_label()


func _next_group() -> void:
	var groups: Array = WallpaperGroups.get_groups_for_lattice(LATTICE_ORDER[_current_lattice_index])
	if groups.is_empty():
		return
	var current_idx: int = groups.find(wallpaper_group)
	wallpaper_group = groups[(current_idx + 1) % groups.size()]
	_update_preview()
	_update_mode_label()


func _toggle_mode() -> void:
	_current_lattice_index = (_current_lattice_index + 1) % LATTICE_ORDER.size()
	var groups: Array = WallpaperGroups.get_groups_for_lattice(LATTICE_ORDER[_current_lattice_index])
	if groups.size() > 0:
		wallpaper_group = groups[0]
	_update_preview()
	_update_mode_label()


func _clear_grid() -> void:
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			_grid_data[y][x] = 0
	# Update all cell visuals
	for i in _grid_cells.size():
		if _grid_cells[i]:
			_grid_cells[i].material_override = _get_material(0)
	_update_preview()


func _spawn_carpet_below() -> void:
	# Just triggers a preview update - carpet is always visible
	_update_preview()


func _update_mode_label() -> void:
	if not _mode_label:
		return
	var info: Dictionary = WallpaperGroups.get_group_info(wallpaper_group)
	_mode_label.text = "%s  (%s)" % [info.get("name", "?").to_upper(), info.get("lattice", "?")]


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
		var g: String = str(config_data["wallpaper_group"]).to_lower()
		var parsed: int = _parse_group(g)
		if parsed >= 0:
			wallpaper_group = parsed
	if config_data.has("cursor"):
		pass  # Cursor mode - could enable cursor visualization
	# Shorthand parsing
	for key in config_data:
		match str(key).to_lower():
			"p4m": wallpaper_group = 11
			"p6m": wallpaper_group = 16
			"p4g": wallpaper_group = 12
			"pm": wallpaper_group = 2
			"cmm": wallpaper_group = 8


func _parse_group(name: String) -> int:
	var group_map := {
		"p1": 0, "p2": 1, "pm": 2, "pg": 3, "pmm": 4, "pmg": 5, "pgg": 6,
		"cm": 7, "cmm": 8, "p4": 9, "p4m": 10, "p4g": 11, "p3": 12,
		"p3m1": 13, "p31m": 14, "p6": 15, "p6m": 16,
	}
	return group_map.get(name, -1)
