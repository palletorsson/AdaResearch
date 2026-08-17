extends Node3D
class_name OrderPair

## order_pair — one word, two operations, and only one of them cares.
##
## THE FAMILY. Three artifacts declare an axis called `order` and they declare it in
## TWO vocabularies:
##
##   VectorSubtraction                  a_minus_b | b_minus_a | reciprocal   default a_minus_b
##   example_1_3_vector_subtraction_vr  a_minus_b | b_minus_a | reciprocal   default a_minus_b
##   animatedcubebuilder                ascend | descend | together          default ascend
##
## THE TWO VECTOR NAMES ARE NOT ONE SCENE, and that was checked rather than assumed:
## algorithms/vectors/04_vector_subtraction/VectorSubtraction.tscn runs
## VectorSubtraction.gd, which `extends "res://algorithms/vectors/shared/vector_scene_base.gd"`
## and builds three grabbable arrow rigs plus a physics balance beam;
## algorithms/vectors/noc_ch01/example_1_3_vector_subtraction_vr.tscn runs a script that
## `extends Node3D` and builds three 0.1 m cylinders and a Label3D. Two scenes, two
## scripts, two different arrow geometries. What they share is the WORD and the VALUE
## LIST, and the second one says so in its own header: both taken "character for
## character from the sibling bench VectorSubtraction". A declared lineage, not a hidden
## family — and the sibling test applies: they must measure alike on `order`, and they
## will, because their `order` code is line-for-line the same decision.
##
## THE ARGUMENT, AND THE CODE SHARPENS IT THREE TIMES.
##
## The brief said: subtraction does not commute, so `order` changes the RESULT; cube
## building does commute, so `order` changes only the PATH. Both halves are true and the
## code adds three things the brief did not have.
##
##   1. `reciprocal` IS NOT A THIRD ORDER. It is the UNION of the first two, and it does
##      not touch the computation at all. In both members the operand swap is guarded on
##      the literal string "b_minus_a" —
##
##          var head: Vector3 = a
##          var tail: Vector3 = b
##          if order == "b_minus_a":
##              head = b
##              tail = a
##
##      — so under `reciprocal` head is still a and tail is still b, i.e. the a_minus_b
##      computation, untouched. What `reciprocal` adds is a SECOND ARROW at -diff, built
##      only for that value (`_ensure_reverse_vector()` / `_apply_order()`), amber in
##      both members. reciprocal's picture is therefore a_minus_b's picture PLUS
##      b_minus_a's arrow. A superset, not an alternative.
##
##      AND THE WORD IS WRONG. The reciprocal of a vector is not defined; the arrow drawn
##      is the ADDITIVE inverse, -(a-b). Two benches copied the wrong word character for
##      character. It is kept here because it is the family's word, and it is corrected
##      in `declines`.
##
##   2. `together` IS NOT A THIRD ORDER EITHER. It is the ABSENCE of one.
##      `_phase_order()` returns an EMPTY ARRAY for it, and `start_animation()` reads that
##      empty array as: reveal every sphere, every line and every triangle in one frame,
##      set COMPLETE, call `_finish()`. No sequence at all.
##
##   3. SO BOTH VOCABULARIES PUT THEIR UNION INSIDE THEIR AXIS. That is the family's real
##      shared structure — not the word `order`, which means two different things, but
##      the habit of making "all of it at once" the third value. CLAUDE.md's own rule says
##      never put an all-rungs value in an axis; both members did, twice, independently.
##      Here they are kept, because the rule is about AABB INFLATION and neither of these
##      inflates anything: reciprocal is one more arrow inside a fixed board, together is
##      a superposition inside one slot. The stage is what fixes the box, and it is
##      identical in all eighteen cells.
##
## AND THE ASYMMETRY THAT IS THE WHOLE POINT. On the vector side the order is READ BY THE
## ARITHMETIC: `head - tail` is a different vector when head and tail swap, exactly the
## negative of the first, so a-b and b-a are two answers. On the cube side the order is
## read by the ANIMATION and by nothing else: `_finish()` under the shipped closure
## `strata` does nothing at all ("nothing is hidden, all three layers are left standing"),
## so ascend, descend and together each end with the same 8 corner handles, the same 12
## edge cylinders and the same 12 triangles visible. Three routes, one object. The
## difference between them exists only while the clock is running, and a still has no
## clock.
##
## WHAT THIS BENCH DOES. One plate carries both operations side by side, split by a low
## seam wall:
##
##   LEFT   the subtraction, drawn in relief on a board: a and b as real arrows from a
##          shared origin, and the difference as a third arrow. `result` shows the
##          difference; `path` shows the walk that reaches it (out along the head, back
##          along the tail) with a size-graded marker at each step.
##   RIGHT  the cube, built from the source's own eight vertices, twelve edges and twelve
##          triangles. `result` shows the finished object. `path` shows the assembly
##          order as three courses on three plinths: a miniature of each phase, standing
##          in the slot it was revealed in.
##
## AND THE ONE STRUCTURAL DECISION, which is the argument rather than a layout choice.
## THE CUBE'S RESULT IS DRAWN UNDER EVERY VALUE OF `order`, BECAUSE IT DOES NOT DEPEND ON
## ONE. THE VECTOR'S RESULT IS DRAWN ONLY UNDER A VECTOR VALUE, BECAUSE IT CANNOT BE
## DRAWN WITHOUT NAMING AN ORDER. That is not symmetry broken by accident; it is the
## thesis made structural, and it is what produces the designed null: in the `result`
## reading, ascend, descend and together are ONE PHOTOGRAPH, because the only body any of
## them would add is already standing and is the same body for all three.
##
## Deterministic and clock-free: no RandomNumberGenerator anywhere, no randf, no noise,
## no _process, no Timer, no tween, no await. Every vertex is arithmetic on the constants
## below. Two builds of one cell are the same mesh. That matters more than usual here,
## because ALL THREE SOURCES ARE CLOCKS: VectorSubtraction recomputes in _process from
## grab-sphere positions, example_1_3 recomputes in _process from two exported Vector3s,
## and animatedcubebuilder is a state machine with an 0.5 s initial delay, a 3.0 s await
## inside setup_scene() and per-item step durations of 0.5 / 0.2 / 0.15 s. The third one
## cannot be photographed mid-argument at all without the shutter time becoming the
## variable.


## WHICH ORDER, IN WHICH VOCABULARY. Six values, three from each of the family's two
## vocabularies, and every one is a word its own member actually ships.
##
##   a_minus_b   VectorSubtraction + example_1_3. head = a, tail = b — the literal
##               `vector_a - vector_b` both benches had welded into _process. The green
##               difference arrow points up-left. CHANGES-RESULT.
##   b_minus_a   the same two. head = b, tail = a. The difference arrow is the exact
##               negative, so it points down-right through the origin: same length, same
##               line, opposite sense. CHANGES-RESULT.
##   reciprocal  the same two. The computation is a_minus_b's; a second arrow at -diff is
##               added. The picture is the union of the other two. CHANGES-RESULT (it
##               changes how many results are on the table, not which one is computed).
##   ascend      animatedcubebuilder. _phase_order() -> ["vertices","edges","triangles"].
##               The shipped chain: 0D, then 1D, then 2D. CHANGES-PATH-ONLY.
##   descend     animatedcubebuilder. -> ["triangles","edges","vertices"]. The same
##               machine backwards. CHANGES-PATH-ONLY.
##   together    animatedcubebuilder. -> [] — no phases. Everything is revealed in one
##               frame. CHANGES-PATH-ONLY, and it removes the path rather than reversing
##               it, so its course is one slot deep and the other two stand bare.
@export_enum("a_minus_b", "b_minus_a", "reciprocal", "ascend", "descend", "together") var order: String = "a_minus_b":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not ORDERS.has(picked):
			return                      ## an unreachable value keeps the standing figure
		order = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## WHAT IS SHOWN OF THE OPERATION. Three values, and `result` is the one that carries the
## thesis, because it is where a path-only order has nothing left to say.
##
##   result  the finished thing. The cube, always; the difference arrow, only if the
##          active word names a difference.
##   path    the route. The walk for a vector word; the three assembly courses for a cube
##          word. The finished cube is NOT drawn here — a route is not its destination.
##   both    the result standing in front of the route it was reached by. The busiest
##          cell in the sheet is (reciprocal, both): two operands, two differences, two
##          walks and six step markers.
@export_enum("result", "path", "both") var reading: String = "result":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not READINGS.has(picked):
			return
		reading = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One cell, or all six orders in a row. NOT PART OF EITHER AXIS, and the registry
## fixture pins `single`. capture_config_sweep unions the AABB across a spec's variants,
## so a six-wide row declared inside `order` would frame every single cell against seven
## and a half metres and photograph the 0.026 m arrows as hairs. `ladder` is a design
## view for reading the whole axis at once on a bench, not a map placement.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const ORDERS: PackedStringArray = ["a_minus_b", "b_minus_a", "reciprocal",
	"ascend", "descend", "together"]
const READINGS: PackedStringArray = ["result", "path", "both"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]
## Which vocabulary a word belongs to. The split is not cosmetic: it decides whether the
## left half or the right half has anything to say at that value.
const VECTOR_WORDS: PackedStringArray = ["a_minus_b", "b_minus_a", "reciprocal"]
const CUBE_WORDS: PackedStringArray = ["ascend", "descend", "together"]

# ── the stage, identical to the millimetre in all eighteen cells ───────────────────────
## THE TWO BOARDS ARE THE WHOLE REASON THE AABB NEVER MOVES. They stand 0.50 m tall on the
## plate, which is taller than anything either half can draw (the tallest drawn thing is
## the +difference arrowhead at 0.506 m, and the cube tops out at 0.424 m), and the plate
## is wider and deeper than anything either half can reach. So the world box is
## 1.16 x 0.524 x 0.60 before a single order-dependent body exists. Without them the
## height of the box would be a fact about which word was picked, the camera would move
## between cells, and every measured pair would carry a framing difference it did not
## earn.
const PLATE_HX: float = 0.58
const PLATE_HZ: float = 0.30
const PLATE_T: float = 0.024
const BOARD_W: float = 0.54
const BOARD_H: float = 0.50
const BOARD_T: float = 0.018
const BOARD_Z: float = -0.28              ## centre; front face at -0.271
const HALF_X: float = 0.28                ## centre of each half, +- this
const SEAM_W: float = 0.014
const SEAM_H: float = 0.060
const SEAM_Z0: float = -0.28
const SEAM_Z1: float = 0.24

# ── the subtraction, drawn as relief on the left board ─────────────────────────────────
## a and b in figure units, then one scale. The units are chosen so the difference is
## nearly VERTICAL: a - b = (-0.24, 0.96), which points up and slightly left, and b - a
## points down and slightly right. That is deliberate — the anti-commutative pair is a
## single line through the origin read in two senses, which is the most legible thing a
## still can say about the sign of an order, and it is the source's own claim ("both
## differences at once, nose to nose through the origin") drawn rather than asserted.
const A_UNIT: Vector2 = Vector2(0.62, 0.74)
const B_UNIT: Vector2 = Vector2(0.86, -0.22)
const VEC_S: float = 0.235                ## metres per figure unit
const VEC_Y: float = 0.274                ## the shared origin, at the board's centre
const Z_FIG: float = -0.271               ## the board's front face; relief grows from it
const ARROW_W: float = 0.026              ## in-plane width of an operand/difference rod
const ARROW_T: float = 0.026              ## relief depth of the same
const HEAD_W: float = 0.046
const HEAD_L: float = 0.050
## Every rod starts this far out from the shared origin, so four arrows meeting at a point
## do not interpenetrate; the origin block covers the gap.
const ORIGIN_GAP: float = 0.018
const ORIGIN_BLOCK: float = 0.030
const WALK_W: float = 0.016
const WALK_T: float = 0.016
const WALK_HEAD_W: float = 0.030
const WALK_HEAD_L: float = 0.034
## The walk stands PROUD of the arrows rather than behind them, because its first leg is
## the same segment as one of the operands and two coplanar rods on one line would
## z-fight. 0.026 of relief for the arrows, then 0.016 more for the walk.
const WALK_Z: float = Z_FIG + ARROW_T
## Step markers, one per waypoint, graded by size so the sequence is readable without a
## numeral. Step 0 at the origin, step 1 at the head's tip, step 2 at the difference.
const MARK_0: float = 0.020
const MARK_1: float = 0.028
const MARK_2: float = 0.036

# ── the cube, built from animatedcubebuilder's own three lists ─────────────────────────
## Copied verbatim from the source: eight vertices in its order, twelve edges in its
## order, twelve triangles in its order — including the fact that its triangle list is
## two per face with the diagonal split, which is why the faces here are drawn as PAIRS
## of shrunken triangles rather than as six squares. The count the picture reports is 12,
## because 12 is what the source builds.
const CUBE_V: PackedVector3Array = [
	Vector3(-0.5, -0.5, -0.5), Vector3(0.5, -0.5, -0.5),
	Vector3(0.5, 0.5, -0.5), Vector3(-0.5, 0.5, -0.5),
	Vector3(-0.5, -0.5, 0.5), Vector3(0.5, -0.5, 0.5),
	Vector3(0.5, 0.5, 0.5), Vector3(-0.5, 0.5, 0.5)]
const CUBE_EDGES: Array = [
	[0, 1], [1, 2], [2, 3], [3, 0],
	[4, 5], [5, 6], [6, 7], [7, 4],
	[0, 4], [1, 5], [2, 6], [3, 7]]
const CUBE_TRIS: Array = [
	[0, 1, 4], [1, 5, 4], [2, 3, 6], [3, 7, 6],
	[4, 5, 7], [5, 6, 7], [1, 0, 2], [0, 3, 2],
	[0, 4, 3], [4, 7, 3], [5, 1, 6], [1, 2, 6]]
const CUBE_SIDE: float = 0.30
const CUBE_Y: float = 0.274               ## the same height as the vector origin
const CUBE_Z: float = -0.06
const CORNER_S: float = 0.038             ## the grab-sphere handles, as blocks
const EDGE_T: float = 0.020
## Each triangle is shrunk toward its own centroid, so the corners and edges stay visible
## around it and the diagonal seam between the two halves of a face stays open. The source
## draws its triangles at alpha 0.6; an opaque shrunken patch says the same thing to a
## still and does not depend on a transparency sort.
const FACE_K: float = 0.60

# ── the assembly courses, drawn as bodies on three plinths ─────────────────────────────
const SLOT_PITCH: float = 0.165
const PLINTH_W: float = 0.150
const PLINTH_D: float = 0.160
const PLINTH_T: float = 0.012
const PLINTH_Z: float = 0.20
const MINI_SIDE: float = 0.13
## The miniature's scale, applied to every part size as well as to the cube itself, so a
## small corner block is a small corner block and not a differently-proportioned one.
const MINI_K: float = MINI_SIDE / CUBE_SIDE

const LADDER_PITCH: float = 1.24

# ── colour ─────────────────────────────────────────────────────────────────────────────
## Rec.709 luminance of each, written down so the greyscale reading is checkable rather
## than hoped, because the critic measures luminance by default and only rescues a
## colour-only pair afterwards:
##   board 0.139 · plate 0.180 · plinth 0.250 · face1 0.276 · face2 0.321 · face0 0.358
##   seam 0.430 · walk2 0.440 · b 0.331 · a 0.398 · origin 0.510 · walk 0.617
##   counter 0.638 · corner 0.651 · diff 0.861 · edge 0.939
## No two bodies that TOUCH sit within 0.10 of each other. The pair that comes closest is
## `a` 0.398 against `b` 0.331 at the shared origin, and they are never a distinction any
## measured pair depends on — both operands are drawn in every one of the eighteen cells.
const C_PLATE: Color = Color(0.17, 0.18, 0.21)
const C_BOARD: Color = Color(0.13, 0.14, 0.16)
const C_PLINTH: Color = Color(0.24, 0.25, 0.28)
const C_SEAM: Color = Color(0.42, 0.43, 0.46)
const C_ORIGIN: Color = Color(0.50, 0.51, 0.54)
const C_A: Color = Color(0.62, 0.36, 0.12)
const C_B: Color = Color(0.20, 0.34, 0.62)
const C_DIFF: Color = Color(0.55, 1.00, 0.40)
## The sources' counter-difference is Color(1.0, 0.85, 0.35) in BOTH members — amber at
## Rec.709 0.846 against their green at 0.861. Isoluminant to within 0.015: a hue-only
## distinction, which is precisely the thing the pixel critic cannot see. Darkened to
## 0.638 so the union reads as a union of two DIFFERENT arrows and so the two reciprocal
## pairs are ordered rather than tied. Recorded in `declines`.
const C_COUNTER: Color = Color(0.86, 0.62, 0.16)
const C_WALK: Color = Color(1.00, 0.50, 0.65)
const C_WALK2: Color = Color(0.70, 0.36, 0.46)
const C_CORNER: Color = Color(0.25, 0.80, 0.35)
const C_EDGE: Color = Color(0.93, 0.94, 0.96)
## The source's three-colour face rotation, kept, with one repair: its third colour is
## Color(0.1, 0.1, 0.1) at alpha 0.6, which opaque is 0.100 luminance against a 0.139
## board and photographs as a hole rather than as a face. Raised to 0.321.
const C_FACE_0: Color = Color(0.80, 0.22, 0.42)
const C_FACE_1: Color = Color(0.78, 0.14, 0.14)
const C_FACE_2: Color = Color(0.32, 0.32, 0.34)

const SIGNS: PackedFloat32Array = [-1.0, 1.0]

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
	if config_data.has("order"):
		order = str(config_data["order"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
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
	var words: PackedStringArray = PackedStringArray()
	if layout == "ladder":
		words = ORDERS.duplicate()
	else:
		words.append(_pick(order, ORDERS, "a_minus_b"))
	var view: String = _pick(reading, READINGS, "result")
	var count: int = words.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Cell_" + words[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_stage(holder)
		if view == "result" or view == "both":
			_build_result(holder, words[i])
		if view == "path" or view == "both":
			_build_path(holder, words[i])


# ── the stage ──────────────────────────────────────────────────────────────────────────

func _build_stage(holder: Node3D) -> void:
	var plate := SurfaceTool.new()
	plate.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(plate, Vector3(0.0, PLATE_T * 0.5, 0.0),
		Vector3(PLATE_HX * 2.0, PLATE_T, PLATE_HZ * 2.0))
	_commit(holder, "Plate", plate, C_PLATE, 0.95)

	var boards := SurfaceTool.new()
	boards.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s in SIGNS:
		_add_box(boards, Vector3(float(s) * HALF_X, PLATE_T + BOARD_H * 0.5, BOARD_Z),
			Vector3(BOARD_W, BOARD_H, BOARD_T))
	_commit(holder, "Boards", boards, C_BOARD, 0.90)

	## The seam. Two vocabularies with a wall between them, and the wall is 0.06 m tall so
	## it reads as a division rather than as a third body.
	var seam := SurfaceTool.new()
	seam.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(seam, Vector3(0.0, PLATE_T + SEAM_H * 0.5, (SEAM_Z0 + SEAM_Z1) * 0.5),
		Vector3(SEAM_W, SEAM_H, SEAM_Z1 - SEAM_Z0))
	_commit(holder, "Seam", seam, C_SEAM, 0.80)

	## Three empty plinths, always. They are the assembly's TIME AXIS and they exist
	## whether or not the active word has anything to stand on them — which is what makes
	## `together`'s two bare slots legible as two bare slots rather than as a smaller rig.
	var plinths := SurfaceTool.new()
	plinths.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(3):
		_add_box(plinths, Vector3(_slot_x(k), PLATE_T + PLINTH_T * 0.5, PLINTH_Z),
			Vector3(PLINTH_W, PLINTH_T, PLINTH_D))
	_commit(holder, "Plinths", plinths, C_PLINTH, 0.90)

	## The two operands, and the block where they meet. Both operands exist under every
	## value of `order` — only which one is negated changes — so they belong to the stage
	## and not to either reading.
	var arrow_a := SurfaceTool.new()
	arrow_a.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_arrow(arrow_a, Vector2.ZERO, A_UNIT, Z_FIG, ARROW_W, ARROW_T, HEAD_W, HEAD_L)
	_commit(holder, "OperandA", arrow_a, C_A, 0.60)

	var arrow_b := SurfaceTool.new()
	arrow_b.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_arrow(arrow_b, Vector2.ZERO, B_UNIT, Z_FIG, ARROW_W, ARROW_T, HEAD_W, HEAD_L)
	_commit(holder, "OperandB", arrow_b, C_B, 0.60)

	var origin := SurfaceTool.new()
	origin.begin(Mesh.PRIMITIVE_TRIANGLES)
	var o: Vector2 = _fig(Vector2.ZERO)
	_add_box(origin, Vector3(o.x, o.y, Z_FIG + ARROW_T * 0.5),
		Vector3(ORIGIN_BLOCK, ORIGIN_BLOCK, ORIGIN_BLOCK))
	_commit(holder, "Origin", origin, C_ORIGIN, 0.70)


# ── the result ─────────────────────────────────────────────────────────────────────────

## THE ASYMMETRY, and it is the argument rather than a layout convenience.
##
## The CUBE is drawn under every value, because its result does not depend on one: the
## same 8 corners, 12 edges and 12 faces stand at the end of ascend, of descend and of
## together, since `_finish()` under the shipped closure `strata` hides nothing. A body
## that is the same for all three values can be drawn without naming a value.
##
## The DIFFERENCE is drawn only under a vector value, because it cannot be drawn without
## naming one. There is no such thing as "the difference of a and b" until an order picks
## which is the head. So under a cube word the left half has no result at all — not as a
## presentation choice, but because the word does not determine one.
##
## THAT PRODUCES THE DESIGNED NULL. Under `reading = result`, ascend, descend and together
## each add exactly the cube and nothing else, so the three cells are one photograph.
func _build_result(holder: Node3D, word: String) -> void:
	_build_cube(holder, Vector3(HALF_X, CUBE_Y, CUBE_Z), CUBE_SIDE, 1.0, "Cube")

	if not VECTOR_WORDS.has(word):
		return
	## head and tail exactly as both members compute them: the swap is guarded on the
	## literal "b_minus_a", so `reciprocal` runs the a_minus_b arithmetic untouched.
	var head: Vector2 = A_UNIT
	var tail: Vector2 = B_UNIT
	if word == "b_minus_a":
		head = B_UNIT
		tail = A_UNIT
	var diff: Vector2 = head - tail

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_arrow(st, Vector2.ZERO, diff, Z_FIG, ARROW_W, ARROW_T, HEAD_W, HEAD_L)
	_commit(holder, "Difference", st, C_DIFF, 0.55)

	if word != "reciprocal":
		return
	## The second arrow, built only for `reciprocal` in both members, at -diff. The two
	## arrows share one line through the origin and have equal length, so this cell is
	## exactly the union of the a_minus_b cell and the b_minus_a cell.
	var counter := SurfaceTool.new()
	counter.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_arrow(counter, Vector2.ZERO, -diff, Z_FIG, ARROW_W, ARROW_T, HEAD_W, HEAD_L)
	_commit(holder, "Counter", counter, C_COUNTER, 0.55)


# ── the path ───────────────────────────────────────────────────────────────────────────

func _build_path(holder: Node3D, word: String) -> void:
	if VECTOR_WORDS.has(word):
		_build_walks(holder, word)
	else:
		_build_courses(holder, word)


## THE WALK. Subtraction as one journey: out along the head, then back along the tail —
## which is the `chain` construction both vector members ship, used here as the PATH
## because it is the only reading of a-b that has a route at all. The route for a-b and
## the route for b-a start in different directions and arrive at different points, so on
## this side the path changes AND the destination changes. That is what a
## non-commutative operation looks like from underneath.
func _build_walks(holder: Node3D, word: String) -> void:
	if word != "b_minus_a":
		_one_walk(holder, A_UNIT, B_UNIT, C_WALK, "Walk")
	if word != "a_minus_b":
		_one_walk(holder, B_UNIT, A_UNIT, C_WALK2, "WalkCounter")


func _one_walk(holder: Node3D, head: Vector2, tail: Vector2, c: Color,
		tag: String) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var arrive: Vector2 = head - tail
	_add_arrow(st, Vector2.ZERO, head, WALK_Z, WALK_W, WALK_T,
		WALK_HEAD_W, WALK_HEAD_L)
	_add_arrow(st, head, arrive, WALK_Z, WALK_W, WALK_T, WALK_HEAD_W, WALK_HEAD_L)
	## The three waypoints, graded by size. Step 0 at the origin, step 1 at the head's
	## tip, step 2 where the walk lands — which is the difference, whether or not the
	## reading is showing it.
	_add_mark(st, Vector2.ZERO, MARK_0)
	_add_mark(st, head, MARK_1)
	_add_mark(st, arrive, MARK_2)
	_commit(holder, tag, st, c, 0.55)


## THE ASSEMBLY COURSES. Three plinths are three time slots. A phase stands in the slot it
## was revealed in, as a miniature of itself: the eight corners alone, the twelve edges
## alone, the twelve faces alone.
##
##   ascend    corners, edges, faces      left to right, 0D then 1D then 2D
##   descend   faces, edges, corners      the same machine backwards
##   together  all three IN SLOT 0        because _phase_order() returns [], which
##                                        start_animation() reads as "reveal everything
##                                        and go straight to COMPLETE". Superimposed in
##                                        one slot the three phases are the whole cube,
##                                        so `together`'s path is a small copy of the
##                                        result, and slots 1 and 2 stand bare.
func _build_courses(holder: Node3D, word: String) -> void:
	var y: float = PLATE_T + PLINTH_T + MINI_SIDE * 0.5
	if word == "together":
		_build_cube(holder, Vector3(_slot_x(0), y, PLINTH_Z), MINI_SIDE, MINI_K,
			"Course0_all")
		return
	var phases: PackedStringArray = ["corners", "edges", "faces"]
	if word == "descend":
		phases = PackedStringArray(["faces", "edges", "corners"])
	for k in range(3):
		var at: Vector3 = Vector3(_slot_x(k), y, PLINTH_Z)
		match phases[k]:
			"edges":
				_build_cube_edges(holder, at, MINI_SIDE, MINI_K, "Course%d_edges" % k)
			"faces":
				_build_cube_faces(holder, at, MINI_SIDE, "Course%d_faces" % k)
			_:
				_build_cube_corners(holder, at, MINI_SIDE, MINI_K,
					"Course%d_corners" % k)


func _slot_x(k: int) -> float:
	return HALF_X + (float(k) - 1.0) * SLOT_PITCH


# ── the cube, in three layers ──────────────────────────────────────────────────────────

func _build_cube(holder: Node3D, at: Vector3, side: float, k: float,
		tag: String) -> void:
	_build_cube_corners(holder, at, side, k, tag + "_corners")
	_build_cube_edges(holder, at, side, k, tag + "_edges")
	_build_cube_faces(holder, at, side, tag + "_faces")


func _build_cube_corners(holder: Node3D, at: Vector3, side: float, k: float,
		tag: String) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var s: float = CORNER_S * k
	for i in range(CUBE_V.size()):
		_add_box(st, at + CUBE_V[i] * side, Vector3(s, s, s))
	_commit(holder, tag, st, C_CORNER, 0.55)


func _build_cube_edges(holder: Node3D, at: Vector3, side: float, k: float,
		tag: String) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var t: float = EDGE_T * k
	var trim: float = CORNER_S * k
	for e in range(CUBE_EDGES.size()):
		var pair: Array = CUBE_EDGES[e]
		var p0: Vector3 = at + CUBE_V[int(pair[0])] * side
		var p1: Vector3 = at + CUBE_V[int(pair[1])] * side
		var d: Vector3 = p1 - p0
		var size: Vector3 = Vector3(t, t, t)
		if absf(d.x) > 0.0001:
			size.x = maxf(absf(d.x) - trim, t)
		elif absf(d.y) > 0.0001:
			size.y = maxf(absf(d.y) - trim, t)
		else:
			size.z = maxf(absf(d.z) - trim, t)
		_add_box(st, (p0 + p1) * 0.5, size)
	_commit(holder, tag, st, C_EDGE, 0.65)


## The source's twelve triangles, in the source's order, with the source's own
## three-colour rotation by index modulo 3 — so the picture reports 12 rather than 6 and
## the diagonal seam of every face stays open. Each triangle is shrunk toward its own
## centroid by FACE_K, which leaves the corners and edges visible around it: the shipped
## `strata` ending is that nothing is hidden, and an unshrunken face would hide the two
## layers the ending exists to keep.
func _build_cube_faces(holder: Node3D, at: Vector3, side: float, tag: String) -> void:
	var tools: Array[SurfaceTool] = []
	for i in range(3):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		tools.append(st)
	for i in range(CUBE_TRIS.size()):
		var tri: Array = CUBE_TRIS[i]
		var v0: Vector3 = at + CUBE_V[int(tri[0])] * side
		var v1: Vector3 = at + CUBE_V[int(tri[1])] * side
		var v2: Vector3 = at + CUBE_V[int(tri[2])] * side
		var c: Vector3 = (v0 + v1 + v2) / 3.0
		_add_face(tools[i % 3], c + (v0 - c) * FACE_K, c + (v1 - c) * FACE_K,
			c + (v2 - c) * FACE_K, at)
	_commit(holder, tag + "_0", tools[0], C_FACE_0, 0.85)
	_commit(holder, tag + "_1", tools[1], C_FACE_1, 0.85)
	_commit(holder, tag + "_2", tools[2], C_FACE_2, 0.85)


# ── drawing primitives ─────────────────────────────────────────────────────────────────

## Figure units to the board's plane. The z of the relief is supplied separately.
func _fig(p: Vector2) -> Vector2:
	return Vector2(-HALF_X + p.x * VEC_S, VEC_Y + p.y * VEC_S)


## An arrow in the board's plane: a rod from `from_u` (offset clear of the shared origin)
## to the base of a triangular head whose point lands exactly on `to_u`. Both parts are
## extruded prisms, so the arrow has real thickness and a lit top edge rather than being
## a decal.
func _add_arrow(st: SurfaceTool, from_u: Vector2, to_u: Vector2, z0: float, w: float,
		t: float, head_w: float, head_l: float) -> void:
	var p0: Vector2 = _fig(from_u)
	var p1: Vector2 = _fig(to_u)
	var d: Vector2 = p1 - p0
	var l: float = d.length()
	if l < 0.004:
		return
	var u: Vector2 = d / l
	var nrm: Vector2 = Vector2(-u.y, u.x)
	var start: Vector2 = p0 + u * minf(ORIGIN_GAP, l * 0.25)
	var base: Vector2 = p1 - u * minf(head_l, l * 0.6)
	if (base - start).dot(u) > 0.001:
		var quad: PackedVector2Array = PackedVector2Array([
			start + nrm * (w * 0.5), base + nrm * (w * 0.5),
			base - nrm * (w * 0.5), start - nrm * (w * 0.5)])
		_extrude(st, quad, z0, t)
	var head: PackedVector2Array = PackedVector2Array([
		p1, base - nrm * (head_w * 0.5), base + nrm * (head_w * 0.5)])
	_extrude(st, head, z0, t)


func _add_mark(st: SurfaceTool, at_u: Vector2, s: float) -> void:
	var p: Vector2 = _fig(at_u)
	_add_box(st, Vector3(p.x, p.y, WALK_Z + WALK_T + s * 0.5 - 0.006),
		Vector3(s, s, s))


## A convex polygon in the x-y plane, extruded along +z: two capped ends and one quad per
## edge, every face wound outward from the prism's own centre and flipped if it is not.
func _extrude(st: SurfaceTool, poly: PackedVector2Array, z0: float, t: float) -> void:
	var n: int = poly.size()
	if n < 3:
		return
	var acc: Vector2 = Vector2.ZERO
	for i in range(n):
		acc += poly[i]
	acc /= float(n)
	var centre: Vector3 = Vector3(acc.x, acc.y, z0 + t * 0.5)
	for i in range(1, n - 1):
		_tri(st, Vector3(poly[0].x, poly[0].y, z0 + t),
			Vector3(poly[i].x, poly[i].y, z0 + t),
			Vector3(poly[i + 1].x, poly[i + 1].y, z0 + t), centre)
		_tri(st, Vector3(poly[0].x, poly[0].y, z0),
			Vector3(poly[i].x, poly[i].y, z0),
			Vector3(poly[i + 1].x, poly[i + 1].y, z0), centre)
	for i in range(n):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % n]
		_quad(st, Vector3(a.x, a.y, z0), Vector3(b.x, b.y, z0),
			Vector3(b.x, b.y, z0 + t), Vector3(a.x, a.y, z0 + t), centre)


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


## One face patch. Emitted with both windings, the way animatedcubebuilder emits its own
## triangles, and every material here is CULL_DISABLED as well: a zero-thickness patch
## that happened to face away would otherwise be a hole in the picture.
func _add_face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		inside: Vector3) -> void:
	_tri(st, a, b, c, inside)
	_tri(st, a, c, b, inside)


## Two triangles a -> b -> c -> d, with the normal taken from the winding and FLIPPED if
## it points back at `inside`.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		inside: Vector3) -> void:
	_tri(st, a, b, c, inside)
	_tri(st, a, c, d, inside)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	var mid: Vector3 = (a + b + c) / 3.0
	if n.dot(mid - inside) < 0.0:
		n = -n
	var tri: PackedVector3Array = PackedVector3Array([a, b, c])
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
