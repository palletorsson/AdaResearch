extends Node3D
class_name AlphabetGrammar

## alphabet_grammar — one rule, one stream of 144 numbers, seven symbol sets, and the
## number of symbols turns out to tell you nothing.
##
## THE FAMILY, and the census first because the census is checkable.
##
##   GeneticProgramming   alphabet = primitives | csg_tree | parametric | voxel
##   genetic_programming  alphabet = primitives | csg_tree | parametric | voxel
##   ten_print_textile    alphabet = diagonals | orthogonals | blocks
##
## THE FIRST TWO ARE ONE SCENE UNDER TWO NAMES — CONFIRMED, NOT ASSUMED. Both registry
## entries in commons/artifacts/registry/procgen_extra.json name the identical scene
## path, res://algorithms/proceduralgeneration/growth_systems/genetic_programming/
## GeneticProgramming.tscn, and there is exactly one .gd in that directory carrying the
## axis. They differ only in bookkeeping: one says category "unknown" / complexity
## "beginner" and carries dna.fixture {"population_seed": 20260802}, the other says
## "procedural" / "advanced" and carries NO fixture at all — which means the same scene
## is declared once as seeded and once as unseeded. So the family is TWO artifacts and
## THREE names, and the third name is a way to sweep the same scene with the determinism
## switched off.
##
## AND A SECOND THING ABOUT THAT SCENE, worth writing down because it is the trap the
## project file already warns about. GeneticProgramming.tscn's ROOT is a scriptless
## Node3D; the script hangs on a CHILD also called GeneticProgramming. So a map token's
## config_alphabet metadata lands on the root, and the root has no _read_dna_meta to read
## it. The axis is reachable from the SWEEP (which sets the property directly) and from
## the editor, and not from a map placement. Nothing here depends on that, but a reader
## comparing this bench to its source should know the source's axis has never been placed.
##
##
## WHAT AN ALPHABET IS, and the claim this bench exists to test.
##
## An alphabet is the set of primitives a generative system may combine. It bounds what
## the system can ever make — not what it is likely to make, what it CAN make. The
## tempting corollary is that a bigger alphabet spans a bigger space. That corollary is
## the thing being tested, and the code refuses it twice.
##
## THE BRIEF SAID: ten_print_textile is named for `10 PRINT CHR$(205.5+RND(1)); : GOTO 10`
## whose alphabet is two characters; a CSG tree's alphabet is a handful of booleans on
## solids and its reachable set is vastly larger; a voxel alphabet is one cube and can
## approximate anything given enough of them. Two symbols, four operations, one cube. All
## three of those readings are wrong about this code, in three different directions:
##
##   1. ten_print_textile's `alphabet` AXIS NEVER CHANGES THE ALPHABET'S SIZE. All three
##      of its values are TWO-symbol alphabets. `diagonals` is the +-45 degree bar (the
##      brief guessed right about this one); `orthogonals` is THE SAME BAR at 0 and 90
##      degrees, a lying bar and a standing one; `blocks` is "no line at all: the flip
##      read as a bitmap", a filled cell against a speck. One fair coin, three pairs of
##      marks. That member's own axis is already the experiment: hold the size at two,
##      hold the rule fixed, change only the marks, and get three cloths that do not look
##      remotely alike. Whoever wrote it had the finding before this bench did.
##
##   2. `voxel` IS NOT ONE CUBE. create_voxel_genome walks an 8x8x8 grid and writes a
##      voxel where `randf() < 0.3` — so the alphabet is {cube, VOID} and the void is
##      doing half the work. A one-symbol alphabet under a random rule produces exactly
##      one picture and has no reach at all. Everything the brief credited to "one cube"
##      belongs to the empty cell beside it. Two symbols, 512 cells, 2^512 bodies.
##
##   3. `csg_tree` HAS THE BIGGEST DECLARED ALPHABET IN THE FAMILY AND DRAWS ONE MARK.
##      create_csg_genome rolls an operation from {union, subtract, intersect} and a
##      primitive from {sphere, box, cylinder} — nine distinct gene kinds. Then
##      build_csg_phenotype calls add_primitive_to_surface, which reads the operation into
##      a local variable, ignores it, ignores the primitive too, and emits THREE VERTICES:
##      vertices[0], [1], [2] of a unit cube — one flat right triangle. Nine words, one
##      mark. The source's own DNA header admits the stub; what it does not say is the
##      consequence, which is that the effective alphabet has size ONE.
##
## SO THE THESIS SOMEONE CAN DISAGREE WITH: a symbol that draws what every other symbol
## draws is not a symbol, it is a synonym, and the DECLARED vocabulary and the EFFECTIVE
## vocabulary are two different sets — only the second one bounds anything. Size is a fact
## about the declaration. Reach is a fact about the renderer. THE DISAGREEMENT AVAILABLE,
## and it is fair: a reader can say csg_tree's collapse is a BUG and a bug is not a fact
## about alphabets. The answer is that check_dna_declarations.py passes this axis — the
## enum is honest, all four values exist, all four are reachable — and the collapse
## happens one layer below anything the corpus's gates can see. That is exactly the class
## of error worth drawing.
##
##
## WHAT THIS BENCH DOES. ONE RULE, and it is 10 PRINT's rule generalised:
##
##     for each cell of a fixed raster, in a fixed order, draw ONE number and read it as
##     one symbol of the alphabet.
##
## That is `CHR$(205.5+RND(1))` with the two-way partition of [0,1) replaced by a K-way
## one, and it is ALSO what GeneticProgramming does at generation zero — create_random_gene
## does `types[randi() % types.size()]`, create_voxel_genome does `if randf() < 0.3`, one
## draw per slot out of a flat distribution. The rule is the shared rule of both members.
##
## THE STREAM IS DRAWN ONCE AND SHARED. 144 uniform floats out of one RandomNumberGenerator
## seeded at RULE_SEED = 20260816, in row-major order, top row first. Every alphabet reads
## THE SAME 144 NUMBERS; the alphabet is nothing but the partition of [0,1) those numbers
## are read through. No alphabet gets more randomness than another, no alphabet gets a
## different draw, and the four two-symbol alphabets get the SAME 144 symbol indices —
## which is what makes `diagonals` against `orthogonals` a pure test of the marks.
##
## Deterministic. No randf outside that one seeded generator, no noise, no NoiseTexture2D,
## no _process, no Timer, no tween. Two builds of one cell are the same mesh. That matters
## more than usual here because BOTH sources are unseeded by default: GeneticProgramming
## rolls every genome off the GLOBAL stream that Godot randomises at boot (its own header
## says two boots gave twenty entirely different creatures, and any two frames differed by
## 100% no matter what changed), and ten_print_textile ships `weave_seed = 0`, which means
## `_rng.randomize()`, plus a `_process` that scrolls the bolt every 0.18 s. Between them
## the family has a random cloth on a moving loom and a random population on a global
## stream. Neither can be photographed twice.
##
##
## WHAT THE THREE READINGS ARE FOR.
##
##   field   the rule run: 12 x 12 = 144 cells, one symbol each. What the alphabet makes.
##   glyphs  the alphabet ITSELF, one plaque per symbol, each symbol at TRUE SIZE — the
##           same dimensions it has in the field. THIS IS THE READING THAT MAKES THE SIZE
##           CLAIM VISIBLE: two plaques for diagonals, two for orthogonals, two for blocks,
##           two for voxel (one of them bare, because void is a symbol), four for
##           primitives, nine for csg_tree, and nine SAMPLES for parametric, which has no
##           finite vocabulary to lay out. It is the only reading that does not consume the
##           stream. Ranked by this reading, csg_tree is the largest alphabet in the sheet.
##   reach   the reading that refutes it. Every 2 x 2 neighbourhood of the field — 11 x 11
##           = 121 overlapping blocks — is keyed by WHAT ITS FOUR CELLS ACTUALLY DRAW, and
##           each DISTINCT key gets its own plaque on an 11-column shelf, in first-
##           occurrence order. The shelf's occupancy is the reach, built as matter.
##           Expected: 16 for each two-symbol alphabet, about 96 for primitives, 121 for
##           parametric — and ONE for csg_tree, because its nine symbols all key the same.
##           Nine words, one plaque.
##
## THE HONEST LIMIT OF `reach`, said here rather than discovered later: 121 blocks can
## never show more than 121 distinct configurations, so the shelf is CENSORED BY THE
## SAMPLE. It separates 1 from 16 from 96 cleanly and it cannot separate primitives' true
## 4^4 = 256 from parametric's continuum, because both saturate. A full shelf means "at
## least 121", not "121".


# ── the two axes ───────────────────────────────────────────────────────────────────────

## WHICH SYMBOL SET THE RULE IS RUN OVER. Seven values, the honest union of the family's
## two vocabularies, with the symbol count of each written beside it. Every mark's
## proportions are taken from its own source file; not one is invented here.
##
##   diagonals    2 · ten_print_textile · a bar CELL*0.9 long and CELL*0.42 thick at
##                rotation.z = +PI/4 (the coin's heads) and -PI/4 (tails). The shipped
##                cloth, and the artifact's own default. The two PETSCII characters of the
##                one-line program, drawn as bars rather than as glyphs.
##   orthogonals  2 · ten_print_textile · THE SAME BAR at rotation.z = 0.0 and PI/2. Its
##                own comment: "the same flip, a different alphabet: a lying bar and a
##                standing one". Same size, same coin, same 144 indices as `diagonals`.
##   blocks       2 · ten_print_textile · "No line at all: the flip read as a bitmap."
##                A filled cell CELL*0.9 square against a speck CELL*0.3 square.
##   voxel        2 · GeneticProgramming · a cube and a VOID. The source's BoxMesh size 0.4
##                on a 0.5 lattice pitch, so the cube is 0.8 of the cell; the second symbol
##                is the cell create_voxel_genome declined to fill.
##   primitives   4 · GeneticProgramming · sphere, box, cylinder, torus — the four strings
##                in Genome.create_random_gene's `types` array, built with the four mesh
##                classes build_primitive_phenotype builds them with, at that function's
##                own proportions INCLUDING its squashed sphere (`sphere.height =
##                sphere.radius`, so the bead is half as tall as it is wide).
##   csg_tree     9 declared, 1 DRAWN · GeneticProgramming · {union, subtract, intersect}
##                x {sphere, box, cylinder}. All nine draw the identical zero-thickness
##                right triangle, because that is literally what add_primitive_to_surface
##                emits — vertices[0], [1], [2] of a cube, one face's worth of half.
##   parametric   a CONTINUUM · GeneticProgramming · the draw IS the symbol. One trig
##                surface per cell from build_parametric_phenotype's own equation, with
##                the eight non-phase parameters pinned at the midpoints of the source's
##                own randf_range so that exactly one number is spent per cell, as the rule
##                requires. At the generator's 32-bit precision that is 2^32 symbols.
## ONE LINE ON PURPOSE, and it cost a gate run to learn: check_dna_declarations reads the
## export with `@export[^\n]*\bvar\s+<axis>`, so a wrapped @export_enum reports NO_EXPORT
## on an axis whose values the same tool derived correctly one call earlier.
@export_enum("diagonals", "orthogonals", "blocks", "voxel", "primitives", "csg_tree", "parametric") var alphabet: String = "diagonals":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not ALPHABETS.has(picked):
			return                          ## an unreachable value keeps the standing figure
		alphabet = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## WHAT IS BEING SHOWN OF IT. Three values, and two of them argue with each other.
##
##   field   the rule run over the whole raster. The generated result.
##   glyphs  the vocabulary laid out, each symbol at true size, one plaque per symbol.
##           The plaque COUNT is the alphabet's size, standing up as matter.
##   reach   the distinct 2x2 configurations that actually occur in that field, collected
##           and stood in rows. The plaque count is the reach.
@export_enum("field", "glyphs", "reach") var reading: String = "field":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not READINGS.has(picked):
			return
		reading = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One panel, or all seven alphabets in a row. NOT PART OF EITHER AXIS, and the reason is
## the reason it is a separate export in every synthesis in this programme:
## capture_config_sweep unions the AABB across a spec's variants, so an all-alphabets value
## declared inside `alphabet` would frame every single cell against seven and a half metres
## and photograph a 0.029 m bar as a hair. The registry fixture pins `single`; `ladder` is
## a design view for looking at the seven side by side in the editor.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const ALPHABETS: PackedStringArray = ["diagonals", "orthogonals", "blocks", "voxel",
	"primitives", "csg_tree", "parametric"]
const READINGS: PackedStringArray = ["field", "glyphs", "reach"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

## THE SEED, and it is this bench's own rather than a source's, because neither source has
## one to borrow. GeneticProgramming's population_seed ships at -1 (meaning "do not seed";
## one of its two registry entries fixtures 20260802 and the other does not), and
## ten_print_textile's weave_seed ships at 0, which means `_rng.randomize()`. So there is
## no family constant here the way there was for the cohort family. 20260816 is the date.
const RULE_SEED: int = 20260816


# ── the stage, identical to the millimetre in all twenty-one cells ─────────────────────
## A LOOM FRAME, and it is the reason the AABB never moves: two uprights, two beams and a
## solid back, spanning 0.96 x 0.96 x 0.16 before a single mark exists. The figure inside
## it changes enormously — 144 marks under `field`, two plaques under `glyphs` at
## `diagonals`, one under `reach` at `csg_tree` — and the world box is the same in every
## cell, so the camera never moves and no measured pair carries a framing difference it did
## not earn. THE PANEL IS VERTICAL, which is not decoration: at the sweep's standpoint
## (yaw 0.62, pitch -0.26) a horizontal plane projects at 0.084 of its area and a vertical
## one in the xy plane at 0.787, nine times better. ten_print_textile's cloth is a hanging
## bolt; this follows it.
const PANEL_W: float = 0.96
const PANEL_H: float = 0.96
const FRAME_D: float = 0.16
const FRAME_BAR: float = 0.045
const BACK_W: float = 0.90
const BACK_D: float = 0.08

# ── the raster ─────────────────────────────────────────────────────────────────────────
## 12 x 12 at 0.070 m. Square cells, because two of the three textile alphabets are
## rotations and a rotation is only an honest comparison in a square cell — the source's
## own cell is 1/14 x 0.07 = 0.0714 x 0.0700, which is square to 2 percent, so this is its
## proportion rounded rather than a new one.
const COLS: int = 12
const ROWS: int = 12
const CELL: float = 0.070
const FIELD_HALF: float = 0.42
const FIELD_TOP: float = 0.90
const MARK_Z: float = 0.001            ## clear of the backing so no face is coplanar

# ── mark geometry, every ratio lifted from its own source ──────────────────────────────
const BAR_L: float = 0.0630            ## CELL * 0.9   — ten_print_textile's sx * 0.9
const BAR_W: float = 0.0294            ## CELL * 0.42  — its _row_h * 0.42
const MARK_D: float = 0.016            ## the source's 0.03 on a 1.26 m bolt, to scale
const BLOCK_BIG: float = 0.0630        ## CELL * 0.9
const BLOCK_SMALL: float = 0.0210      ## CELL * 0.3
const VOXEL_S: float = 0.0560          ## CELL * 0.8 — BoxMesh 0.4 at 0.5 lattice pitch
const PRIM_S: float = 0.0630           ## CELL * 0.9, the max extent of every primitive
const CSG_S: float = 0.0630            ## CELL * 0.9, the triangle's two legs
const PARA_A: float = 1.25             ## midpoint of the source's randf_range(0.5, 2.0)
const PARA_F: float = 1.75             ## midpoint of the source's randf_range(0.5, 3.0)
const PARA_RES: int = 6                ## the source samples 20; 6 at 0.063 m is 36 tris
## Half-depths of the four primitives as built, so each sits ON its surface rather than
## floating: sphere and box and cylinder are 0.063 deep, the torus 0.018 once stood up.
const PRIM_HALF_D: PackedFloat32Array = [0.0315, 0.0315, 0.0315, 0.009]

# ── the glyphs shelf ───────────────────────────────────────────────────────────────────
## Nine positions at 0.84/9 pitch, centred, however many the alphabet needs. The plaque is
## 0.084 square — 1.2 cells — so nine of them nearly touch and two of them sit alone in a
## wide empty panel. THE EMPTINESS IS THE CLAIM. Drawn area of the sparsest case: two
## plaques at 0.0071 m2 each plus two marks at 0.0019 m2 = 0.0179 m2 of world surface,
## about 1.5 percent of the frame, which is seven times the critic's blank floor.
const GLYPH_PITCH: float = 0.0933333
const PLAQUE_W: float = 0.084
const PLAQUE_D: float = 0.008
const GLYPH_Y: float = 0.48
const PARA_SAMPLES: int = 9            ## a continuum cannot be laid out; this is a sample

# ── the reach shelf ────────────────────────────────────────────────────────────────────
## 11 columns at 0.84/11, which is exactly the 11 x 11 = 121 overlapping 2 x 2 blocks a
## 12 x 12 field has, so a saturated shelf fills the panel exactly and nothing has to be
## trimmed or scaled. The marks inside a reach plaque are at HALF size; the plaque itself
## is 0.070 square and is the countable body.
const REACH_COLS: int = 11
const REACH_PITCH: float = 0.0763636
const REACH_PLAQUE: float = 0.070
const REACH_PLAQUE_D: float = 0.006
const REACH_MARK_S: float = 0.5

const LADDER_PITCH: float = 1.10

# ── colour ─────────────────────────────────────────────────────────────────────────────
## EVERY GP ALPHABET USES ONE COLOUR FOR ITS WHOLE SYMBOL SET, because the source hands
## each phenotype branch a single material: build_primitive_phenotype paints all four
## solids Color(0.6, 0.7, 0.9), build_voxel_phenotype paints every cube (0.5, 0.8, 0.6),
## build_csg_phenotype (0.8, 0.6, 0.4), build_parametric_phenotype (0.9, 0.5, 0.7). Only
## ten_print_textile colours by SYMBOL — warm hue 0.07 for the coin's heads, cool 0.58 for
## tails. All five source colours are kept exactly; the two textile VALUES are pushed
## apart, and why is in `declines`.
## Rec.709 luminance of each, written down so the greyscale reading is checkable rather
## than hoped: back 0.109, frame 0.211, plaque 0.310, cool 0.493, parametric 0.599,
## csg 0.628, primitives 0.693, warm 0.694, voxel 0.722. The three things that must be told
## apart INSIDE one frame — backing, plaque, mark — are 0.20 and 0.18 apart at the closest.
## Primitives at 0.693 and warm at 0.694 are a coincidence and a harmless one: they never
## appear in the same frame, and across frames the changed pixels are mark-against-backing
## at 0.58 separation, not mark-against-mark.
const C_BACK: Color = Color(0.10, 0.11, 0.13)
const C_FRAME: Color = Color(0.22, 0.21, 0.19)
const C_PLAQUE: Color = Color(0.30, 0.31, 0.34)
const C_WARM: Color = Color(0.980, 0.639, 0.392)     ## from_hsv(0.07, 0.6, 0.98)
const C_COOL: Color = Color(0.296, 0.527, 0.740)     ## from_hsv(0.58, 0.6, 0.74)
const C_VOXEL: Color = Color(0.50, 0.80, 0.60)
const C_PRIM: Color = Color(0.60, 0.70, 0.90)
const C_CSG: Color = Color(0.80, 0.60, 0.40)
const C_PARA: Color = Color(0.90, 0.50, 0.70)

var _built: Array[Node3D] = []
## Set while a whole config dictionary lands, so three keys cost one rebuild, not three.
var _bulk: bool = false
## THE STREAM. 144 uniform draws, made once per rebuild and shared by every alphabet and
## every reading, so the alphabet is the only thing that differs between two cells.
var _u: PackedFloat32Array = PackedFloat32Array()
var _prim_meshes: Array[Mesh] = []
var _prim_mat: StandardMaterial3D = null


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("alphabet"):
		alphabet = str(config_data["alphabet"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
	_bulk = false
	_rebuild()


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


# ── the rule ───────────────────────────────────────────────────────────────────────────

## THE WHOLE GENERATIVE SYSTEM, and it is four lines. One seeded generator, one draw per
## cell, row-major, top row first — which is the order 10 PRINT prints in and the order
## create_voxel_genome walks its grid in. Called ONCE per rebuild, before any alphabet is
## consulted, so `layout = ladder` shows seven alphabets reading the same 144 numbers.
func _draw_stream() -> void:
	_u = PackedFloat32Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = RULE_SEED
	for i in range(COLS * ROWS):
		_u.append(rng.randf())


## How many symbols the alphabet has. ZERO IS THE SENTINEL FOR A CONTINUUM — `parametric`
## does not partition [0,1) at all, it uses the draw at full precision, so there is no K.
func _symbol_count(who: String) -> int:
	match who:
		"primitives":
			return 4
		"csg_tree":
			return 9                        ## DECLARED nine. All nine draw one mark.
		"parametric":
			return 0                        ## a continuum
		_:
			return 2                        ## diagonals, orthogonals, blocks, voxel
	return 2


## The rule's one operation: read a uniform draw as a symbol. For K = 2 this is exactly
## ten_print_textile's `_rng.randf() < odds` at the fair odds it ships.
func _symbol_index(who: String, u: float) -> int:
	var k: int = _symbol_count(who)
	if k <= 0:
		return 0
	var idx: int = int(floor(u * float(k)))
	if idx >= k:
		idx = k - 1
	if idx < 0:
		idx = 0
	return idx


## THE IDENTITY OF WHAT IS DRAWN, not of what was declared, and this one function is the
## whole `reach` reading. csg_tree returns a constant for all nine of its symbols because
## all nine emit the same triangle; a symbol that draws what its neighbour draws is a
## synonym and cannot widen anything. parametric returns the draw itself, because a
## continuous alphabet has no two equal symbols.
func _mark_key(who: String, u: float) -> String:
	if who == "csg_tree":
		return "t"
	if who == "parametric":
		return "%.9f" % u
	return str(_symbol_index(who, u))


func _cell_x(i: int) -> float:
	return -FIELD_HALF + (float(i) + 0.5) * CELL


func _cell_y(j: int) -> float:
	return FIELD_TOP - (float(j) + 0.5) * CELL


## Every distinct 2 x 2 neighbourhood of the field, in first-occurrence order. 11 x 11 =
## 121 blocks over a 12 x 12 raster. Returns [[key, u00, u01, u10, u11], ...].
func _reach_blocks(who: String) -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	for j in range(ROWS - 1):
		for i in range(COLS - 1):
			var a: float = _u[j * COLS + i]
			var b: float = _u[j * COLS + i + 1]
			var c: float = _u[(j + 1) * COLS + i]
			var d: float = _u[(j + 1) * COLS + i + 1]
			var key: String = (_mark_key(who, a) + "|" + _mark_key(who, b) + "|"
				+ _mark_key(who, c) + "|" + _mark_key(who, d))
			if seen.has(key):
				continue
			seen[key] = true
			out.append([key, a, b, c, d])
	return out


# ── build ──────────────────────────────────────────────────────────────────────────────

func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	_draw_stream()
	var names: PackedStringArray = PackedStringArray()
	if layout == "ladder":
		names = ALPHABETS.duplicate()
	else:
		names.append(_pick(alphabet, ALPHABETS, "diagonals"))
	var how: String = _pick(reading, READINGS, "field")
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Cell_" + names[i] + "_" + how
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_stage(holder)
		var sinks: Dictionary = {}
		match how:
			"glyphs":
				_build_glyphs(holder, sinks, names[i])
			"reach":
				_build_reach(holder, sinks, names[i])
			_:
				_build_field(holder, sinks, names[i])
		_flush(holder, sinks, names[i] + "_" + how)


func _build_stage(holder: Node3D) -> void:
	var back := SurfaceTool.new()
	back.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(back, Vector3(0.0, PANEL_H * 0.5, -BACK_D * 0.5),
		Vector3(BACK_W, BACK_W, BACK_D))
	_commit(holder, "Backing", back, C_BACK, 0.95, 0.0)

	var frame := SurfaceTool.new()
	frame.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ux: float = PANEL_W * 0.5 - FRAME_BAR * 0.5
	_add_box(frame, Vector3(-ux, PANEL_H * 0.5, 0.0),
		Vector3(FRAME_BAR, PANEL_H, FRAME_D))
	_add_box(frame, Vector3(ux, PANEL_H * 0.5, 0.0),
		Vector3(FRAME_BAR, PANEL_H, FRAME_D))
	_add_box(frame, Vector3(0.0, FRAME_BAR * 0.5, 0.0),
		Vector3(PANEL_W, FRAME_BAR, FRAME_D))
	_add_box(frame, Vector3(0.0, PANEL_H - FRAME_BAR * 0.5, 0.0),
		Vector3(PANEL_W, FRAME_BAR, FRAME_D))
	_commit(holder, "Frame", frame, C_FRAME, 0.80, 0.0)


## THE RULE RUN. 144 cells, one draw each, in the order the stream was made.
func _build_field(holder: Node3D, sinks: Dictionary, who: String) -> void:
	for j in range(ROWS):
		for i in range(COLS):
			_emit_mark(holder, sinks, who, _u[j * COLS + i],
				_cell_x(i), _cell_y(j), MARK_Z, 1.0)


## THE VOCABULARY. One plaque per symbol, the symbol at TRUE SIZE on top of it. The only
## reading that does not touch the stream: it enumerates the alphabet instead of sampling
## it, so the representative draw for symbol s of K is (s + 0.5) / K — the midpoint of that
## symbol's own share of [0,1). For `parametric` there is nothing to enumerate, so nine
## evenly spaced samples of the continuum stand in for it and the note says so.
func _build_glyphs(holder: Node3D, sinks: Dictionary, who: String) -> void:
	var k: int = _symbol_count(who)
	var n: int = k
	if k <= 0:
		n = PARA_SAMPLES
	var plaques := SurfaceTool.new()
	plaques.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s in range(n):
		var px: float = (float(s) - float(n - 1) * 0.5) * GLYPH_PITCH
		_add_box(plaques, Vector3(px, GLYPH_Y, MARK_Z + PLAQUE_D * 0.5),
			Vector3(PLAQUE_W, PLAQUE_W, PLAQUE_D))
		var u: float = (float(s) + 0.5) / float(n)
		_emit_mark(holder, sinks, who, u, px, GLYPH_Y, MARK_Z + PLAQUE_D, 1.0)
	_commit(holder, "Glyphs_" + str(n), plaques, C_PLAQUE, 0.85, 0.0)


## THE SPACE ACTUALLY SPANNED. One plaque per DISTINCT 2 x 2 configuration that occurs in
## the field, filling an 11-wide shelf from the top left. The plaque count is the number.
func _build_reach(holder: Node3D, sinks: Dictionary, who: String) -> void:
	var blocks: Array = _reach_blocks(who)
	var plaques := SurfaceTool.new()
	plaques.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half: float = REACH_PITCH * 0.25
	for b in range(blocks.size()):
		var bi: int = int(b)
		var row: int = bi / REACH_COLS
		var col: int = bi % REACH_COLS
		var px: float = -FIELD_HALF + (float(col) + 0.5) * REACH_PITCH
		var py: float = FIELD_TOP - (float(row) + 0.5) * REACH_PITCH
		_add_box(plaques, Vector3(px, py, MARK_Z + REACH_PLAQUE_D * 0.5),
			Vector3(REACH_PLAQUE, REACH_PLAQUE, REACH_PLAQUE_D))
		var cell: Array = blocks[bi]
		var zb: float = MARK_Z + REACH_PLAQUE_D
		_emit_mark(holder, sinks, who, float(cell[1]), px - half, py + half, zb,
			REACH_MARK_S)
		_emit_mark(holder, sinks, who, float(cell[2]), px + half, py + half, zb,
			REACH_MARK_S)
		_emit_mark(holder, sinks, who, float(cell[3]), px - half, py - half, zb,
			REACH_MARK_S)
		_emit_mark(holder, sinks, who, float(cell[4]), px + half, py - half, zb,
			REACH_MARK_S)
	_commit(holder, "Reach_" + str(blocks.size()), plaques, C_PLAQUE, 0.85, 0.0)


# ── the marks ──────────────────────────────────────────────────────────────────────────

## ONE SYMBOL, DRAWN. Every branch here is a transcription of its own source function; the
## only thing this dispatcher adds is that all seven are asked the same question by the
## same rule at the same size.
func _emit_mark(holder: Node3D, sinks: Dictionary, who: String, u: float,
		cx: float, cy: float, z0: float, s: float) -> void:
	var idx: int = _symbol_index(who, u)
	match who:
		"diagonals":
			# ten_print_textile._mark, else-branch: rotation.z = +-PI * 0.25
			var rot_d: float = PI * 0.25
			if idx != 0:
				rot_d = -PI * 0.25
			_add_prism(_sink(sinks, "warm" if idx == 0 else "cool"), cx, cy, z0,
				BAR_L * 0.5 * s, BAR_W * 0.5 * s, MARK_D * s, rot_d)
		"orthogonals":
			# ten_print_textile._mark, orthogonals branch: rotation.z = 0.0 or PI * 0.5
			var rot_o: float = 0.0
			if idx != 0:
				rot_o = PI * 0.5
			_add_prism(_sink(sinks, "warm" if idx == 0 else "cool"), cx, cy, z0,
				BAR_L * 0.5 * s, BAR_W * 0.5 * s, MARK_D * s, rot_o)
		"blocks":
			# ten_print_textile._mark, blocks branch: a filled cell against a speck
			var side: float = BLOCK_BIG
			if idx != 0:
				side = BLOCK_SMALL
			_add_prism(_sink(sinks, "warm" if idx == 0 else "cool"), cx, cy, z0,
				side * 0.5 * s, side * 0.5 * s, MARK_D * s, 0.0)
		"voxel":
			# create_voxel_genome / build_voxel_phenotype: a cube, or the cell it declined
			# to fill. THE SECOND SYMBOL DRAWS NOTHING AND IS STILL A SYMBOL.
			if idx == 0:
				_add_prism(_sink(sinks, "voxel"), cx, cy, z0,
					VOXEL_S * 0.5 * s, VOXEL_S * 0.5 * s, VOXEL_S * s, 0.0)
		"primitives":
			_add_primitive(holder, idx, cx, cy, z0, s)
		"csg_tree":
			_add_csg(_sink(sinks, "csg"), cx, cy, z0, s)
		"parametric":
			_add_ribbon(_sink(sinks, "para"), cx, cy, z0, s, u)
		_:
			pass


## add_primitive_to_surface, transcribed. It reads the gene's operation into a local
## variable and then adds three vertices of a unit cube — vertices[0], [1], [2], the
## lower-left half of the -z face. The operation is never used, the primitive name is
## never used, and every one of the nine symbols arrives here and leaves as this triangle.
## Zero thickness, because that is what the source emits; CULL_DISABLED carries it.
func _add_csg(st: SurfaceTool, cx: float, cy: float, z0: float, s: float) -> void:
	var h: float = CSG_S * 0.5 * s
	var z: float = z0 + 0.002
	var a: Vector3 = Vector3(cx - h, cy - h, z)
	var b: Vector3 = Vector3(cx + h, cy - h, z)
	var c: Vector3 = Vector3(cx + h, cy + h, z)
	_tri_front(st, a, b, c)


## build_parametric_phenotype's own equation and its own triangle pattern, at resolution 6
## instead of 20 and scaled into one cell. Note the shape of the source's surface: x
## depends on u only, y and z on v only, so it is a curve in (y, z) swept along x — a
## ribbon, not a closed body. The phase is the cell's draw; the other eight parameters are
## pinned so the rule spends exactly one number per cell.
func _add_ribbon(st: SurfaceTool, cx: float, cy: float, z0: float, s: float,
		u: float) -> void:
	var ph: float = u * TAU
	var sc: float = (PRIM_S * s) / (2.0 * PARA_A)
	var origin: Vector3 = Vector3(cx, cy, z0 + PARA_A * sc)
	for ui in range(PARA_RES):
		for vi in range(PARA_RES):
			var un: float = float(ui) / float(PARA_RES) * TAU
			var vn: float = float(vi) / float(PARA_RES) * TAU
			var un1: float = float(ui + 1) / float(PARA_RES) * TAU
			var vn1: float = float(vi + 1) / float(PARA_RES) * TAU
			var p1: Vector3 = Vector3(
				PARA_A * cos(un * PARA_F + ph),
				PARA_A * sin(vn * PARA_F + ph),
				PARA_A * cos(vn * PARA_F + ph))
			var p2: Vector3 = Vector3(
				PARA_A * cos(un1 * PARA_F + ph),
				PARA_A * sin(vn * PARA_F + ph),
				PARA_A * cos(vn * PARA_F + ph))
			var p3: Vector3 = Vector3(
				PARA_A * cos(un * PARA_F + ph),
				PARA_A * sin(vn1 * PARA_F + ph),
				PARA_A * cos(vn1 * PARA_F + ph))
			_tri_front(st, p1 * sc + origin, p2 * sc + origin, p3 * sc + origin)


## build_primitive_phenotype's four mesh classes, at that function's own proportions.
## The squashed sphere is deliberate and is the source's line: `sphere.radius = 0.5;
## sphere.height = sphere.radius`, so the bead is half as tall as it is wide. The torus is
## stood up (rotation.x = PI/2) so its hole faces the camera; lying in xz as TorusMesh
## builds it, a wall-mounted torus photographs as a line.
func _prim_setup() -> void:
	if not _prim_meshes.is_empty():
		return
	var sph := SphereMesh.new()
	sph.radius = PRIM_S * 0.5
	sph.height = PRIM_S * 0.5
	var bx := BoxMesh.new()
	bx.size = Vector3(PRIM_S, PRIM_S, PRIM_S)
	var cyl := CylinderMesh.new()
	cyl.top_radius = PRIM_S * 0.5
	cyl.bottom_radius = PRIM_S * 0.5
	cyl.height = PRIM_S
	var tor := TorusMesh.new()
	tor.inner_radius = PRIM_S * (0.3 / 1.4)
	tor.outer_radius = PRIM_S * (0.7 / 1.4)
	_prim_meshes.clear()
	_prim_meshes.append(sph)
	_prim_meshes.append(bx)
	_prim_meshes.append(cyl)
	_prim_meshes.append(tor)
	_prim_mat = StandardMaterial3D.new()
	_prim_mat.albedo_color = C_PRIM
	_prim_mat.roughness = 0.60
	_prim_mat.metallic = 0.0
	_prim_mat.cull_mode = BaseMaterial3D.CULL_DISABLED


func _add_primitive(holder: Node3D, idx: int, cx: float, cy: float, z0: float,
		s: float) -> void:
	_prim_setup()
	var slot: int = idx
	if slot < 0 or slot > 3:
		slot = 0
	var mi := MeshInstance3D.new()
	mi.mesh = _prim_meshes[slot]
	mi.material_override = _prim_mat
	mi.scale = Vector3(s, s, s)
	if slot == 3:
		mi.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	mi.position = Vector3(cx, cy, z0 + PRIM_HALF_D[slot] * s)
	holder.add_child(mi)


# ── geometry helpers ───────────────────────────────────────────────────────────────────

## An oriented prism standing off the panel: a rectangle of half-extents hw x hh rotated by
## `rot` about z, extruded from z0 to z0 + depth. Twelve triangles, each wound outward from
## the prism's own centre.
func _add_prism(st: SurfaceTool, cx: float, cy: float, z0: float, hw: float, hh: float,
		depth: float, rot: float) -> void:
	if hw <= 0.0 or hh <= 0.0 or depth <= 0.0:
		return
	var ca: float = cos(rot)
	var sa: float = sin(rot)
	var ax: Vector2 = Vector2(ca, sa) * hw
	var ay: Vector2 = Vector2(-sa, ca) * hh
	var c: Vector2 = Vector2(cx, cy)
	var f0: Vector2 = c - ax - ay
	var f1: Vector2 = c + ax - ay
	var f2: Vector2 = c + ax + ay
	var f3: Vector2 = c - ax + ay
	var z1: float = z0 + depth
	var p: PackedVector3Array = PackedVector3Array([
		Vector3(f0.x, f0.y, z1), Vector3(f1.x, f1.y, z1),
		Vector3(f2.x, f2.y, z1), Vector3(f3.x, f3.y, z1),
		Vector3(f0.x, f0.y, z0), Vector3(f1.x, f1.y, z0),
		Vector3(f2.x, f2.y, z0), Vector3(f3.x, f3.y, z0)])
	var mid: Vector3 = Vector3(cx, cy, (z0 + z1) * 0.5)
	_quad(st, p[0], p[1], p[2], p[3], mid)
	_quad(st, p[5], p[4], p[7], p[6], mid)
	_quad(st, p[4], p[5], p[1], p[0], mid)
	_quad(st, p[3], p[2], p[6], p[7], mid)
	_quad(st, p[1], p[5], p[6], p[2], mid)
	_quad(st, p[4], p[0], p[3], p[7], mid)


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
## points back at `inside`. Every material here is CULL_DISABLED as well, so a face whose
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


## A single triangle facing the viewer. Used for the two open surfaces — the CSG stub's one
## triangle and the parametric ribbon's soup — neither of which has an inside to wind away
## from. The normal is flipped toward +z so the lit face is the one the camera sees.
func _tri_front(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	if n.z < 0.0:
		n = -n
	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(b)
	st.set_normal(n)
	st.add_vertex(c)


# ── batching ───────────────────────────────────────────────────────────────────────────

## One SurfaceTool per colour, created on first use. 144 marks become one to two meshes
## instead of 144 nodes, and a colour that never fires never commits an empty surface.
func _sink(sinks: Dictionary, key: String) -> SurfaceTool:
	if sinks.has(key):
		return sinks[key] as SurfaceTool
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	sinks[key] = st
	return st


func _sink_colour(key: String) -> Color:
	match key:
		"cool":
			return C_COOL
		"voxel":
			return C_VOXEL
		"csg":
			return C_CSG
		"para":
			return C_PARA
		_:
			return C_WARM
	return C_WARM


func _flush(holder: Node3D, sinks: Dictionary, tag: String) -> void:
	for key in sinks.keys():
		_commit(holder, "Mark_" + str(key) + "_" + tag, sinks[key] as SurfaceTool,
			_sink_colour(str(key)), 0.60, 0.0)


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
