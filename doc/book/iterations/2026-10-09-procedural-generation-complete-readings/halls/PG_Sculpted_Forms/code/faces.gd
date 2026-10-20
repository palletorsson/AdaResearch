extends RefCounted

static func build(faces: Array, origin: Vector3, spacing: float) -> ArrayMesh:
	if faces.is_empty(): return ArrayMesh.new()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in faces:
		var normal := Vector3(face[1])
		var u: Vector3
		var v: Vector3
		if normal.x != 0:
			u = Vector3(0,0,normal.x)
			v = Vector3.UP
		elif normal.y != 0:
			u = Vector3.RIGHT
			v = Vector3(0,0,normal.y)
		else:
			u = Vector3.UP
			v = Vector3(normal.z,0,0)
		var centre := origin + Vector3(face[0]) * spacing + normal * spacing / 2
		var half := spacing / 2
		var corners := [centre + (-u-v)*half, centre + (u-v)*half,
			centre + (u+v)*half, centre + (-u+v)*half]
		surface.set_normal(normal)
		for i in [0,1,2,0,2,3]: surface.add_vertex(corners[i])
	return surface.commit()
