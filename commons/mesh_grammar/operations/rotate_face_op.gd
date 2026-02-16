## RotateFaceOp — Rotate selected faces around their normal axis.
## Does not change topology, only vertex positions.
## Params:
##   angle_degrees: float = 15.0 — rotation angle in degrees
extends MeshRule
class_name RotateFaceOp

func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var angle: float = deg_to_rad(params.get("angle_degrees", 15.0))

	var moved: Dictionary = {}

	for face_idx in selected:
		if face_idx >= mesh.faces.size():
			continue
		var f := mesh.faces[face_idx]
		var centroid := mesh.get_face_centroid(face_idx)
		var normal := mesh.get_face_normal(face_idx)

		for vi in f:
			if not moved.has(vi):
				var rel: Vector3 = mesh.vertices[vi] - centroid
				var rotated := rel.rotated(normal, angle)
				mesh.vertices[vi] = centroid + rotated
				moved[vi] = true

	mesh._adjacency_dirty = true
