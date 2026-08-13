extends Node3D
class_name OpeningPair

## OPENING PAIR — a synthesis for the `opening` family.
##
## @identity
## essence: one pair of rays, computed once, read on three grounds. The angle
##   between two directions and the curvature of the space they sit in are the
##   same question asked twice, and the family answers it in two vocabularies
##   that have never stood in one frame.
## truth: two rays that are `opposing` on a flat plane are not opposing on a
##   sphere. The pair does not own its angle. The ground does.
##
## ─────────────────────────────────────────────────────────────────────────────
## THE FAMILY, AND WHY THIS ARTIFACT EXISTS
##
## Six registry names declare an axis called `opening`, and they carry TWO value
## lists that are two different questions:
##
##   (a) agreeing | strangers | opposing | parallel   — agreement_gauge,
##       dot_aligner, dot_product_projector, exercise_5_9_angle_between.
##       The angle BETWEEN TWO VECTORS, read off the sign of a·b: positive, zero,
##       negative, and the degenerate case where there is no angle at all.
##
##   (b) flat | hyperbolic | elliptic                 — angle_sum_triangle,
##       curvature_slider.
##       The curvature OF THE SPACE, read off the angle sum of a triangle.
##
## Every one of the six stands in ONE of those lists and cannot reach the other,
## so the corpus has a word that means two things and no place where the two
## meanings meet. This artifact is that place: axis (a) against axis (b), a
## genuine 4 × 3 cross.
##
## THE WORD IS TAKEN ONCE AND REFUSED ONCE, ON THE RECORD (law 1).
##   · `opening` here is list (a), verbatim, in order, read at runtime out of
##     dot_product_projector.OPENINGS and cross-checked against
##     dot_aligner.OPENINGS. The artifact is named for it: the opening OF the
##     pair is the angle the pair opens to.
##   · list (b) could not also be called `opening` — a registry `dna.axes` block
##     is a dict and cannot hold the key twice, and neither can one script hold
##     two @export vars of that name. So the SECOND axis is called `ground`,
##     and its VALUES are angle_sum_triangle.OPENING_VALUES verbatim, in that
##     artifact's order, cross-checked as a set against curvature_slider.OPENINGS
##     (whose dict is keyed in K order, not declaration order).
##     Refusing the word and keeping the answers is the honest half of a shared
##     vocabulary; the collision is the finding, not a fault to paper over.
##
## AXIS SHAPE (law 2). Both axes are SIDE BY SIDE and MUTUALLY EXCLUSIVE, so both
## are varied and neither can be held standing.
##   · (a) is exclusive in the family's own code: dot_product_projector
##     ._apply_opening() rotates the single vector_a to ONE angle out of
##     OPENING_DEGREES; agreement_gauge._b_for_opening() returns ONE Vector3.
##     There is one b, so there is one angle.
##   · (b) is exclusive in the family's own code: angle_sum_triangle._bow_sign()
##     is a `match` returning one of {+1, -1, 0} into one scalar; curvature_
##     slider.OPENINGS maps each value to one float K. There is one polyline, so
##     there is one sign.
## The SIMULTANEITY lives in the cross, and in the rail: every frame carries all
## three grounds' readings of the pair it is showing, so the disagreement between
## the grounds is in the picture at every value.
##
## DETERMINISM (law 11): no randf, no randomize, no _process, no timer, no
## physics, no signals. _ready() builds once; apply_grid_config rebuilds only when
## a value this artifact owns actually changed.
## ─────────────────────────────────────────────────────────────────────────────
##
## Z-STACK, front to back (law 7). Every mark the axes draw is IN FRONT of every
## piece of furniture, and nothing spans another layer's interval:
##
##   z = +0.032  caption glyphs
##   z = +0.030  caption plate            (constant at every value)
##   z = +0.028  vertex / tip beads       ← opening
##   z = +0.024  the figure's edges       ← opening AND ground
##   z = +0.020  the FIXED 180° notch     (constant; drawn in front of the puck
##                                         so the datum is never hidden by a
##                                         reading that happens to sit on it)
##   z = +0.018  active ground's puck     ← ground
##   z = +0.016  the other two grounds' pips
##   z = +0.012  rail body                (constant)
##   z = +0.010  field ribs               ← ground
##   z = +0.008  field rim                ← ground
##   z = -0.020 … 0.000  slate panel      (constant, and the only wide surface)
##   z = -0.070 … +0.030 foot             (constant, y ≤ 0.05, below every mark)
##
## No layer is a slab enclosing another. The panel is 20 mm thick and sits ENTIRELY
## BEHIND z = 0; the deepest mark is the field rim at +8 mm. The foot protrudes to
## +30 mm but tops out at y = 0.05 while the lowest mark (the caption plate) starts
## at y = 0.055, and the camera pitches DOWN, so a nearer, lower body cannot rise
## over a farther, higher one.

# ═════════════════════════════════════════════════════════════════════════════
# THE FAMILY'S OWN WORDS AND ARITHMETIC — preloaded, never retyped
#
# All four are zero-preload `extends Node3D` scripts, so this costs one parse each
# and drags in no scenes. agreement_gauge is list (a)'s ORIGINAL owner and is
# deliberately NOT preloaded: it extends a scene base and preloads three .tscn
# interactables, and a synthesis should not pull a control-panel rig into a still.
# dot_product_projector carries the identical list character for character AND the
# angle table that agreement_gauge keeps as a local if-chain, so it is the better
# source; dot_aligner is preloaded purely to cross-check it.
# ═════════════════════════════════════════════════════════════════════════════
const OPENING_SRC := preload("res://commons/artifacts/dot_product_projector/dot_product_projector.gd")
const OPENING_ALT := preload("res://commons/artifacts/dot_aligner/dot_aligner.gd")
const GROUND_SRC := preload("res://commons/artifacts/angle_sum_triangle/angle_sum_triangle.gd")
const GROUND_ALT := preload("res://commons/artifacts/curvature_slider/curvature_slider.gd")

## GDScript forces a literal into an @export_enum hint, so these two lists are the
## one place the family's words are written down twice. _check_vocabulary()
## compares them against the preloaded originals IN BOTH DIRECTIONS at _ready and
## push_error()s on any divergence, so a drift is loud rather than silent.
const OPENING_VALUES: Array[String] = ["agreeing", "strangers", "opposing", "parallel"]
const GROUND_VALUES: Array[String] = ["flat", "hyperbolic", "elliptic"]

## `agreeing` is in NO member's angle table, because every member short-circuits it
## to its own shipped pose: 40° (agreement_gauge), 35.5° (dot_product_projector),
## 60° (exercise_5_9_angle_between), ~16° (dot_aligner). A synthesis has no shipped
## pose to hand back (law 15), so it takes the number of the artifact that owns the
## word. The other three angles are read from OPENING_SRC.OPENING_DEGREES.
const AGREEING_DEG: float = 40.0

## agreement_gauge's rail colours, and its red ← grey → green mapping of cos(theta).
## Transcribed rather than preloaded, for the reason given above; they are three
## Color literals and no gate can check them, so this comment is the record.
const COLOR_RED: Color = Color(0.92, 0.22, 0.2)
const COLOR_GREY: Color = Color(0.55, 0.57, 0.6)
const COLOR_GREEN: Color = Color(0.3, 0.92, 0.4)

# ── the body ─────────────────────────────────────────────────────────────────
const PANEL_W: float = 0.56
const PANEL_Y0: float = 0.05
const PANEL_Y1: float = 0.70
const PANEL_Z0: float = -0.02
const PANEL_Z1: float = 0.0
const FOOT_Y1: float = 0.05
const FOOT_Z0: float = -0.07
const FOOT_Z1: float = 0.03

# ── the ground field ─────────────────────────────────────────────────────────
const FIELD_HALF: float = 0.21
const FIELD_CY: float = 0.44
## Rib offsets as a fraction of FIELD_HALF. |t| == 1.0 is the rim. There is no rib
## at t = 0: a centre cross would sit directly behind the figure and clutter it,
## and the centre line of a bowed chart is the one line that never moves anyway.
const RIB_T: Array[float] = [-1.0, -0.7, 0.7, 1.0]
const RIB_W: float = 0.007
const RIM_W: float = 0.009

# ── the pair ─────────────────────────────────────────────────────────────────
const VERTEX: Vector2 = Vector2(0.0, 0.355)
const RAY_LEN: float = 0.175
const EDGE_W: float = 0.012
const BEAD_R: float = 0.01

# ── the rail ─────────────────────────────────────────────────────────────────
const RAIL_HALF: float = 0.24
const RAIL_Y: float = 0.17
const RAIL_H: float = 0.016
const NOTCH_W: float = 0.009
const NOTCH_H: float = 0.044
const PIP_W: float = 0.009
const PIP_H: float = 0.022
const PUCK_W: float = 0.018
const PUCK_H: float = 0.03
## FIXED CEILING (law 5). The rail reads 0°…360° at every value of every axis and
## never rescales to its own contents, so the 180° notch is at x = 0 in all twelve
## frames and two tiles can be laid side by side and read against each other. A
## spherical triangle can reach 540° and a hyperbolic one 0°, so 360 does not
## bound the mathematics — it bounds THIS FIGURE, whose measured extremes at the
## family's own sagitta are 108.01° and 251.99°, and it is the choice that puts
## the flat answer exactly at the middle of the rail.
const SUM_MAX: float = 360.0

const CAPTION_Y: float = 0.088
const PLATE_W: float = 0.40
const PLATE_H: float = 0.066

const Z_RIM: float = 0.008
const Z_RIB: float = 0.01
const Z_RAIL: float = 0.012
const Z_PIP: float = 0.016
const Z_PUCK: float = 0.018
const Z_NOTCH: float = 0.02
const Z_EDGE: float = 0.024
const Z_BEAD: float = 0.028
const Z_PLATE: float = 0.03
const Z_TEXT: float = 0.032

const C_SLATE: Color = Color(0.09, 0.1, 0.12)
const C_FOOT: Color = Color(0.126, 0.14, 0.168)
const C_RIB: Color = Color(0.26, 0.3, 0.38)
const C_RIM: Color = Color(0.45, 0.52, 0.62)
const C_RAIL: Color = Color(0.3, 0.34, 0.42)
const C_PIP: Color = Color(0.52, 0.56, 0.62)
const C_NOTCH: Color = Color(0.88, 0.89, 0.92)
const C_PUCK: Color = Color(0.55, 0.7, 1.0)
const C_PLATE: Color = Color(0.2, 0.22, 0.26)

## AXIS 1 — WHICH GROUND THE PAIR IS ON. angle_sum_triangle's list, in its order.
## The ground is drawn twice over: as the field the pair sits in (a rim and four
## ribs bowed by the family's own sagitta rule, so the border of a flat ground is
## straight, an elliptic one barrels out and a hyperbolic one pinches in), and as
## the figure's edges, which bow the same way because they are geodesics of the
## same ground.
##   flat        the edges are straight chords and the angle sum is exactly 180°.
##   hyperbolic  the edges bow inward; the corners close; the sum falls under 180°.
##   elliptic    the edges bow outward; the corners open; the sum climbs over 180°.
@export_enum("flat", "hyperbolic", "elliptic") var ground: String = "flat"

## AXIS 2 — WHAT ANGLE THE PAIR OPENS TO. dot_product_projector's list, in its
## order, which is agreement_gauge's list in agreement_gauge's order. Only the
## angle turns: the vertex, both ray lengths and the bisector are fixed at every
## value, so this axis moves theta and nothing else — the same discipline
## _b_for_opening() and _apply_opening() keep in the members.
##   agreeing    theta 40°,  cos > 0 — the figure is drawn green.
##   strangers   theta 90°,  cos = 0 exactly — grey, the family's zero.
##   opposing    theta 140°, cos < 0 — red.
##   parallel    theta 0° — the two rays are ONE ray. There is no angle, no
##               interior, and therefore nothing for the ground to act on: the
##               figure collapses to a single stroke and the rail goes EMPTY.
@export_enum("agreeing", "strangers", "opposing", "parallel") var opening: String = "agreeing"

var _built: bool = false
var _root: Node3D
## The one copy of the arithmetic (law 3): { ground_name: { "pts", "angles", "sum" } },
## computed once per build for ALL THREE grounds and read three ways — as the drawn
## figure, as the rail's three ticks, and as the caption.
var _reading: Dictionary = {}
var _degenerate: bool = false


func _ready() -> void:
	_check_vocabulary()
	# The artifact draws its own caption plate (see the z-stack above), so
	# LabelFramer must not fit a second one over it. This is the opt-out
	# LabelFramer itself documents, not a way around it.
	set_meta("config_framed_labels", "false")
	_build()
	_built = true


# ═════════════════════════════════════════════════════════════════════════════
# VOCABULARY — checked in BOTH directions against the originals
# ═════════════════════════════════════════════════════════════════════════════

func _check_vocabulary() -> void:
	# Reading OPENING_SRC.OPENINGS rather than get_script_constant_map() is
	# deliberate: the latter is non-static and fails on a preloaded class, while
	# this form fails at PARSE time if a member ever deletes the const, which is
	# the failure mode worth having.
	_compare_ordered("opening", OPENING_VALUES, OPENING_SRC.OPENINGS, "dot_product_projector")
	_compare_ordered("opening", OPENING_VALUES, OPENING_ALT.OPENINGS, "dot_aligner")
	_compare_ordered("ground", GROUND_VALUES, GROUND_SRC.OPENING_VALUES, "angle_sum_triangle")
	# curvature_slider stores the same three values as a Dictionary keyed in K
	# order (hyperbolic, flat, elliptic), so only the SET can be compared.
	_compare_unordered("ground", GROUND_VALUES, GROUND_ALT.OPENINGS.keys(), "curvature_slider")


func _compare_ordered(axis: String, mine: Array[String], theirs, who: String) -> void:
	if theirs == null or int(theirs.size()) != mine.size():
		push_error("opening_pair: `%s` has %d values, %s has %d" % [
			axis, mine.size(), who, 0 if theirs == null else int(theirs.size())])
		return
	for i in range(mine.size()):
		if String(theirs[i]) != mine[i]:
			push_error("opening_pair: `%s`[%d] is '%s' here and '%s' in %s" % [
				axis, i, mine[i], String(theirs[i]), who])


func _compare_unordered(axis: String, mine: Array[String], theirs, who: String) -> void:
	if theirs == null or int(theirs.size()) != mine.size():
		push_error("opening_pair: `%s` has %d values, %s has %d" % [
			axis, mine.size(), who, 0 if theirs == null else int(theirs.size())])
		return
	for v in mine:
		if not theirs.has(v):
			push_error("opening_pair: `%s` value '%s' is not in %s" % [axis, v, who])
	for v in theirs:
		if not mine.has(String(v)):
			push_error("opening_pair: %s carries '%s', which `%s` does not" % [who, String(v), axis])


func _opening_value() -> String:
	var o: String = String(opening).strip_edges().to_lower()
	return o if OPENING_VALUES.has(o) else "agreeing"


func _ground_value() -> String:
	var g: String = String(ground).strip_edges().to_lower()
	return g if GROUND_VALUES.has(g) else "flat"


## The angle the pair opens to. The three named angles come from the family's own
## table; `agreeing` is not in it, for the reason at AGREEING_DEG.
func _theta_deg() -> float:
	var o: String = _opening_value()
	if OPENING_SRC.OPENING_DEGREES.has(o):
		return float(OPENING_SRC.OPENING_DEGREES[o])
	return AGREEING_DEG


## angle_sum_triangle._bow_sign(), re-derived from GROUND_VALUES rather than
## re-typed as a match on three literals.
func _bow_sign(g: String) -> float:
	if g == GROUND_VALUES[2]:
		return 1.0
	if g == GROUND_VALUES[1]:
		return -1.0
	return 0.0


# ═════════════════════════════════════════════════════════════════════════════
# THE ARITHMETIC — computed ONCE, read three ways
# ═════════════════════════════════════════════════════════════════════════════

## angle_sum_triangle's own bow, formula for formula: bulge = 4t(1-t) * s * chord,
## laid along `outward`, at its own ARC_SEGMENTS. SAGITTA_RATIO is a fraction of
## the chord and therefore dimensionless, so it transplants to this figure's scale
## without rescaling — which is exactly why it is read and not re-tuned.
func _bowed_edge(a: Vector2, b: Vector2, outward: Vector2, s: float) -> Array[Vector2]:
	var pts: Array[Vector2] = [a]
	if is_zero_approx(s):
		return pts
	var chord: float = a.distance_to(b)
	var segs: int = int(GROUND_SRC.ARC_SEGMENTS)
	for j in range(1, segs):
		var t: float = float(j) / float(segs)
		var bulge: float = 4.0 * t * (1.0 - t) * s * chord
		pts.append(a.lerp(b, t) + outward * bulge)
	return pts


## The two rays, as tips. The vertex and both lengths are fixed at every value; the
## bisector points straight up, so the axis turns theta and nothing else.
func _tips() -> Array[Vector2]:
	var half: float = deg_to_rad(_theta_deg()) * 0.5
	var dx: float = RAY_LEN * sin(half)
	var dy: float = RAY_LEN * cos(half)
	var out: Array[Vector2] = [VERTEX + Vector2(dx, dy), VERTEX + Vector2(-dx, dy)]
	return out


## The closed figure the pair makes on ground `g`, and the corner angles MEASURED
## off it — angle_sum_triangle's discipline: a protractor laid on the picture that
## is actually drawn, never an asserted number.
func _figure(g: String) -> Dictionary:
	var tips: Array[Vector2] = _tips()
	var ta: Vector2 = tips[0]
	var tb: Vector2 = tips[1]
	if ta.distance_to(tb) < 0.000001:
		# `parallel`: the two rays are ONE geodesic. There is no interior, so the
		# family's bow rule (outward = mid - centroid) has no direction to point
		# and NO BOW IS DRAWN, on any ground. That is not a fallback — a single
		# geodesic has nothing to deviate from. By Gauss–Bonnet the excess over a
		# zero-area region is K·A = 0, so there is no reading either, and the rail
		# is left empty rather than parked on a number nothing computed (law 6).
		var stroke: Array[Vector2] = [VERTEX, ta]
		var none: Array[float] = []
		return {"pts": stroke, "angles": none, "sum": -1.0, "degenerate": true}
	var verts: Array[Vector2] = [VERTEX, ta, tb]
	var centroid: Vector2 = (verts[0] + verts[1] + verts[2]) / 3.0
	var s: float = _bow_sign(g) * float(GROUND_SRC.SAGITTA_RATIO)
	var pts: Array[Vector2] = []
	for i in range(3):
		var a: Vector2 = verts[i]
		var b: Vector2 = verts[(i + 1) % 3]
		var mid: Vector2 = (a + b) * 0.5
		var outward: Vector2 = mid - centroid
		# Vector2(0, 1) and NOT Vector2.UP, which is (0, -1) in Godot's 2D convention
		# while the member this is copied from falls back to Vector3.UP = (0, 1, 0).
		# Unreachable for a triangle with area (mid == centroid only if the third
		# vertex sits on the opposite midpoint, i.e. collinear), but a silent sign
		# flip in an unreachable branch is still a trap left for the next reader.
		outward = outward.normalized() if outward.length() > 0.000001 else Vector2(0.0, 1.0)
		pts.append_array(_bowed_edge(a, b, outward, s))
	var angles: Array[float] = _measured_angles(pts)
	var total: float = 0.0
	for v in angles:
		total += v
	return {"pts": pts, "angles": angles, "sum": total, "degenerate": false}


## angle_sum_triangle._angles(), same stride and same neighbours: at each corner,
## the angle between the first segment leaving it and the last segment arriving.
func _measured_angles(pts: Array[Vector2]) -> Array[float]:
	var out: Array[float] = []
	var n: int = pts.size()
	if n < 3:
		var zero: Array[float] = [0.0, 0.0, 0.0]
		return zero
	var stride: int = n / 3
	for i in range(3):
		var idx: int = i * stride
		var prev: Vector2 = pts[(idx - 1 + n) % n]
		var nxt: Vector2 = pts[(idx + 1) % n]
		var d1: Vector2 = prev - pts[idx]
		var d2: Vector2 = nxt - pts[idx]
		var deg: float = 0.0
		if d1.length() > 0.00001 and d2.length() > 0.00001:
			# NOT Vector2.angle_to, which is SIGNED and returns (-PI, PI]. The member
			# this is copied from calls Vector3.angle_to, which is unsigned and returns
			# [0, PI]; the 2D method of the same name is a different function, and a
			# signed corner angle would let a triangle's three angles cancel to a sum
			# nothing in the picture supports. acos of the dot is the unsigned value,
			# and it is what the pre-build rasteriser measured.
			var c: float = clampf(d1.normalized().dot(d2.normalized()), -1.0, 1.0)
			deg = rad_to_deg(acos(c))
		out.append(deg)
	return out


## agreement_gauge._agreement_color: red ← grey → green on cos(theta). The pair's
## colour is the SIGN of a·b, which is the whole content of vocabulary (a).
func _agreement_color(cos_theta: float) -> Color:
	var c: float = clampf(cos_theta, -1.0, 1.0)
	if c < 0.0:
		return COLOR_GREY.lerp(COLOR_RED, -c)
	return COLOR_GREY.lerp(COLOR_GREEN, c)


# ═════════════════════════════════════════════════════════════════════════════
# BUILD
# ═════════════════════════════════════════════════════════════════════════════

func _build() -> void:
	_root = Node3D.new()
	_root.name = "OpeningPairBody"
	add_child(_root)

	# ONE COPY OF THE ARITHMETIC: the same pair, read on all three grounds, before
	# anything is drawn. The active ground picks which reading becomes the figure;
	# all three become ticks on the rail.
	_reading.clear()
	for g in GROUND_VALUES:
		_reading[g] = _figure(g)
	_degenerate = bool(_reading[_ground_value()]["degenerate"])

	_build_body()
	_build_field()
	_build_rail()
	_build_figure()
	_build_caption()


func _build_body() -> void:
	_root.add_child(_box("Panel", Vector3(PANEL_W, PANEL_Y1 - PANEL_Y0, PANEL_Z1 - PANEL_Z0),
		Vector3(0.0, (PANEL_Y0 + PANEL_Y1) * 0.5, (PANEL_Z0 + PANEL_Z1) * 0.5), C_SLATE))
	_root.add_child(_box("Foot", Vector3(PANEL_W, FOOT_Y1, FOOT_Z1 - FOOT_Z0),
		Vector3(0.0, FOOT_Y1 * 0.5, (FOOT_Z0 + FOOT_Z1) * 0.5), C_FOOT))


## The ground itself. The rim and the ribs bow by the family's sagitta, scaled by
## how far the line sits from the centre of the field, so a flat ground is a square
## grid, an elliptic one barrels outward and a hyperbolic one pinches inward.
func _build_field() -> void:
	var s: float = _bow_sign(_ground_value()) * float(GROUND_SRC.SAGITTA_RATIO)
	var ribs := ImmediateMesh.new()
	var rim := ImmediateMesh.new()
	ribs.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	rim.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in RIB_T:
		# Bound to an explicitly typed local before use: an untyped loop variable in
		# an arithmetic expression is a known GDScript compile trap in this repo.
		var tv: float = t
		var is_rim: bool = is_equal_approx(absf(tv), 1.0)
		var im: ImmediateMesh = rim if is_rim else ribs
		var w: float = RIM_W if is_rim else RIB_W
		var z: float = Z_RIM if is_rim else Z_RIB
		var d: float = tv * FIELD_HALF
		var sgn: float = 1.0 if tv >= 0.0 else -1.0
		var bow: float = s * absf(tv)
		var ha: Vector2 = Vector2(-FIELD_HALF, FIELD_CY + d)
		var hb: Vector2 = Vector2(FIELD_HALF, FIELD_CY + d)
		var hp: Array[Vector2] = _bowed_edge(ha, hb, Vector2(0.0, sgn), bow)
		hp.append(hb)
		_ribbon(im, hp, w, z)
		var va: Vector2 = Vector2(d, FIELD_CY - FIELD_HALF)
		var vb: Vector2 = Vector2(d, FIELD_CY + FIELD_HALF)
		var vp: Array[Vector2] = _bowed_edge(va, vb, Vector2(sgn, 0.0), bow)
		vp.append(vb)
		_ribbon(im, vp, w, z)
	ribs.surface_end()
	rim.surface_end()
	_root.add_child(_flat_mesh("FieldRibs", ribs, C_RIB))
	_root.add_child(_flat_mesh("FieldRim", rim, C_RIM))


## The rail. Body and 180° notch are constant at every value; the three ticks are
## the SAME pair read on all three grounds, so a still carries the comparison the
## cross exists to make.
func _build_rail() -> void:
	var body := ImmediateMesh.new()
	body.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_quad(body, -RAIL_HALF, RAIL_Y - RAIL_H * 0.5, RAIL_HALF, RAIL_Y + RAIL_H * 0.5, Z_RAIL)
	body.surface_end()
	_root.add_child(_flat_mesh("RailBody", body, C_RAIL))

	var notch := ImmediateMesh.new()
	notch.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_quad(notch, -NOTCH_W * 0.5, RAIL_Y - NOTCH_H * 0.5, NOTCH_W * 0.5, RAIL_Y + NOTCH_H * 0.5, Z_NOTCH)
	notch.surface_end()
	_root.add_child(_flat_mesh("RailNotch180", notch, C_NOTCH))

	if _degenerate:
		return
	var pips := ImmediateMesh.new()
	var puck := ImmediateMesh.new()
	pips.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	puck.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var active: String = _ground_value()
	for g in GROUND_VALUES:
		var x: float = _rail_x(float(_reading[g]["sum"]))
		if g == active:
			_quad(puck, x - PUCK_W * 0.5, RAIL_Y - PUCK_H * 0.5, x + PUCK_W * 0.5, RAIL_Y + PUCK_H * 0.5, Z_PUCK)
		else:
			_quad(pips, x - PIP_W * 0.5, RAIL_Y - PIP_H * 0.5, x + PIP_W * 0.5, RAIL_Y + PIP_H * 0.5, Z_PIP)
	pips.surface_end()
	puck.surface_end()
	_root.add_child(_flat_mesh("RailPips", pips, C_PIP))
	_root.add_child(_flat_mesh("RailPuck", puck, C_PUCK))


func _rail_x(sum_deg: float) -> float:
	return -RAIL_HALF + 2.0 * RAIL_HALF * clampf(sum_deg / SUM_MAX, 0.0, 1.0)


func _build_figure() -> void:
	var r: Dictionary = _reading[_ground_value()]
	var pts: Array[Vector2] = r["pts"]
	var col: Color = _agreement_color(cos(deg_to_rad(_theta_deg())))

	var edges := ImmediateMesh.new()
	edges.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var closed: Array[Vector2] = []
	closed.append_array(pts)
	if not _degenerate:
		closed.append(pts[0])
	_ribbon(edges, closed, EDGE_W, Z_EDGE)
	edges.surface_end()
	_root.add_child(_flat_mesh("Figure", edges, col))

	var beads := ImmediateMesh.new()
	beads.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var marks: Array[Vector2] = [VERTEX]
	if _degenerate:
		marks.append(pts[pts.size() - 1])
	else:
		marks.append_array(_tips())
	for p in marks:
		_quad(beads, p.x - BEAD_R, p.y - BEAD_R, p.x + BEAD_R, p.y + BEAD_R, Z_BEAD)
	beads.surface_end()
	_root.add_child(_flat_mesh("Beads", beads, col))


## The caption names both active values and every number the rail draws, so a still
## of this artifact cannot misreport itself.
func _build_caption() -> void:
	var plate := ImmediateMesh.new()
	plate.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_quad(plate, -PLATE_W * 0.5, CAPTION_Y - PLATE_H * 0.5, PLATE_W * 0.5, CAPTION_Y + PLATE_H * 0.5, Z_PLATE)
	plate.surface_end()
	_root.add_child(_flat_mesh("CaptionPlate", plate, C_PLATE))

	# Gauged against PLATE_W: the longest line either branch can produce is 32
	# characters, and at font_size 15 / pixel_size 0.0012 that is about 0.35 m
	# against a 0.40 m plate. The short ground names are derived from the values
	# themselves rather than typed out, so a renamed value cannot strand a legend.
	var line2: String = "no angle, no interior, no reading"
	if not _degenerate:
		var parts: PackedStringArray = PackedStringArray()
		for g in GROUND_VALUES:
			var tag: String = g if g.length() <= 4 else g.substr(0, 3)
			parts.append("%s %d" % [tag, int(round(float(_reading[g]["sum"])))])
		line2 = "sum: " + "  ".join(parts)
	var label := Label3D.new()
	label.name = "Caption"
	label.text = "%s %d deg  -  %s\n%s" % [_opening_value(), int(round(_theta_deg())), _ground_value(), line2]
	# Law 8: state the alignment rather than inherit it. Label3D hangs from its
	# origin, and CENTER is the only setting that puts this text over its plate.
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.font_size = 15
	label.pixel_size = 0.0012
	label.outline_size = 0
	label.modulate = Color(0.86, 0.88, 0.92)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.no_depth_test = false
	label.position = Vector3(0.0, CAPTION_Y, Z_TEXT)
	_root.add_child(label)


# ═════════════════════════════════════════════════════════════════════════════
# MESH HELPERS — every mark is a flat ribbon in the panel plane, gauged in metres
# ═════════════════════════════════════════════════════════════════════════════

func _tri(im: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3) -> void:
	im.surface_set_normal(Vector3(0.0, 0.0, 1.0))
	im.surface_add_vertex(a)
	im.surface_set_normal(Vector3(0.0, 0.0, 1.0))
	im.surface_add_vertex(b)
	im.surface_set_normal(Vector3(0.0, 0.0, 1.0))
	im.surface_add_vertex(c)


func _quad(im: ImmediateMesh, x0: float, y0: float, x1: float, y1: float, z: float) -> void:
	var a := Vector3(x0, y0, z)
	var b := Vector3(x1, y0, z)
	var c := Vector3(x1, y1, z)
	var d := Vector3(x0, y1, z)
	_tri(im, a, b, c)
	_tri(im, a, c, d)


## A polyline drawn with real WIDTH. ImmediateMesh line strips render one pixel
## wide whatever the camera does, which is under the bench's legibility floor and
## under a visitor's; at this artifact's framing (0.55) the sweep resolves
## 806 px/m, so a 12 mm edge is 9.4 px tall and 7.7 px wide after the 35° yaw
## foreshortening, and the 7 mm ribs are 5.5 / 4.6 px.
func _ribbon(im: ImmediateMesh, poly: Array[Vector2], w: float, z: float) -> void:
	var h: float = w * 0.5
	for i in range(poly.size() - 1):
		var p0: Vector2 = poly[i]
		var p1: Vector2 = poly[i + 1]
		var d: Vector2 = p1 - p0
		var l: float = d.length()
		if l < 0.000001:
			continue
		var n: Vector2 = Vector2(-d.y, d.x) / l * h
		_tri(im, Vector3(p0.x + n.x, p0.y + n.y, z), Vector3(p1.x + n.x, p1.y + n.y, z),
			Vector3(p1.x - n.x, p1.y - n.y, z))
		_tri(im, Vector3(p0.x + n.x, p0.y + n.y, z), Vector3(p1.x - n.x, p1.y - n.y, z),
			Vector3(p0.x - n.x, p0.y - n.y, z))
	# square joins, so a bowed polyline does not open gaps at its knuckles
	for i in range(1, poly.size() - 1):
		var p: Vector2 = poly[i]
		_quad(im, p.x - h, p.y - h, p.x + h, p.y + h, z)


func _flat_mesh(node_name: String, im: ImmediateMesh, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = im
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	return mi


func _box(node_name: String, size: Vector3, pos: Vector3, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.2
	mat.roughness = 0.85
	mi.material_override = mat
	mi.position = pos
	return mi


# ═════════════════════════════════════════════════════════════════════════════
# GRID CONFIG — guarded: nothing is torn down unless a value this artifact owns
# ACTUALLY changed and _ready has already built once.
# ═════════════════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data == null or config_data.is_empty():
		return
	var changed: bool = false
	if config_data.has("ground"):
		var g: String = String(config_data["ground"]).strip_edges().to_lower()
		if GROUND_VALUES.has(g) and g != ground:
			ground = g
			changed = true
	if config_data.has("opening"):
		var o: String = String(config_data["opening"]).strip_edges().to_lower()
		if OPENING_VALUES.has(o) and o != opening:
			opening = o
			changed = true
	if changed and _built:
		_rebuild()


func _rebuild() -> void:
	if _root != null and is_instance_valid(_root):
		_root.queue_free()
	_root = null
	_build()
