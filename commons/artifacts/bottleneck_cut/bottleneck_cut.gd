class_name BottleneckCut
extends Node3D

# @identity
# essence: one s-t network drawn twice over — the cut a max-flow saturation proves minimal, and the cut a seeded Karger contraction actually returned — with a three-bar ledger where PUSHED and CUT are equal by theorem and FOUND is only ever greater or equal
# desire: to photograph the moment the two parents disagree: at bottleneck=mixed, against=capacity, the pale found-blade stands at x=-0.1575 and the solid min-blade at x=+0.1575, a third of the field apart, and the ledger reads found 18 against cut 9
# critical_parameter: against — it chooses the WEIGHT VECTOR, and the weight vector is the whole disagreement: `edges` hands every edge the same weight (Karger's world, where a cut is a COUNT) and the other three hand it its capacity (the theorem's world, where a cut is a SUM)
# triggers: none. There is no _process, no clock and no interaction; every mark is a function of (bottleneck, against, karger_seed, karger_runs) computed once in _ready
# emerges: max flow equals min cut in all sixteen cells, and Karger's answer is right in twelve of them and wrong in four — not because it was unlucky but because it was never asked the capacity question
# needs: nothing. No Label3D, no slider, no button — the ledger is the readout
# relationships: synthesis of karger_algorithm and networkflow3d (sequence 21, graphtheory), which declare `bottleneck` identically and mean different things by it
# truth: a minimum cut is not a thing an algorithm makes, it is a thing the network already has — and which algorithm you point at it decides whether you are told about the narrowest place or merely a narrow place

## bottleneck_cut — WAVE 24 SYNTHESIS of karger_algorithm + networkflow3d.
##
## THE FAMILY HYPOTHESIS AND WHAT READING IT FOUND. The two sources declare
## `bottleneck` = mixed | throat | braid | severed, identically, and the
## suspicion was that they are max-flow min-cut from opposite ends. They are —
## at `severed` and nowhere else. The word means different things in the two
## files, and the difference is not a nuance:
##
##   networkflow3d.gd:59-70 is a CAPACITY axis. `throat` forces every route
##   through one min_capacity edge (a 0.019 m hair against 0.150 m mains,
##   _build_edges_throat, :305-358); `braid` sets every capacity to
##   max_capacity and keeps THE SAME EDGE SET (_build_edges_scattered's
##   `uniform` branch, :282-301, and its own comment says so). Nothing about
##   the topology moves.
##
##   karger_algorithm.gd:32-48 is a TOPOLOGY axis. `throat` is two 4-cliques
##   plus two bridges (_build_two_cliques, :274-283); `braid` is a
##   near-complete graph, 24 edges, every vertex of degree 6 (_build_braid,
##   :291-297). There are no capacities anywhere in that file. Karger's cut is
##   a COUNT.
##
## So `braid` means "every capacity equal" in one file and "many more edges" in
## the other, and the two claims are not even about the same kind of object.
## This bench keeps both: the four values change the EDGE SET (karger's half)
## and the CAPACITIES (networkflow3d's half), and the second axis, `against`,
## is which of the two questions you ask of the result.
##
## ── AXIS 1: bottleneck — what the network is ───────────────────────────────
##
##   mixed     19 edges, capacities scattered 3..9. The source's own two edges
##             cost 9 each and the sink's three cost 3 each, so the CHEAPEST
##             cut (9, at the sink) and the SMALLEST cut (2 edges, at the
##             source) are at opposite ends of the board. This is the cell
##             where the two parents disagree, and it is the default.
##   throat    the four col2-col3 crossings deleted but one, and that one given
##             capacity 2 against mains of 9. Min cut = {4-7}, capacity 2,
##             cardinality 1 — the one value where every reading agrees, and
##             almost nothing gets through.
##   braid     19 base edges plus 6 chords, every capacity 9. No narrow place;
##             the min cut is the sink's own star, 3 edges at 27. Counting and
##             summing become the same question here, which is the designed
##             null below.
##   severed   throat's edge set with the bridge REMOVED and the two components
##             pulled +/-0.032 m apart along x, opening 0.143 m of empty field.
##             Max flow 0, min cut 0, all three bars empty frames. The cut was
##             never something an algorithm made.
##
## `mixed` IS NOT AN ALL-RUNGS VALUE and was checked for. Waves 20-21 found nine
## values in the corpus that were the union of their own axis, and `mixed` is
## the obvious candidate here because both sources gloss it negatively — "no
## particular narrow place" (networkflow3d.gd:61). A union value would have to
## contain a throat AND a braid AND a severance at once. This one contains none
## of them: it is a connected 19-edge network whose min cut is unique (9, next
## cheapest 18) and whose cardinality min cut is unique (2, next 3). It makes a
## claim the other three do not — that the narrowest place and the cheapest
## place can be different places — and that claim is the pass's finding.
##
## ── AXIS 2: against — what the cut is read AGAINST ───────────────────────────
##
## A min cut is only meaningful against a weight. This axis IS the weight
## vector, and everything downstream (which cut is minimal, how thick each pipe
## is, how tall the bars stand) is a function of it.
##
##   edges     every edge weighs MAXCAP, whatever its capacity. Karger's world:
##             a cut is a number of edges. Pipes are drawn at uniform full bore
##             because that is what an unweighted algorithm sees.
##   capacity  every edge weighs its own capacity, and the pipe is drawn
##             proportional. networkflow3d's world, and the theorem's.
##   flow      capacity weights, plus an inner ribbon on each edge whose width
##             is the flow Edmonds-Karp actually pushed through it. An edge
##             carrying nothing is drawn exactly as `capacity` draws it.
##   residual  capacity weights, plus an inner ribbon of what is LEFT
##             (capacity - flow), plus the source-side territory filled in
##             behind the field. This is the frontier the min cut is read off:
##             everything the source can still reach when nothing more fits.
##
## THE INNER RIBBONS ARE ADDITIVE ON PURPOSE. The first draft recoloured the
## whole pipe at `flow` and `residual`, which made all six pairs of this axis
## loud and hid the two designed nulls inside a wash. Drawing the reading ON
## TOP of the capacity reading, rather than instead of it, is what makes
## `severed`'s capacity-versus-flow pair a true byte identity.
##
## `residual` IS THE VALUE THAT NEEDED THE MOST WATCHING, because residual =
## capacity - flow, so its ribbon is the exact complement of `flow`'s inside the
## same pipe and a value that is arithmetic on two of its neighbours is one step
## from being the union of them. It earns its place on the TERRITORY, not the
## ribbon: the filled source-side region is the frontier a min cut is actually
## read off, it is drawn by no other value, and it is what makes every residual
## pair the loud end of this axis (about 3 percent of frame against the 0.02
## percent floor). The declined half — drawing the SPENT capacity as a returned
## sleeve on the reverse of each pipe — is what would have made `residual` a
## superposition of `capacity` and `flow`, and it is declined for that reason.
##
## ── THE TWO BLADES ───────────────────────────────────────────────────────
##
## The solid blade is the true minimum cut, found by exhaustive enumeration
## over all 256 s-t bipartitions (n = 10, so this is cheap and exact — no
## approximation is needed and none is used). The pale yellow outline is the
## cut a seeded Karger contraction actually returned, best of `karger_runs`.
##
## THIS IS THE THING THE SOURCE COULD NOT SAY. karger_algorithm.gd:118 declares
## `var _success_count: int = 0  # runs that found the actual min cut`, and
## :460-469 then counts a success as `_run_states[p].cut_size ==
## _best_global_cut` — where `_best_global_cut` is the best found SO FAR
## (:229 initialises it to 999, :460 lowers it). So the first round always
## scores at least one success against a bar it set itself, and the observed
## rate on :887-895 is compared against the theoretical 2/(n(n-1)) as though
## the two were the same quantity. The artifact whose whole subject is whether
## you have found the minimum has no way to know whether it has. Here the true
## minimum is computed independently, so FOUND against CUT is a real
## comparison and not a self-reference.
##
## And what it shows is sharper than bad luck. Karger contracts EDGES and
## counts crossings, so it minimises CARDINALITY. At `mixed` it returns the
## source star — 2 edges, the correct answer to the question it was asked, and
## capacity 18 against a true minimum of 9. Exactly twice. The algorithm is not
## unlucky there; it is answering a different question, and at against=graph
## (where cardinality IS the question) the two blades land on the same x to the
## millimetre.
##
## ── SEEDED, NOT RANDOM ───────────────────────────────────────────────────
##
## An unseeded Karger draws a different cut every load, which would mean every
## still ever taken of it photographed a different object. `karger_seed` feeds
## an explicit 32-bit LCG written out below rather than RandomNumberGenerator,
## for one reason: it makes the contraction reproducible OUTSIDE Godot, so the
## prediction in dna.predicted_degeneracy is arithmetic rather than a hope.
## dna.fixture pins seed and run count anyway.
##
## ── SHADING ──────────────────────────────────────────────────────────────
##
## The board and its bezel are LIT (a bench should have a body). Every mark the
## axes argue about — wells, blade, pipes, ribbons, nodes, bars — is UNSHADED,
## so the rendered pixel is filmic(srgb_to_linear(albedo)) and nothing else.
## That is why the registry's prediction is two-sided rather than a floor.

# ── Axes ─────────────────────────────────────────────────────────────────
@export_enum("mixed", "throat", "braid", "severed") var bottleneck: String = "mixed"
@export_enum("edges", "capacity", "flow", "residual") var against: String = "capacity"

const BOTTLENECKS: PackedStringArray = ["mixed", "throat", "braid", "severed"]
const AGAINSTS: PackedStringArray = ["edges", "capacity", "flow", "residual"]

## The contraction stream. Pinned by dna.fixture as well as defaulted here, so a
## sweep and a map placement photograph the same eight runs.
@export var karger_seed: int = 20260818
@export var karger_runs: int = 8

# ── The network ──────────────────────────────────────────────────────────
# Ten nodes in five columns; 0 is the source, 9 the sink. Layout is fixed for
# three of the four values; `severed` displaces the two components along x.
const NODE_X := [-0.210, -0.105, -0.105, 0.000, 0.000, 0.000, 0.105, 0.105, 0.105, 0.210]
const NODE_Y := [0.335, 0.415, 0.255, 0.455, 0.335, 0.215, 0.415, 0.335, 0.255, 0.335]
const N_NODES: int = 10
const SRC: int = 0
const SNK: int = 9
const MAXCAP: float = 9.0

# The 19 base edges, in the order every value builds them.
const BASE_A := [0, 0, 1, 1, 1, 2, 2, 3, 4, 3, 4, 4, 5, 5, 6, 7, 6, 7, 8]
const BASE_B := [1, 2, 2, 3, 4, 4, 5, 4, 5, 6, 6, 7, 7, 8, 7, 8, 9, 9, 9]
## The scattered capacity table. Hand-fixed, not sampled: there is no RNG
## anywhere in the geometry, so two builds of one cell are the same file.
## Chosen so the source star (0-1, 0-2) is the CARDINALITY minimum at 2 edges
## while the sink star (6-9, 7-9, 8-9) is the CAPACITY minimum at 9.
const BASE_CAP := [9.0, 9.0, 7.0, 8.0, 7.0, 8.0, 9.0, 6.0, 7.0,
	8.0, 7.0, 9.0, 8.0, 7.0, 6.0, 7.0, 3.0, 3.0, 3.0]
## Indices into BASE that `throat` and `severed` delete — the other three
## col2-col3 crossings. Index 11 is 4-7, the bridge itself, which only
## `severed` removes.
const DROP_IDX := [9, 10, 12, 13]
const BRIDGE_IDX: int = 11
const THROAT_CAP: float = 2.0
## `braid`'s six extra chords, all at MAXCAP.
const BRAID_A := [0, 0, 3, 6, 2, 1]
const BRAID_B := [3, 5, 5, 8, 6, 7]
const SEVER_DX: float = 0.032

# ── Board geometry, in the face's local frame (x right, y up, z toward camera)
## capture_config_sweep.gd:69 puts the camera at YAW 0.62; facing the board
## along it photographs every front surface square and costs only cos(0.26) of
## the height. Every number in the registry's arithmetic is computed against
## this one.
const FACE_YAW: float = 0.62
const BOARD_W: float = 0.620
const BOARD_H: float = 0.560
const BOARD_D: float = 0.040
const FIELD_X0: float = -0.280
const FIELD_X1: float = 0.280
const FIELD_Y0: float = 0.170
const FIELD_Y1: float = 0.500
const LEDGER_X0: float = -0.280
const LEDGER_X1: float = 0.280
const LEDGER_Y0: float = 0.030
const LEDGER_Y1: float = 0.145
const EDGE_W: float = 0.0090
const NODE_S: float = 0.026
const BLADE_HW: float = 0.009
const FOUND_T: float = 0.0018
const BAR_W: float = 0.070
const BAR_H: float = 0.085
const BAR_Y: float = 0.045
const BAR_CX := [-0.150, 0.000, 0.150]
const FRAME_T: float = 0.0015

# Painter order, back to front. A tenth of a millimetre apart is enough to stop
# z-fighting and far under one pixel at the sweep's 0.915 mm.
const Z_WELL: float = 0.0205
const Z_TERRITORY: float = 0.0210
const Z_BLADE: float = 0.0215
const Z_FOUND: float = 0.0220
const Z_PIPE: float = 0.0225
const Z_RIBBON: float = 0.0230
const Z_NODE: float = 0.0235

# ── Colours ──────────────────────────────────────────────────────────────
const COL_BOARD := Color(0.140, 0.150, 0.175)
const COL_BEZEL := Color(0.200, 0.212, 0.245)
const COL_WELL := Color(0.055, 0.058, 0.070)
const COL_BLADE := Color(0.400, 0.090, 0.130)
const COL_FOUND := Color(0.960, 0.800, 0.240)
const COL_TERRITORY := Color(0.090, 0.190, 0.260)
const COL_PIPE := Color(0.420, 0.460, 0.560)
const COL_CUTPIPE := Color(0.960, 0.280, 0.300)
const COL_FILL_FLOW := Color(0.280, 0.720, 0.900)
const COL_FILL_RES := Color(0.300, 0.860, 0.640)
const COL_NODE_SRC := Color(0.240, 0.850, 0.420)
const COL_NODE_SNK := Color(0.960, 0.280, 0.300)
const COL_NODE_A := Color(0.320, 0.520, 0.900)
const COL_NODE_B := Color(0.620, 0.420, 0.880)
const COL_FRAME := Color(0.230, 0.250, 0.300)

# ── State ────────────────────────────────────────────────────────────────
var _built: bool = false
var _emissive: bool = true
var _face: Node3D = null
var _owned: Array[Node] = []
var _lit_mats: Array[StandardMaterial3D] = []
var _surfaces: Dictionary = {}          # colour key -> PackedVector3Array

var _ea: PackedInt32Array = PackedInt32Array()
var _eb: PackedInt32Array = PackedInt32Array()
var _ecap: PackedFloat64Array = PackedFloat64Array()
var _ew: PackedFloat64Array = PackedFloat64Array()
var _eflow: PackedFloat64Array = PackedFloat64Array()
var _cut_edge: PackedInt32Array = PackedInt32Array()
var _src_side: PackedInt32Array = PackedInt32Array()
var _found_side: PackedInt32Array = PackedInt32Array()
var _total_w: float = 0.0
var _cut_w: float = 0.0
var _flow_w: float = 0.0
var _found_w: float = 0.0
var _blade_x: float = 0.0
var _found_x: float = 0.0
var _lcg: int = 0


func _ready() -> void:
	_build_all()
	_built = true


## SYNCHRONOUS, from the @export values alone. No call_deferred anywhere on the
## build path: a deferred rebuild that removes children first makes the grid's
## auto-grounding measure a zero AABB and bail.
func _build_all() -> void:
	bottleneck = _pick_axis(bottleneck, BOTTLENECKS, "mixed")
	against = _pick_axis(against, AGAINSTS, "capacity")

	_face = Node3D.new()
	_face.name = "Face"
	_face.rotation.y = FACE_YAW
	add_child(_face)
	_owned.append(_face)

	_add_anchor()
	_add_body()
	_solve()
	_surfaces.clear()
	_draw_field()
	_draw_ledger()
	_emit_surfaces()


# ── The frame is pinned ──────────────────────────────────────────────────

## A layers = 0 box sized to the union of every cell's extent. The sweep frames
## by the merged MeshInstance3D AABB, so without this a value that grew the
## board by a millimetre would buy a score by moving the camera. layers = 0
## rather than visible = false: visibility is hierarchical in Godot and would
## take any future child with it, while layers is per-instance and leaves the
## mesh and its material alone.
func _add_anchor() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(BOARD_W, BOARD_H, 0.050)
	mi.mesh = bm
	mi.position = Vector3(0.0, BOARD_H * 0.5, 0.005)
	mi.layers = 0
	mi.name = "FrameAnchor"
	_face.add_child(mi)


## The lit body: a slab and a bezel lip. Nothing here changes with either axis,
## so no measured pair carries a lighting difference it did not earn.
func _add_body() -> void:
	var slab := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(BOARD_W, BOARD_H, BOARD_D)
	slab.mesh = sm
	slab.position = Vector3(0.0, BOARD_H * 0.5, 0.0)
	slab.material_override = _lit_material(COL_BOARD)
	slab.name = "Board"
	_face.add_child(slab)

	var lip := MeshInstance3D.new()
	var lm := BoxMesh.new()
	# BOARD_D + 0.008, not + 0.012: at +0.012 the lip's half-depth is 0.026 and it
	# pokes 1 mm past the 0.025 frame anchor, which would make the AABB — and so
	# the camera distance — a fact about the bezel instead of a constant.
	lm.size = Vector3(BOARD_W, 0.014, BOARD_D + 0.008)
	lip.mesh = lm
	lip.position = Vector3(0.0, 0.007, 0.0)
	lip.material_override = _lit_material(COL_BEZEL)
	lip.name = "Lip"
	_face.add_child(lip)


func _lit_material(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.62
	mat.metallic = 0.0
	mat.emission_enabled = _emissive
	mat.emission = c * 0.12
	_lit_mats.append(mat)
	return mat


func _flat_material(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = c
	# Every quad is authored facing +z in the face's frame, but a ribbon's
	# winding flips with the sign of its direction vector. Disabling the cull
	# costs nothing on a few hundred triangles and removes a whole class of
	# "the axis is invisible from the one angle the sweep uses".
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


# ── Solving ──────────────────────────────────────────────────────────────

func _solve() -> void:
	_build_edges()
	_build_weights()
	_solve_min_cut()
	_solve_flow()
	_solve_karger()
	_blade_x = _partition_x(_src_side)
	_found_x = _partition_x(_found_side)


func _build_edges() -> void:
	_ea = PackedInt32Array()
	_eb = PackedInt32Array()
	_ecap = PackedFloat64Array()
	var drop_bridge: bool = bottleneck == "severed"
	var thin: bool = bottleneck == "throat" or bottleneck == "severed"
	for i in range(BASE_A.size()):
		if thin and DROP_IDX.has(i):
			continue
		if drop_bridge and i == BRIDGE_IDX:
			continue
		var cap: float = 0.0
		match bottleneck:
			"throat":
				cap = THROAT_CAP if i == BRIDGE_IDX else MAXCAP
			"braid":
				cap = MAXCAP
			_:
				# `mixed` and `severed` share the scatter. severed is the shipped
				# capacities with the crossings gone, which is what
				# networkflow3d's _sever_min_cut does to its own network.
				cap = float(BASE_CAP[i])
		_ea.append(int(BASE_A[i]))
		_eb.append(int(BASE_B[i]))
		_ecap.append(cap)
	if bottleneck == "braid":
		for i in range(BRAID_A.size()):
			_ea.append(int(BRAID_A[i]))
			_eb.append(int(BRAID_B[i]))
			_ecap.append(MAXCAP)


## THE AXIS IS THE WEIGHT VECTOR. `graph` hands every edge MAXCAP rather than
## 1.0, and the choice is load-bearing: scaling every unit weight by the same
## constant leaves the argmin untouched, but it makes the vector at `graph`
## LITERALLY EQUAL to the vector at `capacity` whenever every capacity is
## MAXCAP — which is `braid`. That equality is the designed null, and at 1.0 it
## would have been an approximate one.
func _build_weights() -> void:
	_ew = PackedFloat64Array()
	_total_w = 0.0
	for i in range(_ea.size()):
		var w: float = MAXCAP if against == "edges" else _ecap[i]
		_ew.append(w)
		_total_w += w


## Exhaustive over all 2^8 s-t bipartitions. n = 10, so the exact answer costs
## 256 * |E| and there is no reason to approximate it — which is the whole
## point of having Karger's approximation standing next to it. Ties break on
## the first minimal mask; every cell's minimum is unique anyway (checked: the
## second-cheapest cut is 18 against 9 at mixed, 18 against 2 at throat, 36
## against 27 at braid, 9 against 0 at severed).
func _solve_min_cut() -> void:
	var others: PackedInt32Array = PackedInt32Array()
	for v in range(N_NODES):
		if v != SRC and v != SNK:
			others.append(v)
	var best_w: float = INF
	var best_side: PackedInt32Array = PackedInt32Array()
	for mask in range(1 << others.size()):
		var side: PackedInt32Array = PackedInt32Array()
		side.resize(N_NODES)
		side.fill(0)
		side[SRC] = 1
		for i in range(others.size()):
			if (mask >> i) & 1:
				side[others[i]] = 1
		var w: float = 0.0
		for e in range(_ea.size()):
			if side[_ea[e]] != side[_eb[e]]:
				w += _ew[e]
		if w < best_w:
			best_w = w
			best_side = side
	_cut_w = best_w
	_src_side = best_side
	_cut_edge = PackedInt32Array()
	_cut_edge.resize(_ea.size())
	for e in range(_ea.size()):
		_cut_edge[e] = 1 if _src_side[_ea[e]] != _src_side[_eb[e]] else 0


## Edmonds-Karp on the undirected network: each edge is usable in both
## directions at its full weight. networkflow3d.gd:335-341 needed a whole
## orientation pass because its edge list is DIRECTED and a still cannot show
## direction anyway; drawing an undirected network removes that problem instead
## of solving it, and the theorem is the same theorem.
func _solve_flow() -> void:
	var cap: PackedFloat64Array = PackedFloat64Array()
	cap.resize(N_NODES * N_NODES)
	cap.fill(0.0)
	for e in range(_ea.size()):
		cap[_ea[e] * N_NODES + _eb[e]] += _ew[e]
		cap[_eb[e] * N_NODES + _ea[e]] += _ew[e]
	_flow_w = 0.0
	while true:
		var par: PackedInt32Array = PackedInt32Array()
		par.resize(N_NODES)
		par.fill(-2)
		par[SRC] = -1
		var queue: Array[int] = [SRC]
		while queue.size() > 0 and par[SNK] == -2:
			var u: int = queue.pop_front()
			for v in range(N_NODES):
				if par[v] == -2 and cap[u * N_NODES + v] > 1e-9:
					par[v] = u
					queue.append(v)
		if par[SNK] == -2:
			break
		var f: float = INF
		var node: int = SNK
		while par[node] != -1:
			f = minf(f, cap[par[node] * N_NODES + node])
			node = par[node]
		node = SNK
		while par[node] != -1:
			cap[par[node] * N_NODES + node] -= f
			cap[node * N_NODES + par[node]] += f
			node = par[node]
		_flow_w += f
	# cap[a][b] + cap[b][a] is invariant at 2w through every push, so the net
	# magnitude on an undirected edge is |w - cap[a][b]| and needs no separate
	# bookkeeping.
	_eflow = PackedFloat64Array()
	for e in range(_ea.size()):
		_eflow.append(minf(_ew[e], absf(_ew[e] - cap[_ea[e] * N_NODES + _eb[e]])))


# ── Karger, on an explicit stream ────────────────────────────────────────

## A 32-bit linear congruential generator, written out rather than taken from
## RandomNumberGenerator, so the contraction is reproducible outside Godot and
## the registry's prediction can be arithmetic. Same constants as Numerical
## Recipes' ranqd1.
func _lcg_next() -> int:
	_lcg = (_lcg * 1664525 + 1013904223) & 0xFFFFFFFF
	return _lcg


func _lcg_below(n: int) -> int:
	return _lcg_next() % n


## Best of `karger_runs` contractions, on ONE stream that is not reseeded
## between runs. Unweighted by nature — Karger contracts edges and counts
## crossings — which is exactly why its answer can be wrong about capacity
## while being right about cardinality.
func _solve_karger() -> void:
	_lcg = karger_seed & 0xFFFFFFFF
	var m: int = _ea.size()
	var best_k: int = -1
	var best_side: PackedInt32Array = PackedInt32Array()
	for _run in range(maxi(karger_runs, 1)):
		var parent: PackedInt32Array = PackedInt32Array()
		parent.resize(N_NODES)
		for v in range(N_NODES):
			parent[v] = v
		var order: PackedInt32Array = PackedInt32Array()
		for e in range(m):
			order.append(e)
		for i in range(m - 1, 0, -1):
			var j: int = _lcg_below(i + 1)
			var tmp: int = order[i]
			order[i] = order[j]
			order[j] = tmp
		var remaining: int = N_NODES
		var step: int = 0
		while remaining > 2 and step < m:
			var e2: int = order[step]
			step += 1
			var ra: int = _uf_find(parent, _ea[e2])
			var rb: int = _uf_find(parent, _eb[e2])
			if ra != rb:
				parent[rb] = ra
				remaining -= 1
		var root0: int = _uf_find(parent, SRC)
		var side: PackedInt32Array = PackedInt32Array()
		side.resize(N_NODES)
		for v in range(N_NODES):
			side[v] = 1 if _uf_find(parent, v) == root0 else 0
		var k: int = 0
		for e3 in range(m):
			if side[_ea[e3]] != side[_eb[e3]]:
				k += 1
		if best_k < 0 or k < best_k:
			best_k = k
			best_side = side
	_found_side = best_side
	_found_w = 0.0
	for e in range(m):
		if _found_side[_ea[e]] != _found_side[_eb[e]]:
			_found_w += _ew[e]


func _uf_find(parent: PackedInt32Array, x: int) -> int:
	var v: int = x
	while parent[v] != v:
		parent[v] = parent[parent[v]]
		v = parent[v]
	return v


# ── Drawing ──────────────────────────────────────────────────────────────

func _node_pos(v: int) -> Vector2:
	var x: float = float(NODE_X[v])
	if bottleneck == "severed":
		x += -SEVER_DX if _src_side_default(v) else SEVER_DX
	return Vector2(x, float(NODE_Y[v]))


## At `severed` the two components are {0..5} and {6..9} by construction, and
## the displacement has to be decided BEFORE the min cut is solved (the solver
## reads positions only for the blade). Hard-coded rather than read off
## _src_side to keep the layout independent of the against axis: a network
## that moved when you changed how you were looking at it would make every
## against pair carry a geometry difference it did not earn.
func _src_side_default(v: int) -> bool:
	return v <= 5


## The x where the blade stands: midway between the rightmost node on one side
## and the leftmost on the other. Defined for every partition including the
## empty cut, which is why `severed` still draws a blade — in the void.
func _partition_x(side: PackedInt32Array) -> float:
	var left: float = -INF
	var right: float = INF
	for v in range(N_NODES):
		var p: Vector2 = _node_pos(v)
		if side[v] == 1:
			left = maxf(left, p.x)
		else:
			right = minf(right, p.x)
	if left == -INF:
		left = right
	if right == INF:
		right = left
	return 0.5 * (left + right)


func _draw_field() -> void:
	_quad("well", FIELD_X0, FIELD_X1, FIELD_Y0, FIELD_Y1, Z_WELL)

	if against == "residual":
		_quad("territory", FIELD_X0, _blade_x, FIELD_Y0, FIELD_Y1, Z_TERRITORY)

	_quad("blade", _blade_x - BLADE_HW, _blade_x + BLADE_HW, FIELD_Y0, FIELD_Y1, Z_BLADE)
	_quad("found", _found_x - BLADE_HW, _found_x - BLADE_HW + FOUND_T,
		FIELD_Y0, FIELD_Y1, Z_FOUND)
	_quad("found", _found_x + BLADE_HW - FOUND_T, _found_x + BLADE_HW,
		FIELD_Y0, FIELD_Y1, Z_FOUND)

	for e in range(_ea.size()):
		var a: Vector2 = _node_pos(_ea[e])
		var b: Vector2 = _node_pos(_eb[e])
		var key: String = "cutpipe" if _cut_edge[e] == 1 else "pipe"
		_ribbon(key, a, b, EDGE_W * _ew[e] / MAXCAP, Z_PIPE)
		if against == "flow" and _eflow[e] > 1e-9:
			_ribbon("fill_flow", a, b, EDGE_W * _eflow[e] / MAXCAP, Z_RIBBON)
		elif against == "residual" and (_ew[e] - _eflow[e]) > 1e-9:
			_ribbon("fill_res", a, b, EDGE_W * (_ew[e] - _eflow[e]) / MAXCAP, Z_RIBBON)

	for v in range(N_NODES):
		var p: Vector2 = _node_pos(v)
		var key2: String = "node_a" if _src_side[v] == 1 else "node_b"
		if v == SRC:
			key2 = "node_src"
		elif v == SNK:
			key2 = "node_snk"
		_quad(key2, p.x - NODE_S * 0.5, p.x + NODE_S * 0.5,
			p.y - NODE_S * 0.5, p.y + NODE_S * 0.5, Z_NODE)


## PUSHED, CUT, FOUND. The first two are equal in all sixteen cells by
## max-flow min-cut; the third is greater or equal, and at `mixed` under any
## capacity reading it is exactly twice the second. Every bar keeps its empty
## frame, so a zero reads as a zero and not as a missing mark.
func _draw_ledger() -> void:
	_quad("well", LEDGER_X0, LEDGER_X1, LEDGER_Y0, LEDGER_Y1, Z_WELL)
	var vals: PackedFloat64Array = PackedFloat64Array([_flow_w, _cut_w, _found_w])
	var keys: PackedStringArray = PackedStringArray(["bar_push", "bar_cut", "bar_found"])
	for i in range(3):
		var cx: float = float(BAR_CX[i])
		var x0: float = cx - BAR_W * 0.5
		var x1: float = cx + BAR_W * 0.5
		var y1: float = BAR_Y + BAR_H
		_quad("frame", x0, x1, BAR_Y, BAR_Y + FRAME_T, Z_PIPE)
		_quad("frame", x0, x1, y1 - FRAME_T, y1, Z_PIPE)
		_quad("frame", x0, x0 + FRAME_T, BAR_Y, y1, Z_PIPE)
		_quad("frame", x1 - FRAME_T, x1, BAR_Y, y1, Z_PIPE)
		var h: float = 0.0
		if _total_w > 0.0:
			h = BAR_H * (vals[i] / _total_w)
		if h > 1e-9:
			_quad(keys[i], x0 + FRAME_T, x1 - FRAME_T, BAR_Y + FRAME_T, BAR_Y + h, Z_RIBBON)


func _quad(key: String, x0: float, x1: float, y0: float, y1: float, z: float) -> void:
	var lo_x: float = minf(x0, x1)
	var hi_x: float = maxf(x0, x1)
	var a := Vector3(lo_x, y0, z)
	var b := Vector3(hi_x, y0, z)
	var c := Vector3(hi_x, y1, z)
	var d := Vector3(lo_x, y1, z)
	_push(key, a, b, c)
	_push(key, a, c, d)


func _ribbon(key: String, a: Vector2, b: Vector2, width: float, z: float) -> void:
	if width <= 1e-9:
		return
	var dir: Vector2 = b - a
	if dir.length_squared() < 1e-12:
		return
	dir = dir.normalized()
	var perp: Vector2 = Vector2(-dir.y, dir.x) * width * 0.5
	var v0 := Vector3(a.x + perp.x, a.y + perp.y, z)
	var v1 := Vector3(b.x + perp.x, b.y + perp.y, z)
	var v2 := Vector3(b.x - perp.x, b.y - perp.y, z)
	var v3 := Vector3(a.x - perp.x, a.y - perp.y, z)
	_push(key, v0, v1, v2)
	_push(key, v0, v2, v3)


func _push(key: String, a: Vector3, b: Vector3, c: Vector3) -> void:
	if not _surfaces.has(key):
		_surfaces[key] = PackedVector3Array()
	var arr: PackedVector3Array = _surfaces[key]
	arr.append(a)
	arr.append(b)
	arr.append(c)
	_surfaces[key] = arr


## One MeshInstance3D per colour, each with a plain unshaded albedo. Vertex
## colours were the obvious alternative and are refused on purpose: whether a
## vertex colour is treated as sRGB or linear is a material flag, and the whole
## prediction in the registry depends on the rendered pixel being exactly
## filmic(srgb_to_linear(albedo)). An albedo_color has no such ambiguity.
func _emit_surfaces() -> void:
	for key in _surfaces.keys():
		var tris: PackedVector3Array = _surfaces[key]
		if tris.size() < 3:
			continue
		var im := ImmediateMesh.new()
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(tris.size()):
			im.surface_add_vertex(tris[i])
		im.surface_end()
		var mi := MeshInstance3D.new()
		mi.mesh = im
		mi.material_override = _flat_material(_colour_of(str(key)))
		mi.name = "Mark_" + str(key)
		_face.add_child(mi)


func _colour_of(key: String) -> Color:
	match key:
		"well":
			return COL_WELL
		"territory":
			return COL_TERRITORY
		"blade":
			return COL_BLADE
		"found":
			return COL_FOUND
		"pipe":
			return COL_PIPE
		"cutpipe":
			return COL_CUTPIPE
		"fill_flow":
			return COL_FILL_FLOW
		"fill_res":
			return COL_FILL_RES
		"node_src":
			return COL_NODE_SRC
		"node_snk":
			return COL_NODE_SNK
		"node_a":
			return COL_NODE_A
		"node_b":
			return COL_NODE_B
		"frame":
			return COL_FRAME
		"bar_push":
			return COL_FILL_FLOW
		"bar_cut":
			return COL_CUTPIPE
		"bar_found":
			return COL_FOUND
	return COL_WELL


# ── Config ───────────────────────────────────────────────────────────────

## Called by GridInteractablesComponent via call_deferred, after _ready(). It is
## also handed {"emissive": false} by curation_station one line after it frames
## an artifact's labels, so that key applies IN PLACE, before every early
## return — accepting a key and silently doing nothing is the regression this
## contract exists to stop.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_bottleneck: String = bottleneck
	var before_evidence: String = against
	var before_seed: int = karger_seed
	var before_runs: int = karger_runs

	if config_data.has("bottleneck"):
		bottleneck = _pick_axis(str(config_data["bottleneck"]), BOTTLENECKS, bottleneck)
	if config_data.has("against"):
		against = _pick_axis(str(config_data["against"]), AGAINSTS, against)
	if config_data.has("karger_seed"):
		karger_seed = int(config_data["karger_seed"])
	if config_data.has("karger_runs"):
		karger_runs = clampi(int(config_data["karger_runs"]), 1, 512)

	if config_data.has("emissive"):
		_emissive = _as_bool(config_data["emissive"], _emissive)
		_apply_emissive()

	if not _built:
		return
	if bottleneck == before_bottleneck and against == before_evidence \
			and karger_seed == before_seed and karger_runs == before_runs:
		return
	_rebuild_now()
	print("[BottleneckCut] bottleneck=%s against=%s | pushed=%.1f cut=%.1f found=%.1f of %.1f" % [
		bottleneck, against, _flow_w, _cut_w, _found_w, _total_w])


## Accept an axis value only if it names something this artifact actually
## builds. A typo in a map token falls back to the value already standing
## rather than to an empty board.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _as_bool(v: Variant, fallback: bool) -> bool:
	match typeof(v):
		TYPE_BOOL:
			return bool(v)
		TYPE_INT, TYPE_FLOAT:
			return float(v) != 0.0
		TYPE_STRING, TYPE_STRING_NAME:
			var s: String = str(v).to_lower().strip_edges()
			if s == "false" or s == "0" or s == "off" or s == "no":
				return false
			if s == "true" or s == "1" or s == "on" or s == "yes":
				return true
			return fallback
	return fallback


func _apply_emissive() -> void:
	for mat in _lit_mats:
		if is_instance_valid(mat):
			mat.emission_enabled = _emissive


## Synchronous, and it frees only what this script created — grid-added
## children (label plates, mounts, the pickup highlight) are left alone.
func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_lit_mats.clear()
	_surfaces.clear()
	_face = null
	_build_all()


## What the board is currently asserting, for a probe or a test that wants the
## numbers rather than the picture.
func get_algorithm_info() -> Dictionary:
	return {
		"name": "Bottleneck Cut",
		"bottleneck": bottleneck,
		"against": against,
		"edges": _ea.size(),
		"total_weight": _total_w,
		"max_flow": _flow_w,
		"min_cut": _cut_w,
		"karger_found": _found_w,
		"theorem_holds": absf(_flow_w - _cut_w) < 1e-6,
		"karger_is_optimal": absf(_found_w - _cut_w) < 1e-6,
	}
