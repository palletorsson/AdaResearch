extends Node3D
class_name AlgorithmMenu

## algorithm_menu — an axis with thirty-six values, no two of them in the same space.
##
## THE FAMILY, AND IT IS A CENSUS BEFORE IT IS AN ARGUMENT. Three artifacts declare an
## axis called `algorithm`:
##
##   grid2d    12 values   GAME_OF_LIFE SEEDS BRIANS_BRAIN RULE30 RULE110 RULE90
##                         BFS_FLOOD DFS_MAZE WIRE_WORLD LANGTONS_ANT SLOW RANDOM
##   grid3d     8 values   BFS DFS DIJKSTRA KRUSKAL_MST PRIM_MST FORCE_DIRECTED
##                         RANDOM_GRAPH ENTROPY_FIELD
##   profile   16 values   SINE_WAVE SQUARE_WAVE SAW_WAVE TRIANGLE_WAVE FOURIER_SERIES
##                         BEAT_FREQUENCIES LISSAJOUS_1D NOISE_1D NOISE_OCTAVES
##                         RANDOM_WALK BROWNIAN_BRIDGE BELL_CURVE DAMPED_OSCILLATION
##                         SPRING_MASS GRADIENT_DESCENT LOGISTIC_MAP
##
## 36 declared values. THE UNION IS ALSO 36. Every pairwise intersection is EMPTY —
## grid2d against grid3d, grid2d against profile, grid3d against profile, all three
## measured, all three the empty set. cohort_bench's family agreed on five words out of
## five; this one agrees on nothing out of thirty-six. And the near-misses are the tell
## rather than the exception: grid2d's BFS_FLOOD and grid3d's BFS are the same traversal,
## grid2d's DFS_MAZE and grid3d's DFS are the same traversal, and they fail to collide
## only because each member spelled its own menu entry after its own cartridge file.
##
## SO `algorithm` IS NOT AN AXIS. An axis is a dimension of variation — one thing varied
## while everything else is held. This is a DISPATCH TABLE: the list of cartridges a
## particular widget happens to preload. `_create_cartridge()` in each of the three files
## is a `match` block over its own enum, one branch per preload. A menu has no closest
## pair in any meaningful sense, because its values are not points in a space; asking
## which two of SINE_WAVE, LANGTONS_ANT and PRIM_MST are nearest is asking which two
## branches of a switch statement are nearest.
##
## FIVE THINGS THE CODE SAID THAT THE BRIEF DID NOT, each measured:
##
## 1. RULE30, RULE110 AND RULE90 ARE ONE ALGORITHM AT THREE VALUES OF A PARAMETER, and
##    grid2d's own factory says so in three consecutive lines: `.new(30)`, `.new(110)`,
##    `.new(90)`, all three on cartridge_rule_1d.gd, whose entire state is
##    `var rule_number: int = 30`. Meanwhile ca_bridge declares an axis literally named
##    `rule` with values [30, 90, 110, 250], and wave 16's rule_bench was built on it.
##    THE CORPUS DECLARES ONE THING UNDER TWO AXIS NAMES, and the honest name is the one
##    on the other artifact. Three of grid2d's twelve "algorithms" are one algorithm.
##
## 2. SLOW IS THE SAME SHAPE AGAIN, and sharper than the brief guessed. The brief said
##    SLOW is a speed. cartridge_slow.gd is a real rule — `grid[i] = (grid[i] + 1) % 8`
##    over a diagonal init — and its own header says "Same F_order rule as disco; ...
##    only the step interval differs (set in map config)". So SLOW and DISCO are ONE rule
##    at two tempos, the tempo is not in the enum at all (it arrives from the map), and
##    in code the two values differ by SAT 0.4 against 0.7 and VAL 0.7 against 0.95.
##    A palette and a clock, declared as two algorithms.
##
## 3. RANDOM IS NOT AN ALGORITHM AND THE FILE SAYS SO. cartridge_random.gd is
##    `grid[i] = randi() % 8` for every cell every step, and its own header calls it
##    "the 'antithesis' cartridge — same hardware, no memory". It is the absence of a
##    rule, sitting in the list of rules. It is also unseeded, so it cannot be
##    photographed twice.
##
## 4. AND THAT LAST POINT GENERALISES, WHICH IS WHY THIS BENCH HAD TO REBUILD RATHER THAN
##    PHOTOGRAPH. cartridge_game_of_life seeds with bare `randf()`, cartridge_bfs lays its
##    walls with bare `randf()`, cartridge_dfs_maze picks its neighbour with bare
##    `randi()`, cartridge_logistic_map draws `randf_range(0.1, 0.9)`, cartridge_bell_curve
##    draws six `randf()` per sample. NOT ONE of the three members declares a seed
##    anywhere, and all three step under `_process` on a `step_interval` clock. Most
##    values of this axis are a different picture on every boot AND at every shutter.
##
## 5. A THIRTEENTH VALUE EXISTS AND NO TOOL IN THE CHAIN CAN SEE IT. grid2d's enum has
##    THIRTEEN members; DISCO is the tenth line and has a cartridge, a factory branch and
##    a key in both alias tables. The registry declares twelve. `check_dna_declarations`
##    reports `grid2d.algorithm ok` — because it reads an enum body by splitting on
##    commas, and the comment line above DISCO contains one ("same array, three cadences"),
##    so DISCO is swallowed into an unparseable token and dropped. The deriving tool and
##    the checking tool are the same parser, so they agree with each other and disagree
##    with the code. Reproduced: `code_values()` returns 12 names, and `'DISCO' in src`
##    is true.
##
## WHAT THIS BENCH DOES. ONE substrate — a 33 x 33 relief of 1089 cells on a 0.96 m
## panel — and eight of the family's thirty-six values rebuilt on it, deterministically,
## with no clock anywhere. The second axis, `kind`, is the axis the family should have
## had: it names WHAT THE GRID'S TWO DIRECTIONS MEAN, which is the only thing that makes
## two values comparable at all.
##
##   automaton  a local rule iterated. i = cell, j = generation. The panel is a spacetime
##              diagram: row 0 is the initial condition, row j is the j-th step.
##   search     a traversal of a graph. i, j = space, and the grid's own 4-neighbour
##              adjacency IS the graph. Band and relief carry the quantity the traversal
##              orders by, normalised to its own maximum.
##   signal     a function of one variable sampled. i = the variable, j = the value,
##              quantised to 33 levels and filled from the baseline up to the crest.
##
## EVERY VALUE OF `algorithm` BELONGS TO EXACTLY ONE `kind`, so the second axis PARTITIONS
## the first rather than crossing it. The 8 x 3 product has 8 defined cells and 16
## undefined ones, and the emptiness is DRAWN rather than hidden: a foreign cell renders
## the KIND'S BARE SUBSTRATE — the spacetime panel with its initial row and no rule, the
## graph with its source and nobody having walked it, the two axes with no function on
## them. All five foreign cells in the automaton column are therefore one image, all five
## in search are one image, all six in signal are one image. Registered as designed nulls.
##
## THE CENSUS, from a Python replica of this file run before any capture. Lit cells out
## of 1089: RULE30 437, RULE110 350, RULE90 245, each of the three searches 1083,
## SINE_WAVE 561, LOGISTIC_MAP 699.
##
## Deterministic: one RandomNumberGenerator per stage, all seeded off RNG_SEED 20260816.
## THERE IS NO FAMILY SEED TO INHERIT — none of the three members has one, which is
## itself the finding, so this constant is this bench's own and is declared as such. No
## randf outside a seeded generator, no noise, no _process, no Timer, no tween. Two builds
## of one cell are the same mesh.


## WHICH OF THE FAMILY'S THIRTY-SIX IS BUILT. Eight, spanning all three members and all
## three kinds. THE SPELLINGS ARE THE MEMBERS' OWN, character for character, SHOUTY_CASE
## included — they are typed-enum member names in the sources and quoted strings here,
## which is a deliberate difference explained in `declines`.
##
##   RULE30       grid2d. Wolfram elementary rule 30 from a single centre cell, wrapped,
##                33 generations. A full symmetric triangle, dense: 437 of 1089 lit,
##                214 left of centre against 205 right.
##   RULE110      grid2d. Rule 110, same initial cell. GROWS LEFT ONLY — 228 lit in the
##                left half against 89 in the right — so its envelope is a half triangle
##                where 30's and 90's are full ones. 350 lit.
##   RULE90       grid2d. Rule 90, the XOR rule: the Sierpinski gasket. Symmetric like 30
##                (122 left, 122 right) and sparse where 30 is dense. 245 lit.
##                THESE THREE ARE ONE CARTRIDGE AT THREE VALUES OF `rule_number: int`.
##   BFS_FLOOD    grid2d. Breadth-first flood from the centre over the grid's 4-neighbour
##                graph, at the cartridge's own 25 percent wall density with its own 5x5
##                clearing around the source. The ordering quantity is HOP COUNT.
##   DFS_MAZE     grid2d. Depth-first traversal of the SAME graph, neighbour drawn from a
##                seeded generator. The ordering quantity is DISCOVERY INDEX, because
##                depth-first has no metric to minimise — see `declines` for why this is
##                drawn as the order and not as the maze the cartridge carves.
##   DIJKSTRA     grid3d. Shortest path over the SAME graph with a weight in [0.5, 1.5] on
##                every edge. The ordering quantity is WEIGHTED DISTANCE. SET EVERY WEIGHT
##                TO 1.0 AND THIS VALUE IS BFS_FLOOD. That is the pre-registered closest
##                pair, and it is a pair drawn from two different members' menus.
##   SINE_WAVE    profile. sin(2 tau x) at the cartridge's own `_frequency = 2.0`, with
##                its `delta_time * _phase_speed` term pinned at zero. Sweeps all 33
##                levels twice; the crest touches level 0 and level 32.
##   LOGISTIC_MAP profile. r swept 2.5 to 4.0 across the panel, 200 draws per column, 100
##                settling iterations each, running-averaged exactly as the cartridge
##                averages. THE BIFURCATION CARTRIDGE DRAWS NO BIFURCATION: averaging an
##                attractor collapses it to its mean, so the curve spans 0.5195 to 0.6757
##                of its own declared [0, 1] y-range — six of thirty-three levels — and
##                reads as a nearly flat line. The cartridge's own comment inside step()
##                notices the substitution and does it anyway.
##
## THE NEXT LINE IS OVER-LONG ON PURPOSE AND MUST NOT BE WRAPPED. check_dna_declarations
## detects an export with `@export[^\n]*\bvar\s+<axis>\b` — no newline permitted between
## the annotation and the `var` — while code_values() reads the value list with
## `@export_enum\(([^)]*)\)`, whose character class DOES match newlines. So a wrapped
## declaration derives eight correct values and is then reported NO_EXPORT by the same
## tool. Measured here, on this line, in this pass: wrapped gave `algorithm_menu.algorithm
## NO EXPORT — declared [eight values] but there is no such export`, printing the eight
## values it had just read. export_default() carries the same restriction, so a wrapped
## default is read as None as well. Second harness finding of the pass; see `declines`.
@export_enum("RULE30", "RULE110", "RULE90", "BFS_FLOOD", "DFS_MAZE", "DIJKSTRA", "SINE_WAVE", "LOGISTIC_MAP") var algorithm: String = "RULE30":
	set(v):
		var picked: String = _pick(str(v), ALGORITHMS, "")
		if picked == "":
			return                      ## an unreachable value keeps the standing figure
		algorithm = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## WHAT KIND OF THING THE ALGORITHM IS — the axis the family should have had, and the
## only one of the two on which two values are commensurable. Three values, and every
## value of `algorithm` belongs to exactly one of them, so THIS AXIS IS A PARTITION OF THE
## OTHER rather than a second free dimension. The cross product is therefore mostly empty,
## and that is the finding rather than a defect in the sheet.
##
##   automaton  a local rule iterated. Six of grid2d's twelve values are this kind.
##   search     a traversal of a graph. Two of grid2d's, and six of grid3d's eight.
##   signal     a function of one variable sampled. All sixteen of profile's.
##
## THAT COUNT IS THE ARGUMENT IN ONE LINE. The three members are not three widgets that
## happen to share a word; they are three widgets each of which is ALMOST ENTIRELY ONE
## KIND. profile is sixteen signals and nothing else. grid3d is six searches, one graph
## generator and one field. grid2d is the only mixed one, and its mixture is six automata,
## two searches and four things that are not algorithms at all. A `kind` axis would have
## had three values and made the family comparable; `algorithm` has thirty-six and makes
## it a switch statement.
@export_enum("automaton", "search", "signal") var kind: String = "automaton":
	set(v):
		var picked: String = _pick(str(v), KINDS, "")
		if picked == "":
			return
		kind = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One cell, or the eight native cells in a row. NOT PART OF EITHER AXIS, and this is the
## lesson that has cost the programme a sweep more than once: capture_config_sweep unions
## the AABB across a spec's variants, so an all-values entry declared inside `algorithm`
## would frame every single cell against nearly eight metres and photograph 0.019 m cells
## as dust. The registry fixture pins `single`; `ladder` is a design view.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = _pick(str(v), LAYOUTS, "")
		if picked == "":
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const ALGORITHMS: PackedStringArray = ["RULE30", "RULE110", "RULE90", "BFS_FLOOD",
	"DFS_MAZE", "DIJKSTRA", "SINE_WAVE", "LOGISTIC_MAP"]
const KINDS: PackedStringArray = ["automaton", "search", "signal"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

## The partition, written once. `_is_native()` reads this and nothing else does, which is
## the only place in the file where the two axes touch.
const KIND_OF: Dictionary = {
	"RULE30": "automaton", "RULE110": "automaton", "RULE90": "automaton",
	"BFS_FLOOD": "search", "DFS_MAZE": "search", "DIJKSTRA": "search",
	"SINE_WAVE": "signal", "LOGISTIC_MAP": "signal",
}
## The three that are one cartridge, mapped to the parameter grid2d's menu spent three
## entries on — and which ca_bridge declares, correctly, as an axis called `rule`.
const RULE_OF: Dictionary = {"RULE30": 30, "RULE110": 110, "RULE90": 90}

## THIS BENCH'S OWN SEED, and it is its own because there is nothing to inherit.
## cohort_bench could take 20260730 from its family because all three of ITS members had
## independently written that constant down. All three of these members draw from the
## global generator with bare randf()/randi() and none declares a seed anywhere. Stated
## rather than hidden, because a seed nobody shares is a fact about the family.
const RNG_SEED: int = 20260816

# ── the stage, identical to the millimetre in all twenty-four cells ────────────────────
## THE FIELD STANDS VERTICAL AND THAT IS A MEASUREMENT, NOT A STYLE. The sweep's canonical
## standpoint is yaw 0.62, pitch -0.26 — an elevation of 14.90 degrees. On a HORIZONTAL
## field at this pitch a 0.09 m post hides 0.338 m of grid behind it, which is 13.3 cells,
## so eleven of every twelve rows would be a photograph of the front row's backs. On a
## VERTICAL panel the same relief hides 0.024 m sideways — 0.95 of one cell — and the
## panel face fills 82.1 percent of the subject box instead of 29.8 percent. Both numbers
## were computed before the geometry was written, from the capturer's own constants.
##
## THE FOUR CORNER STUDS STAND EXACTLY AS PROUD AS THE DEEPEST CELL, so the world box is
## 0.96 x 0.96 x 0.058 before a single cell is computed. Without them the depth of the box
## would be a fact about which kind was picked — a bare signal cell reaches only D_BODY
## 0.018 — the camera would move between cells, and every measured pair would carry a
## framing difference it did not earn.
const PANEL_HALF: float = 0.48
const PANEL_T: float = 0.024
const FIELD_HALF: float = 0.42
const CORNER_W: float = 0.030
const CORNER_INSET: float = 0.465

# ── the grid ───────────────────────────────────────────────────────────────────────────
## 33 is ODD on purpose: an elementary automaton's initial condition is a single cell at
## the exact centre, and an even width has no exact centre. 33 columns also give the
## 16 maze cells at odd coordinates that cartridge_dfs_maze computes as (width - 1) / 2.
const COLS: int = 33
const ROWS: int = 33
const CELL_W: float = 0.019            ## 75 percent of the 0.02545 m pitch

# ── the value channels ─────────────────────────────────────────────────────────────────
## VALUE IS CARRIED BY RELIEF AND BY ALBEDO AT ONCE, never by hue alone: the critic
## measures luminance by default and has a separate colour rescue, so a pair separated
## only by hue at constant brightness reads as a twin in greyscale. D_MAX is capped at
## 0.034 for the occlusion reason above: 0.034 * 0.7138 = 0.024 m of sideways shadow,
## just under one cell pitch, so the relief reads as relief and never as a hole.
const D_OFF: float = 0.004             ## a cell with nothing in it
const D_LO: float = 0.008              ## the shallow end of the search ramp
const D_BODY: float = 0.018            ## a signal's fill, below its crest
const D_MAX: float = 0.034             ## lit / crest / wall / corner stud

# ── colour: the ladder, written down so the greyscale reading is checkable ─────────────
## Rec.709 luminance of each: panel 0.180, off 0.292, corner 0.411, then the value ramp at
## 0.525, 0.643, 0.757, 0.876. NO TWO STEPS ARE CLOSER THAN 0.112, and the ramp also
## carries a hue arc (cool to warm) so the colour rescue and the luminance reading agree
## rather than compete. A WALL IN THE SEARCH KIND IS DRAWN IN C_PANEL at full relief —
## deliberately no new grey, because a wall is the substrate standing up, and a proud dark
## block against a bright flood cannot be confused with the flat panel it matches.
const C_PANEL: Color = Color(0.17, 0.18, 0.21)
const C_OFF: Color = Color(0.28, 0.29, 0.34)
const C_CORNER: Color = Color(0.40, 0.41, 0.45)
const C_R0: Color = Color(0.36, 0.56, 0.66)
const C_R1: Color = Color(0.52, 0.67, 0.74)
const C_R2: Color = Color(0.80, 0.76, 0.60)
const C_R3: Color = Color(0.97, 0.87, 0.66)

const MAT_OFF: int = 0
const MAT_R0: int = 1
const MAT_R1: int = 2
const MAT_R2: int = 3
const MAT_R3: int = 4
const MAT_WALL: int = 5
const MAT_COUNT: int = 6

# ── the members' own numbers ───────────────────────────────────────────────────────────
const WALL_DENSITY: float = 0.25       ## cartridge_bfs.gd: `randf() < 0.25`
const SOURCE_CLEAR: int = 2            ## cartridge_bfs.gd: `for dy in range(-2, 3)`
const WEIGHT_LO: float = 0.5
const WEIGHT_HI: float = 1.5
const SINE_FREQ: float = 2.0           ## cartridge_sine_wave.gd: `_frequency = 2.0`
const LOGI_ITERS: int = 200            ## cartridge_logistic_map.gd: `_max_iterations`
const LOGI_SETTLE: int = 100           ## cartridge_logistic_map.gd: `_settle`
const LOGI_R_LO: float = 2.5
const LOGI_R_HI: float = 4.0
const BANDS: int = 4

const LADDER_PITCH: float = 1.10
## Iterated rather than written inline, so no loop variable is left untyped.
const SIGNS: PackedFloat32Array = [-1.0, 1.0]

var _built: Array[Node3D] = []
## Set while a whole config dictionary lands, so three keys cost one rebuild, not three.
var _bulk: bool = false


func _ready() -> void:
	_rebuild()


## EVERY DECLARED VALUE IS REACHABLE FROM A MAP TOKEN, AND THAT IS A REPAIR. All three
## members lowercase the incoming string and look it up in a HAND-KEPT alias table whose
## keys are not the enum member names, so 17 of the family's 36 declared values cannot be
## set from a map at all: grid2d loses BFS_FLOOD and WIRE_WORLD, grid3d loses KRUSKAL_MST,
## PRIM_MST and ENTROPY_FIELD, and profile loses TWELVE of its sixteen — every value whose
## enum name carries a suffix the alias table dropped (SINE_WAVE against the key "sine",
## LOGISTIC_MAP against "logistic"). grid2d push_warnings about it; grid3d and profile
## fall through in silence to their default. Here the value is upper-cased and matched
## against the DECLARED LIST ITSELF, so the list and the door cannot drift apart.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("kind"):
		kind = str(config_data["kind"])
	if config_data.has("algorithm"):
		algorithm = str(config_data["algorithm"])
	_bulk = false
	_rebuild()


## Match against the declared list after upper-casing, so "rule30" and "RULE30" are the
## same door and "rule31" is no door. Returns "" for a value the artifact cannot reach,
## which every setter reads as "keep the standing figure".
func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var up: String = value.strip_edges().to_upper()
	for i in range(allowed.size()):
		if allowed[i].to_upper() == up:
			return allowed[i]
	return fallback


func _is_native(algo: String, which_kind: String) -> bool:
	return str(KIND_OF.get(algo, "")) == which_kind


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var algos: PackedStringArray = PackedStringArray()
	var kinds: PackedStringArray = PackedStringArray()
	if layout == "ladder":
		for i in range(ALGORITHMS.size()):
			algos.append(ALGORITHMS[i])
			kinds.append(str(KIND_OF[ALGORITHMS[i]]))
	else:
		algos.append(_pick(algorithm, ALGORITHMS, "RULE30"))
		kinds.append(_pick(kind, KINDS, "automaton"))
	var count: int = algos.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Cell_" + algos[i] + "_" + kinds[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_stage(holder)
		_build_field(holder, algos[i], kinds[i])


# ── the field: one (material, relief) pair per cell ────────────────────────────────────

## THE ONE PLACE THE TWO AXES MEET. A native cell runs its algorithm; a foreign cell
## renders the kind's bare substrate and the algorithm is never consulted. That is the
## most defensible reading of an undefined cell — it makes the emptiness visible instead
## of inventing a picture for it — and it is why a whole column of foreign cells is one
## image, which is registered as a designed null rather than discovered afterwards.
func _build_field(holder: Node3D, algo: String, which_kind: String) -> void:
	var native: bool = _is_native(algo, which_kind)
	var mats: PackedInt32Array = PackedInt32Array()
	var ds: PackedFloat32Array = PackedFloat32Array()
	mats.resize(COLS * ROWS)
	ds.resize(COLS * ROWS)
	mats.fill(MAT_OFF)
	ds.fill(D_OFF)
	match which_kind:
		"search":
			_search_field(mats, ds, algo if native else "")
		"signal":
			_signal_field(mats, ds, algo if native else "")
		_:
			_automaton_field(mats, ds, int(RULE_OF.get(algo, -1)) if native else -1)
	_draw_cells(holder, mats, ds)


## automaton — i is the cell, j is the generation, row 0 is the initial condition and sits
## at the top of the panel. A rule number below zero means BARE: the initial row and
## nothing under it. That the initial row belongs to the KIND and not to any value is not
## a convenience — the three elementary rules ARE one cartridge and therefore share ONE
## `initialize()`, whose whole body is `grid[width / 2] = 1`.
func _automaton_field(mats: PackedInt32Array, ds: PackedFloat32Array, rule: int) -> void:
	var mid: int = int(float(COLS) * 0.5)
	var prev: PackedInt32Array = PackedInt32Array()
	prev.resize(COLS)
	prev.fill(0)
	prev[mid] = 1
	_write_states(mats, ds, 0, prev)
	if rule < 0:
		return
	for j in range(1, ROWS):
		var nxt: PackedInt32Array = PackedInt32Array()
		nxt.resize(COLS)
		for x in range(COLS):
			# Toroidal wrap, exactly as cartridge_rule_1d.gd wraps it.
			var left: int = prev[(x - 1 + COLS) % COLS]
			var centre: int = prev[x]
			var right: int = prev[(x + 1) % COLS]
			var neighbourhood: int = (left << 2) | (centre << 1) | right
			nxt[x] = (rule >> neighbourhood) & 1
		_write_states(mats, ds, j, nxt)
		prev = nxt


func _write_states(mats: PackedInt32Array, ds: PackedFloat32Array, j: int,
		row: PackedInt32Array) -> void:
	for x in range(COLS):
		var at: int = j * COLS + x
		if row[x] == 1:
			mats[at] = MAT_R3
			ds[at] = D_MAX
		else:
			mats[at] = MAT_OFF
			ds[at] = D_OFF


# ── the graph, shared by all three searches ────────────────────────────────────────────

## cartridge_bfs.gd's own construction, seeded: 25 percent walls, the source at the
## centre, the 5x5 block around the source cleared. THE GRAPH BELONGS TO THE KIND — all
## three searches walk the same one, which is what makes them comparable at all and what
## makes the bare search cell a picture of something rather than of nothing. Replica:
## 260 of 1089 cells are walls and 823 of the 829 open cells are reachable.
func _walls() -> PackedByteArray:
	var wall: PackedByteArray = PackedByteArray()
	wall.resize(COLS * ROWS)
	var rng := RandomNumberGenerator.new()
	rng.seed = RNG_SEED
	for at in range(COLS * ROWS):
		wall[at] = 1 if rng.randf() < WALL_DENSITY else 0
	var mid: int = int(float(COLS) * 0.5)
	for dj in range(-SOURCE_CLEAR, SOURCE_CLEAR + 1):
		for di in range(-SOURCE_CLEAR, SOURCE_CLEAR + 1):
			wall[(mid + dj) * COLS + (mid + di)] = 0
	return wall


## One weight per UNDIRECTED edge, drawn in a fixed order so two builds agree. Slot
## 2 * at + 0 is the edge to the east of cell `at`, slot + 1 the edge to the south.
func _weights() -> PackedFloat32Array:
	var w: PackedFloat32Array = PackedFloat32Array()
	w.resize(COLS * ROWS * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = RNG_SEED + 7717
	for i in range(w.size()):
		w[i] = rng.randf_range(WEIGHT_LO, WEIGHT_HI)
	return w


func _edge_weight(w: PackedFloat32Array, a: int, b: int) -> float:
	var lo: int = mini(a, b)
	var hi: int = maxi(a, b)
	if hi - lo == 1:
		return w[lo * 2]
	return w[lo * 2 + 1]


func _neighbours(at: int, wall: PackedByteArray) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	# float division then truncate, so no integer-division warning is emitted per call
	var j: int = int(float(at) / float(COLS))
	var i: int = at - j * COLS
	if i > 0 and wall[at - 1] == 0:
		out.append(at - 1)
	if i < COLS - 1 and wall[at + 1] == 0:
		out.append(at + 1)
	if j > 0 and wall[at - COLS] == 0:
		out.append(at - COLS)
	if j < ROWS - 1 and wall[at + COLS] == 0:
		out.append(at + COLS)
	return out


## search — i and j are space, and the value drawn is THE QUANTITY THE TRAVERSAL ORDERS
## BY, normalised to its own maximum and quantised into four bands. The bands are the
## body: they are iso-contours, and the difference between BFS's diamond contours and
## Dijkstra's wobbled ones is the whole comparison. An empty `algo` means BARE.
func _search_field(mats: PackedInt32Array, ds: PackedFloat32Array, algo: String) -> void:
	var wall: PackedByteArray = _walls()
	var mid: int = int(float(COLS) * 0.5)
	var src: int = mid * COLS + mid
	for at in range(COLS * ROWS):
		if wall[at] == 1:
			mats[at] = MAT_WALL
			ds[at] = D_MAX
	if algo == "":
		mats[src] = MAT_R0
		ds[src] = D_LO
		return
	var field: PackedFloat32Array = PackedFloat32Array()
	match algo:
		"DIJKSTRA":
			field = _dijkstra(wall, src)
		"DFS_MAZE":
			field = _dfs_order(wall, src)
		_:
			field = _bfs_depth(wall, src)
	var top: float = 0.0
	for at in range(field.size()):
		top = maxf(top, field[at])
	if top <= 0.0:
		top = 1.0
	for at in range(COLS * ROWS):
		if wall[at] == 1 or field[at] < 0.0:
			continue
		var v: float = clampf(field[at] / top, 0.0, 1.0)
		mats[at] = MAT_R0 + clampi(int(v * float(BANDS)), 0, BANDS - 1)
		ds[at] = D_LO + v * (D_MAX - D_LO)


## BFS_FLOOD — grid2d. Hop count: the quantity breadth-first minimises.
func _bfs_depth(wall: PackedByteArray, src: int) -> PackedFloat32Array:
	var d: PackedFloat32Array = PackedFloat32Array()
	d.resize(COLS * ROWS)
	d.fill(-1.0)
	d[src] = 0.0
	var frontier: PackedInt32Array = PackedInt32Array([src])
	while not frontier.is_empty():
		var nxt: PackedInt32Array = PackedInt32Array()
		for k in range(frontier.size()):
			var u: int = frontier[k]
			var ns: PackedInt32Array = _neighbours(u, wall)
			for m in range(ns.size()):
				var v: int = ns[m]
				if d[v] < 0.0:
					d[v] = d[u] + 1.0
					nxt.append(v)
		frontier = nxt
	return d


## DIJKSTRA — grid3d. Weighted distance, settled greedily. O(V^2) rather than a heap:
## 823 settles against 1089 candidates is under a million comparisons, it runs inside
## _ready in well under a frame, and a hand-rolled binary heap is a bug surface for no
## gain. Replica: max distance 44.202 against BFS's max depth of 43.
func _dijkstra(wall: PackedByteArray, src: int) -> PackedFloat32Array:
	var w: PackedFloat32Array = _weights()
	var n: int = COLS * ROWS
	var dist: PackedFloat32Array = PackedFloat32Array()
	var settled: PackedByteArray = PackedByteArray()
	dist.resize(n)
	settled.resize(n)
	dist.fill(-1.0)
	settled.fill(0)
	dist[src] = 0.0
	while true:
		var u: int = -1
		var best: float = -1.0
		for at in range(n):
			if settled[at] == 1 or dist[at] < 0.0:
				continue
			if u < 0 or dist[at] < best:
				best = dist[at]
				u = at
		if u < 0:
			break
		settled[u] = 1
		var ns: PackedInt32Array = _neighbours(u, wall)
		for m in range(ns.size()):
			var v: int = ns[m]
			if settled[v] == 1:
				continue
			var alt: float = dist[u] + _edge_weight(w, u, v)
			if dist[v] < 0.0 or alt < dist[v]:
				dist[v] = alt
	return dist


## DFS_MAZE — grid2d. Discovery index, because DEPTH-FIRST HAS NO METRIC TO MINIMISE.
## That is not a shortcoming of this rendering, it is the difference between this value
## and the other two, and it is why `search` is a kind and not a metric: two of its three
## members compute a distance and the third computes an order.
func _dfs_order(wall: PackedByteArray, src: int) -> PackedFloat32Array:
	var order: PackedFloat32Array = PackedFloat32Array()
	order.resize(COLS * ROWS)
	order.fill(-1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = RNG_SEED + 4242
	var stack: PackedInt32Array = PackedInt32Array([src])
	order[src] = 0.0
	var seen: int = 1
	while not stack.is_empty():
		var u: int = stack[stack.size() - 1]
		var ns: PackedInt32Array = _neighbours(u, wall)
		var open_ns: PackedInt32Array = PackedInt32Array()
		for m in range(ns.size()):
			if order[ns[m]] < 0.0:
				open_ns.append(ns[m])
		if open_ns.is_empty():
			stack.remove_at(stack.size() - 1)
			continue
		var v: int = open_ns[rng.randi() % open_ns.size()]
		order[v] = float(seen)
		seen += 1
		stack.append(v)
	return order


# ── the signals ────────────────────────────────────────────────────────────────────────

## signal — i is the variable, j is the value. Level 0 sits at the bottom of the panel and
## level 32 at the top, so the curve reads as a plotted profile. Cells below the crest
## carry the body at D_BODY; the crest itself stands at D_MAX. An empty `algo` means BARE:
## the two axes — the baseline at the middle level and the value axis at column 0 — with
## no function on them.
func _signal_field(mats: PackedInt32Array, ds: PackedFloat32Array, algo: String) -> void:
	if algo == "":
		var midlevel: int = int(float(ROWS - 1) * 0.5)
		for i in range(COLS):
			var at: int = _row_of_level(midlevel) * COLS + i
			mats[at] = MAT_R1
			ds[at] = D_BODY
		for j in range(ROWS):
			var at2: int = j * COLS
			mats[at2] = MAT_R1
			ds[at2] = D_BODY
		return
	var levels: PackedInt32Array = _logistic_levels() if algo == "LOGISTIC_MAP" \
		else _sine_levels()
	for i in range(COLS):
		var crest: int = clampi(levels[i], 0, ROWS - 1)
		for level in range(crest + 1):
			var at3: int = _row_of_level(level) * COLS + i
			if level == crest:
				mats[at3] = MAT_R3
				ds[at3] = D_MAX
			else:
				mats[at3] = MAT_R1
				ds[at3] = D_BODY


func _row_of_level(level: int) -> int:
	return ROWS - 1 - clampi(level, 0, ROWS - 1)


## SINE_WAVE — profile. The cartridge's own frequency, and its `delta_time * _phase_speed`
## term pinned at zero. THAT PIN IS NOT A SIMPLIFICATION, IT IS THE REASON THE VALUE CAN
## BE PHOTOGRAPHED AT ALL: in the member the phase is a function of elapsed clock, so a
## still of the shipped cartridge is a fact about the shutter and not about the algorithm.
func _sine_levels() -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(COLS)
	for i in range(COLS):
		var t: float = float(i) / float(COLS - 1)
		var v: float = sin(t * TAU * SINE_FREQ)
		out[i] = int(round((v + 1.0) * 0.5 * float(ROWS - 1)))
	return out


## LOGISTIC_MAP — profile, and the arithmetic is the cartridge's own rather than a repair
## of it. 200 draws per column, 100 settling iterations each, combined by the same running
## mean `buf = lerpf(buf, x, 1 / k)`. AVERAGING AN ATTRACTOR COLLAPSES IT: past r = 3 the
## orbit is a 2-cycle whose mean is (r + 1) / 2r, a smooth curve, so the bifurcation never
## appears. Replica: the 33 columns span 0.5195 to 0.6757, which is 0.156 of the declared
## [0, 1] y-range and six of thirty-three levels. The cartridge's own comment inside step()
## says a bifurcation diagram "should show the last N values" and then averages anyway.
func _logistic_levels() -> PackedInt32Array:
	var buf: PackedFloat32Array = PackedFloat32Array()
	buf.resize(COLS)
	buf.fill(0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = RNG_SEED + 991
	for k in range(1, LOGI_ITERS + 1):
		for i in range(COLS):
			var r: float = lerpf(LOGI_R_LO, LOGI_R_HI, float(i) / float(COLS - 1))
			var x: float = rng.randf_range(0.1, 0.9)
			for s in range(LOGI_SETTLE):
				x = r * x * (1.0 - x)
			buf[i] = lerpf(buf[i], x, 1.0 / float(k))
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(COLS)
	for i in range(COLS):
		out[i] = int(round(clampf(buf[i], 0.0, 1.0) * float(ROWS - 1)))
	return out


# ── drawing ────────────────────────────────────────────────────────────────────────────

func _build_stage(holder: Node3D) -> void:
	var panel := SurfaceTool.new()
	panel.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(panel, Vector3(0.0, PANEL_HALF, -PANEL_T * 0.5),
		Vector3(PANEL_HALF * 2.0, PANEL_HALF * 2.0, PANEL_T))
	_commit(holder, "Panel", panel, C_PANEL, 0.95)

	var studs := SurfaceTool.new()
	studs.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sx in SIGNS:
		for sy in SIGNS:
			_add_box(studs,
				Vector3(sx * CORNER_INSET, PANEL_HALF + sy * CORNER_INSET, D_MAX * 0.5),
				Vector3(CORNER_W, CORNER_W, D_MAX))
	_commit(holder, "CornerStuds", studs, C_CORNER, 0.80)


## One SurfaceTool per material, so 1089 cells become at most six meshes and the number of
## draw calls does not depend on which value is standing.
func _draw_cells(holder: Node3D, mats: PackedInt32Array,
		ds: PackedFloat32Array) -> void:
	var tools: Array[SurfaceTool] = []
	var used: PackedByteArray = PackedByteArray()
	used.resize(MAT_COUNT)
	used.fill(0)
	for m in range(MAT_COUNT):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		tools.append(st)
	var pitch: float = FIELD_HALF * 2.0 / float(COLS)
	for j in range(ROWS):
		for i in range(COLS):
			var at: int = j * COLS + i
			var m2: int = clampi(mats[at], 0, MAT_COUNT - 1)
			var d: float = ds[at]
			var px: float = -FIELD_HALF + (float(i) + 0.5) * pitch
			var py: float = FIELD_HALF - (float(j) + 0.5) * pitch
			_add_box(tools[m2], Vector3(px, PANEL_HALF + py, d * 0.5),
				Vector3(CELL_W, CELL_W, d))
			used[m2] = 1
	var names: PackedStringArray = ["Off", "Band0", "Band1", "Band2", "Band3", "Wall"]
	var cols: Array[Color] = [C_OFF, C_R0, C_R1, C_R2, C_R3, C_PANEL]
	for m3 in range(MAT_COUNT):
		if used[m3] == 1:
			_commit(holder, names[m3], tools[m3], cols[m3], 0.65)


## An axis-aligned box, twelve triangles, wound outward with explicit per-face normals.
func _add_box(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var p: PackedVector3Array = PackedVector3Array([
		at + Vector3(-h.x, -h.y, h.z), at + Vector3(h.x, -h.y, h.z),
		at + Vector3(h.x, h.y, h.z), at + Vector3(-h.x, h.y, h.z),
		at + Vector3(-h.x, -h.y, -h.z), at + Vector3(h.x, -h.y, -h.z),
		at + Vector3(h.x, h.y, -h.z), at + Vector3(-h.x, h.y, -h.z)])
	_quad(st, p[0], p[1], p[2], p[3], at)
	_quad(st, p[5], p[4], p[7], p[6], at)
	_quad(st, p[3], p[2], p[6], p[7], at)
	_quad(st, p[4], p[5], p[1], p[0], at)
	_quad(st, p[1], p[5], p[6], p[2], at)
	_quad(st, p[4], p[0], p[3], p[7], at)


## Two triangles a -> b -> c -> d, with the normal taken from the winding and FLIPPED if
## it points back at `inside`. Every material here is CULL_DISABLED as well, so a quad
## that happened to wind inward is still drawn rather than becoming a hole.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		inside: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	var mid: Vector3 = (a + b + c + d) * 0.25
	if n.dot(mid - inside) < 0.0:
		n = -n
	var tri: PackedVector3Array = PackedVector3Array([a, b, c, a, c, d])
	for vtx in tri:
		st.set_normal(n)
		st.add_vertex(vtx)


## SurfaceTool.commit() on a tool that was begun and never given a vertex is not a mesh
## with no surfaces, it is an error in the log.
func _commit(holder: Node3D, mesh_name: String, st: SurfaceTool, c: Color,
		rough: float) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = m
	holder.add_child(mi)
