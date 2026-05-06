# GrabCube.gd - Grabbable cube/hexahedron (6 faces, 8 vertices, 12 edges)
@tool
extends GrabbablePolyhedron

func _get_object_name() -> String:
	return "Cube"

func _get_geometry() -> Dictionary:
	var s := object_scale * 0.5
	var vertices: Array[Vector3] = [
		Vector3(-s, -s, s),
		Vector3(s, -s, s),
		Vector3(s, s, s),
		Vector3(-s, s, s),
		Vector3(-s, -s, -s),
		Vector3(s, -s, -s),
		Vector3(s, s, -s),
		Vector3(-s, s, -s)
	]
	var faces: Array = [
		[0, 1, 2], [0, 2, 3],  # Front
		[5, 4, 7], [5, 7, 6],  # Back
		[4, 0, 3], [4, 3, 7],  # Left
		[1, 5, 6], [1, 6, 2],  # Right
		[3, 2, 6], [3, 6, 7],  # Top
		[4, 5, 1], [4, 1, 0]   # Bottom
	]
	return {"vertices": vertices, "faces": faces}
