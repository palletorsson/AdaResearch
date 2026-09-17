# moholy.gd — a composition family of the biome cage, after László Moholy-Nagy's
# A II (Construction A II, 1924), with El Lissitzky's Prouns behind it.
#
# What the painting does. Nothing in A II rests on a ground. Two long bars cross high
# on the canvas at an oblique angle — not a right angle, about sixty degrees — and the
# crossing is off centre: the eye climbs the first bar, reaches the hinge, and is turned
# onto the second. Translucent planes overlap at different depths, one floating almost
# flat, one leaning; a small circle sits near the crossing; a dark block at the far end.
# It is a construction, assembled in the air, and its focus is where it BENDS.
#
# How the numbers answer it. The spine is a bent line: straight from `a` (the foot,
# deep in a corner of the floor) to an elbow, then a turn of 56 .. 62 degrees to `b`.
# The elbow IS the golden section of the parameter — path(0.618) is the hinge, so
# Point One, the one you can move, hangs exactly where the work turns, with the second
# point and the rod behind it along the first bar — and by length it is near it: the
# second bar is 0.68 .. 0.78 of the first, as A II's crossing bar is the shorter, which
# puts the elbow at 0.56 .. 0.60 of the way. heading() jumps at the hinge. The second
# axis is the mirror of the second leg across the first, which makes it the elbow's own
# bisector: a bar through the hinge crossing the first at the same angle. across() runs
# along it, u = 0 the hinge, u = ±1 near the glass. The beam and the runners take its
# near arm, the leaning plane and the divided cube its far arm; the black cube ends
# the second leg on its own, sixty degrees from either. Nothing is built ON the second
# axis but the crossing itself, so the sliding disc (across ±0.55) never reaches the
# cube (path 0.85): with the second leg on the second axis, as a straight-through
# reading would have it, the disc's swing ran under the cube in every seed.
# The lift (1.64 .. 1.76) is the highest of the families: the point at about two
# metres, the raft at 2.5, the beam at three — in the air, as the painting is. The
# first plane takes the tilt the vitrine's `vertical` family calls vertical (86 .. 90,
# a turn about the plane's own width): the slab lies nearly level, a floating raft
# above the first bar. The second leans at about -30, the translucent rectangle that
# cuts across the bars. The mirror signs the seed drew (sx, sz) flip the whole layout,
# so the handedness of the turn comes from the mirror and a mirrored seed mirrors.
#
# Metre scale, at the 5 m cage (inner 2.0): the corners of the spine stay 5 % inside
# the inner square, across(±1) 3 % inside, the arms round the hinge are at least 56
# degrees apart, the second bar is long enough (>= 0.8 * inner) that the cube stands
# clear of the disc's swing by the disc's radius plus the cube's half (0.80 m), and the
# raft's underside clears the sweeping boundary wall's top at the lowest lift
# (0.6 * lift - 0.9 >= the raft's half-height). Everything is drawn in units of
# `inner`, so the 24 m cage is the same work at 5.75 x. probe_biome_family_moholy.gd
# measures each of these.
extends RefCounted

const NAME := "moholy"
const REFERENCE := "László Moholy-Nagy, A II (Construction A II), 1924; El Lissitzky, Prouns"
const LINE := "A work built in the air turns at its hinge: two bars crossing at sixty degrees, and the point sits where the spine bends, not where the room is centred."

const DEG := PI / 180.0
## the hinge, in the spine's parameter: path(PHI) is the elbow
const PHI := 0.618
## the spine's three corners stay this far inside the inner square (a fraction of inner)
const MARGIN := 0.95
## across(±1) stops this short of the inner edge
const REACH := 0.97


## Once per cage. Every draw comes from `rng`, in this order, so one seed is one work.
static func score(rng: RandomNumberGenerator, inner: float, sx: float, sz: float) -> Dictionary:
	# the foot of the first bar: deep in a corner of the floor (lower-left before the
	# mirror). x beyond 0.84 keeps the white sphere at path(0) off the back pane's
	# lattice; z beyond 0.72 leaves the second bar its room toward the far wall
	var ax: float = rng.randf_range(0.84, 0.94)
	var az: float = rng.randf_range(0.72, 0.88)
	var a0 := Vector2(-ax, -az)
	# the first bar rises through the centre: 25 .. 38 degrees from +x toward +z
	var phi1: float = rng.randf_range(25.0, 38.0) * DEG
	# the turn at the hinge: about sixty, never a right angle
	var turn: float = rng.randf_range(56.0, 62.0) * DEG
	# the second bar, as a fraction of the first: the shorter one, as in A II
	var ratio: float = rng.randf_range(0.68, 0.78)
	# how much of the floor the spine takes
	var fill: float = rng.randf_range(0.92, 0.98)
	# the air: the highest lift of the families, and the two tilts
	var lift: float = rng.randf_range(1.64, 1.76)
	var tilt0: float = rng.randf_range(86.0, 90.0)
	var tilt1: float = rng.randf_range(-34.0, -26.0)

	var d1 := Vector2(cos(phi1), sin(phi1))                 # the first bar's travel
	var d2 := Vector2(cos(phi1 + turn), sin(phi1 + turn))   # the second leg's travel
	var d3 := Vector2(cos(phi1 - turn), sin(phi1 - turn))   # the second AXIS, near arm
	# the longest first bar whose elbow (a0 + L1 * d1) and foot (a0 + L1 * w) both stay
	# inside the margin: each is a ray from the foot against the square
	var w: Vector2 = d1 + d2 * ratio
	var l1_max: float = minf(_reach(a0, d1, MARGIN), _reach(a0, w.normalized(), MARGIN) / w.length())
	var len1: float = fill * l1_max
	var len2: float = ratio * len1
	var e0: Vector2 = a0 + d1 * len1
	var b0: Vector2 = e0 + d2 * len2
	# the second axis through the hinge, each arm measured to the inner edge on its side
	var reach_near: float = _reach(e0, d3, 1.0) * REACH
	var reach_far: float = _reach(e0, -d3, 1.0) * REACH

	# mirror, and scale to metres
	var m := Vector2(sx, sz)
	return {
		"a": _v3(a0 * m * inner),
		"b": _v3(b0 * m * inner),
		"lift": lift,
		"tilt0": tilt0,
		"tilt1": tilt1,
		"moholy_elbow": _v3(e0 * m * inner),
		"moholy_d1": _v3(d1 * m),
		"moholy_d2": _v3(d2 * m),
		"moholy_d3": _v3(d3 * m),
		"moholy_t": PHI,
		"moholy_arc_t": len1 / (len1 + len2),
		"moholy_len1": len1 * inner,
		"moholy_len2": len2 * inner,
		"moholy_reach_near": reach_near * inner,
		"moholy_reach_far": reach_far * inner,
		"moholy_turn_deg": turn / DEG,
		"moholy_inner": inner,
	}


## The spine: a to the elbow for t < moholy_t, the elbow to b after. y = 0.
static func path(s: Dictionary, t: float) -> Vector3:
	var a: Vector3 = s["a"]
	var b: Vector3 = s["b"]
	var e: Vector3 = s["moholy_elbow"]
	var te: float = float(s["moholy_t"])
	t = clampf(t, 0.0, 1.0)
	if t < te:
		return a.lerp(e, t / te)
	return e.lerp(b, (t - te) / (1.0 - te))


## The second axis through the elbow. u = 0 is the hinge; u > 0 the near arm (the beam,
## the runners), u < 0 the far arm (the leaning plane, the divided cube); each arm
## reaches its own edge, so ±1 is near the glass on both sides. y = 0.
static func across(s: Dictionary, u: float) -> Vector3:
	var e: Vector3 = s["moholy_elbow"]
	var d3: Vector3 = s["moholy_d3"]
	u = clampf(u, -1.0, 1.0)
	var reach: float = float(s["moholy_reach_near"]) if u >= 0.0 else float(s["moholy_reach_far"])
	return e + d3 * (u * reach)


## Heading along the spine: the first bar's before the elbow, the second leg's after —
## it jumps by the turn at moholy_t. Radians about +y, atan2(dx, dz).
static func heading(s: Dictionary, t: float) -> float:
	var d: Vector3 = s["moholy_d1"] if t < float(s["moholy_t"]) else s["moholy_d2"]
	return atan2(d.x, d.z)


## Distance from p along the unit direction d to the square |x|, |y| <= half.
static func _reach(p: Vector2, d: Vector2, half: float) -> float:
	var r: float = INF
	if absf(d.x) > 1e-9:
		r = minf(r, ((half if d.x > 0.0 else -half) - p.x) / d.x)
	if absf(d.y) > 1e-9:
		r = minf(r, ((half if d.y > 0.0 else -half) - p.y) / d.y)
	return maxf(r, 0.0)


## A floor point (x, z) as a Vector3 with y = 0.
static func _v3(p: Vector2) -> Vector3:
	return Vector3(p.x, 0.0, p.y)
