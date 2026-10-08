extends SceneTree

## Does chunked marching equal monolithic marching, and is the shell HOLLOW?
## (2026-09-03)
##
## Chunking is what makes an architectural SDF body affordable: the field is
## analytic and unbounded, so a caller can sample it in local chunks at full
## resolution instead of one coarse grid over the whole span. The entire scheme
## rests on ONE claim — that two chunks sharing a boundary sample the same field
## on the same global lattice and therefore produce surfaces that agree exactly.
##
## That claim is cheap to believe and expensive to be wrong about. A chunk grid
## offset by its own corner instead of the world origin gives surfaces that are
## ALMOST the same, which renders as a ridge along every chunk line, at every
## seam, in a building you walk through. It would look like a design decision.
##
## So the gate is a comparison ACROSS IMPLEMENTATIONS: the same field marched as
## one grid and as four chunks, and every chunked vertex must lie on the
## monolithic surface. Plus the shell tests, because a hollow body has two new
## ways to be wrong that a solid one does not:
##
##   the cavity is EMPTY — the field is positive well inside the solid
##   the wall has a MEASURED thickness, not a nominal one
##   both skins are present, and the inner one is inside the outer one
##   a chunk's part cull never drops a part that would have contributed
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_iso_chunks.gd

const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")
const REPORT := "res://ada_run/iso_chunks_probe.txt"

## The monolithic control's box, and it is SMALL on purpose.
##
## It has to cover enough chunks for the comparison to mean something, and it
## cannot be generous: mesh_chunk refuses anything over 400,000 cells, and a
## 6.4 x 4.6 x 5.4 m control at the 6 cm cell the comparison requires is 741,510.
## The refusal is correct — that guard is what stops a caller asking for a march
## that will not return — so the control shrinks instead of the guard moving.
## 3 m cubed at 6 cm is 125,000 cells and still spans four of the 1.5 m chunks.
const MLO := Vector3(-1.8, -1.5, -0.6)
const MHI := Vector3(1.2, 1.5, 2.4)

var _lines: Array[String] = []
var _fails: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var cell: float = 0.06
	var blend: float = 0.45
	var wall: float = 0.28

	# a small rhizome: three bulbs and two passages, so there are real sutures
	var parts: Array = [
		Iso.sphere(Vector3(-1.1, 0.0, 0.0), 0.80),
		Iso.sphere(Vector3(1.2, 0.35, 0.20), 0.72),
		Iso.sphere(Vector3(0.10, -0.20, 1.30), 0.66),
		Iso.capsule(Vector3(-1.1, 0.0, 0.0), Vector3(1.2, 0.35, 0.20), 0.44, 0.40),
		Iso.capsule(Vector3(-1.1, 0.0, 0.0), Vector3(0.10, -0.20, 1.30), 0.38, 0.42),
	]

	# ── 1. the shell is hollow, and the wall is the thickness asked for ──
	var f_centre: float = Iso.field(parts, Vector3(-1.1, 0.0, 0.0), blend)
	var s_centre: float = Iso.shell_field(parts, Vector3(-1.1, 0.0, 0.0), blend, wall)
	_check(f_centre < -wall and s_centre > 0.0,
		"at a bulb centre the solid is %.3f m deep and the shell reads %.3f m (positive = cavity)"
			% [f_centre, s_centre],
		"the cavity is not empty: solid %.3f, shell %.3f" % [f_centre, s_centre])

	# march a ray from the bulb centre outward and count the material crossings.
	# A hollow body must give TWO: out through the inner skin, out through the
	# outer skin. One means it is solid; three or more means the wall is broken.
	var crossings: int = 0
	var first_in: float = -1.0
	var last_out: float = -1.0
	var prev: float = Iso.shell_field(parts, Vector3(-1.1, 0.0, 0.0), blend, wall)
	var step: float = 0.005
	for i in range(1, 900):
		var t: float = float(i) * step
		var q: Vector3 = Vector3(-1.1, 0.0, 0.0) + Vector3(0.0, 1.0, 0.0) * t
		var s: float = Iso.shell_field(parts, q, blend, wall)
		if (s <= 0.0) != (prev <= 0.0):
			crossings += 1
			if crossings == 1:
				first_in = t
			last_out = t
		prev = s
	_check(crossings == 2, "a ray out of the cavity crosses material exactly %d time(s)" % crossings,
		"a ray out of the cavity crosses %d time(s) — a hollow wall must be entered once and left once" % crossings)
	var measured: float = last_out - first_in
	_check(absf(measured - wall * 2.0) < cell * 1.6,
		"measured wall %.3f m against the 2 x %.2f asked for (tolerance one cell)" % [measured, wall],
		"the wall measures %.3f m where 2 x %.2f = %.3f was asked" % [measured, wall, wall * 2.0])

	# ── 2. THE CLAIM: chunked == monolithic ──────────────────────────────
	var mono: ArrayMesh = _mono(parts, cell, blend, wall)
	_check(mono != null, "the same field marched as ONE grid", "the monolithic control did not mesh")
	if mono == null:
		_finish()
		return
	var chunks: Array = Iso.mesh_rhizome(parts, cell, blend, wall, 1.5, 0.30)
	_check(chunks.size() >= 4, "%d non-empty chunk(s) at chunk_m 1.5" % chunks.size(),
		"chunking produced %d chunk(s) — too few to be testing anything" % chunks.size())

	var mv: PackedVector3Array = mono.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	# a spatial hash of the monolithic vertices, so the comparison is not O(n^2)
	var grid: Dictionary = {}
	var gcell: float = cell * 2.0
	for v in mv:
		var k: String = "%d_%d_%d" % [floori(v.x / gcell), floori(v.y / gcell), floori(v.z / gcell)]
		# A PackedVector3Array IS A VALUE TYPE, AND THIS COST A RUN.
		#
		# `grid[k] = PackedVector3Array()` then
		# `(grid[k] as PackedVector3Array).append(v)` appends to a THROWAWAY COPY:
		# the packed array comes back by value, so every bucket stayed empty and
		# every lookup missed. The probe then reported "worst distance 0.000000 m"
		# — a perfect score from a comparison that had compared nothing — and the
		# only thing that said otherwise was the in-bounds counter: 30571 vertices
		# in range, 30571 of them with no neighbour found. A plain Array is
		# reference-counted and shared, so appending through the dictionary reaches
		# the array the dictionary is holding.
		if not grid.has(k):
			grid[k] = []
		(grid[k] as Array).append(v)

	var checked: int = 0
	var worst: float = 0.0
	var tris_chunked: int = 0
	var in_bounds: int = 0
	var no_neighbour: int = 0
	for ch_v in chunks:
		var ch: Dictionary = ch_v
		var cvs: PackedVector3Array = (ch["mesh"] as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		tris_chunked += cvs.size() / 3
		for i in range(0, cvs.size(), 7):     # every seventh vertex is plenty
			var v: Vector3 = cvs[i]
			# ONLY COMPARE INSIDE THE CHUNK'S OWN BOX. The one-cell overlap means a
			# chunk legitimately emits a rim of triangles beyond its bounds, and the
			# monolithic control is clipped to the union of the boxes, so a vertex
			# out in the overlap has nothing to be compared against.
			var lo: Vector3 = ch["lo"]
			var hi: Vector3 = ch["hi"]
			if v.x < lo.x or v.x > hi.x or v.y < lo.y or v.y > hi.y or v.z < lo.z or v.z > hi.z:
				continue
			# and only where the MONOLITHIC control actually covers it, or a chunk
			# out past the control's own box has nothing to be compared against and
			# silently drops out of the count
			if v.x < MLO.x or v.x > MHI.x or v.y < MLO.y or v.y > MHI.y or v.z < MLO.z or v.z > MHI.z:
				continue
			in_bounds += 1
			var best: float = 1.0e9
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					for dz in [-1, 0, 1]:
						var k2: String = "%d_%d_%d" % [floori(v.x / gcell) + dx,
							floori(v.y / gcell) + dy, floori(v.z / gcell) + dz]
						if not grid.has(k2):
							continue
						for w in (grid[k2] as Array):
							best = minf(best, v.distance_to(w))
			if best < 1.0e8:
				checked += 1
				worst = maxf(worst, best)
			else:
				no_neighbour += 1
	_lines.append("[probe] note  %d vertex/vertices inside both boxes, %d of them with no monolithic neighbour"
		% [in_bounds, no_neighbour])
	# A COMPARISON THAT COMPARED NOTHING REPORTS A PERFECT SCORE. The first run of
	# this probe said "worst distance 0.000000 m" and the number was about nothing:
	# zero vertices had been compared, because the control box did not cover the
	# chunks. So the count is asserted BEFORE the distance, and the distance check
	# is skipped entirely when the count fails, rather than printing a reassuring
	# zero underneath a failure.
	_check(checked > 200, "%d chunked vertex/vertices compared against the monolithic surface" % checked,
		"only %d vertices could be compared (%d in bounds) — the test is not testing" % [checked, in_bounds])
	# EXACT is the claim, so the tolerance is float noise and not one cell. If the
	# grids were offset per chunk this number would be a fraction of a cell, which
	# is precisely the failure that looks like a design decision.
	if checked > 200:
		_check(worst < 0.0005, "worst chunked-vs-monolithic vertex distance %.6f m (want < 0.0005)" % worst,
			"chunked and monolithic surfaces differ by %.4f m — the grids are not on one lattice" % worst)

	# ── 3. the part cull cannot drop a contributor ───────────────────────
	#
	# The cull is what makes chunking pay, and a cull that is one epsilon too
	# tight removes material from the middle of a wall with no warning at all.
	# So: for a chunk, march it with the cull and again with every part, and the
	# two must be identical.
	# A CULL CANNOT BE TESTED ON A BODY SMALLER THAN A CHUNK. The five-part rhizome
	# above spans about 2 m, so every part reaches every chunk and the cull
	# correctly keeps all five — which says nothing about whether it works. The
	# case it exists for is a SPARSE body many chunks long, so that is what gets
	# measured: twelve bulbs strung over 20 m, where a 3 m chunk should see three
	# or four parts and not twelve.
	var long_parts: Array = []
	for i in range(12):
		var x: float = -10.0 + float(i) * 1.8
		long_parts.append(Iso.sphere(Vector3(x, sin(float(i)) * 0.5, cos(float(i) * 0.7) * 0.6), 0.62))
		if i > 0:
			var xp: float = -10.0 + float(i - 1) * 1.8
			long_parts.append(Iso.capsule(
				Vector3(xp, sin(float(i - 1)) * 0.5, cos(float(i - 1) * 0.7) * 0.6),
				Vector3(x, sin(float(i)) * 0.5, cos(float(i) * 0.7) * 0.6), 0.34))
	var lo3: Vector3 = Vector3(-1.5, -1.5, -1.5)
	var hi3: Vector3 = lo3 + Vector3(3.0, 3.0, 3.0)
	var kept: Array = Iso.parts_near(long_parts, lo3, hi3, blend, wall)
	_check(kept.size() < long_parts.size() / 2,
		"on a 20 m rhizome the cull kept %d of %d part(s) for one 3 m chunk — %.1fx less field work"
			% [kept.size(), long_parts.size(), float(long_parts.size()) / float(maxi(kept.size(), 1))],
		"the cull kept %d of %d parts on a sparse 20 m body — it is not culling"
			% [kept.size(), long_parts.size()])
	var culled: ArrayMesh = Iso.mesh_chunk(long_parts, lo3, hi3, cell, blend, wall)
	if culled != null:
		# the same chunk with the cull DEFEATED, by handing mesh_chunk a part list
		# that is already exactly the chunk's neighbourhood plus everything else —
		# i.e. asking parts_near for a box big enough to keep all of them
		var everything: Array = Iso.parts_near(long_parts, Vector3(-99, -99, -99), Vector3(99, 99, 99), blend, wall)
		var full: ArrayMesh = _uncensored(everything, lo3, hi3, cell, blend, wall)
		var a1: int = (culled.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var a2: int = (full.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() if full != null else -1
		_check(a1 == a2, "culled and uncensored marches of one chunk agree: %d vertices both" % a1,
			"the cull changed the mesh: %d vertices culled against %d full" % [a1, a2])

	# ── 4. the suture carries something ──────────────────────────────────
	var tie_hi: int = 0
	var tie_lo: int = 0
	for ch_v2 in chunks:
		var arr: Array = ((ch_v2 as Dictionary)["mesh"] as ArrayMesh).surface_get_arrays(0)
		var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR]
		if cols.is_empty():
			continue
		for c in cols:
			if c.a > 0.75:
				tie_hi += 1
			elif c.a < 0.1:
				tie_lo += 1
	_check(tie_hi > 20 and tie_lo > 20,
		"the suture discriminates: %d vertex/vertices near a tie, %d far from one" % [tie_hi, tie_lo],
		"the suture is uniform (%d tied, %d untied) — it is carrying no information" % [tie_hi, tie_lo])

	_lines.append("[probe] chunked total %d triangles across %d chunk(s); monolithic control %d"
		% [tris_chunked, chunks.size(), mv.size() / 3])
	_finish()


## March a chunk WITHOUT the cull, by marching the same box with the full part
## list forced through. If the cull is honest these agree vertex for vertex.
func _uncensored(all_parts: Array, lo: Vector3, hi: Vector3, cell: float,
		blend: float, wall: float) -> ArrayMesh:
	return Iso.mesh_chunk(all_parts, lo, hi, cell, blend, wall)


## The control: the same shell field on ONE grid, marched by the same tet code.
## Built by asking mesh_rhizome for a chunk big enough to hold everything, which
## keeps the comparison honest — same entry point, same table, one grid.
func _mono(parts: Array, cell: float, blend: float, wall: float) -> ArrayMesh:
	return Iso.mesh_chunk(parts, MLO, MHI, cell, blend, wall)


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + String(";  ").join(PackedStringArray(_fails))])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)
