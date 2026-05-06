# GrabOctahedron.gd - Grabbable octahedron (8 faces, 6 vertices, 12 edges)
@tool
extends GrabbablePolyhedron

func _get_object_name() -> String:
	return "Octahedron"

func _get_geometry() -> Dictionary:
	var s := object_scale
	var vertices: Array[Vector3] = [
		Vector3(s, 0, 0),
		Vector3(-s, 0, 0),
		Vector3(0, s, 0),
		Vector3(0, -s, 0),
		Vector3(0, 0, s),
		Vector3(0, 0, -s)
	]
	var faces: Array = [
		[0, 2, 4], [0, 4, 3], [0, 3, 5], [0, 5, 2],
		[1, 4, 2], [1, 3, 4], [1, 5, 3], [1, 2, 5]
	]
	return {"vertices": vertices, "faces": faces}
