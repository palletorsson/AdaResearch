extends Node3D
class_name HandBench

## hand_bench — one bed, six hands, three readings. The corpus has quietly put two
## unrelated things under the word `hand`, and this bench puts them on the same
## 0.90 m slab so the difference in KIND is a fact about a photograph.
##
## THE FAMILY. Four registry names carry an axis called `hand`, and they are three
## vocabularies, not four:
##
##   mc_sculpt_vr            stack | sweep | dab | heap
##   marching_cubes_sculpt_vr   THE SAME FOUR — and the same scene, character for
##                           character: both entries name
##                           res://algorithms/proceduralgeneration/isosurfaces/
##                           marchingcave/Scenes/MarchingCubesSculptVR.tscn. ONE
##                           object under two names. (mc_sculpt_vr's own registry
##                           `kin` field already says so and names it a hidden
##                           family; the mirror has since been applied, so both
##                           entries now declare `hand`. Nothing new was found
##                           here — it was CONFIRMED, which is the weaker and
##                           truer claim.)
##   sculpt_one              composition | pour | drape | stipple | spatter
##   maze_generation         backtracker | prim | binary_tree | sidewinder | labyrinth
##
## THE ARGUMENT, sharpened against the code rather than against the words.
##
## The brief said: the sculpt words are gestures of a hand — they differ in how much
## material lands per unit time and how it is spread — and maze_generation's are
## algorithm names, which are not gestures at all. Half of that survives contact
## with the source and half does not.
##
##   WHAT SURVIVES. maze_generation's five ARE procedures. _carve_prim builds a
##   frontier edge list and pops a uniformly random member; _carve_binary_tree
##   tosses north-or-east at every cell; _carve_sidewinder runs east and rises once
##   per run; _carve_labyrinth walks a boustrophedon snake and rolls no dice at all.
##   Nothing in any of them has a rate, a radius or a falloff. There is no knob you
##   could turn a little.
##
##   WHAT DOES NOT. The sculpt words are not rates either. mc_sculpt_vr's own header
##   is explicit: "All four rungs use THE SAME SEVEN DEPOSITS ... Nothing about the
##   amount of material, the threshold or the sampling changes between them. Only
##   the arrangement." maze_generator_vr says the same thing about itself: "All five
##   leave exactly the same number of standing wall blocks ... Nothing about the
##   amount of maze changes. What changes is the TEXTURE." Two of the three members
##   independently hold the AMOUNT fixed and vary only the ARRANGEMENT. So the axis
##   is not gesture-versus-algorithm on the amount axis; both halves already agreed
##   to conserve material, and this bench conserves it too (see VOL_TOTAL).
##
##   WHERE THEY ACTUALLY PART. In the PASS. A gesture has a trajectory: a curve some
##   body moved along, and the material landed as it went. An algorithm has a
##   decision order: a sequence a data structure produced, and the line between
##   consecutive decisions was never traversed by anything. Draw both as a tube and
##   the difference is visible. That is `reading = pass`, and it is the reason this
##   bench has a second axis at all.
##
##   AND THE SPLIT IS THREE WAYS, NOT TWO, which is where the brief is overruled.
##   Of the four sculpt words built here only `stack` and `sweep` have a continuous
##   hand path; `stipple` and `spatter` are sequences of separate touches with the
##   hand lifted in between, so their pass is a plan, not a stroke. And one of the
##   two algorithms — `labyrinth` — has a decision order that IS a walkable route,
##   because a unicursal labyrinth is a path and carving it means following it. So
##   the vocabulary that is supposed to be all gesture contains two non-gestures,
##   and the vocabulary that is supposed to be all procedure contains one route.
##
## Deterministic: no _process, no Timer, no randf. One seeded RandomNumberGenerator,
## consumed by `spatter` and `prim` only; `stipple` and `labyrinth` roll nothing, and
## `stack` and `sweep` are closed-form.


## WHOSE HAND, AND WHOSE VOCABULARY. Six values, one from each of the three real
## vocabularies at minimum, two from each in practice. Every value deposits the SAME
## NOMINAL VOLUME — 9.634 litres — and differs only in how that volume is divided
## and where it is put.
##
##   stack      mc_sculpt_vr. 8 grains of radius 0.066, all at one point in plan,
##              pitch 0.036 up the y axis: a fused column 0.132 wide and 0.408 tall.
##              Spread 0. mc's own stack is "one lump, taller than wide".
##   sweep      mc_sculpt_vr. The SAME 8 grains of radius 0.066 dragged along one
##              bowed arc — chord 0.62, sagitta 0.09, rise 0.05 — so the grain
##              spacing is 0.094 and the deposits fuse into a continuous sausage
##              ~0.66 m long. The arc runs BROADSIDE, along (0.8139, 0, -0.5811),
##              which is the direction perpendicular to the capture azimuth. That is
##              not taste: mc_sculpt_vr measured an earlier +x version at 4.4% of
##              frame against stack where the broadside one is 9.8%, and its own
##              sweep table's endpoints differ by (-0.953, +0.680), which normalises
##              to exactly this line.
##   stipple    sculpt_one. 216 grains of radius 0.022 on 8 concentric rings, ring k
##              at radius 0.045k carrying 6k grains, phase-offset by PI/(6k) so the
##              rings interleave. Arc pitch TAU*0.045/6 = 0.0471 on every ring,
##              radial pitch 0.045, grain diameter 0.044 — so the tightest centre
##              gap anywhere in the 216 is the radial one at 0.0450, which is 1 mm
##              of clear air. Even, bounded, nothing touching: a controlled
##              peppering out to r = 0.36 and then nothing.
##   spatter    sculpt_one. 27 grains of radius 0.044 thrown at the whole bed:
##              seeded dart-throwing inside |x|,|z| <= 0.34 with a minimum centre
##              separation of 0.092, 240 attempts per grain and a best-of fallback,
##              so it always places 27 and always the same 27. Coverage 35%.
##   prim       maze_generation. Randomised Prim on a 7x7 lattice at pitch 0.100:
##              grow from one seed, and at every step open the frontier edge the
##              dice picked out of ALL of them. 48 openings, laid as bars of
##              0.100 x 0.0335 x 0.060. Short-limbed, bushy, isotropic.
##   labyrinth  maze_generation. The unicursal one, and the value that argues with
##              the other four. A boustrophedon snake through all 49 cells: 48
##              openings, the same bar, no junctions, no dead ends, and NO DICE —
##              _carve_labyrinth is the one carver in that file that calls no RNG.
@export_enum("stack", "sweep", "stipple", "spatter", "prim", "labyrinth") var hand: String = "stack":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not HANDS.has(picked):
			return                      ## an unreachable value keeps the current figure
		hand = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## WHAT THE PHOTOGRAPH IS OF. Three readings of one deposition.
##
##   deposit  what landed. The material itself, at true scale, where it fell.
##   pass     the path, as a real tube of radius 0.011 threading the deposits in the
##            order they were laid, with the deposit ghosted underneath as the
##            footprint it covers (5 mm of flat dark). This is the reading that
##            tests the word: only stack and sweep produce a curve a body could have
##            moved along.
##   grain    the unit. One deposit at true scale, alone, standing beside a sphere
##            of the WHOLE pass's material fused into one ball — radius 0.132,
##            identical in all six cells, because 8 x 3^3 = 27 x 2^3 = 216 x 1^3 and
##            the corridor bar's height is solved from the same total. Same amount,
##            different unit. Two pairs of hands are identical here BY CONSTRUCTION
##            and that is the point, not an accident.
@export_enum("deposit", "pass", "grain") var reading: String = "deposit":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not READINGS.has(picked):
			return
		reading = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One bench, or all six hands in a row. NOT PART OF EITHER AXIS, and that is wave
## 13's lesson paid forward: capture_config_sweep unions the AABB across a spec's
## variants, so an all-hands value declared inside `hand` would frame every single
## bench against six and a half metres and photograph a 22 mm grain as nothing. The
## registry fixture pins `single`.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## THE SEED, AND IT IS NOT OPTIONAL. Two of the six hands draw from the RNG —
## `spatter` throws 27 darts and `prim` pops a uniformly random frontier edge 48
## times — and an unseeded one makes every capture a different object, which is the
## trap this corpus has been caught by. sculpt_one carries `sculpt_seed`,
## maze_generation carries `maze_seed`; this is the same knob under the same
## discipline. The other four hands consume nothing: stipple's rings and labyrinth's
## snake are closed-form, and stack and sweep are arithmetic on two constants.
@export var bench_seed: int = 20260815:
	set(v):
		bench_seed = int(v)
		if is_inside_tree() and not _bulk:
			_rebuild()

const HANDS: PackedStringArray = ["stack", "sweep", "stipple", "spatter", "prim",
	"labyrinth"]
const READINGS: PackedStringArray = ["deposit", "pass", "grain"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the bed, and it is the answer to the extent trap ───────────────────────────────────
## The drawn figure runs from 0.49 m across (grain) to 0.81 m across (deposit at
## spatter) — a factor of 1.65 — so an AABB fitted to the FIGURE would move between
## cells and the camera would move with it. The slab, four corner posts and four top
## rails are drawn IDENTICALLY in all eighteen variants and are the largest thing in
## the scene, so the world box is 0.900 x 0.460 x 0.900 in every cell by construction.
## The bed is also the ruler: every number below is readable against a 0.90 m square.
const BED: float = 0.90
const BED_T: float = 0.024
const CAGE_H: float = 0.460
const POST: float = 0.030
const RAIL: float = 0.030

# ── the material budget ────────────────────────────────────────────────────────────────
## THE ONE IDENTITY EVERY HAND OBEYS. 8 grains of 3u, 27 of 2u and 216 of u are the
## same volume, exactly, because 8x27 = 27x8 = 216x1. u is 22 mm, so the three grain
## sizes are 66 / 44 / 22 mm and the total is 216 x (4/3)pi u^3 = 9.634 litres. The
## corridor bar's height is SOLVED from that total rather than chosen, so the two
## algorithm hands lay the same 9.634 litres in 48 pieces.
##
## This is not an invention. mc_sculpt_vr holds its seven deposits fixed across all
## four of its rungs and says so; maze_generator_vr holds its 48 removed walls fixed
## across all five of its hands and says so. Conserving the amount is what BOTH live
## members already do, and it is what makes `hand` an axis about arrangement.
const GRAIN_U: float = 0.022
const R_FINE: float = GRAIN_U               ## stipple
const R_MID: float = 2.0 * GRAIN_U          ## spatter
const R_COARSE: float = 3.0 * GRAIN_U       ## stack, sweep
const N_FINE: int = 216
const N_MID: int = 27
const N_COARSE: int = 8
const VOL_TOTAL: float = 216.0 * 4.0 / 3.0 * PI * GRAIN_U * GRAIN_U * GRAIN_U
## The whole pass fused into one ball. 6u exactly, because 216 = 6^3 — so this sphere
## is six stipple grains, three spatter grains and two stack grains across, and it is
## the same sphere in every cell of the `grain` reading.
const R_ALL: float = 6.0 * GRAIN_U

# ── the lattice, mirrored from maze_generator_vr ───────────────────────────────────────
## 7 x 7 cells is that file's own lattice: it declares a 15 x 15 grid with cells at
## the odd coordinates 1..13, which is 49 cells and 48 openings for a spanning tree.
const GRID: int = 7
const PITCH: float = 0.100
const EDGES: int = 48
const CORRIDOR_W: float = 0.060
## SOLVED, not chosen: 48 bars of PITCH x CORRIDOR_H x CORRIDOR_W must be VOL_TOTAL.
## Works out at 33.45 mm — a 60 mm wide, 33 mm high kerb on a 100 mm pitch. The 48.0 is
## written as a literal rather than float(EDGES) because a conversion call is not a
## constant expression and will not fold.
const CORRIDOR_H: float = VOL_TOTAL / 48.0 / (PITCH * CORRIDOR_W)

# ── the six hands, as numbers ──────────────────────────────────────────────────────────
const STACK_PITCH: float = 0.036            ## 8 grains of 0.066 fuse; top lands at 0.408
const SWEEP_CHORD: float = 0.62
const SWEEP_SAG: float = 0.09
const SWEEP_RISE: float = 0.05
const STIPPLE_RINGS: int = 8                ## 6(1+2+...+8) = 216, so 8 rings is forced
const STIPPLE_STEP: float = 0.045           ## radial pitch; arc pitch is TAU*STEP/6 = 0.0471
const SPATTER_HALF: float = 0.34
const SPATTER_MIN: float = 0.092            ## 2r is 0.088, so 4 mm of clear air minimum
const SPATTER_TRIES: int = 240

## The screen-horizontal direction at capture_config_sweep's standpoint. The camera
## sits along (sin 0.62 cos 0.26, sin 0.26, cos 0.62 cos 0.26); its plan azimuth is
## 35.5 degrees, so BROAD is that turned a quarter and VIEWP is the depth direction.
## A gesture laid along BROAD photographs at its full length; one laid along VIEWP
## photographs as a lump. Both members that ever measured this landed here.
const BROAD: Vector3 = Vector3(0.8139, 0.0, -0.5811)
const VIEWP: Vector3 = Vector3(0.5811, 0.0, 0.8139)

const TUBE_R: float = 0.011
const GHOST_T: float = 0.005
## Where the `grain` reading puts its two objects: -BROAD*0.17 and +BROAD*0.19, so
## they are 0.36 m apart along the screen horizontal and cannot overlap (0.132 +
## 0.066 = 0.198 of clearance needed). Written out rather than computed because
## GDScript will not fold Vector3 arithmetic into a const.
const MASS_AT: Vector3 = Vector3(-0.138363, 0.0, 0.098787)
const UNIT_AT: Vector3 = Vector3(0.154641, 0.0, -0.110409)

const LADDER_PITCH: float = 1.10
## Iterated rather than written as a literal array, so no loop variable is untyped.
const SIGNS: PackedFloat32Array = [-1.0, 1.0]

# ── colour reports role, never the axis ────────────────────────────────────────────────
## Every hand deposits the same substance in the same colour, so nothing on the `hand`
## axis is carried by hue — a difference between two cells is a difference in geometry
## or it is nothing. What colour DOES report is role: the mark is warm and lit, the
## path is cool, the ghost of a deposit under its own path is dark and matte, and the
## fused mass in the `grain` reading is the mark's own colour with the light taken out
## of it, because it is the same stuff and not a mark.
const C_BED: Color = Color(0.13, 0.14, 0.16)
const C_CAGE: Color = Color(0.34, 0.35, 0.38)
const C_MARK: Color = Color(0.90, 0.82, 0.66)
const E_MARK: Color = Color(0.30, 0.25, 0.15)
const C_TRAIL: Color = Color(0.42, 0.86, 1.00)
const E_TRAIL: Color = Color(0.16, 0.42, 0.58)
const C_GHOST: Color = Color(0.24, 0.22, 0.20)
const C_MASS: Color = Color(0.56, 0.51, 0.42)

var _built: Array[Node3D] = []
## Set while a whole config dictionary lands, so four keys cost one rebuild, not four.
var _bulk: bool = false


func _ready() -> void:
	# Metadata FIRST. GridInteractablesComponent stamps config_* at line 1195 and only
	# add_childs at 1220, so a placement's values are already on the node and the first
	# build is the right one; the deferred apply_grid_config that follows then finds
	# nothing changed. Both live members read their metadata this way.
	_read_config_meta()
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("bench_seed"):
		bench_seed = int(config_data["bench_seed"])
	if config_data.has("hand"):
		hand = str(config_data["hand"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
	_bulk = false
	_rebuild()


## A word a map token could not reach must keep the default rather than empty the bed.
func _read_config_meta() -> void:
	_bulk = true
	if has_meta("config_layout"):
		layout = _pick(str(get_meta("config_layout")), LAYOUTS, layout)
	if has_meta("config_bench_seed"):
		bench_seed = int(str(get_meta("config_bench_seed")))
	if has_meta("config_hand"):
		hand = _pick(str(get_meta("config_hand")), HANDS, hand)
	if has_meta("config_reading"):
		reading = _pick(str(get_meta("config_reading")), READINGS, reading)
	_bulk = false


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var names: PackedStringArray = PackedStringArray()
	if layout == "ladder":
		names = HANDS.duplicate()
	else:
		names.append(_pick(hand, HANDS, "stack"))
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Hand_" + names[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_bed(holder)
		_build_figure(holder, names[i])


func _is_corridor(which: String) -> bool:
	return which == "prim" or which == "labyrinth"


## The radius of one grain for a gesture hand. Three values, in the ratio 3 : 2 : 1,
## because the counts are in the ratio 8 : 27 : 216 and the volume is conserved.
func _grain_radius(which: String) -> float:
	if which == "stipple":
		return R_FINE
	if which == "spatter":
		return R_MID
	return R_COARSE


# ── where the material goes ────────────────────────────────────────────────────────────

func _centres(which: String, rng: RandomNumberGenerator) -> PackedVector3Array:
	if which == "sweep":
		return _sweep_centres()
	if which == "stipple":
		return _stipple_centres()
	if which == "spatter":
		return _spatter_centres(rng)
	return _stack_centres()


## STACK. Eight grains, one place, straight up. Spread 0.
func _stack_centres() -> PackedVector3Array:
	var out: PackedVector3Array = PackedVector3Array()
	for i in range(N_COARSE):
		out.append(Vector3(0.0, BED_T + R_COARSE + float(i) * STACK_PITCH, 0.0))
	return out


## SWEEP. The same eight grains dragged along a bowed arc that rises and settles. The
## bow is in plan, along VIEWP; the rise is a half sine, so the gesture leaves the bed
## and comes back to it. Grain spacing 0.094 against a diameter of 0.132, so the eight
## fuse into one continuous mark — which is what makes it one gesture rather than eight.
func _sweep_centres() -> PackedVector3Array:
	var out: PackedVector3Array = PackedVector3Array()
	for i in range(N_COARSE):
		var t: float = float(i) / float(N_COARSE - 1)
		var along: float = (t - 0.5) * SWEEP_CHORD
		var bow: float = SWEEP_SAG * (1.0 - (2.0 * t - 1.0) * (2.0 * t - 1.0))
		var rise: float = SWEEP_RISE * sin(PI * t)
		var p: Vector3 = BROAD * along + VIEWP * bow
		out.append(Vector3(p.x, BED_T + R_COARSE + rise, p.z))
	return out


## STIPPLE. Eight concentric rings, 6k grains on ring k. The count is not a taste:
## 6(1+2+...+k) = 216 has the single solution k = 8. Every ring is phase-offset by half
## its own arc pitch so the rings interleave, and the arc pitch is the same 0.0471 on
## every ring by construction, because the count grows with the radius.
func _stipple_centres() -> PackedVector3Array:
	var out: PackedVector3Array = PackedVector3Array()
	for k in range(1, STIPPLE_RINGS + 1):
		var kk: int = k
		var radius: float = STIPPLE_STEP * float(kk)
		var n: int = 6 * kk
		var phase: float = PI / float(n)
		for m in range(n):
			var a: float = TAU * float(m) / float(n) + phase
			out.append(Vector3(cos(a) * radius, BED_T + R_FINE, sin(a) * radius))
	return out


## SPATTER. Twenty-seven grains thrown at the whole bed. Dart-throwing with a minimum
## separation, a fixed attempt budget and a best-of-attempts fallback, so it always
## terminates, always places 27, and places THE SAME 27 for a given seed. Coverage is
## 35% of the patch against a random-sequential-adsorption jamming limit near 55%, so
## the sampler is working well inside its comfortable range.
func _spatter_centres(rng: RandomNumberGenerator) -> PackedVector3Array:
	var out: PackedVector3Array = PackedVector3Array()
	for i in range(N_MID):
		var best: Vector3 = Vector3.ZERO
		var best_gap: float = -1.0
		for t in range(SPATTER_TRIES):
			var px: float = rng.randf_range(-SPATTER_HALF, SPATTER_HALF)
			var pz: float = rng.randf_range(-SPATTER_HALF, SPATTER_HALF)
			var gap: float = 9.0
			for q in out:
				var qq: Vector3 = q
				var d: float = Vector2(px - qq.x, pz - qq.z).length()
				gap = minf(gap, d)
			if gap > best_gap:
				best_gap = gap
				best = Vector3(px, BED_T + R_MID, pz)
			if gap >= SPATTER_MIN:
				break
		out.append(best)
	return out


# ── the two procedures ─────────────────────────────────────────────────────────────────
## Both return 48 edges of the 7x7 lattice IN THE ORDER THEY WERE DECIDED, which is the
## only thing the `pass` reading needs and the only thing that separates them. Both are
## written to the same shape as maze_generator_vr's own carvers, because the claim being
## made is about those procedures and not about a paraphrase of them.

func _edges(which: String, rng: RandomNumberGenerator) -> Array:
	if which == "labyrinth":
		return _labyrinth_edges()
	return _prim_edges(rng)


func _in_lattice(c: Vector2i) -> bool:
	return c.x >= 0 and c.x < GRID and c.y >= 0 and c.y < GRID


func _cell_world(c: Vector2i) -> Vector3:
	return Vector3((float(c.x) - 3.0) * PITCH, 0.0, (float(c.y) - 3.0) * PITCH)


## PRIM. Grow from one seed; at every step open the frontier edge the dice picked out of
## ALL of them. No commitment and no momentum, so the result is short-limbed and bushy —
## and, which is the part the `pass` reading is for, consecutive decisions can be at
## opposite ends of the lattice. Nothing walks from one to the next.
func _prim_edges(rng: RandomNumberGenerator) -> Array:
	var reached: Dictionary = {}
	var frontier: Array = []
	var start: Vector2i = Vector2i(0, 0)
	reached[start] = true
	_push_frontier(start, reached, frontier)
	var out: Array = []
	while frontier.size() > 0:
		var pick: int = rng.randi_range(0, frontier.size() - 1)
		var edge: Array = frontier[pick]
		frontier.remove_at(pick)
		var to: Vector2i = edge[1]
		if reached.has(to):
			continue
		reached[to] = true
		out.append([edge[0], to])
		_push_frontier(to, reached, frontier)
	return out


func _push_frontier(c: Vector2i, reached: Dictionary, frontier: Array) -> void:
	var steps: Array = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	for s in steps:
		var step: Vector2i = s
		var n: Vector2i = c + step
		if _in_lattice(n) and not reached.has(n):
			frontier.append([c, n])


## LABYRINTH. A boustrophedon snake through all 49 cells: no junctions, no dead ends,
## nothing to solve, and NO RNG — the one carver in maze_generator_vr that rolls nothing.
## It takes the same 48 openings the others take. Its decision order is also a route:
## carving it means following it, which makes it the only value in the algorithm half of
## this axis whose `pass` is a path a body could walk.
func _labyrinth_edges() -> Array:
	var path: Array = []
	var flip: bool = false
	for j in range(GRID):
		var row: Array = []
		for i in range(GRID):
			row.append(Vector2i(i, j))
		if flip:
			row.reverse()
		path.append_array(row)
		flip = not flip
	var out: Array = []
	for k in range(path.size() - 1):
		out.append([path[k], path[k + 1]])
	return out


## The bar that fills one opening: a kerb spanning exactly one lattice pitch, oriented
## along the edge it opens. Returns [centre, size].
func _bar(edge: Array) -> Array:
	var a: Vector2i = edge[0]
	var b: Vector2i = edge[1]
	var wa: Vector3 = _cell_world(a)
	var wb: Vector3 = _cell_world(b)
	var mid: Vector3 = (wa + wb) * 0.5
	var size: Vector3 = Vector3(CORRIDOR_W, CORRIDOR_H, PITCH)
	if a.x != b.x:
		size = Vector3(PITCH, CORRIDOR_H, CORRIDOR_W)
	return [Vector3(mid.x, BED_T + CORRIDOR_H * 0.5, mid.z), size]


# ── building ───────────────────────────────────────────────────────────────────────────

func _build_bed(holder: Node3D) -> void:
	var slab := SurfaceTool.new()
	slab.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(slab, Vector3(0.0, BED_T * 0.5, 0.0), Vector3(BED, BED_T, BED))
	_commit(holder, "Bed", slab, C_BED, Color.BLACK)

	var cage := SurfaceTool.new()
	cage.begin(Mesh.PRIMITIVE_TRIANGLES)
	var off: float = BED * 0.5 - POST * 0.5
	for sx in SIGNS:
		for sz in SIGNS:
			_add_box(cage, Vector3(sx * off, CAGE_H * 0.5, sz * off),
				Vector3(POST, CAGE_H, POST))
	for sz in SIGNS:
		_add_box(cage, Vector3(0.0, CAGE_H - RAIL * 0.5, sz * off),
			Vector3(BED - POST * 2.0, RAIL, RAIL))
	for sx in SIGNS:
		_add_box(cage, Vector3(sx * off, CAGE_H - RAIL * 0.5, 0.0),
			Vector3(RAIL, RAIL, BED - POST * 2.0))
	_commit(holder, "Cage", cage, C_CAGE, Color.BLACK)


func _build_figure(holder: Node3D, which: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = bench_seed
	if reading == "grain":
		_build_grain(holder, which)
	elif reading == "pass":
		_build_pass(holder, which, rng)
	else:
		_build_deposit(holder, which, rng)


## WHAT LANDED. The material at true scale, where it fell, and nothing else.
func _build_deposit(holder: Node3D, which: String, rng: RandomNumberGenerator) -> void:
	var mark := SurfaceTool.new()
	mark.begin(Mesh.PRIMITIVE_TRIANGLES)
	if _is_corridor(which):
		var edges: Array = _edges(which, rng)
		for e in edges:
			var bar: Array = _bar(e)
			var at: Vector3 = bar[0]
			var size: Vector3 = bar[1]
			_add_box(mark, at, size)
	else:
		var r: float = _grain_radius(which)
		var lod: Vector2i = _sphere_lod(r)
		var pts: PackedVector3Array = _centres(which, rng)
		for p in pts:
			_add_sphere(mark, p, r, lod.x, lod.y)
	_commit(holder, "Deposit", mark, C_MARK, E_MARK)


## THE PATH. A tube through the deposits in the order they were laid, with each deposit
## ghosted as the footprint it covers. The tube is the hand's motion where there was
## one and the procedure's decision order where there was not, drawn identically in both
## cases ON PURPOSE — the picture is the argument, so the drawing must not take sides.
func _build_pass(holder: Node3D, which: String, rng: RandomNumberGenerator) -> void:
	var ghost := SurfaceTool.new()
	ghost.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trail := SurfaceTool.new()
	trail.begin(Mesh.PRIMITIVE_TRIANGLES)
	var path: PackedVector3Array = PackedVector3Array()

	if _is_corridor(which):
		var edges: Array = _edges(which, rng)
		for e in edges:
			var bar: Array = _bar(e)
			var at: Vector3 = bar[0]
			var size: Vector3 = bar[1]
			_add_box(ghost, Vector3(at.x, BED_T + GHOST_T * 0.5, at.z),
				Vector3(size.x, GHOST_T, size.z))
			path.append(at)
	else:
		var r: float = _grain_radius(which)
		var pts: PackedVector3Array = _centres(which, rng)
		for p in pts:
			var pp: Vector3 = p
			_add_cylinder(ghost, Vector3(pp.x, BED_T, pp.z), r, GHOST_T, 12)
			path.append(pp)

	_add_tube(trail, path, TUBE_R, 8)
	_commit(holder, "Ghost", ghost, C_GHOST, Color.BLACK)
	_commit(holder, "Pass", trail, C_TRAIL, E_TRAIL)


## THE UNIT. One deposit at true scale beside the whole pass fused into one ball. The
## ball is 0.132 in radius in EVERY cell — that is what conserving the volume buys — so
## the only thing that moves across the six hands is the unit standing next to it.
func _build_grain(holder: Node3D, which: String) -> void:
	var mass := SurfaceTool.new()
	mass.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_sphere(mass, Vector3(MASS_AT.x, BED_T + R_ALL, MASS_AT.z), R_ALL, 14, 20)
	_commit(holder, "Mass", mass, C_MASS, Color.BLACK)

	var unit := SurfaceTool.new()
	unit.begin(Mesh.PRIMITIVE_TRIANGLES)
	if _is_corridor(which):
		_add_box(unit, Vector3(UNIT_AT.x, BED_T + CORRIDOR_H * 0.5, UNIT_AT.z),
			Vector3(PITCH, CORRIDOR_H, CORRIDOR_W))
	else:
		var r: float = _grain_radius(which)
		var lod: Vector2i = _sphere_lod(r)
		_add_sphere(unit, Vector3(UNIT_AT.x, BED_T + r, UNIT_AT.z), r, lod.x, lod.y)
	_commit(holder, "Unit", unit, C_MARK, E_MARK)


# ── mesh primitives ────────────────────────────────────────────────────────────────────

## Tessellation by size, so 216 fine grains do not cost what 216 coarse ones would and a
## coarse grain is still round. Nothing about the axis depends on it: two hands with the
## same radius get the same LOD, which is what keeps the designed nulls exact.
func _sphere_lod(r: float) -> Vector2i:
	if r >= 0.06:
		return Vector2i(12, 18)
	if r >= 0.03:
		return Vector2i(9, 14)
	return Vector2i(6, 10)


func _add_sphere(st: SurfaceTool, centre: Vector3, r: float, rings: int,
		segs: int) -> void:
	var pts: Array = []
	for i in range(rings + 1):
		var th: float = PI * float(i) / float(rings)
		var ring: PackedVector3Array = PackedVector3Array()
		for j in range(segs):
			var ph: float = TAU * float(j) / float(segs)
			ring.append(centre + Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph)) * r)
		pts.append(ring)
	for i in range(rings):
		var r0: PackedVector3Array = pts[i]
		var r1: PackedVector3Array = pts[i + 1]
		for j in range(segs):
			var k: int = (j + 1) % segs
			_quad(st, r0[j], r1[j], r1[k], r0[k])


## A flat disc standing on the bed — the footprint a grain covers, which is what the
## `pass` reading ghosts. Not a squashed sphere: a footprint is a plan, not a body.
func _add_cylinder(st: SurfaceTool, base: Vector3, r: float, h: float,
		segs: int) -> void:
	var top: PackedVector3Array = PackedVector3Array()
	var bot: PackedVector3Array = PackedVector3Array()
	for j in range(segs):
		var a: float = TAU * float(j) / float(segs)
		var o: Vector3 = Vector3(cos(a) * r, 0.0, sin(a) * r)
		bot.append(base + o)
		top.append(base + o + Vector3(0.0, h, 0.0))
	var cap_t: Vector3 = base + Vector3(0.0, h, 0.0)
	for j in range(segs):
		var k: int = (j + 1) % segs
		_quad(st, bot[j], top[j], top[k], bot[k])
		_tri(st, cap_t, top[k], top[j])
		_tri(st, base, bot[j], bot[k])


func _add_tube(st: SurfaceTool, path: PackedVector3Array, r: float, sides: int) -> void:
	var n: int = path.size()
	if n < 2:
		return
	var rings: Array = []
	for i in range(n):
		var d: Vector3 = Vector3(1.0, 0.0, 0.0)
		if i == 0:
			d = path[1] - path[0]
		elif i == n - 1:
			d = path[n - 1] - path[n - 2]
		else:
			d = path[i + 1] - path[i - 1]
		if d.length() < 0.000001:
			d = Vector3(1.0, 0.0, 0.0)
		d = d.normalized()
		var up: Vector3 = Vector3(0.0, 1.0, 0.0)
		if absf(d.dot(up)) > 0.9:
			up = Vector3(1.0, 0.0, 0.0)
		var right: Vector3 = d.cross(up).normalized()
		var fwd: Vector3 = right.cross(d).normalized()
		var ring: PackedVector3Array = PackedVector3Array()
		for s in range(sides):
			var a: float = TAU * float(s) / float(sides)
			ring.append(path[i] + (right * cos(a) + fwd * sin(a)) * r)
		rings.append(ring)
	for i in range(n - 1):
		var r0: PackedVector3Array = rings[i]
		var r1: PackedVector3Array = rings[i + 1]
		for s in range(sides):
			var t: int = (s + 1) % sides
			_quad(st, r0[s], r1[s], r1[t], r0[t])


## An axis-aligned box, twelve triangles, wound outward with explicit per-face normals.
func _add_box(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var p: PackedVector3Array = PackedVector3Array([
		at + Vector3(-h.x, -h.y, h.z), at + Vector3(h.x, -h.y, h.z),
		at + Vector3(h.x, h.y, h.z), at + Vector3(-h.x, h.y, h.z),
		at + Vector3(-h.x, -h.y, -h.z), at + Vector3(h.x, -h.y, -h.z),
		at + Vector3(h.x, h.y, -h.z), at + Vector3(-h.x, h.y, -h.z)])
	_quad(st, p[0], p[1], p[2], p[3])
	_quad(st, p[5], p[4], p[7], p[6])
	_quad(st, p[3], p[2], p[6], p[7])
	_quad(st, p[4], p[5], p[1], p[0])
	_quad(st, p[1], p[5], p[6], p[2])
	_quad(st, p[4], p[0], p[3], p[7])


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	var pts: PackedVector3Array = PackedVector3Array([a, b, c])
	for v in pts:
		st.set_normal(n)
		st.add_vertex(v)


## Two triangles wound a -> b -> c -> d with the normal taken from the winding, and every
## material CULL_DISABLED besides — a sheet photographed from behind is indistinguishable
## from a sheet that was never built.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	var tri: PackedVector3Array = PackedVector3Array([a, b, c, a, c, d])
	for v in tri:
		st.set_normal(n)
		st.add_vertex(v)


## Only non-empty tools are committed. SurfaceTool.commit() on a tool that was begun and
## never given a vertex is not a mesh with no surfaces, it is an error in the log.
func _commit(holder: Node3D, mesh_name: String, st: SurfaceTool, c: Color,
		emission: Color) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = _mat(c, emission)
	holder.add_child(mi)


func _mat(c: Color, emission: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.1
	m.roughness = 0.55
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 0.55
	return m
