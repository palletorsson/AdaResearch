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
# cube table to transcribe, and always watertight. A little more geometry than
# marching cubes, negligible for a cell-sized creature.
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
	# sample the field once per grid vertex (shared across cubes/tets)
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
				vals[vi] = float(field.call(p))
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
	st.generate_normals()
	return st.commit()


# march one tetrahedron: emit 0/1/2 triangles at the surface crossing.
static func _march_tet(st: SurfaceTool, tet: Array, ci: Array, vals: PackedFloat32Array, pos: PackedVector3Array) -> bool:
	var v0: int = ci[tet[0]]
	var v1: int = ci[tet[1]]
	var v2: int = ci[tet[2]]
	var v3: int = ci[tet[3]]
	var d0: float = vals[v0]
	var d1: float = vals[v1]
	var d2: float = vals[v2]
	var d3: float = vals[v3]
	var mask: int = 0
	if d0 < 0.0: mask |= 1
	if d1 < 0.0: mask |= 2
	if d2 < 0.0: mask |= 4
	if d3 < 0.0: mask |= 8
	if mask == 0 or mask == 15:
		return false
	# vertex on edge (va,vb) where the field crosses zero
	var lerp_edge := func(a: int, b: int) -> Vector3:
		var da: float = vals[a]
		var db: float = vals[b]
		var t: float = clampf(da / (da - db), 0.0, 1.0) if absf(da - db) > 1e-9 else 0.5
		return pos[a].lerp(pos[b], t)
	# the classic marching-tetrahedra cases (mask == complement folds by winding)
	match mask:
		1, 14:
			_tri(st, lerp_edge.call(v0, v1), lerp_edge.call(v0, v2), lerp_edge.call(v0, v3), mask == 14)
		2, 13:
			_tri(st, lerp_edge.call(v1, v0), lerp_edge.call(v1, v3), lerp_edge.call(v1, v2), mask == 13)
		4, 11:
			_tri(st, lerp_edge.call(v2, v0), lerp_edge.call(v2, v1), lerp_edge.call(v2, v3), mask == 11)
		8, 7:
			_tri(st, lerp_edge.call(v3, v0), lerp_edge.call(v3, v2), lerp_edge.call(v3, v1), mask == 7)
		3, 12:  # v0,v1 inside → quad
			_quad(st, lerp_edge.call(v0, v3), lerp_edge.call(v0, v2), lerp_edge.call(v1, v2), lerp_edge.call(v1, v3), mask == 12)
		5, 10:  # v0,v2 inside
			_quad(st, lerp_edge.call(v0, v1), lerp_edge.call(v0, v3), lerp_edge.call(v2, v3), lerp_edge.call(v2, v1), mask == 10)
		6, 9:   # v1,v2 inside
			_quad(st, lerp_edge.call(v1, v0), lerp_edge.call(v1, v3), lerp_edge.call(v2, v3), lerp_edge.call(v2, v0), mask == 9)
	return true


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, flip: bool) -> void:
	if flip:
		st.add_vertex(a); st.add_vertex(c); st.add_vertex(b)
	else:
		st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, flip: bool) -> void:
	_tri(st, a, b, c, flip)
	_tri(st, a, c, d, flip)
