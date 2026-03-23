# octagon_square_floor.gd
# Procedural Pompeii mosaic floor — octagon-and-square pattern with terracotta centers.
# Builds border quads + octagon/square tiling + grout lines in one ArrayMesh.
#
# @identity
#   essence: a floor reproducing the octagon-and-square tessellation found in Roman houses
#   desire: players see how octagons and squares tile the plane with no gaps
#   critical_parameter: tiles_short — number of octagon rows on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: recognition that regular and semi-regular tilings have ancient roots
#   needs: [implemented] procedural mesh, border bands, octagon field, terracotta diamonds
#   relationships: pompeii_mosaic_floor (sibling pattern), pattern_maker_station (web editor)
#   truth: the truncated square tiling is one of only eight semi-regular tessellations

extends Node3D
class_name OctagonSquareFloor

@export var floor_size: Vector2 = Vector2(1.0, 0.8)
@export var tiles_short: int = 5
@export var color_dark: Color = Color.html("#141418")
@export var color_light: Color = Color.html("#EBE6D9")
@export var color_terracotta: Color = Color.html("#B8603C")
@export var grout_color: Color = Color.html("#887860")
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.04

var _mi: MeshInstance3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	tiles_short = int(config.get("tiles_short", tiles_short))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()

	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var terra_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	# Border = 2 cell-widths on each side (1 dark outer, 1 checker)
	var border_cells := 2
	var total_short := tiles_short + border_cells * 2
	var pitch := short_m / float(total_short)
	var total_long := int(round(long_m / pitch))

	var gw: int = total_long if is_wide else total_short
	var gh: int = total_short if is_wide else total_long
	var fw := gw * pitch
	var fh := gh * pitch

	# Octagon geometry
	var sqrt2 := sqrt(2.0)
	var oct_side := pitch / (1.0 + sqrt2)
	var cut := oct_side / sqrt2

	var grout_w := pitch * grout_width_fraction
	var half_grout := grout_w * 0.5

	# Field region (inside border)
	var fx0 := border_cells
	var fy0 := border_cells
	var fx1 := gw - border_cells
	var fy1 := gh - border_cells

	# ── Helpers ──
	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	var _add_polygon := func(verts: PackedVector3Array, points: Array) -> PackedVector3Array:
		for i in range(1, points.size() - 1):
			verts.append(points[0])
			verts.append(points[i])
			verts.append(points[i + 1])
		return verts

	var _add_diamond := func(verts: PackedVector3Array, cx: float, cz: float, r: float, y_off: float) -> PackedVector3Array:
		verts.append(Vector3(cx, y_off, cz - r))
		verts.append(Vector3(cx + r, y_off, cz))
		verts.append(Vector3(cx, y_off, cz + r))
		verts.append(Vector3(cx, y_off, cz - r))
		verts.append(Vector3(cx, y_off, cz + r))
		verts.append(Vector3(cx - r, y_off, cz))
		return verts

	# ── 1. Border ──
	# Layer 0: outer dark band (1 cell wide)
	# Top
	dark_verts = _add_rect.call(dark_verts, 0.0, 0.0, fw, pitch)
	# Bottom
	dark_verts = _add_rect.call(dark_verts, 0.0, fh - pitch, fw, pitch)
	# Left
	dark_verts = _add_rect.call(dark_verts, 0.0, pitch, pitch, fh - pitch * 2)
	# Right
	dark_verts = _add_rect.call(dark_verts, fw - pitch, pitch, pitch, fh - pitch * 2)

	# Layer 1: checker band (1 cell wide) — 2x2 checkerboard within each cell
	var cs := pitch * 0.5  # each checker square is half a cell

	# Top checker band (full width between outer dark corners)
	var num_h := int(round((fw - pitch * 2) / cs))
	for row in range(2):
		for i in range(num_h):
			var x := pitch + i * cs
			var z := pitch + row * cs
			var is_dark_sq := ((i + row) % 2 == 0)
			if is_dark_sq:
				dark_verts = _add_rect.call(dark_verts, x, z, cs, cs)
			else:
				light_verts = _add_rect.call(light_verts, x, z, cs, cs)

	# Bottom checker band
	for row in range(2):
		for i in range(num_h):
			var x := pitch + i * cs
			var z := fh - pitch * 2 + row * cs
			var is_dark_sq := ((i + row) % 2 == 0)
			if is_dark_sq:
				dark_verts = _add_rect.call(dark_verts, x, z, cs, cs)
			else:
				light_verts = _add_rect.call(light_verts, x, z, cs, cs)

	# Left checker band (between top and bottom bands)
	var num_v := int(round((fh - pitch * 4) / cs))
	for col in range(2):
		for i in range(num_v):
			var x := pitch + col * cs
			var z := pitch * 2 + i * cs
			var is_dark_sq := ((i + col) % 2 == 0)
			if is_dark_sq:
				dark_verts = _add_rect.call(dark_verts, x, z, cs, cs)
			else:
				light_verts = _add_rect.call(light_verts, x, z, cs, cs)

	# Right checker band
	for col in range(2):
		for i in range(num_v):
			var x := fw - pitch * 2 + col * cs
			var z := pitch * 2 + i * cs
			var is_dark_sq := ((i + col) % 2 == 0)
			if is_dark_sq:
				dark_verts = _add_rect.call(dark_verts, x, z, cs, cs)
			else:
				light_verts = _add_rect.call(light_verts, x, z, cs, cs)

	# ── 2. Octagon-and-square field ──
	var margin := half_grout

	for ty in range(fy0, fy1):
		for tx in range(fx0, fx1):
			var ox := tx * pitch
			var oz := ty * pitch

			# 8 vertices of the octagon (inset by margin for grout gap)
			var p0 := Vector3(ox + cut + margin, 0, oz + margin)
			var p1 := Vector3(ox + pitch - cut - margin, 0, oz + margin)
			var p2 := Vector3(ox + pitch - margin, 0, oz + cut + margin)
			var p3 := Vector3(ox + pitch - margin, 0, oz + pitch - cut - margin)
			var p4 := Vector3(ox + pitch - cut - margin, 0, oz + pitch - margin)
			var p5 := Vector3(ox + cut + margin, 0, oz + pitch - margin)
			var p6 := Vector3(ox + margin, 0, oz + pitch - cut - margin)
			var p7 := Vector3(ox + margin, 0, oz + cut + margin)

			light_verts = _add_polygon.call(light_verts, [p0, p1, p2, p3, p4, p5, p6, p7])

			# Terracotta diamond in center
			var cx := ox + pitch * 0.5
			var cz := oz + pitch * 0.5
			# Diamond half-diagonal: make it proportional to the octagon interior
			var diamond_r := oct_side * 0.45
			terra_verts = _add_diamond.call(terra_verts, cx, cz, diamond_r, 0.0001)

	# Small dark squares at grid intersections (between 4 octagons)
	for ty in range(fy0 + 1, fy1):
		for tx in range(fx0 + 1, fx1):
			var ix := tx * pitch
			var iz := ty * pitch
			var sq_half := cut - margin
			dark_verts = _add_diamond.call(dark_verts, ix, iz, sq_half, 0.0)

	# ── 3. Grout lines ──
	if grout_w > 0.001:
		# Horizontal grout lines across the field
		for gy in range(fy0, fy1 + 1):
			var gz := gy * pitch
			grout_verts = _add_rect.call(grout_verts, fx0 * pitch, gz - half_grout, (fx1 - fx0) * pitch, grout_w)

		# Vertical grout lines
		for gx in range(fx0, fx1 + 1):
			var gxp := gx * pitch
			grout_verts = _add_rect.call(grout_verts, gxp - half_grout, fy0 * pitch, grout_w, (fy1 - fy0) * pitch)

		# Diagonal grout at each octagon corner (the 45-degree cuts)
		var dh := half_grout * 0.7071  # perpendicular offset for 45-degree line
		for ty in range(fy0, fy1):
			for tx in range(fx0, fx1):
				var ox := tx * pitch
				var oz := ty * pitch

				# Top-left: from (ox, oz+cut) to (ox+cut, oz)
				grout_verts.append(Vector3(ox + dh, 0, oz + cut + dh))
				grout_verts.append(Vector3(ox + cut + dh, 0, oz + dh))
				grout_verts.append(Vector3(ox + cut - dh, 0, oz - dh))
				grout_verts.append(Vector3(ox + dh, 0, oz + cut + dh))
				grout_verts.append(Vector3(ox + cut - dh, 0, oz - dh))
				grout_verts.append(Vector3(ox - dh, 0, oz + cut - dh))

				# Top-right: from (ox+pitch-cut, oz) to (ox+pitch, oz+cut)
				grout_verts.append(Vector3(ox + pitch - cut - dh, 0, oz - dh))
				grout_verts.append(Vector3(ox + pitch - dh, 0, oz + cut - dh))
				grout_verts.append(Vector3(ox + pitch + dh, 0, oz + cut + dh))
				grout_verts.append(Vector3(ox + pitch - cut - dh, 0, oz - dh))
				grout_verts.append(Vector3(ox + pitch + dh, 0, oz + cut + dh))
				grout_verts.append(Vector3(ox + pitch - cut + dh, 0, oz + dh))

				# Bottom-right: from (ox+pitch, oz+pitch-cut) to (ox+pitch-cut, oz+pitch)
				grout_verts.append(Vector3(ox + pitch + dh, 0, oz + pitch - cut - dh))
				grout_verts.append(Vector3(ox + pitch - cut + dh, 0, oz + pitch - dh))
				grout_verts.append(Vector3(ox + pitch - cut - dh, 0, oz + pitch + dh))
				grout_verts.append(Vector3(ox + pitch + dh, 0, oz + pitch - cut - dh))
				grout_verts.append(Vector3(ox + pitch - cut - dh, 0, oz + pitch + dh))
				grout_verts.append(Vector3(ox + pitch - dh, 0, oz + pitch - cut + dh))

				# Bottom-left: from (ox+cut, oz+pitch) to (ox, oz+pitch-cut)
				grout_verts.append(Vector3(ox + cut + dh, 0, oz + pitch + dh))
				grout_verts.append(Vector3(ox + dh, 0, oz + pitch - cut + dh))
				grout_verts.append(Vector3(ox - dh, 0, oz + pitch - cut - dh))
				grout_verts.append(Vector3(ox + cut + dh, 0, oz + pitch + dh))
				grout_verts.append(Vector3(ox - dh, 0, oz + pitch - cut - dh))
				grout_verts.append(Vector3(ox + cut - dh, 0, oz + pitch - dh))

	# ── Build ArrayMesh ──
	var arr_mesh := ArrayMesh.new()
	var surface_idx := 0

	if dark_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = dark_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color_dark
		mat.roughness = 0.85
		arr_mesh.surface_set_material(surface_idx, mat)
		surface_idx += 1

	if light_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = light_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color_light
		mat.roughness = 0.75
		arr_mesh.surface_set_material(surface_idx, mat)
		surface_idx += 1

	if terra_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = terra_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color_terracotta
		mat.roughness = 0.8
		arr_mesh.surface_set_material(surface_idx, mat)
		surface_idx += 1

	if grout_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = grout_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = grout_color
		mat.roughness = 0.9
		arr_mesh.surface_set_material(surface_idx, mat)
		surface_idx += 1

	_mi = MeshInstance3D.new()
	_mi.mesh = arr_mesh
	_mi.position = Vector3(-fw * 0.5, 0.005, -fh * 0.5)
	add_child(_mi)

	print("[OctagonSquareFloor] Built %dx%d grid, pitch=%.4f, oct_side=%.4f (%d dark, %d light, %d terra, %d grout tris)" % [
		gw, gh, pitch, oct_side,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		terra_verts.size() / 3,
		grout_verts.size() / 3,
	])
