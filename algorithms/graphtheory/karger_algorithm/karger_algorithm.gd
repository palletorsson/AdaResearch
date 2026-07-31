class_name KargerAlgorithm
extends Node3D

# @identity
# essence: randomized edge contraction — repeatedly merge endpoints of a random edge (Union-Find) until 2 super-vertices remain; the crossing edges are a cut; P(finding min-cut) >= 2/(n*(n-1))
# desire: to watch four parallel contractions race side by side, each making different random choices, and see probability amplification turn a terrible single-run chance into near-certainty
# critical_parameter: initial_vertex_count (n) — P(success per run) = 2/(n*(n-1)); for n=8 that is ~3.6% per run, but parallel repetition amplifies it exponentially
# triggers: auto-demo starts new parallel rounds every _auto_interval seconds; ParameterController3D sliders for vertices, density, speed, and panel count; ImmediateMesh redrawn every frame
# emerges: the probability amplification chart shows observed success rate converging toward theoretical P(at least one success) = 1 - (1-p)^k as rounds accumulate
# needs: slider_horizontal [missing] (uses custom ParameterController3D instead); push_button [missing]; Label3D [has] (title, metrics, probability)
# relationships: appears in GT_Flow alongside push_relabel; demonstrates randomized algorithms and the power of repetition; contrasts with deterministic Edmonds-Karp
# truth: Karger's algorithm is a bet that randomness repeated enough times becomes certainty — the min-cut is always there, you just need enough attempts to stumble onto it

## Karger's Algorithm — Expressive VR 3D visualization
## Parallel run comparison: multiple simultaneous contractions, best-cut highlighting,
## probability amplification chart, cut/uncut edge coloring, VR slider controls.
## Shows how repeated random contractions amplify success probability from ~2/n² to ~1-1/e.

@export var bounding_size: float = 0.8
@export var initial_vertex_count: int = 8
@export var initial_edge_density: float = 0.45

# ── Stage-2 DNA axis: bottleneck ─────────────────────────────────────────
## WHERE THE NARROW PLACE IS, AND WHETHER THERE IS ONE AT ALL.
##
## Karger contracts random edges until two super-vertices remain and calls what
## still crosses a cut. Until now every placement stood on the same
## undifferentiated random graph, so the artifact whose entire subject is finding
## a minimum cut could never be asked to stand on a graph whose minimum cut is
## obvious, expensive, or already made.
##
##   mixed     the shipped graph — G(8, 0.45), ~13 edges on a 0.56 m ring.
##   throat    two 4-cliques joined by exactly 2 edges. The ring becomes a
##             dumbbell with a 0.10 m waist and every run finds the same cut of
##             size 2, so the probability argument becomes legible instead of
##             asserted.
##   braid     near-complete, 24 edges, a solid woven disc. No cheap cut exists;
##             the cut edges fan out around one vertex instead of crossing a
##             waist, and the random bet is hopeless.
##   severed   the same two 4-cliques with NO edge between them, and now the
##             layout says so instead of whispering it. The two lobes are pulled
##             out to +/-0.294 m, leaving a 0.420 m void between the nearest
##             vertices, and each component is floored with a filled 0.336 m
##             territory disc in its own partition colour — two islands with
##             0.252 m of nothing between them, not a ring with two edges
##             missing. Every panel finishes at cut size 0. This is the value
##             that earns the axis: the cut was never something the algorithm
##             made, only something it found.
##
## `severed` used to be `throat` with two hairline bridges deleted and its lobes
## nudged 1 cm: 14 edges against 12, 0.549 m against 0.560 m overall. At the
## critic's 160x160 those bridges are 0.3 px wide and that nudge is under a pixel,
## so the two opposite claims — flow is barely possible / flow is impossible —
## measured 4.48% apart and were one picture. The separation now lives in mass and
## position, the two things that survive the downsample.
##
## This axis is read at the top of _generate_graph, so setting the @export before
## _ready() is enough — the sweep never calls apply_grid_config.
@export_enum("mixed", "throat", "braid", "severed") var bottleneck: String = "mixed"

const BOTTLENECKS: PackedStringArray = ["mixed", "throat", "braid", "severed"]

## Dumbbell geometry, as fractions of the ring radius passed to _vertex_pos, so
## the main graph (r = 0.28) and the four panels read the same shape at both
## scales.
##   throat  : lobe d = 0.224 m, waist gap  = 0.100 m, overall 0.549 m
##   severed : lobe d = 0.168 m, vertex gap = 0.420 m, island d = 0.336 m,
##             void between islands = 0.252 m, overall 0.924 m
## `throat` is the shipped narrow place and is not touched. `severed` is small
## lobes flung wide: the same eight vertices, but the picture is two objects.
const THROAT_LOBE_R: float = 0.40
const THROAT_LOBE_CX: float = 0.58
const SEVERED_LOBE_R: float = 0.30
const SEVERED_LOBE_CX: float = 1.05

## The filled territory under each severed component, as a fraction of r, and how
## far under the graph plane it sits (also a fraction of r, so it scales with the
## panels). 0.60 makes the disc twice the clique's own ring radius: unmistakably a
## ground the component stands on, not a halo around it.
const SEVERED_ISLAND_R: float = 0.60
const SEVERED_ISLAND_DROP: float = 0.02

## Flung that wide, a severed panel graph would be 0.238 m across and hang off its
## 0.18 m card. Panels draw the same shape 38% smaller so it stays on the card;
## the main graph, which is what the critic actually resolves, keeps full size.
const SEVERED_PANEL_FIT: float = 0.62

## The pixel critic must never read noise as signal: two builds of one axis value
## have to be identical. _generate_graph reseeds from this before it draws a
## single edge, and the first four contraction orders are drawn from the same
## stream, so a still taken at the same beat of the same value is the same still.
const GRAPH_SEED: int = 20260729
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _built: bool = false
## _sync_controllers pushes values back into ParameterController3D, whose
## set_value() EMITS value_changed — which used to re-enter _on_density_changed →
## _rebuild_graph → _sync_controllers without end. The guard is what makes any
## config-driven rebuild survivable.
var _syncing: bool = false

# ── Graph state ──────────────────────────────────────────────────────────
var _n: int = 8
var _density: float = 0.45
var _adj: Array[PackedInt32Array] = []       # adjacency lists (edge indices)
var _edge_from: PackedInt32Array = PackedInt32Array()
var _edge_to: PackedInt32Array = PackedInt32Array()
var _edge_count: int = 0

# ── Parallel runs ────────────────────────────────────────────────────────
const MAX_PANELS: int = 4
var _num_panels: int = 4
var _run_states: Array[Dictionary] = []      # per-panel contraction state
var _best_global_cut: int = 999
var _best_global_edges: PackedInt32Array = PackedInt32Array()  # edge indices in best cut
var _best_panel: int = -1
var _total_runs: int = 0
var _success_count: int = 0                  # runs that found the actual min cut

# ── Animation ────────────────────────────────────────────────────────────
var _time: float = 0.0
var _anim_speed: float = 0.5                 # seconds per contraction step
var _anim_timer: float = 0.0
var _is_running: bool = false
var _is_initialized: bool = false
var _round: int = 0                          # how many full parallel rounds completed
var _flash: float = 0.0                      # completion flash

# Auto-demo
var _auto_timer: float = 0.0
var _auto_interval: float = 2.0

# ── Meshes (ImmediateMesh layers) ────────────────────────────────────────
# Main graph display
var _graph_mi: MeshInstance3D
var _graph_im: ImmediateMesh
var _graph_mat: StandardMaterial3D

# Parallel panels
var _panel_mis: Array[MeshInstance3D] = []
var _panel_ims: Array[ImmediateMesh] = []

# Probability chart
var _chart_mi: MeshInstance3D
var _chart_im: ImmediateMesh
var _chart_mat: StandardMaterial3D
var _prob_history: PackedFloat32Array = PackedFloat32Array()

# ── Labels ───────────────────────────────────────────────────────────────
var _title_label: Label3D
var _metrics_label: Label3D
var _prob_label: Label3D

# ── Controllers ──────────────────────────────────────────────────────────
var _vertex_ctrl: ParameterController3D
var _density_ctrl: ParameterController3D
var _speed_ctrl: ParameterController3D
var _panels_ctrl: ParameterController3D

# ── Layout constants ─────────────────────────────────────────────────────
const PANEL_SPACING: float = 0.48
const PANEL_SIZE: float = 0.18
const GRAPH_RADIUS: float = 0.28
const VERTEX_RADIUS: float = 0.015
const EDGE_WIDTH: float = 0.003

# Colors
const COL_VERTEX := Color(0.45, 0.65, 0.95)
const COL_VERTEX_A := Color(0.2, 0.85, 0.4)
const COL_VERTEX_B := Color(0.3, 0.35, 0.95)
const COL_EDGE := Color(0.5, 0.5, 0.55, 0.7)
const COL_CUT := Color(0.95, 0.85, 0.15)
const COL_BEST := Color(0.95, 0.25, 0.85)
const COL_CONTRACTED := Color(0.9, 0.25, 0.2, 0.35)
const COL_PANEL_BG := Color(0.08, 0.09, 0.14, 0.6)
const COL_CHART_BG := Color(0.06, 0.07, 0.11, 0.5)
const COL_CHART_BAR := Color(0.3, 0.75, 0.9)
const COL_CHART_THEORY := Color(0.95, 0.5, 0.2)
## `severed` only. Saturated and OPAQUE — the shared material has transparency
## disabled, and the point of the discs is unambiguous mass, not a tint. Keyed to
## COL_VERTEX_A / COL_VERTEX_B so each island is the colour of the partition that
## stands on it: vertex 0 is in the left lobe, so left is always the A side.
const COL_ISLAND_A := Color(0.09, 0.46, 0.22)
const COL_ISLAND_B := Color(0.15, 0.18, 0.62)


func _ready() -> void:
	_build_all()
	_built = true


## SYNCHRONOUS, from @export values alone. No call_deferred anywhere in the build
## path: a deferred rebuild that removes children first makes the grid's
## auto-grounding measure a zero AABB and bail.
func _build_all() -> void:
	_n = clampi(initial_vertex_count, 4, 12)
	_density = clampf(initial_edge_density, 0.2, 0.8)
	_generate_graph()
	_init_run_states()
	_setup_graph_mesh()
	_setup_panel_meshes()
	_setup_chart_mesh()
	_setup_labels()
	_setup_controllers()
	_is_initialized = true


# ── Graph generation ─────────────────────────────────────────────────────

## Every value's edge set and vertex layout is decided here, and this is the only
## place the axis is read on the build path — which is what makes the sweep
## (@export set, add to tree, never a config call) render the right thing.
func _generate_graph() -> void:
	bottleneck = _pick_axis(bottleneck, BOTTLENECKS, "mixed")
	# Two 4-cliques need exactly eight vertices; the vertex slider is pinned in
	# those two values and _sync_controllers pushes the pin back to the knob
	# rather than letting it show a number the graph does not have.
	if bottleneck == "throat" or bottleneck == "severed":
		_n = 8
	elif bottleneck == "braid":
		_density = 0.8

	_rng.seed = GRAPH_SEED

	_adj.clear()
	_edge_from.clear()
	_edge_to.clear()
	_edge_count = 0
	_best_global_cut = 999
	_best_global_edges.clear()
	_best_panel = -1
	_total_runs = 0
	_success_count = 0
	_round = 0
	_prob_history.clear()

	_adj.resize(_n)
	for i in range(_n):
		_adj[i] = PackedInt32Array()

	match bottleneck:
		"throat":
			_build_two_cliques(2)
		"severed":
			_build_two_cliques(0)
		"braid":
			_build_braid()
		_:
			_build_mixed()


## The shipped graph: G(n, density) plus a chain so it stays connected. Seeded
## now, so it is one particular random graph instead of a different one per run.
func _build_mixed() -> void:
	for i in range(_n):
		for j in range(i + 1, _n):
			if _rng.randf() < _density:
				_add_edge(i, j)

	# Ensure connectivity via chain
	for i in range(_n - 1):
		if not _has_edge(i, i + 1):
			_add_edge(i, i + 1)


## Two K4s and `bridges` edges between them — 14 edges at bridges=2, 12 at 0.
## The chain that _build_mixed uses to guarantee connectivity is deliberately NOT
## run here: edge 3-4 would cross the waist and turn a cut of 2 into a cut of 3,
## and in `severed` it would sew the two pieces back together.
##
## The bridges are (0, half+1) and (half-1, half+2) because those are the four
## vertices _vertex_pos puts nearest the waist, so both crossings are drawn as
## short parallel lines through the gap rather than long diagonals over a lobe.
func _build_two_cliques(bridges: int) -> void:
	var half: int = maxi(_n / 2, 2)
	for i in range(half):
		for j in range(i + 1, half):
			_add_edge(i, j)
			_add_edge(i + half, j + half)
	if bridges > 0:
		_add_edge(0, half + 1)
	if bridges > 1:
		_add_edge(half - 1, half + 2)


## Near-complete: every chord except the diameters. At n=8 that is 28 - 4 = 24
## edges, every vertex of degree 6, so the cheapest cut in the graph is one
## vertex's own star and no bipartition is cheap. Dropping the diameters leaves
## the disc a hollow centre, which is why it reads as a woven band and not as a
## solid blot.
func _build_braid() -> void:
	var diameter: int = _n / 2
	for i in range(_n):
		for j in range(i + 1, _n):
			if _n % 2 == 0 and j - i == diameter:
				continue
			_add_edge(i, j)


func _add_edge(a: int, b: int) -> void:
	var idx := _edge_count
	_edge_from.append(a)
	_edge_to.append(b)
	_adj[a].append(idx)
	_adj[b].append(idx)
	_edge_count += 1

func _has_edge(a: int, b: int) -> bool:
	for ei in _adj[a]:
		if (_edge_from[ei] == b or _edge_to[ei] == b):
			return true
	return false


# ── Vertex positions (circle, or dumbbell) ──────────────────────────────

## `throat` and `severed` split the ring into two lobes so the narrow place is
## visible as a narrow place — the layout has to say what the edge set says, or
## a waist of two edges just looks like a ring with two edges missing. The other
## two values keep the shipped circle: `braid` needs the full circumference for
## its chords, and `mixed` is the pre-promotion look.
func _vertex_pos(v: int, cx: float, cz: float, r: float) -> Vector3:
	if bottleneck == "throat" or bottleneck == "severed":
		var is_throat: bool = bottleneck == "throat"
		var lobe_r: float = (THROAT_LOBE_R if is_throat else SEVERED_LOBE_R) * r
		var lobe_cx: float = (THROAT_LOBE_CX if is_throat else SEVERED_LOBE_CX) * r
		var half: int = maxi(_n / 2, 2)
		var side: float = -1.0 if v < half else 1.0
		var li: int = v if v < half else v - half
		# +45° start puts one vertex of each lobe at each diagonal, so two sit
		# either side of the waist and none sits dead centre blocking it.
		var local: float = PI * 0.25 + (float(li) / float(half)) * TAU
		return Vector3(cx + side * lobe_cx + cos(local) * lobe_r, 0.0, cz + sin(local) * lobe_r)
	var angle: float = (float(v) / float(_n)) * TAU - PI * 0.5
	return Vector3(cx + cos(angle) * r, 0.0, cz + sin(angle) * r)


# ── Run state management ────────────────────────────────────────────────

func _init_run_states() -> void:
	_run_states.clear()
	for p in range(MAX_PANELS):
		_run_states.append(_make_fresh_run())

func _make_fresh_run() -> Dictionary:
	# Union-Find parent array for contraction
	var parent := PackedInt32Array()
	parent.resize(_n)
	for i in range(_n):
		parent[i] = i
	var rank := PackedInt32Array()
	rank.resize(_n)
	rank.fill(0)
	# Available edges (shuffled order for random contraction)
	var order := PackedInt32Array()
	for i in range(_edge_count):
		order.append(i)
	# Fisher-Yates shuffle — from the seeded stream, so the four contraction
	# orders that exist at build time are the same four every launch.
	for i in range(order.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := order[i]
		order[i] = order[j]
		order[j] = tmp
	return {
		"parent": parent,
		"rank": rank,
		"order": order,
		"step": 0,
		"remaining": _n,
		"done": false,
		"cut_size": 0,
		"cut_edges": PackedInt32Array(),
	}

func _uf_find(parent: PackedInt32Array, x: int) -> int:
	while parent[x] != x:
		parent[x] = parent[parent[x]]  # path compression
		x = parent[x]
	return x

func _uf_union(state: Dictionary, a: int, b: int) -> void:
	var ra := _uf_find(state.parent, a)
	var rb := _uf_find(state.parent, b)
	if ra == rb:
		return
	if state.rank[ra] < state.rank[rb]:
		state.parent[ra] = rb
	elif state.rank[ra] > state.rank[rb]:
		state.parent[rb] = ra
	else:
		state.parent[rb] = ra
		state.rank[ra] += 1
	state.remaining -= 1


# ── Advance one contraction step for a panel ─────────────────────────────

func _step_run(state: Dictionary) -> void:
	if state.done or state.remaining <= 2:
		if not state.done:
			_finalize_run(state)
		return

	# Find next edge that crosses components
	while state.step < state.order.size():
		var ei: int = state.order[state.step]
		state.step += 1
		var ra := _uf_find(state.parent, _edge_from[ei])
		var rb := _uf_find(state.parent, _edge_to[ei])
		if ra != rb:
			_uf_union(state, ra, rb)
			return

	# Ran out of edges (shouldn't happen with connected graph)
	_finalize_run(state)

func _finalize_run(state: Dictionary) -> void:
	state.done = true
	# Count cut edges
	var cut_size := 0
	var cut_edges := PackedInt32Array()
	for ei in range(_edge_count):
		var ra := _uf_find(state.parent, _edge_from[ei])
		var rb := _uf_find(state.parent, _edge_to[ei])
		if ra != rb:
			cut_size += 1
			cut_edges.append(ei)
	state.cut_size = cut_size
	state.cut_edges = cut_edges


# ── Process new round of parallel runs ───────────────────────────────────

func _start_round() -> void:
	for p in range(_num_panels):
		_run_states[p] = _make_fresh_run()
	_is_running = true
	_anim_timer = 0.0

func _check_round_complete() -> void:
	var all_done := true
	for p in range(_num_panels):
		if not _run_states[p].done:
			all_done = false
			break

	if all_done:
		_round += 1
		_total_runs += _num_panels

		# Find best in this round
		var round_best := 999
		var round_best_panel := 0
		for p in range(_num_panels):
			if _run_states[p].cut_size < round_best:
				round_best = _run_states[p].cut_size
				round_best_panel = p

		if round_best < _best_global_cut:
			_best_global_cut = round_best
			_best_global_edges = _run_states[round_best_panel].cut_edges.duplicate()
			_best_panel = round_best_panel
			_flash = 1.0

		# Count successes (matching global best)
		for p in range(_num_panels):
			if _run_states[p].cut_size == _best_global_cut:
				_success_count += 1

		# Record probability history
		if _total_runs > 0:
			_prob_history.append(float(_success_count) / float(_total_runs))
			if _prob_history.size() > 40:
				_prob_history.remove_at(0)

		_is_running = false
		_auto_timer = 0.0


# ── Mesh setup ───────────────────────────────────────────────────────────

func _make_unshaded_mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if color.a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	return mat

func _setup_graph_mesh() -> void:
	_graph_im = ImmediateMesh.new()
	_graph_mi = MeshInstance3D.new()
	_graph_mi.mesh = _graph_im
	_graph_mat = _make_unshaded_mat(Color.WHITE)
	_graph_mi.material_override = _graph_mat
	_graph_mi.position = Vector3(0.0, 0.35, 0.0)
	add_child(_graph_mi)

func _setup_panel_meshes() -> void:
	_panel_mis.clear()
	_panel_ims.clear()
	for p in range(MAX_PANELS):
		var im := ImmediateMesh.new()
		var mi := MeshInstance3D.new()
		mi.mesh = im
		mi.material_override = _make_unshaded_mat(Color.WHITE)
		var x_offset := (float(p) - 1.5) * PANEL_SPACING
		mi.position = Vector3(x_offset, -0.05, 0.0)
		add_child(mi)
		_panel_mis.append(mi)
		_panel_ims.append(im)

func _setup_chart_mesh() -> void:
	_chart_im = ImmediateMesh.new()
	_chart_mi = MeshInstance3D.new()
	_chart_mi.mesh = _chart_im
	_chart_mat = _make_unshaded_mat(Color.WHITE)
	_chart_mi.material_override = _chart_mat
	_chart_mi.position = Vector3(0.0, -0.32, 0.0)
	add_child(_chart_mi)


# ── Label setup ──────────────────────────────────────────────────────────

func _make_label(pos: Vector3, font_sz: int) -> Label3D:
	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.font_size = font_sz
	lbl.modulate = Color(0.95, 0.95, 0.97, 1.0)
	lbl.outline_size = 4
	lbl.outline_modulate = Color(0.05, 0.06, 0.09)
	lbl.position = pos
	add_child(lbl)
	return lbl

## CAPTION PLACEMENT. LabelFramer turns each of these three into an opaque
## anthracite plate at spawn, so where they sit is a geometry decision.
##
## Title (font 28, glyphs 0.14 m) and metrics (font 20, 0.10 m) share a parent
## and a column 0.07 m apart, so the framer merges them into ONE plate spanning
## roughly y 0.50..0.69 — above the graph's 0.35 m plane by 0.15 m. Correct as
## authored; left alone.
##
## The probability caption was the fault. At y=-0.22 with 0.09 m glyphs its plate
## spanned -0.30..-0.14 while the amplification chart occupies -0.33..-0.19
## across the full 1.62 m body — about 0.18 m2 of frontal overlap against a
## 1.09 m2 body, ~16%, eight times the probe's 2% bar. Moved to y=-0.50: the
## plate now spans -0.58..-0.42, clearing the chart's bottom edge by 0.09 m,
## below the four controllers at y=0, in a band nothing else occupies. Fixed
## offsets are safe because no bottleneck value moves the graph plane, the panel
## row or the chart — a caption correct at `mixed` is correct at all four.
func _setup_labels() -> void:
	_title_label = _make_label(Vector3(0, 0.62, 0), 28)
	_metrics_label = _make_label(Vector3(0, 0.55, 0), 20)
	_prob_label = _make_label(Vector3(0, -0.50, 0), 18)


# ── Controller setup ─────────────────────────────────────────────────────

func _make_ctrl(pname: String, lo: float, hi: float, val: float, step: float) -> ParameterController3D:
	var ctrl := ParameterController3D.new()
	ctrl.parameter_name = pname
	ctrl.min_value = lo
	ctrl.max_value = hi
	ctrl.default_value = val
	ctrl.step_size = step
	add_child(ctrl)
	return ctrl

func _setup_controllers() -> void:
	_vertex_ctrl = _make_ctrl("Vertices", 4.0, 12.0, float(_n), 1.0)
	_vertex_ctrl.position = Vector3(-0.35, 0.0, 0.35)
	_vertex_ctrl.value_changed.connect(_on_vertex_changed)

	_density_ctrl = _make_ctrl("Edge density", 0.2, 0.8, _density, 0.05)
	_density_ctrl.position = Vector3(-0.12, 0.0, 0.35)
	_density_ctrl.value_changed.connect(_on_density_changed)

	_speed_ctrl = _make_ctrl("Anim speed", 0.1, 1.5, _anim_speed, 0.1)
	_speed_ctrl.position = Vector3(0.12, 0.0, 0.35)
	_speed_ctrl.value_changed.connect(_on_speed_changed)

	_panels_ctrl = _make_ctrl("Panels", 1.0, 4.0, float(_num_panels), 1.0)
	_panels_ctrl.position = Vector3(0.35, 0.0, 0.35)
	_panels_ctrl.value_changed.connect(_on_panels_changed)

func _on_vertex_changed(val: float) -> void:
	if _syncing:
		return
	var new_n := clampi(int(val), 4, 12)
	if new_n != _n:
		_n = new_n
		_rebuild_graph()

func _on_density_changed(val: float) -> void:
	if _syncing:
		return
	_density = clampf(val, 0.2, 0.8)
	_rebuild_graph()

func _on_speed_changed(val: float) -> void:
	if _syncing:
		return
	_anim_speed = clampf(val, 0.1, 1.5)

func _on_panels_changed(val: float) -> void:
	if _syncing:
		return
	_num_panels = clampi(int(val), 1, 4)
	_apply_panel_visibility()

func _apply_panel_visibility() -> void:
	for p in range(MAX_PANELS):
		if p < _panel_mis.size() and is_instance_valid(_panel_mis[p]):
			_panel_mis[p].visible = p < _num_panels

func _rebuild_graph() -> void:
	_rebuild_now()


## SYNCHRONOUS and node-preserving. Everything this artifact draws is an
## ImmediateMesh regenerated from _adj / _edge_* every frame, so a new bottleneck
## is a new data set, not a new scene: nothing needs freeing and nothing may be.
## Freeing the three Label3Ds in particular would destroy the plates LabelFramer
## already built around them at spawn, and the framer does not run twice.
func _rebuild_now() -> void:
	_generate_graph()
	_init_run_states()
	_is_running = false
	_auto_timer = 0.0
	_sync_controllers()

func _sync_controllers() -> void:
	# ParameterController3D.set_value() emits value_changed, and the handlers
	# above rebuild — without this flag a single density push re-enters until the
	# stack gives out.
	if _syncing:
		return
	_syncing = true
	if _vertex_ctrl:
		_vertex_ctrl.set_value(float(_n))
	if _density_ctrl:
		_density_ctrl.set_value(_density)
	if _speed_ctrl:
		_speed_ctrl.set_value(_anim_speed)
	if _panels_ctrl:
		_panels_ctrl.set_value(float(_num_panels))
	_syncing = false


# ── Process loop ─────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _is_initialized:
		return

	_time += delta
	_flash = maxf(_flash - delta * 2.0, 0.0)

	if _is_running:
		_anim_timer += delta
		if _anim_timer >= _anim_speed:
			_anim_timer -= _anim_speed
			# Advance each panel one step
			for p in range(_num_panels):
				_step_run(_run_states[p])
			_check_round_complete()
	else:
		# Auto-start next round
		_auto_timer += delta
		if _auto_timer >= _auto_interval:
			_start_round()

	_rebuild_graph_mesh()
	_rebuild_panel_meshes()
	_rebuild_chart_mesh()
	_update_labels()


# ── Rebuild main graph ───────────────────────────────────────────────────

func _rebuild_graph_mesh() -> void:
	_graph_im.clear_surfaces()

	var half := bounding_size * 0.5

	# `severed` ONLY — every other value falls straight through to the shipped
	# draw order, so `mixed` builds exactly what it built before this branch
	# existed. Drawn first so the graph lands on top of its own ground.
	if bottleneck == "severed":
		_graph_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		_add_severed_islands(_graph_im, 0.0, 0.0, GRAPH_RADIUS)
		_graph_im.surface_end()

	# Draw edges
	_graph_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for ei in range(_edge_count):
		var a := _edge_from[ei]
		var b := _edge_to[ei]
		var pa := _vertex_pos(a, 0.0, 0.0, GRAPH_RADIUS)
		var pb := _vertex_pos(b, 0.0, 0.0, GRAPH_RADIUS)

		var is_cut := false
		for ci in _best_global_edges:
			if ci == ei:
				is_cut = true
				break

		var col: Color
		if is_cut:
			# Pulse cut edges
			var pulse := 0.6 + 0.4 * sin(_time * 4.0)
			col = COL_CUT.lerp(COL_BEST, pulse)
		else:
			col = COL_EDGE

		_add_line_ribbon(_graph_im, pa, pb, EDGE_WIDTH, col)
	_graph_im.surface_end()

	# Draw vertices
	_graph_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in range(_n):
		var pos := _vertex_pos(v, 0.0, 0.0, GRAPH_RADIUS)
		# Color by partition if we have a best cut
		var col := COL_VERTEX
		# Gate on a finished round, NOT on a non-empty cut list. A connected
		# graph always ends with at least one crossing edge so the two are the
		# same test in `mixed`, `throat` and `braid` — but `severed` finishes at
		# cut size 0 with an empty list, and the old test left all eight vertices
		# one colour in the one value whose whole point is that they are two.
		if _best_global_cut < 999 and _run_states.size() > 0:
			var state: Dictionary = _run_states[0] if _best_panel < 0 else _run_states[clampi(_best_panel, 0, _num_panels - 1)]
			if state.done:
				# Determine partition from the best run
				var root0 := _uf_find(state.parent, 0)
				var root_v := _uf_find(state.parent, v)
				col = COL_VERTEX_A if root_v == root0 else COL_VERTEX_B
		_add_sphere_approx(_graph_im, pos, VERTEX_RADIUS, col)
	_graph_im.surface_end()


# ── Rebuild panel meshes ─────────────────────────────────────────────────

func _rebuild_panel_meshes() -> void:
	for p in range(MAX_PANELS):
		var im: ImmediateMesh = _panel_ims[p]
		im.clear_surfaces()

		if p >= _num_panels:
			continue

		var state: Dictionary = _run_states[p]
		var panel_r: float = PANEL_SIZE * 0.4
		if bottleneck == "severed":
			panel_r = PANEL_SIZE * 0.4 * SEVERED_PANEL_FIT

		# Panel background
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		var bgc := COL_PANEL_BG
		if state.done and state.cut_size == _best_global_cut:
			bgc = Color(0.1, 0.2, 0.12, 0.6)  # green tint for best
			if _flash > 0.0 and p == _best_panel:
				bgc = bgc.lerp(Color(0.3, 0.6, 0.2, 0.8), _flash)
		_add_quad(im, Vector3(-PANEL_SIZE * 0.5, -PANEL_SIZE * 0.45, 0.001),
				  Vector3(PANEL_SIZE, 0.0, 0.0), Vector3(0.0, PANEL_SIZE * 0.75, 0.0), bgc)
		im.surface_end()

		# Same two territories on the card, 38% down. Four panels x two islands is
		# eight more coloured patches that only `severed` has.
		if bottleneck == "severed":
			im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			_add_severed_islands(im, 0.0, 0.0, panel_r)
			im.surface_end()

		# Draw edges
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for ei in range(_edge_count):
			var a := _edge_from[ei]
			var b := _edge_to[ei]
			var pa := _vertex_pos(a, 0.0, 0.0, panel_r)
			var pb := _vertex_pos(b, 0.0, 0.0, panel_r)

			var ra := _uf_find(state.parent, a)
			var rb := _uf_find(state.parent, b)

			var col: Color
			if state.done:
				var is_cut := ra != rb
				col = COL_CUT if is_cut else COL_EDGE.lerp(COL_VERTEX, 0.3)
			else:
				if ra == rb:
					col = COL_CONTRACTED
				else:
					col = COL_EDGE
			_add_line_ribbon(im, pa, pb, EDGE_WIDTH * 0.6, col)
		im.surface_end()

		# Draw vertices
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for v in range(_n):
			var pos := _vertex_pos(v, 0.0, 0.0, panel_r)
			var root := _uf_find(state.parent, v)
			var col: Color
			if state.done:
				var root0 := _uf_find(state.parent, 0)
				col = COL_VERTEX_A if root == root0 else COL_VERTEX_B
			elif root != v:
				col = COL_CONTRACTED.lerp(COL_VERTEX, 0.3)
			else:
				col = COL_VERTEX
			_add_sphere_approx(im, pos, VERTEX_RADIUS * 0.7, col)
		im.surface_end()

		# Cut size label rendered as small boxes (digit encoding)
		if state.done:
			im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			var cut_col := COL_BEST if state.cut_size == _best_global_cut else COL_CUT
			# Small indicator bar proportional to cut size
			var bar_w := clampf(float(state.cut_size) / float(maxi(_edge_count, 1)) * PANEL_SIZE * 0.8, 0.005, PANEL_SIZE * 0.8)
			_add_quad(im, Vector3(-bar_w * 0.5, -PANEL_SIZE * 0.42, 0.0),
					  Vector3(bar_w, 0.0, 0.0), Vector3(0.0, 0.015, 0.0), cut_col)
			im.surface_end()


# ── Rebuild chart (probability amplification) ────────────────────────────

func _rebuild_chart_mesh() -> void:
	_chart_im.clear_surfaces()

	var chart_w := bounding_size * 0.8
	var chart_h := 0.12
	var base_x := -chart_w * 0.5
	var base_y := 0.0

	# Background
	_chart_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_quad(_chart_im, Vector3(base_x - 0.01, base_y - 0.01, 0.001),
			  Vector3(chart_w + 0.02, 0.0, 0.0), Vector3(0.0, chart_h + 0.02, 0.0), COL_CHART_BG)
	_chart_im.surface_end()

	if _prob_history.size() < 2:
		return

	# Probability bars
	_chart_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var bar_count := _prob_history.size()
	var bar_w := chart_w / float(bar_count)

	for i in range(bar_count):
		var prob := _prob_history[i]
		var bx := base_x + float(i) * bar_w
		var bh := prob * chart_h
		_add_quad(_chart_im, Vector3(bx + bar_w * 0.1, base_y, 0.0),
				  Vector3(bar_w * 0.8, 0.0, 0.0), Vector3(0.0, bh, 0.0), COL_CHART_BAR)

	# Theoretical line: P(success per run) = 2/(n*(n-1)), amplified over k runs
	# P(fail all k) = (1 - 2/(n*(n-1)))^k → P(at least one) = 1 - (1-p)^k
	var p_single := 2.0 / float(_n * (_n - 1)) if _n > 1 else 1.0
	for i in range(bar_count):
		var k := float((i + 1) * _num_panels)
		var p_amp := 1.0 - pow(1.0 - p_single, k)
		var bx := base_x + float(i) * bar_w + bar_w * 0.4
		var bh := clampf(p_amp, 0.0, 1.0) * chart_h
		_add_quad(_chart_im, Vector3(bx, base_y, -0.001),
				  Vector3(bar_w * 0.2, 0.0, 0.0), Vector3(0.0, bh, 0.0), COL_CHART_THEORY)

	_chart_im.surface_end()


# ── Update labels ────────────────────────────────────────────────────────

func _update_labels() -> void:
	if _title_label:
		_title_label.text = "Karger's Min-Cut — Parallel Runs"

	if _metrics_label:
		var status := "running..." if _is_running else "idle"
		_metrics_label.text = "n=%d  edges=%d | round %d | best cut=%s | %s" % [
			_n, _edge_count, _round,
			str(_best_global_cut) if _best_global_cut < 999 else "?",
			status
		]

	if _prob_label:
		var p_single := 2.0 / float(_n * (_n - 1)) if _n > 1 else 1.0
		var p_amp := 1.0 - pow(1.0 - p_single, float(maxi(_total_runs, 1)))
		var obs_rate := float(_success_count) / float(maxi(_total_runs, 1)) * 100.0 if _total_runs > 0 else 0.0
		# Under 30 characters at worst ("p=100.0%  amp=100%  obs=100%" = 28), so
		# the plate stays inside the 1.62 m body width instead of the ~1.9 m the
		# long form needed.
		_prob_label.text = "p=%.1f%%  amp=%.0f%%  obs=%.0f%%" % [
			p_single * 100.0, p_amp * 100.0, obs_rate
		]
		# Color by observed success
		if obs_rate > 50.0:
			_prob_label.modulate = Color(0.3, 0.95, 0.5)
		elif obs_rate > 20.0:
			_prob_label.modulate = Color(0.95, 0.9, 0.3)
		else:
			_prob_label.modulate = Color(0.95, 0.95, 0.97)


# ── Geometry helpers ─────────────────────────────────────────────────────

func _add_quad(im: ImmediateMesh, origin: Vector3, right: Vector3, up: Vector3, col: Color) -> void:
	var a := origin
	var b := origin + right
	var c := origin + right + up
	var d := origin + up
	im.surface_set_color(col)
	im.surface_add_vertex(a)
	im.surface_set_color(col)
	im.surface_add_vertex(b)
	im.surface_set_color(col)
	im.surface_add_vertex(c)
	im.surface_set_color(col)
	im.surface_add_vertex(a)
	im.surface_set_color(col)
	im.surface_add_vertex(c)
	im.surface_set_color(col)
	im.surface_add_vertex(d)

## A filled disc lying flat in the XZ plane, as a fan from the centre.
##
## The sweep camera sits ~33 degrees above the horizon, so a horizontal disc
## projects to an ellipse about half as tall as it is wide — still the only
## primitive in this artifact with real AREA. Every line here is 3 mm wide, which
## is a third of a pixel once the critic resizes the frame to 160x160; area is
## what survives that, and area is what tells two graphs apart.
##
## Both windings are emitted. The shared material culls back faces and this
## artifact's only other flat-in-XZ primitive (_add_line_ribbon) relies on Godot's
## clockwise-front convention to face upward; a disc that guessed wrong would be
## invisible from the one angle the sweep uses, and six triangles cost nothing.
func _add_disc_fan(im: ImmediateMesh, centre: Vector3, radius: float, col: Color, segments: int = 24) -> void:
	for s in range(segments):
		var a0: float = TAU * float(s) / float(segments)
		var a1: float = TAU * float(s + 1) / float(segments)
		var p0: Vector3 = centre + Vector3(cos(a0) * radius, 0.0, sin(a0) * radius)
		var p1: Vector3 = centre + Vector3(cos(a1) * radius, 0.0, sin(a1) * radius)
		im.surface_set_color(col)
		im.surface_add_vertex(centre)
		im.surface_set_color(col)
		im.surface_add_vertex(p0)
		im.surface_set_color(col)
		im.surface_add_vertex(p1)
		im.surface_set_color(col)
		im.surface_add_vertex(centre)
		im.surface_set_color(col)
		im.surface_add_vertex(p1)
		im.surface_set_color(col)
		im.surface_add_vertex(p0)


## The two territories of `severed`, at whatever scale the caller draws its graph.
## Dropped a hair below the graph plane so the edges and vertices still read on
## top of their own ground instead of z-fighting with it.
func _add_severed_islands(im: ImmediateMesh, cx: float, cz: float, r: float) -> void:
	var island_r: float = SEVERED_ISLAND_R * r
	var dy: float = -SEVERED_ISLAND_DROP * r
	for side_i in range(2):
		var side: float = -1.0 if side_i == 0 else 1.0
		var centre: Vector3 = Vector3(cx + side * SEVERED_LOBE_CX * r, dy, cz)
		var col: Color = COL_ISLAND_A if side_i == 0 else COL_ISLAND_B
		_add_disc_fan(im, centre, island_r, col)


func _add_line_ribbon(im: ImmediateMesh, a: Vector3, b: Vector3, width: float, col: Color) -> void:
	# Flat ribbon in XZ plane
	var dir := (b - a).normalized()
	var perp := Vector3(-dir.z, 0.0, dir.x) * width * 0.5
	if perp.length_squared() < 0.0001:
		perp = Vector3(width * 0.5, 0.0, 0.0)
	var v0 := a + perp
	var v1 := a - perp
	var v2 := b - perp
	var v3 := b + perp
	im.surface_set_color(col)
	im.surface_add_vertex(v0)
	im.surface_set_color(col)
	im.surface_add_vertex(v1)
	im.surface_set_color(col)
	im.surface_add_vertex(v2)
	im.surface_set_color(col)
	im.surface_add_vertex(v0)
	im.surface_set_color(col)
	im.surface_add_vertex(v2)
	im.surface_set_color(col)
	im.surface_add_vertex(v3)

func _add_sphere_approx(im: ImmediateMesh, center: Vector3, radius: float, col: Color, segments: int = 6) -> void:
	var rings := segments
	var slices := segments * 2
	for ring in range(rings):
		var theta0 := PI * float(ring) / float(rings)
		var theta1 := PI * float(ring + 1) / float(rings)
		var st0 := sin(theta0)
		var ct0 := cos(theta0)
		var st1 := sin(theta1)
		var ct1 := cos(theta1)
		for sl in range(slices):
			var phi0 := TAU * float(sl) / float(slices)
			var phi1 := TAU * float(sl + 1) / float(slices)
			var sp0 := sin(phi0)
			var cp0 := cos(phi0)
			var sp1 := sin(phi1)
			var cp1 := cos(phi1)

			var p00 := center + Vector3(st0 * cp0, ct0, st0 * sp0) * radius
			var p01 := center + Vector3(st0 * cp1, ct0, st0 * sp1) * radius
			var p10 := center + Vector3(st1 * cp0, ct1, st1 * sp0) * radius
			var p11 := center + Vector3(st1 * cp1, ct1, st1 * sp1) * radius

			im.surface_set_color(col)
			im.surface_add_vertex(p00)
			im.surface_set_color(col)
			im.surface_add_vertex(p10)
			im.surface_set_color(col)
			im.surface_add_vertex(p11)
			im.surface_set_color(col)
			im.surface_add_vertex(p00)
			im.surface_set_color(col)
			im.surface_add_vertex(p11)
			im.surface_set_color(col)
			im.surface_add_vertex(p01)


# ── apply_grid_config ────────────────────────────────────────────────────

## Called by GridInteractablesComponent via call_deferred, after _ready(). It is
## also handed {"emissive": false} by curation_station one line after it frames
## the labels — a dict with no key this artifact claims, which must therefore
## change nothing at all. It does: nothing is read from it, the four geometry
## keys are unchanged, and the guard below returns before any rebuild.
##
## This is the one artifact in the batch whose config path was already live, so
## `bottleneck` has to exist on BOTH paths — as the @export read at the top of
## _generate_graph (the sweep never calls this function) and as the branch here
## (the map path) — or the two would disagree about what is standing there.
func apply_grid_config(config: Dictionary) -> void:
	var before_bottleneck: String = bottleneck
	var before_n: int = _n
	var before_density: float = _density

	if config.has("bottleneck"):
		bottleneck = _pick_axis(str(config["bottleneck"]), BOTTLENECKS, bottleneck)
	if config.has("vertex_count"):
		_n = clampi(int(config["vertex_count"]), 4, 12)
	if config.has("edge_density"):
		_density = clampf(float(config["edge_density"]), 0.2, 0.8)

	# Non-geometry keys apply IN PLACE, before the returns, or a config that only
	# sets speed or panel count would be silently swallowed by the guard.
	if config.has("anim_speed"):
		_anim_speed = clampf(float(config["anim_speed"]), 0.1, 1.5)
	if config.has("panels"):
		_num_panels = clampi(int(config["panels"]), 1, 4)
		_apply_panel_visibility()
	_sync_controllers()

	if not _built:
		return
	if bottleneck == before_bottleneck and _n == before_n \
			and is_equal_approx(_density, before_density):
		return
	_rebuild_now()
	print("[KargerAlgorithm] Config applied — bottleneck=%s, n=%d, edges=%d" % [
		bottleneck, _n, _edge_count])


## Accept an axis value only if it names something this artifact actually builds.
## A typo in a map token falls back to the value already standing rather than to
## an empty graph.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


# ── Algorithm info ───────────────────────────────────────────────────────

func get_algorithm_info() -> Dictionary:
	var p_single := 2.0 / float(_n * (_n - 1)) if _n > 1 else 1.0
	return {
		"name": "Karger's Algorithm",
		"description": "Randomized contraction algorithm for minimum cut with parallel runs",
		"time_complexity": "O(V² per run, n²·log(n) runs for high probability)",
		"space_complexity": "O(V + E)",
		"min_cut_size": _best_global_cut if _best_global_cut < 999 else -1,
		"total_runs": _total_runs,
		"success_probability_single": p_single,
		"success_probability_amplified": 1.0 - pow(1.0 - p_single, float(maxi(_total_runs, 1))),
	}
