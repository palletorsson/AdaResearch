# GrabTetrahedron.gd - Grabbable tetrahedron (4 faces, 4 vertices, 6 edges)
@tool
extends GrabbablePolyhedron

func _get_object_name() -> String:
	return "Tetrahedron"

func _get_geometry() -> Dictionary:
	var s := object_scale
	var vertices: Array[Vector3] = [
		Vector3(1, 1, 1) * s,
		Vector3(1, -1, -1) * s,
		Vector3(-1, 1, -1) * s,
		Vector3(-1, -1, 1) * s
	]
	var faces: Array = [
		[0, 2, 1],
		[0, 1, 3],
		[0, 3, 2],
		[1, 2, 3]
	]
	return {"vertices": vertices, "faces": faces}
