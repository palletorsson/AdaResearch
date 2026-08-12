extends Node3D
class_name OperationsGallery

## Operations Gallery — a SYNTHESIS artifact. One operation, disclosed four ways,
## on four panels of one wall.
##
## @identity
## essence: Twenty-six artifacts declare `workings` and each of them stands at ONE
##   value: this one shows the answer and seals the mechanism, that one shows the
##   path, the next lays out its ingredients, the last writes the rule out. The
##   gallery runs a single operation — Euclid's algorithm on one pair of whole
##   numbers — and builds all four disclosures at once, out of one descent
##   computed at build time, so the four accounts can be held against each other
##   instead of against memory.
## desire: To make the FAMILY WORD the exhibit. Not another artifact with an
##   opinion about how much to show; the wall where the four opinions are put in
##   the same light and made to account for the same arithmetic.
## critical_parameter: `divisibility` — WHICH PAIR is under the gallery. The four
##   panels never move, never change places and never change what kind of account
##   they give. Only the operation they are accounts of.
## triggers: Read the four panels at `exact` and they nearly agree — 24 = 3 x 8,
##   and the answer, the path, the ingredients and the rule are close to the same
##   picture. Read them at `adversarial` and they do not. The outcome panel holds
##   a single unit square; the trace panel holds a six-stage spiral.
## emerges: The cost of sealing a mechanism is not a property of the machine. It
##   is a property of the input. `outcome` is an honest account of 24 and 8 and a
##   nearly empty one of 21 and 13, and the machine is the same machine.
## needs: one descent [has, _run], four parallel panels [has], one unit scale
##   shared by every panel and every value [has], no random number anywhere [has],
##   no per-frame code [has]
## relationships: Synthesised from the twenty-six artifacts that declare
##   `workings`. The registry `kin` block records the vocabulary split, what was
##   taken and what was refused. It replaces none of them.
## truth: Disclosure is neither free nor uniform. Two pairs with the same answer
##   can cost two steps or six, and the panel that shows the answer cannot tell
##   you which one you are looking at.

# ═══════════════════════════════════════════════════════════════════════════
# THE FAMILY'S WORD, READ FROM THE MEMBER THAT OWNS IT
# ═══════════════════════════════════════════════════════════════════════════
#
# `workings` is carried by twenty-six artifacts in TWO dialects. Nineteen say
# outcome | trace | operands | expression; seven procedural benches say
# result | rule | trial | reject. This gallery is built on the MAJORITY list and
# it does not retype it — the panels are built by walking
# transform_composition_workbench.WORKINGS, which is where every adopter's own doc
# block says the word, the values and the order came from. That is slot_machine's
# discipline: PRELOADED rather than reached through class_name, because class_name
# lookups are not reliable headless and every frame of the evidence loop is
# rendered headless.
#
# So the row order of this exhibit is the family's and not a curator's. If the
# family ever reorders or extends the list, the wall follows, and _check_family()
# says so out loud rather than hanging a frame with nothing in it.
const WorkingsOwner = preload("res://commons/artifacts/transform_composition_workbench/transform_composition_workbench.gd")

## What this gallery was DESIGNED against. Never used to build anything — the
## builder walks the owner's live list — and kept only so divergence can be
## detected and reported at _ready.
const WORKINGS_AS_DESIGNED: PackedStringArray = ["outcome", "trace", "operands", "expression"]

# ═══════════════════════════════════════════════════════════════════════════
# THE AXIS — `divisibility`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHY NOT `workings` ITSELF. All twenty-six members use the word to stand at ONE
# value and forgo the other three. On this wall all four stand at once, and that
# simultaneity IS the object; an axis whose every value demolishes three quarters
# of the exhibit is not a variation of it. The word is EXHIBITED instead — it
# names the artifact, it names the four panels, it is engraved under each one —
# and what turns is the operation the four accounts are accounts OF. This is
# evidence_ladder's ruling on `evidence` and retention_corridor's on `retention`;
# the registry's `kin` block records it as a refusal, not an omission.
#
# WHAT VARIES. The pair of whole numbers Euclid's algorithm is run on. Four named
# cases, ordered by how much the two numbers have in common:
#
#   adversarial  21 and 13. Consecutive Fibonacci, and — verified by brute force
#                over every pair with a <= 24 rather than assumed — the UNIQUE
#                worst case at this scale: six division steps, and no other pair
#                under twenty-four reaches six. The two numbers share nothing but
#                the unit, and the search for that fact is as long as this
#                gallery's ruler can make it.
#   exact        24 and 8. b divides a. One step, gcd = b = 8. The strongest
#                commensurability there is: the answer IS one of the operands.
#   shared       24 and 15. gcd = 3, four steps. A common measure exists and is
#                neither of the numbers — the ordinary case.
#   coprime      23 and 11. gcd = 1 in two steps. The same answer as
#                `adversarial`, at a third of the work.
#
# THE FOURTH VALUE NAMES A RELATION TO THE ALGORITHM rather than to divisibility,
# and the asymmetry is deliberate: `coprime` and `adversarial` are equally
# coprime. That is precisely where divisibility stops being the whole story, and
# it is why this axis has four values instead of three.
@export_enum("adversarial", "exact", "shared", "coprime") var divisibility: String = "adversarial"

## The axis's table, keyed by the value — which is also the allow-list the
## declaration gate reads out of the code.
const PAIRS: Dictionary = {
	"adversarial": Vector2i(21, 13),
	"exact": Vector2i(24, 8),
	"shared": Vector2i(24, 15),
	"coprime": Vector2i(23, 11),
}

# ═══════════════════════════════════════════════════════════════════════════
# THE GAUGES — one ceiling each, fixed across every value and every panel
# ═══════════════════════════════════════════════════════════════════════════
#
# A_MAX is the ceiling of the unit ruler and it does NOT move with the pair. A
# 21-unit bar at `adversarial` is 21/24 of the drawing width and a 24-unit bar at
# `exact` fills it, so lengths are comparable across the wall AND across the
# sweep. Normalising each frame to its own largest operand would make every panel
# draw a full-width bar, and the ruler would say nothing at all about the quantity
# it exists to show.
#
# MAX_STEPS is the same discipline on the trace panel's step gauge and on its
# colour ramp. The true worst case at this scale is 6 (measured, not assumed); the
# gauge has 8 slots and the ramp divides by 7, both FIXED, so `exact` fills one of
# eight and `adversarial` six of eight and a visitor can see that six is not the
# top. A gauge whose largest value fills it cannot be told from a gauge that is
# clipping.
const A_MAX: int = 24
const MAX_STEPS: int = 8

# ── the wall ──────────────────────────────────────────────────────────────
const SLAB_W: float = 1.38
const SLAB_H: float = 1.38
const SLAB_T: float = 0.05          ## back plate: z from -SLAB_T to 0
const PITCH_X: float = 0.68
const PITCH_Y: float = 0.68
const PANEL_S: float = 0.62         ## the slate face, square
const BEZEL_S: float = 0.66
const BEZEL_T: float = 0.024
const FACE_Z: float = 0.012
const DRAW_Z: float = 0.017         ## the drawing plane, inside the bezel
const MARK_T: float = 0.006         ## every drawn mark's thickness in z

# ── the drawing, panel-local (origin = panel centre) ──────────────────────
const DRAW_W: float = 0.52
const U: float = DRAW_W / A_MAX          ## 0.0216667 m per unit — one number, derived
const RX0: float = -DRAW_W * 0.5         ## the rectangle's left edge
const RY0: float = -0.17                 ## the rectangle's bottom edge
const GAP: float = 0.005                 ## the seam between tiles / squares

const GAUGE_Y: float = 0.19
const GAUGE_H: float = 0.070
const GAUGE_W: float = 0.062
const GAUGE_PITCH: float = 0.065

const SCALE_Y: float = 0.20              ## operands: the fixed 24-unit rule
const TICK_H: float = 0.028
const BAR_A_Y: float = 0.05
const BAR_B_Y: float = -0.08
const BAR_T: float = 0.060

## expression: one written line. DERIVED, not chosen — the default font at
## font_size 48 and pixel_size 0.00072 puts a line at 48 * 0.00072 = 0.03456 m,
## and LINE_SPACING adds 12 * 0.00072 = 0.00864, so the pitch below is what the
## label will actually lay out and the two brass rules bracket the block instead
## of floating away from it.
const LINE_PITCH: float = 0.0432
const LINE_SPACING: float = 12.0
const TEXT_TOP: float = 0.24
## The engraved station word. Placed BELOW the tallest thing any panel can grow:
## the expression block at `adversarial` is eleven lines, 0.4752 m, and reaches
## -0.2352 from TEXT_TOP. The word's own block is ~0.052 m tall, so -0.272 leaves
## 11 mm of slate between them at the worst value and keeps every glyph inside the
## 0.62 m face. A caption that collides at one value of the axis is a difference a
## sweep would measure and credit to the axis.
const WORD_Y: float = -0.272

# ── palette: slate and brass, character for character from length_lantern, ──
# the housing sibling that already carries `workings`.
const C_SLATE: Color = Color(0.10, 0.11, 0.14)
const C_BRASS: Color = Color(0.72, 0.55, 0.22)
## The step ramp's cold end, from evidence_ladder, so a graded history reads the
## same way on both synthesis objects.
const C_LATE: Color = Color(0.35, 0.76, 1.0)
const C_FACE: Color = Color(0.13, 0.14, 0.17)     ## the panel slate, a shade up
const C_BEZEL: Color = Color(0.22, 0.20, 0.17)
const C_CHALK: Color = Color(0.88, 0.90, 0.95)
const C_ANSWER: Color = Color(0.98, 0.74, 0.26)   ## the common measure, called out
const C_RULE: Color = Color(0.55, 0.57, 0.62)     ## the fixed ruler

var _root: Node3D = null
var _built: bool = false
var _mats: Dictionary = {}

## THE ONE DESCENT. Each entry is Vector4i(a, b, q, r) for one division step.
## Everything drawn on all four panels is a read of this array. Nothing on this
## wall performs a second division.
var _steps: Array[Vector4i] = []
var _g: int = 1


func _ready() -> void:
	_check_family()
	_rebuild()
	_built = true


func apply_grid_config(config: Dictionary) -> void:
	var changed: bool = false
	if config.has("divisibility"):
		var d: String = String(config["divisibility"]).strip_edges().to_lower()
		if PAIRS.has(d) and d != divisibility:
			divisibility = d
			changed = true
	# Rebuild ONLY when something this wall owns actually changed, and only after
	# _ready has built once. An unconditional teardown here fires on every call,
	# including ones naming nothing on this artifact.
	if changed and _built:
		_rebuild()


## The shared-vocabulary guard. The wall is built from the owner's live list, so
## there is nothing here that can silently drift — but a family that grew a fifth
## value would grow a fifth panel this file has no account for, and that has to be
## loud rather than blank.
func _check_family() -> void:
	var live: PackedStringArray = _stations()
	if live != WORKINGS_AS_DESIGNED:
		push_error("operations_gallery: the `workings` value list moved. Designed against "
			+ str(WORKINGS_AS_DESIGNED) + "; transform_composition_workbench now declares "
			+ str(live) + ". Every value needs a builder in _panel_drawing().")


## The family's four values, in the family's order, from the member that owns
## them. Never retyped here.
func _stations() -> PackedStringArray:
	return WorkingsOwner.WORKINGS


# ═══════════════════════════════════════════════════════════════════════════
# THE OPERATION — one descent, and the only place a division happens
# ═══════════════════════════════════════════════════════════════════════════

## Euclid's algorithm, run once at build time and kept whole. Fills _steps and
## _g, which every panel reads.
##
## This is example_1_7's rule taken as a constraint rather than quoted: an exhibit
## that recomputes its arithmetic inside a second drawing routine is an exhibit
## that will eventually disagree with itself. Here the outcome panel's tile size,
## the trace panel's square sides, its step gauge, the operands panel's two bars
## and the expression panel's written lines all index this one array. There is
## nothing else on this wall for any of them to disagree with.
func _run() -> void:
	_steps.clear()
	var pair: Vector2i = PAIRS.get(divisibility, PAIRS["adversarial"])
	var a: int = pair.x
	var b: int = pair.y
	while b != 0:
		@warning_ignore("integer_division")
		var q: int = a / b
		var r: int = a % b
		_steps.append(Vector4i(a, b, q, r))
		a = b
		b = r
	_g = maxi(a, 1)


func _pair() -> Vector2i:
	return PAIRS.get(divisibility, PAIRS["adversarial"])


## The Euclid square decomposition, DERIVED from _steps rather than re-divided.
## Cut q squares of side b off the a-by-b rectangle; what is left is r by b; turn
## ninety degrees and repeat. Each entry is [x, y, side, step_index] in UNITS.
## The alternation is what makes the Fibonacci pair spiral.
func _squares() -> Array:
	var out: Array = []
	var x: float = 0.0
	var y: float = 0.0
	var horiz: bool = true
	for i in range(_steps.size()):
		var st: Vector4i = _steps[i]
		var s: float = float(st.y)
		var q: int = st.z
		for k in range(q):
			if horiz:
				out.append([x + float(k) * s, y, s, i])
			else:
				out.append([x, y + float(k) * s, s, i])
		if horiz:
			x += float(q) * s
		else:
			y += float(q) * s
		horiz = not horiz
	return out


# ═══════════════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════════════

func _rebuild() -> void:
	if is_instance_valid(_root):
		remove_child(_root)
		_root.queue_free()
	_mats.clear()
	_root = Node3D.new()
	_root.name = "Gallery_%s" % divisibility
	add_child(_root)

	_run()
	_wall(_root)

	var words: PackedStringArray = _stations()
	for i in range(words.size()):
		var panel := Node3D.new()
		panel.name = "Panel_%s" % words[i]
		panel.position = _panel_origin(i)
		_root.add_child(panel)
		_panel_furniture(panel, words[i])
		_panel_drawing(panel, words[i])


## Two columns, two rows, reading order — the family's list walked left to right,
## top row first. A single row of four was laid out and rasterised first; see the
## registry's framing_why for the measurement that turned the row into a square.
func _panel_origin(i: int) -> Vector3:
	var col: int = i % 2
	@warning_ignore("integer_division")
	var row: int = i / 2
	return Vector3((float(col) - 0.5) * PITCH_X, (0.5 - float(row)) * PITCH_Y, 0.0)


func _wall(root: Node3D) -> void:
	# No property is set on a material after _mat() hands it back: the cache is keyed
	# by colour and emission only, so mutating one here would silently re-finish
	# every other mesh sharing that colour — the operands bars' notches, in this case.
	root.add_child(_box(Vector3(0.0, 0.0, -SLAB_T * 0.5), Vector3(SLAB_W, SLAB_H, SLAB_T),
		_mat(C_SLATE, 0.0)))


## THE BEZEL IS A FRAME, AND IT WAS BUILT AS A SLAB. The first version placed one
## BoxMesh of BEZEL_S x BEZEL_S x BEZEL_T at z = BEZEL_T * 0.5, which spans z from
## 0.000 to 0.024 across the panel's whole 0.66 m square — so it enclosed the face
## (0.009 to 0.015) and every mark the axis draws (0.014 to 0.020). All four values
## photographed as the front of the bezel. Nothing failed: the script compiled, the
## declaration gate passed, the sweep produced four frames and the critic reported a
## closest pair of 0.09%, which is what four photographs of the same blank slab
## measure. The only thing visible on the whole wall was the part of the expression
## label that OVERFLOWS its panel — the tail of "gcd(a, b) = gcd(b, a mod b)" sticking
## out past the edge where the slab could not cover it, which is what gave it away.
##
## Four rails, outer BEZEL_S and inner PANEL_S, leaving the opening the face sits in.
## The look is unchanged and the frame now frames something.
func _panel_furniture(panel: Node3D, word: String) -> void:
	var bezel: StandardMaterial3D = _mat(C_BEZEL, 0.0)
	var face: StandardMaterial3D = _mat(C_FACE, 0.0)
	var rail: float = (BEZEL_S - PANEL_S) * 0.5
	var mid: float = (BEZEL_S - rail) * 0.5
	var zc: float = BEZEL_T * 0.5
	panel.add_child(_box(Vector3(0.0, mid, zc), Vector3(BEZEL_S, rail, BEZEL_T), bezel))
	panel.add_child(_box(Vector3(0.0, -mid, zc), Vector3(BEZEL_S, rail, BEZEL_T), bezel))
	panel.add_child(_box(Vector3(-mid, 0.0, zc), Vector3(rail, PANEL_S, BEZEL_T), bezel))
	panel.add_child(_box(Vector3(mid, 0.0, zc), Vector3(rail, PANEL_S, BEZEL_T), bezel))
	panel.add_child(_box(Vector3(0.0, 0.0, FACE_Z), Vector3(PANEL_S, PANEL_S, 0.006), face))
	# The family word, engraved on the panel it names. Identical at every value of
	# the axis, so nothing a sweep measures here is a caption changing.
	var l := _text(word.to_upper(), Vector3(0.0, WORD_Y, DRAW_Z), 0.0011, C_BRASS)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(l)


func _panel_drawing(panel: Node3D, word: String) -> void:
	match word:
		"outcome":
			_draw_outcome(panel)
		"trace":
			_draw_trace(panel)
		"operands":
			_draw_operands(panel)
		"expression":
			_draw_expression(panel)
		_:
			# The family grew a value this file has no account of. Say so on the
			# wall rather than hanging an empty frame that photographs as inert.
			push_error("operations_gallery: no drawing for `workings` value '%s'" % word)
			panel.add_child(_text("NO ACCOUNT\nFOR THIS VALUE",
				Vector3(0.0, 0.0, DRAW_Z), 0.0013, C_ANSWER))


# ── PANEL 1: outcome — the answer, with the mechanism sealed ──────────────
#
# The a-by-b rectangle ruled into g-by-g tiles. The whole content of "the gcd is
# g" is that BOTH lengths are whole multiples of it, and this is that sentence
# drawn. Nothing here says how g was found, or that anything was found at all.
#
# Built as one filled plate plus its interior seams rather than as a/g x b/g
# separate tiles: the same picture at a twentieth of the mesh count, since at
# `adversarial` the tiling is 21 x 13 unit tiles — 273 of them — and 32 seam bars
# draw it exactly.
#
# THE COARSENESS IS THE READING. At `exact` there are two seams and three tiles
# 70 px across. At `adversarial` and `coprime` the tile IS the unit, 8.8 px, and
# the plate reads as a fine mesh. The answer to a coprime pair is that no coarser
# measure exists, and a nearly featureless plate is the honest picture of it.
func _draw_outcome(panel: Node3D) -> void:
	var pair: Vector2i = _pair()
	var w: float = float(pair.x) * U
	var h: float = float(pair.y) * U
	panel.add_child(_plate(RX0 + GAP * 0.5, RY0 + GAP * 0.5, w - GAP, h - GAP, _mat(C_BRASS, 0.0)))

	var seam: StandardMaterial3D = _mat(C_FACE, 0.0)
	@warning_ignore("integer_division")
	var cols: int = pair.x / _g
	@warning_ignore("integer_division")
	var rows: int = pair.y / _g
	for i in range(1, cols):
		panel.add_child(_plate(RX0 + float(i * _g) * U - GAP * 0.5, RY0, GAP, h, seam, 0.001))
	for j in range(1, rows):
		panel.add_child(_plate(RX0, RY0 + float(j * _g) * U - GAP * 0.5, w, GAP, seam, 0.001))

	# The common measure itself, one tile, in the answer colour.
	panel.add_child(_plate(RX0 + GAP * 0.5, RY0 + GAP * 0.5,
		float(_g) * U - GAP, float(_g) * U - GAP, _mat(C_ANSWER, 1.1), 0.002))


# ── PANEL 2: trace — the path it took ─────────────────────────────────────
#
# Euclid's own picture: cut off the largest square that fits, keep cutting, turn,
# repeat. The number of DISTINCT square sizes is the number of division steps and
# the smallest square's side is the answer. Every square is graded by its step
# index along a ramp whose denominator is MAX_STEPS - 1 and NOT this value's own
# step count, so one colour means one stage of one descent at every value.
#
# The gauge above the rectangle is that step count against the same fixed
# ceiling. It counts _steps.size() — divisions actually performed — and not a
# proxy for them; the expression panel prints one line per entry of the same
# array, so the two panels cannot report different amounts of work.
func _draw_trace(panel: Node3D) -> void:
	var pair: Vector2i = _pair()
	var w: float = float(pair.x) * U
	var h: float = float(pair.y) * U
	for sq in _squares():
		var x: float = float(sq[0])
		var y: float = float(sq[1])
		var s: float = float(sq[2])
		var i: int = int(sq[3])
		panel.add_child(_plate(RX0 + x * U + GAP * 0.5, RY0 + y * U + GAP * 0.5,
			s * U - GAP, s * U - GAP, _mat(_step_color(i), 0.35)))

	var edge: StandardMaterial3D = _mat(C_RULE, 0.0)
	# 0.005 m, not the 0.004 this was drawn at first: at 499.5 px/m a 0.004 rule is
	# 1.8 px and aliases. Every mark on this wall was checked against the frame's
	# px-per-metre, computed from dna.framing, before it was drawn.
	var t: float = 0.005
	panel.add_child(_plate(RX0, RY0, w, t, edge, 0.002))
	panel.add_child(_plate(RX0, RY0 + h - t, w, t, edge, 0.002))
	panel.add_child(_plate(RX0, RY0, t, h, edge, 0.002))
	panel.add_child(_plate(RX0 + w - t, RY0, t, h, edge, 0.002))

	var n: int = _steps.size()
	var empty: StandardMaterial3D = _mat(C_RULE.darkened(0.55), 0.0)
	for k in range(MAX_STEPS):
		var gx: float = RX0 + float(k) * GAUGE_PITCH
		if k < n:
			panel.add_child(_plate(gx, GAUGE_Y, GAUGE_W, GAUGE_H, _mat(_step_color(k), 0.35)))
		else:
			panel.add_child(_plate(gx, GAUGE_Y, GAUGE_W, 0.006, empty))


## The ramp position of step i. The denominator is the FIXED ceiling and never the
## current descent's length: normalising per value would paint every value's first
## square identically and its last square identically, and the ramp would carry no
## information about how long the descent actually was.
func _step_color(i: int) -> Color:
	return C_BRASS.lerp(C_LATE, clampf(float(i) / float(MAX_STEPS - 1), 0.0, 1.0))


# ── PANEL 3: operands — what went in ──────────────────────────────────────
#
# The two lengths from a common origin, against a 24-unit rule that is IDENTICAL
# at every value of the axis. Each bar is notched at every unit, so a bar is
# COUNTED and not merely long, and the count is the number itself.
#
# No answer, no remainder, no square: that is the whole discipline of this
# station. The numerals are here because the numerals ARE the ingredients, and
# they sit inside the panel whose subject they are.
func _draw_operands(panel: Node3D) -> void:
	var pair: Vector2i = _pair()
	var rule: StandardMaterial3D = _mat(C_RULE, 0.0)
	panel.add_child(_plate(RX0, SCALE_Y, float(A_MAX) * U, 0.005, rule))
	for k in range(0, A_MAX + 1, 4):
		panel.add_child(_plate(RX0 + float(k) * U - 0.003, SCALE_Y, 0.006, TICK_H, rule))

	_bar(panel, pair.x, BAR_A_Y, C_BRASS)
	_bar(panel, pair.y, BAR_B_Y, C_BRASS.lerp(C_LATE, 0.45))

	# Above the left end of each bar, so the label is inside the panel at a = 24
	# as well as at a = 21. A caption that crops at one value of the axis is a
	# difference the sweep would measure and credit to the axis.
	panel.add_child(_text("a = %d" % pair.x,
		Vector3(RX0 + 0.07, BAR_A_Y + BAR_T + 0.028, DRAW_Z), 0.0008, C_CHALK))
	panel.add_child(_text("b = %d" % pair.y,
		Vector3(RX0 + 0.07, BAR_B_Y + BAR_T + 0.028, DRAW_Z), 0.0008, C_CHALK))


func _bar(panel: Node3D, n: int, y: float, col: Color) -> void:
	panel.add_child(_plate(RX0, y, float(n) * U, BAR_T, _mat(col, 0.0)))
	var notch: StandardMaterial3D = _mat(C_SLATE, 0.0)
	# The notch pitch is one unit — 8.81 px in the capture — and the notch itself is
	# 0.004 m, 1.8 px, so the bar reads as a comb rather than as a solid length. At
	# the 0.003 it was first drawn at the comb was 1.4 px and would have greyed out.
	for k in range(1, n):
		panel.add_child(_plate(RX0 + float(k) * U - 0.002, y, 0.004, BAR_T, notch, 0.001))


# ── PANEL 4: expression — the rule, with this pair substituted ────────────
#
# The two lines that ARE the algorithm, then the descent written out one line per
# entry of _steps, then the answer. The line count is the step count, out of the
# same array the trace panel's gauge fills, so the two are two readings and not
# two claims.
func _draw_expression(panel: Node3D) -> void:
	var pair: Vector2i = _pair()
	var lines: PackedStringArray = PackedStringArray([
		"gcd(a, b) = gcd(b, a mod b)",
		"gcd(a, 0) = a",
		"",
	])
	for st in _steps:
		lines.append("%d = %d x %d + %d" % [st.x, st.z, st.y, st.w])
	lines.append("")
	lines.append("gcd(%d, %d) = %d" % [pair.x, pair.y, _g])

	# THE BLOCK IS LEFT-ALIGNED, so it is hung from the drawing's left margin and not
	# from the panel's centre. This line first read x = 0.0 under a comment claiming
	# "Label3D centres its block on the node origin" — which _text(), three hundred
	# lines down in this same file, contradicts: it sets HORIZONTAL_ALIGNMENT_LEFT.
	# The longest line, gcd(a, b) = gcd(b, a mod b), is 27 characters at 48 px and
	# pixel_size 0.00072, about 0.467 m of an 0.52 m drawing width — so hung from the
	# centre it cleared the panel's right edge by roughly 0.157 m and the tail of the
	# identity hung in mid-air beside the wall. It was the only mark visible while the
	# bezel was a slab, and finding it is what found the slab. The y offset is still
	# computed from the known line count rather than trusted to a flag.
	var span: float = float(lines.size()) * LINE_PITCH
	var l := _text("\n".join(lines), Vector3(RX0, TEXT_TOP - span * 0.5, DRAW_Z), 0.00072, C_CHALK)
	l.line_spacing = LINE_SPACING
	panel.add_child(l)
	# Two brass rules, both at FIXED heights: one over the block, one under the two
	# lines that are the rule itself, separating the algorithm from this pair's
	# descent. A rule pinned to the bottom of the block would move with the line
	# count, and the sweep would be measuring furniture.
	panel.add_child(_plate(RX0, TEXT_TOP + 0.014, DRAW_W * 0.86, 0.006, _mat(C_BRASS, 0.5)))
	panel.add_child(_plate(RX0, TEXT_TOP - 2.0 * LINE_PITCH - 0.008, DRAW_W * 0.86, 0.006,
		_mat(C_BRASS, 0.5)))


# ═══════════════════════════════════════════════════════════════════════════
# PRIMITIVES
# ═══════════════════════════════════════════════════════════════════════════

## A flat mark on the drawing plane. x, y = LOWER-LEFT in panel-local metres.
func _plate(x: float, y: float, w: float, h: float, mat: Material, lift: float = 0.0) -> MeshInstance3D:
	return _box(Vector3(x + w * 0.5, y + h * 0.5, DRAW_Z + lift),
		Vector3(maxf(w, 0.001), maxf(h, 0.001), MARK_T), mat)


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = center
	mi.material_override = mat
	return mi


## Cached, so a 32-seam plate does not build 32 identical materials.
func _mat(c: Color, emit: float) -> StandardMaterial3D:
	var key: String = "%s|%.2f" % [c.to_html(false), emit]
	if _mats.has(key):
		return _mats[key] as StandardMaterial3D
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.55
	m.metallic = 0.25
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	_mats[key] = m
	return m


## Text lying flat on a body. Billboarding is disabled on purpose: the capture
## runs LabelFramer, which mounts a plate behind billboarded text, and a plate the
## player never sees is not evidence about this artifact.
func _text(s: String, pos: Vector3, px: float, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = s
	l.font_size = 48
	l.pixel_size = px
	l.modulate = col
	l.outline_size = 5
	l.outline_modulate = Color(0.04, 0.04, 0.05, 0.9)
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = pos
	return l
