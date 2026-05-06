# GrabBipyramid.gd - Grabbable octahedral bipyramid (8 faces, 6 vertices, 12 edges)
@tool
extends GrabbablePolyhedron

func _get_object_name() -> String:
	return "Bipyramid"

func _get_geometry() -> Dictionary:
	var s := object_scale
	var h := s * 1.3  # Height of apexes
	var r := s * 0.7  # Radius of square base
	var vertices: Array[Vector3] = [
		Vector3(0, h, 0),      # Top apex
		Vector3(0, -h, 0),     # Bottom apex
		Vector3(r, 0, r),      # Base vertices
		Vector3(-r, 0, r),
		Vector3(-r, 0, -r),
		Vector3(r, 0, -r)
	]
	var faces: Array = [
		[0, 2, 3], [0, 3, 4], [0, 4, 5], [0, 5, 2],  # Top faces
		[1, 3, 2], [1, 4, 3], [1, 5, 4], [1, 2, 5]   # Bottom faces
	]
	return {"vertices": vertices, "faces": faces}
