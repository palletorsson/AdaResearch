extends RefCounted
## klee.gd — a composition family of the biome cage, after Paul Klee's magic squares
## (*Ancient Sound*, 1925) and Josef Albers' *Homage to the Square* (1950–76).
##
## WHAT THE PAINTINGS DO. Klee's square is a grid of cells, each one a flat colour, the
## light gathering toward the middle; nothing leaves the grid and nothing sits between two
## cells. Albers nests three squares one inside the next — not concentric: each is pushed
## toward one edge, so the nest reads as a walk inward from a corner, and the eye takes it
## in right-angled steps. This family lays the cage's elements on that walk. Everything
## sits on the cage's 1 m cells, everything is low, and the two planes are tilted so
## little that they read as tiles.
##
## THE SPINE (`path`) is a square spiral of three L-shaped arms — three nested squares —
## from the corner cell `a` inward to the cell `b` beside the centre: out along the near
## wall row, up the far column, then back and in, each arm a third shorter than the last.
## The rod, the two points, plane 0 and the cube fall on the arms at the contract's fixed
## t. Plane 0 (path 0.382) and plane 1 (across −0.6) come to stand PARALLEL on the same
## column a step apart, one higher than the other — two of Albers' squares seen edge on.
##
## `across` is the ROW through `b` (the row the last arm arrives on), read as cell centres
## outward from the cage's centre column — it steps on the grid like everything else, so
## the carrier (a disc that rides across(u) as u swings) hops from tile to tile. `heading`
## is the arm's own direction of travel and turns by a right angle at every corner; at a
## corner it is the OUTGOING arm. That is load-bearing: plane 1 is hung at heading(0.5) +
## 90°, and t = 0.5 is always the outer L's far corner (see r0 below), so the outgoing
## rule sets plane 1 parallel to plane 0 where the incoming rule would put it through.
##
## NUMBERS, for the 5 m cage that ships (k = 1, inner = 2.0: a 5×5 grid of cells at
## −2 … 2, the glass at ±2.5) and the 24 m cage (k = 4.8, inner = 11.5):
##   e0  cells the corner `a` stands in from the glass. The 0.9k sphere at path(0) has
##       radius 0.45k and the glass is 0.5 m past the last cell centre: 0 for the 5 m cage
##       (the sphere sits 5 cm off the corner panes), 2 for the 24 m.
##   e1  cells the inner arms keep from the far glass. The 1.6k plane at path(0.382)
##       stands ACROSS its arm, so half its width (0.8k) must fit past the cell: 1 for the
##       5 m cage, 4 for the 24 m. The beam (1.4k) and plane 1 (1.2k) need less.
##   r0  the outer arm, 2·inner − e0 − e1 cells (3 in the 5 m cage, 17 in the 24 m); the
##       next two arms are round(2·r0/3) and round(r0/3) (2 and 1; 11 and 6). Their sum is
##       r0 for every integer r0, so the outer L is exactly half the spine and t = 0.5 is
##       its far corner. The last cell is a + (r0 − r1 + r2)·(1, 1): (0, 0) in the 5 m
##       cage, (2.5, 2.5) in the 24 m — near the centre, pushed toward the far corner the
##       way Albers pushes his inner squares; the span |a − b| is √2·(r0 − r1 + r2) ≥
##       1.1·inner because the margins e0 + e1 never take more than a third of the side.
##   lift  0.64 … 0.80: the point at 1.25·lift ≈ 0.9 m, the planes at 1.5·lift ≈ 1.1 m —
##       tiles at hip height; the cube at 0.35·lift sits a third into the floor, a tessera.
##   tilt0 4 … 14°, tilt1 −12 … −3°: the split family's 12° / −8° is the tile reading; a
##       few degrees either way keep two seeds from being one picture.
## The seed's mirror signs (sx, sz) pick the corner; one more coin, the HAND, swaps the two
## axes. Together they are the eight symmetries of the square — the whole group Klee's
## grid has, and the only moves that keep every element on a cell.

const NAME := "klee"
const REFERENCE := "Paul Klee, Ancient Sound, 1925 · Josef Albers, Homage to the Square, 1950–76"
const LINE := "A square is walked, not crossed: the spine turns inward by right angles from a corner, and every element sits on a cell."

## Arms shrink by thirds — Albers' three squares. Their rounded sum equals the outer arm
## for every integer r0 (r0 = 3m, 3m+1, 3m+2 all check), which is what pins t = 0.5 to
## the outer L's corner.
const ARM_FRACTIONS: Array[float] = [1.0, 2.0 / 3.0, 1.0 / 3.0]


## Once per cage. Draws the hand, the lift and the two tilts from `rng`; everything else
## is the grid's arithmetic on `inner`.
static func score(rng: RandomNumberGenerator, inner: float, sx: float, sz: float) -> Dictionary:
	var k: float = (2.0 * inner + 1.0) / 5.0
	var hand: bool = rng.randf() < 0.5
	var lift: float = rng.randf_range(0.64, 0.80)
	var tilt0: float = rng.randf_range(4.0, 14.0)
	var tilt1: float = rng.randf_range(-12.0, -3.0)
	# margins in cells: the corner sphere's radius, the wide plane's half-width, each
	# less the half metre from the last cell centre to the glass
	var e0: int = maxi(0, int(ceil(0.45 * k - 0.45)))
	var e1: int = maxi(1, int(ceil(0.8 * k - 0.4)))
	var side: int = int(round(2.0 * inner))          # cells per side, minus one
	var r0: int = maxi(1, side - e0 - e1)
	var arms: Array[int] = []
	for f in ARM_FRACTIONS:
		var r: int = int(round(float(r0) * f))
		if r >= 1 and (arms.is_empty() or r < arms[arms.size() - 1]):
			arms.append(r)
	# the canonical frame: p runs out along the near wall row, q up the far column. The
	# hand swaps which world axis is which; the mirror signs pick the corner.
	var px := Vector3(sx, 0.0, 0.0)
	var qx := Vector3(0.0, 0.0, sz)
	if hand:
		px = Vector3(0.0, 0.0, sz)
		qx = Vector3(sx, 0.0, 0.0)
	var p: float = -inner + float(e0)
	var q: float = p
	var corners := PackedVector3Array([px * p + qx * q])
	var cum := PackedFloat64Array([0.0])
	var total := 0.0
	for j in range(arms.size()):
		var r: float = float(arms[j])
		var sgn: float = 1.0 if j % 2 == 0 else -1.0     # out, then back, then out again
		p += sgn * r
		total += r
		corners.append(px * p + qx * q)
		cum.append(total)
		q += sgn * r
		total += r
		corners.append(px * p + qx * q)
		cum.append(total)
	return {
		"a": corners[0], "b": corners[corners.size() - 1],
		"lift": lift, "tilt0": tilt0, "tilt1": tilt1,
		"klee_inner": inner, "klee_k": k, "klee_hand": hand, "klee_e0": e0, "klee_e1": e1,
		"klee_arms": arms, "klee_corners": corners, "klee_cum": cum, "klee_len": total,
		"klee_px": px, "klee_qx": qx, "klee_row": q,
	}


## The spine: the arm t falls on, walked by arc length. Axis-aligned by construction.
static func path(s: Dictionary, t: float) -> Vector3:
	var corners: PackedVector3Array = s["klee_corners"]
	var cum: PackedFloat64Array = s["klee_cum"]
	var i: int = _arm(s, t)
	var seg: float = cum[i + 1] - cum[i]
	var d: float = clampf(t, 0.0, 1.0) * float(s["klee_len"])
	var f: float = 0.0 if seg <= 0.0 else clampf((d - cum[i]) / seg, 0.0, 1.0)
	var p: Vector3 = corners[i].lerp(corners[i + 1], f)
	p.y = 0.0
	return p


## Across: the row through `b`, as cell centres. u = 0 is the cage's centre column on that
## row; positive u steps toward the wall column the spine came down, so the beam
## (across 0.55) hangs over the third arm and plane 1 (across −0.6) stands on the second.
static func across(s: Dictionary, u: float) -> Vector3:
	var inner: float = float(s["klee_inner"])
	var p: float = _snap(-clampf(u, -1.0, 1.0) * inner, inner)
	var v: Vector3 = (s["klee_px"] as Vector3) * p + (s["klee_qx"] as Vector3) * float(s["klee_row"])
	v.y = 0.0
	return v


## The arm's direction of travel at t, as atan2(dx, dz): one of four right angles.
static func heading(s: Dictionary, t: float) -> float:
	var corners: PackedVector3Array = s["klee_corners"]
	var i: int = _arm(s, t)
	var d: Vector3 = corners[i + 1] - corners[i]
	return atan2(d.x, d.z)


## Which arm t is on: arm i covers cum[i] <= d < cum[i + 1]. A corner belongs to the arm
## LEAVING it (see the note on plane 1 above); t = 1 belongs to the last arm.
static func _arm(s: Dictionary, t: float) -> int:
	var cum: PackedFloat64Array = s["klee_cum"]
	var d: float = clampf(t, 0.0, 1.0) * float(s["klee_len"])
	var i := 0
	while i < cum.size() - 2 and d >= cum[i + 1]:
		i += 1
	return i


## The cell centre nearest v: the centres are −inner, −inner + 1, …, inner (integers for
## an odd side, half-integers for an even one), and none lies outside them.
static func _snap(v: float, inner: float) -> float:
	var side: int = int(round(2.0 * inner))
	return -inner + float(clampi(int(round(v + inner)), 0, side))
