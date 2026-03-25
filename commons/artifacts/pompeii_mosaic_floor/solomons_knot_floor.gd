# solomons_knot_floor.gd
# Procedural Pompeii mosaic floor — Solomon's Knot (nodo di Salomone).
# Two interlocked loops forming an infinite knot, a classic Roman/Byzantine
# decorative motif. Pixel-grid bitmap approach with 3 colors to show
# over-under weave: dark loop, terracotta loop, light background.
# Border: dark(2), light(1), dark(2).
#
# @identity
#   essence: a floor bearing the eternal interlace of Solomon's Knot
#   desire: players look down and see two loops that can never be separated
#   critical_parameter: cells_short — number of knot repeat-units on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the insight that two simple loops, woven together, create infinity
#   needs: [implemented] procedural mesh, border bands, pixel-grid knot
#   relationships: pompeii_mosaic_floor (sibling truchet), swastika_meander_floor (sibling bitmap)
#   truth: the knot of Solomon appears on Roman floors, Jewish synagogues, and Christian basilicas alike

extends Node3D
class_name SolomonsKnotFloor

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

## The repeat tile is 16x16 pixels.
## 0 = background (light), 1 = dark loop, 2 = terracotta loop
## The knot is two interlocked oval loops with over-under crossings.
const TILE_SIZE := 16


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


## Build the 16x16 Solomon's Knot tile bitmap.
## 0=light (background), 1=dark loop, 2=terracotta loop.
## Two interlocked oval loops with alternating over-under at crossings.
## Dark loop runs diagonally TL-BR, terracotta loop runs diagonally TR-BL.
## At each crossing, the "over" strand covers 2px of the "under" strand.
static func _make_tile() -> Array:
	# Solomon's Knot in a 16x16 grid.
	# The knot has 4 lobes (NW, NE, SE, SW) with crossings between them.
	# Dark loop (1): connects NW and SE lobes
	# Terra loop (2): connects NE and SW lobes
	# Over-under alternates: at NE crossing dark is over, at SW crossing terra is over.
	#
	#   Band width = 2px for each strand
	#   Each lobe is roughly a rounded rectangle ~6x6 in a quadrant

	var t := [
		#  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
		[0, 0, 0, 1, 1, 1, 1, 0, 0, 2, 2, 2, 2, 0, 0, 0],  # row 0
		[0, 0, 1, 1, 0, 0, 1, 1, 2, 2, 0, 0, 2, 2, 0, 0],  # row 1
		[0, 1, 1, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 2, 2, 0],  # row 2
		[1, 1, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 2, 2],  # row 3
		[1, 0, 0, 0, 0, 0, 1, 1, 2, 2, 0, 0, 0, 0, 0, 2],  # row 4
		[1, 0, 0, 0, 0, 1, 1, 0, 0, 2, 2, 0, 0, 0, 0, 2],  # row 5
		[1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 2, 2, 0, 0, 2, 2],  # row 6
		[0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 0],  # row 7
		[0, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0],  # row 8
		[2, 2, 0, 0, 2, 2, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1],  # row 9
		[2, 0, 0, 0, 0, 2, 2, 0, 0, 1, 1, 0, 0, 0, 0, 2],  # row 10
		[2, 0, 0, 0, 0, 0, 2, 2, 1, 1, 0, 0, 0, 0, 0, 2],  # row 11
		[2, 2, 0, 0, 0, 0, 0, 2, 1, 0, 0, 0, 0, 0, 1, 1],  # row 12
		[0, 2, 2, 0, 0, 0, 0, 2, 1, 0, 0, 0, 0, 1, 1, 0],  # row 13
		[0, 0, 2, 2, 0, 0, 2, 2, 1, 1, 0, 0, 1, 1, 0, 0],  # row 14
		[0, 0, 0, 2, 2, 2, 2, 0, 0, 1, 1, 1, 1, 0, 0, 0],  # row 15
	]
	return t


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

	# -- 1. Border bands --
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

	# -- 2. Knot field --
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
			elif val == 2:
				accent_verts = _add_rect.call(accent_verts, wx, wz, px_m, px_m)
			else:
				light_verts = _add_rect.call(light_verts, wx, wz, px_m, px_m)

	# -- 3. Grout lines --
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

	# -- Build ArrayMesh --
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

	# Merge border terracotta into accent verts
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

	# StaticBody3D for collision
	var body := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(fw, 0.01, fh)
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	body.position = Vector3(0, 0.005, 0)
	add_child(body)

	print("[SolomonsKnotFloor] Built %dx%d tiles, %dx%d px grid" % [
		tiles_x, tiles_y, gw_px, gh_px,
	])
