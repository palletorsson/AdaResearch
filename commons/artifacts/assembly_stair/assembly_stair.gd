extends Node3D
class_name AssemblyStair

## assembly_stair — twelve parts, three objects, and the word `assembly` doing three
## different jobs that only a PART COUNT can tell apart.
##
## THE FAMILY. Three artifacts declare an axis called `assembly` and between them spend
## eleven words, none of which appears in more than two lists:
##
##   cube_staircase   treads | steps | stringers | full
##   recursive_table  cells | slab | legs | full
##   bricoleur_golem  figure | lashed | cairn | heap
##
## The brief this bench was built from said the axis holds TWO things: a decomposition
## (which parts are shown — the first two members) and a degree of assembly (how organised
## the whole set is — the third). THE CODE SAYS THREE, and the discriminator is countable.
## Counted at each member's shipped defaults (step_count = 6, keep = corners):
##
##   cube_staircase   treads 6 meshes → steps 11 → stringers 13 → full 26.
##                    STRICTLY ADDITIVE AND STRICTLY NESTED. Every non-`full` value OMITS
##                    parts — _shows_risers / _shows_stringers / _shows_handrail return
##                    false and _create_part is never called, so the parts do not exist,
##                    they are not merely de-emphasised. treads ⊂ steps ⊂ stringers ⊂ full.
##                    A TRUE DECOMPOSITION.
##   recursive_table  cells 13 meshes → slab 5 → legs 5 → full 9.
##                    NON-MONOTONE AND NOT NESTED. Step 2 DESTROYS nine tabletop cells and
##                    creates one slab (13 → 5); step 3 adds nothing at all, it rewrites
##                    box.size and position.y on four cells already standing (5 → 5); only
##                    step 4 adds (+4 apron). So `cells` is not a subset of `full` — the
##                    nine cells it shows are gone by the time `full` exists. A DERIVATION,
##                    which is a different animal wearing the same word.
##   bricoleur_golem  figure 6 → lashed 6 → cairn 6 → heap 6.
##                    CONSTANT. All four call _build_random_part(i) for i in 0..5; the only
##                    thing that changes is which of four literal position tables is read
##                    and whether a cant is applied. Its own comment says it: "Same six
##                    parts, same six sizes — only the joinery changes." A DEGREE.
##
## SO THE COUNT IS THE INSTRUMENT. A decomposition draws a SUBSET and its count rises to
## the terminal value. A derivation's count goes down and up because parts are replaced
## rather than added. A degree ALWAYS draws the whole set and never fewer. That is why the
## brief's demand — state how many pieces exist and how many are drawn — is not bookkeeping
## but the whole argument.
##
## AND WHY bricoleur_golem HAS NO `full`, sharpened. Not because a heap is not a partial
## assembly (true but not the reason). Because `figure` IS its full: the complete set in
## its intended arrangement, shipped as the default, named with a degree word instead of a
## completeness word. The family does not lack a terminal value; it has one under another
## vocabulary. See `declines` for why this bench does not spend three cells proving it.
##
## THE THESIS, and a reasonable person can disagree with it: A DECOMPOSITION VOCABULARY
## DOES NOT TRAVEL BETWEEN OBJECTS; ONLY ITS TERMINAL VALUE DOES. The two members that
## share this axis share exactly ONE word — `full` — and rename every other rung, because
## a part name is a fact about one object. recursive_table says so in its own header:
## "`assembly` is cube_staircase's word ... with its terminal value `full` — the same
## question with THIS OBJECT'S OWN PART NAMES." A degree vocabulary travels intact, because
## degree of order is a fact about arrangement and any set of parts can be more or less
## arranged. This bench crosses `assembly` against `object` to put a number on that.
##
## WHAT IS BUILT. TWELVE PARTS, three groups of four, THE SAME TWELVE IN EVERY ONE OF THE
## TWENTY-ONE CELLS — same sizes, same colours, same order. Only where they go changes.
## That law is bricoleur_golem's, adopted verbatim, and it is what makes the count legible.
##
##   4 DECKS  0.26 x 0.030 x 0.13   the horizontal plates
##   4 POSTS  0.060 x 0.26 x 0.060  the vertical members
##   4 TIES   0.26 x 0.024 x 0.024  the thin braces, added last
##
## `object` decides the arrangement — stair (treads / balusters / pitched side rails),
## table (top quadrants / corner legs / apron ring), figure (stacked trunk / two arms and
## two legs / lashing bands). `assembly` decides how many are drawn and in what state.
##
## THE LEDGER, and it is exact:
##   cells   8 of 12   decks + posts, ties absent            DECOMPOSITION
##   treads  4 of 12   the decks alone                       DECOMPOSITION
##   slab    4 of 12   the decks, MERGED into ONE mesh       DECOMPOSITION (derivation step)
##   legs    4 of 12   the posts alone                       DECOMPOSITION
##   full   12 of 12   every part, in its place              DECOMPOSITION (terminal)
##   lashed 12 of 12   every part, joints loosened           DEGREE
##   heap   12 of 12   every part, on the floor              DEGREE
## treads(4) + legs(4) = cells(8) by construction; cells(8) + 4 ties = full(12). The
## decomposition values form an additive ledger. THE DEGREE VALUES DO NOT ENTER IT: both
## draw 12, which is the definition and the reason no count can rank them.
##
## Deterministic: no randf, no noise, no _process, no Timer. Every position is a constant
## in a table, which is stronger than a seed because there is no stream to desynchronise.


## HOW MUCH OF THE SET IS SHOWING, AND IN WHAT STATE. Seven values, the honest union of
## three vocabularies, at least one from each member, and the registry `note` says which
## member each came from, whether it is a DECOMPOSITION or a DEGREE, and how many of the
## twelve parts it draws.
##
##   cells   recursive_table, DECOMPOSITION, 8 of 12. Its step 1: the kept parts standing
##           as separate blocks with no bracing. Here that is decks + posts, ties absent.
##   treads  cube_staircase, DECOMPOSITION, 4 of 12. The deck group alone — what the
##           subdivision yields before anything is closed or braced.
##   slab    recursive_table, DECOMPOSITION, 4 parts accounted, 1 MESH DRAWN. Its step 2,
##           which merges nine tabletop cells into one surface. THE ONLY VALUE IN THE SHEET
##           WHERE PART COUNT AND MESH COUNT DISAGREE, and that disagreement is the tell
##           that recursive_table's ladder is a derivation and not a decomposition.
##   legs    recursive_table, DECOMPOSITION, 4 of 12. The post group alone.
##   full    BOTH first members, and the ONLY word they share. DECOMPOSITION terminal,
##           12 of 12, every part in its place. NOT the banned all-rungs value: it does not
##           put every VALUE of the axis into one cell, it puts every PART of the object
##           into one cell, which is what a decomposition vocabulary is FOR. The banned
##           thing lives in `layout` below, out of the axis, pinned by the fixture.
##   lashed  bricoleur_golem, DEGREE, 12 of 12. Its second rung: "keeps the plan but lets
##           the joints show (canted, gapped)". Here each part is displaced and canted by
##           its own constant. Object-AWARE — it loosens THIS object's plan.
##   heap    bricoleur_golem, DEGREE, 12 of 12. Its last rung: "refuses to stand the parts
##           up at all — the pile that has not yet been made into anything." Its
##           HEAP_POSITIONS is a literal array that does not consult the body plan, so
##           heap is OBJECT-BLIND here too, by construction, and that is a designed null.
## (One line per declaration, deliberately over the column guide: check_dna_declarations.py
## matches `@export_enum(...)` and its `var` on the SAME line, and a wrapped declaration
## reports NO EXPORT — a declared axis the gate cannot verify.)
@export_enum("cells", "treads", "slab", "legs", "full", "lashed", "heap") var assembly: String = "full":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not ASSEMBLIES.has(picked):
			return                      ## an unreachable value keeps the standing object
		assembly = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## WHAT IS BEING ASSEMBLED. Three values, one per member, and this axis is the CHECK on the
## other one. A decomposition value should mean the same thing on all three objects — show
## me the deck group, show me the posts — and a degree value should mean the same thing too
## and yet produce a very different picture.
##
##   stair   cube_staircase. Decks ascend along +Z at 0.085 rise over 0.130 run; posts
##           stand on the treads as balusters at x = -0.215 (its own rail_offset is
##           -0.52 * stair_size, outside the stair, on one side only); ties are two pitched
##           side rails per flank, its stringer/handrail run.
##   table   recursive_table. Decks are four quadrants of one top; posts are corner legs at
##           +-1/3 of the top's span, which is its 3x3 corner-cell rule to the millimetre;
##           ties are the apron ring, inset from the legs as its own numbers are.
##   figure  bricoleur_golem. Decks stack as a trunk; two posts are legs and two are arms;
##           ties are bands across chest, shoulders and hips, and one across the crown.
##
## AND WHERE THE CHECK FAILS, said rather than smoothed over: `treads` is a GEOMETRIC role
## on all three — the horizontal plates — and a FUNCTIONAL word on exactly one. A tread is
## the surface you put your foot on. A tabletop is horizontal and you do not stand on it; a
## torso plate is horizontal and is not a surface at all. So the word transfers as far as
## "which parts" and no further, which is precisely why recursive_table imported `assembly`
## and `full` from one folder over and refused to import `treads`.
@export_enum("stair", "table", "figure") var object: String = "stair":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not OBJECTS.has(picked):
			return
		object = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One object, or all three in a row. NOT PART OF EITHER AXIS, and this is the wave-13
## lesson paid forward: capture_config_sweep unions the AABB across a spec's variants, so an
## all-objects value declared inside `object` would frame every single cell against two and
## a half metres and photograph a 0.010 m seam as nothing. The registry fixture pins
## `single`. `ladder` is a design view, never a map placement.
##
## NOTE WHICH ONE IS THE FAULT. `full` is not this. `full` shows every PART of one object at
## one value of one axis; `ladder` would show every VALUE of an axis at one value of that
## axis. The first is what a decomposition vocabulary means. The second makes every other
## value a subset of one cell and destroys the comparison.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const ASSEMBLIES: PackedStringArray = [
	"cells", "treads", "slab", "legs", "full", "lashed", "heap"]
const OBJECTS: PackedStringArray = ["stair", "table", "figure"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the twelve parts ───────────────────────────────────────────────────────────────────
## FIXED SIZES IN EVERY CELL. This is bricoleur_golem's law — "Same six parts, same six
## sizes — only the joinery changes" — and without it the count is not an instrument,
## because a part that changes size between objects makes `heap` a different pile per object
## and deletes the sheet's designed null.
const PART_TOTAL: int = 12
const DECK_N: int = 4
const POST_N: int = 4
const DECK_SIZE: Vector3 = Vector3(0.26, 0.030, 0.13)
const POST_SIZE: Vector3 = Vector3(0.060, 0.26, 0.060)
const TIE_SIZE: Vector3 = Vector3(0.26, 0.024, 0.024)

## Every colour is a member's, cited. Nothing here is chosen for the picture.
const C_DECK: Color = Color(0.65, 0.63, 0.60)    ## cube_staircase.gd:41 step_color
const C_POST: Color = Color(0.70, 0.72, 0.75)    ## recursive_table.gd:54 generation_colors[2]
const C_TIE: Color = Color(0.30, 0.25, 0.20)     ## cube_staircase.gd:44 rail_color
const C_PLATE: Color = Color(0.19, 0.20, 0.23)
const PART_METALLIC: float = 0.1                 ## cube_staircase.gd:245 _create_part
const PART_ROUGHNESS: float = 0.6                ## cube_staircase.gd:246 _create_part

# ── the stage, identical in all twenty-one cells ───────────────────────────────────────
## A bench top the parts stand on, and an INVISIBLE anchor that fixes the framing. The
## anchor is a MeshInstance3D with layers = 0: it is counted by capture_config_sweep's
## _subtree_aabb, which walks every MeshInstance3D and ignores layers, and it renders
## nothing. `visible = false` would NOT do — Godot visibility is hierarchical and a hidden
## node is still hidden when its AABB is wanted, but more to the point layers = 0 leaves
## mesh, material and AABB alone and touches only what draws.
##
## WITHOUT IT the camera would move: `treads` on the table is 0.53 x 0.030 x 0.27 and `full`
## on the stair is 0.412 x 0.545 x 0.520, a 4.5x spread in the diagonal, so twenty-one cells
## would be twenty-one focal lengths and every measured pair would be reporting zoom.
const PLATE_HALF: float = 0.34
const PLATE_T: float = 0.016
const ANCHOR_SIZE: Vector3 = Vector3(0.68, 0.58, 0.68)
const ANCHOR_CENTRE: Vector3 = Vector3(0.0, 0.29, 0.0)

## The stair's geometry, and the two numbers the whole object is made of.
const RISE: float = 0.085
const RUN: float = 0.13
## atan2(RISE, RUN) = 0.578885 rad = 33.17 deg. Written as a constant because a `var x :=
## atan2(...)` at file scope is not a constant expression and a const cannot call it.
const STAIR_PITCH: float = 0.578885
const QUARTER: float = 1.570796

# ── the three objects, and the pile ────────────────────────────────────────────────────
## Indices 0-3 are the decks, 4-7 the posts, 8-11 the ties, in every table. Rotations are
## Godot's default YXZ Euler, so basis = Ry(y) * Rx(x) * Rz(z): a tie laid along Z is
## (0, QUARTER, 0) and a tie laid along Z and pitched up with +Z is (0, QUARTER, -pitch).
##
## FOUR LITERAL TABLES IS bricoleur_golem's OWN CONSTRUCTION — SLOT_POSITIONS,
## LASHED_POSITIONS, CAIRN_POSITIONS, HEAP_POSITIONS — and it is used here for the same
## reason it works there: a table cannot desynchronise, so two builds of one cell are the
## same object down to the float.
const STAIR_POS: Array[Vector3] = [
	Vector3(0.0, 0.031, -0.195), Vector3(0.0, 0.116, -0.065),
	Vector3(0.0, 0.201, 0.065), Vector3(0.0, 0.286, 0.195),
	Vector3(-0.215, 0.176, -0.195), Vector3(-0.215, 0.261, -0.065),
	Vector3(-0.215, 0.346, 0.065), Vector3(-0.215, 0.431, 0.195),
	Vector3(-0.155, 0.105, -0.115), Vector3(-0.155, 0.2554, 0.115),
	Vector3(0.155, 0.105, -0.115), Vector3(0.155, 0.2554, 0.115),
]
const STAIR_ROT: Array[Vector3] = [
	Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO,
	Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO,
	Vector3(0.0, QUARTER, -STAIR_PITCH), Vector3(0.0, QUARTER, -STAIR_PITCH),
	Vector3(0.0, QUARTER, -STAIR_PITCH), Vector3(0.0, QUARTER, -STAIR_PITCH),
]

const TABLE_POS: Array[Vector3] = [
	Vector3(-0.135, 0.291, -0.070), Vector3(0.135, 0.291, -0.070),
	Vector3(-0.135, 0.291, 0.070), Vector3(0.135, 0.291, 0.070),
	Vector3(-0.177, 0.146, -0.115), Vector3(0.177, 0.146, -0.115),
	Vector3(-0.177, 0.146, 0.115), Vector3(0.177, 0.146, 0.115),
	Vector3(0.0, 0.248, -0.115), Vector3(0.0, 0.248, 0.115),
	Vector3(-0.177, 0.248, 0.0), Vector3(0.177, 0.248, 0.0),
]
const TABLE_ROT: Array[Vector3] = [
	Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO,
	Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO,
	Vector3.ZERO, Vector3.ZERO,
	Vector3(0.0, QUARTER, 0.0), Vector3(0.0, QUARTER, 0.0),
]

const FIGURE_POS: Array[Vector3] = [
	Vector3(0.0, 0.290, 0.0), Vector3(0.0, 0.336, 0.0),
	Vector3(0.0, 0.382, 0.0), Vector3(0.0, 0.428, 0.0),
	Vector3(-0.075, 0.146, 0.0), Vector3(0.075, 0.146, 0.0),
	Vector3(-0.160, 0.313, 0.0), Vector3(0.160, 0.313, 0.0),
	Vector3(0.0, 0.313, 0.078), Vector3(0.0, 0.402, -0.078),
	Vector3(0.0, 0.252, 0.0), Vector3(0.0, 0.462, 0.0),
]
const FIGURE_ROT: Array[Vector3] = [
	Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO,
	Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO,
	Vector3.ZERO, Vector3.ZERO, Vector3.ZERO,
	Vector3(0.0, QUARTER, 0.0),
]

## THE PILE, AND IT DOES NOT KNOW WHAT THE PARTS WERE GOING TO BE. bricoleur_golem's
## HEAP_POSITIONS is a literal array consulted instead of the body plan, not derived from
## it, so its heap is the same heap whatever the golem was. That is kept here exactly, which
## is what makes `heap` identical across all three objects — the sheet's designed null and
## half its argument.
##
## CAPPED ON PURPOSE. A pile spreads: this one is 0.613 x 0.188 x 0.546 against the stair's
## 0.412 x 0.545 x 0.520 and the table's 0.530 x 0.290 x 0.290 — wider than either and much
## flatter, which is what a heap is. The cap is that nothing leaves the 0.68 m plate and
## nothing drops below y = 0.013, so the anchor still bounds every cell and the camera
## never moves. An uncapped scatter took the framing with it in the first build.
const HEAP_POS: Array[Vector3] = [
	Vector3(-0.120, 0.045, -0.100), Vector3(0.100, 0.037, -0.140),
	Vector3(-0.050, 0.098, 0.060), Vector3(0.140, 0.031, 0.120),
	Vector3(-0.190, 0.045, 0.020), Vector3(0.180, 0.045, -0.050),
	Vector3(-0.020, 0.090, -0.020), Vector3(0.060, 0.110, 0.180),
	Vector3(-0.160, 0.028, -0.200), Vector3(0.160, 0.028, 0.030),
	Vector3(0.000, 0.115, 0.100), Vector3(-0.225, 0.028, 0.140),
]
const HEAP_ROT: Array[Vector3] = [
	Vector3(0.06, 0.35, 0.10), Vector3(0.0, -0.90, -0.05),
	Vector3(0.0, 1.15, 0.55), Vector3(0.0, 2.20, 0.0),
	Vector3(0.0, 0.30, QUARTER), Vector3(0.0, -0.85, QUARTER),
	Vector3(0.25, 1.90, 1.35), Vector3(0.0, 2.70, 1.05),
	Vector3(0.0, 0.55, 0.0), Vector3(0.0, -1.25, 0.0),
	Vector3(0.0, 1.05, 0.42), Vector3(0.0, 2.35, 0.0),
]

## `lashed` — the object's OWN plan with every joint loosened. Per part: a displacement and
## a cant, both constants. bricoleur_golem draws its cant from _rng.randf_range(-0.45, 0.45);
## these are capped to 0.26 rad so the loosened object stays inside the anchor, and they are
## constants rather than a seeded stream because a seed is only as reproducible as the number
## of draws taken before it — which is exactly the trap its own comment guards against when
## it takes three draws whether or not the value uses them.
const LASH_OFFSET: Array[Vector3] = [
	Vector3(0.014, 0.026, -0.012), Vector3(-0.011, 0.008, 0.013),
	Vector3(0.012, 0.011, 0.010), Vector3(-0.013, 0.007, -0.011),
	Vector3(-0.016, 0.005, 0.012), Vector3(0.015, 0.006, -0.013),
	Vector3(0.013, 0.009, 0.014), Vector3(-0.014, 0.004, -0.012),
	Vector3(0.010, 0.012, -0.010), Vector3(-0.012, 0.010, 0.011),
	Vector3(0.011, 0.013, 0.012), Vector3(-0.010, 0.011, -0.013),
]
const LASH_CANT: Array[Vector3] = [
	Vector3(0.10, 0.22, -0.14), Vector3(-0.13, -0.18, 0.11),
	Vector3(0.08, 0.26, 0.15), Vector3(-0.11, -0.24, -0.09),
	Vector3(0.15, 0.12, 0.19), Vector3(-0.16, -0.14, -0.21),
	Vector3(0.12, 0.20, -0.17), Vector3(-0.09, -0.22, 0.13),
	Vector3(0.18, 0.16, 0.10), Vector3(-0.14, -0.10, -0.16),
	Vector3(0.11, 0.24, 0.14), Vector3(-0.17, -0.20, -0.12),
]

const LADDER_PITCH: float = 0.90
## The eight corners of a unit half-box, as Vector3 rather than as three nested loops over a
## PackedFloat32Array, so that every value read inside `_build_slab` is explicitly typed and
## no arithmetic happens on an untyped loop variable.
const CORNER_SIGNS: Array[Vector3] = [
	Vector3(-1.0, -1.0, -1.0), Vector3(-1.0, -1.0, 1.0),
	Vector3(-1.0, 1.0, -1.0), Vector3(-1.0, 1.0, 1.0),
	Vector3(1.0, -1.0, -1.0), Vector3(1.0, -1.0, 1.0),
	Vector3(1.0, 1.0, -1.0), Vector3(1.0, 1.0, 1.0),
]

var _built: Array[Node3D] = []
## Set while a whole config dictionary lands, so three keys cost one rebuild, not three.
var _bulk: bool = false


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("object"):
		object = str(config_data["object"])
	if config_data.has("assembly"):
		assembly = str(config_data["assembly"])
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
		names = OBJECTS.duplicate()
	else:
		names.append(_pick(object, OBJECTS, "stair"))
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Cell_" + names[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_stage(holder)
		_build_parts(holder, names[i])


# ── the tables ─────────────────────────────────────────────────────────────────────────

## WHERE THE TWELVE GO. `heap` answers with a table that never looks at the object; every
## other value answers with the object's own.
func _positions_for(obj: String) -> Array[Vector3]:
	if assembly == "heap":
		return HEAP_POS
	match obj:
		"table":
			return TABLE_POS
		"figure":
			return FIGURE_POS
	return STAIR_POS


func _rotations_for(obj: String) -> Array[Vector3]:
	if assembly == "heap":
		return HEAP_ROT
	match obj:
		"table":
			return TABLE_ROT
		"figure":
			return FIGURE_ROT
	return STAIR_ROT


## The size of part i, by group. Never a function of the object or the assembly.
func _size_of(i: int) -> Vector3:
	if i < DECK_N:
		return DECK_SIZE
	if i < DECK_N + POST_N:
		return POST_SIZE
	return TIE_SIZE


func _colour_of(i: int) -> Color:
	if i < DECK_N:
		return C_DECK
	if i < DECK_N + POST_N:
		return C_POST
	return C_TIE


## WHICH OF THE TWELVE ARE DRAWN. This function IS the axis: everything else is where the
## parts sit. The returned count is the number in the registry `note`, and it is the only
## thing separating a decomposition from a degree.
func _drawn_parts() -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	match assembly:
		"treads":
			for i in range(DECK_N):
				out.append(i)
		"legs":
			for i in range(DECK_N, DECK_N + POST_N):
				out.append(i)
		"cells":
			for i in range(DECK_N + POST_N):
				out.append(i)
		"slab":
			pass                        ## drawn as one merged mesh, not as parts
		_:
			for i in range(PART_TOTAL):
				out.append(i)
	return out


# ── building ───────────────────────────────────────────────────────────────────────────

func _build_stage(holder: Node3D) -> void:
	_add_box(holder, "Plate", Vector3(0.0, PLATE_T * 0.5, 0.0),
		Vector3(PLATE_HALF * 2.0, PLATE_T, PLATE_HALF * 2.0), Vector3.ZERO, C_PLATE, false)
	_add_box(holder, "FramingAnchor", ANCHOR_CENTRE, ANCHOR_SIZE, Vector3.ZERO,
		C_PLATE, true)


func _build_parts(holder: Node3D, obj: String) -> void:
	if assembly == "slab":
		_build_slab(holder, obj)
		return
	var pos: Array[Vector3] = _positions_for(obj)
	var rot: Array[Vector3] = _rotations_for(obj)
	var lash: bool = assembly == "lashed"
	var drawn: PackedInt32Array = _drawn_parts()
	for k in range(drawn.size()):
		var i: int = drawn[k]
		var p: Vector3 = pos[i]
		var r: Vector3 = rot[i]
		if lash:
			p += LASH_OFFSET[i]
			r += LASH_CANT[i]
		_add_box(holder, "Part_%d" % i, p, _size_of(i), r, _colour_of(i), false)


## THE MERGE, AND IT IS recursive_table's STEP 2 WITH ONE HALF DECLINED. Its _step_2 does
## two things at once: it fuses nine cells into one, and it FLATTENS them — the cells are
## table_size * 0.4 tall and the slab is table_size * 0.04, a ten-fold thinning. Here the
## decks are already 0.030 m plates, so there is nothing to flatten and this is a fusion
## only. That is a real weakening of the value and it is recorded in `declines` rather than
## absorbed, because most of the change a reader sees in the source at step 2 is the
## thinning, not the fusion.
##
## The box is the WORLD AABB of the four deck parts as this object places them, so the merge
## costs whatever the parts' separation costs and nothing else. On the table that is two
## 0.010 m seams. On the stair it is 0.285 m of rise, and the answer is a solid block —
## which is cube_staircase's own truth line handed back: a staircase is a cube that learned
## to subdivide itself along its own diagonal, so un-subdividing it returns the cube.
func _build_slab(holder: Node3D, obj: String) -> void:
	var pos: Array[Vector3] = _positions_for(obj)
	var rot: Array[Vector3] = _rotations_for(obj)
	var lo: Vector3 = Vector3.ZERO
	var hi: Vector3 = Vector3.ZERO
	var have: bool = false
	for i in range(DECK_N):
		var basis_i: Basis = Basis.from_euler(rot[i])
		var h: Vector3 = _size_of(i) * 0.5
		for k in range(CORNER_SIGNS.size()):
			var sgn: Vector3 = CORNER_SIGNS[k]
			var corner: Vector3 = pos[i] + basis_i * (sgn * h)
			if not have:
				lo = corner
				hi = corner
				have = true
			else:
				lo = Vector3(minf(lo.x, corner.x), minf(lo.y, corner.y),
					minf(lo.z, corner.z))
				hi = Vector3(maxf(hi.x, corner.x), maxf(hi.y, corner.y),
					maxf(hi.z, corner.z))
	if not have:
		return
	_add_box(holder, "Slab", (lo + hi) * 0.5, hi - lo, Vector3.ZERO, C_DECK, false)


## BoxMesh, not SurfaceTool: both members build every part with a BoxMesh through their own
## _create_part / _create_cube, so this is their construction as well as the correctly wound
## one. A Godot primitive winds outward, which is what the triangle-winding rule asks for,
## and no material here is transparent so nothing needs CULL_DISABLED.
##
## `anchor` sets layers = 0. The mesh exists, the AABB counts it, nothing draws it.
func _add_box(holder: Node3D, mesh_name: String, at: Vector3, size: Vector3,
		euler: Vector3, c: Color, anchor: bool) -> void:
	var box := BoxMesh.new()
	box.size = size
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = box
	## Basis and origin in one assignment. `mi.position = at` followed by `mi.basis = ...`
	## is two round trips through the same struct property and the corpus writes rotations
	## as `transform.basis`; one Transform3D avoids both questions.
	mi.transform = Transform3D(Basis.from_euler(euler), at)
	if anchor:
		mi.layers = 0
	else:
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.metallic = PART_METALLIC
		m.roughness = PART_ROUGHNESS
		mi.material_override = m
	holder.add_child(mi)
