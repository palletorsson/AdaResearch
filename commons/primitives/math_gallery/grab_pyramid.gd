# GrabPyramid.gd - Grabbable square pyramid (5 faces, 5 vertices, 8 edges)
@tool
extends GrabbablePolyhedron

func _get_object_name() -> String:
	return "Pyramid"

func _get_geometry() -> Dictionary:
	var s := object_scale
	var h := s * 1.2  # Height
	var b := s * 0.8  # Base half-size
	var vertices: Array[Vector3] = [
		Vector3(-b, 0, -b),  # Base corners
		Vector3(b, 0, -b),
		Vector3(b, 0, b),
		Vector3(-b, 0, b),
		Vector3(0, h, 0)     # Apex
	]
	var faces: Array = [
		[0, 2, 1], [0, 3, 2],  # Base (2 triangles)
		[0, 1, 4],             # Side faces
		[1, 2, 4],
		[2, 3, 4],
		[3, 0, 4]
	]
	return {"vertices": vertices, "faces": faces}
