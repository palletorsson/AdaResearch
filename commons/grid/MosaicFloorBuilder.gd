# MosaicFloorBuilder.gd
# Reads a mosaic composition JSON (v2 ring-stack format from commons/patterns/mosaics/)
# and builds a procedural floor mesh with border rings and patterned field.
#
# Usage:
#   var floor_node = MosaicFloorBuilder.build_floor(
#       "res://commons/patterns/mosaics/pinwheel_truchet_room.json",
#       Vector2(2.4, 1.8),
#       parent_node
#   )

class_name MosaicFloorBuilder
extends RefCounted

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")


## Build a floor from a mosaic composition JSON and add it to parent.
## Returns the MeshInstance3D node (already parented).
static func build_floor(composition_path: String, floor_size: Vector2, parent: Node3D) -> Node3D:
	var comp := _load_composition(composition_path)
	if comp.is_empty():
		push_error("[MosaicFloorBuilder] Failed to load composition: %s" % composition_path)
		return null

	# Parse palette colors
	var palette_colors: Array[Color] = []
	var palette_arr = comp.get("palette", [])
	for hex in palette_arr:
		palette_colors.append(Color.from_string(str(hex), MosaicPalette.DARK))
	# Ensure at least 2 colors
	if palette_colors.size() < 1:
		palette_colors.append(MosaicPalette.DARK)
	if palette_colors.size() < 2:
		palette_colors.append(MosaicPalette.LIGHT)

	# Aging parameters
	var aging = comp.get("aging", {})
	var grout_frac: float = float(aging.get("grout_width", 0.04))
	var wear: float = float(aging.get("wear_amount", 0.3))

	# Rings (border bands from outside-in)
	var rings: Array = comp.get("rings", [])

	# Total border width in tile units
	var border_each: int = 0
	for ring in rings:
		border_each += int(ring.get("width", 1))

	# Also support legacy border_width (if no rings defined)
	if rings.is_empty():
		border_each = int(comp.get("border_width", 0))

	# Field zone
	var zones = comp.get("zones", {})
	var field = zones.get("field", {})
	var motif_id: String = str(field.get("motif", "solid"))

	# Tiles on short axis for the field
	var tiles_short: int = 10
	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	var total_short := tiles_short + border_each * 2
	var ts := short_m / float(total_short)
	var total_long := int(round(long_m / ts))

	var gw: int = total_long if is_wide else total_short
	var gh: int = total_short if is_wide else total_long

	var fw := gw * ts
	var fh := gh * ts

	var grout_w := ts * grout_frac

	# Vertex buffers — one per palette color + grout
	var color_verts: Array[PackedVector3Array] = []
	for i in palette_colors.size():
		color_verts.append(PackedVector3Array())
	var grout_verts := PackedVector3Array()

	# ── 1. Border rings (outside-in) ──
	var inset: int = 0
	if rings.size() > 0:
		for ring in rings:
			var rw: int = int(ring.get("width", 1))
			var ci: int = clampi(int(ring.get("color_index", 0)), 0, palette_colors.size() - 1)
			# Draw a solid rectangular frame for this ring
			_draw_solid_frame(
				color_verts[ci],
				inset * ts, inset * ts,
				(gw - inset * 2) * ts, (gh - inset * 2) * ts,
				rw * ts
			)
			inset += rw
	elif border_each > 0:
		# Legacy: simple solid border using first palette color
		_draw_solid_frame(
			color_verts[0],
			0.0, 0.0,
			gw * ts, gh * ts,
			border_each * ts
		)
		inset = border_each

	# Field region (inside all borders)
	var fx0 := inset
	var fy0 := inset
	var fx1 := gw - inset
	var fy1 := gh - inset

	# ── 2. Field pattern ──
	match motif_id:
		"pinwheel_truchet":
			_build_truchet_field(color_verts, fx0, fy0, fx1, fy1, ts)
		"nested_diamonds":
			_build_nested_diamonds_field(color_verts, fx0, fy0, fx1, fy1, ts)
		"checkerboard":
			_build_checkerboard_field(color_verts, fx0, fy0, fx1, fy1, ts)
		"tumbling_blocks":
			_build_tumbling_blocks_field(color_verts, fx0, fy0, fx1, fy1, ts)
		"octagon_square":
			_build_octagon_square_field(color_verts, fx0, fy0, fx1, fy1, ts)
		"diamonds_squares":
			_build_diamonds_squares_field(color_verts, fx0, fy0, fx1, fy1, ts)
		"polka_dot_field":
			_build_polka_dot_field(color_verts, fx0, fy0, fx1, fy1, ts)
		"star_rosette":
			_build_star_rosette_field(color_verts, fx0, fy0, fx1, fy1, ts)
		"wave_scale":
			_build_wave_scale_field(color_verts, fx0, fy0, fx1, fy1, ts)
		_:
			# Solid fill with first palette color
			_build_solid_field(color_verts, fx0, fy0, fx1, fy1, ts, 0)

	# ── 3. Grout lines ──
	if grout_w > 0.001:
		var half := grout_w * 0.5
		# Horizontal grid lines
		for gy in range(0, gh + 1):
			var z := gy * ts
			_add_rect(grout_verts, 0.0, z - half, fw, grout_w)
		# Vertical grid lines
		for gx in range(0, gw + 1):
			var x := gx * ts
			_add_rect(grout_verts, x - half, 0.0, grout_w, fh)
		# Diagonal grout for truchet field
		if motif_id == "pinwheel_truchet":
			var diag_w := grout_w * 0.7
			var dh := diag_w * 0.7071
			for ty in range(fy0, fy1):
				for tx in range(fx0, fx1):
					var x := tx * ts
					var z := ty * ts
					var even_diag := ((tx + ty) % 2) == 0
					if even_diag:
						_add_diag_line(grout_verts, x, z + ts, x + ts, z, dh)
					else:
						_add_diag_line(grout_verts, x, z, x + ts, z + ts, dh)
		# Diamond grout for nested_diamonds
		elif motif_id == "nested_diamonds":
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
		# Diagonal grout for diamonds_squares (diamond edges at midpoints)
		elif motif_id == "diamonds_squares":
			var diag_w := grout_w * 0.7
			var dh := diag_w * 0.7071
			for ty in range(fy0, fy1):
				for tx in range(fx0, fx1):
					var x := tx * ts
					var z := ty * ts
					var cx := x + ts * 0.5
					var cz := z + ts * 0.5
					_add_diag_line(grout_verts, cx, z, x + ts, cz, dh)
					_add_diag_line(grout_verts, x + ts, cz, cx, z + ts, dh)
					_add_diag_line(grout_verts, cx, z + ts, x, cz, dh)
					_add_diag_line(grout_verts, x, cz, cx, z, dh)
		# Diagonal grout for octagon_square (45-degree cuts at corners)
		elif motif_id == "octagon_square":
			var sqrt2 := sqrt(2.0)
			var oct_side := ts / (1.0 + sqrt2)
			var cut := oct_side / sqrt2
			var dh := grout_w * 0.5 * 0.7071
			for ty in range(fy0, fy1):
				for tx in range(fx0, fx1):
					var ox := tx * ts
					var oz := ty * ts
					# 4 corner cuts per octagon
					_add_diag_line(grout_verts, ox, oz + cut, ox + cut, oz, dh)
					_add_diag_line(grout_verts, ox + ts - cut, oz, ox + ts, oz + cut, dh)
					_add_diag_line(grout_verts, ox + ts, oz + ts - cut, ox + ts - cut, oz + ts, dh)
					_add_diag_line(grout_verts, ox + cut, oz + ts, ox, oz + ts - cut, dh)
		# Star rosette grout: hexagram outlines
		elif motif_id == "star_rosette":
			var line_w := grout_w * 0.6
			var stars_x := (fx1 - fx0) / 2
			var stars_y := (fy1 - fy0) / 2
			for sy in range(stars_y):
				for sx in range(stars_x):
					var cx := (fx0 + sx * 2 + 1.0) * ts
					var cz := (fy0 + sy * 2 + 1.0) * ts
					var R := ts * 2.0 * 0.48
					var r := R * 0.5774
					var outer_pts: Array[Vector3] = []
					var inner_pts: Array[Vector3] = []
					for k in range(6):
						var angle_out := deg_to_rad(k * 60.0 - 90.0)
						var angle_in := deg_to_rad(k * 60.0 + 30.0 - 90.0)
						outer_pts.append(Vector3(cx + R * cos(angle_out), 0, cz + R * sin(angle_out)))
						inner_pts.append(Vector3(cx + r * cos(angle_in), 0, cz + r * sin(angle_in)))
					for k in range(6):
						var k_prev := (k + 5) % 6
						var k_next := (k + 1) % 6
						_add_diag_line(grout_verts, outer_pts[k].x, outer_pts[k].z, inner_pts[k].x, inner_pts[k].z, line_w * 0.5)
						_add_diag_line(grout_verts, outer_pts[k].x, outer_pts[k].z, inner_pts[k_prev].x, inner_pts[k_prev].z, line_w * 0.5)
						_add_diag_line(grout_verts, inner_pts[k].x, inner_pts[k].z, inner_pts[k_next].x, inner_pts[k_next].z, line_w * 0.5)
		# Wave scale grout: arc outlines
		elif motif_id == "wave_scale":
			var field_x0m := fx0 * ts
			var field_z0m := fy0 * ts
			var field_wm := (fx1 - fx0) * ts
			var field_hm := (fy1 - fy0) * ts
			var radius := ts * 2.0
			var row_height := radius
			var segs := 8
			var cols_in := int(field_wm / radius) + 2
			var rows_in := int(field_hm / row_height) + 2
			for row in range(-1, rows_in + 1):
				var is_off := (row % 2) == 1
				var off_x := radius * 0.5 if is_off else 0.0
				var cz := field_z0m + row * row_height
				for col in range(-1, cols_in + 1):
					var cx := field_x0m + col * radius + off_x
					if cx + radius < field_x0m or cx - radius > field_x0m + field_wm:
						continue
					if cz + radius < field_z0m or cz > field_z0m + field_hm:
						continue
					var r_inner := radius - grout_w * 0.5
					var r_outer := radius + grout_w * 0.5
					for seg in range(segs):
						var a0 := PI * float(seg) / float(segs)
						var a1 := PI * float(seg + 1) / float(segs)
						grout_verts.append(Vector3(cx + cos(a0) * r_inner, 0.001, cz + sin(a0) * r_inner))
						grout_verts.append(Vector3(cx + cos(a0) * r_outer, 0.001, cz + sin(a0) * r_outer))
						grout_verts.append(Vector3(cx + cos(a1) * r_outer, 0.001, cz + sin(a1) * r_outer))
						grout_verts.append(Vector3(cx + cos(a0) * r_inner, 0.001, cz + sin(a0) * r_inner))
						grout_verts.append(Vector3(cx + cos(a1) * r_outer, 0.001, cz + sin(a1) * r_outer))
						grout_verts.append(Vector3(cx + cos(a1) * r_inner, 0.001, cz + sin(a1) * r_inner))

	# ── Build ArrayMesh ──
	var arr_mesh := ArrayMesh.new()
	var surface_count := 0

	for i in color_verts.size():
		if color_verts[i].size() > 0:
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = color_verts[i]
			arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			arr_mesh.surface_set_material(surface_count, MosaicPalette.create_material(palette_colors[i], wear))
			surface_count += 1

	if grout_verts.size() > 0:
		# Raise grout slightly above tile surfaces to prevent z-fighting
		for vi in range(grout_verts.size()):
			grout_verts[vi].y = 0.002
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = grout_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(surface_count, MosaicPalette.create_material(MosaicPalette.GROUT, wear))
		surface_count += 1

	var root := Node3D.new()
	root.name = "MosaicFloorRoot"

	var mi := MeshInstance3D.new()
	mi.mesh = arr_mesh
	mi.name = "MosaicFloor"
	# Center the mesh within the root node
	mi.position = Vector3(-fw * 0.5, 0.005, -fh * 0.5)
	root.add_child(mi)
	parent.add_child(root)

	var total_tris := 0
	for cv in color_verts:
		total_tris += cv.size() / 3
	total_tris += grout_verts.size() / 3
	print("[MosaicFloorBuilder] Built %dx%d grid, motif=%s, %d tris" % [gw, gh, motif_id, total_tris])

	return root


# ── Composition loader ──

static func _load_composition(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("[MosaicFloorBuilder] File not found: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("[MosaicFloorBuilder] JSON parse error in %s: %s" % [path, json.get_error_message()])
		return {}
	return json.data as Dictionary


# ── Geometry helpers ──

static func _add_rect(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> void:
	verts.append(Vector3(x, 0, z))
	verts.append(Vector3(x + w, 0, z))
	verts.append(Vector3(x + w, 0, z + h))
	verts.append(Vector3(x, 0, z))
	verts.append(Vector3(x + w, 0, z + h))
	verts.append(Vector3(x, 0, z + h))


static func _add_tri(verts: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> void:
	verts.append(a)
	verts.append(b)
	verts.append(c)


static func _add_diag_line(verts: PackedVector3Array, x0: float, z0: float, x1: float, z1: float, dh: float) -> void:
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


## Draw a solid rectangular frame (4 bands) into a vertex buffer.
static func _draw_solid_frame(verts: PackedVector3Array, x0: float, z0: float, w: float, h: float, band_w: float) -> void:
	# Top band
	_add_rect(verts, x0, z0, w, band_w)
	# Bottom band
	_add_rect(verts, x0, z0 + h - band_w, w, band_w)
	# Left band (between top and bottom)
	_add_rect(verts, x0, z0 + band_w, band_w, h - band_w * 2)
	# Right band (between top and bottom)
	_add_rect(verts, x0 + w - band_w, z0 + band_w, band_w, h - band_w * 2)


# ── Field pattern builders ──

## Pinwheel truchet: diagonal-split tiles with 90-degree rotation.
## Uses palette indices 0 (dark) and 1 (light).
static func _build_truchet_field(color_verts: Array[PackedVector3Array], fx0: int, fy0: int, fx1: int, fy1: int, ts: float) -> void:
	var dark := color_verts[0]
	var light := color_verts[1]

	for ty in range(fy0, fy1):
		for tx in range(fx0, fx1):
			var x := tx * ts
			var z := ty * ts

			var even_diag := ((tx + ty) % 2) == 0
			var flip := ((ty - fy0) % 2) == 1
			var dark_ul := even_diag == (not flip)

			if even_diag:
				# TL-BR diagonal
				if dark_ul:
					dark.append(Vector3(x, 0, z))
					dark.append(Vector3(x + ts, 0, z))
					dark.append(Vector3(x, 0, z + ts))
					light.append(Vector3(x + ts, 0, z))
					light.append(Vector3(x + ts, 0, z + ts))
					light.append(Vector3(x, 0, z + ts))
				else:
					light.append(Vector3(x, 0, z))
					light.append(Vector3(x + ts, 0, z))
					light.append(Vector3(x, 0, z + ts))
					dark.append(Vector3(x + ts, 0, z))
					dark.append(Vector3(x + ts, 0, z + ts))
					dark.append(Vector3(x, 0, z + ts))
			else:
				# TR-BL diagonal
				if dark_ul:
					dark.append(Vector3(x, 0, z))
					dark.append(Vector3(x + ts, 0, z))
					dark.append(Vector3(x + ts, 0, z + ts))
					light.append(Vector3(x, 0, z))
					light.append(Vector3(x + ts, 0, z + ts))
					light.append(Vector3(x, 0, z + ts))
				else:
					light.append(Vector3(x, 0, z))
					light.append(Vector3(x + ts, 0, z))
					light.append(Vector3(x + ts, 0, z + ts))
					dark.append(Vector3(x, 0, z))
					dark.append(Vector3(x + ts, 0, z + ts))
					dark.append(Vector3(x, 0, z + ts))


## Nested diamonds: concentric rotated squares per cell.
## Uses palette indices 0 (dark) and 1 (light).
static func _build_nested_diamonds_field(color_verts: Array[PackedVector3Array], fx0: int, fy0: int, fx1: int, fy1: int, ts: float) -> void:
	var dark := color_verts[0]
	var light := color_verts[1]

	var r_outer := 0.5
	var r_mid := 0.30
	var r_inner := 0.14

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

			# Outer diamond (midpoints)
			var ot := Vector3(cx, 0, z)
			var or_ := Vector3(x + ts, 0, cz)
			var ob := Vector3(cx, 0, z + ts)
			var ol := Vector3(x, 0, cz)

			# Middle diamond
			var mt := Vector3(cx, 0, cz - r_mid * ts)
			var mr := Vector3(cx + r_mid * ts, 0, cz)
			var mb := Vector3(cx, 0, cz + r_mid * ts)
			var ml := Vector3(cx - r_mid * ts, 0, cz)

			# Inner diamond
			var it := Vector3(cx, 0, cz - r_inner * ts)
			var ir := Vector3(cx + r_inner * ts, 0, cz)
			var ib := Vector3(cx, 0, cz + r_inner * ts)
			var il := Vector3(cx - r_inner * ts, 0, cz)

			# Zone 1: LIGHT corner triangles
			_add_tri(light, tl, ot, ol)
			_add_tri(light, tr, or_, ot)
			_add_tri(light, br, ob, or_)
			_add_tri(light, bl, ol, ob)

			# Zone 2: DARK outer diamond ring
			_add_tri(dark, ot, or_, mr)
			_add_tri(dark, ot, mr, mt)
			_add_tri(dark, or_, ob, mb)
			_add_tri(dark, or_, mb, mr)
			_add_tri(dark, ob, ol, ml)
			_add_tri(dark, ob, ml, mb)
			_add_tri(dark, ol, ot, mt)
			_add_tri(dark, ol, mt, ml)

			# Zone 3: LIGHT middle diamond ring
			_add_tri(light, mt, mr, ir)
			_add_tri(light, mt, ir, it)
			_add_tri(light, mr, mb, ib)
			_add_tri(light, mr, ib, ir)
			_add_tri(light, mb, ml, il)
			_add_tri(light, mb, il, ib)
			_add_tri(light, ml, mt, it)
			_add_tri(light, ml, it, il)

			# Zone 4: DARK inner diamond
			_add_tri(dark, it, ir, ib)
			_add_tri(dark, it, ib, il)


## Checkerboard: alternating squares using palette indices 0 and 1.
static func _build_checkerboard_field(color_verts: Array[PackedVector3Array], fx0: int, fy0: int, fx1: int, fy1: int, ts: float) -> void:
	for ty in range(fy0, fy1):
		for tx in range(fx0, fx1):
			var ci: int = (tx + ty) % 2
			ci = clampi(ci, 0, color_verts.size() - 1)
			_add_rect(color_verts[ci], tx * ts, ty * ts, ts, ts)


## Solid fill: fills entire field with a single palette color.
static func _build_solid_field(color_verts: Array[PackedVector3Array], fx0: int, fy0: int, fx1: int, fy1: int, ts: float, ci: int) -> void:
	ci = clampi(ci, 0, color_verts.size() - 1)
	for ty in range(fy0, fy1):
		for tx in range(fx0, fx1):
			_add_rect(color_verts[ci], tx * ts, ty * ts, ts, ts)


## Tumbling blocks: isometric cube illusion from 3 rhombuses per hex cell.
## Uses palette indices 0 (dark), 1 (light), and 2 if available (medium).
static func _build_tumbling_blocks_field(color_verts: Array[PackedVector3Array], fx0: int, fy0: int, fx1: int, fy1: int, ts: float) -> void:
	var dark := color_verts[0]
	var light := color_verts[1]
	# Use palette index 2 for medium shade if available, otherwise blend dark
	var med := color_verts[clampi(2, 0, color_verts.size() - 1)] if color_verts.size() > 2 else dark

	var field_w := (fx1 - fx0) * ts
	var field_h := (fy1 - fy0) * ts
	var field_x0 := fx0 * ts
	var field_z0 := fy0 * ts

	# Cube geometry: each cube = 3 rhombuses on hex grid
	var cube_w := ts * 2.0
	var rx := cube_w * 0.5
	var ry := rx * sqrt(3.0)
	var hy := ry * 0.5
	var row_step := ry * 1.5

	var cols := int(ceil(field_w / cube_w)) + 2
	var rows := int(ceil(field_h / row_step)) + 2

	for row in range(-1, rows + 1):
		var offset_x: float = rx if (row % 2 == 1) else 0.0
		for col in range(-1, cols + 1):
			var cx := field_x0 + col * cube_w + rx + offset_x
			var cz := field_z0 + row * row_step

			# Six hex vertices + center
			var p_top := Vector3(cx, 0, cz - ry)
			var p_tr := Vector3(cx + rx, 0, cz - hy)
			var p_br := Vector3(cx + rx, 0, cz + hy)
			var p_bot := Vector3(cx, 0, cz + ry)
			var p_bl := Vector3(cx - rx, 0, cz + hy)
			var p_tl := Vector3(cx - rx, 0, cz - hy)
			var p_ctr := Vector3(cx, 0, cz)

			# TOP face (light)
			_add_tri(light, p_tl, p_top, p_ctr)
			_add_tri(light, p_top, p_tr, p_ctr)
			# LEFT face (medium)
			_add_tri(med, p_tl, p_ctr, p_bot)
			_add_tri(med, p_tl, p_bot, p_bl)
			# RIGHT face (dark)
			_add_tri(dark, p_ctr, p_tr, p_br)
			_add_tri(dark, p_ctr, p_br, p_bot)


## Octagon-and-square: octagons with small squares at intersections.
## Uses palette indices 0 (dark squares) and 1 (light octagons).
static func _build_octagon_square_field(color_verts: Array[PackedVector3Array], fx0: int, fy0: int, fx1: int, fy1: int, ts: float) -> void:
	var dark := color_verts[0]
	var light := color_verts[1]

	# Octagon geometry within each tile
	var sqrt2 := sqrt(2.0)
	var oct_side := ts / (1.0 + sqrt2)
	var cut := oct_side / sqrt2

	for ty in range(fy0, fy1):
		for tx in range(fx0, fx1):
			var ox := tx * ts
			var oz := ty * ts

			# 8 vertices of the octagon
			var p0 := Vector3(ox + cut, 0, oz)
			var p1 := Vector3(ox + ts - cut, 0, oz)
			var p2 := Vector3(ox + ts, 0, oz + cut)
			var p3 := Vector3(ox + ts, 0, oz + ts - cut)
			var p4 := Vector3(ox + ts - cut, 0, oz + ts)
			var p5 := Vector3(ox + cut, 0, oz + ts)
			var p6 := Vector3(ox, 0, oz + ts - cut)
			var p7 := Vector3(ox, 0, oz + cut)

			# Octagon as fan from center
			var cx := ox + ts * 0.5
			var cz := oz + ts * 0.5
			var center := Vector3(cx, 0, cz)
			var pts: Array[Vector3] = [p0, p1, p2, p3, p4, p5, p6, p7]
			for i in range(8):
				_add_tri(light, center, pts[i], pts[(i + 1) % 8])

	# Small dark squares at grid intersections (between 4 octagons)
	for ty in range(fy0 + 1, fy1):
		for tx in range(fx0 + 1, fx1):
			var ix := tx * ts
			var iz := ty * ts
			# Diamond-shaped square rotated 45 degrees
			_add_tri(dark, Vector3(ix, 0, iz - cut), Vector3(ix + cut, 0, iz), Vector3(ix, 0, iz + cut))
			_add_tri(dark, Vector3(ix, 0, iz - cut), Vector3(ix, 0, iz + cut), Vector3(ix - cut, 0, iz))


## Diamonds-in-squares: alternating cells with rotated diamond inscribed in square.
## Uses palette indices 0 (dark) and 1 (light) in checkerboard pattern.
static func _build_diamonds_squares_field(color_verts: Array[PackedVector3Array], fx0: int, fy0: int, fx1: int, fy1: int, ts: float) -> void:
	var dark := color_verts[0]
	var light := color_verts[1]

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
			var mt := Vector3(x + ts * 0.5, 0, z)
			var mr := Vector3(x + ts, 0, z + ts * 0.5)
			var mb := Vector3(x + ts * 0.5, 0, z + ts)
			var ml := Vector3(x, 0, z + ts * 0.5)

			var is_even := (((tx - fx0) + (ty - fy0)) % 2) == 0
			var diamond_buf: PackedVector3Array = dark if is_even else light
			var corner_buf: PackedVector3Array = light if is_even else dark

			# Diamond (rotated square)
			_add_tri(diamond_buf, mt, mr, mb)
			_add_tri(diamond_buf, mt, mb, ml)

			# 4 corner triangles
			_add_tri(corner_buf, tl, mt, ml)
			_add_tri(corner_buf, tr, mr, mt)
			_add_tri(corner_buf, br, mb, mr)
			_add_tri(corner_buf, bl, ml, mb)


## Polka dot field: dark background with small light dots in a grid pattern.
## Uses palette indices 0 (dark background) and 1 (light dots).
static func _build_polka_dot_field(color_verts: Array[PackedVector3Array], fx0: int, fy0: int, fx1: int, fy1: int, ts: float) -> void:
	var dark := color_verts[0]
	var light := color_verts[1]

	# Dark background
	for ty in range(fy0, fy1):
		for tx in range(fx0, fx1):
			_add_rect(dark, tx * ts, ty * ts, ts, ts)

	# Light dots — one per 3x3 tile block, centered
	var field_x0 := fx0 * ts
	var field_z0 := fy0 * ts
	var field_w := (fx1 - fx0) * ts
	var field_h := (fy1 - fy0) * ts
	var dot_spacing := ts * 3.0
	var dot_size := ts * 0.4
	var half_dot := dot_size * 0.5

	var dots_x := int(field_w / dot_spacing)
	var dots_z := int(field_h / dot_spacing)
	var margin_x := (field_w - dots_x * dot_spacing) * 0.5
	var margin_z := (field_h - dots_z * dot_spacing) * 0.5

	for dz in range(dots_z):
		for dx in range(dots_x):
			var cx := field_x0 + margin_x + (dx + 0.5) * dot_spacing
			var cz := field_z0 + margin_z + (dz + 0.5) * dot_spacing
			# Deterministic jitter
			var hash_n := (dx * 374761393 + dz * 668265263)
			hash_n = (hash_n ^ (hash_n >> 13)) * 1274126177
			hash_n = hash_n ^ (hash_n >> 16)
			var jitter := float(hash_n & 0x7FFFFFFF) / float(0x7FFFFFFF) - 0.5
			var jx := jitter * dot_spacing * 0.15
			var hash_n2 := ((dx + 97) * 374761393 + (dz + 53) * 668265263)
			hash_n2 = (hash_n2 ^ (hash_n2 >> 13)) * 1274126177
			hash_n2 = hash_n2 ^ (hash_n2 >> 16)
			var jz := (float(hash_n2 & 0x7FFFFFFF) / float(0x7FFFFFFF) - 0.5) * dot_spacing * 0.15

			var px := clampf(cx + jx - half_dot, field_x0, field_x0 + field_w - dot_size)
			var pz := clampf(cz + jz - half_dot, field_z0, field_z0 + field_h - dot_size)
			light.append(Vector3(px, 0.0005, pz))
			light.append(Vector3(px + dot_size, 0.0005, pz))
			light.append(Vector3(px + dot_size, 0.0005, pz + dot_size))
			light.append(Vector3(px, 0.0005, pz))
			light.append(Vector3(px + dot_size, 0.0005, pz + dot_size))
			light.append(Vector3(px, 0.0005, pz + dot_size))


## Star rosette: hexagram (6-pointed star) pattern on light background.
## Uses palette indices 0 (dark stars) and 1 (light background).
static func _build_star_rosette_field(color_verts: Array[PackedVector3Array], fx0: int, fy0: int, fx1: int, fy1: int, ts: float) -> void:
	var dark := color_verts[0]
	var light := color_verts[1]

	# Light background fill
	_build_solid_field(color_verts, fx0, fy0, fx1, fy1, ts, 1)

	# Each star occupies a 2x2 tile cell
	var cell_size := ts * 2.0
	var stars_x := (fx1 - fx0) / 2
	var stars_y := (fy1 - fy0) / 2

	for sy in range(stars_y):
		for sx in range(stars_x):
			var cx := (fx0 + sx * 2 + 1.0) * ts
			var cz := (fy0 + sy * 2 + 1.0) * ts
			var R := cell_size * 0.48
			var r := R * 0.5774  # R / sqrt(3)

			# 6 outer tips + 6 inner concave vertices
			var outer_pts: Array[Vector3] = []
			var inner_pts: Array[Vector3] = []
			for k in range(6):
				var angle_out := deg_to_rad(k * 60.0 - 90.0)
				var angle_in := deg_to_rad(k * 60.0 + 30.0 - 90.0)
				outer_pts.append(Vector3(cx + R * cos(angle_out), 0, cz + R * sin(angle_out)))
				inner_pts.append(Vector3(cx + r * cos(angle_in), 0, cz + r * sin(angle_in)))

			# 6 spike triangles
			for k in range(6):
				_add_tri(dark, outer_pts[k], inner_pts[k], inner_pts[(k + 5) % 6])

			# Inner hexagon
			var center := Vector3(cx, 0, cz)
			for k in range(6):
				_add_tri(dark, center, inner_pts[k], inner_pts[(k + 1) % 6])


## Wave/scale: overlapping semicircles in offset rows (fish-scale / imbrication).
## Uses palette indices 0 (dark) and 1 (light) in alternating rows.
static func _build_wave_scale_field(color_verts: Array[PackedVector3Array], fx0: int, fy0: int, fx1: int, fy1: int, ts: float) -> void:
	var dark := color_verts[0]
	var light := color_verts[1]

	# Light background fill
	_build_solid_field(color_verts, fx0, fy0, fx1, fy1, ts, 1)

	# Semicircle geometry
	var field_x0 := fx0 * ts
	var field_z0 := fy0 * ts
	var field_w := (fx1 - fx0) * ts
	var field_h := (fy1 - fy0) * ts

	var radius := ts * 2.0
	var row_height := radius
	var segments := 8  # segments per arc

	var cols_in_row := int(field_w / radius) + 2
	var rows_in_field := int(field_h / row_height) + 2

	for row in range(-1, rows_in_field + 1):
		var is_offset_row := (row % 2) == 1
		var offset_x := radius * 0.5 if is_offset_row else 0.0
		var cz := field_z0 + row * row_height

		# Alternate dark rows
		var target: PackedVector3Array = dark if (row % 2 == 0) else light

		for col in range(-1, cols_in_row + 1):
			var cx := field_x0 + col * radius + offset_x

			# Skip if outside field
			if cx + radius < field_x0 or cx - radius > field_x0 + field_w:
				continue
			if cz + radius < field_z0 or cz > field_z0 + field_h:
				continue

			# Semicircle as triangle fan (arc opens downward)
			for seg in range(segments):
				var a0 := PI * float(seg) / float(segments)
				var a1 := PI * float(seg + 1) / float(segments)
				var x0 := cx + cos(a0) * radius
				var z0 := cz + sin(a0) * radius
				var x1 := cx + cos(a1) * radius
				var z1 := cz + sin(a1) * radius
				target.append(Vector3(cx, 0, cz))
				target.append(Vector3(x0, 0, z0))
				target.append(Vector3(x1, 0, z1))
