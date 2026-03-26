# nested_diamonds_floor.gd
# Procedural Pompeii mosaic floor — nested diamonds pattern (photos 172359, 172420, 172606).
# Each cell contains concentric rotated squares: light background, dark diamond outline,
# light inner diamond, dark center diamond — three nested 45-degree rotations.
#
# @identity
#   essence: a floor encoding Roman depth through concentric rotated geometry
#   desire: players see how nesting the same shape at shrinking scales produces visual gravity
#   critical_parameter: tiles_short — number of nested-diamond cells on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the insight that recursion was a decorative principle millennia before computers
#   needs: [implemented] procedural mesh, border bands, nested diamond field, grout
#   relationships: pompeii_mosaic_floor (sibling pattern), diamonds_squares_floor (single-diamond cousin)
#   truth: every diamond holds a smaller copy of itself — the Romans knew about self-similarity

extends Node3D
class_name NestedDiamondsFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")
const BorderMotifs = preload("res://commons/artifacts/pompeii_mosaic_floor/border_motifs.gd")

@export var floor_size: Vector2 = Vector2(1.2, 1.0)
@export var tiles_short: int = 6
@export var border_widths: Array[int] = [2, 1, 2]
@export var border_motif: int = BorderMotifs.Motif.SAWTOOTH
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.06
@export_range(0.0, 1.0) var wear_level: float = 0.3

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

	# Grid dimensions
	var border_each: int = 0
	for bw in border_widths:
		border_each += bw

	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	var total_short := tiles_short + border_each * 2
	var ts := short_m / float(total_short)  # tile size in meters
	var total_long := int(round(long_m / ts))

	var gw: int = total_long if is_wide else total_short  # grid width in tiles
	var gh: int = total_short if is_wide else total_long   # grid height in tiles

	var fw := gw * ts  # floor width in meters
	var fh := gh * ts  # floor height in meters

	# Field region (inside borders)
	var fx0 := border_each
	var fy0 := border_each
	var fx1 := gw - border_each
	var fy1 := gh - border_each

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
	var inset: int = 0
	for i in border_widths.size():
		var bw: int = border_widths[i]
		var result := BorderMotifs.draw_border_frame(
			dark_verts, light_verts, terra_verts,
			inset * ts, inset * ts,
			(gw - inset * 2) * ts, (gh - inset * 2) * ts,
			bw * ts, ts,
			border_motif, i % 2 == 1
		)
		dark_verts = result["dark"]
		light_verts = result["light"]
		terra_verts = result["terra"]
		inset += bw

	# ── 2. Nested diamonds field ──
	# Each cell has 4 concentric zones (outside-in):
	#   Zone 1 (corners of cell square): LIGHT — 4 corner triangles between cell edge and outer diamond
	#   Zone 2 (outer diamond ring): DARK — ring between outer and middle diamonds
	#   Zone 3 (middle diamond): LIGHT — ring between middle and inner diamonds
	#   Zone 4 (inner diamond): DARK — small solid diamond at center
	#
	# Diamond radii as fraction of half-cell:
	#   Outer diamond: vertices at midpoints of cell edges (r = 0.5 * ts)
	#   Middle diamond: r = 0.3 * ts
	#   Inner diamond: r = 0.15 * ts

	var r_outer := 0.5   # fraction of ts — midpoints of edges
	var r_mid := 0.30     # fraction of ts
	var r_inner := 0.14   # fraction of ts

	for ty in range(fy0, fy1):
		for tx in range(fx0, fx1):
			var x := tx * ts
			var z := ty * ts
			var cx := x + ts * 0.5
			var cz := z + ts * 0.5

			# Cell corners
			var tl := Vector3(x, 0, z)
			var tr := Vector3(x + ts, 0, z)
			var bl := Vector3(x, 0, z + ts)
			var br := Vector3(x + ts, 0, z + ts)

			# Outer diamond vertices (midpoints of cell edges)
			var ot := Vector3(cx, 0, z)
			var or_ := Vector3(x + ts, 0, cz)
			var ob := Vector3(cx, 0, z + ts)
			var ol := Vector3(x, 0, cz)

			# Middle diamond vertices
			var mt := Vector3(cx, 0, cz - r_mid * ts)
			var mr := Vector3(cx + r_mid * ts, 0, cz)
			var mb := Vector3(cx, 0, cz + r_mid * ts)
			var ml := Vector3(cx - r_mid * ts, 0, cz)

			# Inner diamond vertices
			var it := Vector3(cx, 0, cz - r_inner * ts)
			var ir := Vector3(cx + r_inner * ts, 0, cz)
			var ib := Vector3(cx, 0, cz + r_inner * ts)
			var il := Vector3(cx - r_inner * ts, 0, cz)

			# Zone 1: LIGHT corner triangles (cell corners to outer diamond)
			light_verts = _add_tri.call(light_verts, tl, ot, ol)   # top-left
			light_verts = _add_tri.call(light_verts, tr, or_, ot)  # top-right
			light_verts = _add_tri.call(light_verts, br, ob, or_)  # bottom-right
			light_verts = _add_tri.call(light_verts, bl, ol, ob)   # bottom-left

			# Zone 2: DARK outer diamond ring (between outer and middle diamonds)
			# Each quadrant: triangle from outer edge vertex to two adjacent mid vertices,
			# plus triangle to fill the gap
			# Top quadrant (ot, mr, mt, ml)
			dark_verts = _add_tri.call(dark_verts, ot, or_, mr)
			dark_verts = _add_tri.call(dark_verts, ot, mr, mt)
			# Right quadrant
			dark_verts = _add_tri.call(dark_verts, or_, ob, mb)
			dark_verts = _add_tri.call(dark_verts, or_, mb, mr)
			# Bottom quadrant
			dark_verts = _add_tri.call(dark_verts, ob, ol, ml)
			dark_verts = _add_tri.call(dark_verts, ob, ml, mb)
			# Left quadrant
			dark_verts = _add_tri.call(dark_verts, ol, ot, mt)
			dark_verts = _add_tri.call(dark_verts, ol, mt, ml)

			# Zone 3: LIGHT middle diamond ring (between middle and inner diamonds)
			light_verts = _add_tri.call(light_verts, mt, mr, ir)
			light_verts = _add_tri.call(light_verts, mt, ir, it)
			light_verts = _add_tri.call(light_verts, mr, mb, ib)
			light_verts = _add_tri.call(light_verts, mr, ib, ir)
			light_verts = _add_tri.call(light_verts, mb, ml, il)
			light_verts = _add_tri.call(light_verts, mb, il, ib)
			light_verts = _add_tri.call(light_verts, ml, mt, it)
			light_verts = _add_tri.call(light_verts, ml, it, il)

			# Zone 4: DARK inner diamond (solid)
			dark_verts = _add_tri.call(dark_verts, it, ir, ib)
			dark_verts = _add_tri.call(dark_verts, it, ib, il)

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

		# Diamond diagonal grout: outer diamond edges (4 lines per cell)
		var diag_w := grout_w * 0.7
		var dh := diag_w * 0.7071
		for ty in range(fy0, fy1):
			for tx in range(fx0, fx1):
				var x := tx * ts
				var z := ty * ts
				var cx := x + ts * 0.5
				var cz := z + ts * 0.5

				# Outer diamond edges
				_add_diag_line(grout_verts, cx, z, x + ts, cz, dh)
				_add_diag_line(grout_verts, x + ts, cz, cx, z + ts, dh)
				_add_diag_line(grout_verts, cx, z + ts, x, cz, dh)
				_add_diag_line(grout_verts, x, cz, cx, z, dh)

				# Middle diamond edges
				var r_m := 0.30
				_add_diag_line(grout_verts, cx, cz - r_m * ts, cx + r_m * ts, cz, dh)
				_add_diag_line(grout_verts, cx + r_m * ts, cz, cx, cz + r_m * ts, dh)
				_add_diag_line(grout_verts, cx, cz + r_m * ts, cx - r_m * ts, cz, dh)
				_add_diag_line(grout_verts, cx - r_m * ts, cz, cx, cz - r_m * ts, dh)

				# Inner diamond edges
				var r_i := 0.14
				_add_diag_line(grout_verts, cx, cz - r_i * ts, cx + r_i * ts, cz, dh)
				_add_diag_line(grout_verts, cx + r_i * ts, cz, cx, cz + r_i * ts, dh)
				_add_diag_line(grout_verts, cx, cz + r_i * ts, cx - r_i * ts, cz, dh)
				_add_diag_line(grout_verts, cx - r_i * ts, cz, cx, cz - r_i * ts, dh)


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
		arr_mesh.surface_set_material(0, MosaicPalette.create_material(color_dark, wear_level))

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
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(MosaicPalette.TERRACOTTA, wear_level))

	if grout_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = grout_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(grout_color, wear_level))

	_mi = MeshInstance3D.new()
	_mi.mesh = arr_mesh
	_mi.position = Vector3(-fw * 0.5, 0.005, -fh * 0.5)  # Center the floor
	add_child(_mi)

	# ── StaticBody3D + CollisionShape3D ──
	#_body = StaticBody3D.new()
	#var col := CollisionShape3D.new()
	#var box := BoxShape3D.new()
	#box.size = Vector3(fw, 0.01, fh)
	#col.shape = box
	#_body.add_child(col)
	_body.position = Vector3(0.0, 0.0, 0.0)
	#add_child(_body)

	print("[NestedDiamondsFloor] Built %dx%d grid (%d dark tris, %d light tris, %d grout tris)" % [
		gw, gh,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		grout_verts.size() / 3,
	])


func _add_diag_line(verts: PackedVector3Array, x0: float, z0: float, x1: float, z1: float, dh: float) -> void:
	var dx := x1 - x0
	var dz := z1 - z0
	var length := sqrt(dx * dx + dz * dz)
	if length < 0.0001:
		return
	var px := -dz / length * dh
	var pz := dx / length * dh
	verts.append(Vector3(x0 + px, 0, z0 + pz))
	verts.append(Vector3(x1 + px, 0, z1 + pz))
	verts.append(Vector3(x1 - px, 0, z1 - pz))
	verts.append(Vector3(x0 + px, 0, z0 + pz))
	verts.append(Vector3(x1 - px, 0, z1 - pz))
	verts.append(Vector3(x0 - px, 0, z0 - pz))
