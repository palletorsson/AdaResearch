extends RefCounted
## Piecewise-constant occupancy: sample once per box, emit only exposed faces.
## Unlike marching tetrahedra, this preserves square faces and stepped edges.
const DIRECTIONS := [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.UP, Vector3i.DOWN, Vector3i.BACK, Vector3i.FORWARD]

static func build(field: Callable, bounds: AABB, step: float) -> ArrayMesh:
	var size := Vector3i(ceil(bounds.size.x/step), ceil(bounds.size.y/step), ceil(bounds.size.z/step))
	var spacing := bounds.size / Vector3(size)
	var occupied := PackedByteArray()
	occupied.resize(size.x * size.y * size.z)
	for z in range(size.z):
		for y in range(size.y):
			for x in range(size.x):
				var p := bounds.position + (Vector3(x,y,z) + Vector3.ONE * 0.5) * spacing
				occupied[x + size.x * (y + size.y * z)] = 1 if field.call(p) < 0 else 0
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(size.z):
		for y in range(size.y):
			for x in range(size.x):
				var cell := Vector3i(x,y,z)
				if occupied[x + size.x * (y + size.y * z)] == 0:
					continue
				var centre := bounds.position + (Vector3(cell) + Vector3.ONE * 0.5) * spacing
				for direction: Vector3i in DIRECTIONS:
					var neighbour := cell + direction
					if neighbour.x >= 0 and neighbour.x < size.x and neighbour.y >= 0 and neighbour.y < size.y and neighbour.z >= 0 and neighbour.z < size.z:
						if occupied[neighbour.x + size.x * (neighbour.y + size.y * neighbour.z)] != 0:
							continue
					var n := Vector3(direction)
					var tangent := Vector3.RIGHT if direction.y != 0 else Vector3.UP
					var bitangent := n.cross(tangent)
					var face := centre + n * spacing * 0.5
					var u := tangent * spacing * 0.5
					var v := bitangent * spacing * 0.5
					tool.set_normal(n)
					for p in [face-u-v, face-u+v, face+u-v, face+u-v, face-u+v, face+u+v]:
						tool.add_vertex(p)
	tool.index()
	return tool.commit()
