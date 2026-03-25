# star_rosette_floor.gd
# Procedural Pompeii mosaic floor — hexagonal star rosette (hexagram) pattern.
# Each cell contains a 6-pointed star (Star of David / hexagram) formed by two
# overlapping equilateral triangles. Dark stars on light background with small
# rhombus shapes between stars. Classic Roman geometric mosaic.
#
# @identity
#   essence: a floor that carries the sacred geometry of intersecting triangles
#   desire: players look down and see how two simple triangles create complex star forms
#   critical_parameter: stars_across — number of star cells on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the understanding that overlap of simple forms creates emergent complexity
#   needs: [implemented] procedural mesh, border bands, hexagram star field, grout
#   relationships: pompeii_mosaic_floor (sibling pattern), pattern_maker_station (web editor)
#   truth: every hexagram is just two triangles that chose to coexist

extends Node3D
class_name StarRosetteFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")
const BorderMotifs = preload("res://commons/artifacts/pompeii_mosaic_floor/border_motifs.gd")

@export var floor_size: Vector2 = Vector2(1.0, 0.75)
@export var stars_across: int = 6
@export var border_widths: Array[int] = [2, 1, 1]
@export var border_motif: int = BorderMotifs.Motif.MEANDER
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.06
@export_range(0.0, 1.0) var wear_level: float = 0.3

var _mi: MeshInstance3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	stars_across = int(config.get("stars_across", stars_across))
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

	# Border total width in tile units
	var border_each: int = 0
	for bw in border_widths:
		border_each += bw

	# Grid dimensions — the star field sits on a rectangular grid.
	# Each star cell is a square; we compute tile size from the short axis.
	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	# Total tiles on short axis = star cells + border on both sides
	# Each star cell occupies 2x2 grid tiles for detail
	var cell_tiles := 2  # each star cell = 2x2 grid tiles
	var total_short_tiles := stars_across * cell_tiles + border_each * 2
	var ts := short_m / float(total_short_tiles)  # grid tile size in meters
	var total_long_tiles := int(round(long_m / ts))

	var gw: int = total_long_tiles if is_wide else total_short_tiles
	var gh: int = total_short_tiles if is_wide else total_long_tiles

	var fw := gw * ts
	var fh := gh * ts

	# Field region (inside borders), in grid-tile coordinates
	var fx0 := border_each
	var fy0 := border_each
	var fx1 := gw - border_each
	var fy1 := gh - border_each

	# Star cell size in meters
	var cell_size := cell_tiles * ts

	# How many star cells fit in field
	var stars_x := (fx1 - fx0) / cell_tiles
	var stars_y := (fy1 - fy0) / cell_tiles

	# Grout width
	var grout_w := ts * grout_width_fraction

	# Vertex arrays for 3 surfaces: dark, light, grout
	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	# Helper: add a flat quad in XZ plane at y=0
	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	# Helper: add a triangle in XZ plane at given y
	var _add_tri := func(verts: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> PackedVector3Array:
		verts.append(a)
		verts.append(b)
		verts.append(c)
		return verts

	# ── 1. Border bands ── dark(2), light(1), dark(1)
	var terra_verts := PackedVector3Array()
	var inset: int = 0
	for i in border_widths.size():
		var bw_val: int = border_widths[i]
		var result := BorderMotifs.draw_border_frame(
			dark_verts, light_verts, terra_verts,
			inset * ts, inset * ts,
			(gw - inset * 2) * ts, (gh - inset * 2) * ts,
			bw_val * ts, ts,
			border_motif, i % 2 == 1
		)
		dark_verts = result["dark"]
		light_verts = result["light"]
		terra_verts = result["terra"]
		inset += bw_val

	# ── 2. Star rosette field ──
	# Each star cell: hexagram (6-pointed star) = two overlapping equilateral triangles
	# The star is inscribed in a square cell of size `cell_size`.
	#
	# Geometry of a hexagram in a square of side `s`:
	# - Center at (cx, cz)
	# - Outer radius R = s/2 (tips of star touch cell edges)
	# - Inner radius r = R / sqrt(3) ≈ R * 0.577 (inner hexagon vertices)
	#
	# The 6-pointed star has 12 vertices: 6 outer tips + 6 inner concave vertices
	# Outer tips at angles: 0, 60, 120, 180, 240, 300 degrees
	# Inner vertices at angles: 30, 90, 150, 210, 270, 330 degrees

	# Fill the entire field with light background at y=0
	var field_x := fx0 * ts
	var field_z := fy0 * ts
	var field_w := (fx1 - fx0) * ts
	var field_h := (fy1 - fy0) * ts
	light_verts = _add_rect.call(light_verts, field_x, field_z, field_w, field_h)

	# Dark star triangles at y=0.001 to render above light background
	var star_y := 0.001

	for sy in range(stars_y):
		for sx in range(stars_x):
			var cx := (fx0 + sx * cell_tiles + cell_tiles * 0.5) * ts
			var cz := (fy0 + sy * cell_tiles + cell_tiles * 0.5) * ts
			var R := cell_size * 0.48  # outer radius: tips nearly touch cell edges
			var r := R * 0.5774  # R / sqrt(3), inner hexagon radius

			# Build 12 vertices of the hexagram
			# Outer tips at 0, 60, 120, 180, 240, 300 (from top, clockwise)
			# Inner concave at 30, 90, 150, 210, 270, 330
			var outer_pts: Array[Vector3] = []
			var inner_pts: Array[Vector3] = []

			for k in range(6):
				var angle_out := deg_to_rad(k * 60.0 - 90.0)  # start from top
				var angle_in := deg_to_rad(k * 60.0 + 30.0 - 90.0)
				outer_pts.append(Vector3(cx + R * cos(angle_out), star_y, cz + R * sin(angle_out)))
				inner_pts.append(Vector3(cx + r * cos(angle_in), star_y, cz + r * sin(angle_in)))

			# The hexagram = 6 outer spike triangles + inner hexagon
			# Each spike: outer[k] -> inner[k] -> inner[(k+5)%6]
			for k in range(6):
				dark_verts = _add_tri.call(dark_verts,
					outer_pts[k],
					inner_pts[k],
					inner_pts[(k + 5) % 6]
				)

			# Inner hexagon: 6 triangles from center to inner vertices
			var center := Vector3(cx, star_y, cz)
			for k in range(6):
				dark_verts = _add_tri.call(dark_verts,
					center,
					inner_pts[k],
					inner_pts[(k + 1) % 6]
				)

	# ── 3. Grout lines ──
	if grout_w > 0.001:
		var half := grout_w * 0.5

		# Grid lines (border area)
		for gy in range(0, gh + 1):
			var z := gy * ts
			grout_verts = _add_rect.call(grout_verts, 0.0, z - half, fw, grout_w)
		for gx in range(0, gw + 1):
			var x := gx * ts
			grout_verts = _add_rect.call(grout_verts, x - half, 0.0, grout_w, fh)

		# Star outlines: grout lines around each hexagram
		var line_w := grout_w * 0.6
		for sy in range(stars_y):
			for sx in range(stars_x):
				var cx := (fx0 + sx * cell_tiles + cell_tiles * 0.5) * ts
				var cz := (fy0 + sy * cell_tiles + cell_tiles * 0.5) * ts
				var R := cell_size * 0.48
				var r := R * 0.5774

				var outer_pts: Array[Vector3] = []
				var inner_pts: Array[Vector3] = []

				for k in range(6):
					var angle_out := deg_to_rad(k * 60.0 - 90.0)
					var angle_in := deg_to_rad(k * 60.0 + 30.0 - 90.0)
					outer_pts.append(Vector3(cx + R * cos(angle_out), 0, cz + R * sin(angle_out)))
					inner_pts.append(Vector3(cx + r * cos(angle_in), 0, cz + r * sin(angle_in)))

				# Draw lines along all 12 edges of the hexagram
				for k in range(6):
					var k_next := (k + 1) % 6
					var k_prev := (k + 5) % 6
					# outer[k] -> inner[k]
					_add_diag_line(grout_verts, outer_pts[k].x, outer_pts[k].z,
						inner_pts[k].x, inner_pts[k].z, line_w * 0.5)
					# outer[k] -> inner[k_prev]
					_add_diag_line(grout_verts, outer_pts[k].x, outer_pts[k].z,
						inner_pts[k_prev].x, inner_pts[k_prev].z, line_w * 0.5)
					# inner[k] -> inner[k_next] (inner hexagon edges)
					_add_diag_line(grout_verts, inner_pts[k].x, inner_pts[k].z,
						inner_pts[k_next].x, inner_pts[k_next].z, line_w * 0.5)


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

	# Add StaticBody3D for floor collider
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(fw, 0.01, fh)
	col.shape = shape
	body.add_child(col)
	body.position = Vector3(0, 0.005, 0)
	add_child(body)

	print("[StarRosetteFloor] Built %dx%d grid, %d stars (%d dark tris, %d light tris, %d grout tris)" % [
		gw, gh, stars_x * stars_y,
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
