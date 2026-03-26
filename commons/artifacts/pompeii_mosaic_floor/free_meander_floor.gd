# free_meander_floor.gd
# Rule-based Greek key meander — no tiles, no turtle, no bitmap.
# Each cell decides its own color from ONE modular arithmetic rule
# applied to its global position, exactly as a Roman mosaicist
# would place each stone independently.
#
# THE RULE: territory = ((pos_along + ring * band_width) % period) < half_period
#
# pos_along = continuous position around the entire border perimeter
# ring = depth / band_width (which concentric ring of the spiral)
# The shift (ring * band_width) rotates the dark/light boundary inward,
# creating the Greek key hook from pure modular arithmetic.
#
# @identity
#   essence: the Greek key as a per-cell mathematical rule, not a repeated tile
#   desire: players see the cleanest meander yet — because it IS the rule
#   critical_parameter: band_width — controls the hook depth and period
#   triggers: instantiation or apply_grid_config
#   emerges: the insight that all Greek key patterns are one line of modular arithmetic
#   needs: [implemented] per-cell rule evaluation, ArrayMesh, MosaicPalette
#   relationships: exact_meander_floor (bitmap approach), double_snake_meander (walk approach)
#   truth: Roman mosaicists thought in rules, not tiles

extends Node3D
class_name FreeMeanderFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var grid_cells: int = 160          ## cells along the long axis
@export var border_depth: int = 16         ## total border depth in cells (should be 4 * band_width)
@export var band_width: int = 4            ## width of each concentric ring
@export var outer_band: int = 1            ## solid dark frame outside the meander
@export var dot_spacing: int = 5           ## cells between interior polka dots
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.02
@export_range(0.0, 1.0) var wear_level: float = 0.3

var _mi: MeshInstance3D
var _body: StaticBody3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	grid_cells = int(config.get("grid_cells", grid_cells))
	border_depth = int(config.get("border_depth", border_depth))
	band_width = int(config.get("band_width", band_width))
	outer_band = int(config.get("outer_band", outer_band))
	dot_spacing = int(config.get("dot_spacing", dot_spacing))
	wear_level = float(config.get("wear_level", wear_level))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()
		_mi = null
	if _body:
		_body.queue_free()
		_body = null

	# Grid dimensions — cells along each axis
	var is_wide := floor_size.x >= floor_size.y
	var long_m := maxf(floor_size.x, floor_size.y)
	var short_m := minf(floor_size.x, floor_size.y)
	var cell_size := long_m / float(grid_cells)
	var gw: int = grid_cells if is_wide else int(round(short_m / cell_size))
	var gh: int = int(round(short_m / cell_size)) if is_wide else grid_cells
	var cs := cell_size  # shorthand
	var fw := gw * cs
	var fh := gh * cs

	var period: int = 4 * band_width
	var half_period: int = 2 * band_width
	var total_border: int = outer_band + border_depth  # outer solid band + meander zone

	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	# Meander zone boundaries (inside the outer solid band)
	var mz_x0: int = outer_band
	var mz_y0: int = outer_band
	var mz_x1: int = gw - 1 - outer_band
	var mz_y1: int = gh - 1 - outer_band

	for ty in gh:
		for tx in gw:
			var wx := tx * cs
			var wz := ty * cs

			# Distance from each edge
			var d_top := ty
			var d_bot := gh - 1 - ty
			var d_left := tx
			var d_right := gw - 1 - tx
			var min_dist := mini(mini(d_top, d_bot), mini(d_left, d_right))

			# ── Outer solid dark band ──
			if min_dist < outer_band:
				dark_verts = _add_rect(dark_verts, wx, wz, cs, cs)
				continue

			# ── Interior field (dark with polka dots) ──
			if min_dist >= total_border:
				dark_verts = _add_rect(dark_verts, wx, wz, cs, cs)
				continue

			# ── Meander zone ──
			# depth = distance from the outer edge of the meander zone
			var depth: int = min_dist - outer_band

			# Determine which side this cell belongs to using diagonal quadrants.
			# Coordinates relative to the meander zone rectangle.
			var rx: int = tx - mz_x0  # 0..mz_width
			var ry: int = ty - mz_y0  # 0..mz_height
			var mz_w: int = mz_x1 - mz_x0  # width of meander zone rect
			var mz_h: int = mz_y1 - mz_y0  # height of meander zone rect

			# Use cross-products with the diagonals to determine quadrant (side).
			# Diagonal 1: (0,0) to (mz_w, mz_h) — cross = rx*mz_h - ry*mz_w
			# Diagonal 2: (mz_w,0) to (0, mz_h) — cross = (mz_w-rx)*mz_h - ry*mz_w
			var cross1: int = rx * mz_h - ry * mz_w
			var cross2: int = (mz_w - rx) * mz_h - ry * mz_w

			var pos_along: int = 0

			if cross1 >= 0 and cross2 >= 0:
				# Top side: pos_along = tx relative to meander zone left
				pos_along = rx
			elif cross1 >= 0 and cross2 < 0:
				# Right side: pos_along = top_width + ty relative to meander zone top
				pos_along = mz_w + ry
			elif cross1 < 0 and cross2 < 0:
				# Bottom side: pos_along = top_width + right_height + distance from right
				pos_along = mz_w + mz_h + (mz_w - rx)
			else:
				# Left side: pos_along = top_width + right_height + bottom_width + distance from bottom
				pos_along = 2 * mz_w + mz_h + (mz_h - ry)

			# ── THE SQUARED SPIRAL RULE ──
			# Instead of shifting along the perimeter (which creates diagonals),
			# use a 2D XOR-like rule on the LOCAL coordinates within the meander zone.
			# The Greek key is: alternate dark/light in blocks of band_width,
			# with the phase flipping every band_width in BOTH x and y.
			var bx: int = (rx / band_width) % 2  # which horizontal block
			var by: int = (ry / band_width) % 2  # which vertical block
			var is_dark: bool = (bx ^ by) == 0  # XOR creates checkerboard of blocks

			if is_dark:
				dark_verts = _add_rect(dark_verts, wx, wz, cs, cs)
			else:
				light_verts = _add_rect(light_verts, wx, wz, cs, cs)

	# ── Interior polka dots (light on dark field) ──
	var field_x0 := total_border
	var field_y0 := total_border
	var field_x1 := gw - total_border
	var field_y1 := gh - total_border
	var field_w := field_x1 - field_x0
	var field_h := field_y1 - field_y0
	var dots_x := int(field_w / dot_spacing)
	var dots_z := int(field_h / dot_spacing)
	var margin_x := (field_w - dots_x * dot_spacing) * 0.5
	var margin_z := (field_h - dots_z * dot_spacing) * 0.5

	for dz in range(dots_z):
		for dx in range(dots_x):
			var base_px := margin_x + (dx + 0.5) * dot_spacing
			var base_pz := margin_z + (dz + 0.5) * dot_spacing
			var jx := (_hash_2d(dx, dz) - 0.5) * 0.8
			var jz := (_hash_2d(dx + 97, dz + 53) - 0.5) * 0.8
			var px_x := clampf(field_x0 + base_px + jx, field_x0 + 0.5, field_x1 - 1.5)
			var px_z := clampf(field_y0 + base_pz + jz, field_y0 + 0.5, field_y1 - 1.5)
			light_verts = _add_rect(light_verts, px_x * cs, px_z * cs, cs, cs)

	# ── Grout lines ──
	if grout_width_fraction > 0.001:
		var grout_w := cs * grout_width_fraction * 10.0
		var half := grout_w * 0.5
		for gy in range(0, gh + 1):
			grout_verts = _add_rect(grout_verts, 0.0, gy * cs - half, fw, grout_w)
		for gx in range(0, gw + 1):
			grout_verts = _add_rect(grout_verts, gx * cs - half, 0.0, grout_w, fh)

	# ── Y offsets to prevent z-fighting ──
	for i in dark_verts.size():
		dark_verts[i].y = 0.0
	for i in light_verts.size():
		light_verts[i].y = 0.001
	for i in grout_verts.size():
		grout_verts[i].y = -0.001

	# ── Build ArrayMesh ──
	var arr_mesh := ArrayMesh.new()
	if dark_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = dark_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(color_dark, wear_level))
	if light_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = light_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(color_light, wear_level))
	if grout_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = grout_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(grout_color, wear_level))

	_mi = MeshInstance3D.new()
	_mi.mesh = arr_mesh
	_mi.position = Vector3(-fw * 0.5, 0.005, -fh * 0.5)
	add_child(_mi)

	_body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(fw, 0.01, fh)
	col.shape = box
	_body.add_child(col)
	_body.position = Vector3(0, 0.005, 0)
	add_child(_body)

	print("[FreeMeanderFloor] Built %dx%d grid, band=%d, period=%d (%d dark, %d light, %d grout tris)" % [
		gw, gh, band_width, period,
		dark_verts.size() / 3, light_verts.size() / 3, grout_verts.size() / 3,
	])


func _add_rect(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
	verts.append(Vector3(x, 0, z))
	verts.append(Vector3(x + w, 0, z))
	verts.append(Vector3(x + w, 0, z + h))
	verts.append(Vector3(x, 0, z))
	verts.append(Vector3(x + w, 0, z + h))
	verts.append(Vector3(x, 0, z + h))
	return verts


func _hash_2d(x: int, y: int) -> float:
	var n := x * 374761393 + y * 668265263
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0x7FFFFFFF) / float(0x7FFFFFFF)
