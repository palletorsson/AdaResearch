extends MeshInstance3D
## One bar of the limb: the repaired cube of the Cube study, as it stood at its
## "Stop here". The list is a cube of 0.5 m; the Bar node's own scale makes it a
## bar. It is a copy, because a guest names nothing outside its folder.

var corners: Array[Vector3] = [
	Vector3(-0.25, -0.25, -0.25),   # 0 bottom back left
	Vector3(0.25, -0.25, -0.25),    # 1 bottom back right
	Vector3(0.25, 0.25, -0.25),     # 2 top back right
	Vector3(-0.25, 0.25, -0.25),    # 3 top back left
	Vector3(-0.25, -0.25, 0.25),    # 4 bottom front left
	Vector3(0.25, -0.25, 0.25),     # 5 bottom front right
	Vector3(0.25, 0.25, 0.25),      # 6 top front right
	Vector3(-0.25, 0.25, 0.25),     # 7 top front left
]

var triangles: Array = [
	[4, 7, 5], [5, 7, 6],   # front
	[1, 2, 0], [0, 2, 3],   # back
	[0, 3, 4], [4, 3, 7],   # left
	[5, 6, 1], [1, 6, 2],   # right
	[2, 6, 3], [3, 6, 7],   # top
	[0, 4, 1], [1, 4, 5],   # bottom
]

func _ready() -> void:
	build()

func build() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for t in range(triangles.size()):
		var triangle: Array = triangles[t]
		if triangle.max() >= corners.size():
			push_error("triangle %d asks for a corner that is not there: %s" % [t, triangle])
			continue
		surface.add_vertex(corners[triangle[0]])
		surface.add_vertex(corners[triangle[1]])
		surface.add_vertex(corners[triangle[2]])
	surface.generate_normals()
	mesh = surface.commit()
	$Body/CollisionShape3D.shape = mesh.create_trimesh_shape()
