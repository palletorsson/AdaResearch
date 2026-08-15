extends Node3D
class_name ConfigurationYard

## configuration_yard — three vocabularies for the SAME question, standing in one yard.
##
## Three artifacts in this corpus carry an axis called `configuration`, and all three
## mean "where the mass is at t = 0, which is the one thing gravity cannot derive for
## you". They then name three different KINDS of thing, and the family has never noticed:
##
##   example_3_2_forces_with_arbitrary_angular_motion_vr   ring · column · shells · fan · scatter
##       An ARRANGEMENT, the way a stage manager arranges. Its own file says so: the
##       words describe where to stand, and the velocities they come with are picked
##       by eye (`Vector3(-sin(angle) * 0.3, 0, cos(angle) * 0.3)` — the same 0.3 at
##       every radius, which is not a speed anything derived).
##   nbody_simulation                                      cloud · disc · shells · binary · lattice
##       A STATISTICAL SHAPE: where twenty bodies are, said as a distribution. Four of
##       its five values are sampled from an RNG, and its own registry note says the
##       three-body words "mean nothing at twenty".
##   three_body_problem                                    pinwheel · figure_eight · lagrange · hierarchical · near_collision
##       An EXACT SOLUTION. Two of its five are named, published, measure-zero families
##       in a chaotic problem. You cannot reach them by drawing a shape; you solve for
##       them. Its CONFIGURATIONS table holds the numbers to four decimals.
##
## THE CLAIM, and it is disputable: the axis conflates a distribution you can sketch,
## an arrangement you can place, and a solution you must derive — and the three are
## indistinguishable in a photograph of the starting positions. `ring` (a stage
## arrangement) and `lagrange` (a theorem) put three bodies at THE SAME THREE POINTS.
## Only integration separates them, and only perturbation says which one was load-bearing.
##
## WHAT WAS CHECKED IN THE MEMBERS' OWN NUMBERS, because the brief said to check:
##   figure_eight IS the Chenciner–Montgomery choreography, not an approximation of it.
##     three_body's table holds (5.820, 0, -1.459) = 6 x (0.97000436, -0.24308753), the
##     published unit initial condition to five figures, with the velocity scaled by
##     sqrt(100 / 6) — exactly the Kepler scaling for its G = 0.1, m = 1000, L = 6.
##   lagrange IS the equilateral L4/L5 rotating triangle. Circumradius 5, side 8.660 =
##     5 * sqrt(3) (verified: |b1 - b2| = |b0 - b1| = 8.660), speed 3.398 = omega * R
##     with omega = sqrt(3 G m / a^3) = 0.6796. Rigid rotation, exact.
##   Both are reproduced here at this yard's scale rather than quoted.
##   pinwheel, three_body's default, is NOT a pinwheel: two bodies circulate one way and
##     the third the other ((0,0,5) is given (-3,0,0) where a pinwheel wants (+3,0,0)),
##     which is why its total momentum is non-zero and its barycentre drifts. It is not
##     imported. See the registry `declines`.
##
## N = 3 IS FORCED, not chosen. figure_eight and lagrange are theorems about exactly
## three bodies — nbody_simulation's own note says so. Three is the only count at which
## all three vocabularies can be spoken at once, and what that costs is visible: at N = 3
## a "cloud" is not a distribution, it is one arbitrary arrangement, so the statistical
## vocabulary's own null value could not be built (registry `declines`).
##
## Deterministic to the byte: no randf, no noise, no _process, no Timer. The whole figure
## is arithmetic on seven initial-condition tables and one integrator, run inside _ready.


## WHICH UNIVERSE STARTS. Seven values, and every word is a member's.
##
##   ring          example_3_2. Three on a circle of radius SYS_R, in the XZ plane, given
##                 equal tangential speeds picked BY EYE — RING_FRAC = 0.70 of the speed
##                 the theorem requires. A stage arrangement, with the stage manager's
##                 guess at how fast. Note what it turns out to be: the equilateral
##                 triangle is a central configuration, so ANY purely tangential equal
##                 speed gives a homographic solution — the triangle stays equilateral
##                 and breathes. At 0.70 it breathes down to 0.09735 m (e = 0.51) and
##                 back, 1.86 times in the window. The arrangement is not wrong about
##                 the shape. It is wrong about everything else.
##   column        example_3_2. Translation collapsed onto one axis: the three stacked on
##                 the vertical through the centre at COL_SPAN spacing, each given the
##                 same by-eye speed in a horizontal direction 120 degrees from its
##                 neighbours' — which is example_3_2's own `column` statement (its
##                 velocity is indexed by i/n * TAU while its position is not). Maximally
##                 ordered, and a solution of nothing.
##   shells        THE CONTESTED WORD — it is in example_3_2 AND in nbody_simulation, and
##                 THEY DO NOT MEAN THE SAME THING. nbody's shells is two concentric
##                 SPHERES sampled at random (`sin(v)cos(u), cos(v), sin(v)sin(u)` at
##                 0.45 R and 1.0 R): a sampling statement, invisible below N ~ 20.
##                 example_3_2's shells is two horizontal RINGS at two heights (r = 0.12
##                 at y = 0.62, r = 0.40 at y = 0.38, half-step offset "so no inner box
##                 hides behind an outer one"): a placement statement, readable at N = 4.
##                 At N = 3 nbody's word has nothing to say and example_3_2's does, so
##                 what is built here is example_3_2's two levels, with nbody's rule for
##                 WHICH body goes where (i % 2 == 0 is inner, so bodies 0 and 2 are
##                 inner and body 1 is outer). At rest, which both members specify.
##   lattice       nbody_simulation, and it is the one value of its five that is
##                 deterministic. Its code takes per_side = ceil(N^(1/3)), which at N = 3
##                 is 2, and lays the first three cells of a 2x2x2 grid: three corners of
##                 a cube, coplanar, at rest. Perfect order, zero entropy, and its own
##                 note calls it "the least stable arrangement in the set".
##   hierarchical  three_body_problem. A tight binary plus a distant third — the
##                 arrangement most real triple systems settle into. The source's ratio is
##                 kept (separation 3, third at 12, so 1 : 4); the inner pair is given its
##                 exact circular mutual orbit, as the source does, and the outer body is
##                 given a CIRCULAR velocity where the source's is eccentric. That is a
##                 deviation and it is stated in the registry: the source's third body has
##                 semi-major axis 2.0 times its start radius and would leave this yard.
##                 This is also nbody's `binary` at N = 3 — see the registry `declines`.
##   figure_eight  three_body_problem, and it is the Chenciner–Montgomery choreography
##                 rebuilt from the same published constants at L = SYS_R. All three
##                 bodies chase each other around ONE curve, which is what a choreography
##                 is, so the `path` reading of this value draws three tracks that are one
##                 curve — they are nested at three radii so that fact is visible rather
##                 than a z-fight.
##   lagrange      three_body_problem. The equilateral triangle rotating rigidly.
##                 The SAME THREE POINTS as `ring` — same radius, same phase, by
##                 construction — with the one speed that makes it a solution.
@export_enum("ring", "column", "shells", "lattice", "hierarchical", "figure_eight", "lagrange") var configuration: String = "ring":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not CONFIGURATIONS.has(picked):
			return                      ## an unreachable value keeps the current figure
		configuration = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## WHAT IS SHOWN OF IT. Three values, and it is this synthesis's own axis — no member
## has one, though all three have `evidence` (result · trace · longhand · axiom), which
## asks what is drawn of a RUNNING simulation. This asks something narrower and it is the
## thing the family cannot currently answer: how much of the initial condition survives.
##
##   start   the three bodies at t = 0 and nothing else. THE CONFIGURATION ITSELF, as a
##           placement. No velocity is drawn, because an arrangement does not carry one —
##           and that is precisely why ring and lagrange are the same picture here.
##   path    the integrated trajectories, as real tubes. Velocity-Verlet, h = 0.0005 s,
##           2720 steps, T = 1.360 s, G = 1, m = 1, and a minimum-separation clamp at
##           R_MIN = 0.05 m taken from both members (nbody clamps r into [0.01, 0.15];
##           three_body skips pairs closer than 0.1). MEASURED: the clamp is never
##           reached by ring (0.1686), hierarchical (0.1292), figure_eight (0.2071) or
##           lagrange (0.5196), so all four — including both exact solutions — are
##           integrated under Newton's law unmodified. It bites only for column (0.0467),
##           shells (0.0004) and lattice (0.0002), which are the three that collapse.
##   drift   the same trajectories with the perturbed run drawn over them. Body 0 is
##           moved PERTURB = 0.0005 m — half a millimetre, 0.167% of the system radius —
##           and the whole system re-integrated. The perturbed track is GOLD and slightly
##           fatter than the widest unperturbed tube, so the reading is direct: gold alone
##           means the two runs agree to within a tube width; colour beside the gold means
##           they have parted. THIS IS THE READING THAT CARRIES THE THESIS.
@export_enum("start", "path", "drift") var reading: String = "start":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not READINGS.has(picked):
			return
		reading = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One yard, or all seven in a row. NOT PART OF EITHER AXIS, and the registry fixture
## pins `single`. capture_config_sweep unions the AABB across a spec's variants, so an
## all-configurations value declared inside `configuration` would frame every single
## variant against nearly eight metres and photograph the yard as a chip.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const CONFIGURATIONS: PackedStringArray = [
	"ring", "column", "shells", "lattice", "hierarchical", "figure_eight", "lagrange"]
const READINGS: PackedStringArray = ["start", "path", "drift"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the yard, and it is the whole answer to the extent trap ────────────────────────────
## A `shells` figure is 0.55 m across and a `hierarchical` one is 0.80 m; a perturbed
## `column` run reaches 0.76 m from the centre. An AABB fitted to the FIGURE would move
## by a factor of one and a half across the sheet and the camera would move with it. The
## plate, the rim, the four posts and the top ring are drawn IDENTICALLY in all
## twenty-one variants and are the largest thing in the scene, so the union AABB is
## 1.00 x 1.00 x 1.00 in every cell BY CONSTRUCTION — the plate's radius sets x and z, the
## posts set y, and nothing drawn inside can reach either (see CLIP_R).
const YARD_R: float = 0.50
const YARD_H: float = 1.00
const PLATE_T: float = 0.024
const POST_RING: float = 0.46
const POST_T: float = 0.030
const RAIL_R: float = 0.015
const YARD_SEGS: int = 40

# ── the law ────────────────────────────────────────────────────────────────────────────
const G: float = 1.0
const MASS: float = 1.0
## The system's own radius. ring, lagrange and figure_eight all start on it, which is not
## a coincidence: |(0.97000436, -0.24308753)| = 1.00000 in the choreography's unit
## solution, so scaling it by SYS_R puts its two outer bodies exactly where the ring is.
const SYS_R: float = 0.30
## Minimum separation used in the force. THE FAMILY'S OWN DEVICE, not a softening
## invented here: nbody_simulation clamps distance into [0.01, 0.15] and three_body_problem
## refuses any pair closer than 0.1. Above it the law is Newton's, untouched.
const R_MIN: float = 0.05
const H: float = 0.0005
const STEPS: int = 2720
## Every tenth step is drawn: 272 spans per track. T = STEPS * H = 1.360 s, which is
## 1.0009 Lagrange periods (T_L = 1.358758 s), 1.308 figure-eight periods (T_8 = 1.039443 s)
## and 0.945 of hierarchical's outer orbit.
const SAMPLE: int = 10
## Half a millimetre on body 0, applied to POSITION only, then re-centred on the
## barycentre so the two runs start with the same centre of mass and the same total
## momentum. Measured divergence after 1.360 s, as the largest body-to-body distance
## between the two runs: lagrange 0.0072, figure_eight 0.0087, hierarchical 0.0305 —
## against ring 0.3731, shells 0.3880, lattice 0.5221, column 0.5456. A factor of fifty.
const PERTURB: float = 0.0005
## `ring` is example_3_2's arrangement, and example_3_2 gives its ring a tangential speed
## that is a flat 0.3 at every radius — a number nothing derived. 0.70 of the theorem's
## speed is this bench's stand-in for that gesture, and the 0.70 is mine: it is declared
## here rather than dressed up as inherited.
const RING_FRAC: float = 0.70

## Where the system floats inside the yard. High enough that a collapsing figure does not
## sink into the plate, low enough that nothing reaches the top ring.
const CENTRE: Vector3 = Vector3(0.0, 0.52, 0.0)
## A body that leaves the yard leaves the picture. Drawing stops at this radius from
## CENTRE and resumes if the track returns. MEASURED: no UNPERTURBED track is ever cut
## (the widest is lattice at 0.4249); three perturbed ones are (ring 0.5490, lattice
## 0.5386, column 0.7576), which is exactly the case where "it left" is the reading.
## 0.44 + the widest tube (0.0120) = 0.4520, inside the plate's 0.50, so the AABB holds.
const CLIP_R: float = 0.44

const COL_SPAN: float = 0.30
const SHELL_IN_R: float = 0.14
const SHELL_IN_Y: float = 0.12
const SHELL_OUT_R: float = 0.34
const SHELL_OUT_Y: float = -0.12
const LAT: float = 0.20
const HIER_D: float = 0.135
const HIER_SEP: float = 0.54

## The Chenciner–Montgomery choreography, unit solution (G = m = 1), as published:
## x1 = (0.97000436, -0.24308753) = -x2, x3 = 0; v3 = (-0.93240737, -0.86473146),
## v1 = v2 = -v3 / 2; period 6.32591398. Scaled here by L = SYS_R, with velocities by
## 1 / sqrt(L) — the exact Kepler scaling, the same one three_body_problem applies as
## sqrt(100 / 6) for its own G m and L.
const FE_X: float = 0.97000436
const FE_Y: float = 0.24308753
const FE_VX: float = 0.93240737
const FE_VY: float = 0.86473146

# ── how thick a mark is ────────────────────────────────────────────────────────────────
const BODY_R: float = 0.042
## NESTED, and that is not decoration. In a choreography all three bodies run on ONE
## curve, so three tubes of equal radius would be three coincident surfaces and the
## figure_eight tile would be a depth-fight. Nested, the shared curve reads as one ribbon
## with the others inside it, which is what a choreography looks like.
const TUBE_R: PackedFloat32Array = [0.0105, 0.0090, 0.0075]
## Wider than the widest of those, so where the two runs agree the gold swallows the
## colour and where they part both are visible.
const DRIFT_R: float = 0.0120
const LADDER_PITCH: float = 1.15

# ── colour ─────────────────────────────────────────────────────────────────────────────
## The three body colours are three_body_problem's own queer_colors[0..2], character for
## character. The gold is the same Color(1.0, 0.85, 0.35) both members use for the one
## thing in the room that is NOT the instance — three_body's axiom slate and barycentre
## track, nbody's `_draw_axiom`. Here it carries the perturbed run, which is the other
## thing in this yard that is about the law rather than about one starting point.
const C_BODY_0: Color = Color(1.00, 0.40, 0.70)
const C_BODY_1: Color = Color(0.80, 0.30, 1.00)
const C_BODY_2: Color = Color(0.30, 0.90, 1.00)
const E_BODY_0: Color = Color(0.42, 0.14, 0.28)
const E_BODY_1: Color = Color(0.32, 0.10, 0.42)
const E_BODY_2: Color = Color(0.10, 0.36, 0.44)
const C_DRIFT: Color = Color(1.00, 0.85, 0.35)
const E_DRIFT: Color = Color(0.46, 0.38, 0.14)
const C_PLATE: Color = Color(0.20, 0.21, 0.24)
const C_RIM: Color = Color(0.30, 0.31, 0.35)
const C_POST: Color = Color(0.42, 0.43, 0.47)

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
	if config_data.has("configuration"):
		configuration = str(config_data["configuration"])
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
	var names: PackedStringArray = PackedStringArray()
	if layout == "ladder":
		names = CONFIGURATIONS.duplicate()
	else:
		names.append(_pick(configuration, CONFIGURATIONS, "ring"))
	var how: String = _pick(reading, READINGS, "start")
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Yard_" + names[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_yard(holder)
		_build_figure(holder, names[i], how)


# ── the initial conditions ─────────────────────────────────────────────────────────────

## Nine doubles, xyz per body. GDScript's `float` is 64-bit and Vector3's components are
## not, so the whole integration runs in PackedFloat64Array and only becomes Vector3 when
## it is time to draw. Three of the seven configurations pass within a millimetre of each
## other, and at single precision the drawn path there would be a fact about float32.
func _zeros9() -> PackedFloat64Array:
	return PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])


## The one speed that makes the equilateral triangle rigid. Each body is pulled by two
## others at distance a = R * sqrt(3); the two pulls sum to sqrt(3) * F toward the centre,
## so omega^2 = 3 G m / a^3 — which is exactly the formula three_body_problem's own
## comment states for its lagrange row, and reproducing it here rather than quoting its
## numbers is what makes this a rebuild rather than a transcription.
func _lagrange_omega() -> float:
	var side: float = SYS_R * sqrt(3.0)
	return sqrt(3.0 * G * MASS / (side * side * side))


## [positions, velocities], both centred on the barycentre. Centring is not tidiness: the
## barycentre is the one thing conserved (it is what both members' `axiom` value draws),
## so putting it at the yard's centre in every value is the only way seven different
## figures can be photographed by one camera without privileging one of them.
func _initial(which: String) -> Array:
	var p: PackedFloat64Array = _zeros9()
	var v: PackedFloat64Array = _zeros9()
	var omega: float = _lagrange_omega()
	var v_lagrange: float = omega * SYS_R
	var ang: PackedFloat64Array = PackedFloat64Array(
		[PI * 0.5, PI * 7.0 / 6.0, PI * 11.0 / 6.0])

	if which == "ring" or which == "lagrange":
		var speed: float = v_lagrange
		if which == "ring":
			speed = v_lagrange * RING_FRAC
		for i in range(3):
			var a: float = ang[i]
			p[i * 3] = cos(a) * SYS_R
			p[i * 3 + 2] = sin(a) * SYS_R
			v[i * 3] = -sin(a) * speed
			v[i * 3 + 2] = cos(a) * speed
	elif which == "column":
		var cspeed: float = v_lagrange * RING_FRAC
		var ys: PackedFloat64Array = PackedFloat64Array([-COL_SPAN, 0.0, COL_SPAN])
		for i in range(3):
			var b: float = (float(i) / 3.0) * TAU
			p[i * 3 + 1] = ys[i]
			v[i * 3] = -sin(b) * cspeed
			v[i * 3 + 2] = cos(b) * cspeed
	elif which == "shells":
		p[1] = SHELL_IN_Y
		p[2] = SHELL_IN_R
		p[3] = SHELL_OUT_R
		p[4] = SHELL_OUT_Y
		p[7] = SHELL_IN_Y
		p[8] = -SHELL_IN_R
	elif which == "lattice":
		p[0] = -LAT
		p[1] = -LAT
		p[2] = -LAT
		p[3] = LAT
		p[4] = -LAT
		p[5] = -LAT
		p[6] = -LAT
		p[7] = LAT
		p[8] = -LAT
	elif which == "hierarchical":
		var pair_z: float = -HIER_SEP / 3.0
		var third_z: float = HIER_SEP * 2.0 / 3.0
		var v_pair: float = sqrt(G * MASS / (2.0 * HIER_D))
		var v_rel: float = sqrt(G * 3.0 * MASS / HIER_SEP)
		p[0] = -HIER_D * 0.5
		p[2] = pair_z
		p[3] = HIER_D * 0.5
		p[5] = pair_z
		p[8] = third_z
		v[0] = -v_rel / 3.0
		v[2] = v_pair
		v[3] = -v_rel / 3.0
		v[5] = -v_pair
		v[6] = v_rel * 2.0 / 3.0
	elif which == "figure_eight":
		var scale_v: float = 1.0 / sqrt(SYS_R)
		p[0] = FE_X * SYS_R
		p[2] = -FE_Y * SYS_R
		p[3] = -FE_X * SYS_R
		p[5] = FE_Y * SYS_R
		v[0] = FE_VX * 0.5 * scale_v
		v[2] = FE_VY * 0.5 * scale_v
		v[3] = FE_VX * 0.5 * scale_v
		v[5] = FE_VY * 0.5 * scale_v
		v[6] = -FE_VX * scale_v
		v[8] = -FE_VY * scale_v

	return [_centred(p), _centred(v)]


## Equal masses, so the barycentre is the mean. Returns a NEW array rather than writing
## through the argument: GDScript's pass semantics for a Packed array are not something
## a physics result should depend on.
func _centred(a_in: PackedFloat64Array) -> PackedFloat64Array:
	var a: PackedFloat64Array = a_in.duplicate()
	for k in range(3):
		var m: float = (a[k] + a[k + 3] + a[k + 6]) / 3.0
		a[k] -= m
		a[k + 3] -= m
		a[k + 6] -= m
	return a


# ── the law, integrated ────────────────────────────────────────────────────────────────

func _accel(p: PackedFloat64Array) -> PackedFloat64Array:
	var a: PackedFloat64Array = _zeros9()
	for i in range(3):
		for j in range(3):
			if i == j:
				continue
			var dx: float = p[j * 3] - p[i * 3]
			var dy: float = p[j * 3 + 1] - p[i * 3 + 1]
			var dz: float = p[j * 3 + 2] - p[i * 3 + 2]
			var r: float = maxf(sqrt(dx * dx + dy * dy + dz * dz), R_MIN)
			var k: float = G * MASS / (r * r * r)
			a[i * 3] += dx * k
			a[i * 3 + 1] += dy * k
			a[i * 3 + 2] += dz * k
	return a


## Velocity-Verlet, which is symplectic and second order. It matters WHICH integrator:
## both members step with semi-implicit Euler (`velocity += force / mass * delta;
## position += velocity * delta` in CelestialBody, `vel += acc; pos += vel` in nbody),
## and under Euler at any usable step the figure-eight loses the choreography inside one
## period — so the sheet would be measuring integrator error and reporting it as physics.
## The step is fixed, so every configuration is given the same amount of computation.
func _integrate(p_in: PackedFloat64Array, v_in: PackedFloat64Array) -> Array:
	var p: PackedFloat64Array = p_in.duplicate()
	var v: PackedFloat64Array = v_in.duplicate()
	var a: PackedFloat64Array = _accel(p)
	var t0: PackedVector3Array = PackedVector3Array()
	var t1: PackedVector3Array = PackedVector3Array()
	var t2: PackedVector3Array = PackedVector3Array()
	t0.append(Vector3(p[0], p[1], p[2]))
	t1.append(Vector3(p[3], p[4], p[5]))
	t2.append(Vector3(p[6], p[7], p[8]))
	for s in range(STEPS):
		for k in range(9):
			v[k] += a[k] * (H * 0.5)
			p[k] += v[k] * H
		a = _accel(p)
		for k in range(9):
			v[k] += a[k] * (H * 0.5)
		if (s + 1) % SAMPLE == 0:
			t0.append(Vector3(p[0], p[1], p[2]))
			t1.append(Vector3(p[3], p[4], p[5]))
			t2.append(Vector3(p[6], p[7], p[8]))
	return [t0, t1, t2]


## The runs of a track that lie inside the yard, with the crossings interpolated onto the
## boundary. A track that leaves and returns comes back as two runs, not one chord.
func _clip_runs(pts: PackedVector3Array) -> Array:
	var runs: Array = []
	var cur: PackedVector3Array = PackedVector3Array()
	for k in range(pts.size()):
		var q: Vector3 = pts[k]
		if q.length() <= CLIP_R:
			if cur.is_empty() and k > 0:
				cur.append(_boundary(q, pts[k - 1]))
			cur.append(q)
		elif not cur.is_empty():
			cur.append(_boundary(cur[cur.size() - 1], q))
			runs.append(cur)
			cur = PackedVector3Array()
	if not cur.is_empty():
		runs.append(cur)
	var out: Array = []
	for r in runs:
		var run: PackedVector3Array = r
		if run.size() >= 2:
			out.append(run)
	return out


func _boundary(inside_p: Vector3, outside_p: Vector3) -> Vector3:
	var lo: float = 0.0
	var hi: float = 1.0
	for _i in range(24):
		var mid: float = (lo + hi) * 0.5
		if inside_p.lerp(outside_p, mid).length() <= CLIP_R:
			lo = mid
		else:
			hi = mid
	return inside_p.lerp(outside_p, lo)


# ── building ───────────────────────────────────────────────────────────────────────────

func _build_yard(holder: Node3D) -> void:
	var plate := SurfaceTool.new()
	plate.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_disc(plate, PLATE_T, YARD_R)
	_commit(holder, "Plate", plate, C_PLATE, Color.BLACK)

	var rim := SurfaceTool.new()
	rim.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_band(rim, 0.0, PLATE_T, YARD_R)
	_add_ring(rim, YARD_R - RAIL_R, PLATE_T + 0.045, RAIL_R)
	_commit(holder, "Rim", rim, C_RIM, Color.BLACK)

	var cage := SurfaceTool.new()
	cage.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(4):
		var a: float = TAU * (float(i) + 0.5) / 4.0
		_add_box(cage, Vector3(cos(a) * POST_RING, YARD_H * 0.5, sin(a) * POST_RING),
			Vector3(POST_T, YARD_H, POST_T))
	_add_ring(cage, POST_RING, YARD_H - RAIL_R, RAIL_R)
	_commit(holder, "Cage", cage, C_POST, Color.BLACK)


func _build_figure(holder: Node3D, which: String, how: String) -> void:
	var state: Array = _initial(which)
	var p0: PackedFloat64Array = state[0]
	var v0: PackedFloat64Array = state[1]

	var tracks: Array = []
	if how != "start":
		tracks = _integrate(p0, v0)

	for i in range(3):
		var body := SurfaceTool.new()
		body.begin(Mesh.PRIMITIVE_TRIANGLES)
		_add_sphere(body, CENTRE + Vector3(p0[i * 3], p0[i * 3 + 1], p0[i * 3 + 2]),
			BODY_R, 10, 14)
		if tracks.size() == 3:
			var track: PackedVector3Array = tracks[i]
			for r in _clip_runs(track):
				var run: PackedVector3Array = r
				_add_tube(body, _lift(run), TUBE_R[i], 6)
		_commit(holder, "Body_" + str(i), body, _body_colour(i), _body_emission(i))

	if how == "drift":
		var nudged: PackedFloat64Array = p0.duplicate()
		nudged[0] += PERTURB
		var q0: PackedFloat64Array = _centred(nudged)
		var ghosts: Array = _integrate(q0, v0)
		var drift := SurfaceTool.new()
		drift.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(3):
			var ghost: PackedVector3Array = ghosts[i]
			for r in _clip_runs(ghost):
				var run_g: PackedVector3Array = r
				_add_tube(drift, _lift(run_g), DRIFT_R, 6)
		_commit(holder, "Drift", drift, C_DRIFT, E_DRIFT)


## Written out rather than indexed from a PackedColorArray const, which has no precedent
## in this codebase and could not be compile-checked here — the orchestrator holds the
## Godot lock, so this file was reviewed and never run. A const this bench cannot verify
## is not worth the three lines it saves.
func _body_colour(i: int) -> Color:
	if i == 0:
		return C_BODY_0
	if i == 1:
		return C_BODY_1
	return C_BODY_2


func _body_emission(i: int) -> Color:
	if i == 0:
		return E_BODY_0
	if i == 1:
		return E_BODY_1
	return E_BODY_2


## System space to yard space. One place, so the two runs cannot drift apart by an offset.
func _lift(pts: PackedVector3Array) -> PackedVector3Array:
	var out: PackedVector3Array = PackedVector3Array()
	for q in pts:
		out.append(CENTRE + q)
	return out


# ── mesh primitives ────────────────────────────────────────────────────────────────────

func _add_disc(st: SurfaceTool, y: float, radius: float) -> void:
	for i in range(YARD_SEGS):
		var a0: float = TAU * float(i) / float(YARD_SEGS)
		var a1: float = TAU * float(i + 1) / float(YARD_SEGS)
		_tri(st, Vector3(0.0, y, 0.0),
			Vector3(cos(a0) * radius, y, sin(a0) * radius),
			Vector3(cos(a1) * radius, y, sin(a1) * radius))


func _add_band(st: SurfaceTool, y0: float, y1: float, radius: float) -> void:
	for i in range(YARD_SEGS):
		var a0: float = TAU * float(i) / float(YARD_SEGS)
		var a1: float = TAU * float(i + 1) / float(YARD_SEGS)
		_quad(st,
			Vector3(cos(a0) * radius, y0, sin(a0) * radius),
			Vector3(cos(a1) * radius, y0, sin(a1) * radius),
			Vector3(cos(a1) * radius, y1, sin(a1) * radius),
			Vector3(cos(a0) * radius, y1, sin(a0) * radius))


func _add_ring(st: SurfaceTool, radius: float, y: float, thick: float) -> void:
	var path: PackedVector3Array = PackedVector3Array()
	for i in range(YARD_SEGS + 1):
		var a: float = TAU * float(i) / float(YARD_SEGS)
		path.append(Vector3(cos(a) * radius, y, sin(a) * radius))
	_add_tube(st, path, thick, 6)


func _add_tube(st: SurfaceTool, path: PackedVector3Array, r: float, sides: int) -> void:
	var n: int = path.size()
	if n < 2:
		return
	var rings: Array = []
	for i in range(n):
		var d: Vector3 = Vector3(1.0, 0.0, 0.0)
		if i == 0:
			d = path[1] - path[0]
		elif i == n - 1:
			d = path[n - 1] - path[n - 2]
		else:
			d = path[i + 1] - path[i - 1]
		if d.length() < 0.000001:
			d = Vector3(1.0, 0.0, 0.0)
		d = d.normalized()
		var up: Vector3 = Vector3(0.0, 1.0, 0.0)
		if absf(d.dot(up)) > 0.9:
			up = Vector3(1.0, 0.0, 0.0)
		var right: Vector3 = d.cross(up).normalized()
		var fwd: Vector3 = right.cross(d).normalized()
		var ring: PackedVector3Array = PackedVector3Array()
		for s in range(sides):
			var a: float = TAU * float(s) / float(sides)
			ring.append(path[i] + (right * cos(a) + fwd * sin(a)) * r)
		rings.append(ring)
	for i in range(n - 1):
		var r0: PackedVector3Array = rings[i]
		var r1: PackedVector3Array = rings[i + 1]
		for s in range(sides):
			var t: int = (s + 1) % sides
			_quad(st, r0[s], r1[s], r1[t], r0[t])


func _add_sphere(st: SurfaceTool, centre: Vector3, r: float, rings: int, segs: int) -> void:
	var pts: Array = []
	for i in range(rings + 1):
		var th: float = PI * float(i) / float(rings)
		var ring: PackedVector3Array = PackedVector3Array()
		for j in range(segs):
			var ph: float = TAU * float(j) / float(segs)
			ring.append(centre + Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph)) * r)
		pts.append(ring)
	for i in range(rings):
		var r0: PackedVector3Array = pts[i]
		var r1: PackedVector3Array = pts[i + 1]
		for j in range(segs):
			var k: int = (j + 1) % segs
			_quad(st, r0[j], r1[j], r1[k], r0[k])


## An axis-aligned box, twelve triangles, wound outward with explicit per-face normals.
func _add_box(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var p: PackedVector3Array = PackedVector3Array([
		at + Vector3(-h.x, -h.y, h.z), at + Vector3(h.x, -h.y, h.z),
		at + Vector3(h.x, h.y, h.z), at + Vector3(-h.x, h.y, h.z),
		at + Vector3(-h.x, -h.y, -h.z), at + Vector3(h.x, -h.y, -h.z),
		at + Vector3(h.x, h.y, -h.z), at + Vector3(-h.x, h.y, -h.z)])
	_quad(st, p[0], p[1], p[2], p[3])
	_quad(st, p[5], p[4], p[7], p[6])
	_quad(st, p[3], p[2], p[6], p[7])
	_quad(st, p[4], p[5], p[1], p[0])
	_quad(st, p[1], p[5], p[6], p[2])
	_quad(st, p[4], p[0], p[3], p[7])


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	var pts: PackedVector3Array = PackedVector3Array([a, b, c])
	for v in pts:
		st.set_normal(n)
		st.add_vertex(v)


## Two triangles wound a -> b -> c -> d with the normal taken from the winding, and every
## material is CULL_DISABLED besides: a tube generated from a parallel-transported frame
## can flip its winding at an inflection, and a surface photographed from behind is
## indistinguishable from a surface that was never built.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, b, c)
	_tri(st, a, c, d)


func _commit(holder: Node3D, mesh_name: String, st: SurfaceTool, c: Color,
		emission: Color) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = _mat(c, emission)
	holder.add_child(mi)


func _mat(c: Color, emission: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.1
	m.roughness = 0.55
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 0.55
	return m
