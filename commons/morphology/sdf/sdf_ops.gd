# sdf_ops.gd
# Pure-math library of SDF transition operators. Every function takes
# already-evaluated distance values and returns a new distance value — so ops
# compose cleanly and stay backend-agnostic.
#
# The IQ / Mercury SDF playbook: boolean, smooth boolean, morph, displace.

# Preload this via: const SdfOps = preload("res://commons/morphology/sdf/sdf_ops.gd")
# Class_name was removed to avoid GDScript registry caching issues when the
# script is loaded outside a full editor session.
extends RefCounted


# ─── Boolean (sharp) ─────────────────────────────────────────────

static func union(a: float, b: float) -> float:
	return minf(a, b)


static func intersect(a: float, b: float) -> float:
	return maxf(a, b)


static func subtract(a: float, b: float) -> float:
	return maxf(a, -b)


# ─── Smooth boolean (rounded, controlled by k) ───────────────────

## Smooth union with a rounding radius k. k=0 collapses to hard union.
static func smooth_union(a: float, b: float, k: float) -> float:
	if k <= 0.0:
		return minf(a, b)
	var h: float = clampf(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
	return lerp(b, a, h) - k * h * (1.0 - h)


static func smooth_intersect(a: float, b: float, k: float) -> float:
	if k <= 0.0:
		return maxf(a, b)
	var h: float = clampf(0.5 - 0.5 * (b - a) / k, 0.0, 1.0)
	return lerp(b, a, h) + k * h * (1.0 - h)


static func smooth_subtract(a: float, b: float, k: float) -> float:
	return smooth_intersect(a, -b, k)


# ─── Transition (morph) — the core of principle-blending ─────────

## Linear morph from a to b as t goes 0 → 1. Always a valid SDF because a
## convex combination of two SDFs is itself an SDF (zero-isosurface remains
## manifold under lerp for smooth fields).
static func morph(a: float, b: float, t: float) -> float:
	return lerp(a, b, clampf(t, 0.0, 1.0))


## Smoothstep-eased morph — same endpoints, gentler in-between. Reads more
## like "transitioning" than "interpolating" — slow near t=0 and t=1, fast
## in the middle.
static func morph_smooth(a: float, b: float, t: float) -> float:
	var ts: float = smoothstep(0.0, 1.0, clampf(t, 0.0, 1.0))
	return lerp(a, b, ts)


# ─── Field modifiers ─────────────────────────────────────────────

## Push the surface outward by `amount` (positive) or inward (negative).
static func displace(d: float, amount: float) -> float:
	return d - amount


## Inflate the form — useful for thickening thin branches so SDF stays robust
## at low resolution.
static func inflate(d: float, r: float) -> float:
	return d - r


## Hollow shell of given thickness. `inside_d < 0` indicates material inside
## the form; abs(d) < thickness/2 keeps only a shell of that thickness.
static func shell(d: float, thickness: float) -> float:
	return absf(d) - thickness * 0.5


# ─── Common primitive SDFs (for subclasses to build from) ────────

## Sphere centered at origin.
static func sdf_sphere(p: Vector3, radius: float) -> float:
	return p.length() - radius


## Axis-aligned box centered at origin, half-extents b.
static func sdf_box(p: Vector3, b: Vector3) -> float:
	var q: Vector3 = Vector3(absf(p.x), absf(p.y), absf(p.z)) - b
	var outside: float = Vector3(maxf(q.x, 0.0), maxf(q.y, 0.0), maxf(q.z, 0.0)).length()
	var inside: float = minf(maxf(q.x, maxf(q.y, q.z)), 0.0)
	return outside + inside


## Capsule between two points with radius r. Exact SDF, the fundamental
## building block for L-system branches and creature spines.
static func sdf_capsule(p: Vector3, a: Vector3, b: Vector3, r: float) -> float:
	var pa: Vector3 = p - a
	var ba: Vector3 = b - a
	var h: float = clampf(pa.dot(ba) / ba.dot(ba), 0.0, 1.0)
	return (pa - ba * h).length() - r


## Torus — ring in XZ plane, tube radius t.x, ring radius t.y... actually
## t.x = ring radius, t.y = tube radius. Follows IQ convention.
static func sdf_torus(p: Vector3, ring_r: float, tube_r: float) -> float:
	var q: Vector2 = Vector2(Vector2(p.x, p.z).length() - ring_r, p.y)
	return q.length() - tube_r
