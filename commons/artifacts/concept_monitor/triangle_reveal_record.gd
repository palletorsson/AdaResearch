extends RefCounted
## A read-only snapshot of the drawing tool. Coordinates and emitted faces are
## copied; this helper never closes a path, rebuilds a mesh or seeds a drawing.
const MAX_CORNERS := 256

static func capture(source: Node3D) -> Dictionary:
	if not is_instance_valid(source):
		return _empty()
	var title := str(source.name)
	if not source.has_method("get_experiment_state"):
		return _empty(title, "The source does not expose triangle experiment state.")
	if not source.is_inside_tree():
		return _empty(title, "The source must be in the scene tree to read world positions.")
	var state_value: Variant = source.call("get_experiment_state")
	if not state_value is Dictionary:
		return _empty(title, "The triangle experiment state is invalid.")
	var state: Dictionary = state_value
	var stored_value: Variant = source.get("placed_points")
	var path_value: Variant = source.get("current_path")
	var completed_value: Variant = source.get("completed_triangles")
	if not stored_value is Array or not path_value is Array or not completed_value is Array:
		return _empty(title, "The source point, path or completed-face record is invalid.")
	var stored: Array = stored_value
	var path: Array = path_value
	var completed: Array = completed_value
	var selected: Array = []
	var closed := false
	var face: Dictionary = {}
	if path.size() > 1:
		selected = path.duplicate()
	elif not completed.is_empty():
		if not completed[-1] is Dictionary:
			return _empty(title, "The latest completed face is invalid.")
		face = completed[-1]
		var loop_value: Variant = state.get("selected_loop_points", [])
		var face_loop: Variant = face.get("points")
		if not loop_value is Array or not face_loop is Array or loop_value != face_loop:
			return _empty(title, "The selected loop does not match the latest completed face.")
		selected = loop_value.duplicate()
		closed = true
	elif not path.is_empty():
		selected = path.duplicate()
	if selected.is_empty():
		return _empty(title)
	if selected.size() > MAX_CORNERS:
		return _empty(title, "The selected boundary exceeds the 256-corner monitor limit.")
	if closed and selected.size() < 3:
		return _empty(title, "A completed face needs at least three stored corners.")
	var source_world := source.global_transform
	if not source_world.is_finite() or source_world.basis.determinant() == 0.0:
		return _empty(title, "The source transform cannot be inverted.")
	var world_to_source := source_world.affine_inverse()
	var points := PackedVector3Array()
	var indices: Array[int] = []
	for entry: Variant in selected:
		if typeof(entry) != TYPE_INT or entry < 0 or entry >= stored.size():
			return _empty(title, "A boundary index lies outside the stored point list.")
		var point_value: Variant = stored[entry]
		if not point_value is Vector3 or not point_value.is_finite():
			return _empty(title, "A stored boundary position is invalid.")
		indices.append(int(entry))
		points.append(world_to_source * point_value)
	var triangles: Array[Dictionary] = []
	if closed:
		var mesh_node_value: Variant = face.get("mesh")
		if not mesh_node_value is MeshInstance3D or not is_instance_valid(mesh_node_value):
			return _empty(title, "The completed face has no valid mesh instance.")
		var mesh_node: MeshInstance3D = mesh_node_value
		if not mesh_node.is_inside_tree() or mesh_node.mesh == null:
			return _empty(title, "The completed face mesh is not available in the scene tree.")
		if mesh_node.mesh.get_surface_count() != 1:
			return _empty(title, "The drawing tool's completed face must have one surface.")
		if mesh_node.mesh.surface_get_primitive_type(0) != Mesh.PRIMITIVE_TRIANGLES:
			return _empty(title, "The completed surface is not a triangle list.")
		var arrays: Array = mesh_node.mesh.surface_get_arrays(0)
		if arrays.size() != Mesh.ARRAY_MAX:
			return _empty(title, "The completed face mesh arrays are incomplete.")
		var vertex_value: Variant = arrays[Mesh.ARRAY_VERTEX]
		var normal_value: Variant = arrays[Mesh.ARRAY_NORMAL]
		var mesh_indices: Variant = arrays[Mesh.ARRAY_INDEX]
		if not vertex_value is PackedVector3Array or not normal_value is PackedVector3Array:
			return _empty(title, "The completed face has no vertex or normal array.")
		if mesh_indices != null and (not mesh_indices is PackedInt32Array or not mesh_indices.is_empty()):
			return _empty(title, "The source face is indexed; six emitted vertices per fan triangle were expected.")
		var vertices: PackedVector3Array = vertex_value
		var normals: PackedVector3Array = normal_value
		var expected := (indices.size() - 2) * 6
		if vertices.size() != expected or normals.size() != expected:
			return _empty(title, "The source face does not contain six emitted vertices per fan triangle.")
		var mesh_to_source := world_to_source * mesh_node.global_transform
		if not mesh_to_source.is_finite() or mesh_to_source.basis.determinant() == 0.0:
			return _empty(title, "The completed face transform cannot transform normals.")
		var normal_basis := mesh_to_source.basis.inverse().transposed()
		for triangle_index in range(indices.size() - 2):
			var emitted_vertices := PackedVector3Array()
			var emitted_normals := PackedVector3Array()
			for offset in range(6):
				var emitted_index := triangle_index * 6 + offset
				if not vertices[emitted_index].is_finite() or not normals[emitted_index].is_finite():
					return _empty(title, "The source mesh contains a non-finite vertex or normal.")
				emitted_vertices.append(mesh_to_source * vertices[emitted_index])
				# Normals are covectors: inverse transpose preserves perpendicularity
				# when either the mesh or its source has a nonuniform scale.
				emitted_normals.append((normal_basis * normals[emitted_index]).normalized())
			var triangle_indices: Array[int] = [indices[0], indices[triangle_index + 1], indices[triangle_index + 2]]
			triangles.append({"vertices": emitted_vertices, "normals": emitted_normals, "indices": triangle_indices})
	var result := {
		"points": points, "indices": indices, "closed": closed,
		"fills_visible": bool(state.get("fills_visible", true)),
		"triangles": triangles, "source_name": title, "error": "",
	}
	result["signature"] = hash(result)
	return result

static func _empty(title: String = "", error: String = "") -> Dictionary:
	var indices: Array[int] = []
	var triangles: Array[Dictionary] = []
	var result := {
		"points": PackedVector3Array(), "indices": indices, "closed": false,
		"fills_visible": false, "triangles": triangles,
		"source_name": title, "error": error,
	}
	result["signature"] = hash(result)
	return result
