extends Node3D
class_name PostureBench

## posture_bench — four vocabularies for one word, built on one body, and the two of them
## that turn out to be the same six numbers.
##
## THE FAMILY, and it is the least agreed axis left in the corpus. Four artifacts declare
## an axis called `posture` and NO TWO OF THEM SHARE A VALUE LIST:
##
##   armadillo_eggling   ball | walker                          default ball
##   spring_hopper       cycle | drawn | laden | solid           default cycle
##   tentacle_placer     cycle | sentry | stoop | coil | cast    default cycle
##   qfep_formula_3d     line | stack | arc | ring               default line
##
## Fifteen words, four scenes, four scripts, one overlap: `cycle`, in two of them.
##
## WHAT THE BRIEF SAID AND WHAT THE CODE SAYS, and the correction is the finding. The
## brief said these are four different KINDS of thing — a defence STATE, a mechanical
## LOAD, an animal STANCE and a text LAYOUT, only three of which are about a body. Read
## against the sources that is half right, and the wrong half is the interesting half:
##
##   armadillo_eggling's ball/walker IS NOT A BINARY. It is the two ENDPOINTS of one
##   float. `_fold_amount` runs 0..1 and armadillo_droideka._apply_fold_pose() drives
##   EVERY hinge off it linearly — scutes at (scute_open + fan) * fold, equator rings at
##   +-ring_open * fold, the core at core_raise_height * fold, and each leg at
##   lerp(leg_folded_hip_degrees, leg_deployed_hip_degrees, fold) with the same lerp on
##   the knee. Two words, one scalar, sampled at its ends.
##
##   spring_hopper's drawn/laden/solid is ALSO one float — `_rest`, pinned at -0.25, 0.40
##   and 0.90 — driving the coil's Y-scale, the head height and the head's squash off the
##   same number. Two words, one scalar, sampled in the middle.
##
##   SO THE STATE AND THE LOAD ARE THE SAME MECHANISM. `_fold_amount` and `_compression`
##   are one variable wearing two nouns, and the only difference between the two
##   vocabularies is WHERE ON IT each member decided to stand. That is not four kinds of
##   thing. It is three: a SCALAR (armadillo, spring_hopper), a TARGET POINT
##   (tentacle_placer solves a chain to a Vector3), and an ARRANGEMENT (qfep_formula_3d
##   distributes N items along a path).
##
## AND `cycle` MEANS THE SAME THING IN BOTH MEMBERS THAT USE IT, which was worth checking
## and is worth writing down. In spring_hopper it is "sentinel: the state machine keeps
## sole ownership of _compression. Shipped." In tentacle_placer it is "the shipped ritual
## ... Wall-clock dependent, exactly as it ships. THE DEFAULT", and `_is_pinned()` returns
## false for it by name. Both are: DO NOT PIN THIS BODY, hand it back to the clock, and
## both are their member's shipped default. Same meaning to the letter.
##
## WHICH MAKES `cycle` AN ALL-RUNGS VALUE IN THE TIME DOMAIN, and that is why it is not in
## this bench. A still of `cycle` is a sample of the WHOLE axis taken by the shutter, which
## is exactly the fault the all-rungs rule exists to stop, moved from space into time. The
## two are not equally bad and the difference is measurable: spring_hopper's cycle wobbles
## inside _compression = 0.05 +- 0.05, a bounded neighbourhood of `extended` — its own
## header says an "extended" rung "would photograph as a near-duplicate of cycle" — while
## tentacle_placer's cycle runs the entire 7 m ritual, rise, place, descend, three times.
## One is nearly a pose; the other is the union of every pose. Both are declined.
##
## WHAT THIS BENCH IS. One articulated body: a mount, and a chain of SIX equal links on
## SIX hinges, bending in one vertical plane, standing on a plate inside a four-post cage.
## A posture is SIX NUMBERS — one angle per hinge, in degrees — and nothing else. There is
## no root rotation, because none of the four members declares one: qfep arranges in the
## artifact's local frame, the tentacle solves in its own, and neither axis controls how
## the artifact is mounted. Strip the mount, which is what putting four vocabularies on one
## body forces you to do, and the words can be compared.
##
## THE FIRST THING THAT FALLS OUT, and it is the designed null:
##
##   qfep_formula_3d `line`   = _arrange_curved at sweep 0 = no turn at any item
##   tentacle_placer `sentry` = target (0, 6, 0), and 6.0 m IS the chain's exact length,
##                              so the solver takes the UNREACHABLE branch, whose comment
##                              reads "Unreachable — straighten the chain at the target."
##
##   Both are [0, 0, 0, 0, 0, 0]. A LAYOUT word and a STANCE word, from two artifacts that
##   share no vocabulary and no author's intent, name the same body to the byte.
##
## THE SECOND, and it is the pre-registered closest pair: `arc` (qfep, sweep 110 degrees,
## so 18.33 degrees per hinge) against `solid` (spring, compression 0.90, which under that
## member's own coil-height law comes out at 20.93 degrees per hinge). Two independent
## derivations — a typographic sweep and a spring constant — landing 2.60 degrees apart at
## every hinge. Neither number was chosen; both were read off the members.
##
## Deterministic. Every angle is arithmetic or a bisection on a monotone function; there is
## no RandomNumberGenerator, no noise, no _process, no Timer, no tween. Two builds of one
## cell are the same mesh.


# ── the two axes ───────────────────────────────────────────────────────────────────────

## WHICH POSE THE BODY IS HOLDING. Ten values: the union of the four vocabularies that can
## honestly be built as six hinge angles, at least two from every member. Each value's
## KIND, its member, and its arithmetic:
##
##   ball    STATE  · armadillo_eggling. _fold_amount = 0. The member's folded angles, hip
##           and knee alternating down the chain: -116, +132, -116, +132, -116, +132, from
##           armadillo_droideka.gd's leg_folded_hip_degrees and leg_folded_knee_degrees. A
##           packed zigzag: 0.145 x 0.169 m, the most compact body in the sheet.
##   walker  STATE  · armadillo_eggling. _fold_amount = 1. The same two hinges at the other
##           end: +34, -26, +34, -26, +34, -26 (leg_deployed_*). Net +8 per pair, so the
##           chain leans out and up: 0.197 x 0.356 m.
##   laden   LOAD   · spring_hopper, _rest = 0.40. Uniform 12.78 deg per hinge. Derived,
##           not chosen: the member's coil scales its height by 1 - (1 - _coil_floor) * c
##           with the shipped floor 0.15, so c = 0.40 leaves 0.66 of full height, and a
##           chain of rigid links can only lose height by BENDING. Bisect for the uniform
##           angle whose chain height is 0.66 of straight. 0.275 x 0.277 m.
##   solid   LOAD   · spring_hopper, _rest = 0.90. Same law, 0.235 of full height, uniform
##           20.93 deg per hinge. 0.328 x 0.157 m.
##   sentry  STANCE · tentacle_placer, target (0, 6.0, 0). The chain is 6.0 m long in that
##           member and the target is at exactly 6.0 m, so the solver's unreachable branch
##           straightens it. [0, 0, 0, 0, 0, 0]. 0.000 x 0.420 m.
##   coil    STANCE · tentacle_placer, target (0, 2.1, 0.4) scaled by this chain's length
##           ratio 0.070. Solved: -96.40 then 42.87 x5. A tight left-hand curl that ends
##           back over its own mount. 0.167 x 0.188 m.
##   cast    STANCE · tentacle_placer, target (0, 2.4, 5.2) scaled the same way — 95.5 per
##           cent of the chain's own length, the longest reach in the sheet, and it is the
##           member's number UNCAPPED. The cage was widened to hold it rather than the reach
##           being capped to fit the cage. Solved: 39.76 then 10.19 x5. 0.364 x 0.169 m.
##   line    LAYOUT · qfep_formula_3d, _arrange_curved sweep 0. [0, 0, 0, 0, 0, 0].
##           IDENTICAL TO `sentry`, by construction, and registered as the designed null.
##   arc     LAYOUT · qfep_formula_3d, sweep deg_to_rad(110). Total turn 110 degrees over
##           six hinges = 18.33 each. 0.324 x 0.183 m.
##   ring    LAYOUT · qfep_formula_3d, sweep TAU. 60.00 degrees per hinge, six hinges, so
##           the chain closes on itself and the sixth link ends exactly at the mount it
##           left — tip distance 0.000 m, the only zero in the sheet. That is what
##           sweep = TAU means for a body. 0.121 x 0.140 m. 0.121 x 0.140 m.
##
## THE THREE WORDS THAT ARE NOT HERE are in the registry `declines` with their arithmetic:
## `cycle` (twice — the all-rungs sentinel), `drawn` (a rigid chain has no tension), and
## `stack` (a translation, not a curvature — the one qfep value that is not a chain pose).
## `stoop` is declined for balance, not for truth.
@export_enum("ball", "walker", "laden", "solid", "sentry", "coil", "cast", "line", "arc", "ring") var posture: String = "ball":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not POSTURES.has(picked):
			return                      ## an unreachable value keeps the standing figure
		posture = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## WHAT IS DRAWN OF THAT POSE. Three readings of one pose vector, not three styles.
##
##   body      the limb itself: six tapered links and seven collars, real geometry. What
##             the four members all draw and the only reading any of them has.
##   joints    the same chain reduced to thin rods, and at every hinge a solid SECTOR of
##             material spanning that hinge's own angle, all six at one radius. The pose
##             stops being a silhouette and becomes six quantities standing up. A hinge at
##             zero draws nothing, so `line` and `sentry` show six absences.
##   envelope  the limb is not drawn at all. Its place is taken by the convex hull of the
##             seven joint centres, grown by the limb's own half-width and extruded through
##             its depth: the volume the body occupies, as one solid. THIS READING REFUTES
##             THE OBVIOUS CLAIM ABOUT IT — a defence state is supposed to minimise the
##             volume occupied, and `ball` does not. Measured on a replica of this file, the
##             SMALLEST hull in the sheet belongs to `line` and `sentry`, straight sticks at
##             0.0135 m2, against `ball` at 0.0219 and `ring` at 0.0215; the largest is
##             `solid` at 0.0402. A straight arm occupies almost no volume and is maximally
##             exposed. What a curl minimises is REACH — `ball` is 0.145 x 0.169 m where
##             `line` is 0.000 x 0.420 — and reach is not hull. The full ladder is in the
##             registry note and it is this reading's whole argument.
@export_enum("body", "joints", "envelope") var reading: String = "body":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not READINGS.has(picked):
			return
		reading = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One figure, or all ten postures in a row. NOT PART OF EITHER AXIS, and it is not part of
## either axis for the reason waves 13-19 keep paying for: capture_config_sweep unions the
## AABB across a spec's variants, so an all-postures value declared inside `posture` would
## frame every single cell against eight metres and photograph a 26 mm link as a hair. The
## registry fixture pins `single`; `ladder` is a design view and nothing else.
##
## NAME COLLISION, DELIBERATELY LEFT AND SAID OUT LOUD: this export is called `layout`, and
## LAYOUT is also the label this bench gives to qfep_formula_3d's four contributions to the
## `posture` axis (line, stack, arc, ring). They are unrelated. `layout` here means "how
## many figures stand on the plate"; LAYOUT there means "an arrangement of items along a
## path". No posture value reads this export and this export changes no posture value.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const POSTURES: PackedStringArray = ["ball", "walker", "laden", "solid", "sentry",
	"coil", "cast", "line", "arc", "ring"]
const READINGS: PackedStringArray = ["body", "joints", "envelope"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]


# ── the body ───────────────────────────────────────────────────────────────────────────
## SIX links on SIX hinges. Six because it is the smallest count that can close a ring at a
## whole number of degrees per hinge (360 / 6 = 60), which is what qfep's `ring` needs, and
## because armadillo's hip/knee alternation wants an even count.
const JOINTS: int = 6
const SEG: float = 0.070               ## link length; the chain is 6 x 0.070 = 0.420 m
const CHAIN_L: float = 0.420

## The mount. A post, because tentacle_placer stands its arm on a pedestal and because the
## `ring` pose hangs 0.105 m BELOW its own hinge — a chain that closes on itself has to
## have somewhere to close.
const HUB_Y: float = 0.224             ## world height of hinge 0 = PLATE_T + MOUNT_H
const MOUNT_H: float = 0.200
const MOUNT_W: float = 0.052

## Limb section, tapering root to tip so the thing reads as a limb and not as a graph.
const LIMB_W0: float = 0.032
const LIMB_W1: float = 0.018
const LIMB_D0: float = 0.028
const LIMB_D1: float = 0.016
const COLLAR_K: float = 1.22           ## collars this much wider than their link

## The `joints` reading.
const ROD_W: float = 0.010
const ROD_D: float = 0.010
const ARC_R: float = 0.034             ## every sector at ONE radius, so six angles compare
const ARC_D: float = 0.010
const ARC_STEP_DEG: float = 6.0

## The `envelope` reading. The hull is grown by the limb's own half-width so a straight
## chain still has a body — a degenerate hull would publish two empty frames.
const HULL_GROW: float = 0.015
const HULL_D: float = 0.030

# ── the stage, identical to the millimetre in all thirty cells ─────────────────────────
## THE FOUR CORNER POSTS ARE WHY THE AABB NEVER MOVES, and here they carry more than they
## did on cohort_bench, because this figure changes size by a factor of three: `ball`
## occupies 0.145 x 0.169 m and `line` occupies 0.000 x 0.420 m. Without a fixed cage the
## camera would step between cells and every measured pair would carry a framing difference
## it did not earn. Clearances, measured on the replica across all ten poses and all three
## readings: the tallest limb tops out 0.040 m below the posts and the tallest hull 0.025 m
## below them; the longest reach stops 0.021 m short of a post in x and its grown hull 0.006
## m short; the lowest thing any pose draws — `ring`, which hangs below its own hinge — sits
## 0.080 m above the plate. Nothing either axis draws can touch the world box.
const PLATE_HX: float = 0.40
const PLATE_HZ: float = 0.18
const PLATE_T: float = 0.024
const CAGE_H: float = 0.660            ## above the plate top; post tops at y = 0.684
const POST_W: float = 0.024
const POST_X: float = 0.385
const POST_Z: float = 0.165

## The members' own numbers, named so the derivation is checkable against the sources.
const ARM_HIP_FOLDED: float = -116.0   ## armadillo_droideka.gd leg_folded_hip_degrees
const ARM_KNEE_FOLDED: float = 132.0   ## leg_folded_knee_degrees
const ARM_HIP_DEPLOYED: float = 34.0   ## leg_deployed_hip_degrees
const ARM_KNEE_DEPLOYED: float = -26.0 ## leg_deployed_knee_degrees
const SPRING_FLOOR: float = 0.15       ## spring_hopper.gd STOCK_COIL_FLOOR
const SPRING_LADEN: float = 0.40       ## _apply_posture() "laden"
const SPRING_SOLID: float = 0.90       ## _apply_posture() "solid"
const TENT_CHAIN_M: float = 6.0        ## tentacle_placer's own chain length, metres
const TENT_SENTRY: Vector2 = Vector2(0.0, 6.0)   ## (reach, height) of POSTURE_TARGETS
const TENT_COIL: Vector2 = Vector2(0.4, 2.1)
const TENT_CAST: Vector2 = Vector2(5.2, 2.4)
const QFEP_ARC_SWEEP: float = 110.0    ## qfep_formula_3d.gd deg_to_rad(110.0)
const QFEP_RING_SWEEP: float = 360.0   ## TAU

# ── colour ─────────────────────────────────────────────────────────────────────────────
## Rec.709 luminance written down so the greyscale reading is checkable rather than hoped:
## plate 0.180, cage 0.309, mount 0.432, limb 0.813, rod 0.561, sector 0.885, hull 0.720.
## Nothing that must be told apart in one frame sits within 0.10 of anything else, and no
## pair in this sheet is separated by hue at constant brightness — the critic measures
## luminance first and its colour rescue firing here would be reporting a fault.
const C_PLATE: Color = Color(0.17, 0.18, 0.21)
const C_CAGE: Color = Color(0.30, 0.31, 0.34)
const C_MOUNT: Color = Color(0.45, 0.43, 0.40)
const C_LIMB: Color = Color(0.86, 0.82, 0.60)
const C_ROD: Color = Color(0.55, 0.56, 0.60)
const C_SECTOR: Color = Color(0.95, 0.90, 0.55)
const C_HULL: Color = Color(0.70, 0.72, 0.78)

const LADDER_PITCH: float = 0.86
## Iterated rather than written inline, so no loop variable is left untyped.
const SIGNS: PackedFloat32Array = [-1.0, 1.0]

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
	if config_data.has("posture"):
		posture = str(config_data["posture"])
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
		names = POSTURES.duplicate()
	else:
		names.append(_pick(posture, POSTURES, "ball"))
	var how: String = _pick(reading, READINGS, "body")
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Cell_" + names[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_stage(holder)
		var pts: PackedVector2Array = _chain_points(_pose(names[i]))
		if how == "joints":
			_draw_joints(holder, _pose(names[i]), pts)
		elif how == "envelope":
			_draw_envelope(holder, pts)
		else:
			_draw_body(holder, pts)


# ── the pose: six numbers, one per hinge, in degrees ───────────────────────────────────

## Every value in the axis resolves here and nowhere else. Nothing below reads the export;
## `ladder` builds ten poses in one pass, which is why the name is a parameter.
func _pose(who: String) -> PackedFloat32Array:
	match who:
		"walker":
			return _armadillo_pose(1.0)
		"laden":
			return _uniform(_spring_angle(SPRING_LADEN))
		"solid":
			return _uniform(_spring_angle(SPRING_SOLID))
		"sentry":
			return _aim(TENT_SENTRY * (CHAIN_L / TENT_CHAIN_M))
		"coil":
			return _aim(TENT_COIL * (CHAIN_L / TENT_CHAIN_M))
		"cast":
			return _aim(TENT_CAST * (CHAIN_L / TENT_CHAIN_M))
		"line":
			return _uniform(0.0)
		"arc":
			return _uniform(QFEP_ARC_SWEEP / float(JOINTS))
		"ring":
			return _uniform(QFEP_RING_SWEEP / float(JOINTS))
		_:
			return _armadillo_pose(0.0)


## THE ARMADILLO'S OWN MECHANISM, not a reading of it. _apply_fold_pose() drives every
## hinge in that rig off ONE float by lerping between a folded and a deployed angle; this
## does the same on six hinges, alternating hip and knee down the chain exactly as a limb
## alternates them. ball is fold = 0, walker is fold = 1, and the float between them is
## real — it is simply not declared, because the member declares only its ends.
func _armadillo_pose(fold: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for k in range(JOINTS):
		var folded: float = ARM_HIP_FOLDED if k % 2 == 0 else ARM_KNEE_FOLDED
		var deployed: float = ARM_HIP_DEPLOYED if k % 2 == 0 else ARM_KNEE_DEPLOYED
		var a: float = folded + (deployed - folded) * fold
		out.append(a)
	return out


func _uniform(deg: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for k in range(JOINTS):
		out.append(deg)
	return out


## The sum of the six link directions for a uniform turn of `deg` per hinge, in units of
## SEG. Its y is the chain's height, its length is the tip's distance from the hinge, and
## its argument is 3.5 * deg — the mean of the six cumulative turns. Both bisections below
## are root-finds on this one function, which is why neither needs a solver.
func _uniform_tip(deg: float) -> Vector2:
	var acc: float = 0.0
	var out: Vector2 = Vector2.ZERO
	var step: float = deg_to_rad(deg)
	for k in range(JOINTS):
		acc += step
		out += Vector2(sin(acc), cos(acc))
	return out


## spring_hopper's load, turned into a bend. That member scales its coil's height by
## 1 - (1 - _coil_floor) * _compression, with the shipped floor 0.15. A coil gets shorter by
## compressing; A CHAIN OF RIGID LINKS HAS NO OTHER WAY TO GET SHORTER THAN TO BEND, so the
## angle is whatever makes the chain's height match the coil's. Bisected on [0, 30] degrees,
## where the height ratio is monotone decreasing from 1.000 to -0.167 (checked on a replica
## at 0.01-degree resolution); the whole declarable range of compression, 0 to 1, maps to
## 0.00 to 22.5 degrees and lands well inside it.
func _spring_angle(compression: float) -> float:
	var want: float = 1.0 - (1.0 - SPRING_FLOOR) * compression
	var lo: float = 0.0
	var hi: float = 30.0
	for i in range(48):
		var mid: float = (lo + hi) * 0.5
		var ratio: float = _uniform_tip(mid).y / float(JOINTS)
		if ratio > want:
			lo = mid
		else:
			hi = mid
	return (lo + hi) * 0.5


## The uniform hinge angle whose tip lands `d` from the hinge. |sum of six unit vectors at
## k*theta| is the Dirichlet kernel sin(3 theta) / sin(theta / 2): 6 at theta = 0, falling
## monotonically to 0 at theta = 60, where the chain closes. So one bisection, no solver.
func _reach_angle(d: float) -> float:
	var lo: float = 0.0
	var hi: float = 60.0
	for i in range(48):
		var mid: float = (lo + hi) * 0.5
		var reach: float = _uniform_tip(mid).length() * SEG
		if reach > d:
			lo = mid
		else:
			hi = mid
	return (lo + hi) * 0.5


## tentacle_placer's stances. That member pins a target and lets a hand-rolled FABRIK solve
## the chain to it; this pins the same target, scaled by the chain-length ratio, and solves
## it as a CONSTANT-CURVATURE arm — one bend angle shared by hinges 1..5 and an aim carried
## by hinge 0. The reason is in the member's own header and is in `declines`: its solver
## "re-solves every physics frame FROM ITS PREVIOUS SOLUTION", so a still of a FABRIK chain
## is a fact about how long it has been running.
##
## THE UNREACHABLE BRANCH IS THE MEMBER'S AND IS KEPT VERBATIM IN BEHAVIOUR. Its comment
## reads "Unreachable — straighten the chain at the target", and `sentry`'s target is
## (0, 6.0, 0) against a 6.0 m chain, so it takes that branch by construction. Here the
## scaled target is 0.420 m against a 0.420 m chain and it takes it too — which is what
## makes `sentry` all zeros, and what makes it identical to `line`.
func _aim(target: Vector2) -> PackedFloat32Array:
	var d: float = target.length()
	var psi: float = rad_to_deg(atan2(target.x, target.y))
	var out := PackedFloat32Array()
	if d >= CHAIN_L - 0.0005:
		out.append(psi)
		for k in range(JOINTS - 1):
			out.append(0.0)
		return out
	var theta: float = _reach_angle(d)
	var alpha: float = psi - 3.5 * theta
	out.append(alpha + theta)
	for k in range(JOINTS - 1):
		out.append(theta)
	return out


## Seven points — the mount hinge and six link ends — in the bending plane, relative to the
## hinge. x is reach, y is height. The chain rises from the mount, so a pose of all zeros is
## a vertical mast.
func _chain_points(angles: PackedFloat32Array) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(Vector2.ZERO)
	var acc: float = 0.0
	var here: Vector2 = Vector2.ZERO
	for k in range(JOINTS):
		acc += deg_to_rad(angles[k])
		here = here + Vector2(sin(acc), cos(acc)) * SEG
		pts.append(here)
	return pts


func _cumulative(angles: PackedFloat32Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var acc: float = 0.0
	for k in range(JOINTS):
		acc += angles[k]
		out.append(acc)
	return out


# ── drawing ────────────────────────────────────────────────────────────────────────────

func _build_stage(holder: Node3D) -> void:
	var plate := SurfaceTool.new()
	plate.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(plate, Vector3(0.0, PLATE_T * 0.5, 0.0),
		Vector3(PLATE_HX * 2.0, PLATE_T, PLATE_HZ * 2.0))
	_commit(holder, "Plate", plate, C_PLATE, 0.95, 0.0)

	var cage := SurfaceTool.new()
	cage.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sx in SIGNS:
		for sz in SIGNS:
			_add_box(cage,
				Vector3(sx * POST_X, PLATE_T + CAGE_H * 0.5, sz * POST_Z),
				Vector3(POST_W, CAGE_H, POST_W))
	_commit(holder, "CagePosts", cage, C_CAGE, 0.80, 0.0)

	var mount := SurfaceTool.new()
	mount.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(mount, Vector3(0.0, PLATE_T + MOUNT_H * 0.5, 0.0),
		Vector3(MOUNT_W, MOUNT_H, MOUNT_W))
	_commit(holder, "Mount", mount, C_MOUNT, 0.75, 0.05)


## body — six tapered links and seven collars. The collars are wider than their links, so a
## hinge is a thing you can see rather than a corner you infer.
func _draw_body(holder: Node3D, pts: PackedVector2Array) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(JOINTS):
		var t: float = float(k) / float(JOINTS - 1)
		var w: float = LIMB_W0 + (LIMB_W1 - LIMB_W0) * t
		var dep: float = LIMB_D0 + (LIMB_D1 - LIMB_D0) * t
		_add_link(st, pts[k], pts[k + 1], w, dep)
	for k in range(pts.size()):
		var t2: float = float(k) / float(JOINTS)
		var cw: float = (LIMB_W0 + (LIMB_W1 - LIMB_W0) * t2) * COLLAR_K
		var cd: float = (LIMB_D0 + (LIMB_D1 - LIMB_D0) * t2) * COLLAR_K
		_add_square(st, pts[k], cw, cd)
	_commit(holder, "Limb", st, C_LIMB, 0.55, 0.05)


## joints — the same pose with the mass moved out of the links and into the angles. Every
## sector is the same radius and the same depth, so the six wedges are directly comparable
## and a hinge at zero degrees draws nothing at all.
func _draw_joints(holder: Node3D, angles: PackedFloat32Array,
		pts: PackedVector2Array) -> void:
	var rods := SurfaceTool.new()
	rods.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(JOINTS):
		_add_link(rods, pts[k], pts[k + 1], ROD_W, ROD_D)
	for k in range(pts.size()):
		_add_square(rods, pts[k], ROD_W * 1.6, ROD_D * 1.6)
	_commit(holder, "Armature", rods, C_ROD, 0.60, 0.05)

	var cum: PackedFloat32Array = _cumulative(angles)
	var sectors := SurfaceTool.new()
	sectors.begin(Mesh.PRIMITIVE_TRIANGLES)
	var any: bool = false
	for k in range(JOINTS):
		var from_deg: float = 0.0
		if k > 0:
			from_deg = cum[k - 1]
		var to_deg: float = cum[k]
		if _add_sector(sectors, pts[k], from_deg, to_deg):
			any = true
	if any:
		_commit(holder, "Angles", sectors, C_SECTOR, 0.45, 0.10)


## envelope — the volume occupied, and nothing of what occupies it. The hull of the seven
## joint centres grown by the limb's half-width, extruded through the limb's depth.
func _draw_envelope(holder: Node3D, pts: PackedVector2Array) -> void:
	var grown := PackedVector2Array()
	for k in range(pts.size()):
		for sx in SIGNS:
			for sy in SIGNS:
				grown.append(pts[k] + Vector2(float(sx) * HULL_GROW, float(sy) * HULL_GROW))
	var poly: PackedVector2Array = _hull(grown)
	if poly.size() < 3:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_prism(st, poly, HULL_D)
	_commit(holder, "Envelope", st, C_HULL, 0.65, 0.0)


# ── mesh helpers ───────────────────────────────────────────────────────────────────────

## Plane point -> world. The chain bends in x (reach) and y (height); z is thickness only.
func _world(p: Vector2, z: float) -> Vector3:
	return Vector3(p.x, HUB_Y + p.y, z)


## One link: a rectangle in the bending plane, extruded through `depth` in z.
func _add_link(st: SurfaceTool, a: Vector2, b: Vector2, w: float, depth: float) -> void:
	var d: Vector2 = b - a
	if d.length() < 0.0008:
		return
	var n2: Vector2 = Vector2(-d.y, d.x).normalized() * (w * 0.5)
	var poly := PackedVector2Array([a + n2, b + n2, b - n2, a - n2])
	_add_prism(st, poly, depth)


## One collar: an axis-aligned square in the bending plane, extruded in z.
func _add_square(st: SurfaceTool, at: Vector2, w: float, depth: float) -> void:
	var h: float = w * 0.5
	var poly := PackedVector2Array([
		at + Vector2(-h, -h), at + Vector2(h, -h), at + Vector2(h, h), at + Vector2(-h, h)])
	_add_prism(st, poly, depth)


## One hinge angle, as a solid wedge of material. Returns false when the angle is zero, so
## a straight chain commits nothing rather than committing a surface with no vertices.
func _add_sector(st: SurfaceTool, at: Vector2, from_deg: float, to_deg: float) -> bool:
	var span: float = to_deg - from_deg
	if absf(span) < 0.35:
		return false
	var steps: int = maxi(2, int(absf(span) / ARC_STEP_DEG) + 1)
	var poly := PackedVector2Array()
	poly.append(at)
	for i in range(steps + 1):
		var f: float = float(i) / float(steps)
		var ang: float = deg_to_rad(from_deg + span * f)
		poly.append(at + Vector2(sin(ang), cos(ang)) * ARC_R)
	_add_prism(st, poly, ARC_D)
	return true


## A polygon in the bending plane, extruded through +-depth/2 in z. Both caps are fanned
## from vertex 0, which is correct for a convex polygon and correct for a sector whose
## vertex 0 is its centre — the two shapes this is asked for.
func _add_prism(st: SurfaceTool, poly: PackedVector2Array, depth: float) -> void:
	var n: int = poly.size()
	if n < 3:
		return
	var hz: float = depth * 0.5
	var mid: Vector2 = Vector2.ZERO
	for i in range(n):
		mid += poly[i]
	mid = mid / float(n)
	var inside: Vector3 = _world(mid, 0.0)
	for i in range(1, n - 1):
		_tri(st, _world(poly[0], hz), _world(poly[i], hz), _world(poly[i + 1], hz), inside)
		_tri(st, _world(poly[0], -hz), _world(poly[i + 1], -hz), _world(poly[i], -hz),
			inside)
	for i in range(n):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % n]
		_quad(st, _world(a, hz), _world(b, hz), _world(b, -hz), _world(a, -hz), inside)


## An axis-aligned box in WORLD space, twelve triangles, wound outward. Used for the stage
## only — everything the axes draw goes through _add_prism.
func _add_box(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var p := PackedVector3Array([
		at + Vector3(-h.x, -h.y, h.z), at + Vector3(h.x, -h.y, h.z),
		at + Vector3(h.x, h.y, h.z), at + Vector3(-h.x, h.y, h.z),
		at + Vector3(-h.x, -h.y, -h.z), at + Vector3(h.x, -h.y, -h.z),
		at + Vector3(h.x, h.y, -h.z), at + Vector3(-h.x, h.y, -h.z)])
	_quad(st, p[0], p[1], p[2], p[3], at)
	_quad(st, p[5], p[4], p[7], p[6], at)
	_quad(st, p[3], p[2], p[6], p[7], at)
	_quad(st, p[4], p[5], p[1], p[0], at)
	_quad(st, p[1], p[5], p[6], p[2], at)
	_quad(st, p[4], p[0], p[3], p[7], at)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		inside: Vector3) -> void:
	_tri(st, a, b, c, inside)
	_tri(st, a, c, d, inside)


## One triangle, with the normal taken from the winding and FLIPPED if it points back at
## `inside`. Every material here is CULL_DISABLED as well, so a face that happened to wind
## inward is still drawn rather than becoming a hole in the picture.
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	var centre: Vector3 = (a + b + c) / 3.0
	if n.dot(centre - inside) < 0.0:
		n = -n
	var tri := PackedVector3Array([a, b, c])
	for vtx in tri:
		st.set_normal(n)
		st.add_vertex(vtx)


## Andrew's monotone chain. Deterministic, no tolerance games: the input is 28 points, four
## per joint centre, so the hull is always at least a rectangle and the envelope reading can
## never publish an empty frame.
func _hull(points: PackedVector2Array) -> PackedVector2Array:
	var pts: Array = []
	for i in range(points.size()):
		pts.append(points[i])
	pts.sort_custom(_less_xy)
	var lower: Array = []
	for i in range(pts.size()):
		while lower.size() >= 2 and _cross2(lower[lower.size() - 2],
				lower[lower.size() - 1], pts[i]) <= 0.0:
			lower.pop_back()
		lower.append(pts[i])
	var upper: Array = []
	for i in range(pts.size() - 1, -1, -1):
		while upper.size() >= 2 and _cross2(upper[upper.size() - 2],
				upper[upper.size() - 1], pts[i]) <= 0.0:
			upper.pop_back()
		upper.append(pts[i])
	var out := PackedVector2Array()
	for i in range(lower.size() - 1):
		out.append(lower[i])
	for i in range(upper.size() - 1):
		out.append(upper[i])
	return out


func _less_xy(u: Vector2, v: Vector2) -> bool:
	if absf(u.x - v.x) > 0.0000001:
		return u.x < v.x
	return u.y < v.y


func _cross2(o: Vector2, a: Vector2, b: Vector2) -> float:
	return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)


## SurfaceTool.commit() on a tool that was begun and never given a vertex is not a mesh with
## no surfaces, it is an error in the log.
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
