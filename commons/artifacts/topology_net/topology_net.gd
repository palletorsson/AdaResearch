extends Node3D
class_name TopologyNet

## topology_net — a network's SHAPE is a claim about how information can travel, and two
## traditions have been making that claim in two vocabularies without meeting.
##
## THE FAMILY. Three artifacts declare an axis called `topology`.
##   neural_network_visualization  graded · flat · deep · widened · pinched, default graded
##                                 (res://algorithms/machinelearning/neuralnetworkvisualization/)
##   neural_networks_vr            graded · flat · deep · widened · pinched, default graded
##                                 (res://algorithms/machinelearning/neural_networks/)
##   rhizomatic_maze_space         rhizome · tree · severed · plateau, default rhizome
##                                 (res://algorithms/alternativegeometries/rhizomaticmazespace/)
##
## THE BRIEF GUESSED THE TWO NEURAL MEMBERS ARE ONE SCENE UNDER TWO NAMES. THEY ARE NOT.
## Two directories, two .tscn files, two scripts (neural_network_visualization.gd, 40,962
## bytes; NeuralNetworks_VR.gd, 35,860 bytes), two class names, two different stacks per
## value — nnv is 4-6-4-2 / 4-2 / 4-3-3-3-3-3-2 / 4-10-2 / 4-1-4-2 at diagram scale, nnvr is
## 5-4-3-2 / 5-2 / 5-4-4-4-4-4-2 / 5-7-2 / 5-1-2 at building scale, glass rooms you walk
## through. What IS shared is the axis vocabulary, verbatim and in order, and nnv's own
## comment says so at gd:71 — "Shared verbatim with neural_networks_vr, which asks the
## identical question at building scale." So: one vocabulary, two bodies. The corpus's usual
## hidden family (one scene, many registry names) is not what this is.
##
## THE BRIEF'S CENTRAL CLAIM WAS THAT A FEEDFORWARD NET IS A TREE IN D&G'S SENSE, SO `deep`
## AND `tree` MIGHT BE ONE OBJECT. THE CODE SAYS NO, AND IT IS NOT CLOSE.
## rhizomatic_maze_space's `tree` is a graph-theoretic tree and its code says exactly that
## (RhizomaticMazeGenerator.gd:74-79): a minimum spanning tree, "no cycle: one origin, a
## strict descent, and between any two points exactly one route". A feedforward net is the
## other thing. nnv's `deep` is 4-3-3-3-3-3-2 — 21 neurons, 54 weights, where a tree on 21
## nodes has 20 edges — and the number of routes from one input to one output is 3^5 = 243,
## not 1. nnvr's `deep` is 5-4-4-4-4-4-2: 27 nodes, 92 lines, 4^5 = 1024 routes. So a
## feedforward net does not have too few paths, it has ENORMOUSLY MANY, all of exactly the
## same length, none of them lateral and none returning.
##
## What the brief was reaching for is real but it is a different word. D&G's *arborescent* is
## about stratification, hierarchy, an imposed direction; the graph-theorist's *tree* is about
## acyclicity. A feedforward net is arborescent and is not a tree. Conflating the two is the
## mistake this artifact exists to make visible, and the fix is not to delete the claim but to
## find the right pair: THE NEURAL WORD THAT MEANS WHAT `tree` MEANS IS `pinched`. A tree's
## minimum vertex cut is 1 — every internal node on the unique route is a bottleneck. A
## pinched net's minimum vertex cut is 1 — the waist. Measured on this artifact's own graphs
## (max-flow on the split-vertex network, exactly): tree 1, pinched 1, deep 2, graded 3,
## widened 3, flat 11, rhizome 2, severed 0. The difference between `tree` and `pinched` is
## not whether there is a bottleneck but how many: a tree is pinched everywhere at once, a
## pinched net exactly once. And the neural vocabulary really does have no word for `rhizome`,
## for the reason the brief gave — a strictly layered graph has no lateral edge and no return,
## so no amount of width makes it one.
##
## THE BODY. One network, and never a diagram of one: 24 spheres and the rods between them,
## laid out under whichever topology is asked for. The node budget is FIXED at 24 in every
## value — 22 interior plus a designated ENTRY and EXIT nailed at the same two points of the
## same box in all eight — so every value spends the same material and the rods are the whole
## argument. Nothing animates, nothing is printed, nothing is random: the interior scatter is
## a Halton sequence, the tree is Prim's, the cut is max-flow, the routes are BFS.

## WHAT SHAPE. The union of the two vocabularies, each in its members' own order.
## From the neural members (graded · flat · deep · widened · pinched, verbatim, both of them),
## as LAYER WIDTHS between ENTRY and EXIT, 22 interior nodes every time:
##   graded   8-6-5-3, a taper. 104 rods, 720 routes, narrowest cross-section 3.
##   flat     11-11. The members' `flat` is NOT "equal widths" — read the code: nnv sets
##            hidden = [] (gd:114) and nnvr sets [5,2] (gd:79), i.e. NO HIDDEN LAYER AT ALL,
##            input wired straight to output. nnv's comment calls it the architecture that
##            provably cannot learn the XOR data it stands in front of. So `flat` here is flat
##            in DEPTH: two columns, one curtain of 121 rods doing all the work, 143 rods
##            total, 121 routes, narrowest cross-section 11 — a whole column.
##   deep     2 x 11, eleven thin bays. 44 rods, 2048 routes, narrowest cross-section 2. The
##            fewest rods and the most routes in the set, which is the fact that kills the
##            deep-equals-tree reading.
##   widened  3-16-3, a bulge. 102 rods, 144 routes, narrowest cross-section 3.
##   pinched  11-1-10, a one-node waist. 42 rods, 110 routes, narrowest cross-section 1 —
##            everything the network knows passes through one sphere.
## From rhizomatic_maze_space (rhizome · tree · severed, its own order), as CONNECTIVITY over
## the same 24 points, an unlayered Halton scatter:
##   rhizome  every node reaches for its nearest neighbours, so routes close into loops and
##            there is no root and no last node. 55 rods, narrowest cross-section 2, and only
##            9 of its 55 rods lie on a shortest route — the tangle is mostly detour.
##   tree     Prim's minimum spanning tree from ENTRY. Exactly 23 rods, which is 24 - 1, which
##            is what makes it a tree. EXACTLY ONE route from ENTRY to EXIT, 10 rods long.
##   severed  the rhizome, grown in full and then cut: every rod crossing the middle band is
##            removed and the two fragments stand apart. 38 rods, ZERO routes, narrowest
##            cross-section 0 — there is nothing left to cut.
## NOTE THE ONE LINE. check_dna_declarations.py matches `@export...var <name>` on a SINGLE
## line; wrapped for readability, this axis reported NO EXPORT while apply_dna_block happily
## derived its values from the same enum — two tools disagreeing about one declaration, which
## is the corpus's usual tell that a gate is reading something other than what renders.
@export_enum("graded", "flat", "deep", "widened", "pinched", "rhizome", "tree", "severed") var topology: String = "graded":
	set(v):
		topology = v
		if _built:
			_rebuild()

## WHAT YOU ARE SHOWN OF IT. Three readings of one built network, each one geometry and not
## an overlay.
##   net     the nodes and the rods. The shape as such.
##   routes  every rod lying on a SHORTEST route from ENTRY to EXIT, rebuilt at ROUTE_R
##           instead of ROD_R and in the route colour. Exact, by two BFS passes. This is
##           where the three regimes separate absolutely: in a stratified net every route has
##           the same length, so "shortest" selects nothing and the whole net goes gold; in a
##           rhizome it selects a bundle (9 rods of 55); in a tree there is only ever one
##           route so one thread lights and 13 rods stay grey; in a severed network there is
##           no route at all and NOTHING changes.
##   cut     the narrowest cross-section, built. The minimum ENTRY-EXIT vertex cut, computed
##           by max-flow on the split-vertex network, its nodes rebuilt at CUT_R, a hoop laid
##           round each one in the plane across the flow, and every rod touching one of them
##           recoloured. flat marks a whole column of 11 and 132 of its 143 rods; pinched
##           marks one sphere; tree marks one sphere; severed marks nothing, because a graph
##           already in two pieces has an empty minimum cut.
@export_enum("net", "routes", "cut") var reading: String = "net":
	set(v):
		reading = v
		if _built:
			_rebuild()

## One network, or all eight topologies in a row at the current reading. NOT PART OF EITHER
## AXIS — wave 13 learned that an all-rungs value declared inside an axis makes
## capture_config_sweep union the row's AABB with every single and photograph the singles as
## specks. The registry fixture pins `single`.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		layout = v
		if _built:
			_rebuild()

const TOPOLOGIES: PackedStringArray = [
	"graded", "flat", "deep", "widened", "pinched", "rhizome", "tree", "severed"
]
const READINGS: PackedStringArray = ["net", "routes", "cut"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the one box, metres ────────────────────────────────────────────────────────────────
## Every value is fitted into the SAME envelope. This is a design constraint and not a
## convenience: a deep net is naturally long and a flat one naturally short, and if the
## extents differed the sweep would be measuring how big each value happens to be. Columns
## are pitched so the station count never changes the span, and a column of 2 is spread over
## the same height as a column of 16. Measured across all 24 variants the union is
## 0.916 x 0.936 x 0.735 m and no single variant exceeds it.
const SPAN: float = 1.05        ## ENTRY to EXIT, along R_AX, identical in all eight
const HEIGHT: float = 0.76      ## every column spans this, whatever its width
const DEPTH: float = 0.30       ## the rhizomatic scatter only; the layered five are planar
const CENTRE_Y: float = 0.50

## The layered five are built in the plane spanned by R_AX and UP, whose normal F_AX points
## at capture_config_sweep's standpoint (YAW 0.62 -> dir (sin 0.62, ., cos 0.62)). Every
## artifact has a front; this one's front is where the sweep stands, so a stratified net is
## photographed across its layers and not end-on. cos(0.62) = 0.813878, sin(0.62) = 0.581035.
const R_AX: Vector3 = Vector3(0.813878, 0.0, -0.581035)   ## screen-right at the sweep camera
const F_AX: Vector3 = Vector3(0.581035, 0.0, 0.813878)    ## toward the sweep camera

# ── the material budget, metres ────────────────────────────────────────────────────────
const NODE_R: float = 0.024     ## widened's 16-column pitches at 0.0507, so this just clears
const ROD_R: float = 0.013
const ROUTE_R: float = 0.025    ## a route rod is 1.9x a plain one
const CUT_R: float = 0.038
const HOOP_R: float = 0.078     ## the cross-section as a hoop across the flow
const HOOP_T: float = 0.010
const NODE_COUNT: int = 24      ## FIXED. 22 interior + ENTRY + EXIT, at every value.
const ENTRY: int = 0
const EXIT: int = 23

# ── the rhizomatic scatter ─────────────────────────────────────────────────────────────
## Halton(2, 3, 5), indices 1..22. Deterministic by construction: there is no randf, no
## randi and no RandomNumberGenerator anywhere in this file, so two builds of one value are
## the same mesh. rhizomatic_maze_space draws its layout from the UNSEEDED global RNG and
## had to add a `layout_draw = pinned` bench flag to be swept at all; the cheaper fix is not
## to draw at all.
const SPREAD: float = 0.94      ## the scatter's share of SPAN

## Neighbours each node reaches for. THE MEMBER'S RULE IS THREE (RhizomaticMazeGenerator.gd:64
## picks 3, or 5 for plateau) and it is overruled here on a measurement. At 250 nodes three
## nearest makes a tangle; at a 24-node budget it leaves a single articulation vertex —
## brute-forced, node 2, removing it disconnects ENTRY from EXIT, minimum vertex cut 1. A
## rhizome photographed with a bottleneck contradicts its own value. Four is the smallest k
## at which the cut exceeds one (measured: k=3 -> 45 rods and cut 1; k=4 -> 55 rods and cut 2;
## k=5 -> 70 rods and cut 3).
const RHIZ_K: int = 4

## The wound `severed` opens and the distance the fragments then stand apart, as fractions of
## SPAN. The member's numbers are FISSURE_FRACTION 0.14 / DRIFT_FRACTION 0.06; these are its
## rule at this scale. The member GROWS when it drifts; this one may not, because every value
## has to occupy the same box, so the surviving nodes are first compressed toward the cut by
## exactly the drift they are about to be given. The gap is a gap and not extra width.
const FISSURE: float = 0.10
const DRIFT: float = 0.055

const LADDER_PITCH: float = 1.15
const BIG: int = 1000000

var _built: bool = false
## Every node THIS SCRIPT parented to self. A rebuild frees these and nothing else: freeing
## get_children() would destroy the caption plates and bezels the grid adds after spawn.
var _owned: Array[Node] = []

var _mat_node: StandardMaterial3D = null
var _mat_rod: StandardMaterial3D = null
var _mat_route: StandardMaterial3D = null
var _mat_cut: StandardMaterial3D = null


func _ready() -> void:
	_build_all()
	_built = true


## The whole build, SYNCHRONOUS, from @export values alone — which is how the sweep reaches
## the axes: it sets `topology` and `reading` on the instance, adds it to the tree, and never
## calls apply_grid_config. Spheres and rods exist in frame one.
## The axis values are normalised into LOCALS and never written back to the exports. Writing
## them back would fire the setters from inside the build and recurse: a setter that rebuilds
## must never be assigned to by the rebuild.
func _build_all() -> void:
	_make_materials()
	var topo: String = _pick_axis(topology, TOPOLOGIES, "graded")
	var read_mode: String = _pick_axis(reading, READINGS, "net")
	var lay: String = _pick_axis(layout, LAYOUTS, "single")
	if lay == "ladder":
		for i in range(TOPOLOGIES.size()):
			var off: float = (float(i) - float(TOPOLOGIES.size() - 1) * 0.5) * LADDER_PITCH
			_emit_network(TOPOLOGIES[i], read_mode, R_AX * off)
	else:
		_emit_network(topo, read_mode, Vector3.ZERO)


func _rebuild() -> void:
	for n in _owned:
		if is_instance_valid(n):
			# remove_child BEFORE queue_free: queue_free is deferred, so a node freed but
			# still parented would be counted by the grid's auto-grounding AABB and by
			# capture_config_sweep's framing for one more frame.
			remove_child(n)
			n.queue_free()
	_owned.clear()
	_build_all()


func _own(n: Node) -> void:
	add_child(n)
	_owned.append(n)


func _pick_axis(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


func _make_materials() -> void:
	_mat_node = _mat(Color(0.80, 0.82, 0.87), 0.38)
	_mat_rod = _mat(Color(0.42, 0.44, 0.50), 0.52)
	_mat_route = _mat(Color(0.97, 0.72, 0.26), 0.34)
	_mat_cut = _mat(Color(0.28, 0.62, 0.96), 0.34)


func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.06
	return m


# =========================================================================================
#  THE GRAPHS
# =========================================================================================

## Layer widths for the five neural words. Each sums to 22, so ENTRY + interior + EXIT = 24
## at every value and the spheres are a constant. What changes is how they are grouped, which
## is the whole of what the neural vocabulary argues about.
func _columns_for(topo: String) -> PackedInt32Array:
	match topo:
		"graded":
			return PackedInt32Array([8, 6, 5, 3])
		"flat":
			return PackedInt32Array([11, 11])
		"deep":
			return PackedInt32Array([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2])
		"widened":
			return PackedInt32Array([3, 16, 3])
		"pinched":
			return PackedInt32Array([11, 1, 10])
	return PackedInt32Array()


func _halton(index: int, base: int) -> float:
	var f: float = 1.0
	var x: float = 0.0
	var i: int = index
	while i > 0:
		f /= float(base)
		x += f * float(i % base)
		@warning_ignore("integer_division")
		i = i / base     # int / int is integer division in GDScript 2, which is what Halton wants
	return x


## Local frame (a along R_AX, b along UP, c along F_AX) to world.
func _w(a: float, b: float, c: float) -> Vector3:
	return R_AX * a + Vector3.UP * b + F_AX * c + Vector3(0.0, CENTRE_Y, 0.0)


## Returns the 24 node positions in local (a, b, c) coordinates.
func _positions(topo: String) -> Array[Vector3]:
	var pts: Array[Vector3] = []
	var cols: PackedInt32Array = _columns_for(topo)
	if cols.size() > 0:
		var stations: int = cols.size() + 2
		pts.append(Vector3(-SPAN * 0.5, 0.0, 0.0))
		for k in range(cols.size()):
			var a: float = -SPAN * 0.5 + SPAN * float(k + 1) / float(stations - 1)
			var w: int = cols[k]
			for j in range(w):
				var b: float = 0.0
				if w > 1:
					b = (float(j) / float(w - 1) - 0.5) * HEIGHT
				pts.append(Vector3(a, b, 0.0))
		pts.append(Vector3(SPAN * 0.5, 0.0, 0.0))
		return pts
	pts.append(Vector3(-SPAN * 0.5, 0.0, 0.0))
	for i in range(1, 23):
		pts.append(Vector3(
			(_halton(i, 2) - 0.5) * SPAN * SPREAD,
			(_halton(i, 3) - 0.5) * HEIGHT,
			(_halton(i, 5) - 0.5) * DEPTH))
	pts.append(Vector3(SPAN * 0.5, 0.0, 0.0))
	return pts


## Undirected edges as Vector2i(min, max). For the layered five these are also the directed
## arcs, forward only: a stratified net has no lateral edge and no return, and that absence
## is half of what the word `deep` claims.
func _edges(topo: String, pts: Array[Vector3]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var seen: Dictionary = {}
	var cols: PackedInt32Array = _columns_for(topo)
	if cols.size() > 0:
		var prev: PackedInt32Array = PackedInt32Array([ENTRY])
		var next_id: int = 1
		for k in range(cols.size()):
			var group: PackedInt32Array = PackedInt32Array()
			for j in range(cols[k]):
				group.append(next_id)
				next_id += 1
			for p in prev:
				for q in group:
					out.append(Vector2i(p, q))
			prev = group
		for p in prev:
			out.append(Vector2i(p, EXIT))
		return out
	# rhizome / tree / severed, over the same scatter
	if topo == "tree":
		# Prim from ENTRY — rhizomatic_maze_space roots at its lowest seed; here the root is
		# the ENTRY, which is the lowest point of the network in the only order that matters
		# to a route. No randf: a tree is not a matter of chance, it is a rule about who is
		# permitted to connect to whom.
		var joined: Array[int] = [ENTRY]
		var pending: Array[int] = []
		for i in range(NODE_COUNT):
			if i != ENTRY:
				pending.append(i)
		while pending.size() > 0:
			var best_p: int = 0
			var best_j: int = 0
			var best_d: float = INF
			for pi in range(pending.size()):
				for ji in range(joined.size()):
					var d: float = pts[pending[pi]].distance_to(pts[joined[ji]])
					if d < best_d:
						best_d = d
						best_p = pi
						best_j = ji
			out.append(Vector2i(mini(joined[best_j], pending[best_p]),
				maxi(joined[best_j], pending[best_p])))
			joined.append(pending[best_p])
			pending.remove_at(best_p)
		return out
	# The k nearest by repeated strict-minimum selection rather than a sort: strict `<` means
	# the LOWEST INDEX wins a tie, so the neighbour set is fixed even if two Halton points
	# land equidistant. A sort_custom with an unstated tie rule is a hidden RNG.
	for i in range(NODE_COUNT):
		var taken: PackedInt32Array = PackedInt32Array()
		for _slot in range(RHIZ_K):
			var best: int = -1
			var best_dist: float = INF
			for j in range(NODE_COUNT):
				if j == i or taken.has(j):
					continue
				var dj: float = pts[i].distance_to(pts[j])
				if dj < best_dist:
					best_dist = dj
					best = j
			if best < 0:
				break
			taken.append(best)
			var key: int = mini(i, best) * 64 + maxi(i, best)
			if not seen.has(key):
				seen[key] = true
				out.append(Vector2i(mini(i, best), maxi(i, best)))
	if topo == "severed":
		var kept: Array[Vector2i] = []
		for e in out:
			if absf(pts[e.x].x) < SPAN * FISSURE or absf(pts[e.y].x) < SPAN * FISSURE:
				continue
			if (pts[e.x].x < 0.0) != (pts[e.y].x < 0.0):
				continue
			kept.append(e)
		out = kept
	# No sort: the dedup Dictionary preserves insertion order and the selection above is
	# deterministic, so the rod list is already fixed.
	return out


## severed only: compress toward the cut by exactly the drift, then drift. The object does
## not grow. Nodes stranded inside the fissure keep their spheres and lose every rod — a
## rupture leaves debris, and the budget of 24 is a budget whatever happens to it.
func _apply_sever(pts: Array[Vector3]) -> Array[Vector3]:
	var squeeze: float = 1.0 - 2.0 * DRIFT / SPAN
	var out: Array[Vector3] = []
	for p in pts:
		var a: float = p.x * squeeze + (DRIFT if p.x > 0.0 else -DRIFT)
		out.append(Vector3(a, p.y, p.z))
	return out


## Directed arcs for the flow and BFS passes: forward only for the layered five, both ways
## for the rhizomatic three.
func _arcs(topo: String, edges: Array[Vector2i]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var directed: bool = _columns_for(topo).size() > 0
	for e in edges:
		out.append(e)
		if not directed:
			out.append(Vector2i(e.y, e.x))
	return out


## THE NARROWEST CROSS-SECTION, exactly. Minimum ENTRY-EXIT vertex cut by max-flow on the
## split-vertex network: every node becomes in->out at capacity 1 (ENTRY and EXIT at BIG),
## every arc becomes out->in at BIG, so an augmenting path costs one node and the max flow is
## the number of vertex-disjoint routes. The cut itself is read off the residual graph, which
## names the SOURCE-SIDE minimal cut — canonical, so a value with several minimum cuts always
## marks the same one. widened has two cuts of size 3 (both outer columns) and marks the near
## one; graded's 3-column is its unique minimum and sits at the far end.
## The capacity matrix is ONE FLAT PackedInt32Array indexed x * n + y, and the adjacency
## lists are plain Arrays. Not a style choice: a PackedInt32Array nested inside an Array is a
## VALUE, so `cap[x][y] -= f` and `adj[i].append(j)` can operate on a copy and lose the write
## in silence — the same failure mode as a typed set() refused without an error.
func _min_vertex_cut(arcs: Array[Vector2i]) -> PackedInt32Array:
	var n: int = NODE_COUNT * 2
	var cap: PackedInt32Array = PackedInt32Array()
	cap.resize(n * n)
	for v in range(NODE_COUNT):
		cap[(v * 2) * n + (v * 2 + 1)] = BIG if (v == ENTRY or v == EXIT) else 1
	for a in arcs:
		cap[(a.x * 2 + 1) * n + (a.y * 2)] = BIG
	var src: int = ENTRY * 2 + 1
	var snk: int = EXIT * 2
	while true:
		var par: PackedInt32Array = PackedInt32Array()
		par.resize(n)
		par.fill(-1)
		par[src] = src
		var queue: Array[int] = [src]
		var head: int = 0
		while head < queue.size():
			var x: int = queue[head]
			head += 1
			for y in range(n):
				if par[y] < 0 and cap[x * n + y] > 0:
					par[y] = x
					queue.append(y)
		if par[snk] < 0:
			break
		var bottleneck: int = BIG
		var y2: int = snk
		while y2 != src:
			bottleneck = mini(bottleneck, cap[par[y2] * n + y2])
			y2 = par[y2]
		y2 = snk
		while y2 != src:
			cap[par[y2] * n + y2] -= bottleneck
			cap[y2 * n + par[y2]] += bottleneck
			y2 = par[y2]
	var seen: Array[bool] = []
	seen.resize(n)
	seen.fill(false)
	seen[src] = true
	var q2: Array[int] = [src]
	var h2: int = 0
	while h2 < q2.size():
		var x2: int = q2[h2]
		h2 += 1
		for y3 in range(n):
			if not seen[y3] and cap[x2 * n + y3] > 0:
				seen[y3] = true
				q2.append(y3)
	var cut: PackedInt32Array = PackedInt32Array()
	for v2 in range(NODE_COUNT):
		if seen[v2 * 2] and not seen[v2 * 2 + 1]:
			cut.append(v2)
	return cut


func _bfs(arcs: Array[Vector2i], src: int, reverse: bool) -> PackedInt32Array:
	var dist: PackedInt32Array = PackedInt32Array()
	dist.resize(NODE_COUNT)
	dist.fill(-1)
	var adj: Array = []
	for i in range(NODE_COUNT):
		adj.append([])
	for a in arcs:
		if reverse:
			adj[a.y].append(a.x)
		else:
			adj[a.x].append(a.y)
	dist[src] = 0
	var queue: Array[int] = [src]
	var head: int = 0
	while head < queue.size():
		var x: int = queue[head]
		head += 1
		for y in adj[x]:
			if dist[y] < 0:
				dist[y] = dist[x] + 1
				queue.append(y)
	return dist


## Rods on a shortest ENTRY-EXIT route. In a stratified net every route has the same length
## so this is every rod; in a rhizome it is a bundle; in a tree it is the one route there is;
## in a severed network the distance is unreachable and the set is EMPTY, which is what makes
## (severed, routes) identical to (severed, net) by construction.
func _route_edges(arcs: Array[Vector2i]) -> Dictionary:
	var hot: Dictionary = {}
	var ds: PackedInt32Array = _bfs(arcs, ENTRY, false)
	var dt: PackedInt32Array = _bfs(arcs, EXIT, true)
	var span: int = ds[EXIT]
	if span < 0:
		return hot
	for a in arcs:
		if ds[a.x] >= 0 and dt[a.y] >= 0 and ds[a.x] + 1 + dt[a.y] == span:
			hot[mini(a.x, a.y) * 64 + maxi(a.x, a.y)] = true
	return hot


# =========================================================================================
#  THE BODY
# =========================================================================================

func _emit_network(topo: String, read_mode: String, origin: Vector3) -> void:
	var pts: Array[Vector3] = _positions(topo)
	var edges: Array[Vector2i] = _edges(topo, pts)
	if topo == "severed":
		pts = _apply_sever(pts)
	var arcs: Array[Vector2i] = _arcs(topo, edges)

	var hot: Dictionary = {}
	if read_mode == "routes":
		hot = _route_edges(arcs)
	var cut: PackedInt32Array = PackedInt32Array()
	if read_mode == "cut":
		cut = _min_vertex_cut(arcs)

	var world: Array[Vector3] = []
	for p in pts:
		world.append(_w(p.x, p.y, p.z) + origin)

	for e in edges:
		var on_route: bool = hot.has(e.x * 64 + e.y)
		var on_cut: bool = cut.has(e.x) or cut.has(e.y)
		var rad: float = ROUTE_R if on_route else ROD_R
		var mat: StandardMaterial3D = _mat_rod
		if on_route:
			mat = _mat_route
		elif on_cut:
			mat = _mat_cut
		_rod(world[e.x], world[e.y], rad, mat)

	for k in range(NODE_COUNT):
		if cut.has(k):
			_ball(world[k], CUT_R, _mat_cut)
		else:
			_ball(world[k], NODE_R, _mat_node)

	if cut.size() > 0:
		var axis: Vector3 = (world[EXIT] - world[ENTRY]).normalized()
		for k2 in cut:
			_hoop(world[k2], axis)


func _ball(at: Vector3, r: float, mat: StandardMaterial3D) -> void:
	var m: SphereMesh = SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 14
	m.rings = 7
	m.material = mat
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = m
	mi.position = at
	_own(mi)


func _rod(a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> void:
	var d: Vector3 = b - a
	var length: float = d.length()
	if length < 0.0005:
		return
	var m: CylinderMesh = CylinderMesh.new()
	m.top_radius = r
	m.bottom_radius = r
	m.height = length
	m.radial_segments = 8
	m.rings = 1
	m.material = mat
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = m
	mi.transform = Transform3D(_basis_along(d / length), (a + b) * 0.5)
	_own(mi)


## The cross-section as a thing: a ring lying in the plane the flow has to pass through.
func _hoop(at: Vector3, axis: Vector3) -> void:
	var m: TorusMesh = TorusMesh.new()
	m.inner_radius = HOOP_R - HOOP_T
	m.outer_radius = HOOP_R + HOOP_T
	m.rings = 28
	m.ring_segments = 6
	m.material = _mat_cut
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = m
	mi.transform = Transform3D(_basis_along(axis), at)
	_own(mi)


## A basis whose +Y runs along `dir`. CylinderMesh and TorusMesh are both built around +Y, so
## one helper orients both. Not named _set — a helper by that name shadows Object.set() and
## takes a whole pass to find.
func _basis_along(dir: Vector3) -> Basis:
	var up: Vector3 = dir.normalized()
	var reference: Vector3 = Vector3.UP
	if absf(up.dot(Vector3.UP)) > 0.999:
		reference = Vector3.RIGHT
	var x: Vector3 = reference.cross(up).normalized()
	var z: Vector3 = up.cross(x).normalized()
	return Basis(x, up, z)


# =========================================================================================
#  GRID
# =========================================================================================

## Reached from a map token as `topology_net#topology:tree#reading:routes`. Arrives via
## call_deferred AFTER _ready(), so it must never build — only re-build, and only when
## something it knows actually moved.
func apply_grid_config(config_data: Dictionary) -> void:
	if not _built:
		return
	var before_topology: String = topology
	var before_reading: String = reading
	var before_layout: String = layout
	if config_data.has("topology"):
		topology = _pick_axis(str(config_data["topology"]), TOPOLOGIES, topology)
	if config_data.has("reading"):
		reading = _pick_axis(str(config_data["reading"]), READINGS, reading)
	if config_data.has("layout"):
		layout = _pick_axis(str(config_data["layout"]), LAYOUTS, layout)
	if topology == before_topology and reading == before_reading and layout == before_layout:
		return
	_rebuild()
	print("[TopologyNet] Config applied — topology=%s reading=%s layout=%s" % [
		topology, reading, layout])
