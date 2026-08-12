extends Node3D
class_name SlackYard

## Slack Yard — a SYNTHESIS artifact. One span, five drawing conventions, side by side.
##
## @identity
## essence: two masts, one line, and the same span stood up five times — chord,
##   spline, catenary, festoon, truss — so that four conventions can be read
##   against the one that is actually the solution.
## desire: to be walked along until the visitor notices that the lane with no
##   measuring sticks in it is the true one, and that finding it took measuring.
## critical_parameter: `rig` — the hanging problem the five are run on. The five
##   conventions never move and never change their order; only the case does.
## triggers: none. Nothing here animates, nothing is grabbable, nothing is random.
##   One catenary solve per span at build time, read five ways.
## emerges: the five words name three kinds of answer, not five. chord and truss
##   have no lowest point at all — they take the line's extra length up in
##   material. spline has one, and it is a function of nothing. catenary and
##   festoon derive theirs from the length of the line. Which is why the family
##   needed five values and why the word was worth forking.
## needs: one solve per span [has, _solve]; five treatments drawn from that one
##   solve [has]; a datum the departures are measured against [has]; no random
##   number, no _process, no timer anywhere [has]
## relationships: synthesised from the twelve registry names that declare `slack`
##   — three scripts, one const, one vocabulary. See the registry block. It
##   replaces none of them and re-runs none of their axes from the outside.
## truth: a hanging line is one physical situation with five drawings laid over
##   it. Four of the drawings are decisions. Only one of them is the answer, and
##   which of the other four comes closest depends on the rig — the ranking
##   inverts between `level` and `stepped`, so there is no runner-up either.

# ═══════════════════════════════════════════════════════════════════════════
# THE FAMILY WORD, READ AND NOT RETYPED
# ═══════════════════════════════════════════════════════════════════════════
#
# `slack` names the five lanes of this yard. It is REFUSED as this artifact's
# varying axis, on the record and for the reason retention_corridor refused
# `retention`: all twelve members use the word to stand in ONE convention and
# forgo the other four, and on this yard all five are standing at once. That
# simultaneity IS the object. An axis whose every value demolishes four fifths of
# the exhibit is not a variation of it.
#
# So the word is EXHIBITED rather than swept — it names the artifact, it names
# the lanes, it is lettered on a tab at the head of each kerb — and the list is
# PRELOADED out of a member rather than retyped here, so the two cannot drift.
# All three scripts in the family carry the byte-identical const; big_pipe_system
# is the one read, because nine of the twelve registry names resolve to it.
#
# THE FIVE VALUES SIT SIDE BY SIDE, NOT NESTED, and that is why the yard stands
# them all at once instead of varying between them. spline does not contain
# chord; catenary does not contain spline; truss is not a deeper festoon. They
# are five parallel readings of one situation. (The one containment in the family
# is a construction detail rather than a nesting: truss draws the chord path and
# adds structure to it, which is why this yard computes the chord ONCE and lets
# both lanes read it — and why those two lanes then measure identically, which is
# a fact about the conventions and not a bug in the bench.)
const SLACK_SRC := preload("res://algorithms/wavefunctions/big_pipe_system/big_pipe_system.gd")


# ═══════════════════════════════════════════════════════════════════════════
# AXIS 1 — `rig`: the hanging problem the five conventions are run on
# ═══════════════════════════════════════════════════════════════════════════
#
# The same 3.30 m of line in four structurally different rigs. Not four sizes of
# one rig: each is a different classical problem, and each asks the conventions a
# question the others do not. Every figure below was solved in Python before it
# was written down; see dna.note in the registry for the table.
#
#   level    two masts of equal height, 3.00 m apart. The textbook case, and the
#            case every one of the twelve members effectively ships. Slack ratio
#            1.1000, true sag 0.6009 m. All five conventions are defensible here,
#            which is what makes the yard's finding a discovery rather than an
#            announcement.
#   bight    the same line, the masts brought to 1.50 m apart. Slack ratio 2.2000,
#            true sag 1.3605 m. The line's extra length stops being a nuance and
#            becomes the whole shape: the true curve falls 1.3605 m while the
#            drawn batten still draws its 0.45, and the chord is a 1.50 m stub
#            holding 3.30 m of line.
#   stepped  three masts: the rise taken in two steps, so the run is two spans.
#            The batten spans end to end and passes 0.8500 m BELOW the middle mast
#            it is supposed to be anchored to — cable_builder's own argument about
#            drawn curves, given a body. It is also the rig where the RANKING
#            INVERTS: spline is the second-best convention at `level` (mean
#            departure 0.1050 against chord's 0.4057) and the WORST here (0.3346
#            against chord's 0.1673).
#   raked    two masts, one 0.80 m higher. Same total chord as `stepped`, 3.1048 m,
#            and therefore the same slack ratio, 1.0629 — so the difference between
#            those two rigs is where the rise is taken and not how much line there
#            is. This is the rig where the drawn convention is most nearly right in
#            MAGNITUDE (peak departure 0.0558 m) and most wrong in POSITION: the
#            true lowest point sits at u = -0.590, and every drawn convention puts
#            its lowest point at the chord's midpoint, u = 0.
@export_enum("level", "bight", "stepped", "raked") var rig: String = "level"

# ═══════════════════════════════════════════════════════════════════════════
# AXIS 2 — `datum`: how much of the measurement is present
# ═══════════════════════════════════════════════════════════════════════════
#
# A strictly additive ladder — each rung keeps everything the last one drew — so
# this axis NESTS where `rig` sits side by side. Both cases are named in the
# registry because they call for opposite treatment: a nested axis is a sequence
# and must be swept in order, a parallel one is a set.
#
#   none     five runs and the rig. You can see that the conventions differ. You
#            cannot say by how much, and you cannot say which one is right.
#   beside   the true curve is repeated in EVERY lane beside the convention. The
#            answer is now in the frame five times. In the catenary lane it lies
#            inside the run and disappears, which is the correct picture and the
#            first way the yard identifies its own answer.
#   gauged   plus an offset stick at thirteen stations from each run down (or up)
#            to the datum. The departure stops being a haze and becomes a row of
#            sticks you could hold a rule against. The catenary lane grows none,
#            because its departure is below MIN_DEP everywhere — worst case
#            0.0007 m at `bight`, which is the polyline chord error of the datum
#            sampling and nothing else.
#   scored   plus, at the head of each lane, a column whose height IS the mean
#            departure and a collar at the PEAK departure, both 1:1 in metres.
#            This is the rung where the yard stops showing the measurement and
#            starts showing a number, and it exists because the two numbers
#            DISAGREE: on `level`, chord, festoon and truss all peak at exactly
#            0.6009 m, so their collars are level and a worst-case reading says
#            the three are equally wrong; their means are 0.4057, 0.3055 and
#            0.4057, so their columns are not. A scoreboard is a choice of
#            summary, and the yard draws both summaries rather than picking one.
@export_enum("none", "beside", "gauged", "scored") var datum: String = "gauged"


# ═══════════════════════════════════════════════════════════════════════════
# THE LINE
# ═══════════════════════════════════════════════════════════════════════════

const GAP: float = 3.00          ## the level gap between the two masts
const SIGMA: float = 1.10        ## the slack ratio. THE constant of this artifact.
const LINE: float = 3.30         ## SIGMA * GAP. The same line in every rig.

## TYPED ARRAY LITERALS, NOT PackedVector2Array(...). `const X: PackedVector2Array =
## PackedVector2Array([...])` does not parse: the right-hand side is a CONSTRUCTOR CALL
## and GDScript requires a constant expression, so the script failed to load with
## "Assigned value for constant RIG_LEVEL isn't a constant expression" — four times. It
## passed tools/check_dna_declarations.py while broken, because that gate reads the
## @export_enum hints out of the source text and never parses the file; only
## commons/testing/check_compile.gd sees it. An Array[Vector2] literal of constant
## elements IS a constant expression, and _rig_anchors() packs it at the boundary.
##
## The four rigs, as anchor lists in the (u, y) plane, where u runs ALONG the span.
## Every lane hangs between the same anchors; only the across-lane coordinate
## differs. Every mast head is a crosshead spanning all five lanes, and the anchor
## IS the crosshead's centre line, so a run that touches its anchor touches the
## beam it is tied to.
const RIG_LEVEL: Array[Vector2] = [Vector2(-1.50, 1.80), Vector2(1.50, 1.80)]
const RIG_BIGHT: Array[Vector2] = [Vector2(-0.75, 1.80), Vector2(0.75, 1.80)]
const RIG_STEPPED: Array[Vector2] = [Vector2(-1.50, 1.40), Vector2(0.00, 1.80), Vector2(1.50, 1.40)]
const RIG_RAKED: Array[Vector2] = [Vector2(-1.50, 1.40), Vector2(1.50, 2.20)]

## cable_builder._drafted_arc's own depth, imported UNCHANGED and on purpose. Its
## whole argument is that a drawn curve's depth owes nothing to the span, so
## rescaling the constant to this yard would have retracted the claim while
## looking like tidiness. It is 0.45 m here because it is 0.45 m there.
const DRAWN_DEPTH: float = 0.45
const FESTOON_BAYS: int = 4       ## the curve repeated. See _festoon_paths.
const TRUSS_RATIO: float = 12.0   ## girder depth = span / 12, the structural rule of thumb
const STATIONS: int = 13          ## gauge stations across the run
const MIN_DEP: float = 0.004      ## a stick shorter than this is 0.63 px; not drawn

## ── LAYOUT: THE SPAN RUNS ALONG Z AND THE LANES RANK ALONG X ───────────────
##
## This is the one thing in the file chosen against the capture standpoint rather
## than against the object, and it was MEASURED rather than argued. The sweep
## stands at yaw 0.62, so a lane offset projects to screen along
## |right . across| and the span along |right . along|. With the span on X the
## ratio is 0.36 x 0.5810 / (3.00 x 0.8138) = 8.6% — five lanes stacked inside a
## third of one span's screen width — and a Python rasteriser of this exact
## geometry at this exact camera measured how much of each lane then survives
## occlusion by the lanes in front of it: chord 67%, spline 41%, catenary 53%,
## festoon 53%, truss 100%. With the span on Z and the pitch at 0.50 the ratio is
## 0.50 x 0.8138 / (3.00 x 0.5810) = 23.4% and the same measurement reads chord
## 88%, spline 73%, catenary 68%, festoon 71%, truss 100%.
##
## It costs nothing to take: the union AABB is 2.30 x 2.25 x 3.30 either way but
## for 0.20 m of extra apron, so the framing distance moves 0.4% and every mark
## keeps its size. The measured dimension — the vertical departure — is the one
## that does not foreshorten in either layout, so nothing about the measurement
## was traded for the arrangement.
const LANE_PITCH: float = 0.50
const APRON: Vector3 = Vector3(2.30, 0.06, 3.30)   ## x = across lanes, z = along span
const KERB: Vector3 = Vector3(0.07, 0.05, 3.10)
const POST_W: float = 0.09
const HEAD: Vector3 = Vector3(2.22, 0.10, 0.10)    ## the crosshead, spanning all lanes

## Marks, gauged to THIS object at THIS framing (LAW 4). dna.framing 0.55 on the
## union box puts the capture at 7.877 m, a 4.816 m frame and 157.8 px per metre:
##   run     0.064 m across = 10.1 px
##   datum   0.048 m across =  7.6 px   (thinner than the run on purpose: in the
##                                       catenary lane it must vanish INSIDE it,
##                                       and equal radii would z-fight)
##   stick   0.040 m across =  6.3 px
##   web     0.038 m across =  6.0 px
##   post    0.090 m across = 14.2 px
## The score marks are gauged against the BENCH as well as the frame, because the
## critic crops to the subject box and resizes to 160 x 160 before diffing — a
## 581 px crop, so 3.6 screen pixels per sample. A 0.07 m column would be 11 px,
## i.e. 3 samples, which is sorting_hall's three-pixel gauge exactly. Widening it
## ACROSS the lanes instead of along the span buys screen width at 0.8138 per
## metre instead of 0.5810 and costs no span room: 0.07 x 0.5810 + 0.16 x 0.8138
## = 0.171 m = 27.0 px = 7.4 samples. The collar is 40.0 px = 11 samples.
const RUN_R: float = 0.032
const DATUM_R: float = 0.024
const STICK_R: float = 0.020
const WEB_R: float = 0.019
const TUBE_SIDES: int = 8

## The score gauge, at the head of each lane in the 0.105 m of clear apron beyond
## the mast line (mast outer face 1.545, apron edge 1.650).
const BAR_U: float = 0.07
const BAR_L: float = 0.16
const STEM_U: float = 0.03
const STEM_L: float = 0.05
const COLLAR_U: float = 0.10
const COLLAR_L: float = 0.24
const COLLAR_H: float = 0.045
const BAR_STATION: float = 1.595

const C_APRON := Color(0.200, 0.195, 0.190)
const C_KERB := Color(0.300, 0.290, 0.280)
const C_MAST := Color(0.420, 0.440, 0.470)
const C_RUN := Color(0.930, 0.900, 0.840)     ## ALL FIVE LANES SHARE ONE COLOUR
const C_DATUM := Color(0.360, 0.720, 0.850)   ## the true curve, wherever it appears
const C_STICK := Color(0.860, 0.340, 0.110)   ## the measurement
const C_TEXT := Color(0.850, 0.860, 0.880)

var _built: bool = false
var _root: Node3D = null

## ── THE ONE COPY OF THE ARITHMETIC (LAW 3) ─────────────────────────────────
## Filled once per build by _rebuild(). Everything drawn in this file reads these
## and nothing recomputes them. _mean and _peak in particular are computed from
## _dep, which is computed from _lanes and _sol — so the stick a visitor counts
## and the column they read it against cannot disagree.
var _anchors: PackedVector2Array = PackedVector2Array()
var _sol: Array[Vector3] = []                          ## per span: (a, u0, c) of y = a cosh((u-u0)/a) + c
var _arc: PackedFloat32Array = PackedFloat32Array()    ## per span: its share of the line
var _true: PackedVector2Array = PackedVector2Array()   ## the datum, sampled once
var _chord: PackedVector2Array = PackedVector2Array()  ## the chord path, read by chord AND truss
var _lanes: Array = []                                 ## per lane: Array[PackedVector2Array]
var _dep: Array = []                                   ## per lane: Array[Vector3](u, y_run, y_datum)
var _mean: PackedFloat32Array = PackedFloat32Array()   ## per lane: mean |departure|
var _peak: PackedFloat32Array = PackedFloat32Array()   ## per lane: max |departure|


func _ready() -> void:
	_read_grid_config_meta()
	_check_family_list()
	_rebuild()
	_built = true


## LAW 1's validation half. The lane names are READ from the preloaded const, so
## they cannot drift from the family — but the five builders below are literals
## in _strands' if-chain, and a member editing the const would silently leave a
## lane falling through to the chord. This is the only place that can catch it.
func _check_family_list() -> void:
	var known := PackedStringArray(["chord", "spline", "catenary", "festoon", "truss"])
	var fam: PackedStringArray = SLACK_SRC.SLACKS
	for v in fam:
		if not known.has(v):
			push_error("slack_yard: the family declares '%s' and this yard has no lane for it." % v)
	for v in known:
		if not fam.has(v):
			push_error("slack_yard: this yard builds '%s' and the family no longer declares it." % v)


# ═══════════════════════════════════════════════════════════════════════════
# THE CATENARY. Solved once per span; every treatment reads the result.
# ═══════════════════════════════════════════════════════════════════════════

## The curve through both anchors carrying arc length L, as (a, u0, c) in
## y = a*cosh((u-u0)/a) + c.
##
## The arc-length condition is 2a*sinh(h/2a) = sqrt(L^2 - v^2). The left side is
## monotonically DECREASING in a (it tends to h as a grows and to infinity as a
## shrinks), so a bisection with a fixed iteration count is exact enough and, more
## to the point, is DETERMINISTIC: no tolerance, no early exit, no dependence on
## float noise. Two builds of one value are two photographs of one object.
func _solve(p0: Vector2, p1: Vector2, arc: float) -> Vector3:
	var h: float = p1.x - p0.x
	var v: float = p1.y - p0.y
	var s: float = sqrt(maxf(arc * arc - v * v, 0.000000001))
	var lo: float = 0.0001
	var hi: float = 100000.0
	var a: float = 1.0
	for _i in range(96):
		a = 0.5 * (lo + hi)
		if 2.0 * a * sinh(h / (2.0 * a)) - s > 0.0:
			lo = a
		else:
			hi = a
	a = 0.5 * (lo + hi)
	var u0: float = 0.5 * (p0.x + p1.x) - a * _atanh(clampf(v / arc, -0.999999, 0.999999))
	var c: float = p0.y - a * cosh((p0.x - u0) / a)
	return Vector3(a, u0, c)


## Written out rather than called, because Godot's atanh has moved between
## versions and this file must not fail to parse on a headless capture box.
func _atanh(x: float) -> float:
	return 0.5 * log((1.0 + x) / (1.0 - x))


func _cat_y(s: Vector3, u: float) -> float:
	return s.x * cosh((u - s.y) / s.x) + s.z


## if-chains rather than `match` throughout, so the parser cannot argue about
## whether every path returns. The declaration gate reads the @export_enum hints
## above (its first-priority signature) and never has to fall back to reading
## these branches, so nothing is lost by not writing them as match blocks.
func _rig_anchors() -> PackedVector2Array:
	if rig == "bight":
		return PackedVector2Array(RIG_BIGHT)
	if rig == "stepped":
		return PackedVector2Array(RIG_STEPPED)
	if rig == "raked":
		return PackedVector2Array(RIG_RAKED)
	return PackedVector2Array(RIG_LEVEL)


## THE LINE IS DISTRIBUTED BY CHORD, so one slack ratio describes a whole rig no
## matter how many spans it has. `stepped` gets 1.65 m per span over a 1.5524 m
## chord and `raked` gets 3.30 m over 3.1048 m — the same 1.0629 either way, which
## is what makes those two rigs a comparison rather than two different problems.
func _solve_rig() -> void:
	_anchors = _rig_anchors()
	_sol = []
	_arc = PackedFloat32Array()
	var total: float = 0.0
	for i in range(_anchors.size() - 1):
		total += _anchors[i].distance_to(_anchors[i + 1])
	for i in range(_anchors.size() - 1):
		var d: float = _anchors[i].distance_to(_anchors[i + 1])
		_arc.append(LINE * d / total)
		_sol.append(_solve(_anchors[i], _anchors[i + 1], _arc[i]))

	# The datum, sampled ONCE. The catenary lane, the `beside` strands, the gauge
	# sticks and the score columns all read this array; none of them re-evaluates
	# cosh.
	#
	# SAMPLED BY ARC LENGTH, not by u-extent, and the difference is a measurement
	# rather than tidiness. At `bight` the curve carries 3.30 m of line across a
	# 1.50 m gap, so a u-uniform sample lands 24 points on a steeply turning curve
	# and the polyline cuts a corner off it. That residual is what the gauge in the
	# catenary lane would measure — the lane is supposed to draw NO sticks — so it
	# has to stay well under MIN_DEP. Arc-based sampling puts it at 0.0007 m worst
	# case (bight), a sixth of the threshold and 0.11 px at the shipped framing.
	_true = PackedVector2Array()
	for i in range(_sol.size()):
		var p0: Vector2 = _anchors[i]
		var p1: Vector2 = _anchors[i + 1]
		var n: int = maxi(int(64.0 * _arc[i] / GAP), 24)
		for k in range(n + 1):
			if i > 0 and k == 0:
				continue
			var u: float = p0.x + (p1.x - p0.x) * float(k) / float(n)
			_true.append(Vector2(u, _cat_y(_sol[i], u)))

	# The chord, computed ONCE and read by the chord lane and by the truss.
	_chord = PackedVector2Array()
	for p in _anchors:
		_chord.append(p)


# ═══════════════════════════════════════════════════════════════════════════
# THE FIVE TREATMENTS
# ═══════════════════════════════════════════════════════════════════════════

func _strands(convention: String) -> Array:
	if convention == "spline":
		return [_batten_path()]
	if convention == "catenary":
		return [_true]
	if convention == "festoon":
		return _festoon_paths()
	if convention == "truss":
		# INDEX 0 IS THE RUN and everything after it is structure. _lane draws
		# entry 0 at RUN_R and the rest at WEB_R, and _run_y takes the topmost
		# strand, which is this same chord — so the truss's departure is measured
		# on the member that carries the line, not on its web.
		var t: Array = [_chord]
		t.append_array(_truss_paths())
		return t
	return [_chord]


## The draughtsman's batten: end anchor to end anchor, a fixed drawn depth,
## symmetric about the chord's parametric midpoint. Interior anchors are IGNORED
## — cable_builder's own construction and its own argument, that a drawn curve is
## a convention that has stopped agreeing with its own data.
func _batten_path() -> PackedVector2Array:
	var p0: Vector2 = _anchors[0]
	var p1: Vector2 = _anchors[_anchors.size() - 1]
	var out := PackedVector2Array()
	for k in range(41):
		var t: float = float(k) / 40.0
		var p: Vector2 = p0.lerp(p1, t)
		p.y -= DRAWN_DEPTH * 4.0 * t * (1.0 - t)
		out.append(p)
	return out


## THE CURVE REPEATED, which is what the word means. Each span is cut into
## FESTOON_BAYS bays along its chord and each bay hangs its own share of the same
## line — the SAME _solve, called again at a quarter of the span. Because a
## catenary's sag scales linearly with span at a fixed slack ratio, the garland
## hangs EXACTLY 1/FESTOON_BAYS as deep as the single curve: 0.1502 m against
## 0.6009 m at `level`, 0.3401 against 1.3605 at `bight`.
##
## THIS DIVERGES FROM THE FAMILY'S IMPLEMENTATION and the divergence is the
## point. All three members build festoon as their catenary at a larger depth
## factor (1.15/0.45, 0.85/0.35, gravity_sag*1.2) — the same construction at 2.4x
## the amount, which is size wearing a name. The word names a repetition, so this
## yard repeats. The consequence is measurable and is the yard's own finding:
## repeated, festoon has the SAME PEAK departure as the chord (0.6009 at `level`,
## because both meet the datum's low point at a bay boundary) and a mean 25%
## smaller (0.3055 against 0.4057). Scaled, it would simply have been a deeper
## catenary and would have had no independent reading at all.
func _festoon_paths() -> Array:
	var out: Array = []
	for i in range(_anchors.size() - 1):
		var p0: Vector2 = _anchors[i]
		var p1: Vector2 = _anchors[i + 1]
		var bay_arc: float = _arc[i] / float(FESTOON_BAYS)   # read, not recomputed
		var n: int = maxi(int(64.0 * bay_arc / GAP), 10)
		for j in range(FESTOON_BAYS):
			var t0: float = float(j) / float(FESTOON_BAYS)
			var t1: float = float(j + 1) / float(FESTOON_BAYS)
			var b0: Vector2 = p0.lerp(p1, t0)
			var b1: Vector2 = p0.lerp(p1, t1)
			var s: Vector3 = _solve(b0, b1, bay_arc)
			var bay := PackedVector2Array()
			for k in range(n + 1):
				var u: float = b0.x + (b1.x - b0.x) * float(k) / float(n)
				bay.append(Vector2(u, _cat_y(s, u)))
			out.append(bay)
	return out


## The run refuses to hang and SHOWS what stops it. The top chord IS the chord
## lane's path — read, not recomputed — with a bottom chord one twelfth of the
## span below it, seven panel points, and a zigzag web.
func _truss_paths() -> Array:
	var out: Array = []
	for i in range(_anchors.size() - 1):
		var a: Vector2 = _anchors[i]
		var b: Vector2 = _anchors[i + 1]
		var depth: float = a.distance_to(b) / TRUSS_RATIO
		var la: Vector2 = a - Vector2(0.0, depth)
		var lb: Vector2 = b - Vector2(0.0, depth)
		out.append(PackedVector2Array([la, lb]))
		var panels: int = 6
		for k in range(panels + 1):
			var t: float = float(k) / float(panels)
			var top: Vector2 = a.lerp(b, t)
			var bot: Vector2 = la.lerp(lb, t)
			out.append(PackedVector2Array([top, bot]))
			if k < panels:
				var t2: float = float(k + 1) / float(panels)
				var top2: Vector2 = a.lerp(b, t2)
				var bot2: Vector2 = la.lerp(lb, t2)
				if k % 2 == 0:
					out.append(PackedVector2Array([top, bot2]))
				else:
					out.append(PackedVector2Array([bot, top2]))
	return out


# ═══════════════════════════════════════════════════════════════════════════
# THE DEPARTURE. Computed once; `gauged` and `scored` both read it. (LAW 3)
# ═══════════════════════════════════════════════════════════════════════════
#
# NO NORMALISATION ANYWHERE (LAW 5). A stick runs from the point on the run to
# the point on the datum directly below or above it, so the stick IS the
# quantity, 1:1 in metres, with no ceiling and nothing to rescale between frames.
# The score column and its collar are the same metres stood on end, so a column
# in the `bight` frame and a column in the `stepped` frame are directly
# comparable: 0.9800 m of column against 0.1673 m of column, both at 157.8 px
# per metre, both measured from the kerb top.
#
# AND IT COUNTS WHAT IT CLAIMS TO COUNT (LAW 6): the vertical distance from the
# run to the true curve at the station, not a proxy for it. Every treatment here
# is single-valued in u — a catenary is a function of u, and so are a chord, a
# batten, a garland and a top chord — so the vertical is well defined for all
# five and no case silently reports zero.

func _datum_y(u: float) -> float:
	for i in range(_sol.size()):
		if u >= _anchors[i].x - 0.000001 and u <= _anchors[i + 1].x + 0.000001:
			return _cat_y(_sol[i], u)
	return _cat_y(_sol[_sol.size() - 1], u)


## The topmost strand of a treatment at u. `truss` therefore reports its top
## chord, which is the member that carries the line; its web is structure, not run.
func _run_y(strands: Array, u: float) -> float:
	var best: float = -1000000.0
	for s in strands:
		var pl: PackedVector2Array = s
		for i in range(pl.size() - 1):
			var p: Vector2 = pl[i]
			var q: Vector2 = pl[i + 1]
			if absf(q.x - p.x) < 0.000000001:
				continue
			if u >= minf(p.x, q.x) - 0.000001 and u <= maxf(p.x, q.x) + 0.000001:
				best = maxf(best, p.y + (q.y - p.y) * (u - p.x) / (q.x - p.x))
	return best


func _departures(strands: Array) -> Array:
	var out: Array = []
	var u1: float = _anchors[0].x
	var u2: float = _anchors[_anchors.size() - 1].x
	for k in range(STATIONS):
		var u: float = u1 + (u2 - u1) * (float(k) + 0.5) / float(STATIONS)
		var ry: float = _run_y(strands, u)
		if ry < -999999.0:
			continue
		out.append(Vector3(u, ry, _datum_y(u)))
	return out


# ═══════════════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════════════

func _rebuild() -> void:
	if is_instance_valid(_root):
		remove_child(_root)
		_root.queue_free()
	_root = Node3D.new()
	_root.name = "Yard_%s_%s" % [rig, datum]
	add_child(_root)

	_solve_rig()
	var fam: PackedStringArray = SLACK_SRC.SLACKS
	_lanes = []
	_dep = []
	_mean = PackedFloat32Array()
	_peak = PackedFloat32Array()
	for i in range(fam.size()):
		var st: Array = _strands(fam[i])
		_lanes.append(st)
		var dp: Array = _departures(st)
		_dep.append(dp)
		var total: float = 0.0
		var top: float = 0.0
		for d in dp:
			var t: Vector3 = d
			var mag: float = absf(t.y - t.z)
			total += mag
			top = maxf(top, mag)
		_mean.append(total / float(maxi(dp.size(), 1)))
		_peak.append(top)

	_yard()
	for i in range(fam.size()):
		_lane(i, fam[i])


func _lane_x(i: int) -> float:
	var n: int = SLACK_SRC.SLACKS.size()
	return (float(i) - 0.5 * float(n - 1)) * LANE_PITCH


## (along the span, up, across the lanes) -> world. The span runs along Z; see the
## LAYOUT note above the constants for why, and for what it was measured against.
func _w(u: float, y: float, lane: float) -> Vector3:
	return Vector3(lane, y, u)


## Apron, kerbs and masts. The apron is ALWAYS the full 3.30 m — at every value of
## both axes — which is random_cubes' lesson taken directly: without the full
## yard, `bight` would read as a smaller exhibit instead of as the same exhibit
## with its anchors brought in. It is also what holds the capture AABB still.
## Three of the four rigs measure 2.30 x 1.85 x 3.30 and `raked` measures
## 2.30 x 2.25 x 3.30, so the sweep's camera — which fits the union — is identical
## for all sixteen frames and no variant is photographed from further away.
func _yard() -> void:
	var apron: StandardMaterial3D = _matte(C_APRON)
	var kerb: StandardMaterial3D = _matte(C_KERB)
	var mast: StandardMaterial3D = _metal(C_MAST)
	_root.add_child(_box(Vector3(0.0, APRON.y * 0.5, 0.0), APRON, apron))
	var fam: PackedStringArray = SLACK_SRC.SLACKS
	for i in range(fam.size()):
		var x: float = _lane_x(i)
		_root.add_child(_box(Vector3(x, APRON.y + KERB.y * 0.5, 0.0), KERB, kerb))
		# The lane's name, on a small upright tab at the head of its kerb. It
		# carries no measurement and never names an axis value.
		_root.add_child(_text(fam[i], Vector3(x, APRON.y + 0.10, 1.78)))
	for p in _anchors:
		_root.add_child(_box(_w(p.x, p.y * 0.5, 0.0), Vector3(POST_W, p.y, POST_W), mast))
		_root.add_child(_box(_w(p.x, p.y, 0.0), HEAD, mast))


func _lane(i: int, convention: String) -> void:
	var x: float = _lane_x(i)
	var lane := Node3D.new()
	lane.name = "Lane_%s" % convention
	_root.add_child(lane)

	# ORDER MATTERS ONLY FOR READABILITY: datum, then sticks, then the run on top,
	# so the run is never buried by its own measurement.
	if datum != "none":
		var dm := SurfaceTool.new()
		dm.begin(Mesh.PRIMITIVE_TRIANGLES)
		_tube(dm, _true, x, DATUM_R)
		lane.add_child(_commit(dm, _glow(C_DATUM, 0.9), "Datum"))

	if datum == "gauged" or datum == "scored":
		var gs := SurfaceTool.new()
		gs.begin(Mesh.PRIMITIVE_TRIANGLES)
		var drawn: int = 0
		for d in _dep[i]:
			var t: Vector3 = d
			if absf(t.y - t.z) < MIN_DEP:
				continue
			drawn += 1
			_tube(gs, PackedVector2Array([Vector2(t.x, t.y), Vector2(t.x, t.z)]), x, STICK_R)
		if drawn > 0:
			lane.add_child(_commit(gs, _glow(C_STICK, 1.2), "Gauge"))

	if datum == "scored":
		_score(lane, i, x)

	var run := SurfaceTool.new()
	run.begin(Mesh.PRIMITIVE_TRIANGLES)
	var strands: Array = _lanes[i]
	for k in range(strands.size()):
		var r: float = WEB_R if (convention == "truss" and k > 0) else RUN_R
		_tube(run, strands[k], x, r)
	lane.add_child(_commit(run, _matte(C_RUN), "Run"))


## The two summaries of the same thirteen sticks, stood at the head of the lane in
## the clear apron beyond the mast. Both read _mean and _peak, which were computed
## once in _rebuild from _dep — the same array the sticks are drawn from — so the
## gauge and its summary cannot disagree about the departure.
##
## The column is the MEAN and it is orange, the colour of the sticks it sums. The
## collar is the PEAK and it is the datum's blue, because a worst case is a
## statement about one station of the true curve rather than about the run. A stem
## joins them so the pair reads as one gauge and the gap between them is legible:
## that gap is the whole of the rung's argument, and it is widest exactly where
## the two summaries rank the conventions differently.
func _score(lane: Node3D, i: int, x: float) -> void:
	var mean: float = _mean[i]
	var peak: float = _peak[i]
	var base: float = APRON.y + KERB.y
	var col: StandardMaterial3D = _glow(C_STICK, 1.0)
	lane.add_child(_box(_w(BAR_STATION, base + mean * 0.5, x),
		Vector3(BAR_L, maxf(mean, 0.002), BAR_U), col))
	if peak - mean > 0.002:
		lane.add_child(_box(_w(BAR_STATION, base + (mean + peak) * 0.5, x),
			Vector3(STEM_L, peak - mean, STEM_U), col))
	lane.add_child(_box(_w(BAR_STATION, base + peak, x),
		Vector3(COLLAR_L, COLLAR_H, COLLAR_U), _glow(C_DATUM, 0.9)))


## The family's own emitter: a swept circular profile with the up-vector guard
## that interactive_line._emit_run and cable_builder._emit_run both use, taken
## because three artifacts already draw their runs this way and a fourth drawing
## them differently would put the difference in the tube instead of in the axis.
func _tube(st: SurfaceTool, path: PackedVector2Array, x: float, radius: float) -> void:
	var last: int = path.size() - 1
	if last < 1:
		return
	for i in range(last):
		var p1: Vector3 = _w(path[i].x, path[i].y, x)
		var p2: Vector3 = _w(path[i + 1].x, path[i + 1].y, x)
		var delta: Vector3 = p2 - p1
		if delta.length_squared() < 0.0000001:
			continue
		var dir: Vector3 = delta.normalized()
		var up := Vector3.UP
		if absf(dir.dot(up)) > 0.9:
			up = Vector3.RIGHT
		var right: Vector3 = dir.cross(up).normalized()
		var fwd: Vector3 = right.cross(dir).normalized()
		for side in range(TUBE_SIDES):
			var a1: float = (float(side) / float(TUBE_SIDES)) * TAU
			var a2: float = (float(side + 1) / float(TUBE_SIDES)) * TAU
			var o1: Vector3 = (right * cos(a1) + fwd * sin(a1)) * radius
			var o2: Vector3 = (right * cos(a2) + fwd * sin(a2)) * radius
			st.add_vertex(p1 + o1); st.add_vertex(p2 + o1); st.add_vertex(p2 + o2)
			st.add_vertex(p1 + o1); st.add_vertex(p2 + o2); st.add_vertex(p1 + o2)


func _commit(st: SurfaceTool, mat: Material, nm: String) -> MeshInstance3D:
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


# ═══════════════════════════════════════════════════════════════════════════
# GRID PLUMBING
# ═══════════════════════════════════════════════════════════════════════════

## The capture harness stamps config_* metadata before the scene enters the tree.
## Reading it on the way in means the yard is built ONCE, correctly, instead of
## built at the default and then torn down.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_rig"):
			var r: String = _clean(str(node.get_meta("config_rig")))
			if _is_rig(r):
				rig = r
		if node.has_meta("config_datum"):
			var d: String = _clean(str(node.get_meta("config_datum")))
			if _is_datum(d):
				datum = d
		node = node.get_parent()


## Tokens: #rig:bight · #rig:stepped · #rig:raked · #datum:none · #datum:scored
##
## Guarded four ways — a key must be present, its value must be one this code can
## build, it must differ from what is standing, and _ready must have built once.
## The grid reaches this twice for one placement, and an unguarded rebuild would
## tear down and re-raise five lanes on the second call for nothing.
func apply_grid_config(config: Dictionary) -> void:
	var changed: bool = false
	if config.has("rig"):
		var r: String = _clean(str(config["rig"]))
		if _is_rig(r) and r != rig:
			rig = r
			changed = true
	if config.has("datum"):
		var d: String = _clean(str(config["datum"]))
		if _is_datum(d) and d != datum:
			datum = d
			changed = true
	if not changed:
		return
	if not _built:
		return
	_rebuild()


func _is_rig(v: String) -> bool:
	return v == "level" or v == "bight" or v == "stepped" or v == "raked"


func _is_datum(v: String) -> bool:
	return v == "none" or v == "beside" or v == "gauged" or v == "scored"


func _clean(raw: String) -> String:
	return raw.strip_edges().to_lower()


# ═══════════════════════════════════════════════════════════════════════════
# SMALL BUILDERS
# ═══════════════════════════════════════════════════════════════════════════

func _matte(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.86
	m.metallic = 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _metal(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.42
	m.metallic = 0.55
	return m


func _glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.roughness = 0.55
	return m


func _box(p: Vector3, s: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = s
	mi.mesh = bm
	mi.material_override = m
	mi.position = p
	return mi


## Non-billboard, standing at the head of a kerb and facing down the approach.
## Billboard is DISABLED deliberately and not only for stillness: LabelFramer
## treats billboard-enabled as the hanging signal and would bolt a panel and a
## bezel behind every one of these, five slabs this yard did not ask for. Five
## Label3D in the whole artifact and not one of them names an axis value — they
## name the five conventions, which are present at every value of both axes.
##
## Label3D is not a MeshInstance3D, so none of this enters the capture AABB and
## the tab may stand 0.13 m proud of the apron without moving the camera.
func _text(content: String, p: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = content
	l.font_size = 48
	l.pixel_size = 0.0024
	l.outline_size = 0
	l.modulate = C_TEXT
	l.position = p
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return l


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
