## DeleteFaceOp — Remove selected faces from the mesh.
## Creates openings/holes. Optionally cleans up orphan vertices.
## Params:
##   cleanup_vertices: bool = false — remove orphan vertices after deletion
extends MeshRule
class_name DeleteFaceOp

func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var cleanup: bool = params.get("cleanup_vertices", false)
	mesh.remove_faces(selected)
	if cleanup:
		mesh.remove_orphan_vertices()
