# GrabDodecahedron.gd - Grabbable dodecahedron (12 faces, 20 vertices, 30 edges)
@tool
extends GrabbablePolyhedron

const PHI := 1.618033988749895

func _get_object_name() -> String:
	return "Dodecahedron"

func _get_geometry() -> Dictionary:
	var s := object_scale
	var a := 1.0 / PHI
	var b := PHI
	var vertices: Array[Vector3] = [
		Vector3(1, 1, 1), Vector3(1, 1, -1), Vector3(1, -1, 1), Vector3(-1, 1, 1),
		Vector3(-1, -1, 1), Vector3(-1, 1, -1), Vector3(1, -1, -1), Vector3(-1, -1, -1),
		Vector3(0, a, b), Vector3(0, -a, b), Vector3(0, a, -b), Vector3(0, -a, -b),
		Vector3(a, b, 0), Vector3(-a, b, 0), Vector3(a, -b, 0), Vector3(-a, -b, 0),
		Vector3(b, 0, a), Vector3(-b, 0, a), Vector3(b, 0, -a), Vector3(-b, 0, -a)
	]
	for i in range(vertices.size()):
		vertices[i] = vertices[i].normalized() * s
	
	var pentagons: Array = [
		[3, 17, 4, 9, 8], [0, 12, 13, 3, 8], [0, 8, 9, 2, 16], [0, 16, 18, 1, 12],
		[1, 18, 6, 14, 12], [2, 9, 4, 15, 14], [2, 14, 6, 18, 16], [3, 13, 5, 19, 17],
		[4, 17, 19, 7, 15], [5, 13, 12, 1, 10], [5, 10, 11, 7, 19], [6, 11, 10, 1, 18]
	]
	
	var faces: Array = []
	for pentagon in pentagons:
		var pivot = pentagon[0]
		for i in range(1, pentagon.size() - 1):
			faces.append([pivot, pentagon[i], pentagon[i + 1]])
	
	return {"vertices": vertices, "faces": faces}
