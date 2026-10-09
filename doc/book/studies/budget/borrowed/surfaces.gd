extends RefCounted
## Borrowed: two one-liners, supplied with this kit. Use them by path:
##   const Surfaces := preload("res://borrowed/surfaces.gd")
## We call them here; the stair climber (chapter 24) opens them and writes
## them again.
##
##   catenoid(u, v)    a point on the catenoid of the hall FormFinding_Catenary:
##                     the chain's curve, cosh, turned once about an axis.
##                     u from 0 to 1 runs along the axis, from one ring to the
##                     other; v from 0 to 1 runs once around. The axis is y.
##                     The waist (u = 0.5) has radius 1 and stands at height 0;
##                     the two rings have radius cosh(1.2), about 1.81, and
##                     stand at -1.2 and 1.2. Multiply by a size for metres.
##                     The hall keeps a longer piece (its u runs from -1.5 to
##                     1.5 with a waist of 0.5): a flat dish. We keep this one
##                     so that it stands as a neck.
##   gap_to_circle(n)  how far a polygon of n equal sides, drawn inside a
##                     circle, falls short of it in the middle of each side,
##                     as a share of the radius: 1 - cos(PI / n). From the
##                     torus rings of the hall Primitives_Portals.

const HALF := 1.2   # half the length of the piece we keep, in waist radii

static func catenoid(u: float, v: float) -> Vector3:
	var height := lerpf(-HALF, HALF, u)
	var radius := cosh(height)
	return Vector3(radius * cos(TAU * v), height, radius * sin(TAU * v))

static func gap_to_circle(n: int) -> float:
	return 1.0 - cos(PI / n)
