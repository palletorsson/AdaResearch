extends RefCounted
## malevich.gd — a composition family of the biome cage, after Kazimir Malevich,
## *Suprematist Composition: Airplane Flying* (1915).
##
## What the painting does. One long axis, and nothing in the frame agrees with it: the
## rectangles lean at something like 25 degrees off the canvas's upright — not the
## diagonal, not the vertical, an angle no edge can claim, which is why it reads as
## MOTION. The shapes fly along that axis and as they go they slip to one side, so the
## mass gathers high and to the right while the lower left holds one black bar and then
## white. Everything floats; the white is not a ground but the air the shapes fly through.
## And the shapes stay near-parallel to the axis — it is their POSITIONS that step
## sideways, not their orientation.
##
## How the cage answers it, number by number (inner = 2.0 for the 5 m cage, k = 1):
##   the axis     20..30 degrees off the z wall, mirrored by sx / sz so the four mirror
##                seeds are four true mirrors (`malevich_dir`). The drift below adds at
##                most 8 degrees at the head, so every heading along the spine stays in
##                12..38 degrees off a wall: never the 45 the `diagonal` family owns,
##                never the 0 of `split`.
##   the flight   1.5..1.65 x inner long, so head and foot both clear the glass, and the
##                plane at t=0.382 clears the point at t=0.618 in plan: 0.708 m apart along
##                the spine at the shortest, against a flat plane's half-length of 0.55 m
##                and the sphere's 0.15 m.
##   the seat     the whole axis sits 0.12..0.22 x inner to one side (`malevich_side`):
##                the weight off-centre, white on the other side.
##   the drift    positions slide toward the weight side by 4..7 % of the flight length,
##                accelerating (t squared), so the head end slides most and the tangent
##                turns gently into it — the nose banking.
##   across       SHEARED, not perpendicular, and odd to the walls in its own right: the
##                cross line leans 22..35 degrees off the z wall the OPPOSITE way from the
##                flight, so the two scissor at 42..65 degrees (25..48 off the
##                perpendicular) through the golden section of the spine (the
##                cross-centre, `malevich_centre`). +u is the weight side, so the beam
##                (u > 0) lands there and the second plane (u < 0) on the white side; the
##                beam leads the point or trails it as the seed falls (`malevich_lead`) —
##                rectangles stepping diagonally, not sitting square across the axis.
##                u = ±1 reach the inner edge, each side its own distance.
##   lift         1.3..1.45: everything floats high. Not higher: the beam rides at
##                1.9 x lift and the 5 m cage's glass is 3 m tall.
##   tilt         nearly flat. MEASURED in Godot's YXZ Euler order (probe, 2026-09-17): a
##                tilt of 90 lays the slab horizontal (normal (0, -1, 0)), a tilt of 0
##                stands it up — the opposite of what the vitrine's own family notes say.
##                Flat-with-a-bank is therefore 90 minus 6..14 degrees. The slab's leading
##                edge, toward the head, RISES with the bank: nose up, an airplane flying.
##
## Everything is drawn from the given rng, in a fixed order, so one seed is one work.

const NAME := "malevich"
const REFERENCE := "Kazimir Malevich, Suprematist Composition: Airplane Flying, 1915"
const LINE := "A flight has one axis no wall agrees with, and what flies along it slides to one side as it goes, so the weight lands off-centre and the white keeps the rest."

## The golden section of the spine: the point's t, and where `across` crosses the flight.
const PHI := 0.618
## `across` reaches this fraction of the way to the inner edge at u = ±1: on the edge to
## the eye, a hair inside it to the bounds check.
const EDGE := 0.98


## Once per cage. All randomness from `rng`; sx / sz mirror the work.
static func score(rng: RandomNumberGenerator, inner: float, sx: float, sz: float) -> Dictionary:
	# 1. the flight axis — an odd angle off the z wall, mirrored
	var theta_deg: float = rng.randf_range(20.0, 30.0)
	var theta: float = deg_to_rad(theta_deg)
	var dir := Vector3(sin(theta) * sx, 0.0, cos(theta) * sz)
	var perp := Vector3(-dir.z, 0.0, dir.x)
	# 2. the side the weight falls — drawn, then given the mirror's sign so that mirrored
	#    seeds drift to mirrored sides (perp itself flips sense under a single mirror)
	var side: float = (1.0 if rng.randf() < 0.5 else -1.0) * sx * sz
	var lat: Vector3 = perp * side
	# 3. the flight's length, its seat off-centre, and how far it slides as it goes
	var length: float = rng.randf_range(1.5, 1.65) * inner
	var seat: float = rng.randf_range(0.12, 0.22) * inner
	var drift: float = rng.randf_range(0.04, 0.07) * length
	var mid: Vector3 = lat * seat
	var a: Vector3 = mid - dir * (length * 0.5)
	var b: Vector3 = mid + dir * (length * 0.5) + lat * drift
	# 4. the across line: its own lean off the z wall, OPPOSITE to the flight's, so the two
	#    lines scissor at 42..65 degrees — sheared 25..48 degrees off the perpendicular and
	#    never parallel to a wall (a shear measured from the flight alone can be: with the
	#    flight at 25 and the shear at 25 the cross lay flat along the x wall). Signed so
	#    that +u is the weight side; whether it then leads or trails the point is the seed's.
	var psi_deg: float = rng.randf_range(22.0, 35.0)
	var psi: float = deg_to_rad(psi_deg)
	var lead: float = side * sx * sz
	var across_dir: Vector3 = Vector3(-sin(psi) * sx, 0.0, cos(psi) * sz) * lead
	# 5. lift and the planes' bank (tilt 90 = flat, measured; see the header)
	var lift: float = rng.randf_range(1.3, 1.45)
	var bank0: float = rng.randf_range(6.0, 14.0)
	var bank1: float = rng.randf_range(4.0, 12.0)
	var s := {
		"a": a, "b": b, "lift": lift,
		"tilt0": 90.0 - bank0, "tilt1": -(90.0 - bank1),
		"malevich_inner": inner, "malevich_theta_deg": theta_deg, "malevich_dir": dir,
		"malevich_lat": lat, "malevich_side": side, "malevich_length": length,
		"malevich_seat": seat, "malevich_drift": drift,
		"malevich_psi_deg": psi_deg, "malevich_shear_deg": 90.0 - theta_deg - psi_deg,
		"malevich_lead": lead, "malevich_across": across_dir,
	}
	# 6. the cross-centre and each side's reach to the inner edge
	var c: Vector3 = path(s, PHI)
	s["malevich_centre"] = c
	s["malevich_reach"] = Vector2(_reach(c, -across_dir, inner) * EDGE, _reach(c, across_dir, inner) * EDGE)
	return s


## The spine: the straight flight from a, plus the drift, which grows as t squared.
static func path(s: Dictionary, t: float) -> Vector3:
	var a: Vector3 = s["a"]
	var dir: Vector3 = s["malevich_dir"]
	var lat: Vector3 = s["malevich_lat"]
	return a + dir * (float(s["malevich_length"]) * t) + lat * (float(s["malevich_drift"]) * t * t)


## Across the spine, sheared: through the cross-centre along `malevich_across` (its own
## odd lean, scissoring the flight), u = ±1 at the inner edge on each side (their own
## distances, since the centre is off-centre).
static func across(s: Dictionary, u: float) -> Vector3:
	var c: Vector3 = s["malevich_centre"]
	var reach: Vector2 = s["malevich_reach"]
	var r: float = reach.y if u >= 0.0 else reach.x
	return c + (s["malevich_across"] as Vector3) * (u * r)


## The travel direction's heading at t: the flight axis, turning into the drift.
static func heading(s: Dictionary, t: float) -> float:
	var d: Vector3 = (s["malevich_dir"] as Vector3) * float(s["malevich_length"]) \
		+ (s["malevich_lat"] as Vector3) * (2.0 * float(s["malevich_drift"]) * t)
	return atan2(d.x, d.z)


## Distance from c along unit d until |x| or |z| reaches inner.
static func _reach(c: Vector3, d: Vector3, inner: float) -> float:
	var r: float = INF
	if absf(d.x) > 1e-6:
		r = minf(r, ((inner if d.x > 0.0 else -inner) - c.x) / d.x)
	if absf(d.z) > 1e-6:
		r = minf(r, ((inner if d.z > 0.0 else -inner) - c.z) / d.z)
	return maxf(r, 0.0)
