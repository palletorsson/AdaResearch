# diamond_lattice_floor.gd
# Procedural Pompeii diamond lattice floor — diagonal grid creating rhombus shapes.
# Two sets of parallel lines at 45 and 135 degrees cross to form a diamond lattice.
# Alternating diamonds filled dark/light for a rich checkerboard-on-point effect.
#
# @identity
#   essence: a floor that maps the diagonal logic of Roman reticulate masonry
#   desire: players see how a simple 45-degree rotation transforms a grid into jewelry
#   critical_parameter: diamonds_short — number of diamond cells on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the insight that rotation is the simplest symmetry that changes everything
#   needs: [implemented] procedural mesh, border bands, diamond lattice field
#   relationships: pompeii_mosaic_floor (parent pattern), nested_diamonds_floor (cousin)
#   truth: a rotated grid is still a grid — the math doesn't care about orientation

extends Node3D
class_name DiamondLatticeFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var diamonds_short: int = 12
@export var border_widths: Array[int] = [2, 1, 1]
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.05
@export_range(0.0, 1.0) var wear_level: float = 0.3

var _mi: MeshInstance3D
var _body: StaticBody3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	diamonds_short = int(config.get("diamonds_short", diamonds_short))
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
		_mi = null
	if _body:
		_body.queue_free()
		_body = null

	# Grid dimensions
	var border_each: int = 0
	for bw in border_widths:
		border_each += bw

	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	var total_short := diamonds_short + border_each * 2
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

	# Vertex arrays for 3 surfaces: dark, light, grout
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

	# Helper: add a diamond (4 triangles) given center and half-size
	var _add_diamond := func(verts: PackedVector3Array, cx: float, cz: float, half: float) -> PackedVector3Array:
		# Diamond vertices: top, right, bottom, left
		var top := Vector3(cx, 0, cz - half)
		var right := Vector3(cx + half, 0, cz)
		var bottom := Vector3(cx, 0, cz + half)
		var left := Vector3(cx - half, 0, cz)
		# 4 triangles from center
		var center := Vector3(cx, 0, cz)
		verts.append(center); verts.append(top); verts.append(right)
		verts.append(center); verts.append(right); verts.append(bottom)
		verts.append(center); verts.append(bottom); verts.append(left)
		verts.append(center); verts.append(left); verts.append(top)
		return verts

	# ── 1. Border bands (dark(2), light(1), dark(1)) ──
	# Simple solid-color border frames
	var inset: int = 0
	for i in border_widths.size():
		var bw: int = border_widths[i]
		var is_light_band := (i % 2 == 1)
		var band_verts: PackedVector3Array = light_verts if is_light_band else dark_verts

		var ox := inset * ts
		var oz := inset * ts
		var outer_w := (gw - inset * 2) * ts
		var outer_h := (gh - inset * 2) * ts
		var inner_w := (gw - (inset + bw) * 2) * ts
		var inner_h := (gh - (inset + bw) * 2) * ts
		var band_t := bw * ts

		# Top band
		band_verts = _add_rect.call(band_verts, ox, oz, outer_w, band_t)
		# Bottom band
		band_verts = _add_rect.call(band_verts, ox, oz + outer_h - band_t, outer_w, band_t)
		# Left band (between top and bottom)
		band_verts = _add_rect.call(band_verts, ox, oz + band_t, band_t, inner_h)
		# Right band (between top and bottom)
		band_verts = _add_rect.call(band_verts, ox + outer_w - band_t, oz + band_t, band_t, inner_h)

		if is_light_band:
			light_verts = band_verts
		else:
			dark_verts = band_verts
		inset += bw

	# ── 2. Diamond lattice field ──
	# Each grid cell is divided into a diamond (rotated square).
	# Alternate diamonds dark/light in a checkerboard pattern.
	# The corner triangles outside the diamond get the opposite color.
	var half_ts := ts * 0.5
	for ty in range(fy0, fy1):
		for tx in range(fx0, fx1):
			var x := tx * ts
			var z := ty * ts
			var cx := x + half_ts
			var cz := z + half_ts

			var is_dark_diamond := ((tx + ty) % 2) == 0

			# Diamond fills the cell rotated 45 degrees
			# Diamond vertices at midpoints of cell edges
			var top := Vector3(cx, 0, z)
			var right := Vector3(x + ts, 0, cz)
			var bottom := Vector3(cx, 0, z + ts)
			var left := Vector3(x, 0, cz)

			# Diamond interior (4 triangles from center)
			var diamond_verts: PackedVector3Array = dark_verts if is_dark_diamond else light_verts
			var corner_verts: PackedVector3Array = light_verts if is_dark_diamond else dark_verts

			var ctr := Vector3(cx, 0, cz)
			diamond_verts.append(ctr); diamond_verts.append(top); diamond_verts.append(right)
			diamond_verts.append(ctr); diamond_verts.append(right); diamond_verts.append(bottom)
			diamond_verts.append(ctr); diamond_verts.append(bottom); diamond_verts.append(left)
			diamond_verts.append(ctr); diamond_verts.append(left); diamond_verts.append(top)

			# Corner triangles (the 4 corners outside the diamond)
			var tl := Vector3(x, 0, z)
			var tr := Vector3(x + ts, 0, z)
			var br := Vector3(x + ts, 0, z + ts)
			var bl := Vector3(x, 0, z + ts)

			# Top-left corner
			corner_verts.append(tl); corner_verts.append(top); corner_verts.append(left)
			# Top-right corner
			corner_verts.append(tr); corner_verts.append(right); corner_verts.append(top)
			# Bottom-right corner
			corner_verts.append(br); corner_verts.append(bottom); corner_verts.append(right)
			# Bottom-left corner
			corner_verts.append(bl); corner_verts.append(left); corner_verts.append(bottom)

			if is_dark_diamond:
				dark_verts = diamond_verts
				light_verts = corner_verts
			else:
				light_verts = diamond_verts
				dark_verts = corner_verts

	# ── 3. Grout lines ──
	if grout_w > 0.001:
		var half := grout_w * 0.5
		# Outer grid grout — horizontal lines
		for gy in range(0, gh + 1):
			var z := gy * ts
			grout_verts = _add_rect.call(grout_verts, 0.0, z - half, fw, grout_w)
		# Outer grid grout — vertical lines
		for gx in range(0, gw + 1):
			var x := gx * ts
			grout_verts = _add_rect.call(grout_verts, x - half, 0.0, grout_w, fh)

		# Diagonal grout along diamond edges in the field
		var dw := grout_w * 0.7
		var dh := dw * 0.7071  # perpendicular half-width
		for ty in range(fy0, fy1):
			for tx in range(fx0, fx1):
				var x := tx * ts
				var z := ty * ts
				var cx := x + half_ts
				var cz := z + half_ts

				# Diamond edge from top to right (and all 4 edges)
				# Top-right edge: (cx, z) to (x+ts, cz)
				grout_verts.append(Vector3(cx - dh, 0, z - dh))
				grout_verts.append(Vector3(cx + dh, 0, z + dh))
				grout_verts.append(Vector3(x + ts + dh, 0, cz - dh))
				grout_verts.append(Vector3(cx - dh, 0, z - dh))
				grout_verts.append(Vector3(x + ts + dh, 0, cz - dh))
				grout_verts.append(Vector3(x + ts - dh, 0, cz + dh))

				# Right-bottom edge: (x+ts, cz) to (cx, z+ts)
				grout_verts.append(Vector3(x + ts + dh, 0, cz - dh))
				grout_verts.append(Vector3(x + ts - dh, 0, cz + dh))
				grout_verts.append(Vector3(cx + dh, 0, z + ts + dh))
				grout_verts.append(Vector3(x + ts + dh, 0, cz - dh))
				grout_verts.append(Vector3(cx + dh, 0, z + ts + dh))
				grout_verts.append(Vector3(cx - dh, 0, z + ts - dh))

				# Bottom-left edge: (cx, z+ts) to (x, cz)
				grout_verts.append(Vector3(cx + dh, 0, z + ts + dh))
				grout_verts.append(Vector3(cx - dh, 0, z + ts - dh))
				grout_verts.append(Vector3(x - dh, 0, cz + dh))
				grout_verts.append(Vector3(cx + dh, 0, z + ts + dh))
				grout_verts.append(Vector3(x - dh, 0, cz + dh))
				grout_verts.append(Vector3(x + dh, 0, cz - dh))

				# Left-top edge: (x, cz) to (cx, z)
				grout_verts.append(Vector3(x - dh, 0, cz + dh))
				grout_verts.append(Vector3(x + dh, 0, cz - dh))
				grout_verts.append(Vector3(cx - dh, 0, z - dh))
				grout_verts.append(Vector3(x - dh, 0, cz + dh))
				grout_verts.append(Vector3(cx - dh, 0, z - dh))
				grout_verts.append(Vector3(cx + dh, 0, z + dh))


	# ── Z-fighting fix: offset each surface to a distinct Y layer ──
	# Hierarchy: grout(-0.001) < dark(0.0) < light(0.001) < accent/terra(0.002) < border(0.003)
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts
	dark_verts = _offset_y.call(dark_verts, 0.0)
	light_verts = _offset_y.call(light_verts, 0.001)
	grout_verts = _offset_y.call(grout_verts, -0.001)

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

	if grout_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = grout_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(grout_color, wear_level))

	_mi = MeshInstance3D.new()
	_mi.mesh = arr_mesh
	_mi.position = Vector3(-fw * 0.5, 0.005, -fh * 0.5)  # Center at origin, y=0.005
	add_child(_mi)

	# ── StaticBody3D with CollisionShape3D ──
	_body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(fw, 0.01, fh)
	col.shape = box
	_body.add_child(col)
	_body.position = Vector3(0, 0.005, 0)
	add_child(_body)

	print("[DiamondLatticeFloor] Built %dx%d grid (%d dark tris, %d light tris, %d grout tris)" % [
		gw, gh,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		grout_verts.size() / 3,
	])
