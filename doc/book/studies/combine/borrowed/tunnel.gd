extends RefCounted
## Borrowed from Implicit bodies (chapter 36), in a small version: a body that
## is a function and has no corner until it is asked for one. Use it by path:
##   const Tunnel := preload("res://borrowed/tunnel.gd")
## Contract:
##   Tunnel.value(p)      below 0 inside the tunnel, 0 on its skin, above 0 outside.
##                        The tunnel lies along z and stands on its own origin:
##                        a level floor at height 0, 0.8 m wide, 2.1 m high,
##                        2.4 m long.
##   Tunnel.make(spokes)  the skin as a closed mesh: it asks value() along
##                        `spokes` spokes around the tunnel's middle line and
##                        closes both ends.
## This small version asks along spokes, which is enough for a body that every
## spoke leaves once. The Implicit bodies kit has that chapter's own mesher.

const HALF_WIDTH := 0.4     # metres
const MIDDLE := 1.0         # the height of the middle line above the floor
const HALF_HEIGHT := 1.1
const HALF_LENGTH := 1.2

static func value(p: Vector3) -> float:
	var across := pow(p.x / HALF_WIDTH, 4.0) + pow((p.y - MIDDLE) / HALF_HEIGHT, 4.0) - 1.0
	var under_the_floor := -p.y
	var past_the_ends := absf(p.z) / HALF_LENGTH - 1.0
	return maxf(across, maxf(under_the_floor, past_the_ends))   # max: inside all three

static func make(spokes: int) -> ArrayMesh:
	spokes = clampi(spokes, 4, 96)
	var axis := Vector3(0.0, MIDDLE, 0.0)
	var rim: Array[Vector3] = []          # where each spoke leaves the body, at z = 0
	for i in spokes:
		var turn := TAU * i / spokes
		var way := Vector3(cos(turn), sin(turn), 0.0)
		var near := 0.0                    # inside
		var far := 2.0                     # outside
		for step in 24:                    # halve the stretch between them 24 times
			var middle := (near + far) / 2.0
			if value(axis + way * middle) < 0.0:
				near = middle
			else:
				far = middle
		rim.append(axis + way * near)
	var front := Vector3(0.0, 0.0, HALF_LENGTH)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in spokes:
		var a := rim[i]
		var b := rim[(i + 1) % spokes]
		# the wall between two spokes: two triangles, seen from outside
		for corner: Vector3 in [a + front, b + front, b - front, a + front, b - front, a - front]:
			tool.add_vertex(corner)
		# and one triangle of each end
		for corner: Vector3 in [axis + front, b + front, a + front, axis - front, a - front, b - front]:
			tool.add_vertex(corner)
	tool.generate_normals()
	return tool.commit()
