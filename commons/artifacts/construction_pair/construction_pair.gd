extends Node3D
class_name ConstructionPair

## construction_pair — two vectors, one answer, and five arguments for it. Three of the
## five are drawings; two are assertions, and neither vocabulary has both.
##
## THE FAMILY. Three artifacts declare an axis called `construction` and it asks the same
## question in all three: WHICH ARGUMENT for the combination does this bench actually draw?
## Read from their enums rather than their prose:
##
##   VectorAddition                     parallelogram | chain | commute | bare   (default parallelogram)
##   VectorSubtraction                  flip | chain | parallelogram | bare      (default flip)
##   example_1_3_vector_subtraction_vr  bare | flip | chain | parallelogram      (default bare)
##
## Three scenes, three scripts, no shared scene — checked. THREE MEMBERS, THREE DIFFERENT
## DEFAULTS, which is the only vocabulary in the corpus with no majority reading of itself.
## Three words are unanimous (chain, parallelogram, bare); the fourth is where the two
## vocabularies split, and the split is the subject of this bench.
##
## WHAT THE CODE SAYS THAT THE BRIEF DID NOT, and it is the finding.
##
##   1. `flip` IS NOT A MOVE, IT IS A UNION. The brief called flip "subtraction's own move,
##      a - b drawn as a + (-b)". It is not. In VectorSubtraction, _shows_flipped_at_origin()
##      returns _shows_parallelogram() (:192-193) and _shows_tip_to_tail() is flip-or-chain
##      (:196-197), so flip = chain UNION parallelogram exactly. example_1_3 says the same in
##      three lines: _want_neg_origin = flip or parallelogram, _want_neg_tip = flip or chain,
##      _want_dots = flip or parallelogram (:352-354). And the negation itself is drawn under
##      `chain` too — the chained copy IS -b, just rooted at a's tip. EVERY NON-BARE VALUE IS
##      A FLIP. The word names the union, not the move.
##
##   2. `commute` IS ALSO A UNION, OF A DIFFERENT PAIR. VectorAddition's commute is
##      _shows_chain_b() AND _shows_chain_a() (:256-261): b chained at a's tip and a chained
##      at b's tip. So both extra words are unions of readings the vocabulary already has,
##      and the two vocabularies differ by WHICH union they bothered to name:
##          flip     = chain UNION parallelogram          (subtraction's word)
##          commute  = chain UNION its own mirror image   (addition's word)
##      That is the whole difference between the two lists, and neither member has the other's
##      union. This bench draws each union only in the column that declares it, and draws the
##      absence in the other — component_court's rule for a vocabulary gap, wave 13.
##
##   3. THE PARALLELOGRAM AND THE TWO CHAINS ARE THE SAME TWO SEGMENTS. VectorAddition's
##      dotted_line_a runs a -> result and dotted_line_b runs b -> result (:352-354); its
##      chain_b_at_a sits at a and spans b, its chain_a_at_b sits at b and spans a (:199-203).
##      Those are the same two segments. `parallelogram` draws them DOTTED and `commute`
##      draws them SOLID WITH HEADS. The theorem is not a new figure; it is the figure
##      asserted as two journeys instead of one shape.
##
##   4. AND THE HISTORICAL BUILD DRAWS ONE SIDE TWICE. Under `flip`, VectorSubtraction's
##      dotted_line_neg_b runs head -> diff (:148) while tip_tail_neg_b sits at head and
##      spans -tail (:142-143) — the same segment, coincident, dots inside the solid copy.
##      example_1_3 repeats it exactly (_dots_head A->result at :446 under _rod_neg_tip at
##      :442). Both subtraction members ship that double-draw as their default. VectorAddition
##      is the only member that never double-draws, and it is the only member without `flip`.
##
## WHAT THIS BENCH DRAWS. Two fixed operands and one answer, identical in all five
## constructions of a column, and the construction as REAL GEOMETRY — rods with real heads,
## the parallelogram's completing sides as actual dotted runs, the resultant always present:
##
##   bare           the three arrows and nothing else. DRAWING (the null).
##   chain          q re-rooted at a's tip: one walk, out along a then on along q. DRAWING.
##   parallelogram  the two completing sides as dotted runs (and, under subtract, -b standing
##                  at the origin, because that is what both subtraction members draw).
##                  DRAWING.
##   flip           subtraction's union: chain AND parallelogram at once, with the dotted run
##                  on a -> r buried inside the solid copy exactly as the members bury it.
##                  ASSERTION. Absent from addition's vocabulary.
##   commute        addition's union: both chains, both landing on the same tip.
##                  ASSERTION. Absent from subtraction's vocabulary.
##
## THE SECOND AXIS IS `operation`, AND IT IS WHERE THE FAMILY'S UNSAID FACT LIVES. The three
## members teach two operations with one word, and nobody has ever put the two columns side
## by side. Under `add` the resultant is a + b, the parallelogram's diagonal from the origin.
## Under `subtract` it is a - b, WHICH IS THE OTHER DIAGONAL OF THE SAME PARALLELOGRAM —
## the one running from b's tip to a's tip, which is exactly what VectorSubtraction's
## @identity line 8 says it is ("a-b always points from b's tip to a's tip") and which no
## member draws in the same picture as the sum. The arithmetic is checkable and exact here:
## |a+b|^2 + |a-b|^2 = 0.244800 + 0.144000 = 0.388800 = 2(|a|^2 + |b|^2) = 2(0.090000 +
## 0.104400). The parallelogram law is not decoration; it is the reason the two columns are
## one figure read twice.
##
## Deterministic: no RandomNumberGenerator, no randf, no noise, no _process, no Timer, no
## tween. Every vertex is arithmetic on six constants. Two builds of one cell are the same
## mesh.


## WHICH ARGUMENT FOR THE COMBINATION THIS BENCH ACTUALLY DRAWS. The union of the two
## vocabularies, in the order the shared three appear in example_1_3's enum, with each
## vocabulary's own extra word last. Values a column's vocabulary does not declare are drawn
## as an ABSENCE, which is component_court's rule for the same situation in the same domain
## (vector_magnitude_demo declares no `box`; that subset is honest and is drawn as an
## absence). It makes two cells of this sheet exact repeats of `bare`, and those two zeros
## are the census: the union has holes and they are measurable.
@export_enum("bare", "chain", "parallelogram", "flip", "commute") var construction: String = "parallelogram":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not CONSTRUCTIONS.has(picked):
			return                      ## an unreachable value keeps the standing figure
		construction = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## WHICH OPERATION THE SAME TWO OPERANDS ARE PUT THROUGH. Two values, because the family has
## exactly two: VectorAddition teaches a + b, VectorSubtraction and example_1_3 teach a - b,
## and there is no third operation anywhere in the three files. The second operand as USED is
## q = b under add and q = -b under subtract; the resultant is a + q in both, which is the
## identity the whole subtraction family rests on (VectorSubtraction @identity line 4:
## "a - b = a + (-b)").
@export_enum("add", "subtract") var operation: String = "add":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not OPERATIONS.has(picked):
			return
		operation = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One cell, or all five constructions in a row. NOT PART OF EITHER AXIS. capture_config_sweep
## unions the AABB across a spec's variants, so an all-constructions value declared inside
## `construction` would frame every single cell against four and a half metres and photograph
## the 0.015 m rods as hairs. The registry fixture pins `single`; `ladder` is a design view.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const CONSTRUCTIONS: PackedStringArray = ["bare", "chain", "parallelogram", "flip", "commute"]
const OPERATIONS: PackedStringArray = ["add", "subtract"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the operands ───────────────────────────────────────────────────────────────────────
## THE PAIR IS example_1_3'S OWN, RIGIDLY ROTATED AND RESCALED — and the choice of that
## member is forced rather than aesthetic. Its operands are the only PLANAR pair in the
## family (vector_a = (0.2, 0.15, 0), vector_b = (-0.1, 0.25, 0); the z is exactly zero,
## because it is Shiffman's 2D original translated). And a plane is not a simplification of
## this operation, it is the operation's own shape: a and b span a plane and every one of
## a + b, a - b, -b and both parallelograms lies inside it. Nothing here is flattened.
##
## The rotation is -66.8699 degrees, which puts a at exactly -30 degrees and b at 44.9315.
## It preserves everything the family argues — the angle between the operands (74.9315
## degrees) and the length ratio |b|/|a| = 1.077033 are example_1_3's to six figures — and
## it is chosen for one measurable reason: at the capture standpoint (yaw 0.62, pitch -0.26)
## world x projects to (0.8139, -0.1494) and world y to (0, 0.9665), so a figure needs to be
## 1.187 times wider than tall to photograph square. The union box below is 1.1829. The
## family's own numbers, turned to face the camera.
##
## The scale puts |a| at exactly 0.300 m, so |b| = 0.323110 m.
const OP_A: Vector2 = Vector2(0.259808, -0.150000)      ## 0.300000 m at -30.0000 deg
const OP_B: Vector2 = Vector2(0.228746, 0.228200)       ## 0.323110 m at +44.9315 deg

## Where the origin of the figure sits inside the frame. The union of every point any cell
## can draw — 0, a, b, -b, a+b, a-b — spans x in [-0.228746, 0.488554] and y in
## [-0.378200, 0.228200]; this offset centres that box on the frame and lifts the whole
## bench so its foot rail sits at y = 0. The centred extremes come out exactly symmetric:
## a+b and -b are the two x extremes at +-0.358650, b and a-b the two y extremes at
## +-0.303200.
const ORIGIN: Vector3 = Vector3(-0.129904, 0.423000, 0.0)

# ── the stage, identical to the millimetre in all ten cells ────────────────────────────
## THE FRAME IS THE WHOLE REASON THE AABB NEVER MOVES. It bounds every point every cell can
## draw with 0.045 m to spare, so the world box is 0.808 x 0.696 x 0.128 in all ten cells
## before a single construction rod exists. Without it the box would be a fact about which
## construction was picked — `bare` draws three arrows, `flip` draws seven objects — the
## camera would move between cells, and every measured pair would carry a framing difference
## it did not earn. The two feet are the only things with depth; they are what stops the
## z extent from being a fact about which arrowhead happens to be widest.
const FRAME_HX: float = 0.404
const FRAME_HY: float = 0.348
const FRAME_T: float = 0.018
const FOOT_X: float = 0.300
const FOOT_L: float = 0.048
const FOOT_D: float = 0.128

# ── line weights ───────────────────────────────────────────────────────────────────────
## THE MARKS ARE DELIBERATELY FAT, and the reason is measured rather than stylistic.
## component_court (wave 13, the same domain) drew this family with 0.009 m legs and 0.004 m
## box edges and peaked at 1.41 percent of frame — legible to a reader, nearly nothing to the
## critic, because at that framing the marks are 1.5 to 3.5 px after the crop and resize.
## example_1_3 hit the same wall from the other side and wrote it down at :102-109: 6 mm rods
## made `chain` and `parallelogram` differ by 0.045 percent of the frame, "two genuinely
## different figures that no one could tell apart", and it doubled them. These are 0.015 to
## 0.020 m on a 0.72 m figure — about 6 px at this framing — which is the smallest weight
## that survives the pipeline.
const R_OPERAND: float = 0.016
const R_RESULT: float = 0.020
const R_COPY: float = 0.015
const DOT_S: float = 0.015
const DOT_STEP: float = 0.040
const HEAD_MAX: float = 0.055
const HEAD_FRAC: float = 0.32
const HEAD_FLARE: float = 2.6

# ── colour ─────────────────────────────────────────────────────────────────────────────
## Rec.709 luminance written down so the greyscale reading is checkable rather than hoped:
## frame 0.301, operand b 0.438, operand a 0.575, copy 0.728, resultant 0.860. No two things
## that must be told apart sit within 0.13 of each other. This matters more here than usual
## because the three members carry the whole distinction in HUE — coral against cyan, pink
## against green — and the critic measures luminance by default, so a sheet built their way
## would read as five twins in greyscale.
##
## -b IS DRAWN IN b's EXACT COLOUR AND WEIGHT, which is a claim rather than an economy: -b is
## b, turned around, and the two can never be confused for each other because they leave the
## same origin in opposite directions. The members give -b its own pink; that pink says the
## negative is a third object, and the code says it is not.
const C_FRAME: Color = Color(0.29, 0.30, 0.34)
const C_A: Color = Color(0.92, 0.50, 0.30)
const C_B: Color = Color(0.26, 0.46, 0.74)
const C_COPY: Color = Color(0.80, 0.72, 0.60)
const C_RESULT: Color = Color(0.60, 0.98, 0.44)

const E_FRAME: float = 0.0
const E_OPERAND: float = 0.6
const E_COPY: float = 0.7
const E_RESULT: float = 1.4

const LADDER_PITCH: float = 0.90
## Iterated rather than written inline, so no loop variable is left untyped.
const SIGNS: PackedFloat32Array = [-1.0, 1.0]

var _built: Array[Node3D] = []
## Set while a whole config dictionary lands, so three keys cost one rebuild, not three.
var _bulk: bool = false


func _ready() -> void:
	_check_hints()
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("construction"):
		construction = str(config_data["construction"])
	if config_data.has("operation"):
		operation = str(config_data["operation"])
	_bulk = false
	_rebuild()


## The declaration gate reads the @export_enum hint; the builder reads the const. If they
## ever drift, every frame in a sweep is a fact about which of the two a given tool trusted.
func _check_hints() -> void:
	var pairs: Array = [["construction", CONSTRUCTIONS], ["operation", OPERATIONS],
		["layout", LAYOUTS]]
	for entry in pairs:
		var key: String = str(entry[0])
		var want: PackedStringArray = entry[1]
		for prop in get_property_list():
			if String(prop.get("name", "")) != key:
				continue
			var got: PackedStringArray = PackedStringArray()
			for part in String(prop.get("hint_string", "")).split(",", false):
				got.append(String(part).split(":")[0].strip_edges())
			if got != want:
				push_error("construction_pair: '%s' hint %s != const %s" % [key, got, want])
			break


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
		names = CONSTRUCTIONS.duplicate()
	else:
		names.append(_pick(construction, CONSTRUCTIONS, "parallelogram"))
	var op: String = _pick(operation, OPERATIONS, "add")
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Cell_" + names[i] + "_" + op
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_stage(holder)
		_build_figure(holder, op, names[i])


# ── the stage ──────────────────────────────────────────────────────────────────────────

func _build_stage(holder: Node3D) -> void:
	var span_y: float = (FRAME_HY - FRAME_T * 0.5) * 2.0
	for s in SIGNS:
		_box(holder, Vector3(0.0, FRAME_HY + float(s) * (FRAME_HY - FRAME_T * 0.5), 0.0),
			Vector3(FRAME_HX * 2.0, FRAME_T, FRAME_T), C_FRAME, E_FRAME)
		_box(holder, Vector3(float(s) * (FRAME_HX - FRAME_T * 0.5), FRAME_HY, 0.0),
			Vector3(FRAME_T, span_y, FRAME_T), C_FRAME, E_FRAME)
		_box(holder, Vector3(float(s) * FOOT_X, FRAME_T * 0.5, 0.0),
			Vector3(FOOT_L, FRAME_T, FOOT_D), C_FRAME, E_FRAME)


# ── the figure ─────────────────────────────────────────────────────────────────────────

## Field coordinates to artifact space. Everything the figure draws is at z = 0.
func _at(p: Vector2) -> Vector3:
	return ORIGIN + Vector3(p.x, p.y, 0.0)


func _build_figure(holder: Node3D, op: String, who: String) -> void:
	# THE SECOND OPERAND AS USED. q = b under add, q = -b under subtract, and the resultant
	# is a + q either way — the identity the subtraction family is built on, written once.
	var q: Vector2 = OP_B
	if op == "subtract":
		q = -OP_B
	var r: Vector2 = OP_A + q

	# THE THREE ARROWS ARE DRAWN BEFORE THE CONSTRUCTION AND NO BRANCH BELOW TOUCHES THEM.
	# a and b leave the origin in every one of the ten cells; all three members draw both
	# operands unconditionally, including the subtraction ones, which draw b even while
	# arguing from -b. Within a column the three are identical vertex for vertex across all
	# five constructions, which is what makes `commute` measurable as furniture rather than
	# as an answer.
	_arrow(holder, _at(Vector2.ZERO), _at(OP_A), R_OPERAND, C_A, E_OPERAND)
	_arrow(holder, _at(Vector2.ZERO), _at(OP_B), R_OPERAND, C_B, E_OPERAND)
	_arrow(holder, _at(Vector2.ZERO), _at(r), R_RESULT, C_RESULT, E_RESULT)

	# THE VOCABULARY GAP, DRAWN AS AN ABSENCE. VectorAddition declares no `flip`;
	# VectorSubtraction and example_1_3 declare no `commute`. Asked for a word its column's
	# vocabulary does not have, the bench draws nothing extra — the same rule component_court
	# used for vector_magnitude_demo's missing `box`. Two cells of the sheet are therefore
	# exact repeats of `bare`, and those two zeros are the measurement.
	if op == "add" and who == "flip":
		return
	if op == "subtract" and who == "commute":
		return

	# -b STANDING AT THE ORIGIN belongs to the readings that argue from a figure there, and
	# only under subtract, where q is not b. Both subtraction members gate it on
	# flip-or-parallelogram and both leave it out of `chain` ("nothing at the origin").
	var wants_origin_negative: bool = (who == "parallelogram" or who == "flip"
		or who == "commute")
	if op == "subtract" and wants_origin_negative:
		_arrow(holder, _at(Vector2.ZERO), _at(q), R_OPERAND, C_B, E_OPERAND)

	# THE DOTTED CLOSURE — the two completing sides of the figure a and q span, which are the
	# copy of q leaving a's tip and the copy of a leaving q's tip. Drawn before the solid
	# copies so that under `flip` the run on a -> r ends up INSIDE the solid rod laid over
	# it, exactly as both subtraction members bury it.
	if who == "parallelogram" or who == "flip":
		_dot_run(holder, _at(OP_A), _at(r))
		_dot_run(holder, _at(q), _at(r))

	# THE CHAIN — q re-rooted at a's tip. Present in every non-bare reading of every member:
	# under `chain` alone, and inside both unions.
	if who == "chain" or who == "flip" or who == "commute":
		_arrow(holder, _at(OP_A), _at(r), R_COPY, C_COPY, E_COPY)

	# THE MIRROR CHAIN — a re-rooted at q's tip, the second journey to the same point. It is
	# addition's word for the union and it is the only mark in the bench that is an ASSERTION
	# about the operation rather than a picture of it. Note what it asserts under subtract if
	# subtraction had a word for it: a + (-b) = (-b) + a is TRUE, because addition commutes
	# even where subtraction does not — a - b != b - a is a question about swapping the
	# OPERANDS, which is these members' `order` axis and not this one.
	if who == "commute":
		_arrow(holder, _at(q), _at(r), R_COPY, C_COPY, E_COPY)


# ── drawing ────────────────────────────────────────────────────────────────────────────

func _mat(c: Color, e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.45
	m.metallic = 0.0
	# Belt over braces: every mesh below is a Godot primitive and so is already wound
	# outward, but a rod whose quad happened to wind inward would become a hole in the
	# picture rather than a visible fault.
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if e > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = e
	return m


func _add(parent: Node3D, mesh: Mesh, xform: Transform3D, c: Color, e: float) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.transform = xform
	mi.material_override = _mat(c, e)
	parent.add_child(mi)


func _box(parent: Node3D, at: Vector3, size: Vector3, c: Color, e: float) -> void:
	var bm := BoxMesh.new()
	bm.size = size
	_add(parent, bm, Transform3D(Basis.IDENTITY, at), c, e)


func _rod(parent: Node3D, a: Vector3, b: Vector3, r: float, c: Color, e: float) -> void:
	var d: Vector3 = b - a
	var len_m: float = d.length()
	if len_m < 0.0005:
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = len_m
	cyl.radial_segments = 12
	cyl.rings = 1
	_add(parent, cyl, _between(a, b, len_m), c, e)


func _arrow(parent: Node3D, a: Vector3, b: Vector3, r: float, c: Color, e: float) -> void:
	var d: Vector3 = b - a
	var len_m: float = d.length()
	if len_m < 0.0005:
		return
	var head: float = minf(HEAD_MAX, len_m * HEAD_FRAC)
	var shaft_end: Vector3 = b - d.normalized() * head
	_rod(parent, a, shaft_end, r, c, e)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = r * HEAD_FLARE
	cone.height = head
	cone.radial_segments = 14
	cone.rings = 1
	_add(parent, cone, _between(shaft_end, b, head), c, e)


## A run of small cubes from a to b inclusive, at DOT_STEP spacing — the members' own dotted
## line, which places n = int(len / spacing) + 1 dots at t = i / (n - 1) and so puts one dot
## on each endpoint. Both endpoints land inside an arrowhead that is already there, which is
## faithful and is accounted for in the registry's arithmetic rather than quietly fixed.
##
## THE CUBE FITS INSIDE THE COPY ROD ON PURPOSE. Half-side 0.0075 gives a worst-case corner
## distance of 0.0075 * sqrt(3) = 0.012990 m from the segment axis, against a copy rod of
## radius 0.015. So under `flip` the buried run contributes exactly nothing, which is what
## both subtraction members' shipped default has always done and what this bench measures.
func _dot_run(parent: Node3D, a: Vector3, b: Vector3) -> void:
	var d: Vector3 = b - a
	var len_m: float = d.length()
	if len_m < 0.0005:
		return
	var n: int = int(len_m / DOT_STEP) + 1
	if n < 2:
		n = 2
	for i in range(n):
		var t: float = float(i) / float(maxi(n - 1, 1))
		_box(parent, a.lerp(b, t), Vector3(DOT_S, DOT_S, DOT_S), C_COPY, E_COPY)


## Explicit basis rather than look_at, which is undefined for a segment parallel to UP. The
## difference a - b here points 85.3 degrees below the horizontal, so that guard is not
## hypothetical — it fires in half the cells of this sheet.
func _between(a: Vector3, b: Vector3, len_m: float) -> Transform3D:
	var up: Vector3 = (b - a) / len_m
	var ref: Vector3 = Vector3.UP
	if absf(up.dot(Vector3.UP)) > 0.9:
		ref = Vector3.RIGHT
	var side: Vector3 = ref.cross(up).normalized()
	var fwd: Vector3 = up.cross(side).normalized()
	return Transform3D(Basis(side, up, fwd), (a + b) * 0.5)
