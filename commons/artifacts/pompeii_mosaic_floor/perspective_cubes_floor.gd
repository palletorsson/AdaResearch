# perspective_cubes_floor.gd
# Procedural Pompeii mosaic floor — perspective cubes (3D cube illusion).
# Regular rectangular grid of cubes, each drawn as 3 rhombuses (top, left, right).
# Stronger 3D effect than tumbling blocks due to regular grid alignment.
#
# @identity
#   essence: a floor of stacked cubes that trick the eye with three flat shades
#   desire: players look down and perceive depth in a perfectly flat surface
#   critical_parameter: cubes_short — number of cube columns on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the realization that regular grids amplify the isometric illusion
#   needs: [implemented] procedural mesh, border bands, rectangular rhombus tiling
#   relationships: tumbling_blocks_floor (sibling — hex offset), pompeii_mosaic_floor (family)
#   truth: alignment in a grid makes each cube reinforce its neighbours' illusion

extends Node3D
class_name PerspectiveCubesFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")
const BorderMotifs = preload("res://commons/artifacts/pompeii_mosaic_floor/border_motifs.gd")

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var cubes_short: int = 6
@export var border_width: int = 2
@export var border_motif: int = BorderMotifs.Motif.SOLID
@export var color_dark: Color = MosaicPalette.DARK
@export var color_medium: Color = MosaicPalette.MEDIUM
@export var color_light: Color = MosaicPalette.LIGHT
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.04
@export_range(0.0, 1.0) var wear_level: float = 0.3

var _mi: MeshInstance3D
#var _body: StaticBody3D


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
	#if _body:
		#_body.queue_free()

	# ── Geometry constants ──
	# Each perspective cube occupies a rectangular 2-cell area.
	# A cube is built from 3 rhombuses in isometric projection:
	#   - TOP face (light): diamond on top
	#   - LEFT face (medium): parallelogram lower-left
	#   - RIGHT face (dark): parallelogram lower-right
	#
	# Unlike tumbling_blocks which uses hex offset rows, this pattern
	# arranges cubes in a strict rectangular grid — every cube lines up
	# with its neighbours, creating a stronger sense of regular 3D stacking.
	#
	# Cube geometry (isometric):
	#   cube_w = 2 * rx  (width of one cube)
	#   cube_h = 2 * ry  (total height of one cube)
	#   ry = rx * sqrt(3) for 60-degree rhombuses

	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	# Cube sizing: short axis = cubes_short cubes + border margins
	# cube_w = short_m / (cubes_short + border_width)
	var cube_w: float = short_m / float(cubes_short + border_width)
	var rx: float = cube_w * 0.5
	var ry: float = rx * sqrt(3.0)

	var border_m: float = border_width * rx

	# Field dimensions (inside border)
	var field_w: float
	var field_h: float
	if is_wide:
		field_w = long_m - 2.0 * border_m
		field_h = short_m - 2.0 * border_m
	else:
		field_w = short_m - 2.0 * border_m
		field_h = long_m - 2.0 * border_m

	var fw: float = field_w + 2.0 * border_m
	var fh: float = field_h + 2.0 * border_m

	# Regular grid: columns spaced by cube_w, rows spaced by 2*ry (full cube height)
	# No hex offset — cubes stack directly on top of each other.
	var cols: int = int(ceil(field_w / cube_w)) + 1
	var row_step: float = ry  # each row advances by ry (half the cube height)
	var rows: int = int(ceil(field_h / row_step)) + 1

	var grout_w: float = cube_w * grout_width_fraction

	# Vertex arrays: 4 surfaces — dark, medium, light, grout
	var dark_verts := PackedVector3Array()
	var med_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	# Field bounds for clipping
	var field_x0 := border_m
	var field_z0 := border_m
	var field_x1 := fw - border_m
	var field_z1 := fh - border_m

	# Helper: clamp a point to the field region
	var _clamp_pt := func(p: Vector3) -> Vector3:
		return Vector3(clampf(p.x, field_x0, field_x1), p.y, clampf(p.z, field_z0, field_z1))

	# Helper: add grout line between two points
	var _add_grout_line := func(a: Vector3, b: Vector3) -> void:
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

	# Helper: clip a polygon to the field rectangle (Sutherland-Hodgman)
	var _clip_poly_to_rect := func(points: Array) -> Array:
		var poly: Array = points.duplicate()
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
	var terra_verts := PackedVector3Array()
	if border_width > 0:
		var result := BorderMotifs.draw_border_frame(
			dark_verts, light_verts, terra_verts,
			0.0, 0.0,
			fw, fh,
			border_m, rx,
			border_motif, false
		)
		dark_verts = result["dark"]
		light_verts = result["light"]
		terra_verts = result["terra"]

	# ── 2. Perspective cubes field ──
	# Regular rectangular grid — no hex offset.
	# Each cube is centered at (cx, cz) and composed of 3 rhombuses:
	#   - TOP face (light): horizontal diamond at the top
	#   - LEFT face (medium): lower-left parallelogram
	#   - RIGHT face (dark): lower-right parallelogram
	#
	# Cube vertices (6 outer + center):
	#   p_top = (cx, cz - ry)          — top vertex
	#   p_tr  = (cx + rx, cz - ry/2)   — top-right
	#   p_br  = (cx + rx, cz + ry/2)   — bottom-right
	#   p_bot = (cx, cz + ry)          — bottom vertex
	#   p_bl  = (cx - rx, cz + ry/2)   — bottom-left
	#   p_tl  = (cx - rx, cz - ry/2)   — top-left
	#   p_ctr = (cx, cz)               — center

	var hy := ry * 0.5

	# Regular grid: every row is aligned (no offset).
	# Row step = 2*ry (full cube height) so cubes don't overlap.
	# But to create the perspective-cube stacking effect, we use ry * 1.5
	# so adjacent rows share edges — cubes appear to sit on top of each other.
	var grid_row_step: float = ry * 1.5

	for row in range(-1, int(ceil(field_h / grid_row_step)) + 2):
		for col in range(-1, cols + 1):
			var cx: float = border_m + col * cube_w + rx
			var cz: float = border_m + row * grid_row_step

			# Skip cubes entirely outside the field
			if cx + rx < field_x0 - rx or cx - rx > field_x1 + rx:
				continue
			if cz + ry < field_z0 - ry or cz - ry > field_z1 + ry:
				continue

			# Six outer vertices + center
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

	# ── StaticBody3D + CollisionShape3D ──
	#_body = StaticBody3D.new()
	#var col := CollisionShape3D.new()
	#var box := BoxShape3D.new()
	#box.size = Vector3(fw, 0.01, fh)
	#col.shape = box
	#_body.add_child(col)
	#_body.position = Vector3(0.0, 0.0, 0.0)
	#add_child(_body)

	print("[PerspectiveCubesFloor] Built %d cols x %d rows (%d dark, %d med, %d light, %d grout tris)" % [
		cols, int(ceil(field_h / grid_row_step)) + 2,
		dark_verts.size() / 3,
		med_verts.size() / 3,
		light_verts.size() / 3,
		grout_verts.size() / 3,
	])
