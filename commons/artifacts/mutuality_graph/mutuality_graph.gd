extends Node3D
class_name MutualityGraph

## Mutuality Graph — a SYNTHESIS artifact. One vertex set, four edge sets, and the
## question of who can get back.
##
## @identity
## essence: Twelve vertices at twelve fixed positions, drawn four times side by
##   side. The four registers differ ONLY in which arrows are present — 17, 20, 22,
##   23 — and the edge sets NEST, so nothing is redrawn between them, only added.
##   Their strongly connected components go 12, 7, 2, 1.
## desire: To be read left to right and then counted. Three arrows take twelve
##   groups to seven. Two more take seven to two. ONE more takes two to one. The
##   pictures barely change; the answer changes completely.
## critical_parameter: `grouping` — WHICH belonging the picture draws. The four
##   registers never move; only the account of what they have in common.
## triggers: none. Nothing animates, nothing is grabbed, nothing is random. There
##   is no _process and no timer in this file.
## emerges: `linked` — four identical slabs. Every one of the four digraphs is
##   weakly connected, so the undirected reading gives ONE group in all four
##   registers and cannot tell the series apart at all. That is not a degenerate
##   value; it is the measurement the artifact exists to make.
## needs: one vertex set drawn four times [has]; nested edge sets so the partition
##   is the only thing that moves [has, E_none subset E_pockets subset E_split
##   subset E_total]; components drawn as REGIONS rather than left in the edge list
##   [has, `mutual`]; the same partition computed twice by different routes and
##   cross-checked [has, _scc_tarjan vs _scc_kosaraju]
## relationships: Synthesised from the five artifacts that declare `mutuality` —
##   [[tarjan_algorithm]], [[kosaraju_algorithm]], [[rhizomatic_structure]],
##   [[network_analysis]], [[forcedirected3d]]. See the registry block.
## truth: Mutual reachability is not connectedness. Every graph here is connected
##   in the undirected sense and always was; what changes is whether you can get
##   back, and that is invisible in a picture that draws only the arrows.

# ═══════════════════════════════════════════════════════════════════════════
# THE FAMILY WORD IS EXHIBITED, NOT VARIED
# ═══════════════════════════════════════════════════════════════════════════
#
# `mutuality` is refused as this artifact's axis, on the record. All five members
# use the word to stand in ONE value and forgo the other three; here all four
# stand at once and that simultaneity is the object. An axis whose every value
# demolishes three quarters of the exhibit is not a variation of it.
#
# So the word is EXHIBITED: it names the plate, it is engraved on it, and the
# value list is READ OUT OF tarjan_algorithm.gd rather than retyped, so this
# artifact cannot drift from the family it is about. If MUTUALITIES disappears
# from that file this script fails at parse time, which is the failure mode we
# want.
const TARJAN_SCRIPT := preload("res://algorithms/graphtheory/tarjan_algorithm/tarjan_algorithm.gd")

# THE DECLARED ORDER IS NOT THE LADDER, and no member has ever had to notice.
# All five declare pockets | none | split | total — the default first, which is a
# DECLARATION convention. Ordered by how much mutual reachability the digraph
# actually holds, the ladder is none (12 components) < pockets (7) < split (2) <
# total (1), and it is a genuine refinement chain: each partition is a coarsening
# of the last. The registers stand in ladder order and _ready checks the family
# list against it in BOTH directions.
const LADDER: PackedStringArray = ["none", "pockets", "split", "total"]

# ═══════════════════════════════════════════════════════════════════════════
# SYNTHESIS DNA — `grouping`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHAT THE PICTURE DRAWS AS BELONGING TOGETHER. The graphs never move.
#
#   mutual    every strongly connected component shaded as a region: 12 / 7 / 2 /
#             1. Mutual reachability made a SHAPE instead of an inference. This is
#             the default and the strongest single reading.
#   quotient  the condensation. Each component replaced by ONE body at its
#             members' centroid, area proportional to membership, and the arrows
#             between components collapsed: 12 / 7 / 2 / 1 bodies. The fourth
#             register is a single dot where twelve vertices were.
#   linked    weakly connected components — direction discarded. ONE region in
#             every register, four identical slabs, because all four digraphs are
#             weakly connected and always were.
#   implicit  no regions, no collapse. The graph exactly as all five members ship
#             it, with the partition left in the edge list for the reader to
#             compute. The family's own silence, drawn.
#
# LAW 2 — NEST OR SIDE BY SIDE, answered from the members' CODE, not their prose.
# The four values of `mutuality` are PARALLEL in every member: kosaraju builds a
# seeded random digraph, a total order, two complete blocks and a cycle-plus-chords
# (_edges_random / _edges_forward_dag / _edges_two_blocks / _edges_one_cycle);
# tarjan restages the vertices as well (_layout_ring / _layout_line /
# _layout_two_rings); forcedirected3d changes the node count's wiring entirely;
# rhizomatic_structure even changes what a root is. Nothing nests — four values
# are four different objects, and the vertex counts differ across members too
# (10, 12, 16, 25, 51). But what the four values NAME is a total order, the
# coarseness of the SCC partition, and no member can show it because no member
# draws two of its values at once. The case is therefore MIXED: parallel
# constructions naming a nesting quantity. This artifact takes the nesting
# seriously and builds it — ONE vertex set, and edge sets that are literal
# subsets of each other — so that the ladder becomes a refinement chain you can
# see rather than a claim.
@export_enum("mutual", "quotient", "linked", "implicit") var grouping: String = "mutual"

## Allow-list. A typo in a map token falls back to the shipped reading rather than
## stranding a placement with a plate and nothing drawn on it.
const GROUPINGS: PackedStringArray = ["mutual", "quotient", "linked", "implicit"]

# ═══════════════════════════════════════════════════════════════════════════
# THE GRAPH — derived, seeded by nothing, random nowhere
# ═══════════════════════════════════════════════════════════════════════════
#
# Twelve vertices on a 3 x 4 lattice, indexed by a BOUSTROPHEDON snake so that
# consecutive indices are always lattice neighbours: row 0 left to right, row 1
# right to left, and so on. (col, row) for v0..v11.
const CELLS: Array = [
	[0, 0], [1, 0], [2, 0],
	[2, 1], [1, 1], [0, 1],
	[0, 2], [1, 2], [2, 2],
	[2, 3], [1, 3], [0, 3],
]
const N_V: int = 12
const N_COL: int = 3
const N_ROW: int = 4

## `none` is EVERY lattice adjacency oriented from the lower index to the higher —
## derived in _grid_edges(), not typed. Seventeen arrows, all pointing up the
## snake, so no vertex lies on any cycle and every component is a single vertex.
## A directed acyclic graph is the negative space the whole family measures
## against, and it is drawn here as the DENSE object it actually is rather than as
## a thin thread.
##
## Every later value ADDS reversals of lattice edges that are already there, so an
## added arrow is always a second arrow beside an existing one — which is what a
## pocket of mutuality is at its smallest, a two-way street.
const REV_POCKETS: Array = [[4, 1], [8, 7], [11, 10]]
const REV_SPLIT: Array = [[5, 0], [11, 6]]
const REV_TOTAL: Array = [[6, 5]]

# ═══════════════════════════════════════════════════════════════════════════
# GEOMETRY (metres). Every number below was gauged against 156.24 px/m before it
# was chosen — see dna.framing_why in the registry for the arithmetic.
# ═══════════════════════════════════════════════════════════════════════════
const STEP: float = 0.30                 ## lattice pitch, both axes
const ROW_Y: Array = [0.52, 0.82, 1.12, 1.42]
const PANEL_W: float = 1.02
const PANEL_H: float = 1.46
const PANEL_Y0: float = 0.16
const PANEL_GAP: float = 0.10
const PITCH: float = PANEL_W + PANEL_GAP          ## 1.12
const PLATE_MARGIN_X: float = 0.07
const PLATE_H: float = 1.70
## 4 * 1.02 + 3 * 0.10 + 2 * 0.07 = 4.52. The 4 is LADDER.size(), which a const
## cannot call; _ready checks the family list has exactly four values.
const PLATE_W: float = 4.0 * PANEL_W + 3.0 * PANEL_GAP + 2.0 * PLATE_MARGIN_X

const V_R: float = 0.045                 ## vertex disc radius
const V_PUPIL: float = 0.023
## The pupil is a fixed FRACTION of the body it sits in, so a quotient body of
## membership 1 draws EXACTLY the vertex it replaced. Without this the singleton
## case used 0.51 against 0.023/0.045 = 0.51111 and the first register of
## `quotient` came out a few boundary pixels away from `implicit` instead of
## identical — which would have made the predicted closest pair's arithmetic a
## near-miss rather than a theorem.
const PUPIL_RATIO: float = V_PUPIL / V_R
const E_W: float = 0.034                 ## arrow shaft width
const A_LEN: float = 0.080               ## arrowhead length
const A_W: float = 0.068                 ## arrowhead width
## A reversed arrow rides beside its partner rather than on top of it. 0.095 is
## the smallest offset that clears BOTH: the partner shaft (gap 0.095 - 0.034 =
## 0.061 m = 7.8 px) and the vertex disc it runs past (0.095 - 0.045 - 0.017 =
## 0.033 m = 4.2 px). Below about 0.085 the second clearance falls into the 1-3 px
## band and the two-way street photographs as one fat line.
const BACK_OFF: float = 0.095
## The region is the members' bounding lattice block, inflated by this. 0.075 is
## chosen from BOTH sides: it must be big enough that a region reads as a body
## (a singleton tile is 0.15 m = 19 x 23 px) and small enough that two ADJACENT
## components stay apart (gap = STEP - 2 * 0.075 = 0.15 m = 19 x 23 px). At 0.105
## the twelve singletons of the first register merged into a perforated slab and
## `mutual` stopped being distinguishable from `linked` there — measured, at
## 23.79% against 38.78% for the same pair once this came down.
const REGION_PAD: float = 0.075

## THE Z-STACK, WRITTEN OUT (law 7). Nothing on this plate stands in front of a
## mark. Front faces, in metres, camera on the +z side:
##   plate    -0.050 .. 0.000     region  0.020 .. 0.028     vertex 0.040 .. 0.056
##   panel     0.000 .. 0.020     arrows  0.028 .. 0.042     pupil  0.056 .. 0.062
## Total depth 0.112 m, which smears sy * 0.112 = 0.065 m = 10.2 px of screen-x at
## the sweep's yaw — visible as a dark reveal down one side of the plate and
## nowhere near any mark. The regions are BEHIND the arrows on purpose: a region
## is a shading, and a shading that covers the arrows it is about would be
## operations_gallery's bezel again.
const Z_PLATE_T: float = 0.050
const Z_PANEL_T: float = 0.020
const Z_REGION_T: float = 0.008
const Z_ARROW_T: float = 0.014
const Z_V_T: float = 0.016
const Z_PUPIL_T: float = 0.006

const C_PLATE := Color(0.259, 0.275, 0.314)
const C_PANEL := Color(0.804, 0.792, 0.753)
const C_REGION := Color(0.345, 0.380, 0.455)
const C_INK := Color(0.118, 0.125, 0.149)
const C_PUPIL := Color(0.925, 0.906, 0.859)

## Caption glyph heights are font_size * pixel_size, in metres: 0.1008 for a value
## name (15.7 px tall), 0.0864 for the count line (13.5 px), 0.1092 for the plate
## title (17.1 px). Nothing here is in the 1-3 px band.
const CAP_NAME_SIZE: int = 48
const CAP_NAME_PX: float = 0.0021
const CAP_COUNT_SIZE: int = 36
const CAP_COUNT_PX: float = 0.0024
const CAP_TITLE_SIZE: int = 52
const CAP_TITLE_PX: float = 0.0021
const CAP_NAME_Y: float = 0.34
const CAP_COUNT_Y: float = 0.235
const CAP_TITLE_Y: float = 0.075
const CAP_Z: float = 0.032

# ── ONE COPY OF THE ARITHMETIC, evaluated once in _run() and read N ways ────
var _edge_sets: Array = []      ## per register: Array of [from, to]
var _parts: Array = []          ## per register: Array of Array[int] — the SCCs
var _weak: Array = []           ## per register: Array of Array[int] — the WCCs
var _comp_of: Array = []        ## per register: Array[int], vertex -> SCC index

var _owned: Array[Node] = []
var _built: bool = false


func _ready() -> void:
	_check_vocabulary()
	_run()
	_build()
	_built = true


# ═══════════════════════════════════════════════════════════════════════════
# LAW 1 — the shared word, checked in BOTH directions
# ═══════════════════════════════════════════════════════════════════════════
func _check_vocabulary() -> void:
	var family: PackedStringArray = TARJAN_SCRIPT.MUTUALITIES
	for v in LADDER:
		if not family.has(v):
			push_error("[mutuality_graph] LADDER value '%s' is not in the family list %s"
				% [v, family])
	for v in family:
		if not LADDER.has(v):
			push_error("[mutuality_graph] family value '%s' has no register on this plate (%s)"
				% [v, LADDER])
	if family.size() != 4:
		push_error("[mutuality_graph] the plate is built for four registers, family has %d"
			% family.size())
	# The @export_enum hint is a literal GDScript forces on us and is NOT readable
	# at runtime, so it cannot be diffed against GROUPINGS from in here — that is
	# check_dna_declarations.py's job. What CAN be checked is that whatever value
	# actually arrived (scene, inspector, sweep) names something we build.
	if not GROUPINGS.has(grouping):
		push_error("[mutuality_graph] grouping '%s' is not one of %s — falling back to mutual"
			% [grouping, GROUPINGS])
		grouping = "mutual"


# ═══════════════════════════════════════════════════════════════════════════
# THE ARITHMETIC
# ═══════════════════════════════════════════════════════════════════════════

## Every lattice adjacency, oriented low index -> high index. Derived from CELLS.
func _grid_edges() -> Array:
	var where := {}
	for i in range(N_V):
		where[Vector2i(int(CELLS[i][0]), int(CELLS[i][1]))] = i
	# Each unordered adjacency is discovered EXACTLY ONCE — from the cell whose
	# right or up neighbour it is — so there is nothing to deduplicate and nothing
	# to sort. (Godot's Array.sort() on an array OF arrays is not a comparison
	# this file should rely on; where an order is needed below it is by first
	# element, explicitly.)
	var out: Array = []
	for i in range(N_V):
		var c: int = int(CELLS[i][0])
		var r: int = int(CELLS[i][1])
		var right := Vector2i(c + 1, r)
		var up := Vector2i(c, r + 1)
		if where.has(right):
			var j: int = int(where[right])
			out.append([mini(i, j), maxi(i, j)])
		if where.has(up):
			var k: int = int(where[up])
			out.append([mini(i, k), maxi(i, k)])
	return out


func _run() -> void:
	_edge_sets.clear()
	_parts.clear()
	_weak.clear()
	_comp_of.clear()

	var base: Array = _grid_edges()
	if base.size() != 17:
		push_error("[mutuality_graph] the 3x4 lattice should give 17 adjacencies, got %d"
			% base.size())

	# Every reversal must be the reverse of an edge that is already there, or the
	# "second arrow beside an existing one" claim is false.
	for rev in [REV_POCKETS, REV_SPLIT, REV_TOTAL]:
		for e in rev:
			if not _has_edge(base, int(e[1]), int(e[0])):
				push_error("[mutuality_graph] reversal %s has no forward partner" % [e])

	var acc: Array = base.duplicate(true)
	var adds: Array = [[], REV_POCKETS, REV_SPLIT, REV_TOTAL]
	for k in range(LADDER.size()):
		for e in adds[k]:
			acc.append([int(e[0]), int(e[1])])
		_edge_sets.append(acc.duplicate(true))

	for k in range(LADDER.size()):
		var edges: Array = _edge_sets[k]
		var by_tarjan: Array = _scc_tarjan(edges)
		var by_kosaraju: Array = _scc_kosaraju(edges)
		# THE ARTIFACT'S OWN TRUTH LINE, TESTED IN ITS OWN CODE. One low-link pass
		# and two depth-first passes over the transpose are different routes to the
		# same partition. Twelve vertices makes the check free, so it is made
		# rather than asserted in a comment.
		if str(by_tarjan) != str(by_kosaraju):
			push_error("[mutuality_graph] %s: tarjan %s != kosaraju %s"
				% [LADDER[k], by_tarjan, by_kosaraju])
		_parts.append(by_tarjan)
		_weak.append(_weak_components(edges))
		var m: Array = []
		m.resize(N_V)
		for ci in range(by_tarjan.size()):
			for v in by_tarjan[ci]:
				m[int(v)] = ci
		_comp_of.append(m)

	# The refinement chain is the claim the nesting buys. Adding arrows can only
	# MERGE components, never split them, so every partition must be a coarsening
	# of the one before it.
	for k in range(1, LADDER.size()):
		if not _refines(_parts[k - 1], _comp_of[k]):
			push_error("[mutuality_graph] %s does not coarsen %s — the edge sets are not nested"
				% [LADDER[k], LADDER[k - 1]])


func _has_edge(edges: Array, a: int, b: int) -> bool:
	for e in edges:
		if int(e[0]) == a and int(e[1]) == b:
			return true
	return false


func _adjacency(edges: Array, reverse: bool) -> Array:
	var adj: Array = []
	for i in range(N_V):
		adj.append([])
	for e in edges:
		var a: int = int(e[0])
		var b: int = int(e[1])
		if reverse:
			adj[b].append(a)
		else:
			adj[a].append(b)
	return adj


## Tarjan: one depth-first pass, low-link, a stack. Depth is bounded by 12.
func _scc_tarjan(edges: Array) -> Array:
	var adj: Array = _adjacency(edges, false)
	var index: Array = []
	var low: Array = []
	var on: Array = []
	index.resize(N_V)
	low.resize(N_V)
	on.resize(N_V)
	index.fill(-1)
	low.fill(0)
	on.fill(false)
	var stack: Array = []
	var out: Array = []
	var counter: Array = [0]
	for v in range(N_V):
		if int(index[v]) == -1:
			_tarjan_visit(v, adj, index, low, on, stack, out, counter)
	return _canonical(out)


func _tarjan_visit(u: int, adj: Array, index: Array, low: Array, on: Array,
		stack: Array, out: Array, counter: Array) -> void:
	index[u] = int(counter[0])
	low[u] = int(counter[0])
	counter[0] = int(counter[0]) + 1
	stack.append(u)
	on[u] = true
	for raw in adj[u]:
		var w: int = int(raw)
		if int(index[w]) == -1:
			_tarjan_visit(w, adj, index, low, on, stack, out, counter)
			low[u] = mini(int(low[u]), int(low[w]))
		elif bool(on[w]):
			low[u] = mini(int(low[u]), int(index[w]))
	if int(low[u]) == int(index[u]):
		var comp: Array = []
		while true:
			var w2: int = int(stack.pop_back())
			on[w2] = false
			comp.append(w2)
			if w2 == u:
				break
		comp.sort()
		out.append(comp)


## Canonical order for a partition: by each block's smallest member, which is
## unique across blocks. Sorting arrays OF arrays with the default comparator is
## not something to bet a cross-check on.
func _canonical(parts: Array) -> Array:
	parts.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
	return parts


## Kosaraju: finish order on the graph, then depth-first on the TRANSPOSE in
## reverse finish order. Same partition, different route — which is the whole
## reason both are in the family.
func _scc_kosaraju(edges: Array) -> Array:
	var adj: Array = _adjacency(edges, false)
	var radj: Array = _adjacency(edges, true)
	var seen: Array = []
	seen.resize(N_V)
	seen.fill(false)
	var order: Array = []
	for v in range(N_V):
		if not bool(seen[v]):
			_finish_order(v, adj, seen, order)
	var seen2: Array = []
	seen2.resize(N_V)
	seen2.fill(false)
	var out: Array = []
	for i in range(order.size() - 1, -1, -1):
		var v2: int = int(order[i])
		if bool(seen2[v2]):
			continue
		var comp: Array = []
		_collect(v2, radj, seen2, comp)
		comp.sort()
		out.append(comp)
	return _canonical(out)


func _finish_order(u: int, adj: Array, seen: Array, order: Array) -> void:
	seen[u] = true
	for raw in adj[u]:
		var w: int = int(raw)
		if not bool(seen[w]):
			_finish_order(w, adj, seen, order)
	order.append(u)


func _collect(u: int, radj: Array, seen: Array, comp: Array) -> void:
	seen[u] = true
	comp.append(u)
	for raw in radj[u]:
		var w: int = int(raw)
		if not bool(seen[w]):
			_collect(w, radj, seen, comp)


## Weakly connected components — direction thrown away. Union-find, no recursion.
func _weak_components(edges: Array) -> Array:
	var par: Array = []
	par.resize(N_V)
	for i in range(N_V):
		par[i] = i
	for e in edges:
		var ra: int = _find(par, int(e[0]))
		var rb: int = _find(par, int(e[1]))
		if ra != rb:
			par[ra] = rb
	var groups: Dictionary = {}
	for v in range(N_V):
		var r: int = _find(par, v)
		if not groups.has(r):
			groups[r] = []
		groups[r].append(v)
	var out: Array = []
	for k in groups.keys():
		var g: Array = groups[k]
		g.sort()
		out.append(g)
	return _canonical(out)


func _find(par: Array, a: int) -> int:
	var x: int = a
	while int(par[x]) != x:
		par[x] = par[int(par[x])]
		x = int(par[x])
	return x


func _refines(fine: Array, coarse_map: Array) -> bool:
	for blk in fine:
		var first: int = int(coarse_map[int(blk[0])])
		for v in blk:
			if int(coarse_map[int(v)]) != first:
				return false
	return true


# ═══════════════════════════════════════════════════════════════════════════
# BUILD — synchronous, from _run()'s tables alone
# ═══════════════════════════════════════════════════════════════════════════

func _panel_x(p: int) -> float:
	return (-(LADDER.size() - 1) * 0.5 + float(p)) * PITCH


func _vertex_pos(p: int, i: int) -> Vector2:
	var c: int = int(CELLS[i][0])
	var r: int = int(CELLS[i][1])
	return Vector2(_panel_x(p) + (float(c) - float(N_COL - 1) * 0.5) * STEP, float(ROW_Y[r]))


func _own(node: Node) -> void:
	add_child(node)
	_owned.append(node)


var _mats: Dictionary = {}

func _material(colour: Color) -> StandardMaterial3D:
	if _mats.has(colour):
		return _mats[colour]
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = 0.85
	m.metallic = 0.0
	_mats[colour] = m
	return m


func _box(size: Vector3, centre: Vector3, colour: Color, spin: float = 0.0) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = centre
	mi.rotation.z = spin
	mi.material_override = _material(colour)
	_own(mi)


func _disc(radius: float, thick: float, centre: Vector3, colour: Color) -> void:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = thick
	mesh.radial_segments = 24
	mesh.rings = 0
	mi.mesh = mesh
	mi.position = centre
	# A CylinderMesh stands on +Y; +90 degrees about X lays it down the +Z axis so
	# it reads as a disc facing the camera.
	mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	mi.material_override = _material(colour)
	_own(mi)


## PrismMesh is a triangle in XY extruded along Z, apex at +Y — an arrowhead
## without a custom mesh. `spin` turns +Y onto the arrow's direction.
func _head(centre: Vector3, spin: float, colour: Color) -> void:
	var mi := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = Vector3(A_W, A_LEN, Z_ARROW_T)
	mesh.left_to_right = 0.5
	mi.mesh = mesh
	mi.position = centre
	mi.rotation.z = spin
	mi.material_override = _material(colour)
	_own(mi)


## One arrow from a to b, trimmed off both vertex discs, head at the HEAD end.
## `pad_from` and `pad_to` are the radii to clear at each end (a quotient body is
## bigger than a vertex).
func _arrow(a: Vector2, b: Vector2, pad_from: float, pad_to: float) -> void:
	var delta: Vector2 = b - a
	var length: float = delta.length()
	if length < 0.001:
		return
	var dir: Vector2 = delta / length
	var tail: Vector2 = a + dir * pad_from
	var tip: Vector2 = b - dir * pad_to
	var base: Vector2 = tip - dir * A_LEN
	var spin: float = atan2(dir.y, dir.x) - PI * 0.5
	var shaft: float = (base - tail).length()
	if (base - tail).dot(dir) > 0.0 and shaft > 0.004:
		var mid: Vector2 = (tail + base) * 0.5
		_box(Vector3(shaft, E_W, Z_ARROW_T), Vector3(mid.x, mid.y, 0.028 + Z_ARROW_T * 0.5),
			C_INK, atan2(dir.y, dir.x))
	_head(Vector3(tip.x - dir.x * A_LEN * 0.5, tip.y - dir.y * A_LEN * 0.5,
		0.028 + Z_ARROW_T * 0.5), spin, C_INK)


func _label(text: String, size: int, pixel: float, centre: Vector3) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = pixel
	# INK ON THE PLATE, not a card beside it. BILLBOARD_DISABLED is set explicitly
	# because that is what this label now is: LabelFramer's own rule is that a
	# non-billboard label lies on a body and is already integrated, and here it
	# literally does. Twelve framed captions would become twelve opaque panels
	# standing in front of the graphs they name.
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.modulate = C_INK
	l.position = centre
	_own(l)


func _build() -> void:
	_box(Vector3(PLATE_W, PLATE_H, Z_PLATE_T), Vector3(0.0, PLATE_H * 0.5, -Z_PLATE_T * 0.5),
		C_PLATE)
	_label("mutuality", CAP_TITLE_SIZE, CAP_TITLE_PX, Vector3(0.0, CAP_TITLE_Y, CAP_Z))

	for p in range(LADDER.size()):
		_box(Vector3(PANEL_W, PANEL_H, Z_PANEL_T),
			Vector3(_panel_x(p), PANEL_Y0 + PANEL_H * 0.5, Z_PANEL_T * 0.5), C_PANEL)
		_build_register(p)


func _build_register(p: int) -> void:
	var edges: Array = _edge_sets[p]
	var parts: Array = _parts[p]

	if grouping == "mutual" or grouping == "linked":
		var groups: Array = parts if grouping == "mutual" else _weak[p]
		for blk in groups:
			_region(p, blk)

	if grouping == "quotient":
		_build_quotient(p)
	else:
		for e in edges:
			var a: int = int(e[0])
			var b: int = int(e[1])
			var pa: Vector2 = _vertex_pos(p, a)
			var pb: Vector2 = _vertex_pos(p, b)
			if a > b:
				# A REVERSED arrow rides beside its forward partner, offset to the
				# right of its own travel, so a two-way street reads as two lanes.
				var dir: Vector2 = (pb - pa).normalized()
				var off: Vector2 = Vector2(dir.y, -dir.x) * BACK_OFF
				pa += off
				pb += off
			_arrow(pa, pb, V_R, V_R)
		for v in range(N_V):
			var q: Vector2 = _vertex_pos(p, v)
			_disc(V_R, Z_V_T, Vector3(q.x, q.y, 0.040 + Z_V_T * 0.5), C_INK)
			_disc(V_PUPIL, Z_PUPIL_T, Vector3(q.x, q.y, 0.056 + Z_PUPIL_T * 0.5), C_PUPIL)

	_caption(p)


## The region is the members' BOUNDING LATTICE BLOCK inflated by REGION_PAD, and
## that is only honest if the block holds nothing but members. LAW 6 — count the
## thing you claim to count: the check is made, and a component that fails it gets
## one tile per member instead of a lie about who belongs.
func _region(p: int, members: Array) -> void:
	var c0: int = 99
	var c1: int = -1
	var r0: int = 99
	var r1: int = -1
	var own := {}
	for raw in members:
		var v: int = int(raw)
		var c: int = int(CELLS[v][0])
		var r: int = int(CELLS[v][1])
		c0 = mini(c0, c)
		c1 = maxi(c1, c)
		r0 = mini(r0, r)
		r1 = maxi(r1, r)
		own[Vector2i(c, r)] = true
	var exact: bool = true
	for bc in range(c0, c1 + 1):
		for br in range(r0, r1 + 1):
			if not own.has(Vector2i(bc, br)):
				exact = false
	if not exact:
		push_warning("[mutuality_graph] component %s is not a lattice block — drawing tiles"
			% [members])
		for raw2 in members:
			var q: Vector2 = _vertex_pos(p, int(raw2))
			_box(Vector3(REGION_PAD * 2.0, REGION_PAD * 2.0, Z_REGION_T),
				Vector3(q.x, q.y, 0.020 + Z_REGION_T * 0.5), C_REGION)
		return
	var x_lo: float = _panel_x(p) + (float(c0) - float(N_COL - 1) * 0.5) * STEP - REGION_PAD
	var x_hi: float = _panel_x(p) + (float(c1) - float(N_COL - 1) * 0.5) * STEP + REGION_PAD
	var y_lo: float = float(ROW_Y[r0]) - REGION_PAD
	var y_hi: float = float(ROW_Y[r1]) + REGION_PAD
	_box(Vector3(x_hi - x_lo, y_hi - y_lo, Z_REGION_T),
		Vector3((x_lo + x_hi) * 0.5, (y_lo + y_hi) * 0.5, 0.020 + Z_REGION_T * 0.5), C_REGION)


## The condensation: one body per component at its members' centroid, area
## proportional to membership, and the arrows between components collapsed to one
## each. At `none` this reproduces the graph exactly, because the condensation of
## an acyclic digraph IS the digraph — which is why the first register of
## `quotient` and the first register of `implicit` are the same picture.
func _build_quotient(p: int) -> void:
	var parts: Array = _parts[p]
	var cmap: Array = _comp_of[p]
	var centre: Array = []
	var radius: Array = []
	for blk in parts:
		var acc := Vector2.ZERO
		for raw in blk:
			acc += _vertex_pos(p, int(raw))
		centre.append(acc / float(blk.size()))
		radius.append(minf(V_R * sqrt(float(blk.size())), 0.16))
	var seen := {}
	for e in _edge_sets[p]:
		var ca: int = int(cmap[int(e[0])])
		var cb: int = int(cmap[int(e[1])])
		if ca == cb:
			continue
		var key := Vector2i(ca, cb)
		if seen.has(key):
			continue
		seen[key] = true
		var from_p: Vector2 = centre[ca]
		var to_p: Vector2 = centre[cb]
		_arrow(from_p, to_p, float(radius[ca]), float(radius[cb]))
	for k in range(parts.size()):
		var q: Vector2 = centre[k]
		var rr: float = float(radius[k])
		_disc(rr, Z_V_T, Vector3(q.x, q.y, 0.040 + Z_V_T * 0.5), C_INK)
		_disc(rr * PUPIL_RATIO, Z_PUPIL_T, Vector3(q.x, q.y, 0.056 + Z_PUPIL_T * 0.5), C_PUPIL)


## The count line states what the PICTURE draws, never what it withholds. At
## `implicit` the picture gives you arrows and nothing else, so the caption counts
## arrows; printing the component count there would be handing over the answer the
## value exists to keep back.
func _caption(p: int) -> void:
	var n_scc: int = _parts[p].size()
	var line: String = ""
	match grouping:
		"mutual":
			line = "%d mutual group%s" % [n_scc, "" if n_scc == 1 else "s"]
		"quotient":
			line = "%d bod%s" % [n_scc, "y" if n_scc == 1 else "ies"]
		"linked":
			var n_wcc: int = _weak[p].size()
			line = "%d linked group%s" % [n_wcc, "" if n_wcc == 1 else "s"]
		_:
			line = "%d arrows" % _edge_sets[p].size()
	_label(String(LADDER[p]), CAP_NAME_SIZE, CAP_NAME_PX,
		Vector3(_panel_x(p), CAP_NAME_Y, CAP_Z))
	_label(line, CAP_COUNT_SIZE, CAP_COUNT_PX, Vector3(_panel_x(p), CAP_COUNT_Y, CAP_Z))


# ═══════════════════════════════════════════════════════════════════════════
# GRID CONFIG
# ═══════════════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	var before: String = grouping
	if config_data.has("grouping"):
		var raw: String = str(config_data["grouping"]).to_lower().strip_edges()
		grouping = raw if GROUPINGS.has(raw) else grouping

	# NO `emissive` KEY IS ACCEPTED, and that is deliberate. curation_station hands
	# every artifact it curates {"emissive": false} one line after framing its
	# labels. There is no emission anywhere on this plate to switch off, and
	# accepting a key we would apply nowhere is exactly the lie this contract
	# exists to stop. It falls through to the early return below and changes
	# nothing, which is correct. (rhizomatic_structure refused it for the same
	# reason and on the same grounds.)

	if not _built:
		return
	if grouping == before:
		return
	_rebuild_now()
	print("[MutualityGraph] Config applied — grouping=%s" % grouping)


## SYNCHRONOUS. Free only what this script created and build again inline: a
## deferred rebuild leaves the node empty for a frame and the grid's auto-grounding
## measures a zero AABB and gives up.
func _rebuild_now() -> void:
	for node in _owned:
		if is_instance_valid(node):
			remove_child(node)
			node.queue_free()
	_owned.clear()
	_build()


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
