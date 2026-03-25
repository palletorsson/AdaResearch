# diamonds_squares_floor.gd
# Procedural Pompeii mosaic floor — diamonds-in-squares pattern (photo 172436).
# Each cell contains a rotated diamond (45deg square) inscribed in a square.
# Alternating checkerboard: even cells = dark diamond + light corners,
# odd cells = light diamond + dark corners.
#
# @identity
#   essence: a floor encoding the Roman fascination with nested geometry
#   desire: players see how rotating a square inside a square produces visual rhythm
#   critical_parameter: tiles_short — number of diamond-square cells on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the insight that checkerboard logic operates at multiple scales simultaneously
#   needs: [implemented] procedural mesh, border bands, diamond-in-square field, grout
#   relationships: pompeii_mosaic_floor (sibling pattern), pattern_maker_station (web editor)
#   truth: a diamond is just a square that refused to align with the grid

extends Node3D
class_name DiamondsSquaresFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")
const BorderMotifs = preload("res://commons/artifacts/pompeii_mosaic_floor/border_motifs.gd")

@export var floor_size: Vector2 = Vector2(1.0, 0.75)
@export var tiles_short: int = 8
@export var border_width: int = 2
@export var border_motif: int = BorderMotifs.Motif.MEANDER
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.06

var _mi: MeshInstance3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	tiles_short = int(config.get("tiles_short", tiles_short))
	border_width = int(config.get("border_width", border_width))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()

	# Grid dimensions
	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	var total_short := tiles_short + border_width * 2
	var ts := short_m / float(total_short)  # tile size in meters
	var total_long := int(round(long_m / ts))

	var gw: int = total_long if is_wide else total_short  # grid width in tiles
	var gh: int = total_short if is_wide else total_long   # grid height in tiles

	var fw := gw * ts  # floor width in meters
	var fh := gh * ts  # floor height in meters

	# Field region (inside borders)
	var fx0 := border_width
	var fy0 := border_width
	var fx1 := gw - border_width
	var fy1 := gh - border_width

	# Grout absolute width
	var grout_w := ts * grout_width_fraction

	# Build vertex arrays for 3 surfaces: dark, light, grout
	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	# Helper: add a flat quad (2 triangles) in XZ plane at y=0
	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	# Helper: add a triangle (3 verts) in XZ plane at y=0
	var _add_tri := func(verts: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> PackedVector3Array:
		verts.append(a)
		verts.append(b)
		verts.append(c)
		return verts

	# ── 1. Border bands ──
	var terra_verts := PackedVector3Array()
	if border_width > 0:
		var result := BorderMotifs.draw_border_frame(
			dark_verts, light_verts, terra_verts,
			0.0, 0.0,
			float(gw) * ts, float(gh) * ts,
			float(border_width) * ts, ts,
			border_motif, false
		)
		dark_verts = result["dark"]
		light_verts = result["light"]
		terra_verts = result["terra"]

	# ── 2. Diamond-in-square field ──
	# Each cell: 4 corner triangles + 1 center diamond (2 triangles)
	# Diamond vertices are at the midpoints of each cell edge
	for ty in range(fy0, fy1):
		for tx in range(fx0, fx1):
			var x := tx * ts
			var z := ty * ts

			# Cell corners
			var tl := Vector3(x, 0, z)
			var tr := Vector3(x + ts, 0, z)
			var bl := Vector3(x, 0, z + ts)
			var br := Vector3(x + ts, 0, z + ts)

			# Diamond vertices (midpoints of cell edges)
			var mt := Vector3(x + ts * 0.5, 0, z)           # mid-top
			var mr := Vector3(x + ts, 0, z + ts * 0.5)       # mid-right
			var mb := Vector3(x + ts * 0.5, 0, z + ts)       # mid-bottom
			var ml := Vector3(x, 0, z + ts * 0.5)             # mid-left

			# Checkerboard: field-relative coordinates
			var fx_rel := tx - fx0
			var fy_rel := ty - fy0
			var is_even := ((fx_rel + fy_rel) % 2) == 0

			# Even cells: dark diamond, light corners
			# Odd cells: light diamond, dark corners
			var diamond_verts: PackedVector3Array
			var corner_verts: PackedVector3Array
			if is_even:
				diamond_verts = dark_verts
				corner_verts = light_verts
			else:
				diamond_verts = light_verts
				corner_verts = dark_verts

			# Diamond (center): 2 triangles forming the rotated square
			diamond_verts = _add_tri.call(diamond_verts, mt, mr, mb)
			diamond_verts = _add_tri.call(diamond_verts, mt, mb, ml)

			# 4 corner triangles
			corner_verts = _add_tri.call(corner_verts, tl, mt, ml)  # top-left corner
			corner_verts = _add_tri.call(corner_verts, tr, mr, mt)  # top-right corner
			corner_verts = _add_tri.call(corner_verts, br, mb, mr)  # bottom-right corner
			corner_verts = _add_tri.call(corner_verts, bl, ml, mb)  # bottom-left corner

			# Write back
			if is_even:
				dark_verts = diamond_verts
				light_verts = corner_verts
			else:
				light_verts = diamond_verts
				dark_verts = corner_verts

	# ── 3. Grout lines ──
	if grout_w > 0.001:
		var half := grout_w * 0.5
		# Grid lines: horizontal
		for gy in range(0, gh + 1):
			var z := gy * ts
			grout_verts = _add_rect.call(grout_verts, 0.0, z - half, fw, grout_w)
		# Grid lines: vertical
		for gx in range(0, gw + 1):
			var x := gx * ts
			grout_verts = _add_rect.call(grout_verts, x - half, 0.0, grout_w, fh)

		# Diamond diagonal grout: 4 lines per cell connecting midpoints
		var diag_w := grout_w * 0.7
		var dh := diag_w * 0.7071  # perpendicular half-width for diagonal line
		for ty in range(fy0, fy1):
			for tx in range(fx0, fx1):
				var x := tx * ts
				var z := ty * ts
				var cx := x + ts * 0.5
				var cz := z + ts * 0.5
				# Mid-top to mid-right (NE diagonal)
				_add_diag_line(grout_verts, cx, z, x + ts, cz, dh)
				# Mid-right to mid-bottom (SE diagonal)
				_add_diag_line(grout_verts, x + ts, cz, cx, z + ts, dh)
				# Mid-bottom to mid-left (SW diagonal)
				_add_diag_line(grout_verts, cx, z + ts, x, cz, dh)
				# Mid-left to mid-top (NW diagonal)
				_add_diag_line(grout_verts, x, cz, cx, z, dh)


	# ── Z-fighting fix: offset each surface to a distinct Y layer ──
	# Hierarchy: grout(-0.001) < dark(0.0) < light(0.001) < accent/terra(0.002) < border(0.003)
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts
	dark_verts = _offset_y.call(dark_verts, 0.0)
	light_verts = _offset_y.call(light_verts, 0.001)
	grout_verts = _offset_y.call(grout_verts, -0.001)
	terra_verts = _offset_y.call(terra_verts, 0.002)

	# ── Build ArrayMesh ──
	var arr_mesh := ArrayMesh.new()

	if dark_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = dark_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(0, MosaicPalette.create_material(color_dark, 0.4))

	if light_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = light_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(color_light, 0.3))

	if terra_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = terra_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(MosaicPalette.TERRACOTTA, 0.4))

	if grout_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = grout_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(grout_color, 0.5))

	_mi = MeshInstance3D.new()
	_mi.mesh = arr_mesh
	_mi.position = Vector3(-fw * 0.5, 0.005, -fh * 0.5)  # Center the floor
	add_child(_mi)

	print("[DiamondsSquaresFloor] Built %dx%d grid (%d dark tris, %d light tris, %d grout tris)" % [
		gw, gh,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		grout_verts.size() / 3,
	])


func _add_diag_line(verts: PackedVector3Array, x0: float, z0: float, x1: float, z1: float, dh: float) -> void:
	# Draw a thin quad along the diagonal from (x0,z0) to (x1,z1)
	# dh is the perpendicular half-width
	var dx := x1 - x0
	var dz := z1 - z0
	var length := sqrt(dx * dx + dz * dz)
	if length < 0.0001:
		return
	# Perpendicular direction
	var px := -dz / length * dh
	var pz := dx / length * dh
	# Quad as 2 triangles
	verts.append(Vector3(x0 + px, 0, z0 + pz))
	verts.append(Vector3(x1 + px, 0, z1 + pz))
	verts.append(Vector3(x1 - px, 0, z1 - pz))
	verts.append(Vector3(x0 + px, 0, z0 + pz))
	verts.append(Vector3(x1 - px, 0, z1 - pz))
	verts.append(Vector3(x0 - px, 0, z0 - pz))
