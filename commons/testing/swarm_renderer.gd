extends RefCounted
class_name SwarmRenderer

## swarm_renderer.gd  —  Tier 3a (impostor swarm)
##
## Takes a list of (CritterDNA, world_position) pairs and renders the
## whole crowd as ONE MultiMeshInstance3D of capsule impostors. Each
## member's:
##   • position  → per-instance translation
##   • dna.scale × dna.segments × 0.4 → per-instance length (capsule height)
##   • dna.scale × 0.25 → per-instance girth (capsule radius)
##   • dna.primary_color → per-instance INSTANCE_COLOR
##   • dna.iridescence → per-instance INSTANCE_CUSTOM.x (drives shader sheen)
##
## Cost: ONE draw call per swarm regardless of N.
##
## V1 caveat: every member is the same capsule shape. No per-DNA leg
## count, no head bump, no antennae. That's the trade-off — at swarm
## distance you can't tell the difference, but up close it reads as
## blobs. Tier 3b adds a low-poly canonical critter mesh (head + body
## + leg stubs) as one ArrayMesh to fix this; Tier 3c takes the full
## shader refactor for near-quality.

const CritterDNAClass = preload("res://algorithms/nature_system/dna/critter_dna.gd")


## Build a swarm MultiMeshInstance3D and return it (NOT yet added to
## tree — caller decides where it lives).
##
## Args:
##   dnas       — Array[CritterDNA], one per swarm member
##   positions  — Array[Vector3], same length, world-space positions
##   parent     — Optional Node3D to add the MultiMesh under (if null,
##                caller is responsible for adding it).
##
## Returns:  the MultiMeshInstance3D (already configured)
static func build(dnas: Array, positions: Array, parent: Node3D = null) -> MultiMeshInstance3D:
	if dnas.size() != positions.size():
		push_error("[SwarmRenderer] dnas (%d) and positions (%d) length mismatch"
			% [dnas.size(), positions.size()])
		return null
	if dnas.is_empty():
		return null

	# Canonical low-poly critter mesh (Tier 3b shape) — body capsule
	# + head bump + 4 leg stubs, all baked into ONE ArrayMesh. Sized
	# in unit space (length=2 along Y, girth=1 in xz) so per-instance
	# Transform3D scales it correctly. Vertex count ~120 — small
	# enough for swarms in the hundreds without GPU stress.
	var canonical: Mesh = _build_canonical_critter_mesh()

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = canonical
	mm.instance_count = dnas.size()

	for i in dnas.size():
		var dna: CritterDNA = dnas[i]
		var pos: Vector3 = positions[i]

		# Per-instance size — length along the spine (Y in capsule
		# local frame), girth on xz.
		# CapsuleMesh's height includes two hemispheres of radius 1,
		# so a unit capsule is height=2, radius=1. We scale uniformly
		# in xz by `girth` and along Y by `length / 2.0` so the visible
		# overall length is `length`.
		var length: float = clampf(dna.scale * dna.segments * 0.4, 0.3, 3.0)
		var girth: float  = clampf(dna.scale * 0.25, 0.10, 0.6)

		# Random heading — cheap variety per member.
		var rng := RandomNumberGenerator.new()
		rng.seed = i * 977
		var heading: float = rng.randf() * TAU

		var basis := Basis()
		# Lay the capsule on its side (rotate -90° around Z so Y → X)
		# so it reads as a horizontal critter, then yaw by heading.
		basis = basis.rotated(Vector3.FORWARD, -PI * 0.5)
		basis = basis.rotated(Vector3.UP, heading)
		# Apply non-uniform scale: x→girth, y→length/2 (because capsule
		# is height=2 unit), z→girth. After the FORWARD rotation,
		# capsule's local Y axis points along world X — but we apply
		# scale BEFORE rotation in the basis composition order Godot
		# uses, so just scale (girth, length*0.5, girth) in basis-space.
		basis = basis.scaled(Vector3(girth, length * 0.5, girth))

		var xform := Transform3D(basis, pos)
		mm.set_instance_transform(i, xform)

		# Per-instance colour — primary_color goes into INSTANCE_COLOR.
		# A ShaderMaterial reads this via the `COLOR` vertex input;
		# the existing critter_dna.gdshader already assigns
		# `v_instance_color = COLOR` so it gets multiplied into the
		# fragment albedo for free.
		mm.set_instance_color(i, dna.primary_color)

		# Per-instance custom data — pack iridescence + secondary tint
		# hint. INSTANCE_CUSTOM.x = iridescence, .y = secondary luma,
		# .z = tertiary luma, .w = swarm flag (2.0 to distinguish from
		# Tier 2.5's per-critter taper, which uses 1.0).
		var sec_lum: float = (dna.secondary_color.r + dna.secondary_color.g + dna.secondary_color.b) / 3.0
		var ter_lum: float = (dna.tertiary_color.r + dna.tertiary_color.g + dna.tertiary_color.b) / 3.0
		mm.set_instance_custom_data(i, Color(
			dna.iridescence,
			sec_lum,
			ter_lum,
			2.0  # swarm flag
		))

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Swarm"
	mmi.multimesh = mm

	# Material — share one ShaderMaterial across all instances. For
	# Tier 3a we use a plain StandardMaterial3D (vertex_color_use_as_albedo)
	# so the per-instance INSTANCE_COLOR drives appearance with zero
	# shader work. Tier 3c will swap this for the trait-mapper shader
	# once the per-instance reading is wired.
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.7
	mmi.material_override = mat

	if parent:
		parent.add_child(mmi)

	return mmi


## Construct the canonical low-poly critter mesh used as the swarm
## impostor. Built from primitive components combined via SurfaceTool
## into ONE ArrayMesh — at draw time it's a single mesh, indexed.
##
## Anatomy in unit-space (Y is the spine axis, length = 2):
##   • Body: capsule, length 2, radius 0.5 (Y from -1..+1)
##   • Head: smaller sphere at Y=+1, radius 0.45
##   • Tail: cone tapering at Y=-1, length 0.8
##   • Legs: 4 short cylinders sticking down from the body's underside
##           at Y=±0.4, X=±0.5 (so a square arrangement)
##
## All vertices in ONE submesh so the whole thing renders as a single
## draw call when stamped into a MultiMesh.
static func _build_canonical_critter_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Body — capsule made of two hemisphere caps + a cylinder.
	# Place it with Y from -0.6..+0.6 (capsule body), with hemisphere
	# caps extending to ±1.0.
	_emit_capsule(st, Vector3(0, 0, 0), 0.5, 1.2, 8, 4)
	# Head — sphere at Y=+1.0 (front of the critter).
	_emit_sphere(st, Vector3(0, 1.0, 0), 0.45, 8, 4)
	# Tail — cone pointing -Y from Y=-1.0 to Y=-1.5.
	_emit_cone(st, Vector3(0, -1.0, 0), Vector3(0, -1.5, 0), 0.35, 0.05, 6)
	# 4 legs — cylinders from body underside (Y=-0.3) extending down
	# to Y=-0.6, at corners ±0.45 in X and ±0.45 in Z.
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_emit_cylinder(st,
				Vector3(0.45 * float(sx), -0.3, 0.45 * float(sz)),
				Vector3(0.45 * float(sx), -0.6, 0.45 * float(sz)),
				0.10, 0.06, 6)

	st.generate_normals()
	# No generate_tangents — we render with vertex_color_use_as_albedo,
	# no normal map, so tangents aren't needed and Godot warns when
	# we lack UVs.
	return st.commit()


## Emit a capsule centred at `pos`, body length `body_h`, hemisphere
## radius `r`. Total length is `body_h + 2*r`.
static func _emit_capsule(st: SurfaceTool, pos: Vector3, r: float,
		body_h: float, sides: int, rings: int) -> void:
	var half_h: float = body_h * 0.5
	# Cylinder body
	_emit_cylinder(st,
		pos + Vector3(0, -half_h, 0),
		pos + Vector3(0, +half_h, 0),
		r, r, sides)
	# Top hemisphere
	_emit_hemisphere(st, pos + Vector3(0, +half_h, 0), r, sides, rings, true)
	# Bottom hemisphere
	_emit_hemisphere(st, pos + Vector3(0, -half_h, 0), r, sides, rings, false)


static func _emit_cylinder(st: SurfaceTool, a: Vector3, b: Vector3,
		ra: float, rb: float, sides: int) -> void:
	var axis: Vector3 = (b - a)
	var length: float = axis.length()
	if length < 0.001:
		return
	var dir: Vector3 = axis / length
	# Build a basis — pick X perpendicular to dir.
	var x_axis: Vector3
	if absf(dir.dot(Vector3.UP)) < 0.99:
		x_axis = Vector3.UP.cross(dir).normalized()
	else:
		x_axis = Vector3.RIGHT.cross(dir).normalized()
	var z_axis: Vector3 = x_axis.cross(dir).normalized()
	# Emit ring vertices, then triangulate quads between rings.
	var ring_a: Array = []
	var ring_b: Array = []
	for i in sides:
		var ang: float = TAU * float(i) / float(sides)
		var off: Vector3 = x_axis * cos(ang) + z_axis * sin(ang)
		ring_a.append(a + off * ra)
		ring_b.append(b + off * rb)
	for i in sides:
		var j: int = (i + 1) % sides
		var p00: Vector3 = ring_a[i]; var p10: Vector3 = ring_a[j]
		var p01: Vector3 = ring_b[i]; var p11: Vector3 = ring_b[j]
		st.add_vertex(p00); st.add_vertex(p10); st.add_vertex(p11)
		st.add_vertex(p00); st.add_vertex(p11); st.add_vertex(p01)


## Cone with apex at `tip`, base radius `r_base` at `base`. r_tip can
## be > 0 for a frustum.
static func _emit_cone(st: SurfaceTool, base: Vector3, tip: Vector3,
		r_base: float, r_tip: float, sides: int) -> void:
	_emit_cylinder(st, base, tip, r_base, r_tip, sides)


## Sphere via stacked rings.
static func _emit_sphere(st: SurfaceTool, c: Vector3, r: float,
		sides: int, rings: int) -> void:
	# Polar coords: theta vertical 0..π, phi horizontal 0..2π.
	var verts: Array = []  # rings × sides
	for ri in rings + 1:
		var theta: float = PI * float(ri) / float(rings)
		var y: float = cos(theta) * r
		var ring_r: float = sin(theta) * r
		var ring: Array = []
		for si in sides:
			var phi: float = TAU * float(si) / float(sides)
			ring.append(c + Vector3(cos(phi) * ring_r, y, sin(phi) * ring_r))
		verts.append(ring)
	for ri in rings:
		for si in sides:
			var sj: int = (si + 1) % sides
			var p00: Vector3 = verts[ri][si]
			var p10: Vector3 = verts[ri][sj]
			var p01: Vector3 = verts[ri + 1][si]
			var p11: Vector3 = verts[ri + 1][sj]
			st.add_vertex(p00); st.add_vertex(p10); st.add_vertex(p11)
			st.add_vertex(p00); st.add_vertex(p11); st.add_vertex(p01)


## Hemisphere: half a sphere, top or bottom oriented.
static func _emit_hemisphere(st: SurfaceTool, c: Vector3, r: float,
		sides: int, rings: int, top: bool) -> void:
	var verts: Array = []
	for ri in rings + 1:
		var t: float = float(ri) / float(rings)
		var theta: float = PI * 0.5 * t  # 0..π/2
		var y_sign: float = 1.0 if top else -1.0
		var y: float = cos(theta) * r * y_sign
		var ring_r: float = sin(theta) * r
		var ring: Array = []
		for si in sides:
			var phi: float = TAU * float(si) / float(sides)
			ring.append(c + Vector3(cos(phi) * ring_r, y, sin(phi) * ring_r))
		verts.append(ring)
	for ri in rings:
		for si in sides:
			var sj: int = (si + 1) % sides
			var p00: Vector3 = verts[ri][si]
			var p10: Vector3 = verts[ri][sj]
			var p01: Vector3 = verts[ri + 1][si]
			var p11: Vector3 = verts[ri + 1][sj]
			if top:
				st.add_vertex(p00); st.add_vertex(p10); st.add_vertex(p11)
				st.add_vertex(p00); st.add_vertex(p11); st.add_vertex(p01)
			else:
				st.add_vertex(p00); st.add_vertex(p11); st.add_vertex(p10)
				st.add_vertex(p00); st.add_vertex(p01); st.add_vertex(p11)


## Convenience: build a swarm where DNAs are sampled procedurally from
## a kingdom (random_kingdom on each call). For testing.
static func build_random(parent: Node3D, kingdom: int, count: int,
		spread: float = 5.0, base_seed: int = 42) -> MultiMeshInstance3D:
	var dnas: Array = []
	var positions: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = base_seed
	for i in count:
		var dna := CritterDNAClass.random_kingdom(kingdom, base_seed + i)
		dnas.append(dna)
		var pos := Vector3(
			rng.randf_range(-spread, spread),
			0.0,
			rng.randf_range(-spread, spread),
		)
		positions.append(pos)
	return build(dnas, positions, parent)
