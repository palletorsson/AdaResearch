extends MeshInstance3D
## A supplied draft: "what came back" for the one-line instruction "make a cube".
## It was written for this kit as an example of typical defaults. No assistant produced it.
## Its corners and triples are the ones the museum's own cube builder stores
## (commons/primitives/animatedcubebuilder/animatedcubebuilder.gd in the Ada project).

var corners: Array[Vector3] = [
	Vector3(-0.5, -0.5, -0.5),   # 0 bottom back left
	Vector3(0.5, -0.5, -0.5),    # 1 bottom back right
	Vector3(0.5, 0.5, -0.5),     # 2 top back right
	Vector3(-0.5, 0.5, -0.5),    # 3 top back left
	Vector3(-0.5, -0.5, 0.5),    # 4 bottom front left
	Vector3(0.5, -0.5, 0.5),     # 5 bottom front right
	Vector3(0.5, 0.5, 0.5),      # 6 top front right
	Vector3(-0.5, 0.5, 0.5),     # 7 top front left
]

var triangles: Array = [
	[0, 1, 4], [1, 5, 4],   # bottom
	[2, 3, 6], [3, 7, 6],   # top
	[4, 5, 7], [5, 6, 7],   # front
	[1, 0, 2], [0, 3, 2],   # back
	[0, 4, 3], [4, 7, 3],   # left
	[5, 1, 6], [1, 2, 6],   # right
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
