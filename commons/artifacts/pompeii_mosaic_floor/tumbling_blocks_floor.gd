# tumbling_blocks_floor.gd
# Procedural Pompeii mosaic floor — tumbling blocks (3D cube illusion).
# Builds border bands + rhombus field + grout lines in one ArrayMesh.
#
# @identity
#   essence: a floor that makes flat stone conjure three dimensions
#   desire: players look down and see depth emerge from three shades of marble
#   critical_parameter: cubes_short — number of cube columns on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the understanding that isometric projection predates computers by millennia
#   needs: [implemented] procedural mesh, border bands, hexagonal rhombus tiling
#   relationships: pompeii_mosaic_floor (sibling pattern), pattern_maker_station (web editor)
#   truth: three rhombuses and three values of grey fool the eye into seeing cubes

extends Node3D
class_name TumblingBlocksFloor

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var cubes_short: int = 6
@export var border_width: int = 2
@export var color_dark: Color = Color.html("#141418")
@export var color_medium: Color = Color.html("#8B8680")
@export var color_light: Color = Color.html("#EBE6D9")
@export var grout_color: Color = Color.html("#887860")
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.04

var _mi: MeshInstance3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	cubes_short = int(config.get("cubes_short", cubes_short))
	border_width = int(config.get("border_width", border_width))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()

	# ── Geometry constants ──
	# A tumbling-blocks cube is built from 3 rhombuses on a hexagonal grid.
	# Each rhombus is a 60-degree parallelogram.
	# We define one "cube" as having width = 2 * rx, height = 2 * ry
	# where rx = half-width, ry = half-height of a single rhombus.
	#
	# Hex layout: each cube occupies a column width of 2*rx.
	# Odd rows are offset by rx horizontally.
	# Vertically each row advances by 1.5 * ry (since top half of cube overlaps).

	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	# Rhombus dimensions: a single rhombus has width rx*2 and height ry*2.
	# A cube has total width = 2*rx, total height = 2*ry.
	# rx = cube_w / 2, ry = cube_h / 2
	# For 60-degree rhombuses: ry = rx * sqrt(3)
	# cube_w = 2*rx, cube_h = 2*ry = 2*rx*sqrt(3)
	# Rows advance by 1.5 * ry = 1.5 * rx * sqrt(3)

	# Allocate space: short axis has cubes_short cubes + border on each side
	# Each cube column is 2*rx wide.
	# Border is border_width * tile_size where tile_size ~ rx for simplicity.
	# Let's use a simpler approach: compute the rhombus size from the field area.

	# Field area on short axis: short_m - 2 * border_m
	# The short axis gets cubes_short cubes, each 2*rx wide.
	# So field_short = cubes_short * 2 * rx  => rx = field_short / (2 * cubes_short)

	# Border in meters: border_width tiles, each tile = 2*rx / 2 = rx? No.
	# Let's define: tile_unit = the width of one cube = 2*rx.
	# border_m = border_width * (tile_unit / 2)  [half-cube border tiles]
	# Actually, let's keep it simple like the original: border is border_width * ts
	# where ts is a basic tile unit.

	# Simpler: total short = cubes_short cubes + border margins
	# Let cube_w be the width of one cube column.
	# Total short = cubes_short * cube_w + 2 * border_width * (cube_w / 2)
	# = cube_w * (cubes_short + border_width)
	# cube_w = short_m / (cubes_short + border_width)

	var cube_w: float = short_m / float(cubes_short + border_width)
	var rx: float = cube_w * 0.5
	var ry: float = rx * sqrt(3.0)  # 60-degree rhombus height half

	var border_m: float = border_width * rx  # border thickness in meters

	# Field dimensions (inside border)
	var field_w: float
	var field_h: float
	if is_wide:
		field_w = long_m - 2.0 * border_m
		field_h = short_m - 2.0 * border_m
	else:
		field_w = short_m - 2.0 * border_m
		field_h = long_m - 2.0 * border_m

	# Total floor dimensions
	var fw: float = field_w + 2.0 * border_m
	var fh: float = field_h + 2.0 * border_m

	# Number of cube columns and rows to fill the field
	var cols: int = int(ceil(field_w / cube_w)) + 1
	var row_step: float = ry * 1.5  # vertical step between rows
	var rows: int = int(ceil(field_h / row_step)) + 1

	# Grout absolute width
	var grout_w: float = cube_w * grout_width_fraction

	# Vertex arrays: 4 surfaces — dark, medium, light, grout
	var dark_verts := PackedVector3Array()
	var med_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	# Helper: add a flat quad in XZ plane
	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	# Helper: add grout line between two points (clipped to field)
	var field_x0 := border_m
	var field_z0 := border_m
	var field_x1 := fw - border_m
	var field_z1 := fh - border_m

	# Helper: check if a point is inside the field region
	var _in_field := func(p: Vector3) -> bool:
		return p.x >= field_x0 - 0.001 and p.x <= field_x1 + 0.001 and p.z >= field_z0 - 0.001 and p.z <= field_z1 + 0.001

	# Helper: clamp a point to the field region
	var _clamp_pt := func(p: Vector3) -> Vector3:
		return Vector3(clampf(p.x, field_x0, field_x1), p.y, clampf(p.z, field_z0, field_z1))

	var _add_grout_line := func(a: Vector3, b: Vector3) -> void:
		# Clamp endpoints to field
		var ca: Vector3 = _clamp_pt.call(a)
		var cb: Vector3 = _clamp_pt.call(b)
		if ca.distance_to(cb) < 0.001:
			return
		var dir := (cb - ca).normalized()
		var perp := Vector3(-dir.z, 0, dir.x) * grout_w * 0.5
		grout_verts.append(ca + perp)
		grout_verts.append(cb + perp)
		grout_verts.append(cb - perp)
		grout_verts.append(ca + perp)
		grout_verts.append(cb - perp)
		grout_verts.append(ca - perp)

	# Helper: clip a rhombus (quad) to the field rectangle using Sutherland-Hodgman
	var _clip_poly_to_rect := func(points: Array) -> Array:
		# Clip polygon against 4 half-planes of the field rectangle
		var poly: Array = points.duplicate()
		# Each edge: [inside test lambda, intersect lambda]
		var edges := [
			[func(p: Vector3) -> bool: return p.x >= field_x0,
			 func(a: Vector3, b: Vector3) -> Vector3: var t := (field_x0 - a.x) / (b.x - a.x); return a + (b - a) * t],
			[func(p: Vector3) -> bool: return p.x <= field_x1,
			 func(a: Vector3, b: Vector3) -> Vector3: var t := (field_x1 - a.x) / (b.x - a.x); return a + (b - a) * t],
			[func(p: Vector3) -> bool: return p.z >= field_z0,
			 func(a: Vector3, b: Vector3) -> Vector3: var t := (field_z0 - a.z) / (b.z - a.z); return a + (b - a) * t],
			[func(p: Vector3) -> bool: return p.z <= field_z1,
			 func(a: Vector3, b: Vector3) -> Vector3: var t := (field_z1 - a.z) / (b.z - a.z); return a + (b - a) * t],
		]
		for edge in edges:
			if poly.size() == 0:
				break
			var inside_fn: Callable = edge[0]
			var intersect_fn: Callable = edge[1]
			var output: Array = []
			for i in poly.size():
				var cur: Vector3 = poly[i]
				var prev: Vector3 = poly[(i + poly.size() - 1) % poly.size()]
				var cur_in: bool = inside_fn.call(cur)
				var prev_in: bool = inside_fn.call(prev)
				if cur_in:
					if not prev_in:
						output.append(intersect_fn.call(prev, cur))
					output.append(cur)
				elif prev_in:
					output.append(intersect_fn.call(prev, cur))
			poly = output
		return poly

	# Helper: triangulate a convex polygon and add to verts
	var _add_clipped_poly := func(verts: PackedVector3Array, poly: Array) -> PackedVector3Array:
		if poly.size() < 3:
			return verts
		for i in range(1, poly.size() - 1):
			verts.append(poly[0])
			verts.append(poly[i])
			verts.append(poly[i + 1])
		return verts

	# ── 1. Border bands ──
	if border_width > 0:
		# Top band
		dark_verts = _add_rect.call(dark_verts, 0.0, 0.0, fw, border_m)
		# Bottom band
		dark_verts = _add_rect.call(dark_verts, 0.0, fh - border_m, fw, border_m)
		# Left band
		dark_verts = _add_rect.call(dark_verts, 0.0, border_m, border_m, fh - 2.0 * border_m)
		# Right band
		dark_verts = _add_rect.call(dark_verts, fw - border_m, border_m, border_m, fh - 2.0 * border_m)

	# ── 2. Tumbling blocks field ──
	# Each cube is centered at (cx, cz) and composed of 3 rhombuses:
	#   - TOP face (light): horizontal rhombus at the top
	#   - LEFT face (medium): lower-left rhombus
	#   - RIGHT face (dark): lower-right rhombus

	var hy := ry * 0.5  # half of ry

	for row in range(-1, rows + 1):
		var offset_x: float = rx if (row % 2 == 1) else 0.0
		for col in range(-1, cols + 1):
			var cx: float = border_m + col * cube_w + rx + offset_x
			var cz: float = border_m + row * row_step

			# Skip cubes entirely outside the field (with margin)
			if cx + rx < field_x0 - rx or cx - rx > field_x1 + rx:
				continue
			if cz + ry < field_z0 - ry or cz - ry > field_z1 + ry:
				continue

			# Six outer vertices + center of the hexagonal cube
			var p_top := Vector3(cx, 0, cz - ry)
			var p_tr := Vector3(cx + rx, 0, cz - hy)
			var p_br := Vector3(cx + rx, 0, cz + hy)
			var p_bot := Vector3(cx, 0, cz + ry)
			var p_bl := Vector3(cx - rx, 0, cz + hy)
			var p_tl := Vector3(cx - rx, 0, cz - hy)
			var p_ctr := Vector3(cx, 0, cz)

			# TOP face (light): p_top -> p_tr -> center -> p_tl
			var top_quad: Array = [p_top, p_tr, p_ctr, p_tl]
			var top_clipped: Array = _clip_poly_to_rect.call(top_quad)
			light_verts = _add_clipped_poly.call(light_verts, top_clipped)

			# LEFT face (medium): p_tl -> center -> p_bot -> p_bl
			var left_quad: Array = [p_tl, p_ctr, p_bot, p_bl]
			var left_clipped: Array = _clip_poly_to_rect.call(left_quad)
			med_verts = _add_clipped_poly.call(med_verts, left_clipped)

			# RIGHT face (dark): center -> p_tr -> p_br -> p_bot
			var right_quad: Array = [p_ctr, p_tr, p_br, p_bot]
			var right_clipped: Array = _clip_poly_to_rect.call(right_quad)
			dark_verts = _add_clipped_poly.call(dark_verts, right_clipped)

			# Grout lines along the 3 internal edges
			if grout_w > 0.001:
				_add_grout_line.call(p_ctr, p_top)
				_add_grout_line.call(p_ctr, p_bl)
				_add_grout_line.call(p_ctr, p_br)

	# ── Build ArrayMesh ──
	var arr_mesh := ArrayMesh.new()
	var surf_idx := 0

	if dark_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = dark_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color_dark
		mat.roughness = 0.85
		arr_mesh.surface_set_material(surf_idx, mat)
		surf_idx += 1

	if med_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = med_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color_medium
		mat.roughness = 0.80
		arr_mesh.surface_set_material(surf_idx, mat)
		surf_idx += 1

	if light_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = light_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color_light
		mat.roughness = 0.75
		arr_mesh.surface_set_material(surf_idx, mat)
		surf_idx += 1

	if grout_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = grout_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = grout_color
		mat.roughness = 0.9
		arr_mesh.surface_set_material(surf_idx, mat)
		surf_idx += 1

	_mi = MeshInstance3D.new()
	_mi.mesh = arr_mesh
	_mi.position = Vector3(-fw * 0.5, 0.005, -fh * 0.5)
	add_child(_mi)

	print("[TumblingBlocksFloor] Built %d cols x %d rows (%d dark, %d med, %d light, %d grout tris)" % [
		cols, rows,
		dark_verts.size() / 3,
		med_verts.size() / 3,
		light_verts.size() / 3,
		grout_verts.size() / 3,
	])
