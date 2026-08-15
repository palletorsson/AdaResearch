extends Node3D
class_name AccordSwarm

## accord_swarm — four names for a three-number weight vector, and the question the
## family never asks: which of the four, if any, the rules would put back.
##
## THE FAMILY. Three artifacts declare an axis called `accord` and all three declare
## exactly the same four words in exactly the same order — the corpus's cleanest
## shared vocabulary, one word, one ladder, no dialect:
##
##   boid_manager     school | orb | lane | lattice   (boid_manager.gd, 20 m box, 100 boids)
##   boids_aquarium   school | orb | lane | lattice   (boids_aquarium.gd, 1 m tank, 30 boids)
##   swarm_hive       school | orb | lane | lattice   (swarm_hive.gd, 0.5 m hive, 20 boids)
##
## Three separate scenes, three separate scripts, three separate roots — checked, and
## none of the one-scene-many-names pattern here. All three ship `school` as the
## default: three of three.
##
## WHAT `accord` NAMES, in every member's own words: which of Reynolds' three rules
## the neighbourhood is actually obeying, and therefore what standing shape the flock
## holds. So the axis is four samples of a continuous 3-space — the (separation,
## alignment, cohesion) weight vector — with no boundary drawn anywhere between them.
##
## THE WEIGHTS, character for character out of the three files (sep / ali / coh):
##
##            boid_manager      boids_aquarium     swarm_hive
##   school   1.5 / 1.0 / 1.0   1.5 / 1.0 / 1.0    2.0 / 1.0 / 1.0
##   orb      0.4 / 0.6 / 4.5   0.0 / 0.0 / 4.5    0.4 / 0.6 / 4.5
##   lane     0.9 / 4.5 / 0.6   0.0 / 4.5 / 0.5    0.9 / 4.5 / 0.6
##   lattice  4.5 / 0.0 / 0.0   4.5 / 0.0 / 0.0    4.5 / 0.0 / 0.0
##
## `lattice` is UNANIMOUS. `orb` and `lane` split two against one, and `school` splits
## the other way. THE SPLIT IS NOT A TYPO AND IT IS THE FIRST FINDING: boids_aquarium's
## own comments record running the majority's numbers through its own update loop and
## watching them destroy the shape — "sep 0.30 -> 0.0 ... the bead fills the whole tank
## (0.88 m extent) within 1.1 s", "sep 0.8 -> 0.0 ... separation thickens the slab from
## 0.120 m to 0.201 m by 1.1 s and 0.487 m by 2.5 s". The two members that agree are the
## two that never ran the test: both deposit their arrangement and cap the speed so
## nothing has time to move.
##
## IS `lattice` EMERGENT OR IMPOSED? IMPOSED, and the code says so three separate ways.
##
##   1. All three DEPOSIT it. `_spawn_lattice` and `_deposit_lattice` write a regular
##      grid arithmetically. There is no branch anywhere in this family where a lattice
##      arises from the rules.
##   2. Separation alone cannot pick one out. In all three laws separation is purely
##      repulsive, monotone decreasing with distance, and zero past a cutoff. A purely
##      repulsive rule has no finite equilibrium spacing: EVERY arrangement past the
##      cutoff is a fixed point, so the fixed-point set is a continuum and a lattice is
##      one arbitrary member of it. Only the depositor can choose which.
##   3. Both members that comment on it say it outright. swarm_hive: "a regular grid
##      whose spacing is WIDER than separation_radius, so the rule is satisfied
##      everywhere". boids_aquarium: "At 0.20 m spacing and perception 0.15 nobody has a
##      neighbour, so the deposit is a fixed point TRIVIALLY."
##
## AND THE SAME IS TRUE OF `lane`, which nobody had noticed: boids_aquarium's own note
## says "at 0.168 m column spacing nothing is inside perception 0.15, so no rule acts on
## the sheet at all and it simply slides". Two of the four declared arrangements are held
## by nothing whatsoever. Their weights multiply a vector that is identically zero.
##
## THE RULE THAT COULD HAVE HELD THEM. Of Reynolds' three, separation (sum of d/|d|^2)
## and cohesion (mean p - p) depend on POSITION only and are conservative — they store
## energy, they never remove it. Alignment (mean v - v) depends on VELOCITY and is the
## family's only dissipative term; boids_aquarium calls it exactly that, "alignment acts
## as pure drag", in the comment explaining why it had to switch alignment OFF to keep
## the bead. So `lane` is the value that names the only rule capable of settling
## anything, and at lane's own spacing that rule never fires once.
##
## WHICH MAKES THE THESIS SHARPER THAN "some are attractors and some are transient":
## NOTHING HERE IS AN ATTRACTOR, because an attractor needs a sink and this family has
## none. `orb` is a CENTRE — thirty independent harmonic orbits about a fixed centroid —
## so a disturbed bead breathes forever and never settles. The other three do not even
## have that: no rule acts on them at all, and a disturbance is permanent.
##
## WHAT THIS BENCH DOES ABOUT IT. Thirty boids, seeded, in a 0.56 x 0.40 x 0.56 m cage,
## integrated with semi-implicit (symplectic) Euler at a fixed 1/120 s for 240 steps =
## exactly 2.000 s, under boids_aquarium's law — which is the one member whose triples
## were measured against the loop that runs them. Then `reading` asks three questions of
## the same flock:
##
##   flock    the thirty bodies where the 2.000 s left them, each oriented to its own
##            velocity. The family's condition, drawn.
##   weights  the same frame, plus one rod at every boid per rule, of length
##            weight x 0.030 m along that rule's own direction — DRAWN ONLY WHERE THE
##            RULE HAS A NEIGHBOUR TO ACT ON. At `lane` and at `lattice` nothing is
##            drawn, so the frame is its own `flock` frame to the byte. That identity
##            is the finding, not a spare check.
##   recover  the settled flock as dark site cubes, the same flock 2.000 s after an
##            identical impulse as the lit bodies, and a tether from each site to where
##            its body ended up. A bounded orbit and a dissolved sheet come apart here.
##
## Deterministic: one seeded RandomNumberGenerator per build (the global RNG is never
## touched), a disturbance built from thirty Fibonacci directions with no dice in it at
## all, no _process, no Timer, no noise, no texture that bakes on a worker thread.
##
## MEASURED ON A PYTHON REPLICA of this file, same constants, same integrator, at the
## settled state — boids carrying at least one neighbour: orb 30/30, school 0/30,
## lane 0/30, lattice 0/30.


## accord — which of Reynolds' three rules the neighbourhood is actually obeying, and
## therefore what standing shape the flock holds. The family's four words, the family's
## own order, and every triple below is boids_aquarium's, for the reason in `declines`.
##
##   school   sep 1.5 / ali 1.0 / coh 1.0, perception 0.112 m. The shipped balance,
##            two of three members' (boid_manager's Boid.gd defaults and the aquarium's
##            own .tscn). Thirty boids scattered through the middle 60% of the cage.
##            IT IS NOT A FLOCK: with separation unnormalised the equilibrium spacing
##            of these weights is far wider than any tank, so the cloud expands until
##            it hits glass and then bounces. 0 of 30 boids still have a neighbour at
##            2.000 s. That is the shipped default photographed honestly.
##   orb      sep 0.0 / ali 0.0 / coh 4.5, perception 0.112 m. Cohesion alone. A solid
##            0.148 m bead of centres on Fibonacci directions with orbital velocities
##            r*sqrt(coh) and the net momentum subtracted off, so the centroid does not
##            drift. Every boid sees every other (max pair distance 0.078 m). THE ONLY
##            VALUE WHERE ANY RULE ACTS.
##   lane     sep 0.0 / ali 4.5 / coh 0.5, perception 0.084 m. Alignment alone. A
##            0.470 x 0.016 x 0.470 m sheet, six columns by five rows by three layers,
##            every velocity +X so the alignment term is exactly zero. The closest pair
##            is 0.0944 m apart against a 0.084 m perception radius — a 12.4% margin —
##            and since every velocity is identical that spacing never changes. No rule
##            ever acts. The sheet slides 0.030 m in 2.000 s and that is all.
##   lattice  sep 4.5 / ali 0.0 / coh 0.0, perception 0.084 m. Separation alone, and the
##            one triple all three members agree on. A 5 x 3 x 2 grid spanning
##            0.448 x 0.240 x 0.246 m, spacing 0.112 / 0.120 / 0.246 m, each boid given
##            a 0.004 m/s drift so the ranks point thirty different ways. The closest
##            spacing is 0.112 m against perception 0.084, and the drift can close a
##            pair by at most 2 x 0.004 x 2.000 = 0.016 m, so nothing can come nearer
##            than 0.096 m. A 14% margin that is arithmetic rather than luck.
@export_enum("school", "orb", "lane", "lattice") var accord: String = "school":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not ACCORDS.has(picked):
			return                      ## an unreachable value keeps the standing flock
		accord = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## Which question is being asked of the same flock.
##
##   flock    the settled bodies and nothing else. Confounded on purpose: a reader
##            cannot tell from this frame whether an arrangement is held or merely left.
##   weights  the rig that asks WHAT IS ACTING. One rod per rule per boid, length =
##            declared weight x 0.030 m, direction = that rule's own accumulated term,
##            and NOTHING where the term is zero. A rod is the declaration; its presence
##            is whether the declaration reaches anything.
##   recover  the rig that asks WHAT COMES BACK. Every boid takes an impulse of exactly
##            0.10 m/s along its own Fibonacci direction — the same thirty vectors, in
##            the same order, with their mean removed so the total impulse is exactly
##            zero and no accord is pushed off centre. Then the same 2.000 s runs again.
##            Sites are where the flock was, bodies are where it is, tethers are the
##            difference. NOTE WHAT THE TETHERS DO NOT MEASURE: Reynolds' rules are
##            permutation-symmetric, so no rule can promise any boid its own place back.
##            What can come back is the SHAPE, and the shape is the envelope, not the
##            tether.
@export_enum("flock", "weights", "recover") var reading: String = "flock":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not READINGS.has(picked):
			return
		reading = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One accord, or all four in a row. NOT PART OF EITHER AXIS — capture_config_sweep
## unions the AABB across a spec's variants, so an all-accords value inside `accord`
## would frame every single cell against 2.7 m and photograph the flock as a smear.
## The registry fixture pins `single`. `ladder` is a design view; it runs four
## simulations instead of one and costs about four times the build.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const ACCORDS: PackedStringArray = ["school", "orb", "lane", "lattice"]
const READINGS: PackedStringArray = ["flock", "weights", "recover"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the flock ──────────────────────────────────────────────────────────────────────────
## THIRTY, which is boids_aquarium's `boid_count` and the only one of the three member
## populations that is a script default rather than a scene override. boid_manager's
## script says 50 and its .tscn ships 100; swarm_hive caps at 20. Thirty is also what
## keeps this honest as a still: O(n^2) over 30 agents for 480 steps is 432 000 pair
## evaluations, which returns in well under a second and cannot stall a capture.
const BOIDS: int = 30

## THE INTEGRATOR, stated because a claim about fixed points is a claim about a specific
## discretisation. Semi-implicit (symplectic) Euler: the velocity is updated first and
## the position is then advanced with the NEW velocity — which is what boids_aquarium's
## own _update_boids does, and which conserves the energy of a linear spring far better
## than explicit Euler would. Fixed step, no delta from the frame clock, so the flock is
## the same object however slow the machine is.
const DT: float = 1.0 / 120.0
const SETTLE_STEPS: int = 240        ## 2.000 s exactly
const RECOVER_STEPS: int = 240       ## 2.000 s exactly — the same window the deposit got
## The impulse. 0.10 m/s is under the 0.28 m/s speed cap at every accord's settled
## speeds, so the cap never eats any of it and all four flocks receive the identical
## disturbance. (school is the one place the cap can bite, and it is recorded in the
## registry note rather than smoothed over.)
const KICK: float = 0.10
## Reynolds, "Flocks, Herds and Schools of Fishes", 1987 — boids_aquarium's own
## DEPOSIT_SEED, reused. Only `school`'s cloud and `lattice`'s drift headings draw from
## it; every other number in this file is arithmetic.
const SEED: int = 1987
const GOLDEN_ANGLE: float = 2.399963229728653   ## PI * (3 - sqrt(5))

# ── the cage, and it is the stage: identical in all twelve cells ───────────────────────
## A 0.56 x 0.40 x 0.56 m box of wire at mid height, which is boids_aquarium's 1 m tank
## scaled to something that stands on a plinth. THE CAGE IS WHY A STANDING SHAPE IS
## LEGIBLE AT ALL: a flock in open air has nothing to be a shape against, and the
## bounce off these six walls is — as boids_aquarium's own truth line says — the only
## rule in the whole system that is genuinely external.
const DOM_X: float = 0.56
const DOM_Y: float = 0.40
const HX: float = DOM_X * 0.5
const HY: float = DOM_Y * 0.5
const HZ: float = DOM_X * 0.5
const CY: float = 0.30                ## cage centre height; interior runs y 0.10 .. 0.50
const V_MAX: float = 0.50 * DOM_X     ## 0.28 m/s — the aquarium's 0.5 in a 1.0 m tank

const BASE_HALF: float = 0.36
const BASE_W: float = 0.030
const BASE_T: float = 0.018
const POST_XZ: float = 0.345
const POST_S: float = 0.016
const POST_TOP: float = 0.58
const CAGE_S: float = 0.012

# ── the marks ──────────────────────────────────────────────────────────────────────────
## 0.070 x 0.026 x 0.026 m, and the size is boids_aquarium's hardest-won lesson rather
## than taste. Its first accord sheet drew thirty 0.008 x 0.008 x 0.025 m needles and
## measured lane == orb 1.68%, lattice == orb 1.88%, lane == lattice 2.13% — three
## declared values rendering as one picture, because 176 pixels of ink in a
## 25 600-pixel frame cannot hold a shape. It repaired to 0.032 x 0.032 x 0.080 m of
## tank and the three pairs went to 15.1 / 15.6 / 17.6%. This is that fraction of this
## cage. The body's long axis lies along the HEADING; the aquarium's lies along the
## looking_at UP vector instead, which is why its lane needles stand vertical — see
## `declines`.
const BODY_L: float = 0.070
const BODY_W: float = 0.026
const GHOST_S: float = 0.024
const TETHER_S: float = 0.009
const ROD_S: float = 0.010
## Metres of rod per unit of declared weight. 0.030 puts the heaviest weight in the
## family, 4.5, at 0.135 m — long enough that cohesion's inward rods pass through the
## bead and out the far side, which is the only way a rod pointing at the centre of a
## solid ball is visible at all.
const ROD_UNIT: float = 0.030
const LADDER_PITCH: float = 0.90

# ── the four rule sets ─────────────────────────────────────────────────────────────────
## (separation, alignment, cohesion), boids_aquarium's _accord_weights, verbatim.
const W_SCHOOL: Vector3 = Vector3(1.5, 1.0, 1.0)
const W_ORB: Vector3 = Vector3(0.0, 0.0, 4.5)
const W_LANE: Vector3 = Vector3(0.0, 4.5, 0.5)
const W_LATTICE: Vector3 = Vector3(4.5, 0.0, 0.0)
## WHO COUNTS AS A NEIGHBOUR is part of the rule and not a dial — the aquarium's phrase,
## and the whole argument turns on it. Its _accord_perception, as fractions of the tank.
const R_SCHOOL: float = 0.20 * DOM_X
const R_ORB: float = 0.20 * DOM_X
const R_LANE: float = 0.15 * DOM_X
const R_LATTICE: float = 0.15 * DOM_X

# ── the deposits, every fraction lifted from boids_aquarium and scaled to this cage ────
const ORB_R_FRAC: float = 0.070
const LANE_SLAB: Vector3 = Vector3(0.84, 0.040, 0.84)
const LANE_COLS: int = 6
const LANE_ROWS: int = 5
## 0.015 m/s, not the aquarium's 0.12 scaled. Its number was chosen for a 1.1 s shutter;
## this window is 2.000 s, and at anything faster the leading column reaches the +X wall
## inside the settle and the sheet starts bouncing. At 0.015 it travels 0.030 m and the
## leading column ends at 0.265 m of a 0.28 m half-box.
const LANE_SPEED: float = 0.015
const LAT_NX: int = 5
const LAT_NY: int = 3
const LAT_NZ: int = 2
const LAT_SPAN: Vector3 = Vector3(0.80, 0.60, 0.44)
## 0.004 m/s. THIS NUMBER IS WHAT MAKES THE `lattice` NULL ARITHMETIC RATHER THAN LUCK:
## the closest rank spacing is 0.112 m, two drifting boids close at most 2 x 0.004 x
## 2.000 = 0.016 m over the window, so the nearest any pair can come is 0.096 m against
## a 0.084 m perception radius. No neighbour is reachable at any seed. The aquarium's
## 0.03 scaled here would be 0.0168, which closes to 0.0784 and could put a neighbour in
## the frame — a null that held by chance is not a null.
const LAT_DRIFT: float = 0.004
const SCHOOL_BOX: float = 0.30       ## the middle 60% of the cage, as the aquarium spawns

# ── colour, and it is doing no work ────────────────────────────────────────────────────
## EVERY BODY IN THIS SHEET IS THE SAME COLOUR AT EVERY ACCORD, which is boids_aquarium's
## own rule ("Colour is not the axis: the same seeded palette walk in all four values")
## kept and tightened — this bench does not even walk a palette. Nothing anywhere is
## separated by hue, so the critic's per-channel rescue has nothing to rescue; if it ever
## fires on this sheet it is reporting a fault. The three rod colours differ in
## LUMINANCE by design (Rec.709 0.636 / 0.748 / 0.558) and, more to the point, in LENGTH,
## because length is the declared weight. In practice only one of the three is ever drawn
## in the whole sheet, which is itself the finding.
const C_RAIL: Color = Color(0.30, 0.31, 0.34)
const C_POST: Color = Color(0.34, 0.35, 0.38)
const C_CAGE: Color = Color(0.44, 0.46, 0.50)
const C_BODY: Color = Color(0.86, 0.85, 0.80)
const C_GHOST: Color = Color(0.28, 0.30, 0.36)
const C_TETHER: Color = Color(0.60, 0.61, 0.64)
const C_SEP: Color = Color(0.96, 0.58, 0.24)
const C_ALI: Color = Color(0.38, 0.86, 0.72)
const C_COH: Color = Color(0.62, 0.50, 0.94)

const SIGNS: PackedFloat32Array = [-1.0, 1.0]

var _built: Array[Node3D] = []
## Set while a whole config dictionary lands, so three keys cost one rebuild, not three.
var _bulk: bool = false

# Simulation state. Members rather than arguments so there is no question anywhere about
# whether a Packed array was copied on the way into a function.
var _pos: PackedVector3Array = PackedVector3Array()
var _vel: PackedVector3Array = PackedVector3Array()
var _settled_pos: PackedVector3Array = PackedVector3Array()
var _acc: PackedVector3Array = PackedVector3Array()
# The three rule terms at the boid last examined, plus its neighbour count. Written
# rather than returned, because a per-boid Array allocation inside a 432 000-iteration
# loop is the difference between a build and a stall.
var _t_sep: Vector3 = Vector3.ZERO
var _t_ali: Vector3 = Vector3.ZERO
var _t_coh: Vector3 = Vector3.ZERO
var _t_n: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rebuild()


## Called via call_deferred by GridInteractablesComponent, AFTER _ready(). The three
## keys land under _bulk so that a dictionary carrying all three costs ONE rebuild, and
## a dictionary that changes nothing costs none — which matters more here than in most
## artifacts, because a rebuild is up to 432 000 pair evaluations and the shipped path
## hands every curated artifact a config that names no axis at all.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	var was_accord: String = accord
	var was_reading: String = reading
	var was_layout: String = layout
	_bulk = true
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("accord"):
		accord = str(config_data["accord"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
	_bulk = false
	if accord == was_accord and reading == was_reading and layout == was_layout:
		return
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
		names = ACCORDS.duplicate()
	else:
		names.append(_pick(accord, ACCORDS, "school"))
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Cell_" + names[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_stage(holder)
		_build_flock(holder, names[i])


# ── the rule sets ──────────────────────────────────────────────────────────────────────

func _weights_for(acc: String) -> Vector3:
	match acc:
		"orb":
			return W_ORB
		"lane":
			return W_LANE
		"lattice":
			return W_LATTICE
	return W_SCHOOL


func _perception_for(acc: String) -> float:
	match acc:
		"orb":
			return R_ORB
		"lane":
			return R_LANE
		"lattice":
			return R_LATTICE
	return R_SCHOOL


# ── the deposits ───────────────────────────────────────────────────────────────────────

## A unit vector from the seeded stream. Never returns zero. The global RNG is never
## touched — seed()/randomize() from inside an artifact reseeds the whole process and
## poisons every other artifact in the same run.
func _rand_dir() -> Vector3:
	var v: Vector3 = Vector3(
		_rng.randf_range(-1.0, 1.0),
		_rng.randf_range(-1.0, 1.0),
		_rng.randf_range(-1.0, 1.0))
	if v.length() < 0.0001:
		return Vector3.FORWARD
	return v.normalized()


## The i-th of n directions on a Fibonacci sphere. Used twice: for orb's ball, and for
## the disturbance — where it replaces a random draw entirely, so that every accord
## receives exactly the same multiset of impulses in exactly the same order.
func _fib_dir(i: int, n: int) -> Vector3:
	var t: float = (float(i) + 0.5) / float(n)
	var y: float = 1.0 - 2.0 * t
	var ring: float = sqrt(maxf(0.0, 1.0 - y * y))
	var a: float = GOLDEN_ANGLE * float(i)
	return Vector3(cos(a) * ring, y, sin(a) * ring)


func _deposit(acc: String) -> void:
	_rng.seed = SEED
	_pos.resize(BOIDS)
	_vel.resize(BOIDS)
	_acc.resize(BOIDS)
	var centre: Vector3 = Vector3(0.0, CY, 0.0)
	match acc:
		"orb":
			_deposit_orb(centre)
		"lane":
			_deposit_lane(centre)
		"lattice":
			_deposit_lattice(centre)
		_:
			_deposit_school(centre)


## school — the shipped balance, spawned through the middle 60% of the cage at half the
## speed cap, exactly as boids_aquarium's _deposit_school does it.
func _deposit_school(centre: Vector3) -> void:
	var half: Vector3 = Vector3(SCHOOL_BOX * DOM_X, SCHOOL_BOX * DOM_Y, SCHOOL_BOX * DOM_X)
	for i in range(BOIDS):
		_pos[i] = centre + Vector3(
			_rng.randf_range(-half.x, half.x),
			_rng.randf_range(-half.y, half.y),
			_rng.randf_range(-half.z, half.z))
		_vel[i] = _rand_dir() * V_MAX * 0.5


## orb — a solid ball on Fibonacci directions with r = R * t^(1/3) so the interior fills
## evenly rather than piling on the surface, each boid given the orbital speed
## r * sqrt(cohesion) about its own axis, and the net momentum subtracted so the bead
## floats where it was put. Every line of this is boids_aquarium's _deposit_orb.
##
## AND IT IS AN EXACT STANDING CONFIGURATION, not an approximation: cohesion is linear
## in (centroid - p), so with every boid inside everyone else's perception each one runs
## an independent closed ellipse about a centroid that does not move. That is also
## precisely why it is a CENTRE and not an attractor.
func _deposit_orb(centre: Vector3) -> void:
	var radius: float = DOM_X * ORB_R_FRAC
	var omega: float = sqrt(maxf(W_ORB.z, 0.0001))
	var momentum: Vector3 = Vector3.ZERO
	for i in range(BOIDS):
		var t: float = (float(i) + 0.5) / float(BOIDS)
		var dir: Vector3 = _fib_dir(i, BOIDS)
		var r: float = radius * pow(t, 1.0 / 3.0)
		_pos[i] = centre + dir * r
		var t2: float = (float((i * 13) % BOIDS) + 0.5) / float(BOIDS)
		var y2: float = 1.0 - 2.0 * t2
		var ring2: float = sqrt(maxf(0.0, 1.0 - y2 * y2))
		var a2: float = GOLDEN_ANGLE * float(i) * 2.0
		var axis: Vector3 = Vector3(cos(a2) * ring2, y2, sin(a2) * ring2)
		var tang: Vector3 = dir.cross(axis)
		if tang.length() < 0.00001:
			tang = Vector3(-dir.z, 0.0, dir.x)
		if tang.length() < 0.00001:
			tang = Vector3.RIGHT
		var v: Vector3 = tang.normalized() * minf(r * omega, V_MAX)
		_vel[i] = v
		momentum += v
	var drift: Vector3 = momentum / float(BOIDS)
	for i in range(BOIDS):
		_vel[i] = _vel[i] - drift


## lane — a thin horizontal sheet, six columns by five rows across the floorplan and
## three layers through 0.016 m of centres, every velocity +X at the same speed.
## Identical velocities make the alignment term exactly zero, so the sheet is a fixed
## point that simply slides — and at 0.0944 m column spacing against a 0.084 m
## perception radius it is a fixed point for the stronger reason that nothing is looking.
func _deposit_lane(centre: Vector3) -> void:
	var slab: Vector3 = Vector3(LANE_SLAB.x * DOM_X, LANE_SLAB.y * DOM_Y, LANE_SLAB.z * DOM_X)
	var cols: float = float(maxi(LANE_COLS - 1, 1))
	var rows: float = float(maxi(LANE_ROWS - 1, 1))
	for i in range(BOIDS):
		var ix: int = i % LANE_COLS
		var iz: int = (i / LANE_COLS) % LANE_ROWS
		var layer: float = float(i % 3) * 0.5
		_pos[i] = centre + Vector3(
			-slab.x * 0.5 + slab.x * float(ix) / cols,
			-slab.y * 0.5 + slab.y * layer,
			-slab.z * 0.5 + slab.z * float(iz) / rows)
		_vel[i] = Vector3(LANE_SPEED, 0.0, 0.0)


## lattice — 5 x 3 x 2 sites on an even grid with a slow drift, so the bodies point
## thirty different ways rather than all one way (that is lane's picture, and a frozen
## lattice would put every mesh on the same basis). Rank spacing sits outside perception
## by construction and the drift cannot close it — see LAT_DRIFT.
func _deposit_lattice(centre: Vector3) -> void:
	var span: Vector3 = Vector3(LAT_SPAN.x * DOM_X, LAT_SPAN.y * DOM_Y, LAT_SPAN.z * DOM_X)
	var sx: float = span.x / float(maxi(LAT_NX - 1, 1))
	var sy: float = span.y / float(maxi(LAT_NY - 1, 1))
	var sz: float = span.z / float(maxi(LAT_NZ - 1, 1))
	var sites: int = LAT_NX * LAT_NY * LAT_NZ
	for i in range(BOIDS):
		var s: int = i % sites
		var ix: int = s % LAT_NX
		var iy: int = (s / LAT_NX) % LAT_NY
		var iz: int = s / (LAT_NX * LAT_NY)
		_pos[i] = centre + Vector3(
			-span.x * 0.5 + sx * float(ix),
			-span.y * 0.5 + sy * float(iy),
			-span.z * 0.5 + sz * float(iz))
		_vel[i] = _rand_dir() * LAT_DRIFT


# ── the law ────────────────────────────────────────────────────────────────────────────

## THE THREE RULES, boids_aquarium's _update_boids, unnormalised and with ONE radius for
## all three — which is the member's own choice and is load-bearing. boid_manager uses
## two radii (perception for align and cohere, avoid_radius for separate) and swarm_hive
## uses three, and under swarm_hive's radii — cohesion 2.5 m around a 0.5 m hive —
## everybody always sees everybody and no arrangement can ever fall out of range. The
## family disagrees about who counts as a neighbour, and the disagreement decides
## whether the rules act at all.
func _terms(i: int, r2: float) -> void:
	_t_sep = Vector3.ZERO
	_t_ali = Vector3.ZERO
	_t_coh = Vector3.ZERO
	_t_n = 0
	var p: Vector3 = _pos[i]
	for j in range(BOIDS):
		if j == i:
			continue
		var d: Vector3 = p - _pos[j]
		var d2: float = d.length_squared()
		if d2 >= r2:
			continue
		_t_n += 1
		if d2 > 0.000001:
			_t_sep += d / d2
		_t_ali += _vel[j]
		_t_coh += _pos[j]
	if _t_n == 0:
		return
	var inv: float = 1.0 / float(_t_n)
	_t_ali = _t_ali * inv - _vel[i]
	_t_coh = _t_coh * inv - p


## Semi-implicit Euler at a fixed step. THE SPEED CAP IS THE ONLY THING THAT MAKES THE
## unnormalised separation term stable: two boids deposited 0.0148 m apart in `school`
## produce about 100 m/s^2, which the cap swallows. It is also the only place in the
## whole law where energy can leave the system, and it does not fire once at orb.
func _integrate(w: Vector3, r: float, steps: int) -> void:
	var r2: float = r * r
	var centre: Vector3 = Vector3(0.0, CY, 0.0)
	for _s in range(steps):
		for i in range(BOIDS):
			_terms(i, r2)
			_acc[i] = _t_sep * w.x + _t_ali * w.y + _t_coh * w.z
		for i in range(BOIDS):
			var v: Vector3 = _vel[i] + _acc[i] * DT
			if v.length() > V_MAX:
				v = v.normalized() * V_MAX
			var o: Vector3 = (_pos[i] + v * DT) - centre
			if absf(o.x) > HX:
				o.x = signf(o.x) * HX
				v.x = -v.x
			if absf(o.y) > HY:
				o.y = signf(o.y) * HY
				v.y = -v.y
			if absf(o.z) > HZ:
				o.z = signf(o.z) * HZ
				v.z = -v.z
			_pos[i] = centre + o
			_vel[i] = v


## The disturbance. No dice: thirty Fibonacci directions with their own mean subtracted,
## so the impulses sum to zero to within float error and the flock's centroid cannot be
## pushed anywhere. Every accord gets the same thirty vectors in the same order, which
## is what makes the four recoveries comparable at all.
func _disturb() -> void:
	var mean: Vector3 = Vector3.ZERO
	for i in range(BOIDS):
		mean += _fib_dir(i, BOIDS)
	mean = mean / float(BOIDS)
	for i in range(BOIDS):
		_vel[i] = _vel[i] + (_fib_dir(i, BOIDS) - mean) * KICK


# ── building ───────────────────────────────────────────────────────────────────────────

func _build_stage(holder: Node3D) -> void:
	var rails := SurfaceTool.new()
	rails.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s in SIGNS:
		_add_box(rails, Vector3(s * (BASE_HALF - BASE_W * 0.5), BASE_T * 0.5, 0.0),
			Vector3(BASE_W, BASE_T, BASE_HALF * 2.0))
		_add_box(rails, Vector3(0.0, BASE_T * 0.5, s * (BASE_HALF - BASE_W * 0.5)),
			Vector3(BASE_HALF * 2.0, BASE_T, BASE_W))
	_commit(holder, "BaseFrame", rails, C_RAIL, 0.85, 0.0)

	var posts := SurfaceTool.new()
	posts.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sx in SIGNS:
		for sz in SIGNS:
			_add_box(posts, Vector3(sx * POST_XZ, POST_TOP * 0.5, sz * POST_XZ),
				Vector3(POST_S, POST_TOP, POST_S))
			_add_rod(posts, Vector3(sx * POST_XZ, CY, sz * POST_XZ),
				Vector3(sx * HX, CY, sz * HZ), CAGE_S)
	_commit(holder, "Posts", posts, C_POST, 0.80, 0.0)

	var cage := SurfaceTool.new()
	cage.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sy in SIGNS:
		for sz in SIGNS:
			_add_box(cage, Vector3(0.0, CY + sy * HY, sz * HZ),
				Vector3(HX * 2.0, CAGE_S, CAGE_S))
			_add_box(cage, Vector3(sz * HX, CY + sy * HY, 0.0),
				Vector3(CAGE_S, CAGE_S, HZ * 2.0))
	for sx in SIGNS:
		for sz in SIGNS:
			_add_box(cage, Vector3(sx * HX, CY, sz * HZ),
				Vector3(CAGE_S, HY * 2.0, CAGE_S))
	_commit(holder, "Cage", cage, C_CAGE, 0.55, 0.05)


func _build_flock(holder: Node3D, acc: String) -> void:
	var w: Vector3 = _weights_for(acc)
	var r: float = _perception_for(acc)
	_deposit(acc)
	_integrate(w, r, SETTLE_STEPS)
	_settled_pos = _pos.duplicate()

	if reading == "recover":
		_disturb()
		_integrate(w, r, RECOVER_STEPS)
		var sites := SurfaceTool.new()
		sites.begin(Mesh.PRIMITIVE_TRIANGLES)
		var tethers := SurfaceTool.new()
		tethers.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(BOIDS):
			_add_box(sites, _settled_pos[i], Vector3(GHOST_S, GHOST_S, GHOST_S))
			_add_rod(tethers, _settled_pos[i], _pos[i], TETHER_S)
		_commit(holder, "Sites", sites, C_GHOST, 0.90, 0.0)
		_commit(holder, "Tethers", tethers, C_TETHER, 0.70, 0.0)

	var bodies := SurfaceTool.new()
	bodies.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(BOIDS):
		_add_obox(bodies, _pos[i], _basis_for(_vel[i]),
			Vector3(BODY_W * 0.5, BODY_W * 0.5, BODY_L * 0.5))
	_commit(holder, "Bodies", bodies, C_BODY, 0.55, 0.0)

	if reading != "weights":
		return
	# THE ONE PLACE THIS SHEET BITES ITSELF. A rod is drawn only where the rule it names
	# has a neighbour to act on; where nothing acts, nothing is drawn, and the frame is
	# its own `flock` frame to the byte.
	var sep_st := SurfaceTool.new()
	sep_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ali_st := SurfaceTool.new()
	ali_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var coh_st := SurfaceTool.new()
	coh_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r2: float = r * r
	for i in range(BOIDS):
		_terms(i, r2)
		if _t_n == 0:
			continue
		_add_weight_rod(sep_st, _pos[i], _t_sep, w.x)
		_add_weight_rod(ali_st, _pos[i], _t_ali, w.y)
		_add_weight_rod(coh_st, _pos[i], _t_coh, w.z)
	_commit(holder, "RodSeparation", sep_st, C_SEP, 0.45, 0.0)
	_commit(holder, "RodAlignment", ali_st, C_ALI, 0.45, 0.0)
	_commit(holder, "RodCohesion", coh_st, C_COH, 0.45, 0.0)


## One rod: the declared weight as a length, that rule's own accumulated term as a
## direction. A zero weight or a zero term draws nothing, which is the point.
##
## THE LENGTH IS CLIPPED TO THE CAGE, and the clip is a guarantee rather than a
## behaviour: it never fires in any of the twelve cells, because the only value that
## draws rods at all is orb, whose 0.135 m rods reach 0.177 m of a 0.28 m half-box. It
## exists so that the union AABB is the stage by construction and not by arithmetic
## that happened to work out.
func _add_weight_rod(st: SurfaceTool, origin: Vector3, term: Vector3, weight: float) -> void:
	if weight <= 0.0:
		return
	if term.length() < 0.000000001:
		return
	var dir: Vector3 = term.normalized()
	var want: float = weight * ROD_UNIT
	_add_rod(st, origin, origin + dir * minf(want, _cage_clip(origin, dir)), ROD_S)


## How far a ray from `origin` along `dir` can run before it leaves the cage.
func _cage_clip(origin: Vector3, dir: Vector3) -> float:
	var o: Vector3 = origin - Vector3(0.0, CY, 0.0)
	var best: float = 10.0
	best = minf(best, _axis_clip(o.x, dir.x, HX))
	best = minf(best, _axis_clip(o.y, dir.y, HY))
	best = minf(best, _axis_clip(o.z, dir.z, HZ))
	return maxf(best, 0.0)


func _axis_clip(o: float, d: float, h: float) -> float:
	if absf(d) < 0.000001:
		return 10.0
	if d > 0.0:
		return (h - o) / d
	return (-h - o) / d


# ── mesh primitives ────────────────────────────────────────────────────────────────────

## The basis a body wears. The long axis is +Z of the returned basis and it lies along
## the HEADING.
func _basis_for(heading: Vector3) -> Basis:
	var f: Vector3 = heading
	if f.length() < 0.000001:
		f = Vector3.RIGHT
	f = f.normalized()
	var up: Vector3 = Vector3.UP
	if absf(f.y) > 0.99:
		up = Vector3.RIGHT
	var side: Vector3 = up.cross(f).normalized()
	return Basis(side, f.cross(side), f)


func _add_box(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	_add_obox(st, at, Basis.IDENTITY, size * 0.5)


## An oriented box, twelve triangles, wound outward with explicit per-face normals.
func _add_obox(st: SurfaceTool, at: Vector3, b: Basis, h: Vector3) -> void:
	var p: PackedVector3Array = PackedVector3Array([
		at + b * Vector3(-h.x, -h.y, h.z), at + b * Vector3(h.x, -h.y, h.z),
		at + b * Vector3(h.x, h.y, h.z), at + b * Vector3(-h.x, h.y, h.z),
		at + b * Vector3(-h.x, -h.y, -h.z), at + b * Vector3(h.x, -h.y, -h.z),
		at + b * Vector3(h.x, h.y, -h.z), at + b * Vector3(-h.x, h.y, -h.z)])
	_quad(st, p[0], p[1], p[2], p[3], at)
	_quad(st, p[5], p[4], p[7], p[6], at)
	_quad(st, p[3], p[2], p[6], p[7], at)
	_quad(st, p[4], p[5], p[1], p[0], at)
	_quad(st, p[1], p[5], p[6], p[2], at)
	_quad(st, p[4], p[0], p[3], p[7], at)


## A square-section rod from a to b. Sub-millimetre segments are skipped: a rod of zero
## length has no basis, and a tether whose two ends coincide is exactly the case that
## `orb` produces when a boid comes back to where it started.
func _add_rod(st: SurfaceTool, a: Vector3, b: Vector3, s: float) -> void:
	var d: Vector3 = b - a
	var l: float = d.length()
	if l < 0.0002:
		return
	_add_obox(st, (a + b) * 0.5, _basis_for(d), Vector3(s * 0.5, s * 0.5, l * 0.5))


## Two triangles a -> b -> c -> d, with the normal taken from the winding and FLIPPED if
## it points back at `inside`. Every material here is CULL_DISABLED as well, because
## belt and braces is what wave 13 cost.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		inside: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	var mid: Vector3 = (a + b + c + d) * 0.25
	if n.dot(mid - inside) < 0.0:
		n = -n
	var tri: PackedVector3Array = PackedVector3Array([a, b, c, a, c, d])
	for vtx in tri:
		st.set_normal(n)
		st.add_vertex(vtx)


## SurfaceTool.commit() on a tool that was begun and never given a vertex is not a mesh
## with no surfaces, it is an error in the log — and in this artifact three of the six
## optional tools are legitimately empty in most cells.
func _commit(holder: Node3D, mesh_name: String, st: SurfaceTool, c: Color,
		rough: float, metal: float) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = m
	holder.add_child(mi)
