# chain_link_floor.gd
# Procedural Pompeii mosaic floor — interlocking circles / chain link pattern.
# Overlapping circles on a regular grid where each circle passes through
# the center of its neighbors, creating a continuous chain. Classic Roman
# guilloche derivative. The overlapping vesica piscis areas get terracotta fill.
#
# @identity
#   essence: a floor carrying the geometry of Roman interlocking circles
#   desire: players look down and see chain links — the earliest topology
#   critical_parameter: tiles_short — number of circle rows on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: recognition that overlapping circles create vesica piscis lenses
#   needs: [implemented] procedural mesh, border bands, circle grid with overlap
#   relationships: flower_of_life_floor (sibling), pompeii_mosaic_floor (parent pattern)
#   truth: interlocking circles decorated Roman floors from the Republic onward

extends Node3D
class_name ChainLinkFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")
const BorderMotifs = preload("res://commons/artifacts/pompeii_mosaic_floor/border_motifs.gd")

@export var floor_size: Vector2 = Vector2(1.2, 1.0)
@export var tiles_short: int = 6
@export var border_widths: Array[int] = [2, 1, 2]
@export var border_motif: int = BorderMotifs.Motif.GUILLOCHE
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var color_terracotta: Color = MosaicPalette.TERRACOTTA
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.04
@export_range(0.0, 1.0) var wear_level: float = 0.3
@export var circle_segments: int = 48

var _mi: MeshInstance3D
#var _body: StaticBody3D


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
	#if _body:
		#_body.queue_free()

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

	# Chain link grid: circles on a regular square grid
	# radius = grid_spacing * 0.6 so circles overlap significantly
	var grid_spacing := pitch  # one grid cell per pitch unit
	var radius := grid_spacing * 0.6

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

	# ── 1. Light background fill for the field area ──
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

	# ── 3. Vesica piscis fills (terracotta) ──
	# For every pair of adjacent circles whose overlap region (vesica piscis)
	# falls inside the field, fill it with terracotta triangles.
	# Adjacent pairs: horizontal neighbors and vertical neighbors.

	var field_cx := (field_x0 + field_x1) * 0.5
	var field_cz := (field_z0 + field_z1) * 0.5

	# Determine circle grid coverage (extend beyond field to catch edge circles)
	var margin := radius + grid_spacing
	var col_min := int(floor((field_x0 - margin - field_cx) / grid_spacing)) - 1
	var col_max := int(ceil((field_x1 + margin - field_cx) / grid_spacing)) + 1
	var row_min := int(floor((field_z0 - margin - field_cz) / grid_spacing)) - 1
	var row_max := int(ceil((field_z1 + margin - field_cz) / grid_spacing)) + 1

	# Collect circle centers as a grid lookup
	var centers := {}  # key: "col_row" -> Vector2
	for row in range(row_min, row_max + 1):
		for col in range(col_min, col_max + 1):
			var cx := field_cx + col * grid_spacing
			var cz := field_cz + row * grid_spacing
			centers["%d_%d" % [col, row]] = Vector2(cx, cz)

	# Fill vesica piscis between adjacent pairs
	var vesica_segs := 24  # segments per vesica arc
	var neighbor_offsets := [[1, 0], [0, 1]]  # right and down only (avoid doubles)

	for row in range(row_min, row_max + 1):
		for col in range(col_min, col_max + 1):
			var key0 := "%d_%d" % [col, row]
			if not centers.has(key0):
				continue
			var c0: Vector2 = centers[key0]

			for ni in neighbor_offsets.size():
				var nc: int = col + neighbor_offsets[ni][0]
				var nr: int = row + neighbor_offsets[ni][1]
				var key1 := "%d_%d" % [nc, nr]
				if not centers.has(key1):
					continue
				var c1: Vector2 = centers[key1]

				# Distance between centers
				var dist := c0.distance_to(c1)
				if dist >= radius * 2.0:
					continue  # no overlap

				# Vesica piscis: the lens-shaped intersection of two circles
				# The two intersection points and arcs between them
				var half_d := dist * 0.5
				var h := sqrt(radius * radius - half_d * half_d)  # half-height of vesica

				# Midpoint and direction
				var mx := (c0.x + c1.x) * 0.5
				var mz := (c0.y + c1.y) * 0.5

				# Skip if midpoint is outside field
				if mx < field_x0 - radius * 0.3 or mx > field_x1 + radius * 0.3:
					continue
				if mz < field_z0 - radius * 0.3 or mz > field_z1 + radius * 0.3:
					continue

				# Direction from c0 to c1
				var dx := (c1.x - c0.x) / dist
				var dz := (c1.y - c0.y) / dist
				# Perpendicular
				var px := -dz
				var pz := dx

				# Two intersection points
				var ix0 := Vector2(mx + px * h, mz + pz * h)
				var ix1 := Vector2(mx - px * h, mz - pz * h)

				# Fill the vesica piscis as a fan of triangles from the midpoint
				# Arc from c0: from ix0 to ix1 going around the side near c1
				# Arc from c1: from ix1 to ix0 going around the side near c0
				# Simplified: fill as a lens using triangles from midpoint to arc points

				# Angle subtended at c0 by the two intersection points
				var angle_c0_start := atan2(ix0.y - c0.y, ix0.x - c0.x)
				var angle_c0_end := atan2(ix1.y - c0.y, ix1.x - c0.x)

				# Make sure we go the short way around (the arc facing c1)
				var angle_c0_diff := angle_c0_end - angle_c0_start
				if angle_c0_diff > PI:
					angle_c0_diff -= TAU
				elif angle_c0_diff < -PI:
					angle_c0_diff += TAU

				# Arc from c0 (the side closer to c1)
				var arc_step := angle_c0_diff / float(vesica_segs)
				for s in vesica_segs:
					var a0 := angle_c0_start + s * arc_step
					var a1 := angle_c0_start + (s + 1) * arc_step
					var p0 := Vector3(c0.x + cos(a0) * radius, 0.0008, c0.y + sin(a0) * radius)
					var p1 := Vector3(c0.x + cos(a1) * radius, 0.0008, c0.y + sin(a1) * radius)
					var center_pt := Vector3(mx, 0.0008, mz)
					# Clip: skip tris whose centroid is outside field
					var tri_cx := (p0.x + p1.x + center_pt.x) / 3.0
					var tri_cz := (p0.z + p1.z + center_pt.z) / 3.0
					if tri_cx >= field_x0 and tri_cx <= field_x1 and tri_cz >= field_z0 and tri_cz <= field_z1:
						_add_tri.call(terra_verts, center_pt, p0, p1)

				# Arc from c1 (the side closer to c0)
				var angle_c1_start := atan2(ix1.y - c1.y, ix1.x - c1.x)
				var angle_c1_end := atan2(ix0.y - c1.y, ix0.x - c1.x)

				var angle_c1_diff := angle_c1_end - angle_c1_start
				if angle_c1_diff > PI:
					angle_c1_diff -= TAU
				elif angle_c1_diff < -PI:
					angle_c1_diff += TAU

				arc_step = angle_c1_diff / float(vesica_segs)
				for s in vesica_segs:
					var a0 := angle_c1_start + s * arc_step
					var a1 := angle_c1_start + (s + 1) * arc_step
					var p0 := Vector3(c1.x + cos(a0) * radius, 0.0008, c1.y + sin(a0) * radius)
					var p1 := Vector3(c1.x + cos(a1) * radius, 0.0008, c1.y + sin(a1) * radius)
					var center_pt := Vector3(mx, 0.0008, mz)
					var tri_cx := (p0.x + p1.x + center_pt.x) / 3.0
					var tri_cz := (p0.z + p1.z + center_pt.z) / 3.0
					if tri_cx >= field_x0 and tri_cx <= field_x1 and tri_cz >= field_z0 and tri_cz <= field_z1:
						_add_tri.call(terra_verts, center_pt, p0, p1)

	# ── 4. Circle outlines (dark bands) ──
	var line_w := pitch * 0.05  # circle outline thickness
	var half_lw := line_w * 0.5
	var seg := circle_segments
	var angle_step := TAU / float(seg)

	for row in range(row_min, row_max + 1):
		for col in range(col_min, col_max + 1):
			var key := "%d_%d" % [col, row]
			if not centers.has(key):
				continue
			var c: Vector2 = centers[key]
			var cx := c.x
			var cz := c.y

			# Skip circles entirely outside the field with margin
			if cx + radius < field_x0 - line_w or cx - radius > field_x1 + line_w:
				continue
			if cz + radius < field_z0 - line_w or cz - radius > field_z1 + line_w:
				continue

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

	# ── 5. Grout grid lines ──
	if grout_w > 0.001:
		var half := grout_w * 0.5
		for gy in range(0, gh + 1):
			var gz := gy * pitch
			grout_verts = _add_rect.call(grout_verts, 0.0, gz - half, fw, grout_w)
		for gx in range(0, gw + 1):
			var gxp := gx * pitch
			grout_verts = _add_rect.call(grout_verts, gxp - half, 0.0, grout_w, fh)


	# ── Z-fighting fix: offset each surface to a distinct Y layer ──
	# Hierarchy: grout(-0.001) < dark(0.0) < light(0.001) < accent/terra(0.002) < border(0.003)
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts
	dark_verts = _offset_y.call(dark_verts, 0.0)
	light_verts = _offset_y.call(light_verts, 0.001)
	terra_verts = _offset_y.call(terra_verts, 0.002)
	grout_verts = _offset_y.call(grout_verts, -0.001)
	border_terra_verts = _offset_y.call(border_terra_verts, 0.003)

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
	#_body = StaticBody3D.new()
	var col_shape := CollisionShape3D.new()
	#var box := BoxShape3D.new()
	#box.size = Vector3(fw, 0.01, fh)
	col_shape.shape = box
	#_body.add_child(col_shape)
	#_body.position = Vector3(0, 0.0, 0)
	#add_child(_body)

	var n_circles := (row_max - row_min + 1) * (col_max - col_min + 1)
	print("[ChainLinkFloor] Built %dx%d grid, %d circles (%d dark, %d light, %d terra, %d grout tris)" % [
		gw, gh, n_circles,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		terra_verts.size() / 3,
		grout_verts.size() / 3,
	])
