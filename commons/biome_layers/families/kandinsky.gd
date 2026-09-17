extends RefCounted
## kandinsky.gd — a composition family of the biome cage, after Wassily Kandinsky,
## Composition VIII (1923). Written to the contract in README.md and loaded by path;
## no class_name, every draw from the rng the cage hands over.
##
## What the painting does. A fan of straight lines runs in from the upper left and
## converges on a focus set well off centre, low and to the right. The weight of the
## picture is the OPPOSITE corner: one large circle, haloed, with the smaller circles
## gathering around it and along the far side. Nothing sits in the middle. The fan
## opens as it leaves the focus — the further from the convergence, the wider the ribs
## stand apart — so the whole arrangement is heavy in one corner and open towards the
## other, and the eye is led from the circle down the ribs into the point they share.
##
## How the cage answers it. The spine is the fan's leading rib. It sets out from the
## circle's corner (`a`: the ring centre and the white sphere at path(0)) and must
## arrive AIMED at the focus, which a line from the far corner can only do by bowing:
## the spine is one quadratic Bezier whose end tangent points at the focus, and its
## foot `b` stops a step short of it, so the cube at path(0.85) and the point at
## path(0.618) hang in the convergence without sitting on it. `across` is the fan
## itself: u = 0 is the focus, and the two signs of u are the two ribs that flank the
## spine, leaving the focus at an angle to either side of its arrival — the rib inside
## the bow's belly at the spread, the rib on its outer side wider, since a leading line
## is at a fan's edge and not its middle — and reaching almost to the glass. An element
## at |u| stands |u| of the way out along its rib, so its offset from the spine grows
## with its distance from the focus — the fan opens. `sx`, `sz` multiply every stored
## vector, so a mirrored seed is the mirror image of the whole arrangement, ribs
## included, and not merely a spine with the same perpendicular.
##
## At the shipped size (inner 2.0, a 5 m cage) the vitrine's elements — the 0.3 m
## point at path(0.618), the 1.6 x 1.1 m plane at path(0.382), the 1.2 x 0.8 m plane
## at across(-0.6), the 0.7 m cube at path(0.85), the beam at across(0.55) — clear
## each other for every seed; commons/testing/probe_biome_family_kandinsky.gd
## measures that with oriented boxes, not by eye.

const NAME := "kandinsky"
const REFERENCE := "Wassily Kandinsky, Composition VIII, 1923"
const LINE := "A fan of lines converges on a focus set off centre while the weight gathers in the opposite corner: an arrangement is heavy where it is quiet and open where it runs."

## The corner the big circle sits in, as shares of `inner`: x hugs the glass
## (0.80..0.86, where the diagonal family stops at 0.85), z a little less (0.66..0.80),
## so the head is a CORNER and not the end of a diagonal — the painting's circle is
## pressed to the edge on one side and has a little room on the other.
const HEAD_X := Vector2(0.80, 0.86)
const HEAD_Z := Vector2(0.66, 0.80)
## The focus, shares of `inner`: off centre towards the near right, 0.62..0.72 across
## and 0.30..0.44 in. Never the middle (the split family's field) and never the corner
## (the diagonal's end): the convergence sits inside the floor with room behind it.
const FOCUS_X := Vector2(0.62, 0.72)
const FOCUS_Z := Vector2(0.30, 0.44)
## The fan's opening, degrees: the rib inside the bow's belly leaves the focus this far
## from the spine's arrival. Composition VIII's main fan spans roughly 60..80 degrees.
const SPREAD_DEG := Vector2(30.0, 40.0)
## The rib on the bow's outer side swings this much wider. The spine is the fan's
## LEADING line, so the fan is not symmetric about it: it opens away from the belly.
## The number is also a clearance — the beam rides this rib at 1.9 x lift, the plane on
## the spine reaches 1.5 x lift + 0.26 m, and 14 degrees more takes the beam's plan
## footprint out from under the plane's instead of leaving the height to separate them.
const OUTER_EXTRA_DEG := 14.0
## The bow in degrees: how far the spine's arrival turns off the straight chord out of
## the corner. Its sign is a coin, so half the seeds belly one way. Zero would be a
## ruler, and the painting's leading line is the one line in it that is not straight.
const BOW_DEG := Vector2(12.0, 22.0)
## The step the spine's foot stops short of the focus, share of `inner`: at inner 2.0
## that is 0.32..0.44 m, enough that the cube at path(0.85) does not squat on the point
## every rib is aimed at.
const FOOT_GAP := Vector2(0.16, 0.22)
## Where a rib ends: this share of the way from the focus to the inner edge, so u = ±1
## is near the glass and never on it.
const REACH := 0.92
## The lift: the painting floats, nothing in it rests. Higher than the flat families
## (1.0), under the Proun tower (1.45). The floor of the range is also a clearance: the
## beam floats at 1.9 x lift and the plane on the spine reaches 1.5 x lift + 0.26 m, so
## the air between them is 0.4 x lift - 0.41 m — 7 cm at 1.2, 3 cm at 1.1.
const LIFT := Vector2(1.20, 1.40)
## The control point sits this share of the head-to-foot distance behind the foot on
## the arrival line: half a chord back keeps the bow one smooth belly rather than a
## hook at the foot.
const CTRL_BACK := 0.5


## Once per cage. Every draw in a fixed order, so one seed is one work; sx, sz touch
## nothing until the last line, where they mirror every stored vector at once.
static func score(rng: RandomNumberGenerator, inner: float, sx: float, sz: float) -> Dictionary:
	var head := Vector3(-rng.randf_range(HEAD_X.x, HEAD_X.y), 0.0, -rng.randf_range(HEAD_Z.x, HEAD_Z.y)) * inner
	var focus := Vector3(rng.randf_range(FOCUS_X.x, FOCUS_X.y), 0.0, rng.randf_range(FOCUS_Z.x, FOCUS_Z.y)) * inner
	var spread: float = rng.randf_range(SPREAD_DEG.x, SPREAD_DEG.y)
	var bow: float = rng.randf_range(BOW_DEG.x, BOW_DEG.y) * (1.0 if rng.randf() < 0.5 else -1.0)
	var gap: float = rng.randf_range(FOOT_GAP.x, FOOT_GAP.y) * inner
	var lift: float = rng.randf_range(LIFT.x, LIFT.y)
	var tilt_jitter: float = rng.randf_range(-4.0, 4.0)
	# the chord out of the corner, and the arrival turned off it by the bow
	var chord: Vector3 = (focus - head).normalized()
	var arrive: Vector3 = chord.rotated(Vector3.UP, deg_to_rad(bow))
	var foot: Vector3 = focus - arrive * gap
	# the control point lies behind the foot ON the arrival line, so the Bezier's end
	# tangent (b - c) is exactly `arrive`: the spine reaches its foot aimed at the focus.
	# The clamp is a guard only — with these ranges the point never leaves the floor.
	var ctrl: Vector3 = foot - arrive * (CTRL_BACK * head.distance_to(foot))
	ctrl.x = clampf(ctrl.x, -inner * 0.95, inner * 0.95)
	ctrl.z = clampf(ctrl.z, -inner * 0.95, inner * 0.95)
	# the two ribs: back OUT of the focus, one to either side of the spine's arrival (the
	# spread, and the spread plus OUTER_EXTRA_DEG), each as long as the floor allows it
	# (REACH of the way to the inner edge). Which rib
	# is u > 0 follows the bow: a positive bow bellies the spine towards the rib that a
	# positive rotation reaches, so the u > 0 rib — the beam's, floating high — is put on
	# the bow's OUTER side and the u < 0 rib, the low plane's, inside the belly. The
	# plane on the spine then never shares a column of air with the beam.
	var back: Vector3 = -arrive
	var outer: float = -signf(bow)
	var arm_neg: Vector3 = back.rotated(Vector3.UP, -outer * deg_to_rad(spread))
	var arm_pos: Vector3 = back.rotated(Vector3.UP, outer * deg_to_rad(spread + OUTER_EXTRA_DEG))
	var reach_neg: float = _to_edge(focus, arm_neg, inner) * REACH
	var reach_pos: float = _to_edge(focus, arm_pos, inner) * REACH
	# the planes. A tilt is the plane's rotation about its own x: 0 stands it up as a
	# wall, 90 lays it flat. The plane on the spine is a blade of the fan and lies nearly
	# in the picture plane, rising a little towards the focus (72..83 from vertical, the
	# wider the fan the flatter); its raised edge then stays 0.16 m and more under the
	# beam that floats above it at 1.9 x lift, whatever the seed. The plane on the belly
	# rib leans back along its rib by half the spread (-35..-40), a wall folding out of
	# the fan. One jitter keeps two seeds of one spread from being one pair of planes.
	var tilt0: float = 60.0 + 0.5 * spread + tilt_jitter * 0.75
	var tilt1: float = -(20.0 + 0.5 * spread) + tilt_jitter * 0.5
	var m := Vector3(sx, 1.0, sz)
	return {
		"a": head * m,
		"b": foot * m,
		"lift": lift,
		"tilt0": tilt0,
		"tilt1": tilt1,
		"kandinsky_focus": focus * m,
		"kandinsky_ctrl": ctrl * m,
		"kandinsky_arm_neg": arm_neg * m,
		"kandinsky_arm_pos": arm_pos * m,
		"kandinsky_reach_neg": reach_neg,
		"kandinsky_reach_pos": reach_pos,
		"kandinsky_spread": spread,
		"kandinsky_bow": bow,
		"kandinsky_gap": gap,
		"kandinsky_inner": inner,
	}


## The spine: one quadratic Bezier a -> ctrl -> b. t = 0 is a and t = 1 is b exactly
## (the other terms are multiplied by zero), and every point lies in the triangle of
## the three, which lies inside the floor.
static func path(s: Dictionary, t: float) -> Vector3:
	var a: Vector3 = s["a"]
	var b: Vector3 = s["b"]
	var c: Vector3 = s["kandinsky_ctrl"]
	var w: float = 1.0 - t
	var p: Vector3 = a * (w * w) + c * (2.0 * w * t) + b * (t * t)
	p.y = 0.0
	return p


## The fan: u = 0 the focus, u < 0 one rib, u > 0 the other, |u| the share of the rib
## walked. The offset from the spine is |u| * reach * sin(the rib's angle): it grows
## with the distance from the focus, which is the fan opening.
static func across(s: Dictionary, u: float) -> Vector3:
	var f: Vector3 = s["kandinsky_focus"]
	var uu: float = clampf(u, -1.0, 1.0)
	var arm: Vector3 = s["kandinsky_arm_pos"] if uu >= 0.0 else s["kandinsky_arm_neg"]
	var reach: float = float(s["kandinsky_reach_pos"] if uu >= 0.0 else s["kandinsky_reach_neg"])
	var p: Vector3 = f + arm * (absf(uu) * reach)
	p.y = 0.0
	return p


## Heading along the spine at t: the Bezier's tangent, 2(1-t)(c-a) + 2t(b-c), as the
## yaw atan2(dx, dz). At t = 1 this is the arrival, i.e. the direction of the focus.
static func heading(s: Dictionary, t: float) -> float:
	var a: Vector3 = s["a"]
	var b: Vector3 = s["b"]
	var c: Vector3 = s["kandinsky_ctrl"]
	var d: Vector3 = (c - a) * (2.0 * (1.0 - t)) + (b - c) * (2.0 * t)
	if d.length_squared() < 1e-10:
		d = b - a
	return atan2(d.x, d.z)


## Distance from `from` (inside the floor) along the unit `dir` to the square
## |x|, |z| <= inner: the nearer of the two wall hits.
static func _to_edge(from: Vector3, dir: Vector3, inner: float) -> float:
	var best: float = INF
	if absf(dir.x) > 1e-6:
		best = minf(best, ((inner if dir.x > 0.0 else -inner) - from.x) / dir.x)
	if absf(dir.z) > 1e-6:
		best = minf(best, ((inner if dir.z > 0.0 else -inner) - from.z) / dir.z)
	if best == INF:
		return 0.0
	return maxf(best, 0.0)
