extends RefCounted
## Borrowed: two one-liners, supplied with this kit. Use them by path:
##   const Surfaces := preload("res://guests/budget/surfaces.gd")
## They live in the guest's folder because the guest goes to your room whole.
## We call them here; the stair climber (chapter 24) opens them and writes
## them again, with angles in radians.
##
##   catenoid(u, v)    a point on the catenoid of the hall FormFinding_Catenary:
##                     the chain's curve, cosh, turned once about an axis.
##                     u from 0 to 1 goes once around; v from 0 to 1 runs along
##                     the axis, from the lower ring to the upper. The axis is y.
##                     The waist (v = 0.5) has radius 1 and stands at height 0;
##                     the two rings have radius cosh(1.2), about 1.81, at -1.2
##                     and 1.2. Multiply by a size for metres. The hall names
##                     the two the other way round (its u runs along the axis)
##                     and keeps a longer piece, a flat dish: we keep this one
##                     so that it stands as a neck.
##   gap_to_circle(n)  how far a ring of n straight sides, drawn inside a
##                     circle, falls short of it in the middle of each side,
##                     as a share of the radius: 1 - cos(PI / n).

const HALF := 1.2   # half the length of the piece we keep, in waist radii

static func catenoid(u: float, v: float) -> Vector3:
	var height := lerpf(-HALF, HALF, v)
	return Vector3(cosh(height) * cos(TAU * u), height, cosh(height) * sin(TAU * u))

static func gap_to_circle(n: int) -> float:
	return 1.0 - cos(PI / n)
