extends MeshInstance3D
## A supplied draft: "what came back" for the three-line instruction in TUTORIAL.md.
## It was written for this kit as an example of typical faults. No assistant produced it.
## Keep this file as it is: it is the first answer. Repair your own cube.gd.

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
	[4, 7, 5], [5, 7, 6],   # front (yours, unchanged)
	[1, 2, 0], [0, 2, 8],   # back
	[0, 3, 4], [4, 3, 7],   # left
	[5, 6, 1], [1, 6, 2],   # right
	[2, 3, 6], [3, 7, 6],   # top
	[0, 4, 1], [1, 5, 5],   # bottom
]

func _ready() -> void:
	build()

func build() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for t in range(triangles.size()):
		var triangle: Array = triangles[t]
		surface.add_vertex(corners[triangle[0]])
		surface.add_vertex(corners[triangle[1]])
		surface.add_vertex(corners[triangle[2]])
	surface.generate_normals()
	mesh = surface.commit()
	$Body/CollisionShape3D.shape = mesh.create_trimesh_shape()
