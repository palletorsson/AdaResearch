extends Node3D
class_name ProportionBench

## proportion_bench — four right triangles, one theorem, four cultures. Every value of
## `proportion` satisfies a^2 + b^2 = c^2, so nothing here is a fact about geometry.
## Which right triangle counts as THE right triangle is a choice about what you can
## construct and what you find beautiful.
##
## THE FAMILY. Four artifacts in the corpus argue about the triangle, and each holds a
## different thing still:
##
##   righttriangle          proportion: isoceles | 3-4-5 | 1-2 | kepler   THE RATIOS. Its
##                          reading:    uniform | corner_marked |         LEG_RATIOS table
##                                      legs_hypotenuse                   is the centre of
##                          this synthesis and its four values are taken character for
##                          character. gd:38-43.
##   invariants_demo        figure: equilateral | right | scalene         WHICH SHAPE goes
##                          pose:   none | translate | rotate | scale |   under the motion,
##                                  shear | project                      and what survives.
##                          Its `right` case is the isoceles one: verts (-0.15, 0.35),
##                          (0.15, 0.35), (-0.15, 0.65) — legs 0.30 and 0.30. gd:101-103.
##   pythagorean_triangle_  evidence: result | trace | longhand | axiom   HOW MUCH OF THE
##   angles                 PROOF is on show. `result` grows the three squares from the
##                          three sides (update_square_mesh, gd:292-304); `longhand` is
##                          Euclid I.47 with the altitude cutting the hypotenuse square
##                          into the two rectangles that ARE the leg squares.
##   quad_line_puzzle       figure: square | rectangle | rhombus |        WHICH CONSTRAINT
##                                  trapezoid                            you drop. FIGURES,
##                          plane:  upright | ground                     gd:53-62.
##
## Ratios, shape, proof, constraint. This bench takes the first and the third: righttriangle's
## four proportions as the axis, and pythagorean's squares as one of the ways to read them.
##
## THE ARGUMENT, and it is arguable. All four are right triangles, so all four are the same
## theorem — and they are four different cultures:
##
##   3-4-5     the Egyptian rope-stretcher's triangle. Twelve knots in a closed loop, pulled
##             taut at 3, 4 and 5: the only one of the four you can BUILD with no measuring
##             instrument at all. Angles 36.870 and 53.130 degrees.
##   isoceles  the half-square — a square cut on its diagonal. The one with a symmetry, and
##             the one whose hypotenuse the side cannot name: c = a * sqrt(2), the first
##             incommensurable. righttriangle's shipped default. Angles 45 and 45.
##   1-2       the half-DOMINO: a 1 x 2 rectangle cut on its diagonal, c = sqrt(5). Not the
##             half-square (that is `isoceles`) — the brief for this artifact said half-square
##             and the code says otherwise; see `declines`. sqrt(5) is the whole point: it is
##             the straightedge construction of the golden ratio, phi = (1 + sqrt(5)) / 2.
##             So this value and `kepler` are the same number two moves apart. Angles 26.565
##             and 63.435.
##   kepler    sides 1 : sqrt(phi) : phi, the unique right triangle whose three sides are a
##             GEOMETRIC PROGRESSION. (If the sides are a, ar, ar^2 then 1 + r^2 = r^4, so
##             r^2 = phi and r = sqrt(phi) — one solution, no others.) Angles 38.173 and
##             51.827. righttriangle stores it as 0.7861513777574233 = 1 / sqrt(phi), and
##             that literal survives this renormalisation UNCHANGED, which is not a
##             coincidence but the definition: in a geometric progression short/long and
##             long/hypotenuse are the same ratio.
##
## SO THE AXIS IS NOT ABOUT SHAPE. It is about which right triangle a culture reaches for
## first, and the four answers are: the one you can tie in a rope, the one with a mirror,
## the one that makes sqrt(5), and the one that is beautiful.
##
## WHAT I CHANGED FROM THE SOURCE, and it is the load-bearing decision. righttriangle
## normalises the LONGER LEG to 1.0 (`LEG_RATIOS` comment, gd:37: "normalised so the longer
## leg is always 1.0 — the footprint never grows"), so its four triangles share a leg and
## their HYPOTENUSES differ: sqrt(2) = 1.414, 1.25, sqrt(5)/2 = 1.118, sqrt(phi) = 1.272 —
## a 26.5 percent spread, and their areas run 0.500 / 0.375 / 0.250 / 0.393 square metres.
## Four different sizes. This bench holds the HYPOTENUSE at 0.450 m instead, so the four are
## commensurable and the only difference in the picture is shape.
##
## That is itself a claim, and someone can refuse it. Holding c still privileges the side
## the theorem DERIVES; holding a leg still privileges the side you can lay out with a
## ruler. Normalising on c buys comparability and sells constructibility: at c = 0.450 the
## rope-stretcher's triangle has legs of 0.270 and 0.360 m, which is 3 and 4 of nothing.
## The value whose whole argument is that it needs no measurement is the one this
## normalisation can only reach by measuring.
##
## READINGS. Three distances from the claim, which is the ladder both source families
## already carry (righttriangle uniform -> corner_marked -> legs_hypotenuse; pythagorean
## axiom -> result -> longhand):
##
##   figure   the triangle as one slab and nothing else. righttriangle's `uniform`, which is
##            its shipped default: a mute wedge that names nothing.
##   marks    the draughtsman's notation on top of it — righttriangle's `corner_marked` AND
##            `legs_hypotenuse` in one, because at constant hypotenuse the corner glyph alone
##            is under half a percent of the board and would have been a null on its own.
##            Cyan legs (the two given sides), pink hypotenuse (the derived one), white square
##            glyph at the right angle. All three colours are righttriangle's own.
##   squares  pythagorean_triangle_angles' `result`: real squares erected on all three sides,
##            outward, as slabs. a^2 + b^2 = c^2 as built form — blue plus orange equals
##            purple, 0.2025 square metres against 0.2025 square metres, in every one of the
##            four cells.
##
## Nothing animates, nothing is printed, nothing is random. Every vertex is arithmetic on
## four constants, so two builds of one cell are the same mesh.


## WHICH RIGHT TRIANGLE. righttriangle's four values, its own order, its own default.
## NOTE ON THE HYPHENS, because this is where tier_terrarium died: "3-4-5" and "1-2" fail
## both int() and float(), so cabinet_sweep.coerce() hands them through as Strings and
## Object.set() on this typed String property cannot be silently refused. rule_bench's
## `rule` axis ("30", "90", ...) DOES numericise and depends on capture_config_sweep's
## enum-hint conversion; this axis does not need it. check_dna_declarations._strings()
## reads them out of the enum with a plain quoted-string findall, so apply_dna_block
## derives all four verbatim, hyphens and all.
@export_enum("isoceles", "3-4-5", "1-2", "kepler") var proportion: String = "isoceles":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not PROPORTIONS.has(picked):
			return                      ## an unreachable value keeps the current figure
		proportion = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## HOW MUCH IS ON SHOW. figure is righttriangle's shipped `uniform`, so the default cell of
## this bench is righttriangle's default triangle drawn the way righttriangle draws it.
@export_enum("figure", "marks", "squares") var reading: String = "figure":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not READINGS.has(picked):
			return
		reading = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One board, or all four proportions in a row. NOT PART OF EITHER AXIS — an all-values
## value inside an axis makes capture_config_sweep union the row's AABB with every single
## and photograph the singles as specks. The registry fixture pins `single`.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const PROPORTIONS: PackedStringArray = ["isoceles", "3-4-5", "1-2", "kepler"]
const READINGS: PackedStringArray = ["figure", "marks", "squares"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the four ratios, normalised on the HYPOTENUSE ──────────────────────────────────────
## SHORT_OVER_C is the leg that runs along +x (righttriangle's `bx`, the shorter one in
## every case but isoceles); LONG_OVER_C runs along +y. Derived from righttriangle's
## LEG_RATIOS by dividing through by the hypotenuse rather than by the longer leg:
##
##   isoceles  (1, 1)                    /sqrt(2)    -> 0.707107, 0.707107
##   3-4-5     (0.75, 1)                 /1.25       -> 0.6,      0.8
##   1-2       (0.5, 1)                  /sqrt(1.25) -> 0.447214, 0.894427
##   kepler    (0.7861513777574233, 1)   /sqrt(phi)  -> 0.618034, 0.786151
##
## Each column squares to 1: 0.5 + 0.5, 0.36 + 0.64, 0.2 + 0.8, 0.381966 + 0.618034.
## That check is the artifact's thesis in four lines.
const SHORT_OVER_C: Dictionary = {
	"isoceles": 0.70710678118654752,   # 1 / sqrt(2)
	"3-4-5": 0.6,                      # 3 / 5
	"1-2": 0.44721359549995793,        # 1 / sqrt(5)
	"kepler": 0.61803398874989485,     # 1 / phi
}
const LONG_OVER_C: Dictionary = {
	"isoceles": 0.70710678118654752,   # 1 / sqrt(2)
	"3-4-5": 0.8,                      # 4 / 5
	"1-2": 0.89442719099991586,        # 2 / sqrt(5)
	"kepler": 0.78615137775742328,     # 1 / sqrt(phi) — righttriangle's own literal
}

# ── the board, metres ──────────────────────────────────────────────────────────────────
## THE ONE LENGTH EVERY CELL SHARES. 0.450 m of hypotenuse, in all twelve cells.
const HYP: float = 0.450

## The union of all four `squares` figures, in units of HYP: x runs from -max(long) to
## max(short + long) and y from -max(short) to max(short + long), which is
## [-0.8944272, 1.4142136] x [-0.7071068, 1.4142136] = 2.3086408 x 2.1213204.
const FIELD_W: float = 1.038888        ## 2.3086408 * HYP
const FIELD_H: float = 0.954594        ## 2.1213204 * HYP

const BOARD_W: float = 1.090           ## FIELD_W + 2 * 0.02556 of margin
const BOARD_H: float = 1.006           ## FIELD_H + 2 * 0.02570
const BOARD_D: float = 0.020
const BASE_Y: float = 0.050            ## bottom of the board above the floor
const FIELD_CY: float = BASE_Y + BOARD_H * 0.5           ## 0.553 — board centre, field centre

## The right angle, and it does not move. Every figure has its 90 degrees HERE, so the two
## free vertices are the only thing the axis touches — which is invariants_demo's claim
## ("the right angle stays invariant") turned into a construction rule. Placed so the union
## field is centred on the board: the union's own centre sits at (+0.116952, +0.159099)
## from the right angle, so the right angle sits that far the other way from (0, 0.553).
const ORIGIN_X: float = -0.116952
const ORIGIN_Y: float = 0.393901

const REBATE_T: float = 0.008          ## the field's rebate; CONSTANT in every cell
const REBATE_D: float = 0.010
const SQUARE_D: float = 0.010          ## the three squares stand this proud of the board
const FIGURE_D: float = 0.016          ## the triangle stands proud of the squares
const MARK_D: float = 0.010            ## the notation stands proud of the triangle

## CONSTANT, not scaled by the legs. righttriangle sizes both from min(bx, by), which over
## these four values swings by 58 percent — so its notation would carry signal that belongs
## to the sides. Here the mark that names the invariant is itself invariant, and every pixel
## of difference in the `marks` reading comes from the two vertices that actually moved.
## Sized by a rasterised trial, not by eye: at righttriangle's own weight (12 mm here) the
## `figure`-against-`marks` pair measures 6.6 percent focus, which is a WEAK verdict on a
## reading that is plainly a different picture to a human. At 22 mm it is 12.2 percent, on
## the bar. That is a fact about a luminance metric and the note says so.
const MARK_T: float = 0.022            ## bar thickness, legs and hypotenuse
const GLYPH: float = 0.068             ## the draughtsman's square at the right angle
const GLYPH_T: float = 0.018

## The artifact's front is where the sweep stands: capture_config_sweep's standpoint bearing
## (YAW 0.62), so the board is seen as a drawing rather than edge-on. rule_bench's argument.
const FRONT_YAW: float = 0.62
const LADDER_PITCH: float = 1.200

const BOARD_COLOR: Color = Color(0.10, 0.10, 0.12)    ## rule_bench BACK_COLOR
const REBATE_COLOR: Color = Color(0.17, 0.18, 0.21)
## CHALK, NOT righttriangle's BLACK, and the inversion is deliberate. righttriangle's
## base_color is Color(0.1, 0.1, 0.1) and its @identity defends it ("the usefulness of black
## — a neutral diagnostic color"). That is a fact about a lit room. capture_config_sweep's
## backdrop is Color(0.055, 0.055, 0.070) — near black — so a black slab on it is a null by
## accident, not by design. The polarity is swapped: the BOARD takes the dark, the figure
## takes the light. Slate and chalk, which is also the right object for a rope-stretcher.
const FIGURE_COLOR: Color = Color(0.87, 0.85, 0.78)
const LEG_COLOR: Color = Color(0.15, 0.75, 0.85)      ## righttriangle LEG_MARK_COLOR
const HYP_COLOR: Color = Color(0.90, 0.25, 0.55)      ## righttriangle HYP_MARK_COLOR
const CORNER_COLOR: Color = Color(0.95, 0.95, 0.95)   ## righttriangle CORNER_MARK_COLOR
const SQ_A_COLOR: Color = Color(0.20, 0.60, 1.00)     ## pythagorean square_a (on leg a)
const SQ_B_COLOR: Color = Color(1.00, 0.60, 0.20)     ## pythagorean square_b (on leg b)
const SQ_C_COLOR: Color = Color(0.80, 0.20, 1.00)     ## pythagorean square_c (on c)

var _built: Array[Node3D] = []
## Set while a whole config dictionary is landing, so three keys cost one rebuild.
var _bulk: bool = false


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("proportion"):
		proportion = str(config_data["proportion"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
	_bulk = false
	_rebuild()


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


## The two legs in metres, for the current hypotenuse.
func _legs(prop: String) -> Vector2:
	var key: String = _pick(prop, PROPORTIONS, "isoceles")
	return Vector2(float(SHORT_OVER_C[key]) * HYP, float(LONG_OVER_C[key]) * HYP)


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var names: PackedStringArray = PackedStringArray()
	if layout == "ladder":
		names = PROPORTIONS.duplicate()
	else:
		names.append(_pick(proportion, PROPORTIONS, "isoceles"))
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Proportion" + names[i].replace("-", "_")
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH, 0.0, 0.0)
		holder.rotation.y = FRONT_YAW
		add_child(holder)
		_built.append(holder)
		_build_variant(holder, names[i])


# ── building ───────────────────────────────────────────────────────────────────────────

## The board and its rebate are IDENTICAL in all twelve cells and are drawn BEFORE either
## axis is consulted. That is what makes the sheet commensurable: capture_config_sweep
## unions the AABB across a spec's variants, so the framing is the board's and never moves,
## and artifact_dna_critic crops to the union of two frames' subject boxes — which here is
## the same rectangle for every pair, because the rebate is the outermost lit thing in
## every cell. Every number in the sheet therefore has the same denominator.
func _build_variant(holder: Node3D, prop: String) -> void:
	var board := SurfaceTool.new()
	board.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(board, Vector3(0.0, BASE_Y + BOARD_H * 0.5, -BOARD_D * 0.5),
		Vector3(BOARD_W, BOARD_H, BOARD_D))
	_commit(holder, "Board", board, BOARD_COLOR, 0.0)

	var rebate := SurfaceTool.new()
	rebate.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rw: float = FIELD_W + REBATE_T * 2.0
	var rh: float = FIELD_H + REBATE_T * 2.0
	var half_w: float = (FIELD_W + REBATE_T) * 0.5
	var half_h: float = (FIELD_H + REBATE_T) * 0.5
	_add_box(rebate, Vector3(0.0, FIELD_CY + half_h, REBATE_D * 0.5),
		Vector3(rw, REBATE_T, REBATE_D))
	_add_box(rebate, Vector3(0.0, FIELD_CY - half_h, REBATE_D * 0.5),
		Vector3(rw, REBATE_T, REBATE_D))
	_add_box(rebate, Vector3(-half_w, FIELD_CY, REBATE_D * 0.5),
		Vector3(REBATE_T, rh, REBATE_D))
	_add_box(rebate, Vector3(half_w, FIELD_CY, REBATE_D * 0.5),
		Vector3(REBATE_T, rh, REBATE_D))
	_commit(holder, "Rebate", rebate, REBATE_COLOR, 0.0)

	var legs: Vector2 = _legs(prop)
	var o := Vector2(ORIGIN_X, ORIGIN_Y)
	var p: Vector2 = o + Vector2(legs.x, 0.0)     ## the +x leg, `a`
	var q: Vector2 = o + Vector2(0.0, legs.y)     ## the +y leg, `b`

	if reading == "squares":
		_build_squares(holder, o, p, q)

	## The figure itself is in EVERY reading — it is the thing the axis is about, and a
	## reading that removed it would be measuring the notation instead of the triangle.
	var fig := SurfaceTool.new()
	fig.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_poly(fig, PackedVector2Array([o, p, q]), 0.0, FIGURE_D)
	_commit(holder, "Figure", fig, FIGURE_COLOR, 0.0)

	if reading == "marks":
		_build_marks(holder, o, p, q)


## pythagorean_triangle_angles' three squares, erected on the three sides, outward. Its
## update_square_mesh (gd:292-304) takes a directed edge p1 -> p2 and offsets by
## perp = (edge.y, -edge.x); walked round a counter-clockwise triangle that puts every
## square OUTSIDE. Same rule here, same three colours, and the two leg squares are real
## slabs rather than the source's alpha-0.3 planes because a still cannot see through
## transparency the way a headset can.
func _build_squares(holder: Node3D, o: Vector2, p: Vector2, q: Vector2) -> void:
	var sa := SurfaceTool.new()
	sa.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_poly(sa, _erect(o, p), 0.0, SQUARE_D)
	_commit(holder, "SquareOnA", sa, SQ_A_COLOR, 0.35)

	var sb := SurfaceTool.new()
	sb.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_poly(sb, _erect(q, o), 0.0, SQUARE_D)
	_commit(holder, "SquareOnB", sb, SQ_B_COLOR, 0.35)

	var sc := SurfaceTool.new()
	sc.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_poly(sc, _erect(p, q), 0.0, SQUARE_D)
	_commit(holder, "SquareOnC", sc, SQ_C_COLOR, 0.35)


## righttriangle's corner_marked and legs_hypotenuse, together, as geometry. The two given
## sides in cyan, the derived one in pink, and the white square glyph naming the invariant.
func _build_marks(holder: Node3D, o: Vector2, p: Vector2, q: Vector2) -> void:
	var legs := SurfaceTool.new()
	legs.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_poly(legs, _bar(o, p, MARK_T), FIGURE_D, MARK_D)
	_add_poly(legs, _bar(o, q, MARK_T), FIGURE_D, MARK_D)
	_commit(holder, "Legs", legs, LEG_COLOR, 0.35)

	var hyp := SurfaceTool.new()
	hyp.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_poly(hyp, _bar(p, q, MARK_T), FIGURE_D, MARK_D)
	_commit(holder, "Hypotenuse", hyp, HYP_COLOR, 0.35)

	var corner := SurfaceTool.new()
	corner.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_poly(corner, _bar(o + Vector2(0.0, GLYPH), o + Vector2(GLYPH, GLYPH), GLYPH_T),
		FIGURE_D, MARK_D)
	_add_poly(corner, _bar(o + Vector2(GLYPH, 0.0), o + Vector2(GLYPH, GLYPH), GLYPH_T),
		FIGURE_D, MARK_D)
	_commit(holder, "RightAngle", corner, CORNER_COLOR, 0.0)


## The square erected outward on the directed edge a -> b of a counter-clockwise polygon,
## wound counter-clockwise itself.
func _erect(a: Vector2, b: Vector2) -> PackedVector2Array:
	var e: Vector2 = b - a
	var perp := Vector2(e.y, -e.x)
	return PackedVector2Array([a, a + perp, b + perp, b])


## A rectangle of thickness t centred on the segment a -> b, wound counter-clockwise.
func _bar(a: Vector2, b: Vector2, t: float) -> PackedVector2Array:
	var e: Vector2 = b - a
	var l: float = e.length()
	if l < 0.000001 or t <= 0.0:
		return PackedVector2Array()
	var off: Vector2 = Vector2(-e.y, e.x) / l * (t * 0.5)
	return PackedVector2Array([a - off, b - off, b + off, a + off])


## A convex counter-clockwise polygon in XY, extruded from z0 to z0 + d. Fan-triangulated
## front and back with explicit outward normals, plus one quad per edge whose normal is the
## edge's own outward perpendicular. Wave 13's lesson twice over: a face wound inward is
## indistinguishable from a face that was never built, so the winding is explicit AND every
## material is CULL_DISABLED.
func _add_poly(st: SurfaceTool, pts: PackedVector2Array, z0: float, d: float) -> void:
	var n: int = pts.size()
	if n < 3:
		return
	var zf: float = z0 + d
	for i in range(1, n - 1):
		_tri(st, Vector3(pts[0].x, pts[0].y, zf), Vector3(pts[i].x, pts[i].y, zf),
			Vector3(pts[i + 1].x, pts[i + 1].y, zf), Vector3(0.0, 0.0, 1.0))
		_tri(st, Vector3(pts[0].x, pts[0].y, z0), Vector3(pts[i + 1].x, pts[i + 1].y, z0),
			Vector3(pts[i].x, pts[i].y, z0), Vector3(0.0, 0.0, -1.0))
	for i in range(n):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		var e: Vector2 = b - a
		var l: float = e.length()
		if l < 0.000001:
			continue
		var nrm := Vector3(e.y / l, -e.x / l, 0.0)
		_quad(st, Vector3(a.x, a.y, zf), Vector3(a.x, a.y, z0),
			Vector3(b.x, b.y, z0), Vector3(b.x, b.y, zf), nrm)


## An axis-aligned box, twelve triangles, wound outward with explicit per-face normals.
func _add_box(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var v: PackedVector3Array = PackedVector3Array([
		at + Vector3(-h.x, -h.y, h.z), at + Vector3(h.x, -h.y, h.z),
		at + Vector3(h.x, h.y, h.z), at + Vector3(-h.x, h.y, h.z),
		at + Vector3(-h.x, -h.y, -h.z), at + Vector3(h.x, -h.y, -h.z),
		at + Vector3(h.x, h.y, -h.z), at + Vector3(-h.x, h.y, -h.z)])
	_quad(st, v[0], v[1], v[2], v[3], Vector3(0.0, 0.0, 1.0))
	_quad(st, v[5], v[4], v[7], v[6], Vector3(0.0, 0.0, -1.0))
	_quad(st, v[3], v[2], v[6], v[7], Vector3(0.0, 1.0, 0.0))
	_quad(st, v[4], v[5], v[1], v[0], Vector3(0.0, -1.0, 0.0))
	_quad(st, v[1], v[5], v[6], v[2], Vector3(1.0, 0.0, 0.0))
	_quad(st, v[4], v[0], v[3], v[7], Vector3(-1.0, 0.0, 0.0))


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	var verts: PackedVector3Array = PackedVector3Array([a, b, c])
	for v in verts:
		st.set_normal(n)
		st.add_vertex(v)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	_tri(st, a, b, c, n)
	_tri(st, a, c, d, n)


func _commit(holder: Node3D, mesh_name: String, st: SurfaceTool, c: Color,
		emit_energy: float) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = _mat(c, emit_energy)
	holder.add_child(mi)


func _mat(c: Color, emit_energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.1
	m.roughness = 0.65
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emit_energy > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = maxf(0.0, emit_energy)
	return m
