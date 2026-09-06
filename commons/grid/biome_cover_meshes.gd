# biome_cover_meshes.gd — the halo/edge ground cover, built as silhouettes.
#
# WHY THIS FILE EXISTS
#
# Ground cover is the biome's largest visible surface: 241 halo cells across the
# shipped corpus against 116 seeds. It was also the only part never designed —
# each kingdom got one or two Godot primitives with a colour, so fungus read as
# traffic cones, mineral as polystyrene packing, and meta as clipped white discs.
# Varying the tint of a primitive is still a primitive.
#
# It was expensive as well as formless, which is the part nobody had measured.
# `CylinderMesh.new()` with the default 64 radial segments shipped as a LILY PAD:
# 768 triangles for a flat disc, instanced up to 20 times per cell. Measured cost
# per instance before this file:
#
#     flora 18.0   fungus 81.6   fauna 49.0   mineral 8.0   water 336.0   meta 80.0
#     projected worst-case map: 4,048,800 tris
#
# So the two goals are not in tension here — every recipe below is both a better
# silhouette AND cheaper than the primitive it replaces, because a primitive's
# cost comes from segment defaults chosen for a smooth showcase sphere, not for
# something 12 cm tall seen at 4 m in a headset.
#
# THE RULES (probe_biome_cover.gd gates all of them)
#   - One self-contained mesh per recipe. Batched scatter cannot assemble parts.
#   - <= 48 triangles each. At this size, silhouette is the only thing that reads;
#     spending triangles on smoothness buys nothing a headset can see.
#   - Built ONCE per kingdom and cached by the caller, so build cost is irrelevant
#     and only the per-instance triangle bill matters.
#   - No vertex colours. The cover material sets vertex_color_use_as_albedo to
#     consume the per-instance MultiMesh tint; a COLOR array here would multiply
#     against it and mute every tint the halo just gained.
#   - Origin at the BASE, y up. The caller lifts by recipe y_off.

class_name BiomeCoverMeshes
extends RefCounted


# ── shared builders ──────────────────────────────────────────────────────────

static func _ring(n: int, radius: float, y: float, phase: float = 0.0) -> Array:
	var pts: Array = []
	for i in n:
		var a: float = phase + TAU * float(i) / float(n)
		pts.append(Vector3(cos(a) * radius, y, sin(a) * radius))
	return pts


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, b, c)
	_tri(st, a, c, d)


# apex + ring -> n triangles
static func _fan(st: SurfaceTool, apex: Vector3, ring: Array, flip: bool = false) -> void:
	var n: int = ring.size()
	for i in n:
		var b: Vector3 = ring[i]
		var c: Vector3 = ring[(i + 1) % n]
		if flip:
			_tri(st, apex, c, b)
		else:
			_tri(st, apex, b, c)


# two rings of equal size -> n quads
static func _bridge(st: SurfaceTool, lower: Array, upper: Array) -> void:
	var n: int = lower.size()
	for i in n:
		var j: int = (i + 1) % n
		_quad(st, lower[i], lower[j], upper[j], upper[i])


static func _finish(st: SurfaceTool) -> ArrayMesh:
	# ORDER MATTERS. generate_normals() first, index() second: indexing welds only
	# vertices identical in every attribute, so once each face carries its own flat
	# normal the weld cannot smooth the facets away. Reversed, it would round off
	# exactly the faceting these low-poly forms rely on to read.
	st.generate_normals()
	st.index()
	return st.commit()


static func _begin() -> SurfaceTool:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


# ── flora ────────────────────────────────────────────────────────────────────

# A grass blade that BENDS and TAPERS. The old one was a PrismMesh: a straight
# triangular post, which is why a rim of them read as a fence rather than grass.
# Same 8 triangles, entirely different silhouette. 8 tris.
static func blade(height: float = 0.45, width: float = 0.05, bend: float = 0.16) -> ArrayMesh:
	var st: SurfaceTool = _begin()
	var segs: int = 4
	var prev_l: Vector3 = Vector3(-width * 0.5, 0.0, 0.0)
	var prev_r: Vector3 = Vector3(width * 0.5, 0.0, 0.0)
	for i in range(1, segs + 1):
		var t: float = float(i) / float(segs)
		# quadratic lean: near-vertical at the root, falling away at the tip
		var y: float = height * t
		var z: float = bend * t * t
		var w: float = width * (1.0 - t) * 0.5
		var l: Vector3 = Vector3(-w, y, z)
		var r: Vector3 = Vector3(w, y, z)
		if i == segs:
			# the tip is a point, so this is ONE triangle, not a degenerate quad
			_tri(st, prev_l, prev_r, Vector3(0.0, y, z))
		else:
			_quad(st, prev_l, prev_r, r, l)
		prev_l = l
		prev_r = r
	return _finish(st)


# Five petals around a small centre, instead of a 48-triangle sphere. 14 tris.
static func bloom(radius: float = 0.06, lift: float = 0.03) -> ArrayMesh:
	var st: SurfaceTool = _begin()
	var petals: int = 5
	var core: Array = _ring(petals, radius * 0.28, lift)
	for i in petals:
		var a: float = TAU * float(i) / float(petals)
		var tip: Vector3 = Vector3(cos(a) * radius, lift + radius * 0.22, sin(a) * radius)
		_quad(st, core[i], core[(i + 1) % petals], tip, tip)
	_fan(st, Vector3(0.0, lift + radius * 0.1, 0.0), core)
	return _finish(st)


# A low broad leaf. Vertical-only cover reads as spikes from any distance; this is
# the horizontal mass that makes a patch look like ground rather than a hairbrush.
# 12 tris.
static func frond(length: float = 0.14, width: float = 0.07) -> ArrayMesh:
	var st: SurfaceTool = _begin()
	for side in 2:
		var s: float = 1.0 if side == 0 else -1.0
		var segs: int = 3
		var prev_in: Vector3 = Vector3(0.0, 0.012, 0.0)
		var prev_out: Vector3 = Vector3(0.0, 0.012, 0.0)
		for i in range(1, segs + 1):
			var t: float = float(i) / float(segs)
			var w: float = width * sin(t * PI) * s
			var inn: Vector3 = Vector3(0.0, 0.012 + 0.02 * (1.0 - t), length * t)
			var out: Vector3 = Vector3(w, 0.008, length * t)
			_quad(st, prev_in, prev_out, out, inn)
			prev_in = inn
			prev_out = out
	return _finish(st)


# ── fungus ───────────────────────────────────────────────────────────────────

# An actual mushroom: domed cap with a flared rim, on a stem. The old recipe was
# a bare half-sphere sitting on the floor with no stem at all, at 80 triangles.
# 30 tris.
static func mushroom(cap_r: float = 0.1, cap_h: float = 0.07, stem_h: float = 0.11) -> ArrayMesh:
	var st: SurfaceTool = _begin()
	var n: int = 6
	var top: Vector3 = Vector3(0.0, stem_h + cap_h, 0.0)
	var mid: Array = _ring(n, cap_r * 0.66, stem_h + cap_h * 0.62)
	var rim: Array = _ring(n, cap_r, stem_h + cap_h * 0.05)
	_fan(st, top, mid)
	_bridge(st, rim, mid)
	var base: Array = _ring(n, cap_r * 0.2, 0.0)
	var neck: Array = _ring(n, cap_r * 0.15, stem_h)
	_bridge(st, base, neck)
	return _finish(st)


# The taller conical one — a different silhouette, not the same shape scaled.
# 24 tris.
static func toadstool(cap_r: float = 0.09, height: float = 0.24) -> ArrayMesh:
	var st: SurfaceTool = _begin()
	var n: int = 6
	var rim: Array = _ring(n, cap_r, height * 0.58)
	_fan(st, Vector3(0.0, height, 0.0), rim)
	_fan(st, Vector3(0.0, height * 0.5, 0.0), rim, true)   # the underside/gills
	var base: Array = _ring(n, cap_r * 0.16, 0.0)
	var neck: Array = _ring(n, cap_r * 0.12, height * 0.55)
	_bridge(st, base, neck)
	return _finish(st)


# Shelf fungus growing sideways. Horizontal mass again, and the one fungal form
# that is not a vertical stalk. 20 tris.
static func bracket(radius: float = 0.09, thickness: float = 0.022) -> ArrayMesh:
	var st: SurfaceTool = _begin()
	var n: int = 5
	var hub_t: Vector3 = Vector3(0.0, thickness, 0.0)
	var hub_b: Vector3 = Vector3(0.0, 0.0, 0.0)
	var pts_t: Array = []
	var pts_b: Array = []
	for i in range(n + 1):
		var a: float = PI * float(i) / float(n)      # a half disc
		pts_t.append(Vector3(cos(a) * radius, thickness * 0.85, sin(a) * radius))
		pts_b.append(Vector3(cos(a) * radius * 0.94, 0.0, sin(a) * radius * 0.94))
	for i in n:
		_tri(st, hub_t, pts_t[i], pts_t[i + 1])
		_tri(st, hub_b, pts_b[i + 1], pts_b[i])
		_quad(st, pts_b[i], pts_b[i + 1], pts_t[i + 1], pts_t[i])
	return _finish(st)


# ── fauna ────────────────────────────────────────────────────────────────────

# A burrow: a raised annulus with a hole down the middle. The old one was a
# squashed sphere — a brown lump, which is why the fauna rim read as mud.
# The hole is the whole point: it says something LIVES here. 18 tris.
static func burrow(radius: float = 0.11, lip: float = 0.045) -> ArrayMesh:
	var st: SurfaceTool = _begin()
	var n: int = 6
	var outer: Array = _ring(n, radius, 0.0)
	var inner: Array = _ring(n, radius * 0.42, lip)
	_bridge(st, outer, inner)
	_fan(st, Vector3(0.0, lip * 0.15, 0.0), inner, true)   # the dark throat
	return _finish(st)


# A pressed pair of prints rather than a floating pebble. 4 tris.
static func track(size: float = 0.05) -> ArrayMesh:
	var st: SurfaceTool = _begin()
	for i in 2:
		var ox: float = (-0.5 + float(i)) * size * 1.6
		var oz: float = (0.5 - float(i)) * size * 0.9
		_quad(st,
			Vector3(ox - size * 0.5, 0.0, oz - size * 0.35),
			Vector3(ox + size * 0.5, 0.0, oz - size * 0.35),
			Vector3(ox + size * 0.35, 0.004, oz + size * 0.35),
			Vector3(ox - size * 0.35, 0.004, oz + size * 0.35))
	return _finish(st)


# An ovoid, 24 tris (was an 80-triangle SphereMesh).
static func egg(radius: float = 0.045, height: float = 0.12) -> ArrayMesh:
	var st: SurfaceTool = _begin()
	var n: int = 6
	var low: Array = _ring(n, radius * 0.72, height * 0.22)
	var wide: Array = _ring(n, radius, height * 0.52)
	_fan(st, Vector3.ZERO, low, true)
	_bridge(st, low, wide)
	_fan(st, Vector3(0.0, height, 0.0), wide)
	return _finish(st)


# ── mineral ──────────────────────────────────────────────────────────────────

# A hexagonal column with a pointed termination — the shape a crystal actually
# has. The old recipe was a PrismMesh, i.e. a triangular wedge, which is why the
# mineral rim read as packing foam. 18 tris.
static func crystal(radius: float = 0.05, height: float = 0.26) -> ArrayMesh:
	var st: SurfaceTool = _begin()
	var n: int = 6
	var base: Array = _ring(n, radius, 0.0)
	var shoulder: Array = _ring(n, radius * 0.86, height * 0.72)
	_bridge(st, base, shoulder)
	_fan(st, Vector3(0.0, height, 0.0), shoulder)
	return _finish(st)


# Broken flakes at the foot of the columns — grounding, so the shards do not look
# planted in a flat floor. 4 tris.
static func chip(size: float = 0.045) -> ArrayMesh:
	var st: SurfaceTool = _begin()
	var apex: Vector3 = Vector3(0.0, size * 0.5, 0.0)
	var ring: Array = _ring(4, size, 0.0, 0.4)
	_fan(st, apex, ring)
	return _finish(st)


# ── water ────────────────────────────────────────────────────────────────────

# A tapered stalk with a seed head. 14 tris.
static func reed(height: float = 0.5, radius: float = 0.011) -> ArrayMesh:
	var st: SurfaceTool = _begin()
	var n: int = 3
	var base: Array = _ring(n, radius, 0.0)
	var top: Array = _ring(n, radius * 0.55, height * 0.78)
	_bridge(st, base, top)
	var headr: Array = _ring(n, radius * 2.4, height * 0.82)
	_bridge(st, top, headr)
	_fan(st, Vector3(0.0, height, 0.0), headr)
	return _finish(st)


# THE 768-TRIANGLE FLAT DISC. A lily pad is a fan with a notch cut out of it —
# the notch is the only thing that makes it read as a pad rather than a coin, and
# it is free, because it is a triangle NOT drawn. 7 tris, down from 768.
static func lily(radius: float = 0.085) -> ArrayMesh:
	var st: SurfaceTool = _begin()
	var n: int = 8
	var ring: Array = _ring(n, radius, 0.006)
	var centre: Vector3 = Vector3(0.0, 0.004, 0.0)
	for i in range(n - 1):        # skip one wedge: that gap IS the notch
		_tri(st, centre, ring[i], ring[i + 1])
	return _finish(st)


# ── meta ─────────────────────────────────────────────────────────────────────

# An octahedron, not a sphere. At 5 cm the facets are the only thing that
# survives, and there are eight triangles to do it in — down from 80.
#
# The emission clamp lives with the recipe that needs it: at emission_mul 2.2 the
# old mote measured 3.13% of frame at pure 255,255,255, i.e. its form was not dim
# or bright, it was ABSENT — a white disc. Faceted geometry only reads if the
# lighting can still separate the faces.
static func mote(radius: float = 0.05) -> ArrayMesh:
	var st: SurfaceTool = _begin()
	var ring: Array = _ring(4, radius, radius)
	_fan(st, Vector3(0.0, radius * 2.0, 0.0), ring)
	_fan(st, Vector3.ZERO, ring, true)
	return _finish(st)


# A short floating stroke — the meta kingdom's second mark, so a band is not one
# repeated dot. 2 tris.
static func stroke(length: float = 0.09, width: float = 0.012) -> ArrayMesh:
	var st: SurfaceTool = _begin()
	_quad(st,
		Vector3(-length * 0.5, 0.0, 0.0), Vector3(length * 0.5, 0.0, 0.0),
		Vector3(length * 0.5, width, 0.0), Vector3(-length * 0.5, width, 0.0))
	return _finish(st)


# ── fallback ─────────────────────────────────────────────────────────────────

# For a kingdom the grammar does not know. Deliberately the plainest thing here:
# an unknown kingdom should look unremarkable, not invent a look it has not
# earned. 2 tris.
static func tuft(width: float = 0.12, height: float = 0.3) -> ArrayMesh:
	var st: SurfaceTool = _begin()
	_quad(st,
		Vector3(-width * 0.5, 0.0, 0.0), Vector3(width * 0.5, 0.0, 0.0),
		Vector3(width * 0.5, height, 0.0), Vector3(-width * 0.5, height, 0.0))
	return _finish(st)
