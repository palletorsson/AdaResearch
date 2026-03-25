# spiral_mosaic_floor.gd
# Procedural Pompeii mosaic floor — Archimedean spiral pattern.
# A single continuous spiral path winds from the center outward.
# Dark spiral band on light background, widening as it goes out.
# Ancient symbol found in many cultures, from Newgrange to Roman mosaics.
#
# @identity
#   essence: a floor that traces the oldest curve known to human hands
#   desire: players look down and see the spiral path that cultures worldwide discovered independently
#   critical_parameter: num_rotations — number of full spiral turns
#   triggers: instantiation or apply_grid_config
#   emerges: the understanding that growth and motion share one equation: r = a + b*theta
#   needs: [implemented] procedural mesh, border bands, Archimedean spiral, center rosette
#   relationships: pompeii_mosaic_floor (sibling pattern), mosaic_palette (shared colors)
#   truth: the spiral is the shape of becoming — always the same, always further from where it began

extends Node3D
class_name SpiralMosaicFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")

@export var floor_radius: float = 0.55
@export var num_rotations: float = 4.5          # full turns of the spiral
@export var spiral_band_fraction: float = 0.35  # fraction of pitch occupied by dark band
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
	num_rotations = float(config.get("num_rotations", num_rotations))
	spiral_band_fraction = float(config.get("spiral_band_fraction", spiral_band_fraction))
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

	# Total border width
	var border_total: float = 0.0
	for bw in border_bands:
		border_total += bw * border_tile_size

	var inner_radius := floor_radius - border_total
	if inner_radius < 0.05:
		inner_radius = 0.05

	# ── 1. Center rosette (terracotta accent) ──
	# Small 8-petal rosette at the spiral origin
	var rosette_radius := inner_radius * 0.08
	var rosette_petals: int = 8

	# Inner disc
	for i in rosette_petals:
		var a0 := TAU * float(i) / float(rosette_petals)
		var a1 := TAU * float(i + 1) / float(rosette_petals)
		accent_verts.append(Vector3(0, 0, 0))
		accent_verts.append(Vector3(cos(a0) * rosette_radius * 0.5, 0, sin(a0) * rosette_radius * 0.5))
		accent_verts.append(Vector3(cos(a1) * rosette_radius * 0.5, 0, sin(a1) * rosette_radius * 0.5))

	# Petals — pointed triangles extending outward
	for i in rosette_petals:
		var a0 := TAU * float(i) / float(rosette_petals)
		var a_mid := TAU * (float(i) + 0.5) / float(rosette_petals)
		var a1 := TAU * float(i + 1) / float(rosette_petals)
		accent_verts.append(Vector3(cos(a0) * rosette_radius * 0.5, 0, sin(a0) * rosette_radius * 0.5))
		accent_verts.append(Vector3(cos(a_mid) * rosette_radius, 0, sin(a_mid) * rosette_radius))
		accent_verts.append(Vector3(cos(a1) * rosette_radius * 0.5, 0, sin(a1) * rosette_radius * 0.5))

	# ── 2. Archimedean spiral field ──
	# r = a + b * theta
	# a = rosette_radius (start radius)
	# b = (inner_radius - rosette_radius) / (num_rotations * TAU) (growth per radian)
	var spiral_a := rosette_radius
	var spiral_b := (inner_radius - rosette_radius) / (num_rotations * TAU)

	# We sample the spiral at many angular steps and build quad strips.
	# The spiral defines the CENTER of the dark band. The band width grows
	# proportionally: band_half = spiral_band_fraction * pitch / 2
	# where pitch = spiral_b * TAU (distance between successive turns).
	var pitch := spiral_b * TAU  # radial distance per full turn

	# Angular resolution — enough steps for smooth curves
	var steps_per_rotation: int = 120
	var total_steps: int = int(num_rotations * float(steps_per_rotation))
	var d_theta := (num_rotations * TAU) / float(total_steps)

	# Fill the background first as a light disc
	var bg_segments: int = 72
	for seg in bg_segments:
		var a0 := TAU * float(seg) / float(bg_segments)
		var a1 := TAU * float(seg + 1) / float(bg_segments)
		# Full disc from rosette to inner_radius
		light_verts.append(Vector3(cos(a0) * rosette_radius, 0, sin(a0) * rosette_radius))
		light_verts.append(Vector3(cos(a1) * rosette_radius, 0, sin(a1) * rosette_radius))
		light_verts.append(Vector3(cos(a0) * inner_radius, 0, sin(a0) * inner_radius))

		light_verts.append(Vector3(cos(a1) * rosette_radius, 0, sin(a1) * rosette_radius))
		light_verts.append(Vector3(cos(a1) * inner_radius, 0, sin(a1) * inner_radius))
		light_verts.append(Vector3(cos(a0) * inner_radius, 0, sin(a0) * inner_radius))

	# Dark spiral band as quad strips along the Archimedean curve
	for step in total_steps:
		var theta0 := float(step) * d_theta
		var theta1 := float(step + 1) * d_theta

		var r0 := spiral_a + spiral_b * theta0
		var r1 := spiral_a + spiral_b * theta1

		# Band half-width grows proportionally with radius
		var band_half0 := spiral_band_fraction * pitch * 0.5
		var band_half1 := spiral_band_fraction * pitch * 0.5

		# Clamp to not exceed inner_radius or go below rosette
		var r0_inner := maxf(rosette_radius, r0 - band_half0)
		var r0_outer := minf(inner_radius, r0 + band_half0)
		var r1_inner := maxf(rosette_radius, r1 - band_half1)
		var r1_outer := minf(inner_radius, r1 + band_half1)

		# Skip degenerate quads
		if r0_outer - r0_inner < 0.0001 and r1_outer - r1_inner < 0.0001:
			continue

		var ca0 := cos(theta0)
		var sa0 := sin(theta0)
		var ca1 := cos(theta1)
		var sa1 := sin(theta1)

		# Quad: inner0, inner1, outer1, outer0
		var p0i := Vector3(ca0 * r0_inner, 0, sa0 * r0_inner)
		var p0o := Vector3(ca0 * r0_outer, 0, sa0 * r0_outer)
		var p1i := Vector3(ca1 * r1_inner, 0, sa1 * r1_inner)
		var p1o := Vector3(ca1 * r1_outer, 0, sa1 * r1_outer)

		# Two triangles for the quad
		dark_verts.append(p0i)
		dark_verts.append(p1i)
		dark_verts.append(p0o)

		dark_verts.append(p1i)
		dark_verts.append(p1o)
		dark_verts.append(p0o)

	# ── 3. Grout on spiral edges ──
	var grout_w := floor_radius * grout_width_fraction
	if grout_w > 0.001:
		var grout_half := grout_w * 0.5

		# Inner edge of spiral band
		for step in total_steps:
			var theta0 := float(step) * d_theta
			var theta1 := float(step + 1) * d_theta

			var r0 := spiral_a + spiral_b * theta0
			var r1 := spiral_a + spiral_b * theta1

			var band_half := spiral_band_fraction * pitch * 0.5

			# Inner grout edge
			var r0_ge := maxf(rosette_radius, r0 - band_half)
			var r1_ge := maxf(rosette_radius, r1 - band_half)

			if r0_ge > rosette_radius + 0.001 and r1_ge > rosette_radius + 0.001:
				_add_spiral_grout_segment(grout_verts, theta0, theta1, r0_ge, r1_ge, grout_half)

			# Outer grout edge
			var r0_go := minf(inner_radius, r0 + band_half)
			var r1_go := minf(inner_radius, r1 + band_half)

			if r0_go < inner_radius - 0.001 and r1_go < inner_radius - 0.001:
				_add_spiral_grout_segment(grout_verts, theta0, theta1, r0_go, r1_go, grout_half)

		# Concentric grout circle at rosette boundary
		_add_ring_grout(grout_verts, rosette_radius, grout_half, 48)

		# Concentric grout circle at inner_radius boundary
		_add_ring_grout(grout_verts, inner_radius, grout_half, 72)

		# Grout circles at each border band boundary
		var br := inner_radius
		for bi in border_bands.size():
			var bw_tiles: int = border_bands[bi]
			br += bw_tiles * border_tile_size
			_add_ring_grout(grout_verts, br, grout_half, 72)

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

	# ── StaticBody3D with CollisionShape3D for floor collider ──
	_body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = floor_radius
	shape.height = 0.01
	col.shape = shape
	col.position = Vector3(0, 0.005, 0)
	_body.add_child(col)
	add_child(_body)

	print("[SpiralMosaicFloor] Built %.1f rotations (%.2fm radius) — %d dark tris, %d light tris, %d accent tris, %d grout tris" % [
		num_rotations, floor_radius,
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


func _add_spiral_grout_segment(verts: PackedVector3Array, theta0: float, theta1: float, r0: float, r1: float, half_w: float) -> void:
	# Grout quad strip following the spiral edge
	var ca0 := cos(theta0)
	var sa0 := sin(theta0)
	var ca1 := cos(theta1)
	var sa1 := sin(theta1)

	var r0i := r0 - half_w
	var r0o := r0 + half_w
	var r1i := r1 - half_w
	var r1o := r1 + half_w

	verts.append(Vector3(ca0 * r0i, 0.001, sa0 * r0i))
	verts.append(Vector3(ca1 * r1i, 0.001, sa1 * r1i))
	verts.append(Vector3(ca0 * r0o, 0.001, sa0 * r0o))

	verts.append(Vector3(ca1 * r1i, 0.001, sa1 * r1i))
	verts.append(Vector3(ca1 * r1o, 0.001, sa1 * r1o))
	verts.append(Vector3(ca0 * r0o, 0.001, sa0 * r0o))
