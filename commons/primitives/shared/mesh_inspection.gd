extends RefCounted
## Read the actual triangle stream. Overlays use vertex positions, not vertex-ID modulo.
static func inspect(mesh: Mesh) -> Dictionary:
	var submitted := 0
	var surface_triangles := 0
	var wire := ImmediateMesh.new()
	wire.surface_begin(Mesh.PRIMITIVE_LINES)
	for surface in mesh.get_surface_count():
		if mesh is ArrayMesh and (mesh as ArrayMesh).surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES: continue
		var arrays: Array = mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var size: int = indices.size() if not indices.is_empty() else vertices.size()
		for i in range(0,size-2,3):
			submitted += 1
			var a: Vector3 = vertices[indices[i] if not indices.is_empty() else i]
			var b: Vector3 = vertices[indices[i+1] if not indices.is_empty() else i+1]
			var c: Vector3 = vertices[indices[i+2] if not indices.is_empty() else i+2]
			if (b-a).cross(c-a).length_squared() < 1e-16: continue
			surface_triangles += 1
			for pair in [[a,b],[b,c],[c,a]]:
				wire.surface_add_vertex(pair[0])
				wire.surface_add_vertex(pair[1])
	wire.surface_end()
	return {"submitted":submitted,"surface_triangles":surface_triangles,"wire":wire}

static func overlay(mesh: Mesh, measured: Dictionary = {}) -> MeshInstance3D:
	var data: Dictionary = inspect(mesh) if measured.is_empty() else measured
	var node := MeshInstance3D.new()
	node.name = "MeshInspectionEdges"
	node.mesh = data.wire
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.05,0.10,0.16)
	node.material_override = material
	# Slight enlargement avoids coplanar flicker; the count excludes this overlay.
	node.scale = Vector3.ONE * 1.002
	return node

static func apply(subject: MeshInstance3D, color: Color, show_edges: bool) -> void:
	var old := subject.get_node_or_null("MeshInspectionEdges")
	if old:
		subject.remove_child(old)
		old.queue_free()
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.65
	subject.material_override = material
	var wire := overlay(subject.mesh)
	wire.visible = show_edges
	subject.add_child(wire)
