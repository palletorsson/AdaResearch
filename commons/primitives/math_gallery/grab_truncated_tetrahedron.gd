# GrabTruncatedTetrahedron.gd - Grabbable truncated tetrahedron (8 faces: 4 triangles + 4 hexagons)
@tool
extends GrabbablePolyhedron

func _get_object_name() -> String:
	return "Truncated Tetrahedron"

func _get_geometry() -> Dictionary:
	var s := object_scale
	# Truncated tetrahedron vertices (Archimedean solid)
	# Using proper truncation at 1/3 of edge
	var t := 3.0
	var vertices: Array[Vector3] = [
		# Four hexagonal vertices groups around each original tetrahedron vertex
		Vector3(t, 1, 1) * s / 4.0,
		Vector3(1, t, 1) * s / 4.0,
		Vector3(1, 1, t) * s / 4.0,
		
		Vector3(-t, -1, 1) * s / 4.0,
		Vector3(-1, -t, 1) * s / 4.0,
		Vector3(-1, -1, t) * s / 4.0,
		
		Vector3(-t, 1, -1) * s / 4.0,
		Vector3(-1, t, -1) * s / 4.0,
		Vector3(-1, 1, -t) * s / 4.0,
		
		Vector3(t, -1, -1) * s / 4.0,
		Vector3(1, -t, -1) * s / 4.0,
		Vector3(1, -1, -t) * s / 4.0
	]
	
	# Triangular faces (where original tetrahedron vertices were)
	var faces: Array = [
		[0, 1, 2],    # Corner 1
		[3, 5, 4],    # Corner 2
		[6, 7, 8],    # Corner 3
		[9, 10, 11],  # Corner 4
		
		# Hexagonal faces (triangulated)
		# Hex 1: 2, 5, 3, 6, 8, 1 -> 2,5,1 / 5,3,6 / 5,6,1 / 1,6,8
		[2, 5, 1], [5, 6, 1], [5, 3, 6], [1, 6, 7],
		
		# Hex 2: 0, 2, 5, 4, 10, 9
		[0, 2, 5], [0, 5, 4], [0, 4, 10], [0, 10, 9],
		
		# Hex 3: 1, 8, 11, 9, 0 -> triangulated
		[1, 7, 8], [1, 8, 11], [1, 11, 0], [0, 11, 9],
		
		# Hex 4: 3, 4, 10, 11, 8, 6
		[3, 4, 10], [3, 10, 11], [3, 11, 8], [3, 8, 6]
	]
	
	return {"vertices": vertices, "faces": faces}
