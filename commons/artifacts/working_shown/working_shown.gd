extends Node3D
class_name WorkingShown

## working_shown — `evidence` is a theory of who is looking, and the family's own code
## proves it by refusing to nest.
##
## THE FAMILY. Forty-one artifacts declare an axis called `evidence` in the vocabulary
## result · trace · longhand · axiom (six of them stop at longhand); thirty-two of those are
## promoted members, five are wave-12/13 syntheses (boundary_tank, chapter_arc,
## generator_bench, noise_quarry, selection_garden) and four are unpromoted declarations
## (box_counting_dimension, fibonacci_sequences, koch_curve, sine_wave_controller). It is
## the largest one-vocabulary family in the corpus. Seven members' code was read for this
## file: example_2_8_two_body_attraction_vr, example_2_3_gravity_scaled_by_mass_vr,
## example_1_8_motion_101_velocity_and_constant_acceleration_vr, control_pendulum,
## calder_mobile, branching_vine and box_counting_dimension.
##
## THE ARGUMENT. The brief for this synthesis said `evidence` is "how much of the working
## is shown alongside the answer" — a quantity, and the family's ORDER (result < trace <
## longhand < axiom) says the same. The code says otherwise. In seven members read, only
## calder_mobile builds a ladder (result ⊂ trace ⊂ longhand: sculpture, then gram tags,
## then the plaque). control_pendulum nests to longhand and then DROPS the curve at axiom
## (gd:402-407, a slate with no plot under it). example_2_8 HIDES its answer — the resultant
## arrows — at every rung above result (gd:388-392). example_2_3 hides them at trace and
## axiom and keeps them at longhand. box_counting_dimension's axiom mutes the grid, the
## plot, the tags and the D readout and leaves the gasket alone: the top rung shows LESS
## than the bottom one. branching_vine's axiom throws the vine away and draws one
## application of F -> F[+F][-F]F. So the rungs are not more-and-more of one thing. Each
## is a different WITNESS put in the invisible force's place: the outcome (for the visitor
## — where is it now), the path (for the student — the whole motion at once, the future
## drawn before it happens, as three members put it), the steps and the quantities (for the
## examiner — the working, and NOT the smooth answer-curve), the law (for the sceptic — who
## is shown less of the instance than anyone, and in two members none of it). The
## disagreement available: that the family's order is a real ordering of quantity and the
## non-nesting members are merely lazy — the ladder reading. This artifact takes the
## non-nesting reading and BUILDS it: longhand does not carry the tube, and axiom carries
## no body at all.
##
## THE BODY, NOT A GAUGE. There is no chart and no HUD. One physical event — a thrown ball,
## two bodies in mutual attraction, or a pendulum — is computed in closed form and frozen at
## seven-tenths of its own window, and each rung is that frozen event with a different
## witness beside it: the trace is a real tube in space along the path; the longhand's
## working is rods whose lengths ARE the quantities (velocity at 0.10 m per m/s,
## acceleration at 0.02 m per m/s², a separation rod graduated every 5 cm, rings whose
## AREA is the mass, and the body stamped at equal time-steps — equal time, growing gap);
## the axiom is a minimal built diagram of the law, in rods and pegs. The only numerals in
## the whole artifact are the two masses in the attraction's longhand, because a mass is
## the one quantity in the family that has no length, and they sit on the rings.
##
## THE DESIGNED NULL. The throw rests on Galileo's composition — uniform motion across,
## uniformly accelerated motion down, s = ½ g t² — and the pendulum rests on the period
## law T = 2π √(L / g), which is L = (g / 4π²) T²: length goes as g times time squared in
## both, and the two axiom diagrams are drawn as ONE figure, an L of two rulers, one with
## equal ticks and one with ticks at n². So throw + axiom and swing + axiom are identical
## by construction — two events, one law, and the sceptic's rung is where events stop being
## different. The attraction's axiom is the other law, drawn as the inverse-square flux
## figure: one tile at r, four at 2r, nine at 3r.

## WHICH WITNESS STANDS BESIDE THE FROZEN EVENT. The family's four words in the family's
## order.
##   result    the outcome: the fixture and the body (or bodies) at the frozen moment, and
##             nothing of how they got there. The visitor's rung. Eighteen of the
##             thirty-two promoted members default here.
##   trace     the outcome plus the PATH: the tube the body's centre draws over the whole
##             window, past and future, laid down in space. The student's rung. Nothing is
##             taken away; nothing of the arithmetic is offered.
##   longhand  the outcome plus the WORKING, and not the path: the body stamped at every
##             tenth of the window from release to the frozen moment (the steps of the
##             calculation — equal time, growing gap, example_1_8's own device), and at the
##             frozen body the quantities as rods — velocity, acceleration or force, their
##             components, a graduated separation or rod, rings whose area is mass. The
##             examiner's rung: the smooth curve is withheld and the steps are shown.
##   axiom     the LAW, alone: the fixture and the body are gone and a minimal built diagram
##             of the rule stands where they stood — the L of rulers for the throw and the
##             swing (identical by construction), the flux figure for the attraction. The
##             sceptic's rung, and the one that shows least of the instance, as it does in
##             box_counting_dimension and branching_vine.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result":
	set(v):
		evidence = v
		if is_inside_tree():
			_rebuild()

## WHICH PHYSICAL EVENT IS FROZEN. Every value is closed-form and deterministic; the same
## rung reads the same across all three, which is what makes `evidence` a theory of the
## reader rather than a look.
##   throw       one ball launched at 3.0 m/s and 60° under g = 9.8 from the left end of a
##               rail, landing at its right end 0.795 m away, 0.530 s later; frozen at
##               0.371 s, descending. Constant acceleration in closed form (example_1_8's
##               v += a; p += v with the sum done). Its law is Galileo's composition.
##   attraction  two bodies of mass 1.8 and 1.1 (example_2_8's masses) about their
##               barycentre, on a Kepler ellipse of eccentricity 0.5 released at apoapsis
##               0.70 m apart, G = 1.0, period 1.176 s; frozen at 0.823 s, one fifth of a
##               period past periapsis. Position by Kepler's equation, not by stepping. Its
##               law is the inverse square.
##   swing       a pendulum of control_pendulum's g and proportions — L = 0.55, bob 0.05 —
##               released from 0.5 rad, period 1.489 s in the linear closed form (about
##               1.6% short of the true period at this amplitude); frozen at 1.042 s, near
##               the bottom and rising. Its law is the period law, drawn as the throw's.
@export_enum("throw", "attraction", "swing") var event: String = "throw":
	set(v):
		event = v
		if is_inside_tree():
			_rebuild()

## Whether one rung stands alone or all four stand in a row. NOT PART OF EITHER AXIS — a
## value that shows every rung at once, declared inside the ladder axis, makes the sweep
## union the row's AABB with every single rung and photograph the singles as specks. The
## registry fixture pins `single`.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		layout = v
		if is_inside_tree():
			_rebuild()

## When, as a fraction of the event's own window (flight time, orbital period, pendulum
## period), the event is frozen. Seven-tenths puts the ball on its way down, the pair one
## fifth past periapsis and the bob near the bottom and rising — velocity and force both
## non-zero and non-parallel in every event, which is what the longhand needs.
@export var frozen_at: float = 0.7

const EVIDENCES: PackedStringArray = ["result", "trace", "longhand", "axiom"]
const EVENTS: PackedStringArray = ["throw", "attraction", "swing"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

## One g for the throw and the swing: control_pendulum's 9.8 (gd:69).
const GRAVITY: float = 9.8

## THROW. 3.0 m/s at 60°: range v0² sin 2α / g = 0.795 m, flight 2 v0 sin α / g = 0.530 s,
## apex (v0 sin α)² / 2g = 0.344 m above the release.
const THROW_SPEED: float = 3.0
const THROW_ANGLE: float = PI / 3.0
const THROW_BALL_R: float = 0.035
const RAIL_H: float = 0.012
const RAIL_D: float = 0.06
const RAIL_MARGIN: float = 0.05

## ATTRACTION. example_2_8's masses (gd:155-156) and body radii (gd:190, 0.03 + m · 0.01).
## G is 1.0 rather than its 0.4: the rods are drawn at one scale across all three events on
## purpose, and at 0.4 the accelerations at the frozen moment are 3-6 cm of rod beside the
## throw's 20 cm of g. What is kept from the member is the pair of masses and the shape of
## the law; what is not kept is a toy constant tuned for a 0.8 m tank at 60 Hz.
const ATTR_M1: float = 1.8
const ATTR_M2: float = 1.1
const ATTR_G: float = 1.0
const ATTR_R_APO: float = 0.70
const ATTR_E: float = 0.5
const ORBIT_Y: float = 0.35

## SWING. control_pendulum's g (gd:69) and the ratio of its rod to its bob (0.6 : 0.06,
## gd:67-68), at L = 0.55 so the swing stands no taller than the other two events. Released
## from 0.5 rad rather than its 0.3 (gd:84) so the arc is a third of the frame and not a
## fifth; the linear closed form is used, which at 0.5 rad runs about 1.6% fast.
const SWING_L: float = 0.55
const SWING_THETA0: float = 0.5
const SWING_BOB_R: float = 0.05
const PIVOT_Y: float = 0.63
const PIVOT_BAR: Vector3 = Vector3(0.16, 0.03, 0.06)

## The working's scales — ONE set for all events, so a rod is a length you can compare
## across the axis. 0.10 m per m/s; 0.02 m per m/s²; rings at 0.07 sqrt(m) so area is mass.
const K_V: float = 0.10
const K_A: float = 0.02
const RING_K: float = 0.07
const GHOST_DIV: int = 10
const TICK_EVERY: float = 0.05
const TRACE_R: float = 0.006
const TRACE_SAMPLES: int = 160
const TUBE_SIDES: int = 6
const LADDER_PITCH: float = 1.10

## The axiom figures. The L of rulers: a horizontal rule of AX_W with AX_TICKS equal
## divisions, a vertical rule of AX_H with ticks at n² for n = 0..AX_SQ, sharing a corner
## at top-left. The flux figure: an apex, and n×n grids of FLUX_TILE tiles at n · FLUX_STEP
## from it for n = 1..3.
const AX_W: float = 0.72
const AX_H: float = 0.36
const AX_TICKS: int = 12
const AX_SQ: int = 6
const AX_CORNER: Vector3 = Vector3(-0.36, 0.42, 0.0)
const FLUX_APEX: Vector3 = Vector3(-0.36, 0.35, 0.0)
const FLUX_STEP: float = 0.22
const FLUX_TILE: float = 0.11
const FLUX_GAP: float = 0.008

## The family's own colours. Body pink and the second body's lilac are example_2_8's
## fallback pair (gd:450-451); ink and chalk are its EV_INK / EV_CHALK; sky is example_1_8's
## EV_SKY; the mass ring is example_2_3's MASS_RING.
const BODY_A: Color = Color(0.95, 0.55, 0.85)
const BODY_B: Color = Color(0.75, 0.60, 1.00)
const INK: Color = Color(0.98, 0.74, 0.26)
const SKY: Color = Color(0.35, 0.76, 1.00)
const CHALK: Color = Color(0.93, 0.93, 0.88)
const MASS_RING: Color = Color(0.85, 0.80, 0.55)
const METAL: Color = Color(0.46, 0.47, 0.52)

var _built: Array[Node3D] = []


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("layout"):
		layout = _pick(str(config_data["layout"]), LAYOUTS, layout)
	if config_data.has("evidence"):
		evidence = _pick(str(config_data["evidence"]), EVIDENCES, evidence)
	if config_data.has("event"):
		event = _pick(str(config_data["event"]), EVENTS, event)
	if config_data.has("frozen_at"):
		frozen_at = clampf(float(config_data["frozen_at"]), 0.0, 1.0)
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
	var rungs: Array = []
	if layout == "ladder":
		for r in EVIDENCES:
			rungs.append(r)
	else:
		rungs.append(_pick(evidence, EVIDENCES, "result"))
	var n: int = rungs.size()
	for i in range(n):
		var holder := Node3D.new()
		holder.name = str(rungs[i])
		holder.position = Vector3((float(i) - float(n - 1) * 0.5) * LADDER_PITCH, 0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_rung(holder, str(rungs[i]))


## One rung of one event.
func _build_rung(holder: Node3D, rung: String) -> void:
	var t_star: float = clampf(frozen_at, 0.0, 1.0) * _window()
	if rung == "axiom":
		_add_axiom(holder)
		return
	_add_fixture(holder)
	_add_bodies(holder, t_star, 1.0, "Body")
	if rung == "trace":
		_add_trace(holder)
	elif rung == "longhand":
		_add_ghosts(holder, t_star)
		_add_working(holder, t_star)


# ── the physics, in closed form ─────────────────────────────────────────────────────────

func _ev() -> String:
	return _pick(event, EVENTS, "throw")


## The event's own window: flight time, orbital period, pendulum period.
func _window() -> float:
	match _ev():
		"attraction":
			return TAU * sqrt(pow(_attr_a(), 3.0) / _attr_mu())
		"swing":
			return TAU / _swing_omega()
	return 2.0 * THROW_SPEED * sin(THROW_ANGLE) / GRAVITY


func _body_count() -> int:
	if _ev() == "attraction":
		return 2
	return 1


func _body_radius(i: int) -> float:
	match _ev():
		"attraction":
			return 0.03 + (ATTR_M1 if i == 0 else ATTR_M2) * 0.01
		"swing":
			return SWING_BOB_R
	return THROW_BALL_R


func _body_color(i: int) -> Color:
	if i == 1:
		return BODY_B
	return BODY_A


func _body_mass(i: int) -> float:
	if _ev() == "attraction":
		return ATTR_M1 if i == 0 else ATTR_M2
	return 1.0


# throw
func _throw_range() -> float:
	return THROW_SPEED * THROW_SPEED * sin(2.0 * THROW_ANGLE) / GRAVITY


func _throw_launch() -> Vector3:
	return Vector3(-0.5 * _throw_range(), THROW_BALL_R, 0.0)


func _throw_pos(t: float) -> Vector3:
	var p0: Vector3 = _throw_launch()
	return p0 + Vector3(THROW_SPEED * cos(THROW_ANGLE) * t,
			THROW_SPEED * sin(THROW_ANGLE) * t - 0.5 * GRAVITY * t * t, 0.0)


func _throw_vel(t: float) -> Vector3:
	return Vector3(THROW_SPEED * cos(THROW_ANGLE), THROW_SPEED * sin(THROW_ANGLE) - GRAVITY * t, 0.0)


# attraction
func _attr_a() -> float:
	return ATTR_R_APO / (1.0 + ATTR_E)


func _attr_mu() -> float:
	return ATTR_G * (ATTR_M1 + ATTR_M2)


## Kepler's equation E - e sin E = M by Newton, from apoapsis at t = 0 (M0 = pi).
func _attr_eccentric(t: float) -> float:
	var n: float = TAU / _window()
	var m: float = fmod(PI + n * t, TAU)
	var e_anom: float = m
	for _i in range(30):
		var f: float = e_anom - ATTR_E * sin(e_anom) - m
		var fp: float = 1.0 - ATTR_E * cos(e_anom)
		e_anom -= f / fp
	return e_anom


## Relative vector r2 - r1, periapsis along +x, motion counter-clockwise.
func _attr_rel(t: float) -> Vector3:
	var a: float = _attr_a()
	var ea: float = _attr_eccentric(t)
	var x: float = a * (cos(ea) - ATTR_E)
	var y: float = a * sqrt(1.0 - ATTR_E * ATTR_E) * sin(ea)
	return Vector3(x, y, 0.0)


func _attr_rel_vel(t: float) -> Vector3:
	var a: float = _attr_a()
	var p: float = a * (1.0 - ATTR_E * ATTR_E)
	var rel: Vector3 = _attr_rel(t)
	var nu: float = atan2(rel.y, rel.x)
	var k: float = sqrt(_attr_mu() / p)
	return Vector3(-k * sin(nu), k * (ATTR_E + cos(nu)), 0.0)


func _attr_pos(i: int, t: float) -> Vector3:
	var rel: Vector3 = _attr_rel(t)
	var m_total: float = ATTR_M1 + ATTR_M2
	var cm: Vector3 = Vector3(0.0, ORBIT_Y, 0.0)
	if i == 0:
		return cm - rel * (ATTR_M2 / m_total)
	return cm + rel * (ATTR_M1 / m_total)


func _attr_vel(i: int, t: float) -> Vector3:
	var v: Vector3 = _attr_rel_vel(t)
	var m_total: float = ATTR_M1 + ATTR_M2
	if i == 0:
		return -v * (ATTR_M2 / m_total)
	return v * (ATTR_M1 / m_total)


# swing
func _swing_omega() -> float:
	return sqrt(GRAVITY / SWING_L)


func _swing_theta(t: float) -> float:
	return SWING_THETA0 * cos(_swing_omega() * t)


func _swing_theta_dot(t: float) -> float:
	return -SWING_THETA0 * _swing_omega() * sin(_swing_omega() * t)


func _swing_pivot() -> Vector3:
	return Vector3(0.0, PIVOT_Y, 0.0)


func _swing_pos(t: float) -> Vector3:
	var th: float = _swing_theta(t)
	return _swing_pivot() + Vector3(SWING_L * sin(th), -SWING_L * cos(th), 0.0)


func _swing_vel(t: float) -> Vector3:
	var th: float = _swing_theta(t)
	return Vector3(cos(th), sin(th), 0.0) * (SWING_L * _swing_theta_dot(t))


# dispatch
func _pos(i: int, t: float) -> Vector3:
	match _ev():
		"attraction":
			return _attr_pos(i, t)
		"swing":
			return _swing_pos(t)
	return _throw_pos(t)


func _vel(i: int, t: float) -> Vector3:
	match _ev():
		"attraction":
			return _attr_vel(i, t)
		"swing":
			return _swing_vel(t)
	return _throw_vel(t)


## Acceleration of body i at t: g down for the throw; G m_other / r² toward the other for
## the attraction; the pendulum's is drawn from its components in _add_working.
func _accel(i: int, t: float) -> Vector3:
	if _ev() == "attraction":
		var other: int = 1 - i
		var d: Vector3 = _pos(other, t) - _pos(i, t)
		var r: float = d.length()
		if r < 1e-6:
			return Vector3.ZERO
		return d / r * (ATTR_G * _body_mass(other) / (r * r))
	return Vector3(0.0, -GRAVITY, 0.0)


# ── the fixture and the bodies ──────────────────────────────────────────────────────────

## What the event stands on: the rail whose length is the range, with a release mark; the
## barycentre post; the pivot bar. Present in result, trace and longhand; absent in axiom.
func _add_fixture(holder: Node3D) -> void:
	match _ev():
		"attraction":
			var cm: Vector3 = Vector3(0.0, ORBIT_Y, 0.0)
			holder.add_child(_cylinder(Vector3(0.0, ORBIT_Y * 0.5, 0.0), 0.005, ORBIT_Y, METAL, 0.0,
					"BarycentrePost"))
			holder.add_child(_cylinder(Vector3(0.0, 0.004, 0.0), 0.05, 0.008, METAL, 0.0, "PostBase"))
			holder.add_child(_sphere(cm, 0.012, METAL, 0.0, "Barycentre"))
		"swing":
			var pv: Vector3 = _swing_pivot()
			holder.add_child(_box(pv + Vector3(0.0, PIVOT_BAR.y * 0.5, 0.0), PIVOT_BAR, METAL, 0.0,
					"PivotBar"))
			holder.add_child(_sphere(pv, 0.012, METAL, 0.0, "Pivot"))
		_:
			var r: float = _throw_range()
			var launch: Vector3 = _throw_launch()
			holder.add_child(_box(Vector3(0.0, -RAIL_H * 0.5, 0.0),
					Vector3(r + 2.0 * RAIL_MARGIN, RAIL_H, RAIL_D), METAL, 0.0, "Rail"))
			holder.add_child(_box(Vector3(launch.x, 0.002, 0.0), Vector3(0.02, 0.004, RAIL_D + 0.004),
					INK, 0.3, "ReleaseMark"))


## The bodies at time t. For the swing this includes the rod, which is part of the body.
func _add_bodies(holder: Node3D, t: float, alpha: float, label: String) -> void:
	for i in range(_body_count()):
		var c: Color = _body_color(i)
		c.a = alpha
		var emit: float = 0.15 if alpha >= 0.999 else 0.0
		holder.add_child(_sphere(_pos(i, t), _body_radius(i), c, emit, "%s%d" % [label, i]))
	if _ev() == "swing":
		var rc: Color = METAL
		rc.a = alpha
		holder.add_child(_rod(_swing_pivot(), _swing_pos(t), rc, 0.005, 0.0, label + "Rod"))


# ── trace ───────────────────────────────────────────────────────────────────────────────

## The path the body's centre draws over the whole window, as a tube. The swing's path
## folds back on itself, so it is sampled over the half period that covers the arc once.
func _add_trace(holder: Node3D) -> void:
	var w: float = _window()
	var closed: bool = _ev() == "attraction"
	var span: float = w * 0.5 if _ev() == "swing" else w
	for i in range(_body_count()):
		var pts: PackedVector3Array = PackedVector3Array()
		for k in range(TRACE_SAMPLES + 1):
			var t: float = span * float(k) / float(TRACE_SAMPLES)
			pts.append(_pos(i, t))
		if closed:
			pts[TRACE_SAMPLES] = pts[0]
		var c: Color = _body_color(i).lerp(Color.WHITE, 0.35)
		holder.add_child(_tube(pts, TRACE_R, c, 0.6, "Trace%d" % i))


# ── longhand ────────────────────────────────────────────────────────────────────────────

## The body stamped at every tenth of the window from release up to (not including) the
## frozen moment: the steps of the calculation. A stamp that lands on an earlier stamp —
## the swing's second half-period retreads the first to the byte — is not drawn twice.
func _add_ghosts(holder: Node3D, t_star: float) -> void:
	var w: float = _window()
	var seen: Array[Vector3] = []
	for k in range(GHOST_DIV + 1):
		var t: float = w * float(k) / float(GHOST_DIV)
		if t > t_star - 1e-6:
			break
		var p0: Vector3 = _pos(0, t)
		var dup: bool = false
		for s in seen:
			if s.distance_to(p0) < 0.001:
				dup = true
				break
		if dup:
			continue
		seen.append(p0)
		var g := Node3D.new()
		g.name = "Ghost%d" % k
		holder.add_child(g)
		_add_bodies(g, t, 0.30, "Ghost")


## The quantities, as rods whose lengths are the quantities, at the frozen body.
func _add_working(holder: Node3D, t: float) -> void:
	match _ev():
		"attraction":
			_working_attraction(holder, t)
		"swing":
			_working_swing(holder, t)
		_:
			_working_throw(holder, t)


## THROW: v0 at the release and v at the frozen ball, each with its horizontal and vertical
## component drawn as thinner rods — the horizontal one the same length at both, which is
## the whole of the first law; g as one amber rod down from the ball.
func _working_throw(holder: Node3D, t: float) -> void:
	var launch: Vector3 = _throw_launch()
	var v0: Vector3 = _throw_vel(0.0)
	_add_vector_with_components(holder, launch, v0 * K_V, SKY, "V0")
	var p: Vector3 = _throw_pos(t)
	var v: Vector3 = _throw_vel(t)
	_add_vector_with_components(holder, p, v * K_V, SKY, "V")
	holder.add_child(_arrow(p, p + _accel(0, t) * K_A, 0.006, INK, 1.0, "G"))


## ATTRACTION: the separation rod graduated every 5 cm (example_2_8's longhand), a ring
## on each body whose area is its mass with the mass as a numeral on the ring, the force
## on each body toward the other (equal and opposite, F = G m1 m2 / r²) drawn as
## acceleration at the shared scale, and each body's velocity.
func _working_attraction(holder: Node3D, t: float) -> void:
	var pa: Vector3 = _pos(0, t)
	var pb: Vector3 = _pos(1, t)
	var span: Vector3 = pb - pa
	var r: float = span.length()
	if r < 1e-4:
		return
	var dir: Vector3 = span / r
	holder.add_child(_rod(pa, pb, CHALK, 0.003, 0.6, "Separation"))
	var ticks: int = int(r / TICK_EVERY)
	for i in range(1, ticks + 1):
		var at: Vector3 = pa + dir * (float(i) * TICK_EVERY)
		var long_tick: bool = (i % 2) == 0
		var h: float = 0.05 if long_tick else 0.028
		var tick := _box(at, Vector3(0.004, h, 0.004), CHALK if long_tick else INK, 0.6, "Tick%d" % i)
		# Ticks stand across the rod, in the orbit plane.
		var side: Vector3 = Vector3(-dir.y, dir.x, 0.0)
		tick.basis = Basis(dir, side, Vector3.BACK)
		holder.add_child(tick)
	for i in range(2):
		var p: Vector3 = _pos(i, t)
		var m: float = _body_mass(i)
		var ring_r: float = RING_K * sqrt(m)
		holder.add_child(_ring(p, ring_r, MASS_RING, 0.8, "MassRing%d" % i))
		holder.add_child(_numeral("%.1f" % m, p + Vector3(0.0, -ring_r - 0.018, 0.0), MASS_RING,
				"Mass%d" % i))
		holder.add_child(_arrow(p, p + _accel(i, t) * K_A, 0.006, INK, 1.0, "F%d" % i))
		holder.add_child(_arrow(p, p + _vel(i, t) * K_V, 0.005, SKY, 1.0, "V%d" % i))


## SWING: the rod graduated every 5 cm from the pivot (L made countable), g down from the
## bob with its two components — along the rod, and along the tangent, which is the
## restoring part — and the velocity along the tangent.
func _working_swing(holder: Node3D, t: float) -> void:
	var pv: Vector3 = _swing_pivot()
	var p: Vector3 = _swing_pos(t)
	var th: float = _swing_theta(t)
	var radial: Vector3 = (p - pv) / SWING_L
	var tangent: Vector3 = Vector3(cos(th), sin(th), 0.0)
	var ticks: int = int(SWING_L / TICK_EVERY)
	for i in range(1, ticks + 1):
		var at: Vector3 = pv + radial * (float(i) * TICK_EVERY)
		var long_tick: bool = (i % 2) == 0
		var h: float = 0.05 if long_tick else 0.028
		var tick := _box(at, Vector3(0.004, h, 0.004), CHALK if long_tick else INK, 0.6, "Tick%d" % i)
		tick.basis = Basis(radial, tangent, Vector3.BACK)
		holder.add_child(tick)
	var g_vec: Vector3 = Vector3(0.0, -GRAVITY, 0.0) * K_A
	var along: Vector3 = radial * (GRAVITY * cos(th) * K_A)
	var restoring: Vector3 = tangent * (-GRAVITY * sin(th) * K_A)
	holder.add_child(_arrow(p, p + g_vec, 0.006, INK, 1.0, "G"))
	holder.add_child(_arrow(p, p + along, 0.0035, INK, 0.5, "GAlongRod"))
	holder.add_child(_arrow(p, p + restoring, 0.0035, INK, 0.5, "GRestoring"))
	holder.add_child(_rod(p + along, p + g_vec, INK, 0.002, 0.3, "GParallelogramA"))
	holder.add_child(_rod(p + restoring, p + g_vec, INK, 0.002, 0.3, "GParallelogramB"))
	holder.add_child(_arrow(p, p + _vel(0, t) * K_V, 0.005, SKY, 1.0, "V"))


## A vector as an arrow plus its x and y components as thinner arrows and the two dashed
## sides of the rectangle they close.
func _add_vector_with_components(holder: Node3D, at: Vector3, v: Vector3, c: Color, label: String) -> void:
	holder.add_child(_arrow(at, at + v, 0.006, c, 1.0, label))
	var vx: Vector3 = Vector3(v.x, 0.0, 0.0)
	var vy: Vector3 = Vector3(0.0, v.y, 0.0)
	holder.add_child(_arrow(at, at + vx, 0.0035, c, 0.5, label + "x"))
	holder.add_child(_arrow(at, at + vy, 0.0035, c, 0.5, label + "y"))
	holder.add_child(_rod(at + vx, at + v, c, 0.002, 0.3, label + "RectA"))
	holder.add_child(_rod(at + vy, at + v, c, 0.002, 0.3, label + "RectB"))


# ── axiom ───────────────────────────────────────────────────────────────────────────────

func _add_axiom(holder: Node3D) -> void:
	if _ev() == "attraction":
		_axiom_flux(holder)
	else:
		_axiom_rulers(holder)


## THE L OF RULERS. A horizontal rule with equal ticks and a vertical rule with ticks at n²,
## sharing the top-left corner. For the throw: uniform motion across, s = ½ g t² down —
## Galileo's composition, the parabola with the instance taken out of it (example_1_8 draws
## the n² rule under its plate). For the swing: T across, L = (g / 4π²) T² down —
## control_pendulum's slate's second line. The same figure, on purpose, so that
## throw + axiom and swing + axiom are identical to the byte.
func _axiom_rulers(holder: Node3D) -> void:
	var c0: Vector3 = AX_CORNER
	holder.add_child(_rod(c0, c0 + Vector3(AX_W, 0.0, 0.0), CHALK, 0.004, 0.4, "RuleAcross"))
	holder.add_child(_rod(c0, c0 + Vector3(0.0, -AX_H, 0.0), CHALK, 0.004, 0.4, "RuleDown"))
	holder.add_child(_sphere(c0, 0.012, INK, 0.6, "Corner"))
	for i in range(1, AX_TICKS + 1):
		var x: float = AX_W * float(i) / float(AX_TICKS)
		holder.add_child(_box(c0 + Vector3(x, -0.016, 0.0), Vector3(0.005, 0.032, 0.006), INK, 1.0,
				"TickAcross%d" % i))
	for n in range(1, AX_SQ + 1):
		var y: float = AX_H * float(n * n) / float(AX_SQ * AX_SQ)
		holder.add_child(_box(c0 + Vector3(0.016, -y, 0.0), Vector3(0.032, 0.005, 0.006), INK, 1.0,
				"TickDown%d" % n))


## THE FLUX FIGURE. One apex; one tile at r, four at 2r, nine at 3r, of the same size, in
## planes facing the apex; four rods from the apex to the far grid's corners. What passes
## through one tile at r passes through four at 2r: the inverse square with no curve and no
## text (example_2_8 plots 1/r² on a slate).
func _axiom_flux(holder: Node3D) -> void:
	holder.add_child(_sphere(FLUX_APEX, 0.014, INK, 0.8, "Apex"))
	var pitch: float = FLUX_TILE + FLUX_GAP
	for n in range(1, 4):
		var cx: float = FLUX_APEX.x + FLUX_STEP * float(n)
		for a in range(n):
			for b in range(n):
				var oy: float = (float(a) - float(n - 1) * 0.5) * pitch
				var oz: float = (float(b) - float(n - 1) * 0.5) * pitch
				var shade: Color = CHALK.lerp(INK, 0.15 * float(n - 1))
				holder.add_child(_box(Vector3(cx, FLUX_APEX.y + oy, FLUX_APEX.z + oz),
						Vector3(0.004, FLUX_TILE, FLUX_TILE), shade, 0.2, "Tile%d_%d_%d" % [n, a, b]))
	var far_x: float = FLUX_APEX.x + FLUX_STEP * 3.0
	var half: float = 1.5 * pitch
	for i in range(4):
		var sy: float = -1.0 if i < 2 else 1.0
		var sz: float = -1.0 if (i % 2) == 0 else 1.0
		var corner: Vector3 = Vector3(far_x, FLUX_APEX.y + sy * half, FLUX_APEX.z + sz * half)
		holder.add_child(_rod(FLUX_APEX, corner, CHALK, 0.002, 0.3, "Edge%d" % i))


# ── mesh helpers ────────────────────────────────────────────────────────────────────────

## A round tube along a polyline, six sides, rotation-minimising frames so a flip between
## two rings cannot pinch it; normals outward per vertex; culling off.
func _tube(pts: PackedVector3Array, r: float, c: Color, emit: float, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var count: int = pts.size()
	if count < 2:
		return mi
	var rings: Array = []
	var n1: Vector3 = Vector3.ZERO
	for i in range(count):
		var prev: Vector3 = pts[maxi(i - 1, 0)]
		var next: Vector3 = pts[mini(i + 1, count - 1)]
		var tangent: Vector3 = (next - prev).normalized()
		if tangent.length_squared() < 0.5:
			tangent = Vector3.RIGHT
		if i == 0:
			var seed_axis: Vector3 = Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
			n1 = tangent.cross(seed_axis).normalized()
		else:
			n1 = n1 - tangent * n1.dot(tangent)
			if n1.length_squared() < 1e-8:
				var seed_again: Vector3 = Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
				n1 = tangent.cross(seed_again)
			n1 = n1.normalized()
		var n2: Vector3 = tangent.cross(n1).normalized()
		var ring: Array = []
		for k in range(TUBE_SIDES):
			var a: float = TAU * float(k) / float(TUBE_SIDES)
			var normal: Vector3 = n1 * cos(a) + n2 * sin(a)
			ring.append([pts[i] + normal * r, normal])
		rings.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(count - 1):
		var ra: Array = rings[i]
		var rb: Array = rings[i + 1]
		for k in range(TUBE_SIDES):
			var k2: int = (k + 1) % TUBE_SIDES
			var a0: Array = ra[k]
			var a1: Array = ra[k2]
			var b0: Array = rb[k]
			var b1: Array = rb[k2]
			var order: Array = [a0, b0, a1, a1, b0, b1]
			for j in range(order.size()):
				var v: Array = order[j]
				var vpos: Vector3 = v[0]
				var vnrm: Vector3 = v[1]
				st.set_normal(vnrm)
				st.add_vertex(vpos)
	mi.mesh = st.commit()
	mi.material_override = _mat(c, emit, false)
	return mi


func _box(at: Vector3, size: Vector3, c: Color, emit: float, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = at
	mi.material_override = _mat(c, emit, c.a < 0.999)
	return mi


func _sphere(at: Vector3, r: float, c: Color, emit: float, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 24
	sm.rings = 12
	mi.mesh = sm
	mi.position = at
	mi.material_override = _mat(c, emit, c.a < 0.999)
	return mi


func _cylinder(at: Vector3, r: float, h: float, c: Color, emit: float, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = maxf(h, 0.0001)
	cyl.radial_segments = 12
	cyl.rings = 0
	mi.mesh = cyl
	mi.position = at
	mi.material_override = _mat(c, emit, c.a < 0.999)
	return mi


## A ring lying in the x-y plane (facing the viewer), radius r, wire 7 mm.
func _ring(at: Vector3, r: float, c: Color, emit: float, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var tm := TorusMesh.new()
	tm.outer_radius = r
	tm.inner_radius = maxf(0.004, r - 0.007)
	tm.rings = 32
	tm.ring_segments = 8
	mi.mesh = tm
	mi.position = at
	mi.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	mi.material_override = _mat(c, emit, false)
	return mi


## A rod from a to b: a cylinder whose local Y is aligned to the segment.
func _rod(a: Vector3, b: Vector3, c: Color, r: float, emit: float, label: String) -> MeshInstance3D:
	var mi := _cylinder((a + b) * 0.5, r, a.distance_to(b), c, emit, label)
	_align_y(mi, b - a)
	return mi


## An arrow from a to b: shaft plus a cone head whose tip is at b.
func _arrow(a: Vector3, b: Vector3, r: float, c: Color, emit: float, label: String) -> Node3D:
	var root := Node3D.new()
	root.name = label
	var length: float = a.distance_to(b)
	if length < 1e-4:
		return root
	var dir: Vector3 = (b - a) / length
	var head_len: float = minf(0.03, length * 0.35)
	var shaft_end: Vector3 = b - dir * head_len
	root.add_child(_rod(a, shaft_end, c, r, emit, "Shaft"))
	var head := MeshInstance3D.new()
	head.name = "Head"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = r * 3.0
	cone.height = head_len
	cone.radial_segments = 12
	cone.rings = 0
	head.mesh = cone
	head.position = (shaft_end + b) * 0.5
	head.material_override = _mat(c, emit, false)
	_align_y(head, dir)
	root.add_child(head)
	return root


## Point a node's local +Y along dir, with a right-handed basis.
func _align_y(node: Node3D, dir: Vector3) -> void:
	var y: Vector3 = dir.normalized()
	if y.length_squared() < 0.5:
		return
	var helper: Vector3 = Vector3.BACK if absf(y.dot(Vector3.BACK)) < 0.9 else Vector3.RIGHT
	var x: Vector3 = y.cross(helper).normalized()
	var z: Vector3 = x.cross(y).normalized()
	node.basis = Basis(x, y, z)


## The only text in the artifact: a mass, on its ring, in the longhand of the attraction.
func _numeral(text: String, at: Vector3, c: Color, label: String) -> Label3D:
	var l := Label3D.new()
	l.name = label
	l.text = text
	l.font_size = 40
	l.pixel_size = 0.0008
	l.modulate = c
	l.outline_size = 4
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = at + Vector3(0.0, 0.0, 0.01)
	return l


func _mat(c: Color, emit: float, translucent: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.55
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if translucent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	return m
