extends MeshInstance3D

@export var scale_factor: float = 2.0
@export var material_color: Color = Color(0.3, 0.25, 0.2)

func _ready():
	create_sofa_mesh()

func create_sofa_mesh():
	# Vertex data from the provided array
	var vertices = PackedVector3Array([
		Vector3(-0.25, -0.25, -0.25),
		Vector3(-0.25, -0.25, 0.25),
		Vector3(-0.25, 0.25, -0.25),
		Vector3(-0.25, 0.25, 0.25),
		Vector3(0.25, -0.25, -0.25),
		Vector3(-0.14493257, -0.25, 0.25),
		Vector3(0.25, 0.25, -0.25),
		Vector3(-0.14493257, 0.25, 0.25),
		Vector3(-0.25, -0.25, 0.0),
		Vector3(-0.25, 0.25, 0.0),
		Vector3(0.25, 0.25, 0.0),
		Vector3(0.25, -0.25, 0.0),
		Vector3(-0.25, -0.25, 0.02164545),
		Vector3(-0.25, 0.25, 0.02164545),
		Vector3(-0.14493257, 0.25, 0.02164545),
		Vector3(-0.14493257, -0.25, 0.02164545)
	])

	# Face data - quads (need to triangulate for mesh)
	var faces = [
		[12, 1, 3, 13],
		[13, 3, 7, 14],
		[14, 7, 5, 15],
		[15, 5, 1, 12],
		[2, 6, 4, 0],
		[7, 3, 1, 5],
		[4, 11, 8, 0],
		[6, 10, 11, 4],
		[2, 9, 10, 6],
		[0, 8, 9, 2],
		[11, 15, 12, 8],
		[10, 14, 15, 11],
		[9, 13, 14, 10],
		[8, 12, 13, 9]
	]

	# Scale vertices
	for i in range(vertices.size()):
		vertices[i] *= scale_factor

	# Create mesh using SurfaceTool
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Convert quads to triangles and add to surface
	for face in faces:
		if face.size() == 4:
			# Triangulate quad: split into two triangles
			# Triangle 1: [0, 1, 2]
			surface_tool.add_vertex(vertices[face[0]])
			surface_tool.add_vertex(vertices[face[1]])
			surface_tool.add_vertex(vertices[face[2]])

			# Triangle 2: [0, 2, 3]
			surface_tool.add_vertex(vertices[face[0]])
			surface_tool.add_vertex(vertices[face[2]])
			surface_tool.add_vertex(vertices[face[3]])

	# Generate normals and commit
	surface_tool.generate_normals()
	var array_mesh = surface_tool.commit()

	# Set the mesh
	mesh = array_mesh

	# Create and apply material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = material_color
	mat.metallic = 0.1
	mat.roughness = 0.8
	material_override = mat
