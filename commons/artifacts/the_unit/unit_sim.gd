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
## explaining the local rules and the causal evidence". By our reading this model sits at the BORDER of levels 2 and
## 3, and we place it at 2: the rule has the form of Palle's own level-3 example (units change their steering when they
## feel tension), but it is a fixed, linear response with no memory and no choice - what a back-drivable motor does by
## itself - so the shared rates and the relation below are mechanical self-organisation, not units that adapt. Level 1
## is the unjoined control (`apart`): the two programmes, and nothing between them. Units that change their own
## command from what they sense (ease, phase, keep below) were added for his Experiment 2. ease (a leaky integrator)
## and keep (a filter and a threshold) carry memory; phase's hub reflex is a fixed, memoryless map from force to rate,
## which by the criterion above would be level 2 - we place it at level 3 on a different criterion, that it answers a
## load the passive hub drive cannot feel (the pull along its own hub arm does no work on the hub), and say so.
##
## THE ROD is physics, not a controller: a rigid pin-to-pin bar of length L, modelled as a stiff spring (k), pulling
## the two pins together when stretched and apart when squeezed - equal and opposite (Newton's third law).
##
## THE RULE (`rule`) is the same function with the same numbers in every unit. It reads ONLY local things: the unit's
## own hub angle and the force its own pin feels, in its own frame - that force carries the rod's direction and
## tension, which is all a unit knows of its partner. Each unit drives a fixed programmed circle (v0, w0, h0) and GIVES
## WAY, linearly, to the rod: forward speed to the pull along its heading, the chassis turn to the torque about the
## axle, the hub to the torque about the hub. Nothing is choreographed - no path or relation is written into the rule -
## and the shared relation below is the steady state of that coupling.
##
## What came of it (a Python study of three rule families, 2026-11-03, then this model run to 960 s; checked again by
## an adversarial review): one unit draws a closed four-loop rosette; two unjoined units draw two copies of it. Two
## JOINED units, from 10 of 11 starts tried, settle within about ten minutes into one relation neither programme
## contains: a mean of about 73 degrees between headings that breathes through about 37 (either unit leading), both
## turning at about 0.185 rad/s and their hubs
## at about 0.77, against a programmed 0.25 and 1.0. It is not the only relation: two of six 40-degree kicks move the
## pair into a second one near 45 degrees (0.13 rad/s) that holds; the other four are forgotten. For those ten minutes
## the pen on the rod spirals inwards; then it keeps to a ring under a metre in radius and draws over its own lines.
## `facing` is point-symmetric (turned half a turn): the symmetry holds the pen still at its centre while the units
## dance - an unstable state that rounding error breaks, not a mode. The hub sits 12 cm ahead of the axle because on
## the axle the rule conserves g_h*dtheta - g_w*dphi exactly, so the start, not the interaction, fixed the outcome.
##
## PHYSICS AND CONTROLLER (2026-11-03, Experiments 1 and 2): read as physics, the force-yield above is a compliant,
## back-drivable DRIVE - its mobility (g_v, g_w, g_h) is passive - and (v0, w0, h0) is the drive's COMMAND. A unit's
## CONTROLLER (`ctrl`) sets that command each tick: "programme" keeps the constant (v0, w0, h0) and senses nothing (the
## open-loop baseline; everything above is this). A sensing controller computes the command from the unit's OWN local
## sensors - its hub angle, its own pin's force in its own frame, and each link's bearing, length and tension at its own
## attachment (link_sense) - with memory if it needs it; the passive mobility stays on either way, so switching
## sensing off and on is the ablation. drive() is the same physics for any command; rule() is drive() at the programme.
##
## Fixed step: DT = 1/120 s in SUB = 4 sub-steps, Jacobi order (every pin force from the same state before any unit
## moves, so the forces stay equal and opposite). Call advance(seconds) with any frame delta; the state after a given
## simulated time does not depend on the frame rate. Probe: commons/testing/probe_the_unit.tscn.

const DT := 1.0 / 120.0
const SUB := 4

var P := {}
var units: Array = []     ## each {x, z, th, ph, cmd: Vector3(v, w, h), force: Vector2 (world), skid: float, ctrl, mem}
var rods: Array = []      ## each {a: int, b: int, L: float}
var pens: Array = []      ## each {unit: int} (its hub pin), {rod: int, frac} (on a rod), {plate: [..]} or {between: [a, b], frac}
var time := 0.0
var steps := 0
var _carry := 0.0

static func defaults() -> Dictionary:
	return {"r_pin": .15, "a_hub": .12, "L": 1.0, "v0": .15, "w0": .25, "h0": 1.0, "vmax": .4, "wmax": 1.5, "hmax": 2.0,
		"k": 3000.0, "g_v": .01, "g_w": .2, "g_h": .4, "F_slip": 25.0, "b_slip": 50.0}

## The starting arrangements, in model metres, exactly as the Python study placed them (unit 2's pin one rod length
## from unit 1's), and each one's long-run CENTRE: the mean of the two unit centres over 120-300 s there. make()
## subtracts the centre, so the orbit lands on the middle of the paper (the dynamics do not care where they start).
## `facing` is the point-symmetric start (see above).
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
## 7 m across; with a tighter own circle (w0 0.8 - the triangle's programme, TRIANGLE_PARAMS) every start tried settles
## by 900 s into ONE relation - the three turning on average at 0.48 rad/s (programmed 0.8), their hubs at 0.36
## (programmed 1.0) - and the pens weave a dense spirograph ring. The threefold-symmetric start (`tangent`) holds its
## symmetry for minutes (its hubs nearly still, the triangle turning backwards) and then joins the same relation.
## Tendons (cords that only pull) went slack and let the units part. Level 2 again: mechanical coupling, no adaptation.
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

## THE DRIVE: the same passive compliance for any COMMAND (cv, cw, ch) - what a back-drivable motor does when its
## controller asks for those rates and the rod pushes on it. rule() is drive() at the programme (v0, w0, h0).
static func drive(p: Dictionary, phi: float, f_par: float, f_lat: float, cv: float, cw: float, ch: float) -> Vector3:
	var a: float = p.a_hub
	var r: float = p.r_pin
	var px := a + r * cos(phi)
	var pz := r * sin(phi)
	var tau_c := px * f_lat - pz * f_par
	var tau_h := (px - a) * f_lat - pz * f_par
	return Vector3(clampf(cv + float(p.g_v) * f_par, -float(p.vmax), float(p.vmax)),
		clampf(cw + float(p.g_w) * tau_c, -float(p.wmax), float(p.wmax)),
		clampf(ch + float(p.g_h) * tau_h, -float(p.hmax), float(p.hmax)))

func add_unit(x: float, z: float, th: float, ph: float) -> int:
	units.append({"x": x, "z": z, "th": th, "ph": ph, "cmd": Vector3.ZERO, "force": Vector2.ZERO, "skid": 0.0, "ctrl": "programme", "mem": {}})
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

## A tool point between two pins whether or not a link joins them - the unlinked pair's virtual rod middle.
func add_pen_between(a: int, b: int, frac: float = .5) -> int:
	pens.append({"between": [a, b], "frac": frac})
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
	if pen.has("between"):
		var pa := pin(int(pen.between[0]))
		return pa + float(pen.frac) * (pin(int(pen.between[1])) - pa)
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

## What unit i senses of each link at its OWN attachment (a swivel encoder and a reel or load cell at the pin): the
## link's bearing in the unit's body frame (0 ahead, + to the left), the straight-line length to the partner's pin,
## and the tension. The partner's command, heading and hub are not read, but its pin position is: a rod carries it to
## the swivel; a cord carries it only through the ideal take-up reel described with the controllers below.
func link_sense(i: int, pins: Array) -> Array:
	var out := []
	var u: Dictionary = units[i]
	var c := cos(float(u.th))
	var sn := sin(float(u.th))
	for rod in rods:
		var other := -1
		if int(rod.a) == i:other = int(rod.b)
		elif int(rod.b) == i:other = int(rod.a)
		if other < 0:continue
		var d: Vector2 = pins[other] - pins[i]
		var ln := d.length()
		var tn: float = float(P.k) * (ln - float(rod.L))
		if tn < 0.0 and bool(rod.get("tendon", false)):tn = 0.0
		out.append({"bearing": atan2(-d.x * sn + d.y * c, d.x * c + d.y * sn), "length": ln, "tension": tn, "rest": float(rod.L)})
	return out

## THE SENSING CONTROLLERS (Experiment 2, 2026-11-03; designed and tested in the Python twin of this model, then
## ported). Each reads only the unit's own sensors and memory and is evaluated once per tick, from the state at the
## start of the tick (sub-step 0), its command held for the tick's sub-steps. The passive drive stays on in every arm.
##   ease   (rigid rod) the hub leaks toward easing the RADIAL pull on its own pin - the pull along its own hub arm,
##          f_rad = f_par cos(ph) + f_lat sin(ph), which does no work on the hub, so a passive hub cannot feel it:
##          d_h += DT (-0.2 sign(h0) f_rad - 1.0 d_h), clamped to +-1; ch = h0 + d_h. The pair ends with the rod
##          unloaded while both units keep their whole programme: an unstressed two-point carry.
##   phase  (rigid rod) the same radial pull as a memoryless hub reflex, ch = h0 - 0.05 f_rad, plus a bearing hold on
##          the chassis: the rod's spin in the world, rho = d(bearing)/dt + own turn rate (gyro), is pushed against
##          along the rod's normal (cv = v0 - sin(b) du, cw = w0 + cos(b) du / v0, du = clamp(0.1 L rho, +-0.1)).
##          The pair carries the bar without it ever turning, like the bar of a drafting machine.
##   keep   (tendon) pushes away when its own cord, filtered over 3 s, is shorter than 0.95 m (the cord itself does the
##          pulling): e = min(0, ell_f - 0.95); steer and pace away from where the partner's pin is seen. The hub is
##          never touched. The pair ends joined at a distance, the chassis apart after the first seconds.
##   ease_flip, phase_hub, keep_pull: the ablations - the same signal with the opposite sign, the hub reflex alone,
##          and only the pull half (move toward the partner when the filtered cord is longer than 0.95 m - the half a
##          tendon already does).
## For the tendon, link_sense assumes a weightless take-up reel that keeps the cord straight at zero tension, so a unit
## reads the exact distance and bearing of its partner's pin even when the cord is slack - which is where keep's push
## half acts: in effect a range-and-bearing sensor on the partner, carried by the cord.
## THE OTHER TWO RULE FAMILIES of the 2026-11-03 Python study, ported for the gallery's zoo (Palle: "as many different
## examples as possible"). Both read only the unit's own sensors.
##   steer, steer_chiral  (Braitenberg) turn to keep the rod across the body, w = w0 - 2.0 sin(b) cos(b) (chiral: keep
##          it on the left, w = w0 - 2.0 cos(b)); speed up when the rod points ahead and go with its pull,
##          v = v0 (1 + 0.8 cos b) + 0.01 T cos b; the hub gives way to the rod's torque about it, h = h0 + 0.5 tau.
##   rhythm, rhythm_anti  (Kuramoto through the rod) the hub rate yields to (anti: pushes back against) the rod's
##          torque on the hub, low-passed over 0.25 s: h = clamp(h0 +- 1.0 tau_f, 0, hmax); the chassis runs its programme.
## They run here on this model's compliant drive, not on the studies' own physics (stiff servos, a rigid rod,
## saturating motors and a non-back-drivable hub for steer), so they draw their own figures, not copies of the study's.
const STEER_KB := 2.0
const STEER_KA := 0.8
const STEER_KT := 0.01
const STEER_KH := 0.5
const RHYTHM_K := 1.0
const RHYTHM_TF := 0.25
const EASE_KAP := 0.2
const EASE_MU := 1.0
const EASE_DMAX := 1.0
const PHASE_KT := 0.05
const PHASE_KD := 0.1
const PHASE_KLAT := 1.0
const PHASE_DUMAX := 0.1
const KEEP_ELL_STAR := 0.95
const KEEP_TAU_F := 3.0
const KEEP_KV := 0.8
const KEEP_KW := 2.0

func _command(i: int, u: Dictionary, f_par: float, f_lat: float, pins: Array, ds: float) -> Array:
	var mem: Dictionary = u.mem
	if int(mem.get("tick", -1)) == steps:return mem.cmd
	var v0: float = P.v0
	var w0: float = P.w0
	var h0: float = P.h0
	var ph: float = u.ph
	var cmd := [v0, w0, h0]
	var f_rad := f_par * cos(ph) + f_lat * sin(ph)   # the pull along my own hub arm, outward positive
	match str(u.ctrl):
		"ease", "ease_flip":
			var sign_ := -1.0 if str(u.ctrl) == "ease" else 1.0
			var d: float = mem.get("d_h", 0.0)
			d += DT * (sign_ * EASE_KAP * signf(h0) * f_rad - EASE_MU * d)
			d = clampf(d, -EASE_DMAX, EASE_DMAX)
			mem.d_h = d
			cmd = [v0, w0, h0 + d]
		"phase", "phase_hub":
			var ch := h0 - PHASE_KT * f_rad
			var cv := v0
			var cw := w0
			var links := link_sense(i, pins)
			if str(u.ctrl) == "phase" and not links.is_empty():
				var b: float = links[0].bearing
				if mem.has("b_prev"):
					# the rod's spin in the world: its bearing change at my pin plus my own heading change, over the tick
					var rho := (wrapf(b - float(mem.b_prev), -PI, PI) + (float(u.th) - float(mem.th_prev))) / DT
					var du := clampf(float(P.L) * PHASE_KD * rho, -PHASE_DUMAX, PHASE_DUMAX)
					cv = v0 - sin(b) * du
					cw = w0 + PHASE_KLAT * cos(b) * du / v0
				mem.b_prev = b
				mem.th_prev = float(u.th)
			cmd = [cv, cw, ch]
		"keep", "keep_pull":
			var qx := float(P.a_hub) + float(P.r_pin) * cos(ph)
			var qz := float(P.r_pin) * sin(ph)
			var dv := 0.0
			var dw := 0.0
			var links := link_sense(i, pins)
			for j in links.size():
				var ell: float = links[j].length
				var beta: float = links[j].bearing
				var key := "ellf%d" % j
				if mem.has(key):mem[key] = float(mem[key]) + (ell - float(mem[key])) * DT / KEEP_TAU_F
				else:mem[key] = ell
				var e := minf(0.0, float(mem[key]) - KEEP_ELL_STAR) if str(u.ctrl) == "keep" else maxf(0.0, float(mem[key]) - KEEP_ELL_STAR)
				var gam := atan2(qz + ell * sin(beta), qx + ell * cos(beta))
				dv += KEEP_KV * e * cos(gam)
				dw += KEEP_KW * e * sin(gam)
			cmd = [clampf(v0 + dv, -float(P.vmax), float(P.vmax)), clampf(w0 + dw, -float(P.wmax), float(P.wmax)), h0]
		"steer", "steer_chiral":
			var links := link_sense(i, pins)
			if not links.is_empty():
				var b: float = links[0].bearing
				var cb := cos(b)
				var sb := sin(b)
				var tau_h := float(P.r_pin) * (cos(ph) * f_lat - sin(ph) * f_par)   # the rod's torque about my hub
				var cw := w0 - STEER_KB * (sb * cb if str(u.ctrl) == "steer" else cb)
				var cv := v0 * (1.0 + STEER_KA * cb) + STEER_KT * float(links[0].tension) * cb
				cmd = [clampf(cv, -float(P.vmax), float(P.vmax)), clampf(cw, -float(P.wmax), float(P.wmax)), clampf(h0 + STEER_KH * tau_h, -float(P.hmax), float(P.hmax))]
		"rhythm", "rhythm_anti":
			var tau := float(P.r_pin) * (cos(ph) * f_lat - sin(ph) * f_par)
			var tf: float = mem.get("tau_f", tau)
			tf += (tau - tf) * DT / RHYTHM_TF
			mem.tau_f = tf
			var kk := RHYTHM_K if str(u.ctrl) == "rhythm" else -RHYTHM_K
			cmd = [v0, w0, clampf(h0 + kk * tf, 0.0, float(P.hmax))]
	mem.cmd = cmd
	mem.tick = steps
	return cmd

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
			var cmd: Vector3
			if str(u.get("ctrl", "programme")) == "programme":
				cmd = rule(P, float(u.ph), f_par, f_lat)   # the open-loop baseline, bit for bit as before
			else:
				var c3: Array = _command(i, u, f_par, f_lat, pins, ds)
				cmd = drive(P, float(u.ph), f_par, f_lat, float(c3[0]), float(c3[1]), float(c3[2]))
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
