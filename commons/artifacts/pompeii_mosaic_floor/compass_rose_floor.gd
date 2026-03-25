# compass_rose_floor.gd
# Procedural compass rose / wind rose mosaic floor — 16-pointed star built from
# alternating dark/light triangular wedges radiating from center. Inner ring of
# 8 narrow points (dark/terracotta), outer ring of 8 wider points (dark/light).
# Circular border bands around the star. Small circle at center.
#
# @identity
#   essence: a floor that orients the player within the geometry of navigation
#   desire: players look down and see the mariner's compass that guided Renaissance voyages
#   critical_parameter: floor_radius — radius of the compass rose disc
#   triggers: instantiation or apply_grid_config
#   emerges: the understanding that direction is a human overlay on continuous space
#   needs: [implemented] procedural mesh, border bands, 16-point star, center disc
#   relationships: radial_mandala_floor (sibling radial pattern), mosaic_palette (shared colors)
#   truth: every compass rose admits that the world has no inherent up — only agreements

extends Node3D
class_name CompassRoseFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")

@export var floor_radius: float = 0.55
@export var center_circle_fraction: float = 0.08
@export var cardinal_tip_fraction: float = 0.92     # cardinal points reach this far
@export var intercardinal_tip_fraction: float = 0.55 # intercardinal points reach this far
@export var border_bands: Array[int] = [2, 1, 1]
@export var border_tile_size: float = 0.025
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var color_accent: Color = MosaicPalette.TERRACOTTA
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.04
@export_range(0.0, 1.0) var wear_level: float = 0.3

var _mi: MeshInstance3D
var _body: StaticBody3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	floor_radius = float(config.get("floor_radius", floor_radius))
	center_circle_fraction = float(config.get("center_circle_fraction", center_circle_fraction))
	cardinal_tip_fraction = float(config.get("cardinal_tip_fraction", cardinal_tip_fraction))
	intercardinal_tip_fraction = float(config.get("intercardinal_tip_fraction", intercardinal_tip_fraction))
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
	if _body:
		_body.queue_free()
		_body = null

	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var accent_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	var border_total: float = 0.0
	for bw in border_bands:
		border_total += bw * border_tile_size

	var inner_radius := floor_radius - border_total
	if inner_radius < 0.05:
		inner_radius = 0.05

	var center_r := inner_radius * center_circle_fraction
	var cardinal_tip_r := inner_radius * cardinal_tip_fraction
	var intercardinal_tip_r := inner_radius * intercardinal_tip_fraction

	# The compass rose has 16 wedges. Each wedge is a triangular sector from center.
	# Wedge boundaries are at angles: 0, TAU/16, 2*TAU/16, ...
	# Cardinal directions (N, NE, E, SE, S, SW, W, NW) are at wedge MIDPOINTS.
	#
	# Structure per pair of wedges (one dark, one light) centered on a direction:
	#   - Cardinal directions (every other pair): the wedge pair extends to cardinal_tip_r
	#   - Intercardinal directions: the wedge pair extends to intercardinal_tip_r
	#
	# Each wedge is split along its center line into a dark half and a light half.
	# This creates the classic compass rose alternation.

	var num_directions: int = 16  # 8 cardinal + 8 intercardinal
	var direction_angle := TAU / float(num_directions)
	# Each direction occupies one wedge sector of TAU/16

	# ── 1. Center circle (terracotta accent) ──
	var center_segments: int = 32
	for i in center_segments:
		var a0 := TAU * float(i) / float(center_segments)
		var a1 := TAU * float(i + 1) / float(center_segments)
		accent_verts.append(Vector3(0, 0, 0))
		accent_verts.append(Vector3(cos(a0) * center_r, 0, sin(a0) * center_r))
		accent_verts.append(Vector3(cos(a1) * center_r, 0, sin(a1) * center_r))

	# ── 2. Star wedges ──
	# For each of the 16 directions, draw a wedge from center to its tip radius.
	# Each wedge is split into left-half and right-half with alternating colors.
	# Direction 0 = N (up/+Z), then every 22.5 degrees.
	# Even directions (0,2,4,...) = cardinal, odd = intercardinal.
	for d in num_directions:
		var dir_angle := d * direction_angle  # center angle of this direction
		var half := direction_angle * 0.5
		var left_edge := dir_angle - half
		var right_edge := dir_angle + half

		var is_cardinal := (d % 2 == 0)
		var tip_r: float = cardinal_tip_r if is_cardinal else intercardinal_tip_r

		# The wedge shape: triangle from center to tip, with base on center_r arc.
		# Left half-wedge: from center line to left edge
		# Right half-wedge: from center line to right edge

		# Color assignment: alternating pattern
		# d=0: left=dark, right=light
		# d=1: left=light, right=dark (if intercardinal, use accent instead of light)
		# d=2: left=dark, right=light
		# etc.

		var left_verts: PackedVector3Array
		var right_verts: PackedVector3Array

		if d % 4 == 0:
			# Primary cardinal (N, E, S, W): dark left, light right
			left_verts = dark_verts
			right_verts = light_verts
		elif d % 4 == 2:
			# Secondary cardinal (NE, SE, SW, NW): light left, dark right
			left_verts = light_verts
			right_verts = dark_verts
		elif d % 4 == 1:
			# Intercardinal: accent left, dark right
			left_verts = accent_verts
			right_verts = dark_verts
		else:  # d % 4 == 3
			# Intercardinal: dark left, accent right
			left_verts = dark_verts
			right_verts = accent_verts

		# Tip point
		var tip := Vector3(cos(dir_angle) * tip_r, 0, sin(dir_angle) * tip_r)
		# Center point (on center circle at dir_angle)
		var center_pt := Vector3(cos(dir_angle) * center_r, 0, sin(dir_angle) * center_r)
		# Edge points on center circle
		var left_base := Vector3(cos(left_edge) * center_r, 0, sin(left_edge) * center_r)
		var right_base := Vector3(cos(right_edge) * center_r, 0, sin(right_edge) * center_r)

		# Left half: triangle center_pt -> left_base -> tip
		left_verts.append(center_pt)
		left_verts.append(left_base)
		left_verts.append(tip)

		# Right half: triangle center_pt -> tip -> right_base
		right_verts.append(center_pt)
		right_verts.append(tip)
		right_verts.append(right_base)

		# Write back (GDScript array assignment semantics)
		if d % 4 == 0:
			dark_verts = left_verts
			light_verts = right_verts
		elif d % 4 == 2:
			light_verts = left_verts
			dark_verts = right_verts
		elif d % 4 == 1:
			accent_verts = left_verts
			dark_verts = right_verts
		else:
			dark_verts = left_verts
			accent_verts = right_verts

	# ── 3. Background fill: light disc from star outline to inner_radius ──
	# The star tips don't reach inner_radius (except maybe cardinals).
	# Fill the space between the star silhouette and the inner_radius circle.
	# For each direction, fill from tip outward to the inner_radius arc.
	var fill_arc_segments: int = 6
	for d in num_directions:
		var dir_angle := d * direction_angle
		var half := direction_angle * 0.5
		var left_edge := dir_angle - half
		var right_edge := dir_angle + half

		var is_cardinal := (d % 2 == 0)
		var tip_r: float = cardinal_tip_r if is_cardinal else intercardinal_tip_r

		if tip_r >= inner_radius:
			continue  # No gap to fill

		var tip := Vector3(cos(dir_angle) * tip_r, 0, sin(dir_angle) * tip_r)

		# Fill arc from left_edge to right_edge at inner_radius, fanned from tip
		for s in fill_arc_segments:
			var a0 := left_edge + (right_edge - left_edge) * float(s) / float(fill_arc_segments)
			var a1 := left_edge + (right_edge - left_edge) * float(s + 1) / float(fill_arc_segments)
			var p0 := Vector3(cos(a0) * inner_radius, 0, sin(a0) * inner_radius)
			var p1 := Vector3(cos(a1) * inner_radius, 0, sin(a1) * inner_radius)
			light_verts.append(tip)
			light_verts.append(p0)
			light_verts.append(p1)

		# Fill side triangles: from tip to adjacent edges at inner_radius
		# Left edge: triangle from left_base (at tip_r) to inner_radius at left_edge
		# Actually, fill the gap between adjacent tips
		var ir_left := Vector3(cos(left_edge) * inner_radius, 0, sin(left_edge) * inner_radius)
		var ir_right := Vector3(cos(right_edge) * inner_radius, 0, sin(right_edge) * inner_radius)
		var edge_left := Vector3(cos(left_edge) * tip_r, 0, sin(left_edge) * tip_r)
		var edge_right := Vector3(cos(right_edge) * tip_r, 0, sin(right_edge) * tip_r)

		# Quad from edge at tip_r to edge at inner_radius on left side
		light_verts.append(edge_left)
		light_verts.append(ir_left)
		light_verts.append(tip)

		light_verts.append(edge_right)
		light_verts.append(tip)
		light_verts.append(ir_right)

	# Also fill the gaps between adjacent direction tips at different radii
	for d in num_directions:
		var dir_angle := d * direction_angle
		var next_d := (d + 1) % num_directions
		var next_angle := next_d * direction_angle
		var edge_angle := dir_angle + direction_angle * 0.5  # = boundary between d and d+1

		var is_cardinal := (d % 2 == 0)
		var next_is_cardinal := (next_d % 2 == 0)
		var tip_r: float = cardinal_tip_r if is_cardinal else intercardinal_tip_r
		var next_tip_r: float = cardinal_tip_r if next_is_cardinal else intercardinal_tip_r

		# If both tips are at the same radius, no gap at the boundary
		var min_r := minf(tip_r, next_tip_r)
		var max_r := maxf(tip_r, next_tip_r)

		if max_r > min_r + 0.001:
			# There's a gap between the shorter tip's edge and the taller tip's edge
			# Fill with light from min_r to max_r at the boundary angle
			var p_short := Vector3(cos(edge_angle) * min_r, 0, sin(edge_angle) * min_r)
			var p_tall := Vector3(cos(edge_angle) * max_r, 0, sin(edge_angle) * max_r)

			# Which direction has the taller tip?
			var tall_angle: float = dir_angle if tip_r > next_tip_r else next_angle
			var tall_tip := Vector3(cos(tall_angle) * max_r, 0, sin(tall_angle) * max_r)

			# Triangle from short boundary point to tall boundary point to tall tip
			light_verts.append(p_short)
			light_verts.append(p_tall)
			light_verts.append(tall_tip)

	# ── 4. Border bands (concentric ring borders) ──
	var band_r := inner_radius
	for bi in border_bands.size():
		var bw_tiles: int = border_bands[bi]
		var band_width := bw_tiles * border_tile_size
		var band_r_outer := band_r + band_width

		var band_verts: PackedVector3Array
		if bi % 2 == 0:
			band_verts = dark_verts
		else:
			band_verts = light_verts

		var band_segments: int = 64
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

	# ── 5. Grout lines ──
	var grout_w := floor_radius * grout_width_fraction
	if grout_w > 0.001:
		var half := grout_w * 0.5
		var grout_circle_segments: int = 72

		# Concentric grout circles
		_add_ring_grout(grout_verts, center_r, half, grout_circle_segments)
		_add_ring_grout(grout_verts, inner_radius, half, grout_circle_segments)

		# Radial grout: 16 spoke lines at wedge boundaries
		for d in num_directions:
			var a := d * direction_angle
			_add_radial_grout(grout_verts, a, center_r * 0.3, inner_radius, half * 0.7)

		# Additional radial grout at wedge edges (between directions)
		for d in num_directions:
			var a := d * direction_angle + direction_angle * 0.5
			var is_cardinal := (d % 2 == 0)
			var tip_r: float = cardinal_tip_r if is_cardinal else intercardinal_tip_r
			_add_radial_grout(grout_verts, a, center_r, tip_r, half * 0.5)

		# Border band boundary grout
		var br := inner_radius
		for bi in border_bands.size():
			var bw_tiles: int = border_bands[bi]
			br += bw_tiles * border_tile_size
			_add_ring_grout(grout_verts, br, half, grout_circle_segments)

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
	_mi.position = Vector3(0, 0.005, 0)
	add_child(_mi)

	_body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = floor_radius
	shape.height = 0.01
	col.shape = shape
	col.position = Vector3(0, 0.005, 0)
	_body.add_child(col)
	add_child(_body)

	print("[CompassRoseFloor] Built 16-point star (%.2fm radius) — %d dark tris, %d light tris, %d accent tris, %d grout tris" % [
		floor_radius,
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
	var ca := cos(angle)
	var sa := sin(angle)
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
