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

## AXIS — WHICH STATE OF THE RECORD this floor is shown in. Tiles repeat; mosaics do not.
## A mosaic is a grid its maker kept deviating from — for the setting-out, for a later
## repair, for the line people walked, for what the ground finally kept — and the floor is
## the document of those deviations, not the pattern. So the axis is not "which pattern"
## (that is what the sibling floors are for) but WHAT THE FLOOR ADMITS ABOUT ITS OWN HISTORY.
## Shared word for word with [[san_michele_mosaic_floor]], so two floors in the same room
## cannot disagree about what state they are in.
##
##   design   as set out — the pattern with no deviation admitted. THE LEGACY LINEAGE,
##            byte for byte: this value adds nothing at all.
##   datum    the setting-out struck through — red-ochre guide lines showing: twelve radii
##            from the centre punch, four concentric circles at the zone radii, and the
##            generating Archimedean curve itself drawn as one thin line. The drawing under
##            the floor, on top of the floor.
##   repair   later hands — a whole 60-degree sector relaid in the wrong stone (a cool grey
##            against the sand) at four times the tessera size, plus two small rectangular
##            patches. The spiral runs into the sector and stops; nobody matched it.
##   wear     the line people walked — a broad mottled band of bleached, dished surface
##            crossing the disc, plus a rubbed-out ring at the centre where they stood. The
##            spiral reads THROUGH the scour rather than under a blanket.
##   loss     as excavated — six irregular lacunae down to the dark bedding, one of them
##            biting the border at the rim, each ringed by its own broken edge.
##
## `wear_level` above is the SHADER's weathering (dust, fade, hairline cracks, everywhere at
## once). `wear` here is GEOMETRY in one place: the traffic line. They are orthogonal and
## the default of each is unchanged by the other.
@export var condition: String = "design"
const CONDITIONS: PackedStringArray = ["design", "datum", "repair", "wear", "loss"]

## Seed for the irregularity `repair`, `wear` and `loss` need. NOTHING rolled in this
## artifact before, so the honest default is a fixed number: every render of a value is the
## same picture and the sweep measures the axis, not the noise. -1 randomises per build.
## The stream is a LOCAL RandomNumberGenerator, so the global stream is never touched and
## `design` never draws at all.
@export var condition_seed: int = 20260802

## Condition palette — the tones a conservator would name, not the mosaicist's.
const COND_OCHRE := Color(0.60, 0.24, 0.16)    # sinopia: the red-ochre setting-out line
const COND_STONE := Color(0.50, 0.49, 0.46)    # the wrong stone — a cool grey that does not match
const COND_JOINT := Color(0.26, 0.24, 0.21)    # coarse mortar between relaid tesserae
const COND_PALE := Color(0.91, 0.88, 0.83)     # bleached, dished, walked-out surface
const COND_BED := Color(0.15, 0.13, 0.11)      # the bedding under a floor that is gone
const COND_RUBBLE := Color(0.40, 0.36, 0.30)   # the broken edge around a lacuna

var _mi: MeshInstance3D
var _cond_mi: MeshInstance3D
#var _body: StaticBody3D


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
	# Condition, read the same way station_wall reads upkeep: normalise, and keep the
	# current value on a word the artifact cannot build. An unknown token must never
	# silently become a wildcard.
	var cond: String = str(config.get("condition", condition)).strip_edges().to_lower()
	condition = cond if CONDITIONS.has(cond) else condition
	condition_seed = int(config.get("condition_seed", condition_seed))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()
		_mi = null
	#if _body:
		#_body.queue_free()
		#_body = null

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


	# ── Z-fighting fix: offset each surface to a distinct Y layer ──
	# Hierarchy: grout(-0.001) < dark(0.0) < light(0.001) < accent/terra(0.002) < border(0.003)
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts
	# Light is the FULL background disc here (same as san_michele) — must
	# sit at the BOTTOM of the y-stack or it occludes the dark spiral
	# bands above it. Order: grout(-0.001) < light(0.0) < dark(0.001) <
	# accent(0.002).
	light_verts = _offset_y.call(light_verts, 0.0)
	dark_verts = _offset_y.call(dark_verts, 0.001)
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
	_mi.position = Vector3(0, 0.005, 0)
	add_child(_mi)

	# ── StaticBody3D with CollisionShape3D for floor collider ──
	#_body = StaticBody3D.new()
	#var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = floor_radius
	shape.height = 0.01
	#col.shape = shape
	#col.position = Vector3(0, 0.005, 0)
	#_body.add_child(col)
	#add_child(_body)

	print("[SpiralMosaicFloor] Built %.1f rotations (%.2fm radius) — %d dark tris, %d light tris, %d accent tris, %d grout tris" % [
		num_rotations, floor_radius,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		accent_verts.size() / 3,
		grout_verts.size() / 3,
	])

	# CONDITION, appended LAST so every vertex, surface, y-offset and child above is
	# untouched on the legacy path. "design" adds no node at all.
	_build_condition()


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


# ── CONDITION ────────────────────────────────────────────────────────────────
# One axis, five states of the record, all of it drawn into ONE extra MeshInstance3D
# standing 0.008 m above the floor plate — clear of the accent layer at 0.007, and never
# outside the disc. That matters twice: the AABB (and so the sweep's framing) is identical
# picture to picture, and the legacy mesh is not touched by a single vertex.

func _build_condition() -> void:
	if _cond_mi:
		_cond_mi.queue_free()
		_cond_mi = null

	var ochre := PackedVector3Array()    # the setting-out struck in red
	var stone := PackedVector3Array()    # relaid tesserae, the wrong stone
	var joint := PackedVector3Array()    # mortar under and between them
	var pale := PackedVector3Array()     # scoured, walked-out surface
	var bed := PackedVector3Array()      # what is under a floor that is gone
	var rubble := PackedVector3Array()   # the broken edge of a lacuna

	var rng := RandomNumberGenerator.new()
	if condition_seed < 0:
		rng.randomize()
	else:
		rng.seed = condition_seed

	match condition:
		"design":
			pass                                  # the legacy lineage — nothing is added
		"datum":
			_cond_datum(ochre)
		"repair":
			_cond_repair(stone, joint, rng)
		"wear":
			_cond_wear(pale, rng)
		"loss":
			_cond_loss(bed, rubble, rng)
		_:
			pass                                  # an unknown word reads as "design"

	var arr := ArrayMesh.new()
	_cond_surface(arr, rubble, COND_RUBBLE)
	_cond_surface(arr, bed, COND_BED)
	_cond_surface(arr, joint, COND_JOINT)
	_cond_surface(arr, stone, COND_STONE)
	_cond_surface(arr, pale, COND_PALE)
	_cond_surface(arr, ochre, COND_OCHRE)
	if arr.get_surface_count() == 0:
		return

	_cond_mi = MeshInstance3D.new()
	_cond_mi.mesh = arr
	_cond_mi.position = Vector3(0, 0.008, 0)
	add_child(_cond_mi)


## DATUM — the setting-out struck through the finished floor. Twelve radii from the centre
## punch, the four circles the compass swung, and the generating Archimedean curve itself
## drawn one tessera wide over the band it produced. Red ochre on sand: the drawing under
## the floor, put back on top of it.
func _cond_datum(v: PackedVector3Array) -> void:
	var big_r: float = floor_radius
	var y: float = 0.0009
	var lw: float = maxf(big_r * 0.011, 0.004)
	var inner: float = maxf(big_r - _cond_border_total(), 0.05)
	var rose: float = inner * 0.08

	for k in range(12):
		var a: float = TAU * float(k) / 12.0
		var dir: Vector2 = Vector2(cos(a), sin(a))
		_cond_seg(v, dir * (rose * 0.6), dir * (big_r * 0.985), lw, y)

	var rings: Array[float] = [rose, inner * 0.5, inner, big_r * 0.985]
	for r in rings:
		_cond_ring(v, r, lw * 0.8, 84, y)

	var sb: float = (inner - rose) / maxf(num_rotations * TAU, 0.001)
	var steps: int = maxi(int(num_rotations * 72.0), 24)
	var dth: float = (num_rotations * TAU) / float(steps)
	var prev: Vector2 = Vector2(rose, 0.0)
	for s in range(1, steps + 1):
		var th: float = float(s) * dth
		var rr: float = rose + sb * th
		var cur: Vector2 = Vector2(cos(th) * rr, sin(th) * rr)
		_cond_seg(v, prev, cur, lw * 0.55, y)
		prev = cur

	_cond_disc(v, Vector2.ZERO, maxf(rose * 0.55, 0.012), 16, y)


## REPAIR — later hands. A whole 60-degree sector is lifted and relaid in a cool grey that
## does not match the sand, at four times the tessera size, in courses that follow the
## SECTOR and not the spiral: the band runs into the patch and simply stops. Two small
## rectangular patches sit elsewhere at their own angles, because nobody lined them up.
func _cond_repair(stone: PackedVector3Array, joint: PackedVector3Array,
		rng: RandomNumberGenerator) -> void:
	var big_r: float = floor_radius
	var lim: float = big_r * 0.94
	var inner: float = maxf(big_r - _cond_border_total(), 0.05)

	var a0: float = 0.92
	var a1: float = 1.98
	var r0: float = inner * 0.28
	var r1: float = lim
	for i in range(22):
		var t0: float = lerpf(a0, a1, float(i) / 22.0)
		var t1: float = lerpf(a0, a1, float(i + 1) / 22.0)
		_cond_quad(joint,
			Vector2(cos(t0) * r0, sin(t0) * r0),
			Vector2(cos(t1) * r0, sin(t1) * r0),
			Vector2(cos(t1) * r1, sin(t1) * r1),
			Vector2(cos(t0) * r1, sin(t0) * r1), 0.0)

	var cell: float = 0.042
	var rows: int = maxi(int((r1 - r0) / cell), 2)
	for ri in range(rows):
		var rr0: float = r0 + (r1 - r0) * float(ri) / float(rows)
		var rr1: float = r0 + (r1 - r0) * float(ri + 1) / float(rows)
		var mid: float = (rr0 + rr1) * 0.5
		var cols: int = maxi(int((a1 - a0) * mid / cell), 2)
		for ci in range(cols):
			var t0: float = lerpf(a0, a1, float(ci) / float(cols))
			var t1: float = lerpf(a0, a1, float(ci + 1) / float(cols))
			_cond_tessera_polar(stone, t0, t1, rr0, rr1, 0.0006)

	_cond_patch_rect(stone, joint, Vector2(-big_r * 0.44, big_r * 0.14),
		Vector2(big_r * 0.36, big_r * 0.24), rng.randf_range(-0.55, 0.55), lim)
	_cond_patch_rect(stone, joint, Vector2(big_r * 0.12, -big_r * 0.54),
		Vector2(big_r * 0.28, big_r * 0.20), rng.randf_range(-0.55, 0.55), lim)


## WEAR — the line people walked. A broad band crossing the disc, mottled rather than
## solid, so the spiral reads THROUGH the scour the way a rubbed floor does rather than
## disappearing under a blanket. The centre, where a person on a round floor stands and
## turns, is rubbed out on its own.
func _cond_wear(pale: PackedVector3Array, rng: RandomNumberGenerator) -> void:
	var big_r: float = floor_radius
	var lim: float = big_r * 0.95
	var y: float = 0.0003
	var phi: float = 0.62
	var dir: Vector2 = Vector2(cos(phi), sin(phi))
	var nrm: Vector2 = Vector2(-dir.y, dir.x)
	var half: float = big_r * 0.30
	var step: float = 0.021
	var tile: float = 0.016
	var n: int = maxi(int(big_r * 2.0 / step), 8)
	for ix in range(-n, n + 1):
		for iz in range(-n, n + 1):
			var p: Vector2 = Vector2(float(ix), float(iz)) * step
			if p.length() > lim:
				continue
			var across: float = absf(p.dot(nrm))
			var along: float = absf(p.dot(dir)) / maxf(lim, 0.01)
			var band: float = half * (1.0 - 0.30 * along)
			var take: float = 0.0
			if across < band:
				take = 1.0 - (across / maxf(band, 0.001)) * 0.75
			if p.length() < big_r * 0.20:
				take = maxf(take, 0.85)
			if take <= 0.02:
				continue
			if rng.randf() > take:
				continue
			var h: float = tile * 0.5
			_cond_quad(pale, p + Vector2(-h, -h), p + Vector2(h, -h),
				p + Vector2(h, h), p + Vector2(-h, h), y)


## LOSS — as excavated. Six irregular lacunae down to the dark bedding, each ringed by the
## broken edge where the tesserae let go, and one more at the rim that has taken a bite out
## of the border with it. Everything is clamped to the disc, so the floor loses area
## without the artifact changing size.
func _cond_loss(bed: PackedVector3Array, rubble: PackedVector3Array,
		rng: RandomNumberGenerator) -> void:
	var big_r: float = floor_radius
	var lim: float = big_r * 0.99
	for i in range(6):
		var a: float = rng.randf_range(0.0, TAU)
		var d: float = rng.randf_range(big_r * 0.12, big_r * 0.68)
		var c: Vector2 = Vector2(cos(a), sin(a)) * d
		var rad: float = rng.randf_range(big_r * 0.11, big_r * 0.26)
		_cond_blob(rubble, c, rad * 1.16, 0.26, rng, 0.0, lim)
		_cond_blob(bed, c, rad, 0.22, rng, 0.0006, lim)

	var ra: float = rng.randf_range(0.0, TAU)
	var rc: Vector2 = Vector2(cos(ra), sin(ra)) * (big_r * 0.86)
	_cond_blob(rubble, rc, big_r * 0.34, 0.30, rng, 0.0, lim)
	_cond_blob(bed, rc, big_r * 0.29, 0.26, rng, 0.0006, lim)


# ── condition primitives ─────────────────────────────────────────────────────

func _cond_border_total() -> float:
	var total: float = 0.0
	for bw in border_bands:
		total += float(bw) * border_tile_size
	return total


func _cond_surface(arr: ArrayMesh, verts: PackedVector3Array, c: Color) -> void:
	if verts.size() == 0:
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arr.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	arr.surface_set_material(arr.get_surface_count() - 1,
		MosaicPalette.create_material(c, wear_level))


func _cond_quad(v: PackedVector3Array, a: Vector2, b: Vector2, c: Vector2, d: Vector2,
		y: float) -> void:
	v.append(Vector3(a.x, y, a.y))
	v.append(Vector3(b.x, y, b.y))
	v.append(Vector3(c.x, y, c.y))
	v.append(Vector3(a.x, y, a.y))
	v.append(Vector3(c.x, y, c.y))
	v.append(Vector3(d.x, y, d.y))


func _cond_seg(v: PackedVector3Array, p0: Vector2, p1: Vector2, half_w: float,
		y: float) -> void:
	var d: Vector2 = p1 - p0
	if d.length() < 0.00001:
		return
	var n: Vector2 = Vector2(-d.y, d.x).normalized() * half_w
	_cond_quad(v, p0 - n, p1 - n, p1 + n, p0 + n, y)


func _cond_ring(v: PackedVector3Array, radius: float, half_w: float, segs: int,
		y: float) -> void:
	var ri: float = maxf(radius - half_w, 0.0)
	var ro: float = radius + half_w
	for i in range(segs):
		var a0: float = TAU * float(i) / float(segs)
		var a1: float = TAU * float(i + 1) / float(segs)
		_cond_quad(v,
			Vector2(cos(a0) * ri, sin(a0) * ri),
			Vector2(cos(a1) * ri, sin(a1) * ri),
			Vector2(cos(a1) * ro, sin(a1) * ro),
			Vector2(cos(a0) * ro, sin(a0) * ro), y)


func _cond_disc(v: PackedVector3Array, centre: Vector2, radius: float, segs: int,
		y: float) -> void:
	for i in range(segs):
		var a0: float = TAU * float(i) / float(segs)
		var a1: float = TAU * float(i + 1) / float(segs)
		v.append(Vector3(centre.x, y, centre.y))
		v.append(Vector3(centre.x + cos(a0) * radius, y, centre.y + sin(a0) * radius))
		v.append(Vector3(centre.x + cos(a1) * radius, y, centre.y + sin(a1) * radius))


## An irregular lobe, every rim vertex clamped inside `lim` so a lacuna can eat the border
## without ever growing the artifact's bounding box.
func _cond_blob(v: PackedVector3Array, centre: Vector2, radius: float, jitter: float,
		rng: RandomNumberGenerator, y: float, lim: float) -> void:
	var segs: int = 18
	var rs: Array[float] = []
	for i in range(segs):
		rs.append(radius * (1.0 - jitter + rng.randf() * jitter * 2.0))
	var mid: Vector2 = _cond_clamp(centre, lim)
	for i in range(segs):
		var a0: float = TAU * float(i) / float(segs)
		var a1: float = TAU * float(i + 1) / float(segs)
		var p0: Vector2 = _cond_clamp(centre + Vector2(cos(a0), sin(a0)) * rs[i], lim)
		var p1: Vector2 = _cond_clamp(
			centre + Vector2(cos(a1), sin(a1)) * rs[(i + 1) % segs], lim)
		v.append(Vector3(mid.x, y, mid.y))
		v.append(Vector3(p0.x, y, p0.y))
		v.append(Vector3(p1.x, y, p1.y))


func _cond_clamp(p: Vector2, lim: float) -> Vector2:
	if p.length() <= lim:
		return p
	return p.normalized() * lim


## One relaid tessera in polar coordinates, inset so the coarse joint shows around it.
func _cond_tessera_polar(v: PackedVector3Array, t0: float, t1: float, r0: float, r1: float,
		y: float) -> void:
	var mid: float = (r0 + r1) * 0.5
	var ang_in: float = 0.006 / maxf(mid, 0.02)
	var ta: float = t0 + ang_in
	var tb: float = t1 - ang_in
	var ra: float = r0 + 0.006
	var rb: float = r1 - 0.006
	if tb <= ta or rb <= ra:
		return
	_cond_quad(v,
		Vector2(cos(ta) * ra, sin(ta) * ra),
		Vector2(cos(tb) * ra, sin(tb) * ra),
		Vector2(cos(tb) * rb, sin(tb) * rb),
		Vector2(cos(ta) * rb, sin(ta) * rb), y)


## A rectangular patch set at its own angle: bedding first, then coarse tesserae inset on
## top. Skipped entirely if any corner would leave the disc.
func _cond_patch_rect(stone: PackedVector3Array, joint: PackedVector3Array, centre: Vector2,
		size: Vector2, rot: float, lim: float) -> void:
	var ca: float = cos(rot)
	var sa: float = sin(rot)
	var hx: float = size.x * 0.5
	var hz: float = size.y * 0.5
	var local: Array[Vector2] = [
		Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(hx, hz), Vector2(-hx, hz)]
	var world: Array[Vector2] = []
	for p in local:
		world.append(centre + Vector2(p.x * ca - p.y * sa, p.x * sa + p.y * ca))
	for w in world:
		if w.length() > lim:
			return
	_cond_quad(joint, world[0], world[1], world[2], world[3], 0.0)

	var cell: float = 0.038
	var nx: int = maxi(int(size.x / cell), 2)
	var nz: int = maxi(int(size.y / cell), 2)
	var inset: float = 0.006
	for ix in range(nx):
		for iz in range(nz):
			var x0: float = -hx + size.x * float(ix) / float(nx) + inset
			var x1: float = -hx + size.x * float(ix + 1) / float(nx) - inset
			var z0: float = -hz + size.y * float(iz) / float(nz) + inset
			var z1: float = -hz + size.y * float(iz + 1) / float(nz) - inset
			if x1 <= x0 or z1 <= z0:
				continue
			_cond_quad(stone,
				centre + Vector2(x0 * ca - z0 * sa, x0 * sa + z0 * ca),
				centre + Vector2(x1 * ca - z0 * sa, x1 * sa + z0 * ca),
				centre + Vector2(x1 * ca - z1 * sa, x1 * sa + z1 * ca),
				centre + Vector2(x0 * ca - z1 * sa, x0 * sa + z1 * ca), 0.0006)
