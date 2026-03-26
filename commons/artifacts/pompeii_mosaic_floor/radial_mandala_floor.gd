# radial_mandala_floor.gd
# Procedural Pompeii mosaic floor — concentric radial mandala pattern.
# Center 6-pointed star/rosette in terracotta, surrounded by concentric rings
# of alternating dark/light triangles radiating outward. Each ring has more
# triangles than the previous, and consecutive rings offset so triangles interlock.
#
# @identity
#   essence: a floor that radiates sacred geometry from a single center point
#   desire: players look down and see the mandala logic of Roman cosmological floors
#   critical_parameter: num_rings — number of concentric triangle rings
#   triggers: instantiation or apply_grid_config
#   emerges: the understanding that radial symmetry is tessellation freed from the grid
#   needs: [implemented] procedural mesh, border bands, radial triangle rings, center star
#   relationships: pompeii_mosaic_floor (sibling pattern), mosaic_palette (shared colors)
#   truth: every mandala begins with a point and the courage to draw a circle around it

extends Node3D
class_name RadialMandalaFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")

@export var floor_radius: float = 0.55
@export var num_rings: int = 5
@export var base_segments: int = 6          # segments in innermost ring (6 = hexagonal star)
@export var segments_per_ring_mult: int = 2 # each ring adds this many more segments per base segment
@export var border_bands: Array[int] = [2, 1, 1]  # dark, light, dark widths in border tile units
@export var border_tile_size: float = 0.025
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var color_accent: Color = MosaicPalette.TERRACOTTA
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.04
@export_range(0.0, 1.0) var wear_level: float = 0.3

var _mi: MeshInstance3D
#var _body: StaticBody3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	floor_radius = float(config.get("floor_radius", floor_radius))
	num_rings = int(config.get("num_rings", num_rings))
	base_segments = int(config.get("base_segments", base_segments))
	wear_level = float(config.get("wear_level", wear_level))
	var bb = config.get("border_bands", null)
	if bb is Array:
		border_bands.clear()
		for v in bb:
			border_bands.append(int(v))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()
		_mi = null
	#if _body:
		#_body.queue_free()
		_body = null

	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var accent_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	# Total border width
	var border_total: float = 0.0
	for bw in border_bands:
		border_total += bw * border_tile_size

	var inner_radius := floor_radius - border_total
	if inner_radius < 0.05:
		inner_radius = 0.05

	# ── 1. Radial mandala pattern ──
	# Center star radius — proportional to inner_radius
	var star_radius := inner_radius * 0.22
	var ring_width := (inner_radius - star_radius) / float(num_rings)

	# ── 1a. Center 6-pointed star (terracotta accent) ──
	# Draw as 6 triangles forming a hexagonal rosette
	for i in base_segments:
		var angle0 := TAU * float(i) / float(base_segments)
		var angle1 := TAU * float(i + 1) / float(base_segments)
		accent_verts.append(Vector3(0, 0, 0))
		accent_verts.append(Vector3(cos(angle0) * star_radius, 0, sin(angle0) * star_radius))
		accent_verts.append(Vector3(cos(angle1) * star_radius, 0, sin(angle1) * star_radius))

	# Star points — extend every other vertex outward to form the 6-pointed star
	var star_outer := star_radius * 1.6
	for i in base_segments:
		var angle0 := TAU * float(i) / float(base_segments)
		var angle_mid := TAU * (float(i) + 0.5) / float(base_segments)
		var angle1 := TAU * float(i + 1) / float(base_segments)
		# Pointed triangle extending outward between two hex vertices
		accent_verts.append(Vector3(cos(angle0) * star_radius, 0, sin(angle0) * star_radius))
		accent_verts.append(Vector3(cos(angle_mid) * star_outer, 0, sin(angle_mid) * star_outer))
		accent_verts.append(Vector3(cos(angle1) * star_radius, 0, sin(angle1) * star_radius))

	# ── 1b. Concentric rings of alternating triangles ──
	for ring in num_rings:
		var r_inner := star_radius + ring * ring_width
		var r_outer := star_radius + (ring + 1) * ring_width

		# Number of triangle pairs in this ring
		var n_seg: int = base_segments * (ring + 1) * segments_per_ring_mult
		# Ensure even number for clean alternation
		if n_seg % 2 != 0:
			n_seg += 1

		var angle_step := TAU / float(n_seg)

		# Offset: alternate rings shift by half a segment
		var angle_offset := 0.0
		if ring % 2 == 1:
			angle_offset = angle_step * 0.5

		for seg in n_seg:
			var a0 := angle_offset + seg * angle_step
			var a1 := angle_offset + (seg + 1) * angle_step

			var p_inner0 := Vector3(cos(a0) * r_inner, 0, sin(a0) * r_inner)
			var p_inner1 := Vector3(cos(a1) * r_inner, 0, sin(a1) * r_inner)
			var p_outer0 := Vector3(cos(a0) * r_outer, 0, sin(a0) * r_outer)
			var p_outer1 := Vector3(cos(a1) * r_outer, 0, sin(a1) * r_outer)

			# Alternation: even segments start dark-inward, odd start light-inward
			# Ring parity flips the whole ring
			var is_dark: bool
			if ring % 2 == 0:
				is_dark = (seg % 2 == 0)
			else:
				is_dark = (seg % 2 == 1)

			# Inner triangle: inner0, inner1, outer0
			var inner_tri_verts: PackedVector3Array
			# Outer triangle: inner1, outer1, outer0
			var outer_tri_verts: PackedVector3Array

			if is_dark:
				inner_tri_verts = dark_verts
				outer_tri_verts = light_verts
			else:
				inner_tri_verts = light_verts
				outer_tri_verts = dark_verts

			# Inner triangle
			inner_tri_verts.append(p_inner0)
			inner_tri_verts.append(p_inner1)
			inner_tri_verts.append(p_outer0)

			# Outer triangle
			outer_tri_verts.append(p_inner1)
			outer_tri_verts.append(p_outer1)
			outer_tri_verts.append(p_outer0)

			# Write back
			if is_dark:
				dark_verts = inner_tri_verts
				light_verts = outer_tri_verts
			else:
				light_verts = inner_tri_verts
				dark_verts = outer_tri_verts

	# ── 2. Border bands (concentric ring borders) ──
	var band_r := inner_radius
	for bi in border_bands.size():
		var bw_tiles: int = border_bands[bi]
		var band_width := bw_tiles * border_tile_size
		var band_r_outer := band_r + band_width

		# Choose color based on band index: dark(0), light(1), dark(2)
		var band_verts: PackedVector3Array
		if bi % 2 == 0:
			band_verts = dark_verts
		else:
			band_verts = light_verts

		# Draw as ring of triangles
		var band_segments: int = 60
		for seg in band_segments:
			var a0 := TAU * float(seg) / float(band_segments)
			var a1 := TAU * float(seg + 1) / float(band_segments)

			var pi0 := Vector3(cos(a0) * band_r, 0, sin(a0) * band_r)
			var pi1 := Vector3(cos(a1) * band_r, 0, sin(a1) * band_r)
			var po0 := Vector3(cos(a0) * band_r_outer, 0, sin(a0) * band_r_outer)
			var po1 := Vector3(cos(a1) * band_r_outer, 0, sin(a1) * band_r_outer)

			band_verts.append(pi0)
			band_verts.append(pi1)
			band_verts.append(po0)

			band_verts.append(pi1)
			band_verts.append(po1)
			band_verts.append(po0)

		if bi % 2 == 0:
			dark_verts = band_verts
		else:
			light_verts = band_verts

		band_r = band_r_outer

	# ── 3. Grout lines (radial + concentric) ──
	var grout_w := floor_radius * grout_width_fraction
	if grout_w > 0.001:
		var half := grout_w * 0.5

		# Concentric circle grout at each ring boundary
		var grout_circle_segments: int = 72
		# At star boundary
		_add_ring_grout(grout_verts, star_radius, half, grout_circle_segments)
		# At each ring boundary
		for ring in num_rings:
			var r := star_radius + (ring + 1) * ring_width
			_add_ring_grout(grout_verts, r, half, grout_circle_segments)
		# At each border band boundary
		var br := inner_radius
		for bi in border_bands.size():
			var bw_tiles: int = border_bands[bi]
			br += bw_tiles * border_tile_size
			_add_ring_grout(grout_verts, br, half, grout_circle_segments)

		# Radial grout lines from center through each ring
		for ring in num_rings:
			var r_inner := star_radius + ring * ring_width
			var r_outer := star_radius + (ring + 1) * ring_width
			var n_seg: int = base_segments * (ring + 1) * segments_per_ring_mult
			if n_seg % 2 != 0:
				n_seg += 1
			var angle_step := TAU / float(n_seg)
			var angle_offset := 0.0
			if ring % 2 == 1:
				angle_offset = angle_step * 0.5
			for seg in n_seg:
				var a := angle_offset + seg * angle_step
				_add_radial_grout(grout_verts, a, r_inner, r_outer, half)


	# ── Z-fighting fix: offset each surface to a distinct Y layer ──
	# Hierarchy: grout(-0.001) < dark(0.0) < light(0.001) < accent/terra(0.002) < border(0.003)
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts
	dark_verts = _offset_y.call(dark_verts, 0.0)
	light_verts = _offset_y.call(light_verts, 0.001)
	accent_verts = _offset_y.call(accent_verts, 0.002)
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

	if accent_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = accent_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(color_accent, wear_level))

	if grout_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = grout_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(grout_color, wear_level))

	_mi = MeshInstance3D.new()
	_mi.mesh = arr_mesh
	_mi.position = Vector3(0, 0.005, 0)  # Center at origin, y=0.005
	add_child(_mi)

	# ── StaticBody3D with CollisionShape3D for floor collider ──
	#_body = StaticBody3D.new()
	#var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = floor_radius
	shape.height = 0.01
	col.shape = shape
	col.position = Vector3(0, 0.005, 0)
	#_body.add_child(col)
	#add_child(_body)

	print("[RadialMandalaFloor] Built %d rings, %d base segments (%.2fm radius) — %d dark tris, %d light tris, %d accent tris, %d grout tris" % [
		num_rings, base_segments, floor_radius,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		accent_verts.size() / 3,
		grout_verts.size() / 3,
	])


func _add_ring_grout(verts: PackedVector3Array, radius: float, half_w: float, segments: int) -> void:
	for seg in segments:
		var a0 := TAU * float(seg) / float(segments)
		var a1 := TAU * float(seg + 1) / float(segments)
		var ri := radius - half_w
		var ro := radius + half_w
		verts.append(Vector3(cos(a0) * ri, 0.001, sin(a0) * ri))
		verts.append(Vector3(cos(a1) * ri, 0.001, sin(a1) * ri))
		verts.append(Vector3(cos(a0) * ro, 0.001, sin(a0) * ro))
		verts.append(Vector3(cos(a1) * ri, 0.001, sin(a1) * ri))
		verts.append(Vector3(cos(a1) * ro, 0.001, sin(a1) * ro))
		verts.append(Vector3(cos(a0) * ro, 0.001, sin(a0) * ro))


func _add_radial_grout(verts: PackedVector3Array, angle: float, r_inner: float, r_outer: float, half_w: float) -> void:
	# Thin quad along a radial line
	var ca := cos(angle)
	var sa := sin(angle)
	# Perpendicular offset
	var px := -sa * half_w
	var pz := ca * half_w
	var x0 := ca * r_inner
	var z0 := sa * r_inner
	var x1 := ca * r_outer
	var z1 := sa * r_outer
	verts.append(Vector3(x0 + px, 0.001, z0 + pz))
	verts.append(Vector3(x1 + px, 0.001, z1 + pz))
	verts.append(Vector3(x1 - px, 0.001, z1 - pz))
	verts.append(Vector3(x0 + px, 0.001, z0 + pz))
	verts.append(Vector3(x1 - px, 0.001, z1 - pz))
	verts.append(Vector3(x0 - px, 0.001, z0 - pz))
