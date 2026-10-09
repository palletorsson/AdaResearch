extends MeshInstance3D

@export_range(1.0, 2.0) var stretch: float = 1.53   # how far the cube is pulled along one diagonal
@export_range(0.0, 0.5) var cut: float = 0.38       # how far along each edge the two end corners are cut off

func _ready() -> void:
	build()

func build() -> void:
	stretch = clampf(stretch, 1.0, 2.0)
	cut = clampf(cut, 0.0, 0.5)
	var corners: Array[Vector3] = [
		Vector3(-0.25, -0.25, -0.25),   # 0 the low end of the diagonal
		Vector3(0.25, -0.25, -0.25),    # 1
		Vector3(0.25, 0.25, -0.25),     # 2
		Vector3(-0.25, 0.25, -0.25),    # 3
		Vector3(-0.25, -0.25, 0.25),    # 4
		Vector3(0.25, -0.25, 0.25),     # 5
		Vector3(0.25, 0.25, 0.25),      # 6 the high end of the diagonal
		Vector3(-0.25, 0.25, 0.25),     # 7
	]
	for i in range(corners.size()):
		var p := corners[i]
		corners[i] = p + Vector3.ONE * (p.x + p.y + p.z) / 3.0 * (stretch - 1.0)
	for end in [[6, 2, 5, 7], [0, 1, 3, 4]]:
		for i in range(1, 4):
			corners.append(corners[end[0]] + (corners[end[i]] - corners[end[0]]) * cut)
	var faces: Array = [
		[4, 7, 10, 9, 5], [5, 9, 8, 2, 1], [2, 8, 10, 7, 3],        # around the high end
		[1, 2, 3, 12, 11], [13, 12, 3, 7, 4], [11, 13, 4, 5, 1],    # around the low end
		[8, 9, 10], [11, 12, 13],                                   # the two cuts
	]
	var upright := Quaternion(Vector3.ONE, Vector3.UP)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for face in faces:
		for i in range(1, face.size() - 1):
			surface.add_vertex(upright * corners[face[0]])
			surface.add_vertex(upright * corners[face[i]])
			surface.add_vertex(upright * corners[face[i + 1]])
	surface.generate_normals()
	mesh = surface.commit()

func triangles() -> int:
	var arrays := mesh.surface_get_arrays(0)
	return arrays[Mesh.ARRAY_VERTEX].size() / 3
