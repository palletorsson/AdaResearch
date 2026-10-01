extends MeshInstance3D
## drafted_solid.gd
## The solid from Dürer's engraving Melencolia I: a cube pulled along one of
## its diagonals, stood on that diagonal, with the two corners on it cut off.
## With the default values the box is about 0.79 x 0.99 x 0.79 m and the mesh
## lists 20 triangles (6 five-sided faces as 3 each, plus the 2 cut faces).

const EDGE: float = 0.5

@export var stretch: float = 1.53
@export var cut: float = 0.38

var _verts: PackedVector3Array = PackedVector3Array()
var _normals: PackedVector3Array = PackedVector3Array()
var _indices: PackedInt32Array = PackedInt32Array()


func _ready() -> void:
	build()


func build() -> void:
	_verts = PackedVector3Array()
	_normals = PackedVector3Array()
	_indices = PackedInt32Array()

	var h: float = EDGE * 0.5
	var c: float = clampf(cut, 0.0, 1.0)

	# The cube sits around the origin, corners at (+-h, +-h, +-h).
	# The diagonal runs from (-h, -h, -h) to (h, h, h); those two corners go.
	for s: float in [1.0, -1.0]:
		var apex: Vector3 = Vector3(h, h, h) * s
		var cap: PackedVector3Array = PackedVector3Array()
		for axis in 3:
			var u: int = (axis + 1) % 3
			var v: int = (axis + 2) % 3

			# The square face of the cube that keeps apex[axis]:
			# apex -> a -> b -> d -> back to apex.
			var a: Vector3 = apex
			a[u] = -apex[u]
			var b: Vector3 = a
			b[v] = -apex[v]
			var d: Vector3 = apex
			d[v] = -apex[v]

			# The apex is replaced by the two cut points on its edges.
			_add_face(PackedVector3Array([a, b, d, apex.lerp(d, c), apex.lerp(a, c)]))

			# One corner of the small triangle that closes the cut.
			var along_edge: Vector3 = apex
			along_edge[axis] = -apex[axis]
			cap.append(apex.lerp(along_edge, c))
		_add_face(cap)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _verts
	arrays[Mesh.ARRAY_NORMAL] = _normals
	arrays[Mesh.ARRAY_INDEX] = _indices

	var solid: ArrayMesh = ArrayMesh.new()
	solid.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = solid


func triangles() -> int:
	if mesh == null or mesh.get_surface_count() == 0:
		return 0
	var arrays: Array = mesh.surface_get_arrays(0)
	if arrays[Mesh.ARRAY_INDEX] == null:
		var loose: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		@warning_ignore("integer_division")
		return loose.size() / 3
	var listed: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	@warning_ignore("integer_division")
	return listed.size() / 3


# Turns a point of the cube so the diagonal stands upright, and pulls it
# along that diagonal. The turn is the shortest one that brings the diagonal
# to +Y, so the solid's middle stays on the origin.
func _place(p: Vector3) -> Vector3:
	var diagonal: Vector3 = Vector3(1.0, 1.0, 1.0).normalized()
	var keep: Vector3 = Vector3(-1.0, 0.0, 1.0).normalized()  # the turn's axis, stays put
	var before: Vector3 = keep.cross(diagonal)                 # third direction, before the turn
	var after: Vector3 = keep.cross(Vector3.UP)                # the same direction, after it
	return Vector3.UP * (p.dot(diagonal) * stretch) \
			+ keep * p.dot(keep) \
			+ after * p.dot(before)


# Adds one flat face given its corners in order around the face (either way).
# The face is placed, then its corners are put in clockwise order as seen
# from outside, because that is the side Godot draws.
func _add_face(corners: PackedVector3Array) -> void:
	var face: PackedVector3Array = PackedVector3Array()
	var centre: Vector3 = Vector3.ZERO
	for p in corners:
		var q: Vector3 = _place(p)
		face.append(q)
		centre += q
	if face.size() < 3:
		return
	centre /= face.size()

	var normal: Vector3 = (face[1] - face[0]).cross(face[2] - face[0])
	if normal.length_squared() < 1e-12:
		return  # a face with no area (cut = 0), nothing to draw
	normal = normal.normalized()

	# The solid is convex around the origin, so "outward" is the side the
	# face's own centre points to.
	if normal.dot(centre) > 0.0:
		# The corners run counter-clockwise from outside: turn them round.
		face.reverse()
	else:
		# Already clockwise from outside; only the normal pointed inward.
		normal = -normal

	var first: int = _verts.size()
	for q in face:
		_verts.append(q)
		_normals.append(normal)
	for i in range(1, face.size() - 1):
		_indices.append(first)
		_indices.append(first + i)
		_indices.append(first + i + 1)
