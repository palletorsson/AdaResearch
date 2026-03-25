# swastika_meander_floor.gd
# Procedural Pompeii mosaic floor — swastika meander (Greek key labyrinth).
# Continuous meander path of dark tesserae on light background,
# with small terracotta squares at the center of each meander cell's void.
# Border: dark(2), light(1), dark(2).
#
# @identity
#   essence: a floor carrying the labyrinthine logic of the Greek key meander
#   desire: players trace the continuous path and see it form swastika-like shapes
#   critical_parameter: cells_short — number of meander repeat-units on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the realization that a single L-shaped motif, rotated, fills the plane
#   needs: [implemented] procedural mesh, border bands, meander pixel grid
#   relationships: pompeii_mosaic_floor (sibling truchet pattern), mosaic_palette
#   truth: the meander is one of humanity's oldest continuous ornaments

extends Node3D
class_name SwastikaMeanderFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")
const BorderMotifs = preload("res://commons/artifacts/pompeii_mosaic_floor/border_motifs.gd")

@export var floor_size: Vector2 = Vector2(1.0, 1.0)
@export var cells_short: int = 3
@export var border_widths: Array[int] = [2, 1, 2]
@export var border_motif: int = BorderMotifs.Motif.SOLID
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var color_accent: Color = MosaicPalette.TERRACOTTA
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.02
@export_range(0.0, 1.0) var wear_level: float = 0.3

var _mi: MeshInstance3D

## The repeat tile is 24x24 pixels, comprising two rows of 12px meander
## cells offset by half a cell (6px).  Band width = 2px.
## Each cell contains a squared-spiral hook: horizontal top band → right
## descender → inner return bar → inner descender.  The half-cell offset
## between rows creates the interlocking that forms swastika-like shapes
## at the intersection points.
const B := 2       # band width in pixels
const CELL := 12   # meander cell size in pixels
const TILE_SIZE := 24  # repeat tile = 2 cell rows × 2 cell cols


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	cells_short = int(config.get("cells_short", cells_short))
	wear_level = float(config.get("wear_level", wear_level))
	var bw = config.get("border_widths", null)
	if bw is Array:
		border_widths.clear()
		for v in bw:
			border_widths.append(int(v))
	_build()


## Build the 24x24 meander tile bitmap.  0=light, 1=dark.
static func _make_tile() -> Array:
	var n := TILE_SIZE
	var g := []
	for r in n:
		var row := []
		for c in n:
			row.append(0)
		g.append(row)

	# Fill a rectangle with dark pixels
	var fill := func(r0: int, c0: int, h: int, w: int):
		for r in range(r0, mini(r0 + h, n)):
			for c in range(c0, mini(c0 + w, n)):
				if r >= 0 and c >= 0:
					g[r][c] = 1

	# ── Top meander row (rows 0-11) ──
	# Two cells side by side at cols 0-11 and 12-23.
	# Each cell hook: top band → right descender → inner bar → inner descender
	for cell_x in [0, 12]:
		fill.call(0, cell_x, B, CELL)                         # top band
		fill.call(B, cell_x + CELL - B, CELL - B * 2, B)      # right descender
		fill.call(CELL - B * 2, cell_x + B * 2, B, CELL - B * 3)  # inner bar
		fill.call(CELL - B * 2, cell_x + B * 2, B * 2, B)     # inner descender

	# ── Bottom meander row (rows 12-23), shifted right by CELL/2 ──
	var shift := CELL / 2
	for cell_start in [shift, shift + CELL]:
		# Top band (wraps at tile edge)
		for c in range(CELL):
			var cc: int = (cell_start + c) % n
			g[12][cc] = 1
			g[13][cc] = 1
		# Right descender
		for r in range(B, CELL - B * 2):
			var cc0: int = (cell_start + CELL - B) % n
			var cc1: int = (cell_start + CELL - B + 1) % n
			g[12 + r][cc0] = 1
			g[12 + r][cc1] = 1
		# Inner bar
		for c in range(B * 2, CELL - B):
			var cc: int = (cell_start + c) % n
			g[12 + CELL - B * 2][cc] = 1
			g[12 + CELL - B * 2 + 1][cc] = 1
		# Inner descender
		for r in range(CELL - B * 2, CELL):
			var cc0: int = (cell_start + B * 2) % n
			var cc1: int = (cell_start + B * 2 + 1) % n
			g[12 + r][cc0] = 1
			g[12 + r][cc1] = 1

	return g


func _build() -> void:
	if _mi:
		_mi.queue_free()

	var tile := _make_tile()

	var border_each: int = 0
	for bw in border_widths:
		border_each += bw

	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	var field_short_px := cells_short * TILE_SIZE
	var total_short_px := field_short_px + border_each * 2
	var px_m := short_m / float(total_short_px)

	var total_long_px := int(round(long_m / px_m))
	var field_long_px := total_long_px - border_each * 2
	var cells_long := int(field_long_px / TILE_SIZE)
	field_long_px = cells_long * TILE_SIZE
	total_long_px = field_long_px + border_each * 2

	var gw_px: int
	var gh_px: int
	var tiles_x: int
	var tiles_y: int
	if is_wide:
		gw_px = total_long_px
		gh_px = total_short_px
		tiles_x = cells_long
		tiles_y = cells_short
	else:
		gw_px = total_short_px
		gh_px = total_long_px
		tiles_x = cells_short
		tiles_y = cells_long

	var fw := gw_px * px_m
	var fh := gh_px * px_m

	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var accent_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	# ── 1. Border bands ──
	var terra_verts := PackedVector3Array()
	var inset: int = 0
	for i in border_widths.size():
		var bw: int = border_widths[i]
		var result := BorderMotifs.draw_border_frame(
			dark_verts, light_verts, terra_verts,
			inset * px_m, inset * px_m,
			(gw_px - inset * 2) * px_m, (gh_px - inset * 2) * px_m,
			bw * px_m, px_m,
			border_motif, i % 2 == 1
		)
		dark_verts = result["dark"]
		light_verts = result["light"]
		terra_verts = result["terra"]
		inset += bw

	# ── 2. Meander field ──
	var field_w := tiles_x * TILE_SIZE
	var field_h := tiles_y * TILE_SIZE

	for fy in field_h:
		for fx in field_w:
			var ty := fy % TILE_SIZE
			var tx := fx % TILE_SIZE
			var val: int = tile[ty][tx]
			var wx := (border_each + fx) * px_m
			var wz := (border_each + fy) * px_m

			if val == 1:
				dark_verts = _add_rect.call(dark_verts, wx, wz, px_m, px_m)
			else:
				light_verts = _add_rect.call(light_verts, wx, wz, px_m, px_m)

	# ── 2b. Terracotta accents at void centers ──
	# Each meander cell has a rectangular void.  Place a 2x2 accent at center.
	# Top-row cells: void at rows 2-7, cols 0-3 → accent at (rows 4-5, cols 1-2)
	# Bottom-row cells (shifted): same relative position
	for ty_tile in tiles_y:
		for tx_tile in tiles_x:
			var bx := border_each + tx_tile * TILE_SIZE
			var bz := border_each + ty_tile * TILE_SIZE

			# Top row cells at cols 0 and 12
			for cell_x in [0, 12]:
				accent_verts = _add_rect.call(accent_verts,
					(bx + cell_x + 1) * px_m, (bz + 4) * px_m,
					float(B) * px_m, float(B) * px_m)

			# Bottom row cells at cols 6 and 18 (shifted, wrapping)
			for cell_x in [6, 18]:
				var cx: int = cell_x % TILE_SIZE
				accent_verts = _add_rect.call(accent_verts,
					(bx + cx + 1) * px_m, (bz + 16) * px_m,
					float(B) * px_m, float(B) * px_m)

	# ── 3. Grout lines ──
	if grout_width_fraction > 0.001:
		var grout_w := px_m * grout_width_fraction * float(TILE_SIZE)
		var half := grout_w * 0.5
		for gy in range(0, gh_px + 1):
			var z := gy * px_m
			grout_verts = _add_rect.call(grout_verts, 0.0, z - half, fw, grout_w)
		for gx in range(0, gw_px + 1):
			var x := gx * px_m
			grout_verts = _add_rect.call(grout_verts, x - half, 0.0, grout_w, fh)


	# ── Z-fighting fix: offset each surface to a distinct Y layer ──
	# Hierarchy: grout(-0.001) < dark(0.0) < light(0.001) < accent/terra(0.002) < border(0.003)
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts
	dark_verts = _offset_y.call(dark_verts, 0.0)
	light_verts = _offset_y.call(light_verts, 0.001)
	accent_verts = _offset_y.call(accent_verts, 0.002)
	grout_verts = _offset_y.call(grout_verts, -0.001)
	terra_verts = _offset_y.call(terra_verts, 0.002)

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

	# Merge border terracotta into accent verts (both use terracotta color)
	if terra_verts.size() > 0:
		accent_verts.append_array(terra_verts)

	if accent_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = accent_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(color_accent, wear_level))

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

	print("[SwastikaMeanderFloor] Built %dx%d tiles, %dx%d px grid" % [
		tiles_x, tiles_y, gw_px, gh_px,
	])
