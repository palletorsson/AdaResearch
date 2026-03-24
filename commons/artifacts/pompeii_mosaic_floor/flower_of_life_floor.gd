# flower_of_life_floor.gd
# Procedural Pompeii mosaic floor — Flower of Life sacred geometry pattern.
# Overlapping circles on a hexagonal grid create petal shapes at intersections.
# Dark circle outlines on light background with terracotta accent petals.
#
# @identity
#   essence: a floor carrying the sacred geometry of overlapping circles
#   desire: players look down and see the Flower of Life — geometry older than writing
#   critical_parameter: tiles_short — number of circle rows on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: recognition that overlapping circles generate all regular polygons
#   needs: [implemented] procedural mesh, border bands, hexagonal circle grid
#   relationships: pompeii_mosaic_floor (sibling pattern), pattern_maker_station (web editor)
#   truth: the Flower of Life appears in temples from Abydos to da Vinci's notebooks

extends Node3D
class_name FlowerOfLifeFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")
const BorderMotifs = preload("res://commons/artifacts/pompeii_mosaic_floor/border_motifs.gd")

@export var floor_size: Vector2 = Vector2(1.2, 1.0)
@export var tiles_short: int = 6
@export var border_widths: Array[int] = [2, 1, 2]
@export var border_motif: int = BorderMotifs.Motif.SAWTOOTH
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var color_terracotta: Color = MosaicPalette.TERRACOTTA
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.04
@export_range(0.0, 1.0) var wear_level: float = 0.3
@export var circle_segments: int = 36

var _mi: MeshInstance3D
var _body: StaticBody3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	tiles_short = int(config.get("tiles_short", tiles_short))
	wear_level = float(config.get("wear_level", wear_level))
	var bw = config.get("border_widths", null)
	if bw is Array:
		border_widths.clear()
		for v in bw:
			border_widths.append(int(v))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()
	if _body:
		_body.queue_free()

	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var terra_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	# Border width from border_widths array
	var border_cells: int = 0
	for bw in border_widths:
		border_cells += bw

	var total_short := tiles_short + border_cells * 2
	var pitch := short_m / float(total_short)
	var total_long := int(round(long_m / pitch))

	var gw: int = total_long if is_wide else total_short
	var gh: int = total_short if is_wide else total_long
	var fw := gw * pitch
	var fh := gh * pitch

	var grout_w := pitch * grout_width_fraction

	# Field region (inside border)
	var fx0 := border_cells
	var fy0 := border_cells
	var fx1 := gw - border_cells
	var fy1 := gh - border_cells

	# Field dimensions in world coords
	var field_x0 := fx0 * pitch
	var field_z0 := fy0 * pitch
	var field_x1 := fx1 * pitch
	var field_z1 := fy1 * pitch

	# Circle radius = pitch (characteristic of Flower of Life)
	var radius := pitch

	# Hex grid spacing
	var hex_dx := pitch
	var hex_dz := pitch * sqrt(3.0) * 0.5

	# ── Helpers ──
	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	var _add_tri := func(verts: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> void:
		verts.append(a)
		verts.append(b)
		verts.append(c)

	# ── 1. Light background fill for the field area only ──
	light_verts = _add_rect.call(light_verts, field_x0, field_z0, field_x1 - field_x0, field_z1 - field_z0)

	# ── 2. Border bands ──
	var border_terra_verts := PackedVector3Array()
	var inset: int = 0
	for i in border_widths.size():
		var bw_val: int = border_widths[i]
		var result := BorderMotifs.draw_border_frame(
			dark_verts, light_verts, border_terra_verts,
			inset * pitch, inset * pitch,
			(gw - inset * 2) * pitch, (gh - inset * 2) * pitch,
			bw_val * pitch, pitch,
			border_motif, i % 2 == 1
		)
		dark_verts = result["dark"]
		light_verts = result["light"]
		border_terra_verts = result["terra"]
		inset += bw_val

	if border_terra_verts.size() > 0:
		terra_verts.append_array(border_terra_verts)

	# ── 3. Flower of Life circle outlines (dark lines on light background) ──
	var line_w := pitch * 0.045  # circle line thickness
	var half_lw := line_w * 0.5

	# Determine hex grid centers
	var margin_c := radius + line_w
	var field_cx := (field_x0 + field_x1) * 0.5
	var field_cz := (field_z0 + field_z1) * 0.5

	var cols_needed := int(ceil((field_x1 - field_x0 + margin_c * 2) / hex_dx)) + 2
	var rows_needed := int(ceil((field_z1 - field_z0 + margin_c * 2) / hex_dz)) + 2

	var start_col := -cols_needed / 2
	var end_col := cols_needed / 2
	var start_row := -rows_needed / 2
	var end_row := rows_needed / 2

	# Collect circle centers
	var centers := PackedVector2Array()
	for row in range(start_row, end_row + 1):
		for col in range(start_col, end_col + 1):
			var cx := field_cx + col * hex_dx + (0.5 * hex_dx if row % 2 != 0 else 0.0)
			var cz := field_cz + row * hex_dz
			if cx + radius >= field_x0 - line_w and cx - radius <= field_x1 + line_w:
				if cz + radius >= field_z0 - line_w and cz - radius <= field_z1 + line_w:
					centers.append(Vector2(cx, cz))

	# Draw circle outlines as quads, clipped to field
	var seg := circle_segments
	var angle_step := TAU / float(seg)

	for ci in centers.size():
		var cx := centers[ci].x
		var cz := centers[ci].y
		for s in seg:
			var a0 := s * angle_step
			var a1 := (s + 1) * angle_step

			var x0 := cx + cos(a0) * radius
			var z0 := cz + sin(a0) * radius
			var x1 := cx + cos(a1) * radius
			var z1 := cz + sin(a1) * radius

			# Skip segments entirely outside the field
			if maxf(x0, x1) < field_x0:
				continue
			if minf(x0, x1) > field_x1:
				continue
			if maxf(z0, z1) < field_z0:
				continue
			if minf(z0, z1) > field_z1:
				continue

			# Outward normal for width
			var nx0 := cos(a0)
			var nz0 := sin(a0)
			var nx1 := cos(a1)
			var nz1 := sin(a1)

			var inner0 := Vector3(x0 - nx0 * half_lw, 0.001, z0 - nz0 * half_lw)
			var outer0 := Vector3(x0 + nx0 * half_lw, 0.001, z0 + nz0 * half_lw)
			var inner1 := Vector3(x1 - nx1 * half_lw, 0.001, z1 - nz1 * half_lw)
			var outer1 := Vector3(x1 + nx1 * half_lw, 0.001, z1 + nz1 * half_lw)

			_add_tri.call(dark_verts, inner0, outer0, outer1)
			_add_tri.call(dark_verts, inner0, outer1, inner1)

	# ── 4. Terracotta accent petals ──
	# Small diamond/petal marks at select lens intersections between circles.
	# Rather than filling the entire vesica piscis, place small terracotta diamonds.

	var center_set := {}
	for ci in centers.size():
		var key := "%d_%d" % [int(round(centers[ci].x * 1000)), int(round(centers[ci].y * 1000))]
		center_set[key] = ci

	var _add_diamond := func(verts: PackedVector3Array, cx_d: float, cz_d: float, half_w: float, half_h: float, y_off: float) -> void:
		# Diamond shape: 4 triangles from center
		verts.append(Vector3(cx_d, y_off, cz_d - half_h))
		verts.append(Vector3(cx_d + half_w, y_off, cz_d))
		verts.append(Vector3(cx_d, y_off, cz_d + half_h))
		verts.append(Vector3(cx_d, y_off, cz_d - half_h))
		verts.append(Vector3(cx_d, y_off, cz_d + half_h))
		verts.append(Vector3(cx_d - half_w, y_off, cz_d))

	# Place small terracotta diamonds at the midpoints between adjacent circle pairs
	# Use a spatial hash check to find actual neighbors
	var petal_counter := 0
	for ci in centers.size():
		var c0 := centers[ci]
		var neighbor_offsets := [
			Vector2(hex_dx, 0),
			Vector2(hex_dx * 0.5, -hex_dz),
			Vector2(hex_dx * 0.5, hex_dz),
		]
		for ni in neighbor_offsets.size():
			var offset: Vector2 = neighbor_offsets[ni]
			var c1_approx := Vector2(c0.x + offset.x, c0.y + offset.y)
			var key := "%d_%d" % [int(round(c1_approx.x * 1000)), int(round(c1_approx.y * 1000))]
			if center_set.has(key):
				# Midpoint between the two centers
				var c1 := centers[center_set[key]]
				var mx := (c0.x + c1.x) * 0.5
				var mz := (c0.y + c1.y) * 0.5

				# Only place if midpoint is within the field
				if mx < field_x0 or mx > field_x1 or mz < field_z0 or mz > field_z1:
					petal_counter += 1
					continue

				# Alternate: fill every other petal in each direction
				if petal_counter % 2 == 0:
					var diamond_size := pitch * 0.15
					_add_diamond.call(terra_verts, mx, mz, diamond_size, diamond_size, 0.0015)

				petal_counter += 1

	# ── 5. Small figurative elements ──
	# Place tiny terracotta marks at the centers of hexagonal cells
	# (where 3 circles overlap to form the characteristic 6-petal rosette)
	# These represent the small figurative elements (birds, dolphins) from the reference
	for ci in centers.size():
		var cx := centers[ci].x
		var cz := centers[ci].y
		# Only if center is within the field
		if cx >= field_x0 and cx <= field_x1 and cz >= field_z0 and cz <= field_z1:
			# Small dot at each circle center
			var dot_r := pitch * 0.06
			var dot_segs := 6
			for ds in dot_segs:
				var da0 := ds * TAU / float(dot_segs)
				var da1 := (ds + 1) * TAU / float(dot_segs)
				_add_tri.call(terra_verts,
					Vector3(cx, 0.0012, cz),
					Vector3(cx + cos(da0) * dot_r, 0.0012, cz + sin(da0) * dot_r),
					Vector3(cx + cos(da1) * dot_r, 0.0012, cz + sin(da1) * dot_r))

	# ── 6. Grout grid lines ──
	if grout_w > 0.001:
		var half := grout_w * 0.5
		for gy in range(0, gh + 1):
			var gz := gy * pitch
			grout_verts = _add_rect.call(grout_verts, 0.0, gz - half, fw, grout_w)
		for gx in range(0, gw + 1):
			var gxp := gx * pitch
			grout_verts = _add_rect.call(grout_verts, gxp - half, 0.0, grout_w, fh)

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

	if terra_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = terra_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(color_terracotta, wear_level))

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

	# ── StaticBody3D for collision ──
	_body = StaticBody3D.new()
	var col_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(fw, 0.01, fh)
	col_shape.shape = box
	_body.add_child(col_shape)
	_body.position = Vector3(0, 0.0, 0)
	add_child(_body)

	print("[FlowerOfLifeFloor] Built %dx%d grid, %d circles, %d petals (%d dark, %d light, %d terra, %d grout tris)" % [
		gw, gh, centers.size(), petal_counter,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		terra_verts.size() / 3,
		grout_verts.size() / 3,
	])
