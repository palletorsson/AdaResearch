extends Node3D
class_name CohortBench

## cohort_bench — five shapes of data, three inductive biases, and the half of the
## family's own argument that none of its three members has ever photographed.
##
## THE FAMILY. Three artifacts declare an axis called `cohort` and all three declare
## the SAME FIVE WORDS — the only unanimous vocabulary of this size in the corpus:
##
##   enhanced_kmeans              blobs | block | rings | braid | skew   default blobs
##   random_forest_visualization  blobs | block | rings | braid | skew   default block
##   svm_visualization            blobs | block | rings | braid | skew   default blobs
##
## Three separate scenes, three separate scripts, no shared scene — checked. Two of the
## three ship `blobs`; the forest ships `block`, which is its own shipped look.
##
## THE FIRST THING THE CODE SAYS, and it corrects the brief this bench was built from.
## The brief said the five shapes are ADVERSARIES, each chosen to defeat a particular
## inductive bias, and that is right about the DATA and wrong about the PICTURE:
##
##   IN ALL THREE MEMBERS, `cohort` CHANGES ONLY THE SCATTER. Not one of them reliably
##   photographs what its method DOES to that scatter.
##
##     enhanced_kmeans   its @identity says the algorithm makes a "Voronoi tessellation
##                       of space". Nothing in the file draws a Voronoi.
##                       update_voronoi_regions() builds ONE flat PlaneMesh per centroid,
##                       sized data_space_size/2 square, positioned AT the centroid, at
##                       alpha 0.1 — k stacked translucent squares, not a partition. And
##                       `show_voronoi_regions` ships FALSE, so it never renders at all.
##                       The centroids themselves move under _process, so where they are
##                       when the shutter opens is a fact about the clock.
##     random_forest     draws no decision boundary anywhere. Its trees are node-and-edge
##                       diagrams on a Timer, hanging below the scatter; its own header
##                       says so — "the trees ... may be absent or mid-grow when the
##                       shutter opens, so the axis is legible in the SCATTER ALONE".
##                       The two volumes it does draw at `braid` and `skew` are the TRUE
##                       class regions, not the forest's cuts. `show_ensemble_prediction`
##                       is exported and read by NOTHING.
##     svm               builds its boundary as a POINT CLOUD — a 50x50 sample of the
##                       decision function, PRIMITIVE_POINTS where |f| < 0.1 — and only
##                       inside finalize_training(), at the end of a Timer-driven SMO
##                       loop. `margin_meshes` is declared, cleared, and never once
##                       appended to: THE MAXIMUM-MARGIN ARTIFACT DRAWS NO MARGIN.
##                       `show_decision_boundary` and `show_margin_lines` are read by
##                       nothing either.
##
## So the family has built the battery and never built the instrument. The five shapes
## are adversaries in the note and in the arithmetic; in the still they are five
## scatters. This bench builds the missing half: the same battery, and the boundary as
## REAL GEOMETRY — walls standing in the field, computed from the points, synchronously,
## with no clock anywhere.
##
## AND THE SECOND CORRECTION, which is smaller and sharper. The brief said "a linear SVM
## cannot separate rings or braid without a kernel". svm_visualization SHIPS THE KERNEL:
## `kernel_type: String = "rbf"`, gamma 1.0, C 1.0, and its own header calls `rings` "the
## honest advertisement for the kernel trick". The linear case is one of four branches in
## kernel_function and is never the default. This bench draws the LINEAR cut and says so
## in `declines`; the failure it shows at `rings` is a fact about the linear branch.
##
## WHAT THIS BENCH DOES. One field — a 0.84 x 0.84 m square on a 0.96 x 0.96 m plate —
## carries 120 points in every cell, and `cut` applies one of the three members' biases
## to them and draws the result as walls:
##
##   centroid  k-means, k = 4 (enhanced_kmeans' own cluster_count), run to convergence,
##             and the actual VORONOI of the four centroids: every interior bisector
##             clipped to the field and stood up as a wall.
##   axis      one CART, Gini, axis-aligned splits, max depth 5 and min_samples_split 2
##             (random_forest_visualization's own numbers). Each internal node's cut is a
##             wall spanning ITS OWN rectangle, so the recursion draws a staircase.
##   margin    one linear separator, chosen over 180 directions for fewest errors and
##             then widest gap, drawn as three parallel walls: the decision plane at full
##             height, and the two margin planes at half height.
##
## THE ONE RIG DECISION, and it is the argument. Under `centroid` the 120 points are
## drawn UNLABELLED — one neutral post each, at the mean of the two class heights —
## because k-means is unsupervised and that is the data it is actually handed.
## `axis` and `margin` are supervised, so their points carry class in TWO channels at
## once: height (0.026 m against 0.062 m) and albedo (0.785 against 0.428 on Rec.709),
## never hue alone.
##
## AND THAT PRODUCES THE NULL, WHICH IS THE THESIS. `block` and `skew` are ONE
## POPULATION UNDER TWO LABELLINGS — the same 120 lattice positions, the same jitter
## draws, agreeing on 66 points and disagreeing on 54. This is not invented: in
## random_forest_visualization, _gen_block and _gen_skew are both uniform fills of the
## same 8 m cube and differ only in how the labels are assigned. So under `centroid`,
## which cannot see a label, `block` and `skew` ARE THE SAME PHOTOGRAPH TO THE BYTE;
## under `axis` and `margin` they are two of the furthest-apart cells in the sheet.
## One population is an easy problem and an impossible one depending on a labelling that
## one of the three methods is constitutionally unable to see.
##
## Deterministic: one seeded RandomNumberGenerator, seed 20260730 — the family's OWN
## constant, identical in all three members (enhanced_kmeans RNG_SEED, random_forest
## DATA_SEED, svm DATA_SEED) — offset by the POPULATION index, not the cohort index, so
## block and skew draw the same lattice. No randf outside it, no noise, no NoiseTexture2D,
## no _process, no Timer, no tween. Two builds of one cell are the same mesh.


## THE SHAPE OF THE POPULATION. The family's five words, in the family's own order (the
## order two of the three members declare; the forest lists block first because block is
## its default). Every value below says what defeats what, and the arithmetic is in the
## registry `note`.
##
##   blobs  two isotropic discs, radius 0.17 m, centres at x = +-0.21 m, 60 points each
##          and the LEFT DISC IS THE EXACT MIRROR OF THE RIGHT. The shape k-means was
##          built for, and the one shape where all three biases nearly agree: `axis` puts
##          its single cut at x = 0.000 and `margin` puts its decision plane at x = 0.000,
##          the same wall to the millimetre. This is the flattering case, and it is here
##          so the other four have something to fail against.
##          NOTE THE FAMILY DISAGREES ABOUT THE COUNT: kmeans builds THREE gaussian discs
##          plus 10 noise points, the forest and the svm build TWO. Two wins 2-1.
##   block  a filled 12 x 10 lattice, 120 cells at 0.070 x 0.084 m pitch, jittered 0.006 m
##          inside its own cell, labelled from the CELL CENTRE by x + z >= 0 — which comes
##          out at exactly 60 and 60. A filled field has no hole for a margin to sit in,
##          and svm_visualization's own comment is the caption: "the thing being maximised
##          has nowhere to sit". The lattice rather than a uniform draw is that member's
##          own repair, and the reason is in `declines`.
##   rings  48 points in a 0.13 m core inside 72 on a 0.34 m shell 0.07 m thick. ALL THREE
##          MEMBERS SPLIT THIS 40/60, independently — kmeans CORE_N 40 / RING_N 60, the
##          forest 40 / 60, the svm 0.4 / 0.6 of the total. The strongest agreement in the
##          family. A Voronoi cell cannot express a shell and a straight line gets 42 of
##          120 wrong against a do-nothing baseline of 48. BUT THE STAIRCASE THE FOREST'S
##          HEADER PROMISES HERE DOES NOT EXIST, and that is measured, not argued: a box
##          separates a disc of radius r from an annulus exactly whenever the annulus's
##          inner radius exceeds r x sqrt(2), because that is where the box's corner
##          reaches. At the family's own proportions — core 0.35 of the outer edge — it
##          does: 0.13 x 1.414 = 0.184 against an inner radius of 0.305. FOUR CUTS, NO
##          STAIRCASE. The real staircase is at `block`, and it is eleven cuts long.
##   braid  two sinusoidal bands, amplitude 0.13 m, period 0.42 m, 0.05 m apart, 60 points
##          each. THE ONE VALUE WHERE ALL THREE MEMBERS BUILD A DIFFERENT SHAPE: kmeans
##          makes two Archimedean spiral arms, the forest makes eight alternating
##          axis-aligned slabs, the svm makes two offset sine bands. One word, three
##          geometries. The svm's reading is used here and the reason is in `declines`.
##   skew   the SAME 120 lattice positions as `block`, relabelled 114 / 6 with the six
##          minority points in a BOX at the +x +z corner. The forest's and the svm's ratio
##          (95/5) on this bench's 120 points; kmeans instead builds 88 plus two 6-point
##          groups, so 2-1 again.
##
## WHAT THE FIVE ACTUALLY DO TO THE THREE, measured on a Python replica of this file
## before any capture — wall counts, and the linear cut's error out of 120:
##
##            centroid          axis                margin
##   blobs    5 walls, right    1 wall              3 walls,  0 errors, gap 0.121
##   block    5 walls, invented 11 walls (staircase) 3 walls, 0 errors, gap 0.004
##   rings    5 walls, wedges   4 walls (a box)     3 walls, 42 errors (baseline 48)
##   braid    5 walls, halves   8 walls             3 walls, 41 errors (baseline 60)
##   skew     5 walls, blind    2 walls (native)    3 walls,  1 error
##
## AND THAT TABLE CORRECTS THE BRIEF A THIRD TIME. It asked for one cohort that defeats
## all three. THERE ISN'T ONE. Every non-flattering shape is handled cleanly by at least
## one bias: `rings` and `skew` fall to `axis` in four cuts and two, `block` falls to
## `margin` exactly. The only method defeated by all five is `centroid`, and it is
## defeated for the same reason every time — it never sees a label, so it can only ever
## be right by coincidence, and `blobs` is that coincidence. The nearest thing to a
## universal adversary is `braid`: wedged by centroid, 41 of 120 wrong under margin, and
## eight axis-aligned cuts spent approximating two smooth curves. Which is the value the
## three members cannot agree on the shape of.
@export_enum("blobs", "block", "rings", "braid", "skew") var cohort: String = "blobs":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not COHORTS.has(picked):
			return                      ## an unreachable value keeps the standing figure
		cohort = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## WHICH INDUCTIVE BIAS IS APPLIED. Three values, one per member, and every hyperparameter
## is the member's own rather than this bench's.
##
##   centroid  enhanced_kmeans. Nearest centre, so the boundary is a Voronoi diagram and
##             the walls are perpendicular bisectors. k = 4 from that member's
##             `cluster_count: int = 4`. UNSUPERVISED: the points are drawn without class,
##             because that is the data k-means receives.
##   axis      random_forest_visualization. Axis-aligned cuts only, so the boundary is a
##             staircase of walls, each spanning only the rectangle its node owns. Depth 5
##             and min_samples_split 2 from that member's `max_depth` and
##             `min_samples_split`. SUPERVISED.
##   margin    svm_visualization, LINEAR branch. One plane whatever the data is, plus the
##             two margin planes that bound the gap it found. SUPERVISED.
@export_enum("centroid", "axis", "margin") var cut: String = "centroid":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not CUTS.has(picked):
			return
		cut = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One cell, or all five cohorts in a row. NOT PART OF EITHER AXIS. capture_config_sweep
## unions the AABB across a spec's variants, so an all-cohorts value declared inside
## `cohort` would frame every single cell against five and a half metres and photograph
## the walls as hairs. The registry fixture pins `single`; `ladder` is a design view.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const COHORTS: PackedStringArray = ["blobs", "block", "rings", "braid", "skew"]
const CUTS: PackedStringArray = ["centroid", "axis", "margin"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

## THE FAMILY'S OWN SEED, identical in all three members: enhanced_kmeans RNG_SEED,
## random_forest_visualization DATA_SEED, svm_visualization DATA_SEED. All three wrote
## 20260730 independently and all three say the same thing about why — two builds of one
## value must be pixel-identical or the pixel critic reads sampling noise as axis signal.
const DATA_SEED: int = 20260730

# ── the stage, identical to the millimetre in all fifteen cells ─────────────────────────
## THE FOUR CORNER POSTS ARE THE WHOLE REASON THE AABB NEVER MOVES. They stand exactly
## WALL_H tall at the plate corners, so the world box is 0.96 x 0.164 x 0.96 whatever the
## cut draws — even before a single wall exists. Without them the height of the box would
## be a fact about which cut was picked, the camera would move between cells, and every
## measured pair would carry a framing difference it did not earn.
const PLATE_HALF: float = 0.48
const PLATE_T: float = 0.024
const FIELD_HALF: float = 0.42
const CORNER_W: float = 0.030
const CORNER_INSET: float = 0.465

# ── the cut, drawn as bodies ───────────────────────────────────────────────────────────
## Every wall in every cut is the same thickness and the same height, so the difference
## between three biases is WHERE THE WALLS ARE and nothing else. The margin planes are the
## one exception and they are deliberately a different KIND of thing: half height, two
## thirds thickness, and dimmer, because they mark the gap rather than the decision.
const WALL_H: float = 0.140
const WALL_T: float = 0.009
const MARGIN_H: float = 0.070
const MARGIN_T: float = 0.006
## A gap of zero would put the margin planes inside the decision plane and photograph as
## one wall. Floored just clear of WALL_T so `block`, which genuinely has no margin, reads
## as three walls crowded together rather than as a rendering fault.
const MARGIN_MIN: float = 0.011
const MARGIN_MAX: float = 0.120

# ── the population, drawn as bodies ────────────────────────────────────────────────────
## CLASS IS CARRIED BY HEIGHT AND BY ALBEDO AT ONCE, never by hue alone. The critic
## measures luminance by default and has a separate colour rescue; a pair separated only
## by hue at constant brightness reads as a twin in greyscale, and class colour is exactly
## the thing a machine-learning visualisation reaches for first. POST_U is the arithmetic
## mean of the two class heights, and C_UNLAB is the mean of the two class luminances to
## within 0.003 — the unlabelled post is literally the average of what it could be.
const N_POINTS: int = 120
const POST_W: float = 0.020
const POST_A: float = 0.026            ## label 0, the short post
const POST_B: float = 0.062            ## label 1, the tall post
const POST_U: float = 0.044            ## unlabelled, (0.026 + 0.062) / 2

# ── cohort geometry, all in metres of the field ────────────────────────────────────────
const BLOB_R: float = 0.17
const BLOB_CX: float = 0.21
const BLOB_N: int = 60                 ## per disc; the right disc is drawn and mirrored
const LAT_COLS: int = 12
const LAT_ROWS: int = 10
const LAT_JITTER: float = 0.006        ## 8.6 percent of the smaller pitch, well under 16
## The minority pocket is a CORNER BOX, because both members that build one build a box —
## random_forest_visualization's SKEW_CORNER 1.5 m cube at (+x,+y,+z) and
## svm_visualization's SKEW_POCKET 0.9 m square. It matters: a box is not linearly
## separable from an L-shaped complement, and a set defined by "the six largest x + z"
## IS. The first draft used the ranking, and the replica caught it — the margin cut came
## back with zero errors on `skew`, which would have published a failure case that the
## method solves perfectly.
const SKEW_POCKET_X: float = 0.21
const SKEW_POCKET_Z: float = 0.25      ## three columns by two rows = exactly 6 of 120
const RING_CORE_N: int = 48            ## 40 percent — all three members split it 40/60
const RING_SHELL_N: int = 72           ## 60 percent
const RING_DISC: float = 0.13
const RING_MEAN: float = 0.34
const RING_WALL: float = 0.07
const BRAID_N: int = 60                ## per band
const BRAID_AMP: float = 0.13
const BRAID_PERIOD: float = 0.42
const BRAID_SEP: float = 0.05
const BRAID_JITTER: float = 0.010      ## 20 percent of the separation, the svm's ratio

# ── the members' own hyperparameters ───────────────────────────────────────────────────
const KMEANS_K: int = 4                ## enhanced_kmeans.gd:89, cluster_count
const KMEANS_ITERS: int = 40
const TREE_MAX_DEPTH: int = 5          ## random_forest_visualization.gd:118, max_depth
const TREE_MIN_SPLIT: int = 2          ## random_forest_visualization.gd:119
const MARGIN_DIRECTIONS: int = 180     ## one degree of arc; the svm searches no angles

# ── colour ─────────────────────────────────────────────────────────────────────────────
## Rec.709 luminance of each, written down so the greyscale reading is checkable rather
## than hoped: plate 0.180, corner 0.309, unlabelled 0.610, class 0 0.785, class 1 0.428,
## wall 0.899, margin 0.561. No two things that must be told apart sit within 0.10 of each
## other, and the two classes are 0.357 apart in luminance BEFORE their heights differ.
const C_PLATE: Color = Color(0.17, 0.18, 0.21)
const C_CORNER: Color = Color(0.30, 0.31, 0.34)
const C_UNLAB: Color = Color(0.60, 0.61, 0.64)
const C_CLASS_A: Color = Color(0.86, 0.80, 0.42)
const C_CLASS_B: Color = Color(0.32, 0.44, 0.62)
const C_WALL: Color = Color(0.90, 0.90, 0.92)
const C_MARGIN: Color = Color(0.55, 0.56, 0.60)

const LADDER_PITCH: float = 1.10
## Iterated rather than written inline, so no loop variable is left untyped.
const SIGNS: PackedFloat32Array = [-1.0, 1.0]

var _built: Array[Node3D] = []
## Set while a whole config dictionary lands, so three keys cost one rebuild, not three.
var _bulk: bool = false
## The population of the cell currently being built. Vector2 is (x, z) in field metres.
var _pts: PackedVector2Array = PackedVector2Array()
var _lab: PackedInt32Array = PackedInt32Array()
## Which cohort that population belongs to. Read by the k-means seed rather than the
## `cohort` export, because layout=ladder builds five cells in one pass and seeding off
## the export would give all five the same initialisation.
var _pop: String = "blobs"


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("cohort"):
		cohort = str(config_data["cohort"])
	if config_data.has("cut"):
		cut = str(config_data["cut"])
	_bulk = false
	_rebuild()


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
		names = COHORTS.duplicate()
	else:
		names.append(_pick(cohort, COHORTS, "blobs"))
	var which: String = _pick(cut, CUTS, "centroid")
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Cell_" + names[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_stage(holder)
		_build_population(names[i])
		_draw_population(holder, which)
		_draw_cut(holder, which, names[i])


# ── the population ─────────────────────────────────────────────────────────────────────

## THE SEED IS KEYED TO THE POPULATION, NOT TO THE COHORT, and that one line is what makes
## the designed null real. `skew` returns `block`'s index, so the two values draw the same
## lattice out of the same generator in the same order and differ only in their labels.
## Seeding off the cohort index instead would give them two different jitters, the null
## would break, and the break would be a fact about a seed rather than about supervision.
func _population_seed(who: String) -> int:
	var idx: int = COHORTS.find(who)
	if who == "skew":
		idx = COHORTS.find("block")
	if idx < 0:
		idx = 0
	return DATA_SEED + idx * 1013


func _build_population(who: String) -> void:
	_pts = PackedVector2Array()
	_lab = PackedInt32Array()
	_pop = who
	var rng := RandomNumberGenerator.new()
	rng.seed = _population_seed(who)
	match who:
		"block":
			_gen_lattice(rng, false)
		"skew":
			_gen_lattice(rng, true)
		"rings":
			_gen_rings(rng)
		"braid":
			_gen_braid(rng)
		_:
			_gen_blobs(rng)


## blobs — 60 points in the right disc, then the EXACT MIRROR of those 60 on the left.
## The mirror is the mechanism: it makes the gap symmetric about x = 0, which makes the
## only zero-impurity axis-aligned split land at exactly 0.000, and makes the widest-gap
## direction exactly x-hat. Both the `axis` cut and the `margin` decision plane are then
## the same wall to the millimetre, which is the pre-registered closest pair.
func _gen_blobs(rng: RandomNumberGenerator) -> void:
	var right: PackedVector2Array = PackedVector2Array()
	for i in range(BLOB_N):
		var a: float = rng.randf() * TAU
		# sqrt of a uniform draw keeps the disc evenly covered instead of piling points
		# at the centre — the same correction all three members make.
		var r: float = sqrt(rng.randf()) * BLOB_R
		right.append(Vector2(BLOB_CX + cos(a) * r, sin(a) * r))
	for i in range(right.size()):
		_pts.append(right[i])
		_lab.append(1)
	for i in range(right.size()):
		_pts.append(Vector2(-right[i].x, right[i].y))
		_lab.append(0)


## block and skew — ONE POPULATION, TWO LABELLINGS. A 12 x 10 lattice at 0.070 x 0.084 m
## pitch fills the field with no hole anywhere; the dot is jittered inside its own cell but
## the LABEL is read off the cell centre, so the seam stays a clean staircase instead of a
## fringe. That split is svm_visualization's own repair, and the reason it had to make it
## is in `declines`.
##   block  x + z >= 0 at the cell centre. Comes out at exactly 60 and 60 — counted, not
##          hoped: 1+2+3+4+5+7+8+9+10+11 over the ten rows.
##   skew   the six cells inside the corner box x >= 0.21, z >= 0.25 are the minority —
##          columns 9, 10, 11 by rows 8, 9 — and the other 114 are the majority. All six
##          are ALSO class 1 under block's labelling, so the two labellings agree on 66
##          points and disagree on 54. Counted on the replica, not assumed.
func _gen_lattice(rng: RandomNumberGenerator, minority_only: bool) -> void:
	var step_x: float = FIELD_HALF * 2.0 / float(LAT_COLS)
	var step_z: float = FIELD_HALF * 2.0 / float(LAT_ROWS)
	var centres: PackedVector2Array = PackedVector2Array()
	for j in range(LAT_ROWS):
		for i in range(LAT_COLS):
			var cx: float = -FIELD_HALF + (float(i) + 0.5) * step_x
			var cz: float = -FIELD_HALF + (float(j) + 0.5) * step_z
			centres.append(Vector2(cx, cz))
			_pts.append(Vector2(
				cx + rng.randf_range(-LAT_JITTER, LAT_JITTER),
				cz + rng.randf_range(-LAT_JITTER, LAT_JITTER)))
			_lab.append(0)
	if not minority_only:
		for i in range(centres.size()):
			var side: float = centres[i].x / FIELD_HALF + centres[i].y / FIELD_HALF
			_lab[i] = 1 if side >= 0.0 else 0
		return
	# The corner box, read off the cell centre so the jitter cannot change who is in it.
	for i in range(centres.size()):
		if centres[i].x >= SKEW_POCKET_X and centres[i].y >= SKEW_POCKET_Z:
			_lab[i] = 1


## rings — a core inside a shell, split 40/60 exactly as all three members split it.
## The core is the minority class, so `margin` is being asked for a straight line that
## separates a disc from what surrounds it, which does not exist at any angle.
func _gen_rings(rng: RandomNumberGenerator) -> void:
	for i in range(RING_CORE_N):
		var a: float = rng.randf() * TAU
		var r: float = sqrt(rng.randf()) * RING_DISC
		_pts.append(Vector2(cos(a) * r, sin(a) * r))
		_lab.append(1)
	var half_wall: float = RING_WALL * 0.5
	var step: float = TAU / float(RING_SHELL_N)
	for i in range(RING_SHELL_N):
		# Evenly spaced with a sub-spacing jitter, so the shell reads as a shell rather
		# than as a random annulus — enhanced_kmeans' correction, kept.
		var a2: float = float(i) * step + rng.randf_range(-step * 0.35, step * 0.35)
		var r2: float = RING_MEAN + rng.randf_range(-half_wall, half_wall)
		_pts.append(Vector2(cos(a2) * r2, sin(a2) * r2))
		_lab.append(0)


## braid — two sine bands 0.05 m apart. x is stratified (evenly spaced, not sampled) so
## the bands read as bands; only the cross-band scatter is random. Every straight cut
## through the field crosses both classes four times.
func _gen_braid(rng: RandomNumberGenerator) -> void:
	for band in range(2):
		var label: int = 1 if band == 0 else 0
		var offset: float = BRAID_SEP * 0.5 * (1.0 if band == 0 else -1.0)
		for i in range(BRAID_N):
			var x: float = -FIELD_HALF + (float(i) + 0.5) / float(BRAID_N) \
				* FIELD_HALF * 2.0
			var base: float = BRAID_AMP * sin(TAU * x / BRAID_PERIOD)
			_pts.append(Vector2(x, base + offset
				+ rng.randf_range(-BRAID_JITTER, BRAID_JITTER)))
			_lab.append(label)


# ── the three cuts ─────────────────────────────────────────────────────────────────────

## centroid — k-means at the member's own k = 4, then the VORONOI of what it converged to.
## k-means++ initialisation from the same seeded generator, Lloyd to a fixed point or 40
## iterations, an empty cluster keeps its site rather than teleporting.
## THIS FUNCTION NEVER READS `_lab`. That is the whole point of the value and the whole
## mechanism of the designed null.
func _kmeans_sites() -> PackedVector2Array:
	var n: int = _pts.size()
	var sites: PackedVector2Array = PackedVector2Array()
	if n == 0:
		return sites
	var rng := RandomNumberGenerator.new()
	rng.seed = _population_seed(_pop) + 7717
	sites.append(_pts[rng.randi() % n])
	while sites.size() < KMEANS_K:
		var d2: PackedFloat32Array = PackedFloat32Array()
		var total: float = 0.0
		for i in range(n):
			var best: float = 1000000.0
			for s in range(sites.size()):
				var dd: float = _pts[i].distance_squared_to(sites[s])
				if dd < best:
					best = dd
			d2.append(best)
			total += best
		var target: float = rng.randf() * total
		var acc: float = 0.0
		var chosen: int = n - 1
		for i in range(n):
			acc += d2[i]
			if acc >= target:
				chosen = i
				break
		sites.append(_pts[chosen])

	var assign: PackedInt32Array = PackedInt32Array()
	assign.resize(n)
	for i in range(n):
		assign[i] = -1
	for step in range(KMEANS_ITERS):
		var moved: bool = false
		for i in range(n):
			var pick: int = 0
			var bd: float = 1000000.0
			for s in range(KMEANS_K):
				var dd2: float = _pts[i].distance_squared_to(sites[s])
				if dd2 < bd:
					bd = dd2
					pick = s
			if assign[i] != pick:
				assign[i] = pick
				moved = true
		var sums: PackedVector2Array = PackedVector2Array()
		var counts: PackedInt32Array = PackedInt32Array()
		for s in range(KMEANS_K):
			sums.append(Vector2.ZERO)
			counts.append(0)
		for i in range(n):
			var a: int = assign[i]
			sums[a] = sums[a] + _pts[i]
			counts[a] = counts[a] + 1
		for s in range(KMEANS_K):
			if counts[s] > 0:
				sites[s] = sums[s] / float(counts[s])
		if not moved:
			break
	return sites


## Sutherland-Hodgman against ONE half-plane: keep p where (p - m) dot d <= 0. Every
## Voronoi cell is the field square clipped by one such half-plane per rival site, which is
## the definition of the cell and not an approximation of it.
func _clip_half(poly: PackedVector2Array, m: Vector2, d: Vector2) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var n: int = poly.size()
	if n == 0:
		return out
	for i in range(n):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % n]
		var da: float = (a - m).dot(d)
		var db: float = (b - m).dot(d)
		var a_in: bool = da <= 0.0
		var b_in: bool = db <= 0.0
		if a_in:
			out.append(a)
		if a_in != b_in:
			var denom: float = da - db
			if absf(denom) > 0.0000001:
				out.append(a + (b - a) * (da / denom))
	return out


## Every interior Voronoi edge, once. Edges lying ON the field boundary are dropped — the
## square is the stage, not an answer — and each shared bisector is deduped so two adjacent
## cells do not stack two coincident walls and z-fight.
func _voronoi_walls(sites: PackedVector2Array) -> Array:
	var walls: Array = []
	var seen: Dictionary = {}
	var square: PackedVector2Array = PackedVector2Array([
		Vector2(-FIELD_HALF, -FIELD_HALF), Vector2(FIELD_HALF, -FIELD_HALF),
		Vector2(FIELD_HALF, FIELD_HALF), Vector2(-FIELD_HALF, FIELD_HALF)])
	for i in range(sites.size()):
		var poly: PackedVector2Array = square.duplicate()
		for j in range(sites.size()):
			if j == i:
				continue
			var mid: Vector2 = (sites[i] + sites[j]) * 0.5
			poly = _clip_half(poly, mid, sites[j] - sites[i])
			if poly.size() < 3:
				break
		if poly.size() < 3:
			continue
		for e in range(poly.size()):
			var a: Vector2 = poly[e]
			var b: Vector2 = poly[(e + 1) % poly.size()]
			if _on_field_edge(a) and _on_field_edge(b) and _same_field_edge(a, b):
				continue
			var key: String = _edge_key(a, b)
			if seen.has(key):
				continue
			seen[key] = true
			walls.append([a, b])
	return walls


func _on_field_edge(p: Vector2) -> bool:
	return absf(absf(p.x) - FIELD_HALF) < 0.0005 or absf(absf(p.y) - FIELD_HALF) < 0.0005


func _same_field_edge(a: Vector2, b: Vector2) -> bool:
	if absf(a.x - b.x) < 0.0005 and absf(absf(a.x) - FIELD_HALF) < 0.0005:
		return true
	return absf(a.y - b.y) < 0.0005 and absf(absf(a.y) - FIELD_HALF) < 0.0005


func _edge_key(a: Vector2, b: Vector2) -> String:
	var ka: String = "%.4f,%.4f" % [a.x, a.y]
	var kb: String = "%.4f,%.4f" % [b.x, b.y]
	if ka <= kb:
		return ka + "|" + kb
	return kb + "|" + ka


## axis — one CART at the forest's own depth 5 and min_samples_split 2, Gini, candidate
## splits at the midpoints of consecutive distinct values. A node draws ONE wall and that
## wall spans only the node's own rectangle, which is what turns the recursion into a
## staircase instead of a set of full-width lines.
func _tree_walls() -> Array:
	var walls: Array = []
	var idx: PackedInt32Array = PackedInt32Array()
	for i in range(_pts.size()):
		idx.append(i)
	_grow(idx, -FIELD_HALF, FIELD_HALF, -FIELD_HALF, FIELD_HALF, 0, walls)
	return walls


func _gini(ones: int, total: int) -> float:
	if total <= 0:
		return 0.0
	var p: float = float(ones) / float(total)
	return 2.0 * p * (1.0 - p)


func _grow(idx: PackedInt32Array, x0: float, x1: float, z0: float, z1: float,
		depth: int, walls: Array) -> void:
	var n: int = idx.size()
	if depth >= TREE_MAX_DEPTH or n < TREE_MIN_SPLIT:
		return
	var ones: int = 0
	for i in range(n):
		ones += _lab[idx[i]]
	var parent: float = _gini(ones, n)
	if parent <= 0.0:
		return

	var best_gain: float = 0.0
	var best_feature: int = -1
	var best_value: float = 0.0
	for feature in range(2):
		var rows: Array = []
		for i in range(n):
			var p: Vector2 = _pts[idx[i]]
			var value: float = p.x if feature == 0 else p.y
			rows.append([value, float(_lab[idx[i]])])
		rows.sort_custom(func(u, w): return u[0] < w[0])
		var left_ones: int = 0
		for s in range(1, n):
			left_ones += int(rows[s - 1][1])
			var lo: float = float(rows[s - 1][0])
			var hi: float = float(rows[s][0])
			if hi - lo < 0.0000001:
				continue
			var weighted: float = (float(s) * _gini(left_ones, s)
				+ float(n - s) * _gini(ones - left_ones, n - s)) / float(n)
			var gain: float = parent - weighted
			if gain > best_gain + 0.0000001:
				best_gain = gain
				best_feature = feature
				best_value = (lo + hi) * 0.5
	if best_feature < 0:
		return

	var left: PackedInt32Array = PackedInt32Array()
	var right: PackedInt32Array = PackedInt32Array()
	for i in range(n):
		var p2: Vector2 = _pts[idx[i]]
		var v2: float = p2.x if best_feature == 0 else p2.y
		if v2 <= best_value:
			left.append(idx[i])
		else:
			right.append(idx[i])
	if left.is_empty() or right.is_empty():
		return

	if best_feature == 0:
		walls.append([Vector2(best_value, z0), Vector2(best_value, z1)])
		_grow(left, x0, best_value, z0, z1, depth + 1, walls)
		_grow(right, best_value, x1, z0, z1, depth + 1, walls)
	else:
		walls.append([Vector2(x0, best_value), Vector2(x1, best_value)])
		_grow(left, x0, x1, z0, best_value, depth + 1, walls)
		_grow(right, x0, x1, best_value, z1, depth + 1, walls)


## margin — the linear branch of svm_visualization's kernel_function, solved by exhaustive
## search over 180 directions rather than by SMO, because SMO's answer depends on how many
## timer ticks have elapsed and a still cannot wait. FEWEST ERRORS FIRST, THEN WIDEST GAP:
## the second half of that rule is what makes it a MARGIN method rather than merely an
## accuracy method, and it is the only place the word margin earns its keep. Returns the
## normal, the offset, and half the gap it found.
func _linear_cut() -> Dictionary:
	var n: int = _pts.size()
	var out: Dictionary = {"ok": false, "w": Vector2.RIGHT, "b": 0.0, "m": MARGIN_MIN}
	if n < 2:
		return out
	var ones_total: int = 0
	for i in range(n):
		ones_total += _lab[i]
	var best_err: int = n + 1
	var best_gap: float = -1.0
	for a in range(MARGIN_DIRECTIONS):
		var theta: float = float(a) * PI / float(MARGIN_DIRECTIONS)
		var w: Vector2 = Vector2(cos(theta), sin(theta))
		var rows: Array = []
		for i in range(n):
			rows.append([_pts[i].dot(w), float(_lab[i])])
		rows.sort_custom(func(u, v): return u[0] < v[0])
		var ones_left: int = 0
		for s in range(1, n):
			ones_left += int(rows[s - 1][1])
			var lo: float = float(rows[s - 1][0])
			var hi: float = float(rows[s][0])
			var gap: float = hi - lo
			if gap < 0.0000001:
				continue
			# Orientation A: label 0 on the low side. Orientation B is its complement, so
			# the error count of the better orientation is min(e, n - e).
			var e: int = ones_left + ((n - s) - (ones_total - ones_left))
			var err: int = mini(e, n - e)
			if err < best_err or (err == best_err and gap > best_gap):
				best_err = err
				best_gap = gap
				out["ok"] = true
				out["w"] = w
				out["b"] = (lo + hi) * 0.5
				out["m"] = clampf(gap * 0.5, MARGIN_MIN, MARGIN_MAX)
	return out


## The line {p : p dot w = b}, clipped to the field square. Returns an empty array when the
## line misses the square entirely, which is how an offset margin plane declines to draw.
func _clip_line(w: Vector2, b: float) -> Array:
	var u: Vector2 = Vector2(-w.y, w.x)
	var p0: Vector2 = w * b
	var t_lo: float = -1000.0
	var t_hi: float = 1000.0
	for axis in range(2):
		var du: float = u.x if axis == 0 else u.y
		var dp: float = p0.x if axis == 0 else p0.y
		if absf(du) < 0.0000001:
			if absf(dp) > FIELD_HALF:
				return []
			continue
		var ta: float = (-FIELD_HALF - dp) / du
		var tb: float = (FIELD_HALF - dp) / du
		t_lo = maxf(t_lo, minf(ta, tb))
		t_hi = minf(t_hi, maxf(ta, tb))
	if t_hi - t_lo < 0.0005:
		return []
	return [p0 + u * t_lo, p0 + u * t_hi]


# ── drawing ────────────────────────────────────────────────────────────────────────────

func _build_stage(holder: Node3D) -> void:
	var plate := SurfaceTool.new()
	plate.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(plate, Vector3(0.0, PLATE_T * 0.5, 0.0),
		Vector3(PLATE_HALF * 2.0, PLATE_T, PLATE_HALF * 2.0))
	_commit(holder, "Plate", plate, C_PLATE, 0.95, 0.0)

	var posts := SurfaceTool.new()
	posts.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sx in SIGNS:
		for sz in SIGNS:
			_add_box(posts,
				Vector3(sx * CORNER_INSET, PLATE_T + WALL_H * 0.5, sz * CORNER_INSET),
				Vector3(CORNER_W, WALL_H, CORNER_W))
	_commit(holder, "CornerPosts", posts, C_CORNER, 0.80, 0.0)


func _draw_population(holder: Node3D, which: String) -> void:
	if which == "centroid":
		var neutral := SurfaceTool.new()
		neutral.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(_pts.size()):
			_add_post(neutral, _pts[i], POST_U)
		_commit(holder, "Unlabelled", neutral, C_UNLAB, 0.55, 0.0)
		return
	var short_st := SurfaceTool.new()
	short_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tall_st := SurfaceTool.new()
	tall_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(_pts.size()):
		if _lab[i] == 1:
			_add_post(tall_st, _pts[i], POST_B)
		else:
			_add_post(short_st, _pts[i], POST_A)
	_commit(holder, "ClassA", short_st, C_CLASS_A, 0.55, 0.0)
	_commit(holder, "ClassB", tall_st, C_CLASS_B, 0.55, 0.0)


func _draw_cut(holder: Node3D, which: String, who: String) -> void:
	var body := SurfaceTool.new()
	body.begin(Mesh.PRIMITIVE_TRIANGLES)
	var drew: bool = false
	if which == "axis":
		var tw: Array = _tree_walls()
		for i in range(tw.size()):
			var seg: Array = tw[i]
			_add_wall(body, seg[0], seg[1], WALL_H, WALL_T)
			drew = true
	elif which == "margin":
		var fit: Dictionary = _linear_cut()
		if bool(fit["ok"]):
			var w: Vector2 = fit["w"]
			var b: float = float(fit["b"])
			var line: Array = _clip_line(w, b)
			if line.size() == 2:
				_add_wall(body, line[0], line[1], WALL_H, WALL_T)
				drew = true
			var edges := SurfaceTool.new()
			edges.begin(Mesh.PRIMITIVE_TRIANGLES)
			var any_edge: bool = false
			for s in SIGNS:
				var side: Array = _clip_line(w, b + float(s) * float(fit["m"]))
				if side.size() == 2:
					_add_wall(edges, side[0], side[1], MARGIN_H, MARGIN_T)
					any_edge = true
			if any_edge:
				_commit(holder, "MarginPlanes", edges, C_MARGIN, 0.70, 0.0)
	else:
		var sites: PackedVector2Array = _kmeans_sites()
		var vw: Array = _voronoi_walls(sites)
		for i in range(vw.size()):
			var edge: Array = vw[i]
			_add_wall(body, edge[0], edge[1], WALL_H, WALL_T)
			drew = true
	if drew:
		_commit(holder, "Cut_" + which + "_" + who, body, C_WALL, 0.70, 0.0)


## One data point, as a square post standing on the plate. A post rather than a sphere
## because height is one of the two channels class is carried in, and because a 0.02 m
## sphere is about two pixels once the critic crops and resizes to 160 x 160 — the exact
## resolution failure random_forest_visualization had to repair with drawn volumes.
func _add_post(st: SurfaceTool, p: Vector2, h: float) -> void:
	_add_box(st, Vector3(p.x, PLATE_T + h * 0.5, p.y), Vector3(POST_W, h, POST_W))


## A wall standing on the plate along the 2D segment a -> b: an oriented box, twelve
## triangles, wound outward from its own centre.
func _add_wall(st: SurfaceTool, a: Vector2, b: Vector2, h: float, t: float) -> void:
	var d: Vector2 = b - a
	if d.length() < 0.0008:
		return
	var nrm: Vector2 = Vector2(-d.y, d.x).normalized() * (t * 0.5)
	var y0: float = PLATE_T
	var y1: float = PLATE_T + h
	var p: PackedVector3Array = PackedVector3Array([
		Vector3(a.x + nrm.x, y0, a.y + nrm.y), Vector3(b.x + nrm.x, y0, b.y + nrm.y),
		Vector3(b.x + nrm.x, y1, b.y + nrm.y), Vector3(a.x + nrm.x, y1, a.y + nrm.y),
		Vector3(a.x - nrm.x, y0, a.y - nrm.y), Vector3(b.x - nrm.x, y0, b.y - nrm.y),
		Vector3(b.x - nrm.x, y1, b.y - nrm.y), Vector3(a.x - nrm.x, y1, a.y - nrm.y)])
	var c: Vector3 = Vector3((a.x + b.x) * 0.5, (y0 + y1) * 0.5, (a.y + b.y) * 0.5)
	_quad(st, p[0], p[1], p[2], p[3], c)
	_quad(st, p[5], p[4], p[7], p[6], c)
	_quad(st, p[3], p[2], p[6], p[7], c)
	_quad(st, p[4], p[5], p[1], p[0], c)
	_quad(st, p[1], p[5], p[6], p[2], c)
	_quad(st, p[4], p[0], p[3], p[7], c)


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


## Two triangles a -> b -> c -> d, with the normal taken from the winding and FLIPPED if it
## points back at `inside`. Every material here is CULL_DISABLED as well, so a wall whose
## quad happened to wind inward is still drawn rather than becoming a hole in the picture.
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
		rough: float, metal: float) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = m
	holder.add_child(mi)
