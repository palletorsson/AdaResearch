extends RefCounted
## THE UNIT - the model (Palle, 2026-11-03: "every unit has only three controllable actions: move forward or
## backward, turn its mobile chassis, rotate an independent central hub carrying interchangeable attachments ... the
## first convincing prototype should show two identical units becoming a third thing: a drawing mechanism made by
## their relationship"; "a complicated movement programmed in advance is not necessarily emergent - test simple local
## rules whose interactions produce collective behaviour that has not been choreographed in detail").
##
## A UNIT is a differential-drive chassis on the floor plane (x, z) - it rolls along its heading and cannot slide
## sideways unless pushed past its wheels' grip - with a hub mounted `a_hub` ahead of the axle. Its state is
## (x, z, th, ph): position, heading, and the hub's angle relative to the chassis. Its ONLY three actions are rates:
## v (drive, m/s), w (chassis turn, rad/s), h (hub turn, rad/s). The hub carries a pin on its rim (`r_pin`): a pen sits
## there, or the end of a rod.
##
## WHAT LEVEL THIS IS (Palle, 2026-11-03, on the first studies): keep three things apart - (1) KINEMATIC COMPOSITION,
## motions combined geometrically; (2) MECHANICAL INTERACTION, forces and constraints changing the motion; (3)
## COLLECTIVE ADAPTATION, local rules and feedback giving new behaviour - "do not label a pattern emergent without
## explaining the local rules and the causal evidence". This model is LEVEL 2. A unit that gives way in proportion to
## the force at its pin is what a back-drivable motor does with no decision in it, so the shared rates and the relation
## below are mechanical self-organisation - two clocks on one beam - not adaptive collective behaviour. Level 1 is the
## unjoined control (`apart`): the two programmes, and nothing between them. Level 3 - units that change their own
## programme from what they sense, with memory (ease tension, hold a distance, shift a phase) - is not built yet.
##
## THE ROD is physics, not a controller: a rigid pin-to-pin bar of length L, modelled as a stiff spring (k), pulling
## the two pins together when stretched and apart when squeezed - equal and opposite (Newton's third law).
##
## THE RULE (`rule`) is the same function with the same numbers in every unit. It reads ONLY local things: the unit's
## own hub angle and the force its own pin feels, in its own frame. Each unit runs its own drive (v0, w0, h0 - a
## circle with the hub spinning) and GIVES WAY to the rod: forward speed yields to the pull along its heading, the
## chassis turn to the torque about the axle, the hub to the torque about the hub. No unit reads another unit's
## state; there is no central controller and no precomputed path.
##
## What came of it (Python study 2026-11-03, scratchpad unit_sims/compliance, setting S4 = this file's defaults):
## one unit draws a closed four-loop rosette; two unjoined units draw two copies of it; two JOINED units are pulled
## into a relation neither PROGRAMME contains (mechanically - see the levels above). Within a minute three different starts fall onto ONE relation - 0.985-0.990 m
## apart, about 27 degrees between headings, both turning at 0.08-0.10 rad/s (programmed 0.25) with their hubs near
## 0.64 rad/s (programmed 1.0) - and from there all three slide together, breathing, toward about 77 degrees while the
## pair's orbit spirals in (the units' ring from about 2.1 m to 1.0 m in radius over 15 minutes); the pen on the rod
## draws a slow wavy spiral that never retraces. A 40-degree kick to one unit's heading is forgotten. A start mirrored
## exactly (`facing`) falls into a second mode, a dancing dumbbell with the pen nearly still - metastable: after about
## five minutes it breaks its symmetry and wanders off. With the hub on the axle (a_hub = 0) an exact conservation law,
## not the interaction, decided the outcome and a kick was remembered; 12 cm ahead breaks it.
##
## Fixed step: DT = 1/120 s in SUB = 4 sub-steps, Jacobi order (every pin force from the same state before any unit
## moves, so the forces stay equal and opposite). Call advance(seconds) with any frame delta; the state after a given
## simulated time does not depend on the frame rate. Probe: commons/testing/probe_the_unit.tscn.

const DT := 1.0 / 120.0
const SUB := 4

var P := {}
var units: Array = []     ## each {x, z, th, ph, cmd: Vector3(v, w, h), force: Vector2 (world), skid: float}
var rods: Array = []      ## each {a: int, b: int, L: float}
var pens: Array = []      ## each {unit: int} (on that unit's hub pin) or {rod: int, frac: float} (on a rod)
var time := 0.0
var steps := 0
var _carry := 0.0

static func defaults() -> Dictionary:
	return {"r_pin": .15, "a_hub": .12, "L": 1.0, "v0": .15, "w0": .25, "h0": 1.0, "vmax": .4, "wmax": 1.5, "hmax": 2.0,
		"k": 3000.0, "g_v": .01, "g_w": .2, "g_h": .4, "F_slip": 25.0, "b_slip": 50.0}

## The starting arrangements, in model metres, exactly as the Python study placed them (unit 2's pin one rod length
## from unit 1's), and each one's long-run CENTRE: the mean of the two unit centres over 120-300 s there. make()
## subtracts the centre, so the orbit lands on the middle of the paper (the dynamics do not care where they start).
## `facing` is the mirror-symmetric start - the second mode.
const ARRANGEMENTS := {
	"c": {"units": [[-0.5, -0.3, 0.0, 1.5707963267948966], [0.6552446958219177, -0.10681463890439558, 2.1, -0.4]], "centre": [-0.821, -0.532]},
	"parallel": {"units": [[-0.5, -0.5, 0.0, 0.0], [-0.35, 0.35, 0.0, 1.5707963267948966]], "centre": [-0.011, 2.167]},
	"crossed": {"units": [[-0.3, -0.3, 0.0, 3.141592653589793], [0.3771067811865476, 0.43710678118654755, 1.5707963267948966, 3.141592653589793]], "centre": [0.626, 0.91]},
	"facing": {"units": [[-0.6, 0.0, 0.0, 0.0], [0.9400000000000001, 0.0, 3.141592653589793, 0.0]], "centre": [0.169, -0.001]},
}
const ORDER := ["c", "parallel", "crossed", "facing"]

## THREE UNITS IN A TRIANGLE (Palle, 2026-11-03: "can we make three units in a triangle"): three identical units, a
## rigid rod between every two hub pins. The rule is unchanged - each unit feels the SUM of the forces at its own pin.
## With the pair's programme (w0 0.25) six of eight random starts fall onto one relation, but it travels a circle about
## 7 m across; with a tighter own circle (w0 0.8 - the triangle's programme, TRIANGLE_PARAMS) nine of eleven starts end
## in ONE relation - the three turning on average at 0.48 rad/s (programmed 0.8), their hubs at 0.36 (programmed
## 1.0) - and the pens draw a dense spirograph ring; mirror-symmetric starts (`tangent`) fall into a second mode, the
## hubs stopped and the triangle counter-rotating. Tendons (cords that only pull) went slack and let the units part.
## Starts: the three units exactly as the exploration placed them (each pin on an equilateral triangle of side L), and
## each one's long-run centre (the pins' centroid averaged over 150-300 s).
const TRIANGLE_PARAMS := {"w0": 0.8}
const TRIANGLES := {
	"c": {"units": [[0.17999615261193969, 0.42258505583844863, 1.8707963267948966, 1.0], [-0.6953699597527311, -0.11010084624181073, 5.765191429188092, -0.4], [0.4103372403350274, -0.29308187079151027, 4.759586531581287, 2.5]], "centre": [0.083138, 0.04381]},
	"scattered": {"units": [[0.034152467908524206, 0.8146871046657604, 4.030693606534276, 0.96174693], [-0.4728686724839381, -0.44178295393078243, 0.6208031349681211, 1.9319842], [0.5860703781143999, -0.28867567955649026, 7.820474583567981, 2.5308444]], "centre": [0.440147, 0.606481]},
	"drifted": {"units": [[0.2131764105480568, 0.7387438382021203, 3.9456034461644034, -0.28059506], [-0.598439212579559, -0.37204517186237485, 1.994006054928143, -2.1685104], [0.6100568577414167, -0.5180192259384936, 7.917632061900501, 0.687974]], "centre": [0.489187, -0.09813]},
	"tangent": {"units": [[0.27, 0.57735026, 3.141592653589793, 0.0], [-0.6349999999999998, -0.0548482703918062, 5.235987755982988, 0.0], [0.3649999999999999, -0.5225019884354031, 7.330382858376184, 0.0]], "centre": [-0.002047, 0.013854]},
}
const ORDER_TRIANGLE := ["c", "scattered", "drifted", "tangent"]

## The starts a setup steps through.
static func order(setup: String) -> Array:
	return ORDER_TRIANGLE if setup == "triangle" else ORDER

static func has_arrangement(setup: String, arrangement: String) -> bool:
	return (TRIANGLES if setup == "triangle" else ARRANGEMENTS).has(arrangement)

func _init(params: Dictionary = {}) -> void:
	P = defaults()
	for k in params:P[k] = params[k]

## THE RULE: the same for every unit. Inputs are the unit's own hub angle and the force at its own pin, split along its
## heading (f_par) and its left (f_lat). Returns its three actions (v, w, h).
static func rule(p: Dictionary, phi: float, f_par: float, f_lat: float) -> Vector3:
	var a: float = p.a_hub
	var r: float = p.r_pin
	var px := a + r * cos(phi)
	var pz := r * sin(phi)
	var tau_c := px * f_lat - pz * f_par      # torque about the axle
	var tau_h := (px - a) * f_lat - pz * f_par  # torque about the hub
	return Vector3(clampf(float(p.v0) + float(p.g_v) * f_par, -float(p.vmax), float(p.vmax)),
		clampf(float(p.w0) + float(p.g_w) * tau_c, -float(p.wmax), float(p.wmax)),
		clampf(float(p.h0) + float(p.g_h) * tau_h, -float(p.hmax), float(p.hmax)))

func add_unit(x: float, z: float, th: float, ph: float) -> int:
	units.append({"x": x, "z": z, "th": th, "ph": ph, "cmd": Vector3.ZERO, "force": Vector2.ZERO, "skid": 0.0})
	return units.size() - 1

## A rod between two units' hub pins; a TENDON pulls when stretched and goes slack when pushed (a cord, not a bar).
func add_rod(a: int, b: int, length: float = -1.0, tendon := false) -> int:
	rods.append({"a": a, "b": b, "L": float(P.L) if length < 0.0 else length, "tendon": tendon})
	return rods.size() - 1

func add_pen_on_unit(i: int) -> int:
	pens.append({"unit": i})
	return pens.size() - 1

func add_pen_on_rod(j: int, frac: float = .5) -> int:
	pens.append({"rod": j, "frac": frac})
	return pens.size() - 1

## A pen at the centroid of some units' pins - on a plate the rods between them carry.
func add_pen_on_plate(of: Array) -> int:
	pens.append({"plate": of.duplicate()})
	return pens.size() - 1

## Where unit i's hub pin is, in model metres.
func pin(i: int) -> Vector2:
	var u: Dictionary = units[i]
	var th: float = u.th
	var al: float = th + float(u.ph)
	return Vector2(float(u.x) + float(P.a_hub) * cos(th) + float(P.r_pin) * cos(al), float(u.z) + float(P.a_hub) * sin(th) + float(P.r_pin) * sin(al))

func hub(i: int) -> Vector2:
	var u: Dictionary = units[i]
	return Vector2(float(u.x) + float(P.a_hub) * cos(float(u.th)), float(u.z) + float(P.a_hub) * sin(float(u.th)))

func pen_point(j: int) -> Vector2:
	var pen: Dictionary = pens[j]
	if pen.has("unit"):
		return pin(int(pen.unit))
	if pen.has("plate"):
		var c := Vector2.ZERO
		for i in pen.plate:c += pin(int(i))
		return c / float((pen.plate as Array).size())
	var rod: Dictionary = rods[int(pen.rod)]
	var a := pin(int(rod.a))
	var b := pin(int(rod.b))
	return a + float(pen.frac) * (b - a)

## The rod's stretch (length minus rest length), metres.
func stretch(j: int) -> float:
	var rod: Dictionary = rods[j]
	return pin(int(rod.b)).distance_to(pin(int(rod.a))) - float(rod.L)

## Run the model forward by `seconds` of simulated time in whole fixed ticks; the remainder carries to the next call.
func advance(seconds: float) -> int:
	_carry += seconds
	var n := 0
	while _carry >= DT - 1e-12:
		_carry -= DT
		tick()
		n += 1
	return n

## One fixed tick: SUB sub-steps, each computing every pin force from the same state, then moving every unit.
func tick() -> void:
	var ds := DT / SUB
	var k: float = P.k
	for s in SUB:
		var pins := []
		for i in units.size():pins.append(pin(i))
		var forces := []
		forces.resize(units.size());forces.fill(Vector2.ZERO)
		for rod in rods:
			var a: int = rod.a
			var b: int = rod.b
			var dx: float = pins[b].x - pins[a].x
			var dz: float = pins[b].y - pins[a].y
			var ln := sqrt(dx * dx + dz * dz)
			if ln < 1e-9:continue
			var tn: float = k * (ln - float(rod.L))   # tension: positive pulls the pins together
			if tn < 0.0 and bool(rod.get("tendon", false)):continue   # a slack cord pushes nothing
			var ux := dx / ln
			var uz := dz / ln
			forces[a] = Vector2(forces[a].x + tn * ux, forces[a].y + tn * uz)
			forces[b] = Vector2(forces[b].x - tn * ux, forces[b].y - tn * uz)
		for i in units.size():
			var u: Dictionary = units[i]
			var c := cos(float(u.th))
			var sn := sin(float(u.th))
			var fx: float = forces[i].x
			var fz: float = forces[i].y
			var f_par := fx * c + fz * sn
			var f_lat := -fx * sn + fz * c
			var cmd := rule(P, float(u.ph), f_par, f_lat)
			# the ground: the wheels hold sideways up to F_slip, past it the chassis skids
			var excess := absf(f_lat) - float(P.F_slip)
			var slip := (signf(f_lat) * excess / float(P.b_slip)) if excess > 0.0 else 0.0
			u.x = float(u.x) + (cmd.x * c - slip * sn) * ds
			u.z = float(u.z) + (cmd.x * sn + slip * c) * ds
			u.th = float(u.th) + cmd.y * ds
			u.ph = float(u.ph) + cmd.z * ds
			u.cmd = cmd
			u.force = forces[i]
			u.skid = float(u.skid) + absf(slip) * ds
	time += DT
	steps += 1

## A pair at one of ARRANGEMENTS, joined (pen on the rod) or not (a pen on each hub pin); or one unit alone.
## `apart` uses the same starts as the pair - the control: same units, same rule, no rod.
static func make(setup: String, arrangement: String, params: Dictionary = {}, pen_frac: float = .5, centred := true) -> RefCounted:
	if setup == "triangle":
		var tp := TRIANGLE_PARAMS.duplicate()
		for k in params:tp[k] = params[k]
		var tri = load("res://commons/artifacts/the_unit/unit_sim.gd").new(tp)
		var t: Dictionary = TRIANGLES.get(arrangement, TRIANGLES.c)
		var tx: float = float(t.centre[0]) if centred else 0.0
		var tz: float = float(t.centre[1]) if centred else 0.0
		for u in t.units:tri.add_unit(float(u[0]) - tx, float(u[1]) - tz, float(u[2]), float(u[3]))
		tri.add_pen_on_plate([0, 1, 2])
		for e in [[0, 1], [1, 2], [2, 0]]:tri.add_pen_on_rod(tri.add_rod(int(e[0]), int(e[1])), .5)
		return tri
	var sim = load("res://commons/artifacts/the_unit/unit_sim.gd").new(params)
	var turn_r: float = float(sim.P.v0) / float(sim.P.w0)   # an unjoined unit circles a centre this far to its left
	if setup == "one":
		sim.add_unit(0.0, -turn_r if centred else 0.0, 0.0, 0.0)
		sim.add_pen_on_unit(0)
		return sim
	var arr: Dictionary = ARRANGEMENTS.get(arrangement, ARRANGEMENTS.c)
	var cx: float = float(arr.centre[0]) if centred else 0.0
	var cz: float = float(arr.centre[1]) if centred else 0.0
	if setup == "apart" and centred:
		# unjoined, each unit keeps its own circle: centre the paper on the mean of their two turning centres
		cx = 0.0;cz = 0.0
		for u in arr.units:
			cx += (float(u[0]) - turn_r * sin(float(u[2]))) / 2.0
			cz += (float(u[1]) + turn_r * cos(float(u[2]))) / 2.0
	for u in arr.units:sim.add_unit(float(u[0]) - cx, float(u[1]) - cz, float(u[2]), float(u[3]))
	if setup == "pair":
		var j: int = sim.add_rod(0, 1)
		sim.add_pen_on_rod(j, pen_frac)
	else:
		sim.add_pen_on_unit(0)
		sim.add_pen_on_unit(1)
	return sim
