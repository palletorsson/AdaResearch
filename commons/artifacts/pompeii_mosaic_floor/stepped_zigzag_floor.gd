# stepped_zigzag_floor.gd
# Procedural Pompeii mosaic floor — stepped zigzag (3D staircase illusion).
# Interlocking L-shaped steps with 3 tones create an optical illusion of
# never-ending staircases ascending and descending across the floor.
# Border: dark(2), light(1), dark(1).
#
# @identity
#   essence: a floor where flat stone becomes an impossible staircase
#   desire: players look down and see Escher-like depth from three shades of marble
#   critical_parameter: cells_short — number of zigzag cells on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the realization that luminance alone can fabricate volume
#   needs: [implemented] procedural mesh, border bands, stepped L-shape pixel grid
#   relationships: tumbling_blocks_floor (sibling 3D illusion), swastika_meander_floor (sibling meander)
#   truth: stepped zigzag patterns appear in Roman, Greek, and pre-Columbian floors alike

extends Node3D
class_name SteppedZigzagFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")
const BorderMotifs = preload("res://commons/artifacts/pompeii_mosaic_floor/border_motifs.gd")

@export var floor_size: Vector2 = Vector2(1.0, 1.0)
@export var cells_short: int = 4
@export var border_widths: Array[int] = [2, 1, 1]
@export var border_motif: int = BorderMotifs.Motif.SOLID
@export var color_dark: Color = MosaicPalette.DARK
@export var color_medium: Color = MosaicPalette.MEDIUM
@export var color_light: Color = MosaicPalette.LIGHT
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.02
@export_range(0.0, 1.0) var wear_level: float = 0.3

var _mi: MeshInstance3D
#var _body: StaticBody3D

## The repeat tile is 8x8 pixels containing interlocking L-shaped steps.
## The pattern uses three tones — dark (0), medium (1), light (2) — to shade
## the riser, tread and top face of each step, creating the illusion of a
## 3D staircase viewed from above.  Adjacent tiles interlock seamlessly.
##
## Pixel values: 0=dark, 1=medium, 2=light
const CELL := 12   # repeat tile size in pixels
const TILE_SIZE := 12


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


## Build the 12x12 stepped zigzag tile bitmap.
## Returns an Array[Array[int]] where 0=dark, 1=medium, 2=light.
##
## The pattern creates interlocking L-shaped steps that form a zigzag.
## Steps descend diagonally for 6 rows, then reverse direction for the
## next 6 rows, creating a continuous chevron/zigzag staircase.
##
## The 3D illusion comes from consistent directional shading:
##   - DARK (0): shadow/riser face of each step
##   - MEDIUM (1): tread surface (the flat step)
##   - LIGHT (2): lit/highlight face of each step
##
## The tile contains two L-shaped stair units that interlock:
##   Unit A (rows 0-5): steps descend to the right (dark-medium-light)
##   Unit B (rows 6-11): steps descend to the left (mirror of A)
## This creates a zigzag when tiled vertically.
static func _make_tile() -> Array:
	var D := 0
	var M := 1
	var L := 2
	# Each row has a dark band (2px wide) with medium borders, on a light ground.
	# The dark band zigzags: moves right 2px every 2 rows for 6 rows,
	# then left 2px every 2 rows for 6 rows, creating chevron steps.
	# The band wraps horizontally via modular arithmetic.
	var tile := []
	var n := TILE_SIZE
	for r in n:
		var row := []
		for _c in n:
			row.append(L)
		tile.append(row)

	# Zigzag offsets: for each pair of rows, the dark band center shifts.
	# Rows 0-1: offset 0, rows 2-3: offset +2, rows 4-5: offset +4
	# Rows 6-7: offset +4, rows 8-9: offset +2, rows 10-11: offset 0
	var offsets := [0, 0, 2, 2, 4, 4, 4, 4, 2, 2, 0, 0]

	for r in n:
		var off: int = offsets[r]
		# Dark band: 2 pixels wide
		var d0: int = off % n
		var d1: int = (off + 1) % n
		# Medium borders on each side of the dark band
		var m_left: int = (off - 1 + n) % n
		var m_right: int = (off + 2) % n

		tile[r][d0] = D
		tile[r][d1] = D
		tile[r][m_left] = M
		tile[r][m_right] = M

		# Second dark band (offset by half the tile width for interlocking)
		var off2: int = (off + 6) % n
		var d2: int = off2 % n
		var d3: int = (off2 + 1) % n
		var m2_left: int = (off2 - 1 + n) % n
		var m2_right: int = (off2 + 2) % n

		tile[r][d2] = D
		tile[r][d3] = D
		tile[r][m2_left] = M
		tile[r][m2_right] = M

	return tile


func _build() -> void:
	if _mi:
		_mi.queue_free()
		_mi = null
	#if _body:
		#_body.queue_free()
		#_body = null

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
	var med_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	# ── 1. Border bands: dark(2), light(1), dark(1) ──
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

	# ── 2. Stepped zigzag field ──
	var field_w := tiles_x * TILE_SIZE
	var field_h := tiles_y * TILE_SIZE

	for fy in field_h:
		for fx in field_w:
			var ty := fy % TILE_SIZE
			var tx := fx % TILE_SIZE
			var val: int = tile[ty][tx]
			var wx := (border_each + fx) * px_m
			var wz := (border_each + fy) * px_m

			if val == 0:
				dark_verts = _add_rect.call(dark_verts, wx, wz, px_m, px_m)
			elif val == 1:
				med_verts = _add_rect.call(med_verts, wx, wz, px_m, px_m)
			else:
				light_verts = _add_rect.call(light_verts, wx, wz, px_m, px_m)

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
	med_verts = _offset_y.call(med_verts, 0.001)
	light_verts = _offset_y.call(light_verts, 0.001)
	grout_verts = _offset_y.call(grout_verts, -0.001)
	terra_verts = _offset_y.call(terra_verts, 0.002)

	# ── Build ArrayMesh ──
	var arr_mesh := ArrayMesh.new()
	var surf_idx := 0

	if dark_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = dark_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(surf_idx, MosaicPalette.create_material(color_dark, wear_level))
		surf_idx += 1

	if med_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = med_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(surf_idx, MosaicPalette.create_material(color_medium, wear_level))
		surf_idx += 1

	if light_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = light_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(surf_idx, MosaicPalette.create_material(color_light, wear_level))
		surf_idx += 1

	# Merge border terracotta if any
	if terra_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = terra_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(surf_idx, MosaicPalette.create_material(MosaicPalette.TERRACOTTA, wear_level))
		surf_idx += 1

	if grout_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = grout_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(surf_idx, MosaicPalette.create_material(grout_color, wear_level))
		surf_idx += 1

	_mi = MeshInstance3D.new()
	_mi.mesh = arr_mesh
	_mi.position = Vector3(-fw * 0.5, 0.005, -fh * 0.5)
	add_child(_mi)

	# ── StaticBody3D with box collision ──
	#_body = StaticBody3D.new()
	#var col := CollisionShape3D.new()
	#var box := BoxShape3D.new()
	#box.size = Vector3(fw, 0.01, fh)
	#col.shape = box
	#_body.add_child(col)
	#_body.position = Vector3(0, 0.005, 0)
	#add_child(_body)

	print("[SteppedZigzagFloor] Built %dx%d tiles, %dx%d px grid (%d dark, %d med, %d light tris)" % [
		tiles_x, tiles_y, gw_px, gh_px,
		dark_verts.size() / 3,
		med_verts.size() / 3,
		light_verts.size() / 3,
	])
