extends MeshInstance3D
## The Point Cube guest: the repaired cube.
## It is the lesson's cube.gd as it stands at "Stop here": eight corners, twelve
## triples, a loop that reports a bad triple, flat normals and a collider. The
## Cube node stands 0.25 m above the guest's origin, so the cube stands on the
## ground. The `triangles` list is ours: put your own repair in its place.
## A guest names nothing outside its folder, so the colour is written out here.

const BODY := Color("c6ff3d")   # the course look's BODY

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
	var paint := StandardMaterial3D.new()
	paint.albedo_color = BODY
	paint.roughness = 0.8
	material_override = paint
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
