# pattern_maker_station.gd
# Interactive pattern design station — edit a small domain grid on an upright
# panel, see the result tiled across a large floor carpet using any of the
# 17 wallpaper symmetry groups. VR buttons for palette, group cycling,
# mirror/rotate operations.
#
# Layout: XY back-panel (like control_board), carpet on floor below.
# Reuses WallpaperGroups.get_symmetric_color() for tiling.
extends Node3D
class_name PatternMakerStation

const SLIDER_H = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

# ── Palette ──────────────────────────────────────────────────────────
# Italian textile palette (matches PatternTilePuzzle / ArrayCarpet)
const PALETTE: Array[Color] = [
	Color(0.95, 0.92, 0.85),  # Cream/natural
	Color(0.8, 0.2, 0.15),    # Deep red
	Color(0.15, 0.25, 0.5),   # Navy blue
	Color(0.7, 0.55, 0.2),    # Gold/ochre
	Color(0.2, 0.4, 0.25),    # Forest green
	Color(0.4, 0.2, 0.15),    # Brown
	Color(0.1, 0.1, 0.12),    # Near black
	Color(0.6, 0.3, 0.5)      # Dusty purple
]

const COL_PANEL := Color(0.08, 0.08, 0.10)
const COL_BEZEL := Color(0.15, 0.15, 0.18)
const COL_GRID_LINE := Color(0.3, 0.3, 0.35, 0.8)

# ── Config ───────────────────────────────────────────────────────────
@export var tile_size: int = 4          # Domain NxN (2-8)
@export var cell_size: float = 0.06     # Meters per cell on panel
@export var panel_width: float = 1.2    # XY panel width
@export var panel_height: float = 0.9   # XY panel height
@export var carpet_world_size: float = 3.0  # Carpet side length in meters
@export var carpet_repeats: int = 8     # How many domain repeats across carpet

# ── Groups ───────────────────────────────────────────────────────────
const GROUP_ORDER: Array = [
	WallpaperGroups.Group.P1,   WallpaperGroups.Group.P2,
	WallpaperGroups.Group.PM,   WallpaperGroups.Group.PG,
	WallpaperGroups.Group.CM,   WallpaperGroups.Group.PMM,
	WallpaperGroups.Group.PMG,  WallpaperGroups.Group.PGG,
	WallpaperGroups.Group.CMM,  WallpaperGroups.Group.P4,
	WallpaperGroups.Group.P4M,  WallpaperGroups.Group.P4G,
	WallpaperGroups.Group.P3,   WallpaperGroups.Group.P3M1,
	WallpaperGroups.Group.P31M, WallpaperGroups.Group.P6,
	WallpaperGroups.Group.P6M,
]

# ── State ────────────────────────────────────────────────────────────
var _grid_data: Array = []          # 2D array of color indices
var _selected_color: int = 1        # Current paint color
var _group_index: int = 0           # Index into GROUP_ORDER
var _current_group: WallpaperGroups.Group = WallpaperGroups.Group.P1

# ── Scene refs ───────────────────────────────────────────────────────
var _cell_meshes: Array = []        # 2D array of MeshInstance3D
var _cell_materials: Array = []     # 2D array of StandardMaterial3D
var _carpet_mesh: MeshInstance3D
var _carpet_material: StandardMaterial3D
var _group_label: Label3D
var _size_label: Label3D
var _palette_indicators: Array[MeshInstance3D] = []
var _edit_grid_container: Node3D
var _touch_area: Area3D
var _last_painted_cell: Vector2i = Vector2i(-1, -1)

# ═══════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════

func _ready() -> void:
	_init_grid_data()
	_build_back_panel()
	_build_edit_grid()
	_build_palette()
	_build_controls()
	_build_carpet()
	_build_touch_area()
	_build_capture_camera()
	_update_carpet()
	print("[PatternMaker] Built — %dx%d domain, group %s, carpet %.1fm" % [
		tile_size, tile_size,
		WallpaperGroups.get_group_name(_current_group),
		carpet_world_size])

func _process(_delta: float) -> void:
	_check_touch_paint()

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("tile_size"):
		tile_size = clampi(int(config_data["tile_size"]), 2, 8)
	if config_data.has("carpet_size"):
		carpet_world_size = float(config_data["carpet_size"])
	if config_data.has("carpet_repeats"):
		carpet_repeats = int(config_data["carpet_repeats"])
	if config_data.has("wallpaper_group"):
		_group_index = clampi(int(config_data["wallpaper_group"]), 0, GROUP_ORDER.size() - 1)
		_current_group = GROUP_ORDER[_group_index]

# ═══════════════════════════════════════════════════════════════════
# DATA
# ═══════════════════════════════════════════════════════════════════

func _init_grid_data() -> void:
	_grid_data.clear()
	for y in tile_size:
		var row: Array = []
		for x in tile_size:
			row.append(0)
		_grid_data.append(row)
	# Seed a small pattern so the carpet isn't blank
	if tile_size >= 4:
		_grid_data[0][0] = 1; _grid_data[0][3] = 2
		_grid_data[1][1] = 3; _grid_data[1][2] = 3
		_grid_data[2][1] = 3; _grid_data[2][2] = 3
		_grid_data[3][0] = 2; _grid_data[3][3] = 1

# ═══════════════════════════════════════════════════════════════════
# BUILDERS
# ═══════════════════════════════════════════════════════════════════

func _build_back_panel() -> void:
	var plate := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(panel_width, panel_height, 0.04)
	plate.mesh = mesh
	plate.material_override = _mat(COL_PANEL, 0.3, 0.7)
	plate.position = Vector3(0, panel_height * 0.5, -0.02)
	add_child(plate)

func _build_edit_grid() -> void:
	_edit_grid_container = Node3D.new()
	_edit_grid_container.name = "EditGrid"
	add_child(_edit_grid_container)

	var grid_total := tile_size * cell_size
	var start_x := -grid_total / 2.0
	var start_y := panel_height - 0.08 - grid_total  # Top area of panel

	_cell_meshes.clear()
	_cell_materials.clear()

	for y in tile_size:
		var row_meshes: Array = []
		var row_mats: Array = []
		for x in tile_size:
			var cell := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(cell_size * 0.92, cell_size * 0.92)
			cell.mesh = qm

			var color_idx: int = _grid_data[y][x]
			var mat := StandardMaterial3D.new()
			mat.albedo_color = PALETTE[color_idx]
			mat.roughness = 0.8
			cell.material_override = mat

			cell.position = Vector3(
				start_x + x * cell_size + cell_size * 0.5,
				start_y + (tile_size - 1 - y) * cell_size + cell_size * 0.5,
				0.005
			)
			_edit_grid_container.add_child(cell)
			row_meshes.append(cell)
			row_mats.append(mat)
		_cell_meshes.append(row_meshes)
		_cell_materials.append(row_mats)

	# Grid lines
	_build_grid_lines(start_x, start_y, grid_total)
	# Frame
	_build_grid_frame(start_x, start_y, grid_total)

	# Title label
	var title := Label3D.new()
	title.text = "PATTERN MAKER"
	title.pixel_size = 0.0008
	title.font_size = 14
	title.modulate = Color(0.7, 0.7, 0.7)
	title.position = Vector3(0, panel_height - 0.03, 0.01)
	add_child(title)

func _build_grid_lines(start_x: float, start_y: float, total: float) -> void:
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = COL_GRID_LINE
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	for i in tile_size + 1:
		# Vertical
		var vl := MeshInstance3D.new()
		var vm := BoxMesh.new()
		vm.size = Vector3(0.001, total, 0.001)
		vl.mesh = vm
		vl.material_override = line_mat
		vl.position = Vector3(start_x + i * cell_size, start_y + total * 0.5, 0.006)
		_edit_grid_container.add_child(vl)

		# Horizontal
		var hl := MeshInstance3D.new()
		var hm := BoxMesh.new()
		hm.size = Vector3(total, 0.001, 0.001)
		hl.mesh = hm
		hl.material_override = line_mat
		hl.position = Vector3(start_x + total * 0.5, start_y + i * cell_size, 0.006)
		_edit_grid_container.add_child(hl)

func _build_grid_frame(start_x: float, start_y: float, total: float) -> void:
	var frame_w := 0.008
	var frame_mat := _mat(COL_BEZEL, 0.5, 0.5)
	var cx := start_x + total * 0.5
	var cy := start_y + total * 0.5

	for data in [
		[Vector3(total + frame_w * 2, frame_w, 0.01), Vector3(cx, cy + total * 0.5 + frame_w * 0.5, 0.003)],
		[Vector3(total + frame_w * 2, frame_w, 0.01), Vector3(cx, cy - total * 0.5 - frame_w * 0.5, 0.003)],
		[Vector3(frame_w, total, 0.01), Vector3(cx - total * 0.5 - frame_w * 0.5, cy, 0.003)],
		[Vector3(frame_w, total, 0.01), Vector3(cx + total * 0.5 + frame_w * 0.5, cy, 0.003)],
	]:
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = data[0]
		bar.mesh = bm
		bar.material_override = frame_mat
		bar.position = data[1]
		_edit_grid_container.add_child(bar)

func _build_palette() -> void:
	var base_y: float = 0.12
	var start_x: float = -panel_width * 0.5 + 0.08
	var spacing: float = 0.065

	# Palette label
	var lbl := Label3D.new()
	lbl.text = "COLOR"
	lbl.pixel_size = 0.0006
	lbl.font_size = 8
	lbl.modulate = Color(0.5, 0.5, 0.5)
	lbl.position = Vector3(start_x - 0.02, base_y + 0.04, 0.01)
	add_child(lbl)

	_palette_indicators.clear()
	for i in PALETTE.size():
		var btn := PUSH_BUTTON.instantiate()
		btn.name = "PaletteBtn_%d" % i
		btn.position = Vector3(start_x + i * spacing, base_y, 0.02)
		btn.scale = Vector3(0.5, 0.5, 0.5)
		btn.pressed_color = PALETTE[i]
		btn.released_color = PALETTE[i].darkened(0.3)
		add_child(btn)
		var area := btn.get_node_or_null("InteractableAreaButton")
		if area:
			var idx := i
			area.button_pressed.connect(func(_b): _select_color(idx))

		# Active indicator (glowing dot below button)
		var indicator := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.008
		sm.height = 0.016
		indicator.mesh = sm
		var ind_mat := StandardMaterial3D.new()
		ind_mat.emission_enabled = true
		ind_mat.emission = PALETTE[i]
		ind_mat.emission_energy_multiplier = 0.0 if i != _selected_color else 2.5
		ind_mat.albedo_color = PALETTE[i].darkened(0.5)
		indicator.material_override = ind_mat
		indicator.position = Vector3(start_x + i * spacing, base_y - 0.035, 0.02)
		add_child(indicator)
		_palette_indicators.append(indicator)

func _build_controls() -> void:
	var base_x: float = panel_width * 0.5 - 0.12
	var base_y: float = panel_height - 0.15

	# ── Group cycle button ──
	var group_btn := PUSH_BUTTON.instantiate()
	group_btn.name = "GroupCycle"
	group_btn.position = Vector3(base_x, base_y, 0.02)
	group_btn.scale = Vector3(0.6, 0.6, 0.6)
	group_btn.pressed_color = Color(0.3, 0.6, 0.9)
	group_btn.released_color = Color(0.15, 0.3, 0.45)
	add_child(group_btn)
	_connect_btn(group_btn, _cycle_group)

	_group_label = Label3D.new()
	_group_label.text = WallpaperGroups.get_group_name(_current_group).to_upper()
	_group_label.pixel_size = 0.0008
	_group_label.font_size = 12
	_group_label.modulate = Color(0.3, 0.7, 1.0)
	_group_label.position = Vector3(base_x, base_y - 0.04, 0.01)
	add_child(_group_label)

	var group_lbl := Label3D.new()
	group_lbl.text = "GROUP"
	group_lbl.pixel_size = 0.0005
	group_lbl.font_size = 7
	group_lbl.modulate = Color(0.4, 0.4, 0.4)
	group_lbl.position = Vector3(base_x, base_y + 0.035, 0.01)
	add_child(group_lbl)

	# ── Mirror X ──
	var mx_btn := PUSH_BUTTON.instantiate()
	mx_btn.name = "MirrorX"
	mx_btn.position = Vector3(base_x, base_y - 0.10, 0.02)
	mx_btn.scale = Vector3(0.5, 0.5, 0.5)
	mx_btn.pressed_color = Color(0.8, 0.6, 0.2)
	mx_btn.released_color = Color(0.4, 0.3, 0.1)
	add_child(mx_btn)
	_connect_btn(mx_btn, _mirror_x)
	_add_btn_label(mx_btn, "FLIP X")

	# ── Mirror Y ──
	var my_btn := PUSH_BUTTON.instantiate()
	my_btn.name = "MirrorY"
	my_btn.position = Vector3(base_x, base_y - 0.17, 0.02)
	my_btn.scale = Vector3(0.5, 0.5, 0.5)
	my_btn.pressed_color = Color(0.8, 0.6, 0.2)
	my_btn.released_color = Color(0.4, 0.3, 0.1)
	add_child(my_btn)
	_connect_btn(my_btn, _mirror_y)
	_add_btn_label(my_btn, "FLIP Y")

	# ── Rotate CW ──
	var rot_btn := PUSH_BUTTON.instantiate()
	rot_btn.name = "RotateCW"
	rot_btn.position = Vector3(base_x, base_y - 0.24, 0.02)
	rot_btn.scale = Vector3(0.5, 0.5, 0.5)
	rot_btn.pressed_color = Color(0.2, 0.7, 0.5)
	rot_btn.released_color = Color(0.1, 0.35, 0.25)
	add_child(rot_btn)
	_connect_btn(rot_btn, _rotate_cw)
	_add_btn_label(rot_btn, "ROTATE")

	# ── Clear ──
	var clr_btn := PUSH_BUTTON.instantiate()
	clr_btn.name = "Clear"
	clr_btn.position = Vector3(base_x, base_y - 0.31, 0.02)
	clr_btn.scale = Vector3(0.5, 0.5, 0.5)
	clr_btn.pressed_color = Color(0.8, 0.2, 0.2)
	clr_btn.released_color = Color(0.4, 0.1, 0.1)
	add_child(clr_btn)
	_connect_btn(clr_btn, _clear_domain)
	_add_btn_label(clr_btn, "CLEAR")

func _build_carpet() -> void:
	_carpet_mesh = MeshInstance3D.new()
	_carpet_mesh.name = "Carpet"

	var quad := QuadMesh.new()
	quad.size = Vector2(carpet_world_size, carpet_world_size)
	_carpet_mesh.mesh = quad

	# Lie flat on the floor in front of the panel
	_carpet_mesh.rotation_degrees.x = -90
	_carpet_mesh.position = Vector3(0, 0.005, carpet_world_size * 0.5 + 0.3)

	_carpet_material = StandardMaterial3D.new()
	_carpet_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_carpet_material.roughness = 0.9
	_carpet_material.metallic = 0.0
	_carpet_mesh.material_override = _carpet_material

	add_child(_carpet_mesh)

func _build_capture_camera() -> void:
	# Built-in camera for screenshot capture — positioned to show
	# both the upright panel and the floor carpet in one shot.
	var cam := Camera3D.new()
	cam.name = "CaptureCamera"
	cam.fov = 60.0
	cam.position = Vector3(0.3, 1.4, 4.2)
	cam.look_at(Vector3(-0.1, 0.25, 0.6), Vector3.UP)
	add_child(cam)

func _build_touch_area() -> void:
	_touch_area = Area3D.new()
	_touch_area.name = "TouchArea"
	_touch_area.collision_layer = 1048576  # Bit 20 (interactive)
	_touch_area.collision_mask = 393216    # Bits 18+19 (hands+pointers)
	_touch_area.monitoring = true
	_touch_area.monitorable = false

	var grid_total := tile_size * cell_size
	var start_y := panel_height - 0.08 - grid_total

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(grid_total + 0.02, grid_total + 0.02, 0.06)
	collision.shape = shape
	collision.position = Vector3(
		0,
		start_y + grid_total * 0.5,
		0.01
	)
	_touch_area.add_child(collision)
	add_child(_touch_area)

# ═══════════════════════════════════════════════════════════════════
# INTERACTIONS
# ═══════════════════════════════════════════════════════════════════

func _select_color(idx: int) -> void:
	_selected_color = idx
	# Update indicators
	for i in _palette_indicators.size():
		var mat: StandardMaterial3D = _palette_indicators[i].material_override
		mat.emission_energy_multiplier = 2.5 if i == _selected_color else 0.0
	print("[PatternMaker] Color → %d" % idx)

func _cycle_group() -> void:
	_group_index = (_group_index + 1) % GROUP_ORDER.size()
	_current_group = GROUP_ORDER[_group_index]
	_group_label.text = WallpaperGroups.get_group_name(_current_group).to_upper()
	_update_carpet()
	print("[PatternMaker] Group → %s" % WallpaperGroups.get_group_name(_current_group))

func _mirror_x() -> void:
	var new_data: Array = []
	for y in tile_size:
		var row: Array = []
		for x in tile_size:
			row.append(_grid_data[y][tile_size - 1 - x])
		new_data.append(row)
	_grid_data = new_data
	_refresh_grid_visuals()
	_update_carpet()

func _mirror_y() -> void:
	var new_data: Array = []
	for y in tile_size:
		new_data.append(_grid_data[tile_size - 1 - y].duplicate())
	_grid_data = new_data
	_refresh_grid_visuals()
	_update_carpet()

func _rotate_cw() -> void:
	var new_data: Array = []
	for y in tile_size:
		var row: Array = []
		for x in tile_size:
			row.append(_grid_data[tile_size - 1 - x][y])
		new_data.append(row)
	_grid_data = new_data
	_refresh_grid_visuals()
	_update_carpet()

func _clear_domain() -> void:
	for y in tile_size:
		for x in tile_size:
			_grid_data[y][x] = 0
	_refresh_grid_visuals()
	_update_carpet()

func _paint_cell(gx: int, gy: int) -> void:
	if gx < 0 or gx >= tile_size or gy < 0 or gy >= tile_size:
		return
	if _grid_data[gy][gx] == _selected_color:
		return
	_grid_data[gy][gx] = _selected_color
	_cell_materials[gy][gx].albedo_color = PALETTE[_selected_color]
	_update_carpet()

func _check_touch_paint() -> void:
	var bodies := _touch_area.get_overlapping_bodies()
	if bodies.is_empty():
		_last_painted_cell = Vector2i(-1, -1)
		return

	# Find closest hand/pointer body to the grid surface
	for body in bodies:
		var local_pos := _edit_grid_container.to_local(body.global_position)
		var grid_total := tile_size * cell_size
		var start_x := -grid_total / 2.0
		var start_y := panel_height - 0.08 - grid_total

		var gx := int((local_pos.x - start_x) / cell_size)
		var gy := tile_size - 1 - int((local_pos.y - start_y) / cell_size)

		if gx >= 0 and gx < tile_size and gy >= 0 and gy < tile_size:
			var cell := Vector2i(gx, gy)
			if cell != _last_painted_cell:
				_last_painted_cell = cell
				_paint_cell(gx, gy)
			return

func _refresh_grid_visuals() -> void:
	for y in tile_size:
		for x in tile_size:
			var color_idx: int = _grid_data[y][x]
			_cell_materials[y][x].albedo_color = PALETTE[color_idx]

# ═══════════════════════════════════════════════════════════════════
# CARPET TEXTURE
# ═══════════════════════════════════════════════════════════════════

func _update_carpet() -> void:
	var tex_size: int = carpet_repeats * tile_size
	if tex_size <= 0:
		return

	var image := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)

	for py in tex_size:
		for px in tex_size:
			var color_idx: int = WallpaperGroups.get_symmetric_color(
				px, py, tile_size, _grid_data, _current_group
			)
			var color: Color = PALETTE[color_idx] if color_idx < PALETTE.size() else Color.WHITE
			image.set_pixel(px, py, color)

	var texture := ImageTexture.create_from_image(image)
	_carpet_material.albedo_texture = texture

# ═══════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════

func _mat(color: Color, metallic: float = 0.0, roughness: float = 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m

func _connect_btn(btn: Node, callback: Callable) -> void:
	var area := btn.get_node_or_null("InteractableAreaButton")
	if area:
		area.button_pressed.connect(func(_b): callback.call())

func _add_btn_label(btn: Node, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0006
	lbl.font_size = 7
	lbl.modulate = Color(0.6, 0.6, 0.6)
	lbl.position = Vector3(0, -0.03, 0)
	btn.add_child(lbl)
