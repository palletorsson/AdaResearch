## ExtrudeFaceOp — Push selected faces outward along their normal.
## Creates side walls connecting old edges to new offset face.
## Params:
##   distance: float = 0.5  — how far to push
##   scale: float = 1.0     — scale the extruded face (< 1.0 = taper)
##   top_tag: String = "extruded_top"
##   side_tag: String = "extruded_side"
extends MeshRule
class_name ExtrudeFaceOp

func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var distance: float = params.get("distance", 0.5)
	var scale_factor: float = params.get("scale", 1.0)
	var top_tag: String = params.get("top_tag", "extruded_top")
	var side_tag: String = params.get("side_tag", "extruded_side")

	# Process in reverse to avoid index invalidation
	var sorted: Array = Array(selected)
	sorted.sort()
	sorted.reverse()

	for face_idx in sorted:
		if face_idx >= mesh.faces.size():
			continue
		var f := mesh.faces[face_idx]
		var v0: Vector3 = mesh.vertices[f[0]]
		var v1: Vector3 = mesh.vertices[f[1]]
		var v2: Vector3 = mesh.vertices[f[2]]
		var normal := mesh.get_face_normal(face_idx)
		var centroid := mesh.get_face_centroid(face_idx)
		var old_depth: int = 0
		if face_idx < mesh.face_depth.size():
			old_depth = mesh.face_depth[face_idx]

		# New top vertices (offset + scaled)
		var nv0 := centroid + (v0 - centroid) * scale_factor + normal * distance
		var nv1 := centroid + (v1 - centroid) * scale_factor + normal * distance
		var nv2 := centroid + (v2 - centroid) * scale_factor + normal * distance

		var ni0 := mesh.add_vertex(nv0)
		var ni1 := mesh.add_vertex(nv1)
		var ni2 := mesh.add_vertex(nv2)

		# Remove original face
		mesh.remove_faces(PackedInt32Array([face_idx]))

		# Add top face
		mesh.add_face(PackedInt32Array([ni0, ni1, ni2]),
			PackedStringArray([top_tag]), old_depth + 1)

		# Add 3 side quads (each as 2 triangles)
		# Side between edge (v0,v1) and (nv0,nv1)
		var old_i0 := f[0]; var old_i1 := f[1]; var old_i2 := f[2]
		_add_side_quad(mesh, old_i0, old_i1, ni1, ni0, side_tag, old_depth + 1)
		_add_side_quad(mesh, old_i1, old_i2, ni2, ni1, side_tag, old_depth + 1)
		_add_side_quad(mesh, old_i2, old_i0, ni0, ni2, side_tag, old_depth + 1)

func _add_side_quad(mesh: MeshData, a: int, b: int, c: int, d: int,
		tag: String, depth: int) -> void:
	mesh.add_face(PackedInt32Array([a, b, c]), PackedStringArray([tag]), depth)
	mesh.add_face(PackedInt32Array([a, c, d]), PackedStringArray([tag]), depth)
