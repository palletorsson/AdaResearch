extends SceneTree

## WHAT DOES A COARSER MARCH COST THE FETISH IDOL, AND WHAT DOES IT MELT?
## (2026-09-03)
##
## fetish_idol.gd marches one isosurface at const CELL 0.034 and takes about
## 1.7 s. The museum builds halls on the MAIN THREAD during play, so that is a
## 1.7 s frozen frame, and it recurs every time the walker crosses back over
## ~16 m and the segment rebuilds. Coarsening the cell is the obvious fix.
##
## IT IS ALSO THE DANGEROUS ONE, because dream_iso.mesh_of only warns when it
## emits ZERO triangles. A cell that melts the collar off the neck, or rounds the
## heel stilt away, still commits thousands of triangles and says NOTHING. The
## artifact would build faster and quietly stop being the sculpture it is. That
## silence is exactly the failure class this project fears, so this probe exists
## to put numbers where the eye would have to guess.
##
## THE FEATURES AT RISK, from fetish_idol.gd itself:
##   collar torus     minor radius 0.026, at shoulder_y + 0.075
##   heel stilt       radius 0.028 -> 0.036, in the lowest 0.25 m
##   lower forearm    radius 0.036
##   platform sole    half-thickness 0.0175 -> 0.030
## The blend is 0.075, which already fattens all of them, so "radius > cell" is
## not the question. The question is whether the SHAPE still reads.
##
## HOW THAT QUESTION IS ANSWERED HERE, AND WHY IT IS NOT ANSWERED WITH A BOX.
## The first version scored each feature by the surface area inside a hand-drawn
## box around it. It ran, it printed four confident rows, and the collar row was
## a row about the CHEST: the box reported "max |z| 0.150 m" for a torus whose own
## outer radius is 0.084, because the chest capsule ends at the shoulder with
## radius 0.150 and its sphere cap still spans 0.130 at the collar's height. The
## heel-stilt row was likewise partly about the calf. Both looked entirely
## reasonable. That is the exact failure this project fears, produced by this
## probe, on its first run.
##
## So the headline measure is the REMOVAL SWEEP: delete the part from the field,
## march again at the same cell, and measure how far the surface moved. That
## displacement is the feature's relief — what it contributes to the body — and
## it needs no assumption about where the feature lives or what is next to it. It
## also answers a question nobody had asked: whether a feature is on the body AT
## ALL at 0.034. A part the blend has already swallowed cannot be melted by a
## coarser cell, and reporting it as "surviving" would be a lie by omission.
##
## The box measure is still printed, as a neighbourhood second opinion, labelled
## as such. Area is used there rather than vertex count on purpose: vertex count
## falls as 1/cell^2 everywhere, so a raw vertex census would call every feature
## "melted" at 0.066 for a reason that has nothing to do with the shape.
##
## HOW THIS PROBE VARIES A const IT MAY NOT EDIT
## ---------------------------------------------
## CELL is `const CELL: float = 0.034` inside fetish_idol.gd, and this session
## owns only this file. So the probe composes the SAME field itself and hands it
## to Iso.mesh_of at each cell. That is a second implementation of one rule, and
## the corpus's standing lesson (long_museum.py re-deriving the museum's geometry
## in Python and drifting by three passage rows) is that a second implementation
## drifts. So STAGE A is a parity gate: the real fetish_idol.build() runs at its
## own CELL, the replica runs at Idol.CELL through the same mesher, and the two
## vertex arrays must agree to the float. If they do not, every number below is
## about the wrong body and the probe says so and stops. The gate is the only
## thing that makes the duplication safe, and it is what will catch the day
## somebody moves the collar in fetish_idol.gd and not here.
##
## WHY THE FIDELITY NUMBER IS POINT-TO-TRIANGLE AND NOT POINT-TO-VERTEX
## --------------------------------------------------------------------
## Nearest-VERTEX distance between two marched meshes has a floor of about half
## the coarse cell — the coarse mesh simply has no vertex nearer than that, even
## where the two surfaces coincide exactly. At cell 0.066 that floor is ~33 mm,
## which is the same size as the collar's entire protrusion, so the metric would
## drown the signal in its own sampling. The headline number here is therefore
## the distance from a reference vertex to the nearest POINT ON A COARSE
## TRIANGLE, whose floor is the real geometric error. The naive vertex-to-vertex
## number is printed beside it, so the floor effect is visible rather than
## argued about.
##
## WHAT THIS PROBE CANNOT TELL YOU. It runs --headless, and --headless changes
## which code runs: the milliseconds here are CPU march time with no mesh upload
## and no shader compile. Treat the absolute number as a FLOOR on the hall's real
## cost and the RATIO between cells as the transferable result.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_iso_cell_cost.gd
##
## Exits 0 on a completed measurement — it is an instrument, not a gate. It exits
## non-zero only when it could not measure (parity gate broken, or the mesher
## returned nothing), because a measurement that silently measured the wrong
## thing is the failure this file was written against.

const Idol := preload("res://commons/artifacts/dream_bodies/bodies/fetish_idol.gd")
const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")
const REPORT := "res://ada_run/iso_cell_cost.txt"

## fetish_idol.build() passes pad 0.06 as a literal. CELL and BLEND are read off
## the script itself so they cannot drift; pad cannot be, so it is named here and
## the parity gate is what proves the pair still agree.
const PAD: float = 0.06

const CELLS: Array[float] = [0.034, 0.038, 0.042, 0.046, 0.050, 0.058, 0.066]

## Three seeds, because two of the four features are seed-dealt: heel_h is
## 0.16-0.24 and sole_h is 0.035-0.060, so the thinnest sole in the deal is
## 0.0175 half-thickness and the thickest is 0.030 — nearly 2x. A verdict from
## one seed would be a verdict about one body.
const SEEDS: Array[int] = [20260903, 7, 41]

## Full surface fidelity is O(points x triangles) and is a property of the
## marcher, not of the deal, so it runs on the primary seed only. The feature
## checks — which ARE seed-sensitive — run on all three.
const FIDELITY_POINTS: int = 2500

## THE THRESHOLDS ARE JUDGEMENT AND ARE PRINTED SO THEY CAN BE ARGUED WITH.
## A feature keeping 70% of its reference area share is still a feature; below
## that it is a swelling on the body. A reach that has lost more than 15% has
## visibly receded. 8 mm on a 1.68 m body is ~0.5% of height, about the width of
## the collar's own highlight at museum viewing distance.
const AREA_KEEP: float = 0.70
const P95_BUDGET_MM: float = 8.0
## There is deliberately NO reach threshold. The first run gated on "the feature
## keeps 85% of its reach" and the heel stilt scored 1.32 at cell 0.058 — the
## reach was growing, because the box around the stilt also holds the calf
## capsule's lower cap (r 0.070 + blend) and the marcher's rounding moved THAT.
## A metric that can go up when the thing it watches melts is not a gate.

var _lines: Array[String] = []
var _fatal: String = ""
var _build_ms: float = 0.0     # STAGE B's best full build(), quoted again in the verdict
var _timing_contended: bool = false


func _initialize() -> void:
	call_deferred("_run")


# ── the run ────────────────────────────────────────────────────────────────

func _run() -> void:
	_say("[iso-cell] fetish_idol march cost vs geometric fidelity")
	_say("[iso-cell] Idol.CELL=%.4f  Idol.BLEND=%.4f  pad=%.4f  headless CPU only" % [
		float(Idol.CELL), float(Idol.BLEND), PAD])
	_say("[iso-cell] seeds %s   cells %s" % [str(SEEDS), str(CELLS)])
	_say("")

	if not _stage_a_parity():
		_finish()
		return

	_stage_b_real_build_cost()

	var per_seed: Array = []
	for i in range(SEEDS.size()):
		var sd: int = SEEDS[i]
		var full: bool = (i == 0)
		var res: Dictionary = _sweep_seed(sd, full)
		if res.is_empty():
			_finish()
			return
		per_seed.append(res)

	# the marcher's own error at each cell, so the removal sweep can say whether a
	# feature's relief is bigger than the noise coarsening already introduces
	var p95_by_cell: Dictionary = {}
	for r_v in ((per_seed[0] as Dictionary)["rows"] as Array):
		var r: Dictionary = r_v
		p95_by_cell[float(r["cell"])] = float(r["surf_p95_mm"])

	var relief: Dictionary = _stage_f_removal(SEEDS[0], p95_by_cell)
	_stage_d_cross_seed(per_seed)
	_stage_e_verdict(per_seed, relief)
	_finish()


# ── STAGE A: the parity gate ───────────────────────────────────────────────
#
# The whole probe rests on the replica field being the same field. Without this
# gate the probe could measure a body that fetish_idol.gd stopped building
# months ago and every table below would be confidently, silently wrong.

func _stage_a_parity() -> bool:
	var sd: int = SEEDS[0]
	var root := Node3D.new()
	Idol.build(root, sd, {})
	var real_mesh: ArrayMesh = _body_mesh_of(root)
	if real_mesh == null:
		_fatal = ("fetish_idol.build(seed %d) produced no ArrayMesh body — there is nothing "
			+ "to measure against") % sd
		_say("[iso-cell] PARITY  *** %s ***" % _fatal)
		root.free()
		return false

	var deal: Dictionary = _deal(sd)
	var replica: ArrayMesh = Iso.mesh_of(deal["parts"], float(Idol.CELL), float(Idol.BLEND), PAD)
	if replica == null:
		_fatal = "the replica field meshed to nothing at Idol.CELL — the copy is broken"
		_say("[iso-cell] PARITY  *** %s ***" % _fatal)
		root.free()
		return false

	var a: PackedVector3Array = real_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var b: PackedVector3Array = replica.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	root.free()

	if a.size() != b.size():
		_fatal = ("the replica field has DRIFTED from fetish_idol.gd: %d vertices vs %d. "
			+ "Someone changed the body and not this probe; every number below would be "
			+ "about the wrong sculpture") % [a.size(), b.size()]
		_say("[iso-cell] PARITY  *** %s ***" % _fatal)
		return false

	var worst: float = 0.0
	for i in range(a.size()):
		worst = maxf(worst, (a[i] - b[i]).length())
	if worst > 0.0000005:
		_fatal = ("the replica field has DRIFTED from fetish_idol.gd: same vertex count but "
			+ "worst vertex is %.7f m away" % worst)
		_say("[iso-cell] PARITY  *** %s ***" % _fatal)
		return false

	_say("[iso-cell] PARITY  replica == fetish_idol.build at cell %.4f: %d vertices, worst delta %.9f m  OK" % [
		float(Idol.CELL), a.size(), worst])
	_say("[iso-cell]          (this gate is what lets the probe vary a const it may not edit)")
	_say("")
	return true


# ── STAGE B: what the hall actually pays today ─────────────────────────────

func _stage_b_real_build_cost() -> void:
	var sd: int = SEEDS[0]
	var runs: Array[float] = []
	for run in range(4):
		var root := Node3D.new()
		var t0: int = Time.get_ticks_usec()
		Idol.build(root, sd, {})
		runs.append(float(Time.get_ticks_usec() - t0) / 1000.0)
		root.free()
	var best: float = runs[1]
	for i in range(1, runs.size()):
		best = minf(best, runs[i])
	_say("[iso-cell] FULL fetish_idol.build() at CELL %.4f, seed %d:" % [float(Idol.CELL), sd])
	_say("[iso-cell]   run 1 %8.1f ms (discarded: first-call script warmup)" % runs[0])
	_say("[iso-cell]   runs 2-4 %5.1f / %.1f / %.1f ms" % [runs[1], runs[2], runs[3]])
	_build_ms = best
	_say("[iso-cell]   BEST  %8.1f ms  <- the number to quote" % best)
	_say("[iso-cell]   The spread across runs 2-4 is the machine, not the code — quote the best.")
	_say("[iso-cell]   build() = the march + plinth + two materials + the fit/centre pass.")
	_say("")


# ── STAGE C: one seed across every cell ────────────────────────────────────

func _sweep_seed(sd: int, full_fidelity: bool) -> Dictionary:
	var deal: Dictionary = _deal(sd)
	var parts: Array = deal["parts"]
	var regions: Array = _regions(deal)

	_say("[iso-cell] ---- seed %d ----" % sd)

	# WARM PASS, discarded. The first call into mesh_of for a given script pays
	# GDScript's own first-call cost; the corpus has been burned by quoting it.
	for c in CELLS:
		var warm: ArrayMesh = Iso.mesh_of(parts, c, float(Idol.BLEND), PAD)
		if warm == null:
			_fatal = "mesh_of returned NOTHING at cell %.3f, seed %d" % [c, sd]
			_say("[iso-cell]   *** %s ***" % _fatal)
			return {}

	var rows: Array = []
	var ref_row: Dictionary = {}
	for c in CELLS:
		# THREE TIMED RUNS, KEEP THE MINIMUM. The first version reported a single
		# run and the same cell measured 2707, 1875 and 1747 ms on three consecutive
		# invocations — a 35% spread, entirely from whatever else the machine was
		# doing. Two runs was still not enough: a later pass measured cell 0.042 at
		# 1850 ms against 0.034's 1621, which is impossible, because 0.042 marches
		# a third fewer triangles. Another Godot was running. The minimum of three
		# is the least-interrupted run, and _check_monotonic below refuses to let a
		# contended series be quoted as if it were a measurement.
		var mesh: ArrayMesh = null
		var ms: float = 1.0e9
		for _pass in range(3):
			var t0: int = Time.get_ticks_usec()
			mesh = Iso.mesh_of(parts, c, float(Idol.BLEND), PAD)
			ms = minf(ms, float(Time.get_ticks_usec() - t0) / 1000.0)
		if mesh == null:
			_fatal = "mesh_of returned NOTHING at cell %.3f, seed %d on the timed pass" % [c, sd]
			_say("[iso-cell]   *** %s ***" % _fatal)
			return {}
		var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var row: Dictionary = {
			"cell": c,
			"ms": ms,
			"verts": verts.size(),
			"tris": verts.size() / 3,
			"aabb": _aabb_of(verts),
			"feat": _measure_regions(verts, regions),
			"total_area": _total_area(verts),
		}
		if c == CELLS[0]:
			ref_row = row
			row["surf_mean_mm"] = 0.0
			row["surf_p95_mm"] = 0.0
			row["surf_max_mm"] = 0.0
			row["vtx_p95_mm"] = 0.0
			row["brute"] = 0
		elif full_fidelity:
			var ref_v: PackedVector3Array = ref_row["ref_verts"]
			var fid: Dictionary = _fidelity(ref_v, verts, c)
			row["surf_mean_mm"] = fid["mean_mm"]
			row["surf_p95_mm"] = fid["p95_mm"]
			row["surf_max_mm"] = fid["max_mm"]
			row["vtx_p95_mm"] = fid["vtx_p95_mm"]
			row["brute"] = fid["brute"]
		else:
			row["surf_mean_mm"] = -1.0
			row["surf_p95_mm"] = -1.0
			row["surf_max_mm"] = -1.0
			row["vtx_p95_mm"] = -1.0
			row["brute"] = 0
		if c == CELLS[0]:
			row["ref_verts"] = verts
		rows.append(row)

	_print_cost_table(rows, sd)
	_check_monotonic(rows, sd)
	_print_feature_table(rows, regions, sd)
	return {"seed": sd, "rows": rows, "regions": regions, "deal": deal}


## A COARSER CELL CANNOT COST MORE. It samples a smaller lattice and emits fewer
## triangles, and the triangle column proves that held. So if the millisecond
## column is not monotonically falling, the clock was measuring the machine and
## not the march — another Godot on the box, most likely, which this project
## already knows to serialize. The geometry in the same row is still exact
## (mesh_of is deterministic); only the timing is spoiled. Saying so is the whole
## point: a contended series looks exactly like a real one, and the RECOMMENDATION
## reads the timing.
func _check_monotonic(rows: Array, sd: int) -> void:
	var bad: Array[String] = []
	for i in range(1, rows.size()):
		var prev: Dictionary = rows[i - 1]
		var cur: Dictionary = rows[i]
		if float(cur["ms"]) > float(prev["ms"]):
			bad.append("%.3f (%.0f ms) is SLOWER than %.3f (%.0f ms) despite %d fewer triangles" % [
				float(cur["cell"]), float(cur["ms"]), float(prev["cell"]), float(prev["ms"]),
				int(prev["tris"]) - int(cur["tris"])])
	if bad.is_empty():
		_say("[iso-cell]   timing sanity: cost falls monotonically with cell size  OK")
		_say("")
		return
	_timing_contended = true
	_say("[iso-cell]   *** TIMING IS CONTENDED FOR SEED %d — DO NOT QUOTE THE ms COLUMN ***" % sd)
	for b in bad:
		_say("[iso-cell]       %s" % b)
	_say("[iso-cell]       A coarser cell cannot cost more. Something else was using the CPU —")
	_say("[iso-cell]       most likely a second Godot, which this project serializes for exactly")
	_say("[iso-cell]       this reason. Re-run alone. The geometry and fidelity columns above are")
	_say("[iso-cell]       unaffected: mesh_of is deterministic and the triangle counts are right.")
	_say("")


func _print_cost_table(rows: Array, sd: int) -> void:
	_say("[iso-cell] seed %d — march cost and shape" % sd)
	_say("[iso-cell]   cell    ms     x/0.034  tris    verts   AABB w x h x d (m)    surf mean  surf p95  surf max  vtxNN p95")
	var base_ms: float = float((rows[0] as Dictionary)["ms"])
	for r_v in rows:
		var r: Dictionary = r_v
		var box: AABB = r["aabb"]
		var fid: String = "     -         -         -         -   "
		if float(r["surf_p95_mm"]) >= 0.0:
			fid = "%8.2f  %8.2f  %8.2f  %8.2f" % [float(r["surf_mean_mm"]), float(r["surf_p95_mm"]),
				float(r["surf_max_mm"]), float(r["vtx_p95_mm"])]
		_say("[iso-cell]   %.3f %7.1f  %6.2fx  %6d  %6d  %.3f %.3f %.3f   %s" % [
			float(r["cell"]), float(r["ms"]), float(r["ms"]) / maxf(base_ms, 0.001),
			int(r["tris"]), int(r["verts"]),
			box.size.x, box.size.y, box.size.z, fid])
	if float((rows[1] as Dictionary)["surf_p95_mm"]) >= 0.0:
		_say("[iso-cell]   surf * = reference vertex -> nearest point on the coarse SURFACE, mm.")
		_say("[iso-cell]   vtxNN  = the naive vertex-to-vertex p95, mm — its floor is ~cell/2, which")
		_say("[iso-cell]            is why it is not the headline. Compare the two columns.")
		var brutes: int = 0
		for r2_v in rows:
			var r2: Dictionary = r2_v
			brutes += int(r2["brute"])
		if brutes > 0:
			_say("[iso-cell]   NOTE %d query point(s) fell out of the spatial hash and used brute force." % brutes)
	_say("")


func _print_feature_table(rows: Array, regions: Array, sd: int) -> void:
	_say("[iso-cell] seed %d — per-NEIGHBOURHOOD survival: the share of the body's surface area" % sd)
	_say("[iso-cell]           and the reach inside a box drawn around each feature, as a")
	_say("[iso-cell]           fraction of the 0.034 reference.")
	_say("[iso-cell]   READ THIS AS CONTEXT, NOT AS THE FEATURE. A box around the collar also")
	_say("[iso-cell]   contains the chest capsule's sphere cap (r 0.150 at the shoulder), and a")
	_say("[iso-cell]   box around the heel stilt also contains the calf's lower cap (r 0.070).")
	_say("[iso-cell]   The feature's own contribution is measured in the REMOVAL SWEEP below.")
	var ref: Dictionary = (rows[0] as Dictionary)["feat"]
	for ri in range(regions.size()):
		var reg: Dictionary = regions[ri]
		var rname: String = reg["name"]
		var rref: Dictionary = ref[rname]
		if float(rref["area"]) <= 0.0:
			_say("[iso-cell]   %-12s *** NOT MEASURABLE: the reference has NO surface in this region ***" % rname)
			_say("[iso-cell]                the region box is wrong, or this seed does not build the feature")
			continue
		_say("[iso-cell]   %-12s reference: area %.5f m2 (%.2f%% of body), %s %.4f m, %d verts" % [
			rname, float(rref["area"]), float(rref["share"]) * 100.0,
			String(reg["reach_label"]), float(rref["reach"]), int(rref["verts"])])
		var line: String = "[iso-cell]                "
		for r_v in rows:
			var r: Dictionary = r_v
			var f: Dictionary = (r["feat"] as Dictionary)[rname]
			var share_ratio: float = float(f["share"]) / maxf(float(rref["share"]), 1.0e-9)
			var reach_ratio: float = float(f["reach"]) / maxf(float(rref["reach"]), 1.0e-9)
			line += "%.3f:area %.2f reach %.2f | " % [float(r["cell"]), share_ratio, reach_ratio]
		_say(line)
	_say("")


# ── STAGE F: THE REMOVAL SWEEP — the only assumption-free feature measure ──
#
# WHY THIS STAGE EXISTS, AND WHAT IT CAUGHT. The first version of this probe
# scored each feature by the surface area inside a hand-drawn box around it. The
# collar box reported "max |z| 0.150 m" — but the collar torus's own outer radius
# is 0.058 + 0.026 = 0.084. The box was not measuring the collar at all; it was
# measuring the CHEST capsule, whose top end has radius 0.150 and whose sphere cap
# still spans 0.130 at the collar's height. Every collar number in that table was
# a number about the chest, and it looked completely reasonable.
#
# So the feature is not located by arithmetic here. It is located by DELETING it:
# march the field with the part and without it, at the same cell, and measure how
# far the surface moved. That displacement IS the feature's relief — what it
# contributes to the body — and it needs no guess about where the feature lives or
# what else is nearby.
#
# Two things fall out of one measurement:
#   at cell 0.034 the relief says whether the feature is VISIBLE AT ALL. A part
#     the blend has already swallowed cannot be melted by a coarser cell, and a
#     probe that reports it "surviving" is reporting on nothing.
#   across cells the relief ratio says whether it is melting.

func _stage_f_removal(sd: int, p95_by_cell: Dictionary) -> Dictionary:
	var deal: Dictionary = _deal(sd)
	var parts: Array = deal["parts"]
	var idx: Dictionary = deal["idx"]
	var names: Array = ["collar", "heel_stilt", "forearm", "platform"]

	_say("[iso-cell] REMOVAL SWEEP, seed %d — delete the part, remesh, measure how far the" % sd)
	_say("[iso-cell] surface moved. RELIEF (mm) is what the feature contributes to the body.")
	_say("[iso-cell]")
	_say("[iso-cell] THE FLOOR UNDER THESE NUMBERS. mesh_of derives its sample grid from the")
	_say("[iso-cell] parts it is given, so deleting a part can shift the lattice and the two")
	_say("[iso-cell] meshes then disagree slightly everywhere, not only where the feature was.")
	_say("[iso-cell] The last column is therefore the honest reading: a relief SMALLER than the")
	_say("[iso-cell] deviation coarsening itself introduces at that cell is not a feature the")
	_say("[iso-cell] cell is protecting — it is under the march's own noise.")
	_say("[iso-cell]   feature      cell   relief max   relief mean   surface it owns   vs march p95")

	# the intact body at each cell is the same for all four features — marched once
	# rather than 4x, which is 20 s of the run
	var intact: Dictionary = {}
	for c in CELLS:
		var m: ArrayMesh = Iso.mesh_of(parts, c, float(Idol.BLEND), PAD)
		if m == null:
			_fatal = "the intact body meshed to nothing at cell %.3f in the removal sweep" % c
			_say("[iso-cell]   *** %s ***" % _fatal)
			return {}
		intact[c] = m.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

	var out: Dictionary = {}
	for nm_v in names:
		var nm: String = nm_v
		var drop: Array = idx[nm]
		var lean_parts: Array = []
		for i in range(parts.size()):
			if drop.has(i):
				continue
			lean_parts.append(parts[i])
		# only vertices near the deleted part can move — the smooth union's reach
		# is about one blend beyond the part's own surface. Querying the whole body
		# would be 8x the work for the same answer.
		var near: AABB = _parts_aabb(_subset(parts, drop)).grow(float(Idol.BLEND) * 2.0 + 0.05)

		var rows: Array = []
		for c in CELLS:
			var without: ArrayMesh = Iso.mesh_of(lean_parts, c, float(Idol.BLEND), PAD)
			if without == null:
				_say("[iso-cell]   %-12s %.3f  *** the body without %s meshed to NOTHING ***" % [nm, c, nm])
				continue
			var wv: PackedVector3Array = intact[c]
			var ov: PackedVector3Array = without.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var r: Dictionary = _relief(wv, ov, near, c)
			r["cell"] = c
			var p95: float = float(p95_by_cell.get(c, 0.0))
			var verdict: String = "reference"
			if p95 > 0.0:
				verdict = "%.1fx p95 %s" % [float(r["max_mm"]) / p95,
					"ABOVE" if float(r["max_mm"]) > p95 else "*** UNDER NOISE ***"]
			r["above_noise"] = (p95 <= 0.0) or (float(r["max_mm"]) > p95)
			rows.append(r)
			_say("[iso-cell]   %-12s %.3f  %9.2f    %9.2f     %6.2f%% of body area   %s" % [
				nm, c, float(r["max_mm"]), float(r["mean_mm"]), float(r["owned_share"]) * 100.0,
				verdict])
		out[nm] = rows
		# THE LOUD CASE: a feature the reference cell cannot show is not at risk
		# from a coarser cell, and saying "it survived" about it would be a lie by
		# omission. 1 mm on a 1.68 m body is below anything a viewer can see.
		if not rows.is_empty():
			var ref0: Dictionary = rows[0]
			if float(ref0["max_mm"]) < 1.0:
				_say("[iso-cell]   *** %s IS ALREADY INVISIBLE AT CELL %.3f: deleting it moves the" % [nm, CELLS[0]])
				_say("[iso-cell]       surface by %.2f mm. The blend of %.3f has swallowed it whole." % [
					float(ref0["max_mm"]), float(Idol.BLEND)])
				_say("[iso-cell]       No cell can melt what is not there — this is a fault in the BODY,")
				_say("[iso-cell]       not in the march, and it is not an argument for keeping %.3f." % CELLS[0])
		_say("")

	# THE ANSWER TO THE QUESTION THAT WAS ASKED, in one line per feature.
	_say("[iso-cell] DOES RELIEF DECAY? — relief at the coarsest cell as a fraction of the")
	_say("[iso-cell] reference. This, not the neighbourhood boxes, is the melt test.")
	for nm2_v in names:
		var nm2: String = nm2_v
		var rr: Array = out[nm2]
		if rr.size() < 2:
			continue
		var first: Dictionary = rr[0]
		var last: Dictionary = rr[rr.size() - 1]
		var keep: float = float(last["max_mm"]) / maxf(float(first["max_mm"]), 1.0e-9)
		var word: String = "HOLDS"
		if keep < AREA_KEEP:
			word = "*** MELTS ***"
		var noisy: String = ""
		if not bool(last["above_noise"]):
			noisy = "  (and it is under the march's own p95 at that cell, so this ratio is noise)"
		_say("[iso-cell]   %-12s %.2f mm -> %.2f mm at %.3f = %.0f%%  %s%s" % [
			nm2, float(first["max_mm"]), float(last["max_mm"]), float(last["cell"]),
			keep * 100.0, word, noisy])
	_say("")
	return out


## How far did the surface move when the part was deleted? Measured from the
## WITH-mesh's vertices (restricted to the part's neighbourhood) to the
## WITHOUT-mesh's surface, so it is a true geometric displacement and not a
## vertex-sampling artifact.
func _relief(withv: PackedVector3Array, withoutv: PackedVector3Array, near: AABB,
		cell: float) -> Dictionary:
	var bucket: float = maxf(cell, 0.03)
	var h: Dictionary = _hash_triangles(withoutv, bucket)
	var total_area: float = 0.0
	var owned_area: float = 0.0
	var sum: float = 0.0
	var n: int = 0
	var worst: float = 0.0
	for i in range(0, withv.size(), 3):
		var a: Vector3 = withv[i]
		var b: Vector3 = withv[i + 1]
		var c: Vector3 = withv[i + 2]
		var area: float = 0.5 * (b - a).cross(c - a).length()
		total_area += area
		var mid: Vector3 = (a + b + c) / 3.0
		if not near.has_point(mid):
			continue
		var d: float = _nearest_triangle(mid, withoutv, h, bucket)
		if d >= 1.0e8:
			d = _brute_triangle(mid, withoutv)
		sum += d
		n += 1
		worst = maxf(worst, d)
		# "owned" = the triangles the feature actually put there. 1 mm is the
		# floor of visibility, not a tuning knob.
		if d > 0.001:
			owned_area += area
	return {
		"max_mm": worst * 1000.0,
		"mean_mm": (sum / maxf(float(n), 1.0)) * 1000.0,
		"owned_share": owned_area / maxf(total_area, 1.0e-9),
		"probed": n,
	}


func _subset(parts: Array, keep: Array) -> Array:
	var out: Array = []
	for i in keep:
		out.append(parts[int(i)])
	return out


## The same box mesh_of derives for a field, so "near the part" means the same
## thing to this probe as it does to the marcher.
func _parts_aabb(parts: Array) -> AABB:
	var lo := Vector3(1.0e9, 1.0e9, 1.0e9)
	var hi := Vector3(-1.0e9, -1.0e9, -1.0e9)
	for p_v in parts:
		var p: Dictionary = p_v
		var c: Vector3 = p["a"]
		var reach: float = float(p.get("r", 0.1))
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
	return AABB(lo, hi - lo)


# ── STAGE D: does the deal change the answer? ──────────────────────────────

func _stage_d_cross_seed(per_seed: Array) -> void:
	_say("[iso-cell] WORST CASE ACROSS %d SEEDS — the smallest area ratio and reach ratio any" % per_seed.size())
	_say("[iso-cell] feature reached at each cell. This is the column the verdict reads, because")
	_say("[iso-cell] heel_h and sole_h are dealt and a thin-soled body melts before a thick one.")
	_say("[iso-cell]   cell    worst area  worst reach  (the feature that was worst)")
	for ci in range(CELLS.size()):
		var c: float = CELLS[ci]
		var worst_area: float = 9.0
		var worst_reach: float = 9.0
		var who_a: String = "-"
		var who_r: String = "-"
		for ps_v in per_seed:
			var ps: Dictionary = ps_v
			var rows: Array = ps["rows"]
			var regions: Array = ps["regions"]
			var ref: Dictionary = (rows[0] as Dictionary)["feat"]
			var cur: Dictionary = (rows[ci] as Dictionary)["feat"]
			for reg_v in regions:
				var reg: Dictionary = reg_v
				var rname: String = reg["name"]
				var rr: Dictionary = ref[rname]
				if float(rr["area"]) <= 0.0:
					continue
				var cc: Dictionary = cur[rname]
				var ar: float = float(cc["share"]) / maxf(float(rr["share"]), 1.0e-9)
				var re: float = float(cc["reach"]) / maxf(float(rr["reach"]), 1.0e-9)
				if ar < worst_area:
					worst_area = ar
					who_a = "%s/seed %d" % [rname, int(ps["seed"])]
				if re < worst_reach:
					worst_reach = re
					who_r = "%s/seed %d" % [rname, int(ps["seed"])]
		_say("[iso-cell]   %.3f     %.3f       %.3f      area:%s  reach:%s" % [
			c, worst_area, worst_reach, who_a, who_r])
	_say("")


# ── STAGE E: one recommendation, and why ───────────────────────────────────

func _stage_e_verdict(per_seed: Array, relief: Dictionary) -> void:
	_say("[iso-cell] THRESHOLDS (mine, printed so they can be argued with):")
	_say("[iso-cell]   a VISIBLE feature keeps >= %.0f%% of its reference RELIEF (removal sweep)" % (AREA_KEEP * 100.0))
	_say("[iso-cell]   its neighbourhood keeps >= %.0f%% of its reference area share" % (AREA_KEEP * 100.0))
	_say("[iso-cell]   surface p95 deviation <= %.1f mm (~0.5%% of a 1.68 m body)" % P95_BUDGET_MM)
	_say("[iso-cell]   a feature whose relief at %.3f is already under 1 mm is EXCLUDED from the" % CELLS[0])
	_say("[iso-cell]   verdict, because it is not on the body and cannot be protected by a cell.")
	_say("")

	var primary: Dictionary = per_seed[0]
	var prows: Array = primary["rows"]
	var best_cell: float = CELLS[0]
	var best_ms: float = float((prows[0] as Dictionary)["ms"])
	var base_ms: float = float((prows[0] as Dictionary)["ms"])
	var first_fail: String = ""

	for ci in range(CELLS.size()):
		var c: float = CELLS[ci]
		var ok: bool = true
		var why: String = ""
		# THE PRIMARY GATE: the removal sweep, which measures the feature itself
		for nm_v in relief.keys():
			var nm: String = nm_v
			var rr_rows: Array = relief[nm]
			if rr_rows.size() <= ci:
				continue
			var base: Dictionary = rr_rows[0]
			if float(base["max_mm"]) < 1.0:
				continue                        # already invisible: nothing to lose
			var here: Dictionary = rr_rows[ci]
			var keep: float = float(here["max_mm"]) / maxf(float(base["max_mm"]), 1.0e-9)
			if keep < AREA_KEEP:
				ok = false
				why = "%s relief falls to %.0f%% (%.1f mm of %.1f mm)" % [
					nm, keep * 100.0, float(here["max_mm"]), float(base["max_mm"])]
		# the neighbourhood boxes, across every seed, as a second opinion
		for ps_v in per_seed:
			var ps: Dictionary = ps_v
			var rows: Array = ps["rows"]
			var regions: Array = ps["regions"]
			var ref: Dictionary = (rows[0] as Dictionary)["feat"]
			var cur: Dictionary = (rows[ci] as Dictionary)["feat"]
			for reg_v in regions:
				var reg: Dictionary = reg_v
				var rname: String = reg["name"]
				var rr: Dictionary = ref[rname]
				if float(rr["area"]) <= 0.0:
					continue
				var cc: Dictionary = cur[rname]
				var ar: float = float(cc["share"]) / maxf(float(rr["share"]), 1.0e-9)
				if ar < AREA_KEEP:
					ok = false
					why = "the %s neighbourhood keeps only %.0f%% of its area share (seed %d)" % [
						rname, ar * 100.0, int(ps["seed"])]
		var p95: float = float((prows[ci] as Dictionary)["surf_p95_mm"])
		if ok and p95 >= 0.0 and p95 > P95_BUDGET_MM:
			ok = false
			why = "surface p95 is %.1f mm, over the %.1f mm budget" % [p95, P95_BUDGET_MM]
		if not ok:
			# STOP at the first failure rather than looking for a coarser cell that
			# happens to score better. Degradation here is not guaranteed monotonic
			# and "0.066 passed but 0.050 did not" would be an artifact of the
			# region boxes, not a licence to ship 0.066.
			first_fail = "%.3f fails: %s" % [c, why]
			break
		best_cell = c
		best_ms = float((prows[ci] as Dictionary)["ms"])

	_say("[iso-cell] ================ RECOMMENDATION ================")
	if _timing_contended:
		_say("[iso-cell] *** THE MILLISECONDS BELOW ARE CONTENDED — see the timing-sanity failure")
		_say("[iso-cell]     above. The CELL is still sound (it comes from geometry, which is")
		_say("[iso-cell]     deterministic); the SAVING is not. Re-run with no other Godot alive. ***")
	if is_equal_approx(best_cell, CELLS[0]):
		_say("[iso-cell] NO COARSER CELL IS SAFE. Keep CELL at %.3f and cache the mesh instead." % CELLS[0])
		_say("[iso-cell] Reason: the first step up already breaks a feature — %s" % first_fail)
	else:
		_say("[iso-cell] CELL = %.3f  (march %.1f ms, %.2fx the %.1f ms at %.3f)" % [
			best_cell, best_ms, best_ms / maxf(base_ms, 0.001), base_ms, CELLS[0]])
		_say("[iso-cell] Reason: it is the coarsest cell at which every VISIBLE feature still")
		_say("[iso-cell] shapes the body by %.0f%% of the relief it has at %.3f, measured by" % [
			AREA_KEEP * 100.0, CELLS[0]])
		_say("[iso-cell] deleting each part and remeshing, across %d seeds%s." % [
			per_seed.size(),
			"" if first_fail == "" else " — the next step, " + first_fail])
	_say("[iso-cell] ===============================================")

	# WHICH GATE ACTUALLY BOUND THE ANSWER. If no feature melted, the answer is a
	# judgement about general surface fidelity, not a measurement of damage, and
	# saying so is more useful than the number on its own.
	var melted: bool = false
	for nm_v in relief.keys():
		var rr_rows: Array = relief[nm_v]
		if rr_rows.size() < 2:
			continue
		var f0: Dictionary = rr_rows[0]
		var fl: Dictionary = rr_rows[rr_rows.size() - 1]
		if float(f0["max_mm"]) >= 1.0 and float(fl["max_mm"]) / maxf(float(f0["max_mm"]), 1.0e-9) < AREA_KEEP:
			melted = true
	if not melted:
		var last_row: Dictionary = prows[prows.size() - 1]
		_say("[iso-cell] NOTE — NO FEATURE MELTED AT ANY CELL TESTED, INCLUDING %.3f." % CELLS[CELLS.size() - 1])
		_say("[iso-cell] The four features named as at risk all keep their relief to the coarsest")
		_say("[iso-cell] cell in the sweep. The blend of %.3f has already fattened every one of" % float(Idol.BLEND))
		_say("[iso-cell] them past the cell sizes tested, so the thing a coarser march costs here")
		_say("[iso-cell] is GENERAL surface fidelity, not any named feature.")
		_say("[iso-cell] The recommendation above is therefore bound by the %.1f mm p95 budget," % P95_BUDGET_MM)
		_say("[iso-cell] which is a judgement, not damage. If %.1f mm p95 is acceptable, %.3f is" % [
			float(last_row["surf_p95_mm"]), float(last_row["cell"])])
		_say("[iso-cell] available at %.1f ms — %.2fx the reference — with every feature intact." % [
			float(last_row["ms"]), float(last_row["ms"]) / maxf(base_ms, 0.001)])
	# WHAT A CELL CHANGE CANNOT BUY, so the parent can price the alternative. If
	# the march is the whole of build(), then caching the ArrayMesh removes ~all
	# of the cost, and a cell change only ever removes a fraction of it.
	_say("[iso-cell] THE MARCH IS %.0f%% OF build() (%.1f ms of %.1f ms). Everything else — the" % [
		(base_ms / maxf(_build_ms, 0.001)) * 100.0, base_ms, _build_ms])
	_say("[iso-cell] plinth, both materials, the fit and centre pass — is the remainder. So a")
	_say("[iso-cell] cached mesh removes essentially the whole %.1f ms." % _build_ms)
	var saved_rec: float = base_ms - best_ms
	var saved_max: float = base_ms - float((prows[prows.size() - 1] as Dictionary)["ms"])
	_say("[iso-cell]   cache             saves ~%5.0f ms" % _build_ms)
	_say("[iso-cell]   cell %.3f (rec)   saves  %5.0f ms  = %.2fx what the cache saves" % [
		best_cell, saved_rec, saved_rec / maxf(_build_ms, 0.001)])
	_say("[iso-cell]   cell %.3f (max)   saves  %5.0f ms  = %.2fx what the cache saves" % [
		CELLS[CELLS.size() - 1], saved_max, saved_max / maxf(_build_ms, 0.001)])
	_say("[iso-cell] Remember the headless caveat: these ms are CPU march only. The hall also")
	_say("[iso-cell] pays mesh upload and the plinth/material/fit pass measured in STAGE B.")


# ── the replica field ──────────────────────────────────────────────────────
#
# A LINE-FOR-LINE COPY of fetish_idol.build()'s geometry half, in the same rng
# order, so the same seed deals the same body. STAGE A proves it. If you change
# fetish_idol.gd's proportions or parts, STAGE A will fail loudly and name the
# vertex counts; change this function to match, do not delete the gate.

func _deal(seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var hip_y: float = rng.randf_range(0.80, 0.90)
	var shoulder_y: float = hip_y + rng.randf_range(0.44, 0.52)
	var head_y: float = shoulder_y + rng.randf_range(0.18, 0.23)
	var hip_w: float = rng.randf_range(0.155, 0.205)
	var shoulder_w: float = rng.randf_range(0.150, 0.200)
	var lean: float = rng.randf_range(-0.075, 0.075)
	var contra: float = rng.randf_range(0.03, 0.085) * (1.0 if rng.randf() < 0.5 else -1.0)
	var heel_h: float = rng.randf_range(0.16, 0.24)
	var sole_h: float = rng.randf_range(0.035, 0.060)

	var parts: Array = []

	# WHICH PART IS WHICH, recorded where it is appended rather than counted by
	# hand afterwards — a hard-coded index would survive an edit to the body and
	# then silently delete the wrong capsule in the removal sweep.
	var idx_sole: Array[int] = []
	var idx_stilt: Array[int] = []
	var idx_forearm: Array[int] = []

	for s_v in [-1.0, 1.0]:
		var s: float = s_v
		var fx: float = s * hip_w * 0.55
		var fz: float = contra * s * 0.5
		idx_sole.append(parts.size())
		parts.append(Iso.box(Vector3(fx, sole_h * 0.5, fz + 0.035),
			Vector3(0.062, sole_h * 0.5, 0.115), 0.02))
		idx_stilt.append(parts.size())
		parts.append(Iso.capsule(Vector3(fx, sole_h, fz - 0.05),
			Vector3(fx, sole_h + heel_h, fz - 0.03), 0.028, 0.036))
		parts.append(Iso.capsule(Vector3(fx, sole_h + heel_h * 0.6, fz),
			Vector3(fx + s * 0.012, hip_y * 0.52, fz + contra), 0.070, 0.085))
		parts.append(Iso.capsule(Vector3(fx + s * 0.012, hip_y * 0.52, fz + contra),
			Vector3(s * hip_w * 0.48, hip_y, 0.0), 0.085, 0.105))

	parts.append(Iso.capsule(Vector3(-hip_w * 0.42, hip_y, 0.0),
		Vector3(hip_w * 0.42, hip_y, 0.0), 0.155, 0.155))
	var waist_y: float = hip_y + (shoulder_y - hip_y) * 0.40
	parts.append(Iso.capsule(Vector3(lean * 0.3, hip_y + 0.02, 0.0),
		Vector3(lean * 0.6, waist_y, 0.01), 0.135, 0.115))
	parts.append(Iso.capsule(Vector3(lean * 0.6, waist_y, 0.01),
		Vector3(lean, shoulder_y, 0.0), 0.120, 0.150))
	parts.append(Iso.capsule(Vector3(lean - shoulder_w * 0.5, shoulder_y, 0.0),
		Vector3(lean + shoulder_w * 0.5, shoulder_y, 0.0), 0.098, 0.098))

	var raised: float = 1.0 if rng.randf() < 0.5 else -1.0
	# the LOWERED arm carries the forearm this probe watches (r 0.048 -> 0.036)
	var low_sx: float = 0.0
	var low_elb := Vector3.ZERO
	var low_end := Vector3.ZERO
	for s2_v in [-1.0, 1.0]:
		var s2: float = s2_v
		var sx: float = lean + s2 * (shoulder_w * 0.5 + 0.03)
		if s2 == raised:
			var elb := Vector3(sx + s2 * 0.16, shoulder_y + 0.02, -0.04)
			parts.append(Iso.capsule(Vector3(sx, shoulder_y, 0.0), elb, 0.060, 0.048))
			parts.append(Iso.capsule(elb, Vector3(sx + s2 * 0.20, shoulder_y + 0.30, -0.02), 0.048, 0.038))
		else:
			var elb2 := Vector3(sx + s2 * 0.035, shoulder_y - 0.26, 0.02)
			parts.append(Iso.capsule(Vector3(sx, shoulder_y, 0.0), elb2, 0.060, 0.048))
			idx_forearm.append(parts.size())
			parts.append(Iso.capsule(elb2, Vector3(sx + s2 * 0.07, shoulder_y - 0.50, 0.05), 0.048, 0.036))
			low_sx = sx
			low_elb = elb2
			low_end = Vector3(sx + s2 * 0.07, shoulder_y - 0.50, 0.05)

	parts.append(Iso.capsule(Vector3(lean, shoulder_y, 0.0), Vector3(lean, head_y - 0.10, 0.0), 0.052, 0.048))
	var idx_collar: int = parts.size()
	parts.append(Iso.torus(Vector3(lean, shoulder_y + 0.075, 0.0), 0.058, 0.026, Vector3.UP))
	parts.append(Iso.sphere(Vector3(lean, head_y, 0.0), 0.105))
	parts.append(Iso.cut(Iso.sphere(Vector3(lean, waist_y + 0.05, 0.14), 0.105)))

	return {
		"parts": parts, "hip_y": hip_y, "shoulder_y": shoulder_y, "head_y": head_y,
		"hip_w": hip_w, "shoulder_w": shoulder_w, "lean": lean, "contra": contra,
		"heel_h": heel_h, "sole_h": sole_h, "waist_y": waist_y, "raised": raised,
		"low_elb": low_elb, "low_end": low_end, "low_sx": low_sx,
		"idx": {
			"collar": [idx_collar] as Array[int],
			"heel_stilt": idx_stilt,
			"forearm": idx_forearm,
			"platform": idx_sole,
		},
	}


# ── the four regions at risk ───────────────────────────────────────────────
#
# Each region is a predicate over a triangle's centroid plus a "reach" — the
# feature's own outermost measure, so a feature that has receded rather than
# vanished still shows up. The regions are cut from the DEALT proportions, not
# from constants, because heel_h and sole_h differ per seed.

func _regions(deal: Dictionary) -> Array:
	var lean: float = deal["lean"]
	var shoulder_y: float = deal["shoulder_y"]
	var sole_h: float = deal["sole_h"]
	var heel_h: float = deal["heel_h"]
	var hip_w: float = deal["hip_w"]
	var contra: float = deal["contra"]
	var collar_y: float = shoulder_y + 0.075

	return [
		{
			# THE COLLAR. Sampled front-and-back of the neck (|x - lean| small),
			# because left and right of the neck at this height is the shoulder
			# capsule, which is 0.098 fat and would drown the ring's 0.026.
			# Reach = how far the surface stands out in z. If the torus melts
			# flush the reach falls back toward the neck+shoulder's own bulge.
			"name": "collar",
			"kind": "box_z",
			"y_lo": collar_y - 0.038, "y_hi": collar_y + 0.038,
			"x_lo": lean - 0.045, "x_hi": lean + 0.045,
			"reach_label": "max |z|",
		},
		{
			# THE HEEL STILT, middle half only — the ends are inside the sole's
			# and the calf's blends and would report their fat, not the stilt's.
			# Reach = distance from the stilt's own axis, i.e. the stilt's radius.
			"name": "heel_stilt",
			"kind": "axis",
			# the calf capsule STARTS at sole_h + heel_h * 0.6 and its lower sphere
			# cap (r 0.070 + blend) hangs well below that, so the band stops at 0.50
			# and is still not clean. The removal sweep is what actually isolates it.
			"y_lo": sole_h + heel_h * 0.20, "y_hi": sole_h + heel_h * 0.50,
			"axis_a": Vector3(-hip_w * 0.55, sole_h, contra * -0.5 - 0.05),
			"axis_b": Vector3(-hip_w * 0.55, sole_h + heel_h, contra * -0.5 - 0.03),
			"axis_a2": Vector3(hip_w * 0.55, sole_h, contra * 0.5 - 0.05),
			"axis_b2": Vector3(hip_w * 0.55, sole_h + heel_h, contra * 0.5 - 0.03),
			"reach_label": "max r from stilt axis",
		},
		{
			# THE LOWER FOREARM, the r 0.036 end of the lowered arm.
			"name": "forearm",
			"kind": "axis",
			"y_lo": deal["low_end"].y - 0.02, "y_hi": deal["low_end"].y + 0.14,
			"axis_a": deal["low_elb"], "axis_b": deal["low_end"],
			"axis_a2": deal["low_elb"], "axis_b2": deal["low_end"],
			"reach_label": "max r from forearm axis",
		},
		{
			# THE PLATFORM SOLE: everything at or below the sole box's own top.
			# Reach = max z, the toe. A melted platform pulls the toe back toward
			# the stilt and the shoe stops being a shoe.
			"name": "platform",
			"kind": "box_z",
			"y_lo": -1.0, "y_hi": sole_h,
			"x_lo": -9.0, "x_hi": 9.0,
			"reach_label": "max z (toe)",
		},
	]


func _measure_regions(verts: PackedVector3Array, regions: Array) -> Dictionary:
	var out: Dictionary = {}
	var total: float = 0.0
	var acc: Array = []
	for _r in regions:
		acc.append({"area": 0.0, "reach": 0.0, "verts": 0})

	for i in range(0, verts.size(), 3):
		var a: Vector3 = verts[i]
		var b: Vector3 = verts[i + 1]
		var c: Vector3 = verts[i + 2]
		var area: float = 0.5 * (b - a).cross(c - a).length()
		total += area
		var mid: Vector3 = (a + b + c) / 3.0
		for ri in range(regions.size()):
			var reg: Dictionary = regions[ri]
			if mid.y < float(reg["y_lo"]) or mid.y > float(reg["y_hi"]):
				continue
			var bucket: Dictionary = acc[ri]
			if String(reg["kind"]) == "box_z":
				if mid.x < float(reg["x_lo"]) or mid.x > float(reg["x_hi"]):
					continue
				bucket["area"] = float(bucket["area"]) + area
				bucket["verts"] = int(bucket["verts"]) + 3
				for p in [a, b, c]:
					bucket["reach"] = maxf(float(bucket["reach"]), absf((p as Vector3).z))
			else:
				# axis regions: belong to whichever stilt/arm axis is nearer, and
				# only if the centroid is within a plausible sleeve of it — a
				# triangle 0.3 m away in the same y band is the other leg or the
				# torso, not this feature.
				var d1: float = _seg_dist(mid, reg["axis_a"], reg["axis_b"])
				var d2: float = _seg_dist(mid, reg["axis_a2"], reg["axis_b2"])
				var dn: float = minf(d1, d2)
				if dn > 0.13:
					continue
				var use_first: bool = d1 <= d2
				bucket["area"] = float(bucket["area"]) + area
				bucket["verts"] = int(bucket["verts"]) + 3
				for p2 in [a, b, c]:
					var dv: float = 0.0
					if use_first:
						dv = _seg_dist(p2, reg["axis_a"], reg["axis_b"])
					else:
						dv = _seg_dist(p2, reg["axis_a2"], reg["axis_b2"])
					bucket["reach"] = maxf(float(bucket["reach"]), dv)
			acc[ri] = bucket

	for ri in range(regions.size()):
		var reg2: Dictionary = regions[ri]
		var bk: Dictionary = acc[ri]
		bk["share"] = float(bk["area"]) / maxf(total, 1.0e-9)
		out[String(reg2["name"])] = bk
	return out


func _seg_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab: Vector3 = b - a
	var denom: float = maxf(0.000001, ab.dot(ab))
	var h: float = clampf((p - a).dot(ab) / denom, 0.0, 1.0)
	return (p - (a + ab * h)).length()


# ── fidelity: reference vertex -> nearest point on the coarse SURFACE ──────

func _fidelity(ref_verts: PackedVector3Array, coarse: PackedVector3Array, cell: float) -> Dictionary:
	# subsample the reference by a stride, so the sample is spread over the whole
	# body rather than over whichever slab the marcher happened to emit first
	var stride: int = maxi(1, int(ceil(float(ref_verts.size()) / float(FIDELITY_POINTS))))
	var pts: PackedVector3Array = PackedVector3Array()
	for i in range(0, ref_verts.size(), stride):
		pts.append(ref_verts[i])

	var bucket: float = maxf(cell, 0.03)
	var tri_hash: Dictionary = _hash_triangles(coarse, bucket)
	var vtx_hash: Dictionary = _hash_points(coarse, bucket)

	var dists: PackedFloat32Array = PackedFloat32Array()
	var vdists: PackedFloat32Array = PackedFloat32Array()
	dists.resize(pts.size())
	vdists.resize(pts.size())
	var brute: int = 0
	for i in range(pts.size()):
		var p: Vector3 = pts[i]
		var d: float = _nearest_triangle(p, coarse, tri_hash, bucket)
		if d >= 1.0e8:
			# the hash could not reach it: fall back to brute force rather than
			# silently record a bogus distance. Counted and printed — a probe that
			# quietly degraded its own metric is the failure this file fears.
			brute += 1
			d = _brute_triangle(p, coarse)
		dists[i] = d
		vdists[i] = _nearest_point(p, coarse, vtx_hash, bucket)

	dists.sort()
	vdists.sort()
	var sum: float = 0.0
	for d2 in dists:
		sum += d2
	var n: int = dists.size()
	return {
		"mean_mm": (sum / maxf(float(n), 1.0)) * 1000.0,
		"p95_mm": float(dists[mini(n - 1, int(float(n) * 0.95))]) * 1000.0,
		"max_mm": float(dists[n - 1]) * 1000.0,
		"vtx_p95_mm": float(vdists[mini(n - 1, int(float(n) * 0.95))]) * 1000.0,
		"brute": brute,
		"sampled": n,
	}


func _key(ix: int, iy: int, iz: int) -> int:
	# collision-free for any grid under 1024 cells a side; the body's widest span
	# is ~2.1 m and the smallest bucket 0.03 m, so ~70 cells.
	return (ix + 512) + (iy + 512) * 1024 + (iz + 512) * 1048576


func _hash_triangles(verts: PackedVector3Array, bucket: float) -> Dictionary:
	var h: Dictionary = {}
	for i in range(0, verts.size(), 3):
		var a: Vector3 = verts[i]
		var b: Vector3 = verts[i + 1]
		var c: Vector3 = verts[i + 2]
		var lo := Vector3(minf(a.x, minf(b.x, c.x)), minf(a.y, minf(b.y, c.y)), minf(a.z, minf(b.z, c.z)))
		var hi := Vector3(maxf(a.x, maxf(b.x, c.x)), maxf(a.y, maxf(b.y, c.y)), maxf(a.z, maxf(b.z, c.z)))
		for ix in range(int(floor(lo.x / bucket)), int(floor(hi.x / bucket)) + 1):
			for iy in range(int(floor(lo.y / bucket)), int(floor(hi.y / bucket)) + 1):
				for iz in range(int(floor(lo.z / bucket)), int(floor(hi.z / bucket)) + 1):
					var k: int = _key(ix, iy, iz)
					# a plain Array, NOT a PackedInt32Array: packed arrays are
					# copy-on-write value types, so read-append-writeback would be
					# O(n) per insert and quietly turn this into O(n^2)
					if not h.has(k):
						h[k] = []
					(h[k] as Array).append(i)
	return h


func _hash_points(verts: PackedVector3Array, bucket: float) -> Dictionary:
	var h: Dictionary = {}
	for i in range(verts.size()):
		var v: Vector3 = verts[i]
		var k: int = _key(int(floor(v.x / bucket)), int(floor(v.y / bucket)), int(floor(v.z / bucket)))
		if not h.has(k):
			h[k] = []
		(h[k] as Array).append(i)
	return h


## Expand shells until the best distance found is provably inside the searched
## radius. Hash collisions can only ADD real triangles, which can only lower a
## true minimum, so they cost time and never correctness; MISSING a cell would
## cost correctness, which is what the shell guarantee prevents.
func _nearest_triangle(p: Vector3, verts: PackedVector3Array, h: Dictionary, bucket: float) -> float:
	var cx: int = int(floor(p.x / bucket))
	var cy: int = int(floor(p.y / bucket))
	var cz: int = int(floor(p.z / bucket))
	var best: float = 1.0e9
	var ring: int = 0
	while ring <= 6:
		for dx in range(-ring, ring + 1):
			for dy in range(-ring, ring + 1):
				for dz in range(-ring, ring + 1):
					if maxi(absi(dx), maxi(absi(dy), absi(dz))) != ring:
						continue
					var k: int = _key(cx + dx, cy + dy, cz + dz)
					if not h.has(k):
						continue
					for ti_v in (h[k] as Array):
						var ti: int = ti_v
						var d: float = _pt_tri(p, verts[ti], verts[ti + 1], verts[ti + 2])
						best = minf(best, d)
		if best < 1.0e8 and best <= float(ring) * bucket:
			return best
		ring += 1
	return best


func _brute_triangle(p: Vector3, verts: PackedVector3Array) -> float:
	var best: float = 1.0e9
	for i in range(0, verts.size(), 3):
		best = minf(best, _pt_tri(p, verts[i], verts[i + 1], verts[i + 2]))
	return best


func _nearest_point(p: Vector3, verts: PackedVector3Array, h: Dictionary, bucket: float) -> float:
	var cx: int = int(floor(p.x / bucket))
	var cy: int = int(floor(p.y / bucket))
	var cz: int = int(floor(p.z / bucket))
	var best: float = 1.0e9
	var ring: int = 0
	while ring <= 6:
		for dx in range(-ring, ring + 1):
			for dy in range(-ring, ring + 1):
				for dz in range(-ring, ring + 1):
					if maxi(absi(dx), maxi(absi(dy), absi(dz))) != ring:
						continue
					var k: int = _key(cx + dx, cy + dy, cz + dz)
					if not h.has(k):
						continue
					for vi_v in (h[k] as Array):
						var vi: int = vi_v
						best = minf(best, (p - verts[vi]).length())
		if best < 1.0e8 and best <= float(ring) * bucket:
			return best
		ring += 1
	return best


## Closest distance from a point to a triangle (Ericson's region test). Written
## out rather than approximated by the three edges, because the interior case is
## the common one here and edge-only would over-report on every flat panel.
func _pt_tri(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> float:
	var ab: Vector3 = b - a
	var ac: Vector3 = c - a
	var ap: Vector3 = p - a
	var d1: float = ab.dot(ap)
	var d2: float = ac.dot(ap)
	if d1 <= 0.0 and d2 <= 0.0:
		return ap.length()
	var bp: Vector3 = p - b
	var d3: float = ab.dot(bp)
	var d4: float = ac.dot(bp)
	if d3 >= 0.0 and d4 <= d3:
		return bp.length()
	var vc: float = d1 * d4 - d3 * d2
	if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
		var v: float = d1 / maxf(d1 - d3, 1.0e-20)
		return (p - (a + ab * v)).length()
	var cp: Vector3 = p - c
	var d5: float = ab.dot(cp)
	var d6: float = ac.dot(cp)
	if d6 >= 0.0 and d5 <= d6:
		return cp.length()
	var vb: float = d5 * d2 - d1 * d6
	if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
		var w: float = d2 / maxf(d2 - d6, 1.0e-20)
		return (p - (a + ac * w)).length()
	var va: float = d3 * d6 - d5 * d4
	if va <= 0.0 and (d4 - d3) >= 0.0 and (d5 - d6) >= 0.0:
		var w2: float = (d4 - d3) / maxf((d4 - d3) + (d5 - d6), 1.0e-20)
		return (p - (b + (c - b) * w2)).length()
	var denom: float = 1.0 / maxf(va + vb + vc, 1.0e-20)
	var vv: float = vb * denom
	var ww: float = vc * denom
	return (p - (a + ab * vv + ac * ww)).length()


# ── small helpers ──────────────────────────────────────────────────────────

func _body_mesh_of(root: Node3D) -> ArrayMesh:
	# the body is the ArrayMesh child; the plinth is a BoxMesh. Named explicitly
	# rather than taken as child 0, so a future extra child does not silently
	# make this probe measure the plinth.
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var mi: MeshInstance3D = ch
		if mi.mesh is ArrayMesh:
			return mi.mesh
	return null


func _aabb_of(verts: PackedVector3Array) -> AABB:
	if verts.is_empty():
		return AABB()
	var lo: Vector3 = verts[0]
	var hi: Vector3 = verts[0]
	for v in verts:
		lo = Vector3(minf(lo.x, v.x), minf(lo.y, v.y), minf(lo.z, v.z))
		hi = Vector3(maxf(hi.x, v.x), maxf(hi.y, v.y), maxf(hi.z, v.z))
	return AABB(lo, hi - lo)


func _total_area(verts: PackedVector3Array) -> float:
	var t: float = 0.0
	for i in range(0, verts.size(), 3):
		t += 0.5 * (verts[i + 1] - verts[i]).cross(verts[i + 2] - verts[i]).length()
	return t


func _say(s: String) -> void:
	_lines.append(s)
	print(s)


func _finish() -> void:
	if _fatal != "":
		_say("")
		_say("[iso-cell] COULD NOT MEASURE: %s" % _fatal)
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	else:
		print("[iso-cell] *** could not write %s ***" % REPORT)
	quit(0 if _fatal == "" else 2)
