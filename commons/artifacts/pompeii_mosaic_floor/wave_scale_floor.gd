# wave_scale_floor.gd
# Procedural Roman imbrication (fish-scale) floor — overlapping semicircles
# arranged in offset rows creating a wave/scale effect. Common in Roman baths
# and fountains. Built as ArrayMesh with dark, light, terracotta, grout surfaces.
#
# @identity
#   essence: a floor that carries the rhythmic geometry of Roman water architecture
#   desire: players look down and see overlapping arcs flowing like waves or scales
#   critical_parameter: scale_rows — number of semicircle rows on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: understanding that simple arc repetition with offset produces complex organic pattern
#   needs: [implemented] procedural mesh, border bands, imbrication semicircles
#   relationships: pattern_maker_station (web editor), pompeii_mosaic_floor (sibling)
#   truth: nature's fish scales and Roman mosaicists arrived at the same tiling independently

extends Node3D
class_name WaveScaleFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var scale_rows: int = 8
@export var segments_per_arc: int = 10
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var color_terra: Color = MosaicPalette.TERRACOTTA
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.04
@export_range(0.0, 1.0) var wear_level: float = 0.3

# Border widths: dark(2), light(1), dark(1)
@export var border_widths: Array[int] = [2, 1, 1]

var _mi: MeshInstance3D
#var _body: StaticBody3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	scale_rows = int(config.get("scale_rows", scale_rows))
	segments_per_arc = int(config.get("segments_per_arc", segments_per_arc))
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
	#if _body:
		#_body.queue_free()
		#_body = null

	# Border total width in tile units
	var border_each: int = 0
	for bw in border_widths:
		border_each += bw

	# Grid dimensions — tile size derived from short axis
	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	# Scale radius derived from available field area
	var total_short_tiles := scale_rows * 2 + border_each * 2
	var ts := short_m / float(total_short_tiles)  # tile size
	var total_long_tiles := int(round(long_m / ts))

	var gw: int = total_long_tiles if is_wide else total_short_tiles
	var gh: int = total_short_tiles if is_wide else total_long_tiles

	var fw := gw * ts
	var fh := gh * ts

	# Field region inside borders
	var fx0 := border_each
	var fy0 := border_each
	var fx1 := gw - border_each
	var fy1 := gh - border_each

	var field_w := (fx1 - fx0) * ts
	var field_h := (fy1 - fy0) * ts

	# Scale/semicircle radius — each semicircle spans 2 tile units wide
	var radius := ts * 2.0
	var row_height := radius  # vertical spacing between rows

	var grout_w := ts * grout_width_fraction

	# Vertex arrays per surface
	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var terra_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	# Helper: add a flat quad
	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	# ── 1. Border bands ──
	# Draw concentric rectangular border frames
	var inset: int = 0
	var border_colors := [color_dark, color_light, color_dark]
	for i in border_widths.size():
		var bw_tiles: int = border_widths[i]
		var bx := inset * ts
		var bz := inset * ts
		var bfw := (gw - inset * 2) * ts
		var bfh := (gh - inset * 2) * ts
		var band_w := bw_tiles * ts
		var col_idx := i % border_colors.size()
		var target_verts: PackedVector3Array
		if col_idx == 0 or col_idx == 2:
			target_verts = dark_verts
		else:
			target_verts = light_verts

		# Top band
		target_verts = _add_rect.call(target_verts, bx, bz, bfw, band_w)
		# Bottom band
		target_verts = _add_rect.call(target_verts, bx, bz + bfh - band_w, bfw, band_w)
		# Left band (between top and bottom)
		target_verts = _add_rect.call(target_verts, bx, bz + band_w, band_w, bfh - band_w * 2)
		# Right band
		target_verts = _add_rect.call(target_verts, bx + bfw - band_w, bz + band_w, band_w, bfh - band_w * 2)

		if col_idx == 0 or col_idx == 2:
			dark_verts = target_verts
		else:
			light_verts = target_verts

		inset += bw_tiles

	# ── 2. Field background (light fill) ──
	var field_x := fx0 * ts
	var field_z := fy0 * ts
	light_verts = _add_rect.call(light_verts, field_x, field_z, field_w, field_h)

	# ── 3. Imbrication (fish-scale) semicircles ──
	# Rows of semicircles, each row offset by half a circle width
	var cols_in_row := int(field_w / radius) + 2  # extra for clipping
	var rows_in_field := int(field_h / row_height) + 2

	var color_cycle := [color_dark, color_light, color_terra]

	for row in range(-1, rows_in_field + 1):
		var is_offset_row := (row % 2) == 1
		var offset_x := radius * 0.5 if is_offset_row else 0.0
		var cz := field_z + row * row_height  # center z of semicircle

		# Pick color for this row
		var row_color_idx := ((row % 3) + 3) % 3
		var row_color: Color = color_cycle[row_color_idx]

		# Select target vertex array
		var target: PackedVector3Array
		if row_color == color_dark:
			target = dark_verts
		elif row_color == color_terra:
			target = terra_verts
		else:
			target = light_verts

		var grout_target := grout_verts

		for col in range(-1, cols_in_row + 1):
			var cx := field_x + col * radius + offset_x  # center x

			# Clip: skip if completely outside field
			if cx + radius < field_x or cx - radius > field_x + field_w:
				continue
			if cz + radius < field_z or cz > field_z + field_h:
				continue

			# Draw semicircle as triangle fan (arc opens downward, +z)
			# Center is at top of semicircle, arc sweeps from left to right
			for seg in range(segments_per_arc):
				var a0 := PI * float(seg) / float(segments_per_arc)
				var a1 := PI * float(seg + 1) / float(segments_per_arc)

				# Semicircle opens downward: angles from 0 to PI
				# 0 = right, PI = left
				var x0 := cx + cos(a0) * radius
				var z0 := cz + sin(a0) * radius
				var x1 := cx + cos(a1) * radius
				var z1 := cz + sin(a1) * radius

				# Clip triangle vertices to field bounds
				var p0 := Vector3(x0, 0, z0)
				var p1 := Vector3(x1, 0, z1)
				var pc := Vector3(cx, 0, cz)

				target.append(pc)
				target.append(p0)
				target.append(p1)

			# Grout arc outline for this semicircle
			if grout_w > 0.001:
				for seg in range(segments_per_arc):
					var a0 := PI * float(seg) / float(segments_per_arc)
					var a1 := PI * float(seg + 1) / float(segments_per_arc)

					var r_inner := radius - grout_w * 0.5
					var r_outer := radius + grout_w * 0.5

					var ix0 := cx + cos(a0) * r_inner
					var iz0 := cz + sin(a0) * r_inner
					var ox0 := cx + cos(a0) * r_outer
					var oz0 := cz + sin(a0) * r_outer
					var ix1 := cx + cos(a1) * r_inner
					var iz1 := cz + sin(a1) * r_inner
					var ox1 := cx + cos(a1) * r_outer
					var oz1 := cz + sin(a1) * r_outer

					grout_target.append(Vector3(ix0, 0.001, iz0))
					grout_target.append(Vector3(ox0, 0.001, oz0))
					grout_target.append(Vector3(ox1, 0.001, oz1))
					grout_target.append(Vector3(ix0, 0.001, iz0))
					grout_target.append(Vector3(ox1, 0.001, oz1))
					grout_target.append(Vector3(ix1, 0.001, iz1))

		# Write back
		if row_color == color_dark:
			dark_verts = target
		elif row_color == color_terra:
			terra_verts = target
		else:
			light_verts = target
		grout_verts = grout_target

	# ── 4. Border grout lines ──
	if grout_w > 0.001:
		var half := grout_w * 0.5
		# Outer border grout lines
		for i_b in range(border_widths.size() + 1):
			var offset_tiles: int = 0
			for j in range(i_b):
				offset_tiles += border_widths[j]
			var bx := offset_tiles * ts
			var bz := offset_tiles * ts
			var bfw := (gw - offset_tiles * 2) * ts
			var bfh := (gh - offset_tiles * 2) * ts
			# Top
			grout_verts = _add_rect.call(grout_verts, bx, bz - half, bfw, grout_w)
			# Bottom
			grout_verts = _add_rect.call(grout_verts, bx, bz + bfh - half, bfw, grout_w)
			# Left
			grout_verts = _add_rect.call(grout_verts, bx - half, bz, grout_w, bfh)
			# Right
			grout_verts = _add_rect.call(grout_verts, bx + bfw - half, bz, grout_w, bfh)


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
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(color_terra, wear_level))

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

	# ── StaticBody3D + CollisionShape3D ──
	#_body = StaticBody3D.new()
	var col_shape := CollisionShape3D.new()
	#var box := BoxShape3D.new()
	#box.size = Vector3(fw, 0.01, fh)
	col_shape.shape = box
	#_body.add_child(col_shape)
	#_body.position = Vector3(0, 0.0, 0)
	#add_child(_body)

	print("[WaveScaleFloor] Built %dx%d grid, radius=%.3f (%d dark, %d light, %d terra, %d grout tris)" % [
		gw, gh, radius,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		terra_verts.size() / 3,
		grout_verts.size() / 3,
	])
