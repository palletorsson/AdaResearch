extends RefCounted
## Read-only source geometry and a rigid unfolding of its four triangle faces.
## The unfolding is an explanatory motion: it does not run on the held artifact.
const BASE_FACE := 3
const EPSILON := 0.00001

static func capture(source: Node3D) -> Dictionary:
	if not is_instance_valid(source):
		return _empty("", "No tetrahedron is available.")
	var title := str(source.name)
	if not source.is_inside_tree() or not source.has_method("_tetrahedron_geometry"):
		return _empty(title, "The source must be a tetrahedron in the scene tree.")
	var geometry_value: Variant = source.call("_tetrahedron_geometry")
	if not geometry_value is Dictionary:
		return _empty(title, "The source geometry is invalid.")
	var geometry: Dictionary = geometry_value
	var vertex_value: Variant = geometry.get("vertices")
	var face_value: Variant = geometry.get("faces")
	if not vertex_value is Array or not face_value is Array or vertex_value.size() != 4 or face_value.size() != 4:
		return _empty(title, "The source must provide four positions and four triangular faces.")
	var points := PackedVector3Array()
	for point: Variant in vertex_value:
		if not point is Vector3 or not point.is_finite():
			return _empty(title, "A source position is invalid.")
		points.append(point)
	var volume6 := (points[1] - points[0]).dot((points[2] - points[0]).cross(points[3] - points[0]))
	if absf(volume6) < 0.00000001:
		return _empty(title, "The four source positions do not enclose a volume.")
	var faces: Array = []
	var face_keys: Array[String] = []
	for row: Variant in face_value:
		if not row is Array or row.size() != 3:
			return _empty(title, "Every source face must contain three vertex indices.")
		var copied: Array[int] = []
		for index: Variant in row:
			if typeof(index) != TYPE_INT or index < 0 or index >= 4 or copied.has(index):
				return _empty(title, "A source face has an invalid or repeated vertex index.")
			copied.append(index)
		var sorted := copied.duplicate()
		sorted.sort()
		var key := str(sorted)
		if face_keys.has(key):
			return _empty(title, "The source repeats a triangular face.")
		face_keys.append(key)
		faces.append(copied)
	var instance := source.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if instance == null or instance.mesh == null or instance.mesh.get_surface_count() != 1:
		return _empty(title, "The source's rendered mesh is not available.")
	if not instance.mesh is ArrayMesh or instance.mesh.surface_get_primitive_type(0) != Mesh.PRIMITIVE_TRIANGLES:
		return _empty(title, "The source's rendered mesh must be a triangle array.")
	var arrays: Array = instance.mesh.surface_get_arrays(0)
	var vertices_value: Variant = arrays[Mesh.ARRAY_VERTEX]
	var normals_value: Variant = arrays[Mesh.ARRAY_NORMAL]
	var indices_value: Variant = arrays[Mesh.ARRAY_INDEX]
	if not vertices_value is PackedVector3Array or not normals_value is PackedVector3Array:
		return _empty(title, "The source has no rendered vertex and normal arrays.")
	if indices_value != null and (not indices_value is PackedInt32Array or not indices_value.is_empty()):
		return _empty(title, "The source must emit three vertices directly for each face.")
	var vertices: PackedVector3Array = vertices_value
	var normals: PackedVector3Array = normals_value
	if vertices.size() != 12 or normals.size() != 12:
		return _empty(title, "The rendered source does not contain four three-vertex faces.")
	# This is a direct child. Its local transform is already the exact mesh-to-
	# source frame; root position/rotation/nonuniform scale must not enter it.
	var mesh_to_source := instance.transform
	if not mesh_to_source.is_finite() or is_zero_approx(mesh_to_source.basis.determinant()):
		return _empty(title, "The rendered mesh has an invalid local transform.")
	var normal_basis := mesh_to_source.basis.inverse().transposed()
	var triangles: Array[Dictionary] = []
	for face_index in range(4):
		var emitted := PackedVector3Array()
		var emitted_normals := PackedVector3Array()
		for corner in range(3):
			var index := face_index * 3 + corner
			if not vertices[index].is_finite() or not normals[index].is_finite() or normals[index].is_zero_approx():
				return _empty(title, "The rendered source contains an invalid vertex or normal.")
			var point := mesh_to_source * vertices[index]
			if point.distance_to(points[faces[face_index][corner]]) > EPSILON:
				return _empty(title, "The rendered mesh no longer matches the source face list.")
			emitted.append(point)
			# Preserve the source normal, including its inward orientation. Do not
			# replace it with an outward normal just to stage the unfolding.
			emitted_normals.append(normal_basis * normals[index])
		triangles.append({"vertices": emitted, "normals": emitted_normals})
	var result := {"points": points, "faces": faces, "triangles": triangles,
		"source_name": title, "error": ""}
	result["signature"] = hash(result)
	return result

static func unfold_transform(record: Dictionary, face_index: int, amount: float) -> Transform3D:
	if not _valid(record) or face_index < 0 or face_index > 3 or face_index == BASE_FACE or amount <= 0.0:
		return Transform3D.IDENTITY
	var points: PackedVector3Array = record.points
	var face: Array = record.faces[face_index]
	var base: Array = record.faces[BASE_FACE]
	var shared: Array[int] = []
	var moving := -1
	var inside := -1
	for index: int in face:
		if base.has(index): shared.append(index)
		else: moving = index
	for index: int in base:
		if not face.has(index): inside = index
	if shared.size() != 2 or moving < 0 or inside < 0:
		return Transform3D.IDENTITY
	var anchor: Vector3 = points[shared[0]]
	var axis: Vector3 = (points[shared[1]] - anchor).normalized()
	var moving_offset: Vector3 = points[moving] - anchor
	var base_offset: Vector3 = points[inside] - anchor
	var radial: Vector3 = moving_offset - axis * moving_offset.dot(axis)
	# The target lies in the base plane on the OTHER side of the hinge from
	# the base's third corner. Rotating to this direction creates a flat net.
	var outside: Vector3 = -(base_offset - axis * base_offset.dot(axis)).normalized()
	var angle := atan2(axis.dot(radial.cross(outside)), radial.dot(outside))
	var rotation := Basis(axis, angle * clampf(amount, 0.0, 1.0))
	return Transform3D(rotation, anchor - rotation * anchor)

static func display_basis(record: Dictionary) -> Basis:
	if not _valid(record):
		return Basis.IDENTITY
	var points: PackedVector3Array = record.points
	var base: Array = record.faces[BASE_FACE]
	var a: Vector3 = points[base[0]]
	var b: Vector3 = points[base[1]]
	var c: Vector3 = points[base[2]]
	var outward := (b - a).cross(c - a).normalized()
	var centre := (points[0] + points[1] + points[2] + points[3]) * 0.25
	if outward.dot(centre - a) > 0.0:
		outward = -outward
	var x := (b - a).normalized()
	var y := -outward
	var z := x.cross(y).normalized()
	# Converts source-local points to a view where the base is horizontal and
	# its outward normal faces down. No source vertex is modified.
	return Basis(x, y, z).transposed()

static func _valid(record: Dictionary) -> bool:
	return str(record.get("error", "")).is_empty() and record.get("points", PackedVector3Array()).size() == 4 and record.get("faces", []).size() == 4

static func _empty(title: String = "", message: String = "") -> Dictionary:
	var result := {"points": PackedVector3Array(), "faces": [], "triangles": [],
		"source_name": title, "error": message}
	result["signature"] = hash(result)
	return result
