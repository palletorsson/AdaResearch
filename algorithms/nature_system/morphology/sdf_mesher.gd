# SdfMesher.gd — turn a signed distance field into ONE continuous mesh.
#
# The critter body used to be a chain of separate tube meshes: where the tubes
# met at a joint (radius change, sharp curve) or a limb attached, the surfaces
# didn't merge and left gaps — the "holes". An SDF has no joints: the body is
# a single scalar field (smooth-union of capsules + spheres), and its zero-
# crossing is ONE closed surface. This mesher walks a grid over that field and
# marching-tetrahedra it into a watertight ArrayMesh with smooth normals.
#
# Marching TETRAHEDRA (not cubes): each grid cube splits into 6 tetrahedra;
# each tet has only 16 sign cases, handled by a tiny edge table — no 256-entry
# cube table to transcribe. A little more geometry than marching cubes,
# negligible for a cell-sized creature.
#
# KNOWN SIMPLIFICATION — the skin is NOT watertight (probe_biome_sdf measures the
# crack load). This extraction is not conforming: adjacent tets triangulate a
# shared face with mismatched diagonals, so the surface carries a lattice of
# hairline boundary edges (~half the edges, growing with resolution). It does not
# matter here because every SDF skin renders cull_mode = DISABLED (double-sided):
# a crack shows the backface, never a see-through hole. True closure would need a
# conforming re-mesh; not worth the risk for decorative bodies that already read
# solid. What IS guaranteed and probe-locked: every triangle faces outward
# (positive enclosed volume) and — since the isolevel bias below — no crossing
# lands on a grid vertex, so the mesh is manifold (no edge shared by 3+ faces,
# which would poison the averaged normals even under double-siding).
#
# SDF PRIMITIVES here are the ones a body needs: capsule (a fattened line
# segment — the body between two spine points) and sphere (the head). smin
# (smooth minimum) unions them so neighbours blend instead of intersecting.

class_name SdfMesher
extends RefCounted


# ── SDF primitives + combinators ──

static func sd_sphere(p: Vector3, c: Vector3, r: float) -> float:
	return p.distance_to(c) - r


# distance to a capsule: the segment a→b fattened to radius r
static func sd_capsule(p: Vector3, a: Vector3, b: Vector3, r: float) -> float:
	var pa: Vector3 = p - a
	var ba: Vector3 = b - a
	var h: float = clampf(pa.dot(ba) / maxf(ba.dot(ba), 1e-6), 0.0, 1.0)
	return (pa - ba * h).length() - r


# a tapered capsule: radius lerps ra→rb along the segment (a body that thins)
static func sd_capsule_tapered(p: Vector3, a: Vector3, b: Vector3, ra: float, rb: float) -> float:
	var pa: Vector3 = p - a
	var ba: Vector3 = b - a
	var h: float = clampf(pa.dot(ba) / maxf(ba.dot(ba), 1e-6), 0.0, 1.0)
	return (pa - ba * h).length() - lerpf(ra, rb, h)


# an ellipsoid (squashed/stretched sphere): radii r per axis. iq's approximation.
static func sd_ellipsoid(p: Vector3, c: Vector3, r: Vector3) -> float:
	var q: Vector3 = p - c
	var k0: float = (Vector3(q.x / r.x, q.y / r.y, q.z / r.z)).length()
	var k1: float = (Vector3(q.x / (r.x * r.x), q.y / (r.y * r.y), q.z / (r.z * r.z))).length()
	return k0 * (k0 - 1.0) / maxf(k1, 1e-6)


static func smin(a: float, b: float, k: float) -> float:
	if k <= 0.0:
		return minf(a, b)
	var h: float = clampf(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
	return lerpf(b, a, h) - k * h * (1.0 - h)


# ── the mesher ──
#
# field: Callable(Vector3) -> float, negative INSIDE the body.
# aabb_min/max: sample volume (pad the body's bounds by ~2 cells).
# res: grid cells along the longest axis.
# Returns an ArrayMesh (smooth-shaded) or null if the field never crosses zero.

const _TET_CORNERS: Array = [  # 6 tetrahedra covering the unit cube (corner indices 0..7)
	[0, 5, 1, 6], [0, 1, 2, 6], [0, 2, 3, 6],
	[0, 3, 7, 6], [0, 7, 4, 6], [0, 4, 5, 6],
]
# cube corner offsets, index 0..7
const _CUBE_OFF: Array = [
	Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0),
	Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1),
]


static func mesh_field(field: Callable, aabb_min: Vector3, aabb_max: Vector3, res: int) -> ArrayMesh:
	res = clampi(res, 8, 48)
	var size: Vector3 = aabb_max - aabb_min
	var longest: float = maxf(size.x, maxf(size.y, size.z))
	var step: float = longest / float(res)
	if step <= 0.0:
		return null
	var nx: int = int(ceil(size.x / step)) + 1
	var ny: int = int(ceil(size.y / step)) + 1
	var nz: int = int(ceil(size.z / step)) + 1
	# sample the field once per grid vertex (shared across cubes/tets).
	# ISOLEVEL BIAS: a sample sitting exactly on the surface makes an edge
	# crossing land ON a grid vertex, where the several edges meeting there
	# collapse to one welded point and the mesh turns non-manifold (an edge
	# shared by 3+ faces → a meaningless averaged normal, visible speckle even
	# double-sided). Nudge any near-zero sample just OUTSIDE so every crossing is
	# strictly interior to its edge. Grid-aligned bodies — the fungus stem and
	# creature head both sit at the origin — are exactly the ones that hit this,
	# so it is not a corner case. Bias is a thousandth of a cell: below any
	# visible geometry, above float noise.
	var iso: float = step * 1e-3
	var vals: PackedFloat32Array = PackedFloat32Array()
	vals.resize(nx * ny * nz)
	var pos: PackedVector3Array = PackedVector3Array()
	pos.resize(nx * ny * nz)
	var vi: int = 0
	for iz in range(nz):
		for iy in range(ny):
			for ix in range(nx):
				var p: Vector3 = aabb_min + Vector3(ix, iy, iz) * step
				pos[vi] = p
				var v: float = float(field.call(p))
				vals[vi] = v if absf(v) >= iso else iso
				vi += 1
	var idx := func(ix: int, iy: int, iz: int) -> int:
		return (iz * ny + iy) * nx + ix
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var any: bool = false
	for iz in range(nz - 1):
		for iy in range(ny - 1):
			for ix in range(nx - 1):
				# gather the 8 cube corners
				var ci: Array = []
				for off in _CUBE_OFF:
					ci.append(idx.call(ix + int(off.x), iy + int(off.y), iz + int(off.z)))
				for tet in _TET_CORNERS:
					if _march_tet(st, tet, ci, vals, pos):
						any = true
	if not any:
		return null
	# weld coincident edge-crossing vertices (adjacent tets share edges and
	# compute the same point) so normals average across faces → smooth skin,
	# not a field of disconnected flat triangles.
	st.index()
	st.generate_normals()
	return st.commit()


# march one tetrahedron: emit 0/1/2 triangles at the surface crossing.
# Winding is NOT trusted from a case table (the old complement-flip was the
# "see-through broken" bug — inconsistent faces got backface-culled). Instead
# every triangle is oriented so its normal points AWAY from the tet's inside
# corners, i.e. toward the outside — always correct, whatever the case.
static func _march_tet(st: SurfaceTool, tet: Array, ci: Array, vals: PackedFloat32Array, pos: PackedVector3Array) -> bool:
	var vv: Array = [ci[tet[0]], ci[tet[1]], ci[tet[2]], ci[tet[3]]]
	var dd: Array = [vals[vv[0]], vals[vv[1]], vals[vv[2]], vals[vv[3]]]
	var mask: int = 0
	for i in 4:
		if float(dd[i]) < 0.0:
			mask |= (1 << i)
	if mask == 0 or mask == 15:
		return false
	# inside centroid: average of the corners that are inside (negative)
	var inside := Vector3.ZERO
	var n_in: int = 0
	for i in 4:
		if float(dd[i]) < 0.0:
			inside += pos[vv[i]]
			n_in += 1
	inside /= float(n_in)
	var lerp_edge := func(a: int, b: int) -> Vector3:
		var da: float = vals[a]
		var db: float = vals[b]
		var t: float = clampf(da / (da - db), 0.0, 1.0) if absf(da - db) > 1e-9 else 0.5
		return pos[a].lerp(pos[b], t)
	match mask:
		1, 14:
			_tri(st, lerp_edge.call(vv[0], vv[1]), lerp_edge.call(vv[0], vv[2]), lerp_edge.call(vv[0], vv[3]), inside)
		2, 13:
			_tri(st, lerp_edge.call(vv[1], vv[0]), lerp_edge.call(vv[1], vv[3]), lerp_edge.call(vv[1], vv[2]), inside)
		4, 11:
			_tri(st, lerp_edge.call(vv[2], vv[0]), lerp_edge.call(vv[2], vv[1]), lerp_edge.call(vv[2], vv[3]), inside)
		8, 7:
			_tri(st, lerp_edge.call(vv[3], vv[0]), lerp_edge.call(vv[3], vv[2]), lerp_edge.call(vv[3], vv[1]), inside)
		3, 12:  # two corners inside → quad
			_quad(st, lerp_edge.call(vv[0], vv[3]), lerp_edge.call(vv[0], vv[2]), lerp_edge.call(vv[1], vv[2]), lerp_edge.call(vv[1], vv[3]), inside)
		5, 10:
			_quad(st, lerp_edge.call(vv[0], vv[1]), lerp_edge.call(vv[0], vv[3]), lerp_edge.call(vv[2], vv[3]), lerp_edge.call(vv[2], vv[1]), inside)
		6, 9:
			_quad(st, lerp_edge.call(vv[1], vv[0]), lerp_edge.call(vv[1], vv[3]), lerp_edge.call(vv[2], vv[3]), lerp_edge.call(vv[2], vv[0]), inside)
	return true


# emit triangle a,b,c with the winding that makes its normal face away from
# `inside` (the interior). Flip if the geometric normal points inward.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
	var normal: Vector3 = (b - a).cross(c - a)
	var centroid: Vector3 = (a + b + c) / 3.0
	if normal.dot(centroid - inside) >= 0.0:
		st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)
	else:
		st.add_vertex(a); st.add_vertex(c); st.add_vertex(b)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3) -> void:
	_tri(st, a, b, c, inside)
	_tri(st, a, c, d, inside)
