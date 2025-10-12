# PrimitiveMeshBuilder.gd - SurfaceTool helpers for simple primitives
extends Object
class_name PrimitiveMeshBuilder

static func build_mesh(vertices: Array, faces: Array, options: Dictionary = {}) -> ArrayMesh:
	var double_sided: bool = bool(options.get("double_sided", false))
	var generate_normals: bool = bool(options.get("generate_normals", false))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in faces:
		var indices := _extract_indices(face)
		if indices.size() != 3:
			continue
		var v0: Vector3 = vertices[indices[0]]
		var v1: Vector3 = vertices[indices[1]]
		var v2: Vector3 = vertices[indices[2]]
		var normal: Vector3 = _extract_normal(face)
		if normal == Vector3.ZERO:
			normal = _compute_normal(v0, v1, v2)
		if normal == Vector3.ZERO:
			continue
		_add_triangle(st, v0, v1, v2, normal, double_sided)
	if generate_normals:
		st.generate_normals()
	return st.commit()

static func build_mesh_instance(vertices: Array, faces: Array, config: Dictionary = {}) -> MeshInstance3D:
	var mesh_options := {}
	if config.has("double_sided"):
		mesh_options["double_sided"] = config["double_sided"]
	if config.has("generate_normals"):
		mesh_options["generate_normals"] = config["generate_normals"]
	var mesh := build_mesh(vertices, faces, mesh_options)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.name = config.get("name", "Primitive")
	if config.has("material"):
		instance.material_override = config["material"]
	return instance

static func _extract_indices(face) -> Array:
	if typeof(face) == TYPE_DICTIONARY:
		return face.get("indices", [])
	return face

static func _extract_normal(face) -> Vector3:
	if typeof(face) == TYPE_DICTIONARY:
		return face.get("normal", Vector3.ZERO)
	return Vector3.ZERO

static func _compute_normal(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var normal := (b - a).cross(c - a)
	if normal.length_squared() == 0.0:
		return Vector3.ZERO
	return normal.normalized()

static func _add_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3, double_sided: bool) -> void:
	st.set_normal(normal)
	st.add_vertex(a)
	st.set_normal(normal)
	st.add_vertex(b)
	st.set_normal(normal)
	st.add_vertex(c)
	if double_sided:
		var back_normal := -normal
		st.set_normal(back_normal)
		st.add_vertex(a)
		st.set_normal(back_normal)
		st.add_vertex(c)
		st.set_normal(back_normal)
		st.add_vertex(b)
