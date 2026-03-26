# honeycomb_hex_floor.gd
# Procedural Pompeii honeycomb/hexagonal mosaic floor.
# Regular hexagons tessellated across the field with decorative terracotta
# crosses at every 3rd hexagon center. Dark grout outlines all hexagons.
#
# @identity
#   essence: a floor that carries the geometry of nature's most efficient tiling
#   desire: players look down and see the same pattern bees discovered millennia ago
#   critical_parameter: hex_radius — size of each hexagon
#   triggers: instantiation or apply_grid_config
#   emerges: the understanding that hexagons tile the plane with minimal perimeter
#   needs: [implemented] procedural mesh, border bands, hex grid, decorative crosses
#   relationships: pattern_maker_station (web editor), mosaic_editor (composition)
#   truth: the hexagonal lattice is the most efficient partition of the plane

extends Node3D
class_name HoneycombHexFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var hex_radius: float = 0.04
@export var border_widths: Array[int] = [2, 1, 1]
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var color_terracotta: Color = MosaicPalette.TERRACOTTA
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
	hex_radius = float(config.get("hex_radius", hex_radius))
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

	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var terra_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	var fw := floor_size.x
	var fh := floor_size.y

	# Border tile size (based on hex_radius for consistent scale)
	var border_ts := hex_radius * 0.8  # border tile unit

	# Calculate total border inset
	var border_each: float = 0.0
	for bw in border_widths:
		border_each += bw * border_ts

	# Inner field bounds
	var field_x0 := border_each
	var field_z0 := border_each
	var field_x1 := fw - border_each
	var field_z1 := fh - border_each

	# ── 1. Border bands ──
	# Draw concentric rectangular border frames
	var inset: float = 0.0
	for i in border_widths.size():
		var bw_m: float = border_widths[i] * border_ts
		var is_light := (i % 2 == 1)
		var band_color_verts: PackedVector3Array
		if is_light:
			band_color_verts = light_verts
		else:
			band_color_verts = dark_verts

		var ox := inset
		var oz := inset
		var bw_total := fw - inset * 2.0
		var bh_total := fh - inset * 2.0

		# Top band
		band_color_verts = _add_rect(band_color_verts, ox, oz, bw_total, bw_m)
		# Bottom band
		band_color_verts = _add_rect(band_color_verts, ox, oz + bh_total - bw_m, bw_total, bw_m)
		# Left band
		band_color_verts = _add_rect(band_color_verts, ox, oz + bw_m, bw_m, bh_total - bw_m * 2.0)
		# Right band
		band_color_verts = _add_rect(band_color_verts, ox + bw_total - bw_m, oz + bw_m, bw_m, bh_total - bw_m * 2.0)

		if is_light:
			light_verts = band_color_verts
		else:
			dark_verts = band_color_verts

		inset += bw_m

	# ── 2. Background fill for field area ──
	light_verts = _add_rect(light_verts, field_x0, field_z0, field_x1 - field_x0, field_z1 - field_z0)

	# ── 3. Hexagonal grid ──
	# Flat-top hexagons: width = 2*R, height = sqrt(3)*R
	var R := hex_radius
	var hex_w := R * 2.0
	var hex_h := R * sqrt(3.0)
	var col_step := hex_w * 0.75  # horizontal distance between hex centers
	var row_step := hex_h         # vertical distance between hex centers

	# Grout line width
	var grout_w := R * grout_width_fraction * 2.0

	# Pre-compute hex corner offsets (flat-top hexagon)
	var hex_corners: Array[Vector2] = []
	for k in 6:
		var angle := PI / 3.0 * k
		hex_corners.append(Vector2(cos(angle) * R, sin(angle) * R))

	# Iterate hex grid
	var col := 0
	var hex_index := 0
	var cx := field_x0 + R
	while cx < field_x1 - R * 0.5:
		var row := 0
		var offset_z := hex_h * 0.5 if (col % 2 == 1) else 0.0
		var cz := field_z0 + hex_h * 0.5 + offset_z
		while cz < field_z1 - hex_h * 0.3:
			# Draw hexagon as 6 triangles (fan from center)
			# Alternate coloring: checkerboard on hex grid
			var is_dark_hex := ((col + row) % 2 == 0)

			for k in 6:
				var k_next := (k + 1) % 6
				var p0 := Vector3(cx, 0, cz)
				var p1 := Vector3(cx + hex_corners[k].x, 0, cz + hex_corners[k].y)
				var p2 := Vector3(cx + hex_corners[k_next].x, 0, cz + hex_corners[k_next].y)

				if is_dark_hex:
					dark_verts.append(p0)
					dark_verts.append(p1)
					dark_verts.append(p2)
				else:
					light_verts.append(p0)
					light_verts.append(p1)
					light_verts.append(p2)

			# Grout outline for each hexagon edge
			if grout_w > 0.001:
				for k in 6:
					var k_next := (k + 1) % 6
					var p1 := Vector2(cx + hex_corners[k].x, cz + hex_corners[k].y)
					var p2 := Vector2(cx + hex_corners[k_next].x, cz + hex_corners[k_next].y)
					grout_verts = _add_line_quad(grout_verts, p1, p2, grout_w)

			# Decorative cross at every 3rd hexagon
			if hex_index % 3 == 0:
				var cross_r := R * 0.25  # cross arm length
				var cross_w := R * 0.08  # cross arm half-width
				# 4 small triangles forming a cross/flower shape
				# North arm
				terra_verts.append(Vector3(cx - cross_w, 0.001, cz))
				terra_verts.append(Vector3(cx + cross_w, 0.001, cz))
				terra_verts.append(Vector3(cx, 0.001, cz - cross_r))
				# South arm
				terra_verts.append(Vector3(cx - cross_w, 0.001, cz))
				terra_verts.append(Vector3(cx + cross_w, 0.001, cz))
				terra_verts.append(Vector3(cx, 0.001, cz + cross_r))
				# East arm
				terra_verts.append(Vector3(cx, 0.001, cz - cross_w))
				terra_verts.append(Vector3(cx, 0.001, cz + cross_w))
				terra_verts.append(Vector3(cx + cross_r, 0.001, cz))
				# West arm
				terra_verts.append(Vector3(cx, 0.001, cz - cross_w))
				terra_verts.append(Vector3(cx, 0.001, cz + cross_w))
				terra_verts.append(Vector3(cx - cross_r, 0.001, cz))

			hex_index += 1
			row += 1
			cz += row_step

		col += 1
		cx += col_step


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
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(color_terracotta, wear_level))

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

	# StaticBody3D + CollisionShape3D for floor collision
	#_body = StaticBody3D.new()
	var col_shape := CollisionShape3D.new()
	#var box := BoxShape3D.new()
	#box.size = Vector3(fw, 0.01, fh)
	col_shape.shape = box
	#_body.add_child(col_shape)
	#_body.position = Vector3(0, 0.0, 0)
	#add_child(_body)

	print("[HoneycombHexFloor] Built hex grid (%d dark tris, %d light tris, %d terra tris, %d grout tris)" % [
		dark_verts.size() / 3,
		light_verts.size() / 3,
		terra_verts.size() / 3,
		grout_verts.size() / 3,
	])


func _add_rect(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
	verts.append(Vector3(x, 0, z))
	verts.append(Vector3(x + w, 0, z))
	verts.append(Vector3(x + w, 0, z + h))
	verts.append(Vector3(x, 0, z))
	verts.append(Vector3(x + w, 0, z + h))
	verts.append(Vector3(x, 0, z + h))
	return verts


func _add_line_quad(verts: PackedVector3Array, a: Vector2, b: Vector2, width: float) -> PackedVector3Array:
	# Create a thin quad along the line from a to b
	var dir := (b - a).normalized()
	var perp := Vector2(-dir.y, dir.x) * width * 0.5
	var p0 := a + perp
	var p1 := a - perp
	var p2 := b - perp
	var p3 := b + perp
	verts.append(Vector3(p0.x, 0.001, p0.y))
	verts.append(Vector3(p1.x, 0.001, p1.y))
	verts.append(Vector3(p2.x, 0.001, p2.y))
	verts.append(Vector3(p0.x, 0.001, p0.y))
	verts.append(Vector3(p2.x, 0.001, p2.y))
	verts.append(Vector3(p3.x, 0.001, p3.y))
	return verts
