extends RefCounted

## THE ISO SOURCE (2026-09-03, Palle: "use iso sources for like this
## mc_portal_landscape__burial-standing__num_portals-7 to build some the
## sculptures").
##
## A dream body made of primitives is a body ASSEMBLED: you can see where the
## sphere ends and the capsule starts. A body marched out of a field is a body
## GROWN - limbs merge into the torso with a fillet, two heads share one neck,
## a hole is not a missing piece but a place the field never crossed zero. That
## is the difference this file buys, and it is why the isosurfaces sequence
## exists in the curriculum at all.
##
## WHY NOT THE marchingcave GENERATORS. algorithms/proceduralgeneration/
## isosurfaces/marchingcave/ already marches cubes, and mc_portal_landscape is
## one of its artifacts - but those are TERRAIN generators: they build node
## trees, own their own materials, some run on the GPU, and one of them has a
## teardown crash the corpus already recorded (TerrainGeneratorBase.release()).
## A statue needs a MESH, deterministically, inside a static function that
## touches nothing. So this is the same algorithm at a different scale: 256
## cells of field, one ArrayMesh out, no nodes, no disk, no autoloads.
##
## THE FIELD IS THE ARGUMENT. Callers compose an SDF out of the parts below -
## sphere, capsule, box, torus, plus the smooth union that gives the fillet -
## and hand it here as an Array of part dictionaries. Everything is data, so a
## seed can build the field and the builder never writes a marching-cubes loop.
##
##     var parts := []
##     parts.append(DreamIso.sphere(Vector3(0, 1.2, 0), 0.22))
##     parts.append(DreamIso.capsule(Vector3(0, 0.2, 0), Vector3(0, 1.1, 0), 0.16))
##     var mesh := DreamIso.mesh_of(parts, 0.06, 0.12)     # cell size, blend
##
## STATIC AND PURE, like every builder under bodies/.

# ── the field's parts ──────────────────────────────────────────────────────

static func sphere(at: Vector3, r: float) -> Dictionary:
	return {"k": 0, "a": at, "r": r}


static func capsule(a: Vector3, b: Vector3, r: float, r2: float = -1.0) -> Dictionary:
	return {"k": 1, "a": a, "b": b, "r": r, "r2": (r if r2 < 0.0 else r2)}


static func box(at: Vector3, half: Vector3, round_r: float = 0.02) -> Dictionary:
	return {"k": 2, "a": at, "h": half, "r": round_r}


## A ring standing in a plane - the portal, and the hole a body can grow through.
static func torus(at: Vector3, major: float, minor: float, axis: Vector3 = Vector3.UP) -> Dictionary:
	return {"k": 3, "a": at, "R": major, "r": minor, "n": axis.normalized()}


## SUBTRACTED, not added: a part that carves. Every kind can do it.
static func cut(part: Dictionary) -> Dictionary:
	var p: Dictionary = part.duplicate()
	p["cut"] = true
	return p


# ── the field ──────────────────────────────────────────────────────────────

static func _sd_part(p: Dictionary, q: Vector3) -> float:
	match int(p.get("k", 0)):
		0:
			return (q - (p["a"] as Vector3)).length() - float(p["r"])
		1:
			var a: Vector3 = p["a"]
			var b: Vector3 = p["b"]
			var pa: Vector3 = q - a
			var ba: Vector3 = b - a
			var denom: float = maxf(0.000001, ba.dot(ba))
			var h: float = clampf(pa.dot(ba) / denom, 0.0, 1.0)
			var rr: float = lerpf(float(p["r"]), float(p.get("r2", p["r"])), h)
			return (pa - ba * h).length() - rr
		2:
			var d: Vector3 = (q - (p["a"] as Vector3)).abs() - (p["h"] as Vector3)
			var outside: Vector3 = Vector3(maxf(d.x, 0.0), maxf(d.y, 0.0), maxf(d.z, 0.0))
			return outside.length() + minf(maxf(d.x, maxf(d.y, d.z)), 0.0) - float(p.get("r", 0.0))
		3:
			var n: Vector3 = p["n"]
			var rel: Vector3 = q - (p["a"] as Vector3)
			var along: float = rel.dot(n)
			var radial: float = (rel - n * along).length() - float(p["R"])
			return Vector2(radial, along).length() - float(p["r"])
	return 1.0e9


## The fillet: two parts meeting swell into each other instead of intersecting.
static func _smin(a: float, b: float, k: float) -> float:
	if k <= 0.0:
		return minf(a, b)
	var h: float = clampf(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
	return lerpf(b, a, h) - k * h * (1.0 - h)


static func field(parts: Array, q: Vector3, blend: float) -> float:
	var d: float = 1.0e9
	# THE CUTTERS' OWN DISTANCE, unioned — negative inside any cutter.
	#
	# THIS LINE HAD A SIGN ERROR AND IT INVERTED THE BODY. It accumulated -c and
	# handed that to the subtraction, which made the expression max(d, c): the
	# INTERSECTION of the body with the cutter, so a statue kept only its own
	# holes. tube_reef marched 37 capsules spanning 0.77 x 1.33 x 0.67 m into a
	# 144-triangle blob 0.12 m across — exactly one pore sphere — and the museum
	# frame showed six eel heads hovering over an empty coral bed. Nothing
	# errored, nothing warned, and the builder's own "if the mesher yields
	# nothing, sweep primitives instead" fallback never fired, because the mesher
	# HAD yielded something.
	var cut_d: float = 1.0e9
	for p_v in parts:
		var p: Dictionary = p_v
		var v: float = _sd_part(p, q)
		if bool(p.get("cut", false)):
			cut_d = minf(cut_d, v)
		else:
			d = _smin(d, v, blend)
	if cut_d < 1.0e8:
		# smooth subtraction: max(d, -cut_d), softened so a carved hole has a lip
		# and not a razor edge
		d = -_smin(-d, cut_d, blend * 0.6)
	return d


# ── the march ──────────────────────────────────────────────────────────────

## Marching CUBES proper would need the 256-case table; a statue does not need
## it. This marches TETRAHEDRA - each cell cut into six, each tet emitting one
## or two triangles - which is the same isosurface, needs no table, and cannot
## produce the ambiguous-face holes the table exists to resolve. It costs about
## 40% more triangles, which for a body on a plinth is nothing.
static func mesh_of(parts: Array, cell: float = 0.055, blend: float = 0.10,
		pad: float = 0.12) -> ArrayMesh:
	if parts.is_empty():
		push_warning("[dream_iso] mesh_of called with no parts")
		return null
	# the box the field lives in, from the parts themselves
	var lo := Vector3(1.0e9, 1.0e9, 1.0e9)
	var hi := Vector3(-1.0e9, -1.0e9, -1.0e9)
	for p_v in parts:
		var p: Dictionary = p_v
		if bool(p.get("cut", false)):
			continue
		var c: Vector3 = p["a"]
		var reach: float = float(p.get("r", 0.1)) + blend + pad
		var pts: Array = [c]
		if p.has("b"):
			pts.append(p["b"])
		if p.has("h"):
			reach += (p["h"] as Vector3).length()
		if p.has("R"):
			reach += float(p["R"])
		for q_v in pts:
			var q: Vector3 = q_v
			lo = Vector3(minf(lo.x, q.x - reach), minf(lo.y, q.y - reach), minf(lo.z, q.z - reach))
			hi = Vector3(maxf(hi.x, q.x + reach), maxf(hi.y, q.y + reach), maxf(hi.z, q.z + reach))
	var span: Vector3 = hi - lo
	# a cell size that keeps the grid inside a budget, whatever the caller asked
	var want: Vector3i = Vector3i(int(ceil(span.x / cell)), int(ceil(span.y / cell)), int(ceil(span.z / cell)))
	var cells: int = maxi(1, want.x) * maxi(1, want.y) * maxi(1, want.z)
	var grow: float = 1.0
	while cells > 220000 and grow < 8.0:
		grow *= 1.25
		want = Vector3i(int(ceil(span.x / (cell * grow))), int(ceil(span.y / (cell * grow))),
			int(ceil(span.z / (cell * grow))))
		cells = maxi(1, want.x) * maxi(1, want.y) * maxi(1, want.z)
	var cs: float = cell * grow
	var nx: int = maxi(1, want.x)
	var ny: int = maxi(1, want.y)
	var nz: int = maxi(1, want.z)

	# sample once per corner, reused by every tet that touches it
	var vals := PackedFloat32Array()
	vals.resize((nx + 1) * (ny + 1) * (nz + 1))
	var idx: int = 0
	for iz in range(nz + 1):
		for iy in range(ny + 1):
			for ix in range(nx + 1):
				var q := Vector3(lo.x + float(ix) * cs, lo.y + float(iy) * cs, lo.z + float(iz) * cs)
				vals[idx] = field(parts, q, blend)
				idx += 1

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# the six tetrahedra of a cube, by corner index
	var TETS: Array = [[0, 5, 1, 6], [0, 1, 2, 6], [0, 2, 3, 6], [0, 3, 7, 6], [0, 7, 4, 6], [0, 4, 5, 6]]
	var OFF: Array = [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 1, 0), Vector3i(0, 1, 0),
		Vector3i(0, 0, 1), Vector3i(1, 0, 1), Vector3i(1, 1, 1), Vector3i(0, 1, 1)]
	var emitted: int = 0
	for iz in range(nz):
		for iy in range(ny):
			for ix in range(nx):
				var cv := PackedFloat32Array()
				cv.resize(8)
				var cp: Array = []
				var any_in: bool = false
				var any_out: bool = false
				for c in range(8):
					var o: Vector3i = OFF[c]
					var jx: int = ix + o.x
					var jy: int = iy + o.y
					var jz: int = iz + o.z
					var v: float = vals[jx + jy * (nx + 1) + jz * (nx + 1) * (ny + 1)]
					cv[c] = v
					cp.append(Vector3(lo.x + float(jx) * cs, lo.y + float(jy) * cs, lo.z + float(jz) * cs))
					if v <= 0.0:
						any_in = true
					else:
						any_out = true
				if not (any_in and any_out):
					continue
				for t_v in TETS:
					var t: Array = t_v
					emitted += _tet(st, cp, cv, int(t[0]), int(t[1]), int(t[2]), int(t[3]),
						parts, blend, cs)
	if emitted == 0:
		# A NULL HERE IS A BODY THAT DOES NOT EXIST, and every caller's fallback
		# is silent by design — so the mesher says what it was given and what
		# grid it looked at, or a missing statue reads as an empty plinth.
		push_warning("[dream_iso] no surface from %d part(s): grid %dx%dx%d at %.3f m over %s"
			% [parts.size(), nx, ny, nz, cs, str(hi - lo)])
		return null
	st.generate_normals()
	return st.commit()


static func _lerp_edge(pa: Vector3, pb: Vector3, va: float, vb: float) -> Vector3:
	var d: float = vb - va
	if absf(d) < 0.000001:
		return pa
	return pa + (pb - pa) * (-va / d)


## One tetrahedron's contribution.
##
## TWO THINGS HERE WERE WRONG AND A PICTURE COULD NOT HAVE SHOWN EITHER, which is
## the whole reason probe_dream_iso.gd exists (2026-09-03):
##
##   THE QUAD WAS FANNED ACROSS AN EDGE, NOT A DIAGONAL. Four crossing edges give
##   a quad p0 p1 p2 p3 in cyclic order; the split was (p0,p1,p2)+(p2,p1,p3),
##   which uses p1-p2 - a SIDE of the quad - as the shared edge, so the two
##   triangles overlap and the real diagonals p0-p2 and p1-p3 are left open. The
##   probe measured 3642 open edges of 7074 on a plain sphere. The fan is
##   (p0,p1,p2)+(p0,p2,p3) now: one diagonal, shared once.
##
##   THE 5/10 CASE WAS NOT IN CYCLIC ORDER. Its crossing edges were listed
##   01, 23, 03, 21 - and e01 and e23 share no tet corner, so they are opposite
##   quad corners, not neighbours. Any fan over that order is a bowtie. Correct
##   cycle: 01, 03, 23, 21.
##
## And the winding is no longer GUESSED from the mask's parity. Whether a face
## points out depends on the tetrahedron's own handedness as well as the case,
## and the parity table had it right for 310 of 12240 vertices. So each triangle
## asks the field: step a little along the face normal and a little against it,
## and the side where the field is LARGER is outside. Two evaluations per
## triangle, and it cannot be off by a sign.
static func _tet(st: SurfaceTool, cp: Array, cv: PackedFloat32Array,
		i0: int, i1: int, i2: int, i3: int,
		parts: Array, blend: float, cs: float) -> int:
	var p: Array = [cp[i0], cp[i1], cp[i2], cp[i3]]
	var v: Array = [cv[i0], cv[i1], cv[i2], cv[i3]]
	var mask: int = 0
	for i in range(4):
		if float(v[i]) <= 0.0:
			mask |= (1 << i)
	if mask == 0 or mask == 15:
		return 0
	var tri: Array = []
	match mask:
		1, 14:
			tri = [[0, 1], [0, 2], [0, 3]]
		2, 13:
			tri = [[1, 0], [1, 3], [1, 2]]
		4, 11:
			tri = [[2, 0], [2, 1], [2, 3]]
		8, 7:
			tri = [[3, 0], [3, 2], [3, 1]]
		3, 12:
			tri = [[0, 2], [0, 3], [1, 3], [1, 2]]
		5, 10:
			tri = [[0, 1], [0, 3], [2, 3], [2, 1]]
		9, 6:
			tri = [[0, 1], [0, 2], [3, 2], [3, 1]]
	if tri.is_empty():
		return 0
	var pts: Array = []
	for e_v in tri:
		var e: Array = e_v
		pts.append(_lerp_edge(p[int(e[0])], p[int(e[1])], float(v[int(e[0])]), float(v[int(e[1])])))
	if pts.size() == 3:
		_tri(st, pts[0], pts[1], pts[2], parts, blend, cs)
		return 1
	# a diagonal, so the two halves share exactly one edge and the quad's own
	# four sides are each emitted once
	_tri(st, pts[0], pts[1], pts[2], parts, blend, cs)
	_tri(st, pts[0], pts[2], pts[3], parts, blend, cs)
	return 2


## Emit one triangle, wound so its face points at rising field — outward.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		parts: Array, blend: float, cs: float) -> void:
	# THE NORMAL THE ENGINE WILL COMPUTE, not the one the textbook writes.
	# SurfaceTool.generate_normals() takes Plane(a, b, c).normal, and Godot builds
	# that plane as (a - c) x (a - b) — the NEGATIVE of the usual (b-a) x (c-a),
	# because Godot winds front faces clockwise. Written the textbook way this
	# function flipped every triangle in the mesh and the probe read 0 of 12240
	# outward: perfectly consistent, perfectly inside out, and invisible in a
	# render that draws back faces.
	var n: Vector3 = (a - c).cross(a - b)
	if n.length_squared() < 1.0e-16:
		return                                   # degenerate, contributes nothing
	n = n.normalized()
	var mid: Vector3 = (a + b + c) / 3.0
	var eps: float = cs * 0.35
	if field(parts, mid + n * eps, blend) < field(parts, mid - n * eps, blend):
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)
	else:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)


## The whole convenience: field -> MeshInstance3D, material applied, added to root.
static func add_body(root: Node3D, parts: Array, mat: Material,
		cell: float = 0.055, blend: float = 0.10) -> MeshInstance3D:
	var mesh: ArrayMesh = mesh_of(parts, cell, blend)
	if mesh == null:
		return null
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


# ── the rhizome extensions ─────────────────────────────────────────────────
#
# 2026-09-03, Palle: "use SDF iso surfaces to make a more complex form, not just
# a tunnel — morphogenic, animal machine architecture, radical inside, rhizomatic
# body. right?" Right, and the earlier objection was only half true.
#
# "ONE MARCH CANNOT COVER 20 m" IS A FACT ABOUT ONE MONOLITHIC MARCH, not about
# marching. mesh_of samples a single grid over the whole span, so it hits the
# 220,000-cell cap and coarsens up to 9.31x — a 4 cm request over 20 m comes back
# at 29.8 cm. But the FIELD is analytic and unbounded: nothing stops a caller
# sampling it in local chunks at full resolution and committing one mesh each.
# Two chunks sharing a boundary sample the SAME field on the SAME global lattice,
# so their surfaces agree exactly — the seam is not stitched, it never existed.
# commons/testing/probe_iso_chunks.gd holds that to the float.
#
# The cost is cells x parts, and chunking attacks the SECOND factor too: a 3 m
# chunk of a forty-part rhizome touches six or eight parts, not forty. That is
# what makes an architectural body affordable at body resolution.


## The chunk grid, in metres. 3.0 keeps a chunk near 216,000 cells at 5 cm, just
## inside mesh_of's own budget, and gives streaming and collision a granularity
## that is already about the size of a room.
const CHUNK_M: float = 3.0


## A HOLLOW body: the walkable void is the solid's own interior.
##
## abs(f) - wall is the standard shell trick, and it is the whole of "radical
## inside" in one line. Where f < -wall the point is in the CAVITY and the shell
## field is positive, i.e. empty. Marching it yields both boundaries at once — an
## outer skin and an inner skin with the wall between them — so the rhizome's own
## topology becomes the plan of the building. Every place two limbs smooth-union
## into each other is a place you can walk through, and nobody decided that.
static func shell_field(parts: Array, q: Vector3, blend: float, wall: float) -> float:
	return absf(field(parts, q, blend)) - wall


## The parts whose reach touches a box — the cull that makes chunking pay.
##
## Cost is cells x parts. Chunking divides the first factor; this divides the
## second, and without it a forty-part rhizome pays for all forty in every chunk.
## The reach arithmetic is mesh_of's own, so a part cannot be culled out of a
## chunk it would have contributed to.
static func parts_near(parts: Array, lo: Vector3, hi: Vector3, blend: float, wall: float) -> Array:
	var out: Array = []
	var slack: float = blend + wall + 0.05
	for p_v in parts:
		var p: Dictionary = p_v
		# A CUT IS NEVER CULLED. A subtractor dropped from a chunk leaves the hole
		# it was meant to bore filled in — and filled in SILENTLY, by a chunk that
		# looks like every other chunk. Cuts are few and cost one distance each.
		if bool(p.get("cut", false)):
			out.append(p)
			continue
		var pl := Vector3(1.0e9, 1.0e9, 1.0e9)
		var ph := Vector3(-1.0e9, -1.0e9, -1.0e9)
		var reach: float = float(p.get("r", 0.1)) + slack
		if p.has("h"):
			reach += (p["h"] as Vector3).length()
		if p.has("R"):
			reach += float(p["R"])
		for k in ["a", "b"]:
			if not p.has(k):
				continue
			var q: Vector3 = p[k]
			pl = Vector3(minf(pl.x, q.x - reach), minf(pl.y, q.y - reach), minf(pl.z, q.z - reach))
			ph = Vector3(maxf(ph.x, q.x + reach), maxf(ph.y, q.y + reach), maxf(ph.z, q.z + reach))
		if ph.x < lo.x or pl.x > hi.x or ph.y < lo.y or pl.y > hi.y or ph.z < lo.z or pl.z > hi.z:
			continue
		out.append(p)
	return out


## March one chunk of a shell field at FULL resolution.
##
## Returns null when the chunk is empty, which is most of them — a rhizome is
## mostly the air around it.
static func mesh_chunk(parts: Array, lo: Vector3, hi: Vector3, cell: float,
		blend: float, wall: float) -> ArrayMesh:
	var local: Array = parts_near(parts, lo, hi, blend, wall)
	if local.is_empty():
		return null
	# ONE CELL OF OVERLAP ON EVERY FACE. Without it the two chunks either side of
	# a boundary each stop AT the boundary and neither emits the triangles that
	# straddle it: a continuous surface with a one-cell slot along every chunk
	# line, which in a walkable interior is a crack you can see through. The
	# overlap costs a duplicated rim of triangles in exactly the same place on
	# both sides, because both chunks sample one field on one lattice.
	var elo: Vector3 = lo - Vector3(cell, cell, cell)
	var ehi: Vector3 = hi + Vector3(cell, cell, cell)

	# SNAP THE GRID TO A GLOBAL LATTICE. This is the line the whole scheme rests
	# on: sample positions are floor(q / cell) * cell measured from the WORLD
	# origin, never from the chunk corner, so two chunks sharing a boundary
	# evaluate the field at bitwise-identical points and their surfaces are
	# bitwise identical. Offset each grid by its own corner instead and every
	# seam becomes a ridge that no amount of overlap can fix.
	var g0 := Vector3(floor(elo.x / cell) * cell, floor(elo.y / cell) * cell, floor(elo.z / cell) * cell)
	var nx: int = maxi(1, int(ceil((ehi.x - g0.x) / cell)))
	var ny: int = maxi(1, int(ceil((ehi.y - g0.y) / cell)))
	var nz: int = maxi(1, int(ceil((ehi.z - g0.z) / cell)))
	if nx * ny * nz > 400000:
		push_warning("[dream_iso] chunk of %dx%dx%d cells refused — ask for a smaller chunk_m or a coarser cell" % [nx, ny, nz])
		return null

	var vals := PackedFloat32Array()
	vals.resize((nx + 1) * (ny + 1) * (nz + 1))
	var idx: int = 0
	var any_in: bool = false
	var any_out: bool = false
	for iz in range(nz + 1):
		for iy in range(ny + 1):
			for ix in range(nx + 1):
				var v: float = shell_field(local, Vector3(g0.x + float(ix) * cell,
					g0.y + float(iy) * cell, g0.z + float(iz) * cell), blend, wall)
				vals[idx] = v
				if v <= 0.0:
					any_in = true
				else:
					any_out = true
				idx += 1
	if not (any_in and any_out):
		return null

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var TETS: Array = [[0, 5, 1, 6], [0, 1, 2, 6], [0, 2, 3, 6], [0, 3, 7, 6], [0, 7, 4, 6], [0, 4, 5, 6]]
	var OFF: Array = [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 1, 0), Vector3i(0, 1, 0),
		Vector3i(0, 0, 1), Vector3i(1, 0, 1), Vector3i(1, 1, 1), Vector3i(0, 1, 1)]
	var emitted: int = 0
	for iz in range(nz):
		for iy in range(ny):
			for ix in range(nx):
				var cv := PackedFloat32Array()
				cv.resize(8)
				var cp: Array = []
				var cin: bool = false
				var cout: bool = false
				for c in range(8):
					var o: Vector3i = OFF[c]
					var jx: int = ix + o.x
					var jy: int = iy + o.y
					var jz: int = iz + o.z
					var v2: float = vals[jx + jy * (nx + 1) + jz * (nx + 1) * (ny + 1)]
					cv[c] = v2
					cp.append(Vector3(g0.x + float(jx) * cell, g0.y + float(jy) * cell,
						g0.z + float(jz) * cell))
					if v2 <= 0.0:
						cin = true
					else:
						cout = true
				if not (cin and cout):
					continue
				for t_v in TETS:
					var t: Array = t_v
					emitted += _tet_shell(st, cp, cv, int(t[0]), int(t[1]), int(t[2]), int(t[3]),
						local, blend, wall, cell)
	if emitted == 0:
		return null
	st.generate_normals()
	return st.commit()


## _tet, but asking the SHELL field which way is out.
##
## The winding test in _tet samples field(), which for a hollow body is the wrong
## question: on the inner skin the solid's distance falls as you move into the
## cavity, so the outward direction for the WALL is the opposite of the outward
## direction for the solid. Asking shell_field gets both skins right with no
## special case, because the shell is what these triangles belong to.
static func _tet_shell(st: SurfaceTool, cp: Array, cv: PackedFloat32Array,
		i0: int, i1: int, i2: int, i3: int,
		parts: Array, blend: float, wall: float, cs: float) -> int:
	var p: Array = [cp[i0], cp[i1], cp[i2], cp[i3]]
	var v: Array = [cv[i0], cv[i1], cv[i2], cv[i3]]
	var mask: int = 0
	for i in range(4):
		if float(v[i]) <= 0.0:
			mask |= (1 << i)
	if mask == 0 or mask == 15:
		return 0
	var tri: Array = []
	match mask:
		1, 14:
			tri = [[0, 1], [0, 2], [0, 3]]
		2, 13:
			tri = [[1, 0], [1, 3], [1, 2]]
		4, 11:
			tri = [[2, 0], [2, 1], [2, 3]]
		8, 7:
			tri = [[3, 0], [3, 2], [3, 1]]
		3, 12:
			tri = [[0, 2], [0, 3], [1, 3], [1, 2]]
		5, 10:
			tri = [[0, 1], [0, 3], [2, 3], [2, 1]]
		9, 6:
			tri = [[0, 1], [0, 2], [3, 2], [3, 1]]
	if tri.is_empty():
		return 0
	var pts: Array = []
	for e_v in tri:
		var e: Array = e_v
		pts.append(_lerp_edge(p[int(e[0])], p[int(e[1])], float(v[int(e[0])]), float(v[int(e[1])])))
	if pts.size() == 3:
		_tri_shell(st, pts[0], pts[1], pts[2], parts, blend, wall, cs)
		return 1
	_tri_shell(st, pts[0], pts[1], pts[2], parts, blend, wall, cs)
	_tri_shell(st, pts[0], pts[2], pts[3], parts, blend, wall, cs)
	return 2


## Emit one shell triangle, wound outward, carrying its SUTURE in vertex COLOR.
##
## THE SEAM OF A GROWN BODY IS NOT A PANEL JOINT. arch_surface.gdshader draws its
## seams from a per-quad 0..1 unwrap, and a marched mesh has no quads and no UVs
## to unwrap. But a smooth-union body has something truer: at every point one
## part is nearest and another is second, and where the two are TIED the surface
## is a suture — the morphogenic equivalent of a joint, and the exact place two
## limbs of the rhizome became one. It is a property of the FIELD, so it costs
## one extra evaluation and needs no parameterisation at all.
##
##   COLOR.rgb  the nearest part's own dealt hue, so a limb keeps its identity
##   COLOR.a    1 at a perfect tie, falling to 0 a blend-width away — the suture
static func _tri_shell(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		parts: Array, blend: float, wall: float, cs: float) -> void:
	var n: Vector3 = (a - c).cross(a - b)
	if n.length_squared() < 1.0e-16:
		return
	n = n.normalized()
	var mid: Vector3 = (a + b + c) / 3.0
	var eps: float = cs * 0.35
	var flip: bool = shell_field(parts, mid + n * eps, blend, wall) < shell_field(parts, mid - n * eps, blend, wall)
	var su: Color = suture_at(parts, mid, blend)
	var vs: Array = [a, c, b] if flip else [a, b, c]
	for q_v in vs:
		st.set_color(su)
		st.add_vertex(q_v)


## Which limb is this, and how close is the runner-up.
static func suture_at(parts: Array, q: Vector3, blend: float) -> Color:
	var best: float = 1.0e9
	var second: float = 1.0e9
	var who: int = -1
	for i in range(parts.size()):
		var p: Dictionary = parts[i]
		if bool(p.get("cut", false)):
			continue
		var d: float = _sd_part(p, q)
		if d < best:
			second = best
			best = d
			who = i
		elif d < second:
			second = d
	var tie: float = 1.0
	if second < 1.0e8:
		tie = clampf(1.0 - (second - best) / maxf(blend, 0.001), 0.0, 1.0)
	var col := Color(0.6, 0.6, 0.65)
	if who >= 0:
		var hue: Variant = (parts[who] as Dictionary).get("hue", null)
		if hue is Color:
			col = hue
	col.a = tie
	return col


## The whole rhizome, chunk by chunk.
##
## Returns one entry per non-empty chunk: {mesh, lo, hi, parts}. Empty chunks are
## dropped rather than returned as nulls, because a rhizome is mostly the air
## around it and the caller should not have to filter.
static func mesh_rhizome(parts: Array, cell: float = 0.06, blend: float = 0.55,
		wall: float = 0.30, chunk_m: float = CHUNK_M, pad: float = 0.35) -> Array:
	if parts.is_empty():
		push_warning("[dream_iso] mesh_rhizome called with no parts")
		return []
	var lo := Vector3(1.0e9, 1.0e9, 1.0e9)
	var hi := Vector3(-1.0e9, -1.0e9, -1.0e9)
	for p_v in parts:
		var p: Dictionary = p_v
		if bool(p.get("cut", false)):
			continue
		var reach: float = float(p.get("r", 0.1)) + blend + wall + pad
		if p.has("h"):
			reach += (p["h"] as Vector3).length()
		if p.has("R"):
			reach += float(p["R"])
		for k in ["a", "b"]:
			if not p.has(k):
				continue
			var q: Vector3 = p[k]
			lo = Vector3(minf(lo.x, q.x - reach), minf(lo.y, q.y - reach), minf(lo.z, q.z - reach))
			hi = Vector3(maxf(hi.x, q.x + reach), maxf(hi.y, q.y + reach), maxf(hi.z, q.z + reach))
	var out: Array = []
	var steps := Vector3i(
		maxi(1, int(ceil((hi.x - lo.x) / chunk_m))),
		maxi(1, int(ceil((hi.y - lo.y) / chunk_m))),
		maxi(1, int(ceil((hi.z - lo.z) / chunk_m))))
	for cz in range(steps.z):
		for cy in range(steps.y):
			for cx in range(steps.x):
				var clo := Vector3(lo.x + float(cx) * chunk_m, lo.y + float(cy) * chunk_m,
					lo.z + float(cz) * chunk_m)
				var chi: Vector3 = clo + Vector3(chunk_m, chunk_m, chunk_m)
				var m: ArrayMesh = mesh_chunk(parts, clo, chi, cell, blend, wall)
				if m == null:
					continue
				out.append({"mesh": m, "lo": clo, "hi": chi,
					"parts": parts_near(parts, clo, chi, blend, wall).size()})
	return out
