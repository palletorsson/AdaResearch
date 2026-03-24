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
