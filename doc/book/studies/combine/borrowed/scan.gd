extends RefCounted
## Borrowed from Collage (chapter 18), in a small version: the found body. It is
## a stand-in for a scan: this script makes it, nothing was scanned. Use it by path:
##   const Scan := preload("res://borrowed/scan.gd")
## Contract:
##   Scan.make(closed)   a lumpy skin 2.85 m high and at most 1.6 m wide, standing
##                       on the ground at its own origin. With `closed` false it
##                       is as a scanner leaves it: a shell, with no face where
##                       the body stood. With `closed` true the foot is added.
## The Collage kit has a found body with a unit and an origin of its own; this
## one is already in metres and already stands on its origin. It lists 340
## triangles as a shell and 360 with its foot.

const AROUND := 20       # corners in one ring
const RINGS := 9         # rings between the foot and the top
const HEIGHT := 2.85     # metres
const SHOULDER := 1.7    # metres: where the skin begins to close towards the top

## How far the skin is from the body's axis at a height and a turn.
static func reach(height: float, turn: float) -> float:
	var body := 0.727
	if height > SHOULDER:
		body *= sqrt(1.0 - pow((height - SHOULDER) / (HEIGHT - SHOULDER), 2.0))
	var square := pow(pow(absf(cos(turn)), 4.0) + pow(absf(sin(turn)), 4.0), -0.25)   # 1 on the axes, 1.19 on the diagonals
	var lumps := 1.0 + 0.06 * sin(3.0 * turn + 2.2 * height) + 0.04 * sin(5.0 * turn - 3.1 * height + 1.0)
	return body * square * lumps

static func make(closed: bool) -> ArrayMesh:
	var rings: Array = []
	for r in RINGS:
		var height := HEIGHT * r / RINGS
		var ring: Array[Vector3] = []
		for i in AROUND:
			var turn := TAU * i / AROUND
			var far := reach(height, turn)
			ring.append(Vector3(cos(turn) * far, height, sin(turn) * far))
		rings.append(ring)
	var top := Vector3(0.0, HEIGHT, 0.0)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_smooth_group(0)
	for r in RINGS:
		for i in AROUND:
			var j := (i + 1) % AROUND
			var a: Vector3 = rings[r][i]
			var b: Vector3 = rings[r][j]
			if r == RINGS - 1:
				for corner: Vector3 in [a, b, top]:
					tool.add_vertex(corner)
			else:
				var c: Vector3 = rings[r + 1][i]
				var d: Vector3 = rings[r + 1][j]
				for corner: Vector3 in [a, d, c, a, b, d]:
					tool.add_vertex(corner)
	if closed:
		# the face a scanner cannot see: a fan from the middle of the foot to its rim
		tool.set_smooth_group(1)
		for i in AROUND:
			for corner: Vector3 in [Vector3.ZERO, rings[0][(i + 1) % AROUND], rings[0][i]]:
				tool.add_vertex(corner)
	tool.index()
	tool.generate_normals()
	return tool.commit()
