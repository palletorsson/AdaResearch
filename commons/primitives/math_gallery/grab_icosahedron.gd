# GrabIcosahedron.gd - Grabbable icosahedron (20 faces, 12 vertices, 30 edges)
@tool
extends GrabbablePolyhedron

const PHI := 1.618033988749895

func _get_object_name() -> String:
	return "Icosahedron"

func _get_geometry() -> Dictionary:
	var s := object_scale
	var vertices: Array[Vector3] = [
		Vector3(0, 1, PHI), Vector3(0, -1, PHI), Vector3(0, 1, -PHI), Vector3(0, -1, -PHI),
		Vector3(1, PHI, 0), Vector3(-1, PHI, 0), Vector3(1, -PHI, 0), Vector3(-1, -PHI, 0),
		Vector3(PHI, 0, 1), Vector3(-PHI, 0, 1), Vector3(PHI, 0, -1), Vector3(-PHI, 0, -1)
	]
	for i in range(vertices.size()):
		vertices[i] = vertices[i].normalized() * s
	
	var faces: Array = [
		[0, 1, 8], [0, 8, 4], [0, 4, 5], [0, 5, 9], [0, 9, 1],
		[1, 6, 8], [8, 6, 10], [8, 10, 4], [4, 10, 2], [4, 2, 5],
		[5, 2, 11], [5, 11, 9], [9, 11, 7], [9, 7, 1], [1, 7, 6],
		[3, 6, 7], [3, 7, 11], [3, 11, 2], [3, 2, 10], [3, 10, 6]
	]
	return {"vertices": vertices, "faces": faces}
