# pelta_shield_floor.gd
# Procedural Roman pelta (Amazon shield) mosaic floor — interlocking crescent
# shapes arranged in rows with half-unit offsets. Built as ArrayMesh with
# dark, light, terracotta, grout surfaces.
#
# @identity
#   essence: a floor carrying the defensive geometry of interlocking shields
#   desire: players look down and see the rhythm of paired crescents guarding space
#   critical_parameter: pelta_rows — number of pelta rows on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: understanding that subtraction (concave bite) creates interlocking form
#   needs: [implemented] procedural mesh, border bands, pelta semicircles with concave bites
#   relationships: wave_scale_floor (sibling), pattern_maker_station (web editor)
#   truth: the Amazon shield motif spread across the Roman world as border and field pattern

extends Node3D
class_name PeltaShieldFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var pelta_rows: int = 6
@export var segments_per_arc: int = 12
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var color_terra: Color = MosaicPalette.TERRACOTTA
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.04
@export_range(0.0, 1.0) var wear_level: float = 0.3

# Border widths: dark(2), light(1), dark(1)
@export var border_widths: Array[int] = [2, 1, 1]

var _mi: MeshInstance3D
var _body: StaticBody3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	pelta_rows = int(config.get("pelta_rows", pelta_rows))
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
	if _body:
		_body.queue_free()
		_body = null

	# Border total width in tile units
	var border_each: int = 0
	for bw in border_widths:
		border_each += bw

	# Grid dimensions — tile size derived from short axis
	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	# Each pelta pair occupies ~2 tile units tall
	var total_short_tiles := pelta_rows * 2 + border_each * 2
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
	var field_x := fx0 * ts
	var field_z := fy0 * ts

	# Pelta geometry parameters
	# The outer semicircle radius
	var pelta_radius := ts * 2.0
	# The concave bite radius (smaller semicircle subtracted from flat side)
	var bite_radius := pelta_radius * 0.45
	var row_height := pelta_radius  # vertical spacing between rows

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

	# ── 1. Border bands (dark, light, dark) ──
	var inset: int = 0
	var border_colors_list := [color_dark, color_light, color_dark]
	for i in border_widths.size():
		var bw_tiles: int = border_widths[i]
		var bx := inset * ts
		var bz := inset * ts
		var bfw := (gw - inset * 2) * ts
		var bfh := (gh - inset * 2) * ts
		var band_w := bw_tiles * ts
		var col_idx := i % border_colors_list.size()
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
	light_verts = _add_rect.call(light_verts, field_x, field_z, field_w, field_h)

	# ── 3. Pelta field — interlocking crescent/shield shapes ──
	# Each pelta: outer semicircle (opens downward) minus a concave bite from the flat side.
	# Peltas alternate dark/terra and interlock in offset rows.
	var cols_in_row := int(field_w / pelta_radius) + 2
	var rows_in_field := int(field_h / row_height) + 2

	for row in range(-1, rows_in_field + 1):
		var is_offset_row := (row % 2) == 1
		var offset_x := pelta_radius * 0.5 if is_offset_row else 0.0
		var cz := field_z + row * row_height  # center z of pelta

		# Alternate dark/terracotta by row
		var use_dark := (row % 2) == 0
		var pelta_color: Color = color_dark if use_dark else color_terra

		var target: PackedVector3Array
		if pelta_color == color_dark:
			target = dark_verts
		else:
			target = terra_verts

		var grout_target := grout_verts

		for col in range(-1, cols_in_row + 1):
			var cx := field_x + col * pelta_radius + offset_x

			# Clip: skip if completely outside field
			if cx + pelta_radius < field_x or cx - pelta_radius > field_x + field_w:
				continue
			if cz + pelta_radius < field_z or cz > field_z + field_h:
				continue

			# Draw outer semicircle as triangle fan (opens downward, +z)
			for seg in range(segments_per_arc):
				var a0 := PI * float(seg) / float(segments_per_arc)
				var a1 := PI * float(seg + 1) / float(segments_per_arc)

				var x0 := cx + cos(a0) * pelta_radius
				var z0 := cz + sin(a0) * pelta_radius
				var x1 := cx + cos(a1) * pelta_radius
				var z1 := cz + sin(a1) * pelta_radius

				target.append(Vector3(cx, 0, cz))
				target.append(Vector3(x0, 0, z0))
				target.append(Vector3(x1, 0, z1))

			# Subtract concave bite: draw a semicircle in the OPPOSITE color
			# at the flat side (top of the pelta), opening upward (-z)
			# This creates the shield/mushroom shape
			var bite_cz := cz  # bite center at the flat edge
			var bite_color: Color = color_light  # bite reveals background
			var bite_target: PackedVector3Array = light_verts

			for seg in range(segments_per_arc):
				# Bite semicircle opens upward (angles from PI to 2*PI)
				var a0 := PI + PI * float(seg) / float(segments_per_arc)
				var a1 := PI + PI * float(seg + 1) / float(segments_per_arc)

				var x0 := cx + cos(a0) * bite_radius
				var z0 := bite_cz + sin(a0) * bite_radius
				var x1 := cx + cos(a1) * bite_radius
				var z1 := bite_cz + sin(a1) * bite_radius

				bite_target.append(Vector3(cx, 0, bite_cz))
				bite_target.append(Vector3(x0, 0, z0))
				bite_target.append(Vector3(x1, 0, z1))

			light_verts = bite_target

			# Grout: outer arc outline
			if grout_w > 0.001:
				for seg in range(segments_per_arc):
					var a0 := PI * float(seg) / float(segments_per_arc)
					var a1 := PI * float(seg + 1) / float(segments_per_arc)

					var r_inner := pelta_radius - grout_w * 0.5
					var r_outer := pelta_radius + grout_w * 0.5

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

				# Grout: bite arc outline
				for seg in range(segments_per_arc):
					var a0 := PI + PI * float(seg) / float(segments_per_arc)
					var a1 := PI + PI * float(seg + 1) / float(segments_per_arc)

					var r_inner := bite_radius - grout_w * 0.5
					var r_outer := bite_radius + grout_w * 0.5

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
		if pelta_color == color_dark:
			dark_verts = target
		else:
			terra_verts = target
		grout_verts = grout_target

	# ── 4. Border grout lines ──
	if grout_w > 0.001:
		var half := grout_w * 0.5
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
	_body = StaticBody3D.new()
	var col_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(fw, 0.01, fh)
	col_shape.shape = box
	_body.add_child(col_shape)
	_body.position = Vector3(0, 0.0, 0)
	add_child(_body)

	print("[PeltaShieldFloor] Built %dx%d grid, radius=%.3f (%d dark, %d light, %d terra, %d grout tris)" % [
		gw, gh, pelta_radius,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		terra_verts.size() / 3,
		grout_verts.size() / 3,
	])
