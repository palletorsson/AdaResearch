extends RefCounted
## Supplied adapter: the installed glass vessel's construction and solver.
const Solver = preload("solver.gd")
const RINGS := 14
const SEGMENTS := 22
const RADIUS := 0.55
var sim = Solver.new()
var indices := PackedInt32Array()

func _init() -> void:
	sim.stiffness = 0.6
	sim.damping = 0.995
	sim.gravity = Vector3(0, -9.8, 0)
	sim.floor_y = -10.0
	sim.constraint_passes = 5
	for ring in RINGS + 1:
		var phi := PI * float(ring) / RINGS
		var y := cos(phi) * RADIUS
		var ring_radius := sin(phi) * RADIUS
		for segment in SEGMENTS:
			var theta := TAU * float(segment) / SEGMENTS
			var p := Vector3(ring_radius * cos(theta), y, ring_radius * sin(theta))
			var pinned := p.y > RADIUS * (1.0 - 0.12 * 2.0)
			if not pinned:
				p *= 1.2
			sim.add_particle(p, pinned)
	for ring in RINGS:
		for segment in SEGMENTS:
			var next := (segment + 1) % SEGMENTS
			var a := ring * SEGMENTS + segment
			var b := ring * SEGMENTS + next
			var c := (ring + 1) * SEGMENTS + segment
			var d := (ring + 1) * SEGMENTS + next
			sim.add_spring(a, b)
			sim.add_spring(a, c)
			sim.add_spring(a, d)
			indices.append_array([a, c, d, a, d, b])

func mesh_for(points: PackedVector3Array, faces: PackedInt32Array) -> ArrayMesh:
	var normals := PackedVector3Array()
	normals.resize(points.size())
	for i in range(0, faces.size(), 3):
		var a := faces[i]
		var b := faces[i + 1]
		var c := faces[i + 2]
		var n := (points[b] - points[a]).cross(points[c] - points[a]).normalized()
		normals[a] += n
		normals[b] += n
		normals[c] += n
	for i in normals.size():
		normals[i] = normals[i].normalized() if normals[i].length_squared() > 0.0 else Vector3.UP
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = faces
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
