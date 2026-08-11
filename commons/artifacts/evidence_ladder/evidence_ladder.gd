extends Node3D
class_name EvidenceLadder

## Evidence Ladder — a SYNTHESIS artifact. One event, told four ways, side by side.
##
## @identity
## essence: The corpus's most-shared axis word given a body. Four identical piers
##   carrying four readings of the same half-second — result, trace, longhand,
##   axiom — so the question forty-five artifacts have each asked alone becomes a
##   comparison you walk past instead of one you hold in your head.
## desire: To make the ladder itself the exhibit, not another rung on it.
## critical_parameter: `phenomenon` — the event under the ladder. The four readings
##   never move and never change their order; only what they are readings OF.
## triggers: Read left to right it looks like increasing disclosure. Stop at the
##   fourth pier and it is not — the event has been taken away again.
## emerges: The body is visible at exactly one station: the one that explains
##   nothing. By the pier that holds the law, there is nothing left to look at.
## needs: one integration [has, _run], four parallel stations [has], a floor line
##   at the same height on every panel [has], no random number anywhere [has]
## relationships: Synthesised from the `evidence` family — see the registry block.
##   Directly out of example_1_7_motion_101_velocity_vr (one _step, no second copy
##   of the arithmetic), bouncing_ball (predict the envelope, never accumulate it;
##   and the baseline every value gets) and dark_side_prism (axiom = the law kept,
##   the picture withheld). It replaces none of them.
## truth: The ladder is not monotone. result → trace → longhand adds working;
##   axiom subtracts the event and keeps the rule. The top of the ladder shows LESS
##   of the thing than the bottom does, and that turn is why the word is hard.

# ═══════════════════════════════════════════════════════════════════════════
# SYNTHESIS DNA — `phenomenon`
# ═══════════════════════════════════════════════════════════════════════════
#
# BORN PROMOTED (2026-08-06). This artifact did not exist before the twenty
# promotion batches that produced its sources; it is the argument those batches
# left lying in registry notes, built as an object.
#
# WHAT IT IS. Four piers on one rail. Each carries a 0.62 m slate panel with the
# same floor line at the same height, and each panel gives a different account of
# ONE event:
#
#   result    the body, at rest on the floor, in the middle of an unmarked panel.
#             No abscissa — a result is a state, not a function, so there is no
#             axis for it to sit on. This is the only station where the body
#             itself appears.
#   trace     the whole flight as a time-coloured ribbon, amber at t = 0 and blue
#             at the end, so the ORDER of what happened is legible and the drawing
#             is not a tangle. The history and nothing else: no numbers, no rule.
#   longhand  the working. The floor line doubles as a time axis and is ticked
#             every 0.1 s; the same flight is dropped as dots at an even cadence,
#             so the widening gaps ARE the acceleration; a second lane under it
#             carries v(t), the straight line whose slope is -g and whose jumps
#             are the impacts; and a third mark, the range x(t), lies flat on the
#             floor for a fall and climbs for a throw.
#   axiom     the rule, standing where the event was. Four lines of update on the
#             slate, and the initial state drawn small — a dot at release height
#             for a fall, a dot with a launch arrow for a throw, a dot with the
#             floor's reply for a bounce, and for a drag the same dot as the fall,
#             because the two are told apart nowhere but in the printed rule. The
#             flight is withheld entirely.
#
# ONE COPY OF THE ARITHMETIC. Every mark on all four panels is read out of a
# single integration, `_run()`, performed once at build time through a single
# `_step()`. This is example_1_7's rule, taken as a design constraint rather than
# quoted: an exhibit that predicts the path with its own copy of the arithmetic is
# an exhibit that will eventually be lying. Here it is stronger than one function —
# it is one RUN. The trace ribbon, the longhand dots, the velocity lane, the range
# line, the resting body and even the length of the time axis all index the same
# arrays. Nothing on this bench can drift out of agreement with anything else on it,
# because there is nothing else for it to agree with.
#
# AND THE DOTS ARE NOT A SECOND, COARSER INTEGRATION. The obvious way to draw
# "Euler steps you can see" is to re-integrate at a visible dt. It is wrong here:
# at dt ~ 0.06 s the body penetrates the floor by a quarter of a metre before the
# reflection fires, the clamp-then-reflect then hands back more speed than it took,
# and the bounce climbs. The picture would be about the integrator. So the dots are
# the SAME fine run read at a cadence you can count — equal in time, unequal in
# space, which is the entire content of the word "accelerated".
#
# `phenomenon` — WHY THIS AND NOT THE FAMILY WORD. See the registry `kin` block:
# `evidence` is refused as an AXIS here on purpose. Every member uses it to pick
# ONE rung and discard the other three; on this object all four rungs are present
# simultaneously and that simultaneity IS the object. An axis whose every value
# demolishes three quarters of the exhibit is not this artifact's variation.
#
# What varies instead is the event under the ladder:
#
#   fall    released from rest at h0. Two lines of law and no horizontal term.
#   throw   launched from the floor with vx = 1.0 and vy chosen so the apex is
#           exactly h0 — the SAME law, the same two lines, a different v0. That is
#           what the axiom pier says out loud, and it is why fall and throw differ
#           least at the top of the ladder and most in the middle of it.
#   bounce  released from rest at h0 onto a floor with e = 0.62. The one value that
#           adds a line to the law. `bounce` and its restitution come from
#           bouncing_ball, whose `regime` list this deliberately does NOT take: e
#           here is a fixed property of one event, not the four named populations
#           that bench compares, and taking a word without its answers is the
#           dishonest half of a shared vocabulary.
#   drag    released from rest at h0 through air. The one value that rewrites the
#           UPDATE rather than the floor or the initial state, and the only one whose
#           y(t) is not a parabola at all.
#
# WHY `drag` WAS ADDED, and why it is the ONLY value that could be. MEASURED first:
# the first sweep of this bench returned 0.595 / 0.596 / 0.725 per cent for its three
# pairs — three numbers so alike that the limit is plainly the TOTAL INK in the two
# piers that can vary, not the similarity of any pair. Pier 1 is identical at every
# value by construction and pier 4 moves a line of text, so at most half the drawing
# can ever move, and it was drawn in hairlines.
#
# The second half of that finding is the constraint on new values. y(t) does not
# depend on vx AT ALL, and both axes on these panels are normalised — height by h0,
# time by the run's own window. So every projectile with apex h0 collapses to ONE
# curve here no matter how hard or flat it is thrown: a second throw would have been
# a duplicate frame wearing a different plate. The shapes actually available to this
# panel are a half parabola (fall), a full one (throw), a decaying train (bounce) and
# whatever a velocity-dependent force draws — which is why the fourth value had to
# reach into the update line, and why there is no fifth.
#
# And `drag` is the value that inverts the bench's own central sentence. The longhand
# pier says the widening gaps between the dots ARE the acceleration. Under drag the
# gaps stop widening and the dots march out evenly along a straight line, which is the
# exact picture example_1_7 drew for CONSTANT velocity. The same panel, the same
# cadence, the opposite reading.
#
# THE VERTICAL SCALE IS SHARED AND THE HORIZONTAL ONE IS NOT, on purpose. All
# four events peak at exactly h0, so height is directly comparable across the
# three stills. Time is not: the fall is over in 0.45 s and the bounce takes four
# times as long. Rather than hide that by relabelling, the axis is ticked at a
# fixed 0.1 s, so the TICK DENSITY carries the difference and no caption is needed.
#
# Fully deterministic. There is not one call to randf, randi or randomize in this
# file, so no seed and no fixture: every build of a given value is the same object
# down to the vertex.
#
# Usage in map_data.json:
#   "evidence_ladder"                     — the fall
#   "evidence_ladder#phenomenon:bounce"
#   "evidence_ladder#phenomenon:drag"

## The event the four readings are readings OF. The ladder is invariant.
@export_enum("fall", "throw", "bounce", "drag") var phenomenon: String = "fall"

## Allow-list. An unknown word in a map token falls back to the shipped fall
## rather than stranding a placement with four blank panels.
const PHENOMENA: PackedStringArray = ["fall", "throw", "bounce", "drag"]

## The four rungs, in the order 29 artifacts declare them. Left to right.
const RUNGS: PackedStringArray = ["result", "trace", "longhand", "axiom"]

# ── the event ────────────────────────────────────────────────────────────
const G: float = 9.8                  ## drawn gravity; the panel is a diagram
const H0: float = 1.0                 ## release height / apex, metres. Shared by all four.
const E_BOUNCE: float = 0.62          ## restitution, `bounce` only
const VX_THROW: float = 1.0           ## the horizontal term `throw` adds
## `drag` only. The terminal speed it settles at, and the drag coefficient DERIVED
## from it rather than typed beside it — at equilibrium g = k v^2, so one number fixes
## both and the plaque cannot print a k the integration is not running.
const V_TERM: float = 1.15
const K_DRAG: float = G / (V_TERM * V_TERM)
const REST_EPS: float = 0.30          ## below this an impact is a buzz, not an arc
const SIM_DT: float = 0.0008          ## the one integration's step
const SIM_MAX_STEPS: int = 4200       ## 3.36 s cap; the bounce settles near 1.8 s
const TAIL: float = 1.06              ## a little room after the body stops

# ── the furniture ────────────────────────────────────────────────────────
const PITCH: float = 0.72             ## station to station
const RAIL_W: float = 2.92
const RAIL_H: float = 0.05
const RAIL_D: float = 0.26
const PIER_W: float = 0.66
const PIER_H: float = 0.86
const PIER_D: float = 0.20
const PANEL_S: float = 0.62           ## panel face, square
const BEZEL_S: float = 0.66
const BEZEL_T: float = 0.024
const FACE_T: float = 0.018
const BEZEL_Z: float = 0.088
const FACE_Z: float = 0.092
const DRAW_Z: float = 0.107           ## the drawing plane, just proud of the slate
const PANEL_Y: float = 1.24           ## panel centre, world
const CORNICE_Y: float = 1.5675

# ── the drawing, panel-local ─────────────────────────────────────────────
const LEFT_X: float = -0.26
const RIGHT_X: float = 0.26
const GROUND_Y: float = -0.05         ## the floor line. Identical on all four panels.
const TOP_Y: float = 0.23             ## h = H0 lands here
const VZERO_Y: float = -0.19          ## the velocity lane's zero
const VAMP: float = 0.115             ## |v| = VMAX lands here
const TICK_LEN: float = 0.020
const TICK_EVERY: float = 0.1         ## seconds per tick. Density carries the timescale.
const N_DOT: int = 18                 ## longhand's cadence
const N_RIB: int = 180                ## trace ribbon samples

# ── STROKE WEIGHTS, and why they are not the ones this bench shipped with ────
# The first sweep drew every mark as a hairline: an 0.018 m ribbon on a 0.62 m slate
# is 3.9 px in the 760 px capture and roughly one pixel through a headset at standing
# distance. It is legible in the source file and nowhere else. So every mark the axis
# can move is drawn at roughly twice the width, which is what a diagram chalked on an
# exhibition slate actually looks like, and the dot cadence drops from 26 to 18 so the
# beads stay separate beads at the new size instead of fusing into a bar. The furniture
# is untouched: nothing was shrunk to make the drawing look bigger.
const W_FLOOR: float = 0.009          ## the floor line, on every panel
const W_TRACE: float = 0.034          ## the trace ribbon
const W_VEL: float = 0.020            ## the velocity lane's ribbon
const W_LANE: float = 0.006           ## the velocity lane's zero line
const W_TICK: float = 0.006           ## time ticks on the floor line
const W_RANGE: float = 0.011          ## x(t), lying on the floor
const W_DOT: float = 0.024            ## longhand's beads
const W_RULE: float = 0.007           ## the axiom pier's ruled square
const W_ARROW: float = 0.010          ## v0 and the floor's reply
const LAW_PX: float = 0.0013          ## the law's pixel_size

# ── palette, taken from example_1_7 so the family reads as one bench ──────
const C_CHALK := Color(0.88, 0.90, 0.95)
const C_INK := Color(0.98, 0.74, 0.26)
const C_LATE := Color(0.35, 0.76, 1.0)
const C_SLATE := Color(0.16, 0.17, 0.20)
const C_BEZEL := Color(0.28, 0.24, 0.20)
const C_STONE := Color(0.31, 0.30, 0.29)
const C_RAIL := Color(0.21, 0.20, 0.19)
const C_RANGE := Color(0.42, 0.86, 0.82)

var _root: Node3D = null
var _built: bool = false

## The one integration. Four parallel lanes, index-aligned, sampled every SIM_DT.
var _t: PackedFloat32Array = PackedFloat32Array()
var _px: PackedFloat32Array = PackedFloat32Array()
var _py: PackedFloat32Array = PackedFloat32Array()
var _vy: PackedFloat32Array = PackedFloat32Array()
var _t_win: float = 1.0
var _vmax: float = 1.0


func _ready() -> void:
	_read_grid_config_meta()
	_rebuild()
	_built = true


# ═══════════════════════════════════════════════════════════════════════════
# THE LAW — one step, and the only place it is written
# ═══════════════════════════════════════════════════════════════════════════

## Semi-implicit Euler with a floor. `e` is the floor's restitution: 0.0 is a
## perfectly inelastic landing (bouncing_ball's `dead` — the first impact keeps
## nothing), anything above it reflects the normal component and keeps the rest.
## `k` is quadratic drag, and it is ZERO for every value but `drag`: at k = 0 the
## acceleration is exactly Vector2(0, -G) and this function reduces, term for term, to
## the two lines it shipped with, so fall, throw and bounce integrate bit-identically
## to their first sweep. Only the new value takes the new branch.
##
## Returns [position, velocity]. This is the single copy of the arithmetic on this
## bench; every mark on all four panels descends from it through _run().
func _step(p: Vector2, v: Vector2, dt: float, e: float, k: float) -> Array[Vector2]:
	var a: Vector2 = Vector2(0.0, -G)
	if k > 0.0:
		# opposes motion and grows with speed — the whole of what `drag` adds
		a -= v * (k * v.length())
	v += a * dt
	p += v * dt

	if p.y <= 0.0:
		p.y = 0.0
		if e <= 0.0 or absf(v.y) < REST_EPS:
			v = Vector2.ZERO
		else:
			v.y = -e * v.y

	var out: Array[Vector2] = [p, v]
	return out


## The event's opening state: [position, velocity, restitution, drag].
##
## All four peak at exactly H0 — the fall, the bounce and the drag because they are
## released there, the throw because its vy is sqrt(2 g H0), which is the same
## speed the fall arrives with, run backwards. So the height scale on the panels
## is shared across every value of the axis and heights are directly comparable.
##
## `drag` and `fall` open at the SAME state, which is the axiom pier's sharpest line:
## the two are told apart nowhere in the initial condition and only in the update. Each
## value of this axis reaches the law in a different place — throw at v0, bounce at the
## floor rule, drag at the update itself — and the pier colours whichever line moved.
func _initial() -> Array:
	var out: Array = [Vector2(0.0, H0), Vector2.ZERO, 0.0, 0.0]
	if phenomenon == "throw":
		out = [Vector2(0.0, 0.0), Vector2(VX_THROW, sqrt(2.0 * G * H0)), 0.0, 0.0]
	elif phenomenon == "bounce":
		out = [Vector2(0.0, H0), Vector2.ZERO, E_BOUNCE, 0.0]
	elif phenomenon == "drag":
		out = [Vector2(0.0, H0), Vector2.ZERO, 0.0, K_DRAG]
	return out


## Integrate once, forward, at build time, and keep the whole thing. Everything the
## four panels draw is a read of these arrays — there is no second integration on
## this artifact and no per-frame code at all.
func _run() -> void:
	_t.clear()
	_px.clear()
	_py.clear()
	_vy.clear()

	var init: Array = _initial()
	var p: Vector2 = init[0]
	var v: Vector2 = init[1]
	var e: float = init[2]
	var k: float = init[3]

	_vmax = maxf(sqrt(2.0 * G * H0), 0.001)

	var t: float = 0.0
	var rest_at: float = -1.0
	var i: int = 0
	while i < SIM_MAX_STEPS:
		_t.append(t)
		_px.append(p.x)
		_py.append(p.y)
		_vy.append(v.y)

		if rest_at < 0.0 and p.y <= 0.0 and v.length() < 0.0001 and i > 0:
			rest_at = t
		if rest_at >= 0.0 and t > rest_at * TAIL:
			break

		var stepped: Array[Vector2] = _step(p, v, SIM_DT, e, k)
		p = stepped[0]
		v = stepped[1]
		t += SIM_DT
		i += 1

	_t_win = maxf(_t[_t.size() - 1], 0.05)


## The sample index nearest a time. The panels ask this; they never re-integrate.
func _idx(at: float) -> int:
	return clampi(int(round(at / SIM_DT)), 0, _t.size() - 1)


# ── panel-space mapping ──────────────────────────────────────────────────

func _map_t(at: float) -> float:
	return lerpf(LEFT_X, RIGHT_X, clampf(at / _t_win, 0.0, 1.0))


func _map_h(h: float) -> float:
	return GROUND_Y + (h / H0) * (TOP_Y - GROUND_Y)


func _map_v(v: float) -> float:
	return VZERO_Y + clampf(v / _vmax, -1.0, 1.0) * VAMP


# ═══════════════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════════════

func _rebuild() -> void:
	if is_instance_valid(_root):
		remove_child(_root)
		_root.queue_free()
	_root = Node3D.new()
	_root.name = "Ladder_%s" % phenomenon
	add_child(_root)

	_run()
	_furniture(_root)

	var n: int = RUNGS.size()
	for i in range(n):
		var station := Node3D.new()
		station.name = "Station_%s" % RUNGS[i]
		station.position = Vector3((float(i) - 0.5 * float(n - 1)) * PITCH, 0.0, 0.0)
		_root.add_child(station)
		_station(station, RUNGS[i])


## The rail, the four piers, the panels and the cornice. Identical at every value of
## the axis and identical between stations — so the READING is the only thing that
## varies, both across the row and across the sweep.
func _furniture(root: Node3D) -> void:
	var stone: StandardMaterial3D = _mat(C_STONE, 0.0)
	stone.roughness = 0.9
	var rail_mat: StandardMaterial3D = _mat(C_RAIL, 0.0)
	rail_mat.roughness = 0.85
	var bezel: StandardMaterial3D = _mat(C_BEZEL, 0.0)
	var slate: StandardMaterial3D = _mat(C_SLATE, 0.0)
	slate.roughness = 0.75

	root.add_child(_box(Vector3(0.0, RAIL_H * 0.5, 0.0), Vector3(RAIL_W, RAIL_H, RAIL_D), rail_mat))
	root.add_child(_box(Vector3(0.0, CORNICE_Y, 0.0), Vector3(RAIL_W, 0.035, 0.22), rail_mat))

	var n: int = RUNGS.size()
	for i in range(n):
		var x: float = (float(i) - 0.5 * float(n - 1)) * PITCH
		root.add_child(_box(Vector3(x, RAIL_H + PIER_H * 0.5, 0.0),
			Vector3(PIER_W, PIER_H, PIER_D), stone))
		root.add_child(_box(Vector3(x, PANEL_Y, BEZEL_Z),
			Vector3(BEZEL_S, BEZEL_S, BEZEL_T), bezel))
		root.add_child(_box(Vector3(x, PANEL_Y, FACE_Z),
			Vector3(PANEL_S, PANEL_S, FACE_T), slate))

	# THE HEADER DOES NOT NAME THE EVENT, deliberately. A caption carrying the axis
	# value would put text-shaped pixels into the bite report and let a measurement
	# of the physics be padded by a measurement of the label. Every pixel that moves
	# between fall, throw and bounce on this bench is a mark the integration made.
	root.add_child(_text("one event  ·  four readings",
		Vector3(0.0, CORNICE_Y + 0.062, 0.115), 44, 0.0018, C_CHALK))


## One station. Everything is drawn in the panel's local frame, on the plane
## DRAW_Z, with the floor line at GROUND_Y — the same height on all four.
func _station(station: Node3D, rung: String) -> void:
	var panel := Node3D.new()
	panel.position = Vector3(0.0, PANEL_Y, 0.0)
	station.add_child(panel)

	# The floor. EVERY rung gets it, including the one that withholds the event —
	# bouncing_ball's rule, and its reason: without a zero line an envelope is a
	# shape, and with one it is a measurement.
	_seg(panel, Vector2(LEFT_X, GROUND_Y), Vector2(RIGHT_X, GROUND_Y), W_FLOOR,
		_mat(C_CHALK, 0.25), DRAW_Z)

	match rung:
		"result":
			_draw_result(panel)
		"trace":
			_draw_trace(panel)
		"longhand":
			_draw_longhand(panel)
		"axiom":
			_draw_axiom(panel)

	# The nameplate, engraved on the pier rather than hung in the air. Non-billboard,
	# so LabelFramer treats it as text already lying on a body and leaves it alone.
	station.add_child(_text(rung, Vector3(0.0, 0.80, PIER_D * 0.5 + 0.006), 52, 0.0018, C_CHALK))


## RESULT — the body, at rest, in the middle of an unmarked panel.
##
## No abscissa. Not an omission: a result is a state, not a function, so there is
## no axis for it to sit on, and once time is gone there is no "where along it"
## either. The consequence is the sharpest sentence on this bench — a fall and a
## bounce produce the SAME picture here, and only the throw is displaced at all in
## the world it came from. bouncing_ball found this by accident and reported it
## honestly: at evidence=result its restitution "has no geometry". This station is
## that finding, on purpose.
##
## It is also the only station where the body itself appears. By the pier that
## holds the law there is nothing left to look at.
func _draw_result(panel: Node3D) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.030
	sm.height = 0.060
	mi.mesh = sm
	mi.material_override = _mat(C_INK, 0.9)
	mi.position = Vector3(0.0, GROUND_Y + 0.030, DRAW_Z + 0.030)
	panel.add_child(mi)


## TRACE — the whole flight, drawn as one time-coloured ribbon.
##
## Amber at t = 0, blue at the end, which is example_1_7's device and is here for
## its reason and not its look: without it a bounce is a tangle of arcs with no
## order in it. Read off the one integration, so the ribbon is not a prediction the
## exhibit made about itself — it is the run.
func _draw_trace(panel: Node3D) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(N_RIB):
		var at: float = _t_win * float(i) / float(N_RIB - 1)
		var k: int = _idx(at)
		pts.append(Vector2(_map_t(_t[k]), _map_h(_py[k])))
	_ribbon(panel, pts, W_TRACE, C_INK, C_LATE, DRAW_Z)


## LONGHAND — the working instead of the answer.
##
## Three marks, all read out of the same run:
##   the floor line ticked every 0.1 s, so the abscissa is time and its DENSITY
##     says how long the event took without a caption saying so;
##   the flight dropped as dots at an even cadence — equal in time, unequal in
##     space. example_1_7 drew forty dots the SAME distance apart and said that is
##     what constant velocity looks like when you stop saying it. These widen, and
##     that is what accelerated looks like. The same picture, one derivative along —
##     and under `drag` they STOP widening and march out evenly along a near-straight
##     line, which is example_1_7's constant-velocity picture arriving on the panel
##     built to say the opposite. It is the one reading on this bench that turns round;
##   a lower lane carrying v(t): a straight line of slope -g, whose jumps are the
##     impacts and whose crossing of zero is the apex — except under `drag`, where it
##     bends over to a shallow horizontal at the terminal speed and stays there, which
##     is what "the force depends on the velocity" looks like with nobody saying so.
##
## And the range, x(t), on the floor. It is the only place on this bench where the
## horizontal term appears at all: a height-against-time strip cannot show it, so a
## throw read at `trace` is indistinguishable from a tall fall. The working is where
## the exhibit admits what the picture above it dropped. Flat on the floor for a
## fall, a bounce and a drag, climbing for a throw — same frame, different content, which is
## the family's own way of drawing a difference.
func _draw_longhand(panel: Node3D) -> void:
	var tick_mat: StandardMaterial3D = _mat(C_CHALK, 0.2)
	var n_tick: int = int(floor(_t_win / TICK_EVERY))
	for i in range(n_tick + 1):
		var at: float = float(i) * TICK_EVERY
		if at > _t_win:
			break
		var x: float = _map_t(at)
		_seg(panel, Vector2(x, GROUND_Y), Vector2(x, GROUND_Y - TICK_LEN), W_TICK,
			tick_mat, DRAW_Z)

	# the range. Straight, because nothing accelerates it.
	var last: int = _t.size() - 1
	_seg(panel, Vector2(LEFT_X, _map_h(_px[0])), Vector2(RIGHT_X, _map_h(_px[last])),
		W_RANGE, _mat(C_RANGE, 0.7), DRAW_Z + 0.002)

	# the flight at a cadence you can count
	var dot_mat: StandardMaterial3D = _mat(C_INK, 1.0)
	var dot_mesh := BoxMesh.new()
	dot_mesh.size = Vector3(W_DOT, W_DOT, 0.010)
	for i in range(N_DOT):
		var at2: float = _t_win * float(i) / float(N_DOT - 1)
		var k: int = _idx(at2)
		var mi := MeshInstance3D.new()
		mi.mesh = dot_mesh
		mi.material_override = dot_mat
		mi.position = Vector3(_map_t(_t[k]), _map_h(_py[k]), DRAW_Z + 0.004)
		panel.add_child(mi)

	# the velocity lane
	_seg(panel, Vector2(LEFT_X, VZERO_Y), Vector2(RIGHT_X, VZERO_Y), W_LANE,
		_mat(C_CHALK, 0.18), DRAW_Z)
	var vpts: PackedVector2Array = PackedVector2Array()
	for i in range(N_RIB):
		var at3: float = _t_win * float(i) / float(N_RIB - 1)
		var k2: int = _idx(at3)
		vpts.append(Vector2(_map_t(_t[k2]), _map_v(_vy[k2])))
	_ribbon(panel, vpts, W_VEL, C_LATE, C_LATE, DRAW_Z)

	panel.add_child(_text("y(t)", Vector3(RIGHT_X - 0.045, TOP_Y - 0.012, DRAW_Z), 24, 0.0012, C_INK))
	panel.add_child(_text("v(t)", Vector3(RIGHT_X - 0.045, VZERO_Y + 0.062, DRAW_Z), 24, 0.0012, C_LATE))


## AXIOM — the rule, standing where the event was.
##
## dark_side_prism's move, and its exact words: the rainbow withheld, the law kept.
## Nothing of the flight is drawn here — no ribbon, no dots, no body. What is left is
## four lines of update and the initial state, small, on the same floor the other
## three panels use.
##
## The initial state is the whole difference between a fall and a throw at this rung,
## and the reason those two values differ LEAST here and most in the middle of the
## ladder: they run identical arithmetic, and the exhibit says so by printing
## identical arithmetic under two different v0.
##
## All four print four lines, and the ink is not hard-coded — _lines_the_axis_reaches()
## writes out all four laws and colours whichever lines disagree. Today that is three of
## them, and each value reaches a DIFFERENT one: `throw` the initial condition, `bounce`
## the floor's rule, `drag` the update itself. Only "p += v dt" is chalk, because nothing
## the axis can name touches the carry. So the pier's second reading is that an event can
## be varied in three separate places in one law, and you can see which place without
## reading a word of it. `drag` and `fall` share the ruled square exactly — same release,
## same rest, no arrow — and differ only in the coloured text, which is the strongest
## thing this pier says: at the top of the ladder two different flights can be told apart
## nowhere except in the rule.
func _draw_axiom(panel: Node3D) -> void:
	var lines: PackedStringArray = _law()
	var reach: PackedInt32Array = _lines_the_axis_reaches()
	for i in range(lines.size()):
		var y: float = 0.19 - float(i) * 0.055
		panel.add_child(_text(lines[i], Vector3(0.0, y, DRAW_Z), 30, LAW_PX,
			C_INK if reach.has(i) else C_CHALK))

	# THE INITIAL STATE, in its own frame, on its own floor. It gets a frame rather
	# than the panel's shared floor line for a plain reason: a fall starts at h0,
	# which on the shared scale is TOP_Y, and TOP_Y is where the first line of the
	# law is printed. example_1_7 hit the same problem and answered it the same way —
	# a small ruled square on the plate, holding the support of the thing that varies.
	var rule: StandardMaterial3D = _mat(C_CHALK, 0.35)
	var cx: float = 0.0
	var cy: float = -0.155
	var h: float = 0.115
	_seg(panel, Vector2(cx - h, cy + h), Vector2(cx + h, cy + h), W_RULE, rule, DRAW_Z)
	_seg(panel, Vector2(cx - h, cy - h), Vector2(cx + h, cy - h), W_RULE * 1.55, rule, DRAW_Z)
	_seg(panel, Vector2(cx - h, cy - h), Vector2(cx - h, cy + h), W_RULE, rule, DRAW_Z)
	_seg(panel, Vector2(cx + h, cy - h), Vector2(cx + h, cy + h), W_RULE, rule, DRAW_Z)

	var init: Array = _initial()
	var p0: Vector2 = init[0]
	var v0: Vector2 = init[1]
	var e: float = init[2]
	var floor_y: float = cy - h
	var body_y: float = floor_y + (p0.y / H0) * (h * 1.88)
	var at: Vector2 = Vector2(cx - 0.045, body_y)

	panel.add_child(_box(Vector3(at.x, at.y, DRAW_Z + 0.004), Vector3(0.026, 0.026, 0.012),
		_mat(C_INK, 1.1)))

	var impact: float = maxf(sqrt(2.0 * G * H0), 0.001)
	var scale_v: float = 0.11 / maxf(Vector2(VX_THROW, impact).length(), 0.001)
	if v0.length() > 0.001:
		_arrow(panel, at, at + v0 * scale_v, W_ARROW, _mat(C_INK, 1.0))

	if e > 0.0:
		# what the floor gives back: e times the speed it took from the body
		var foot: Vector2 = Vector2(cx + 0.045, floor_y)
		_arrow(panel, foot, foot + Vector2(0.0, impact * e * scale_v), W_ARROW,
			_mat(C_LATE, 1.0))


## The law, as the axiom pier prints it: the update, the carry, the floor's rule and
## the initial condition, in that order.
func _law() -> PackedStringArray:
	return _law_for(phenomenon)


## The same four lines for ANY value, so the pier can be asked which of them the axis
## is able to move rather than told. `fall` is the plainest event and prints the
## plainest law; each other value rewrites exactly one line of it, and a different one:
## throw the initial condition, bounce the floor's rule, drag the update itself.
func _law_for(which: String) -> PackedStringArray:
	var update: String = "v.y -= g dt"
	var floor_rule: String = "floor: v = 0"
	var v0_line: String = "v0 = (0, 0)"
	if which == "throw":
		v0_line = "v0 = (1.00, 4.43)"
	elif which == "bounce":
		floor_rule = "floor: v.y = -e v.y"
		v0_line = "v0 = (0,0)  e = 0.62"
	elif which == "drag":
		update = "v.y -= (g + k|v|v.y) dt"
		v0_line = "v0 = (0,0)  k = %.2f" % K_DRAG
	return PackedStringArray([update, "p += v dt", floor_rule, v0_line])


## WHICH LINES ARE INK — asked of the four laws rather than asserted about them.
## The pier's rule is that chalk is what the axis cannot touch and ink is what it can,
## and the honest way to know that is to write all four laws out and see which lines
## disagree. It also cannot rot: a fifth value would recolour the pier by itself.
func _lines_the_axis_reaches() -> PackedInt32Array:
	var base: PackedStringArray = _law_for(PHENOMENA[0])
	var out: PackedInt32Array = PackedInt32Array()
	for i in range(base.size()):
		for w in PHENOMENA:
			if _law_for(w)[i] != base[i]:
				out.append(i)
				break
	return out


# ═══════════════════════════════════════════════════════════════════════════
# CONFIG
# ═══════════════════════════════════════════════════════════════════════════

## Grid config arrives twice and by two routes: GridInteractablesComponent sets
## config_<key> metadata on the instantiated root and then calls apply_grid_config,
## and the capture harness calls apply_grid_config before the scene enters the tree.
## Reading the metadata on the way in means the bench is built once, correctly,
## instead of built as `fall` and then torn down.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_phenomenon"):
			var want: String = _clean(str(node.get_meta("config_phenomenon")))
			if PHENOMENA.has(want):
				phenomenon = want
		node = node.get_parent()


## Tokens: #phenomenon:throw · #phenomenon:bounce · #phenomenon:drag
##
## GUARDED THREE WAYS — the key must be present, the value must be one the code can
## build, and it must differ from the one already standing. A placement carrying any
## other token reaches here with no `phenomenon` key at all, and the grid reaches
## this twice for one placement; an unguarded rebuild would tear down and re-raise
## four stations on both of those, for nothing.
func apply_grid_config(config: Dictionary) -> void:
	if not config.has("phenomenon"):
		return
	var want: String = _clean(str(config["phenomenon"]))
	if not PHENOMENA.has(want):
		return
	if want == phenomenon:
		return
	phenomenon = want
	if not _built:
		return          # _ready has not built yet and will build this value itself
	_rebuild()


func _clean(raw: String) -> String:
	return raw.strip_edges().to_lower()


# ═══════════════════════════════════════════════════════════════════════════
# BUILDERS
# ═══════════════════════════════════════════════════════════════════════════

func _mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m


func _box(p: Vector3, s: Vector3, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = s
	mi.mesh = bm
	mi.material_override = m
	mi.position = p
	return mi


## A segment in the panel plane. Rotated about Z rather than aimed with looking_at,
## because everything on these panels is planar and an axis-angle basis cannot pick
## a degenerate up vector.
func _seg(root: Node3D, a: Vector2, b: Vector2, thick: float, m: StandardMaterial3D,
		z: float) -> void:
	var d: Vector2 = b - a
	var l: float = d.length()
	if l < 0.0005:
		return
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(l, thick, thick)
	mi.mesh = bm
	mi.material_override = m
	var mid: Vector2 = (a + b) * 0.5
	mi.transform = Transform3D(Basis(Vector3(0.0, 0.0, 1.0), atan2(d.y, d.x)),
		Vector3(mid.x, mid.y, z))
	root.add_child(mi)


func _arrow(root: Node3D, a: Vector2, b: Vector2, thick: float,
		m: StandardMaterial3D) -> void:
	var d: Vector2 = b - a
	if d.length() < 0.002:
		return
	_seg(root, a, b, thick, m, DRAW_Z + 0.002)
	var head: float = minf(d.length() * 0.36, 0.024)
	var dir: Vector2 = d.normalized()
	_seg(root, b, b - dir.rotated(0.42) * head, thick, m, DRAW_Z + 0.002)
	_seg(root, b, b - dir.rotated(-0.42) * head, thick, m, DRAW_Z + 0.002)


## A flat vertex-coloured strip of constant width along a planar path. One mesh and
## one material for the whole curve — a line strip would come back a hairline in a
## 760 px still, which is the documented way an axis reads as inert when it is not.
func _ribbon(root: Node3D, pts: PackedVector2Array, w: float, c0: Color, c1: Color,
		z: float) -> void:
	var n: int = pts.size()
	if n < 2:
		return
	var im := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var emitted: int = 0
	for i in range(n - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var d: Vector2 = b - a
		if d.length() < 0.00001:
			continue
		emitted += 1
		var off: Vector2 = Vector2(-d.y, d.x).normalized() * (w * 0.5)
		var ca: Color = c0.lerp(c1, float(i) / float(n - 1))
		var cb: Color = c0.lerp(c1, float(i + 1) / float(n - 1))
		var a1 := Vector3(a.x + off.x, a.y + off.y, z)
		var a2 := Vector3(a.x - off.x, a.y - off.y, z)
		var b1 := Vector3(b.x + off.x, b.y + off.y, z)
		var b2 := Vector3(b.x - off.x, b.y - off.y, z)
		im.surface_set_color(ca)
		im.surface_add_vertex(a1)
		im.surface_set_color(ca)
		im.surface_add_vertex(a2)
		im.surface_set_color(cb)
		im.surface_add_vertex(b2)
		im.surface_set_color(ca)
		im.surface_add_vertex(a1)
		im.surface_set_color(cb)
		im.surface_add_vertex(b2)
		im.surface_set_color(cb)
		im.surface_add_vertex(b1)
	if emitted == 0:
		# surface_end() on an empty surface is a hard error in Godot 4, and an
		# artifact that errors on build is a finding about the harness, not the axis.
		im.surface_add_vertex(Vector3(0.0, 0.0, z))
		im.surface_add_vertex(Vector3(0.0, 0.0, z))
		im.surface_add_vertex(Vector3(0.0, 0.0, z))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.material_override = mat
	root.add_child(mi)


## Non-billboard on purpose. LabelFramer frames HANGING labels and leaves text that
## already lies on a body alone — these lie on slate and on stone, so they keep
## their place and add no plate to the capture AABB. The outline is zeroed for the
## same reason it is zeroed there: against an opaque dark panel it only fattens the
## glyphs it was drawn to rescue.
func _text(content: String, p: Vector3, size: int, px: float, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = content
	l.font_size = size
	l.pixel_size = px
	l.outline_size = 0
	l.modulate = c
	l.position = p
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return l


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
