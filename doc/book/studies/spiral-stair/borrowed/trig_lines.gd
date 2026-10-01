extends RefCounted
## Borrowed: four lines of trigonometry that earlier chapters handed you closed.
## You called them; this chapter opens them. Use them by path:
##   const Trig := preload("res://borrowed/trig_lines.gd")
## These are small versions made for this kit. Contract, one line each:
##   wave_height(x, z)         from Noise: the height of a rolling floor over the point (x, z), between -1 and 1
##   gap_to_circle(n)          from The budget: how far a circle cut into n straight sides falls short of the round one, as a share of its radius
##   catenoid(u, v)            from The budget: the point at angle u (radians) and height v on a catenoid, the surface a soap film takes between two rings
##   base_ring(sides, radius)  from the pyramid in the hall of the cube lesson: the corners of a pyramid's base, as a list of Vector3

static func wave_height(x: float, z: float) -> float:
	return sin(x) * sin(z)

static func gap_to_circle(n: int) -> float:
	return 1.0 - cos(PI / n)

static func catenoid(u: float, v: float) -> Vector3:
	return Vector3(cosh(v) * cos(u), v, cosh(v) * sin(u))

static func base_ring(sides: int, radius: float) -> Array:
	var ring := []
	for i in sides:
		var angle := deg_to_rad(225.0) + TAU * float(i) / float(sides)
		ring.append(Vector3(cos(angle) * radius, 0.0, sin(angle) * radius))
	return ring
