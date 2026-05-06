## ScaleFaceOp — Scale selected faces relative to their centroids.
## Does not change topology, only vertex positions.
## Params:
##   scale: float = 1.2 — uniform scale factor (>1 = grow, <1 = shrink)
extends MeshRule
class_name ScaleFaceOp

func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var scale_factor: float = params.get("scale", 1.2)

	# Track which vertices have been moved to avoid double-scaling shared verts
	var moved: Dictionary = {}

	for face_idx in selected:
		if face_idx >= mesh.faces.size():
			continue
		var f := mesh.faces[face_idx]
		var centroid := mesh.get_face_centroid(face_idx)

		for vi in f:
			if not moved.has(vi):
				mesh.vertices[vi] = centroid + (mesh.vertices[vi] - centroid) * scale_factor
				moved[vi] = true

	mesh._adjacency_dirty = true
