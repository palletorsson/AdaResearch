# GrabPrism.gd - Grabbable triangular prism (5 faces, 6 vertices, 9 edges)
@tool
extends GrabbablePolyhedron

func _get_object_name() -> String:
	return "Triangular Prism"

func _get_geometry() -> Dictionary:
	var s := object_scale
	var h := s * 0.8   # Half height
	var r := s * 0.7   # Radius of triangular base
	
	# Equilateral triangle base vertices
	var a := r * sqrt(3.0) / 2.0
	var vertices: Array[Vector3] = [
		# Bottom triangle
		Vector3(r, -h, 0),
		Vector3(-r/2.0, -h, a),
		Vector3(-r/2.0, -h, -a),
		# Top triangle
		Vector3(r, h, 0),
		Vector3(-r/2.0, h, a),
		Vector3(-r/2.0, h, -a)
	]
	
	var faces: Array = [
		[0, 2, 1],  # Bottom face
		[3, 4, 5],  # Top face
		[0, 1, 4], [0, 4, 3],  # Side 1
		[1, 2, 5], [1, 5, 4],  # Side 2
		[2, 0, 3], [2, 3, 5]   # Side 3
	]
	return {"vertices": vertices, "faces": faces}
