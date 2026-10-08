extends RefCounted
## Shared, deterministic pose score for the four research studies.
## Positions in metres, angles in radians. Uniform positive scale about local origin.
const PERIOD: float = 4.0
const MODES := ["translate", "rotate", "scale", "combine"]

static func sample_time(time: float, interval: float) -> float:
	return floor((maxf(time,0.0) + 0.000000001) / maxf(interval,0.0001)) * maxf(interval,0.0001)

static func pose(mode: String, time: float) -> Transform3D:
	var phase: float = TAU * time / PERIOD
	var at := Vector3.ZERO
	var turn := Basis.IDENTITY
	var size: float = 1.0
	if mode in ["translate","combine"]: at.x = 0.6 * sin(phase)
	if mode in ["rotate","combine"]: turn = Basis(Vector3.UP, phase)
	if mode in ["scale","combine"]: size = 1.0 + 0.3 * sin(phase)
	# T * R * S: scale first, turn about the same origin, then displace.
	return Transform3D(turn.scaled(Vector3.ONE*size), at)

static func cube_points() -> PackedVector3Array:
	var points := PackedVector3Array()
	for x in [-0.275,0.275]:
		for y in [-0.275,0.275]:
			for z in [-0.275,0.275]: points.append(Vector3(x,y,z))
	return points

static func asymmetric_points() -> PackedVector3Array:
	return PackedVector3Array([Vector3(-0.3,-0.28,-0.22),Vector3(0.38,-0.28,-0.22),Vector3(-0.3,-0.28,0.31),Vector3(-0.1,0.42,-0.08)])

static func mark_point(shape: String) -> Vector3:
	if shape == "sphere": return Vector3(0.17,0.09,-0.255).normalized()*0.325
	if shape == "asymmetric": return (asymmetric_points()[0]+asymmetric_points()[1]+asymmetric_points()[3])/3.0 + Vector3(0,0,-0.015)
	return Vector3(0.16,0.09,-0.285)
