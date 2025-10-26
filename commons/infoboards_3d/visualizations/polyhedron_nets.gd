# PolyhedronNets.gd - 2D net visualizations for polyhedra
extends Node3D

@export var net_type: String = "tetrahedron"
@export var edge_length: float = 0.5
@export var line_thickness: float = 0.01
@export var face_color: Color = Color(1.0, 0.9, 0.7, 0.8)
@export var edge_color: Color = Color(0.2, 0.2, 0.2, 1.0)

const PrimitiveMeshBuilder = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")
const GridMaterialFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")

func _ready():
	match net_type:
		"tetrahedron":
			create_tetrahedron_net()
		"cube":
			create_cube_net()
		"octahedron":
			create_octahedron_net()

func create_tetrahedron_net():
	# Strip of 4 equilateral triangles
	var h = edge_length * sqrt(3.0) / 2.0  # Triangle height

	# 4 triangles laid flat in a strip
	var vertices_3d: Array[Vector3] = [
		# Triangle 1 (leftmost)
		Vector3(-1.5 * edge_length, 0, 0),
		Vector3(-edge_length, 0, 0),
		Vector3(-1.25 * edge_length, 0, h),
		# Triangle 2
		Vector3(-edge_length, 0, 0),
		Vector3(-0.5 * edge_length, 0, 0),
		Vector3(-0.75 * edge_length, 0, h),
		# Triangle 3 (center)
		Vector3(-0.5 * edge_length, 0, 0),
		Vector3(0, 0, 0),
		Vector3(-0.25 * edge_length, 0, h),
		# Triangle 4 (rightmost)
		Vector3(0, 0, 0),
		Vector3(0.5 * edge_length, 0, 0),
		Vector3(0.25 * edge_length, 0, h)
	]

	var faces = [
		[0, 1, 2],    # Triangle 1
		[3, 4, 5],    # Triangle 2
		[6, 7, 8],    # Triangle 3
		[9, 10, 11]   # Triangle 4
	]

	create_net_mesh(vertices_3d, faces)
	add_fold_line_labels()

func create_cube_net():
	# Classic cross/Latin cross pattern
	var s = edge_length

	# Vertices for 6 squares laid out in cross pattern
	var vertices_3d: Array[Vector3] = []
	var faces = []

	# Center square (front face)
	var base_squares = [
		# Center
		{"offset": Vector3(0, 0, 0)},
		# Top
		{"offset": Vector3(0, 0, s)},
		# Bottom
		{"offset": Vector3(0, 0, -s)},
		# Left
		{"offset": Vector3(-s, 0, 0)},
		# Right
		{"offset": Vector3(s, 0, 0)},
		# Back (to the right of right)
		{"offset": Vector3(2 * s, 0, 0)}
	]

	for sq in base_squares:
		var offset = sq["offset"]
		var base_idx = vertices_3d.size()
		vertices_3d.append(offset + Vector3(0, 0, 0))
		vertices_3d.append(offset + Vector3(s, 0, 0))
		vertices_3d.append(offset + Vector3(s, 0, s))
		vertices_3d.append(offset + Vector3(0, 0, s))
		faces.append([base_idx, base_idx + 1, base_idx + 2])
		faces.append([base_idx, base_idx + 2, base_idx + 3])

	create_net_mesh(vertices_3d, faces)
	add_fold_line_labels()

func create_octahedron_net():
	# Strip of 8 triangles
	var h = edge_length * sqrt(3.0) / 2.0
	var vertices_3d: Array[Vector3] = []
	var faces = []

	# Create strip of 8 triangles alternating up/down
	for i in range(8):
		var x_offset = i * edge_length * 0.5
		var base_idx = vertices_3d.size()

		if i % 2 == 0:  # Point up
			vertices_3d.append(Vector3(x_offset, 0, 0))
			vertices_3d.append(Vector3(x_offset + edge_length * 0.5, 0, 0))
			vertices_3d.append(Vector3(x_offset + edge_length * 0.25, 0, h))
		else:  # Point down
			vertices_3d.append(Vector3(x_offset, 0, 0))
			vertices_3d.append(Vector3(x_offset + edge_length * 0.5, 0, 0))
			vertices_3d.append(Vector3(x_offset + edge_length * 0.25, 0, -h))

		faces.append([base_idx, base_idx + 1, base_idx + 2])

	create_net_mesh(vertices_3d, faces)
	add_fold_line_labels()

func create_net_mesh(vertices: Array[Vector3], faces: Array):
	# Create the flat net with transparency
	var material = GridMaterialFactory.make(face_color, {
		"double_sided": true,
		"edge_color": edge_color
	})

	var mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		vertices,
		faces,
		{
			"name": net_type + "_Net",
			"material": material,
			"double_sided": true
		}
	)

	add_child(mesh_instance)

func add_fold_line_labels():
	# Add a label explaining this is a net
	var label = Label3D.new()
	label.text = net_type.capitalize() + " Net (fold along edges)"
	label.font_size = 12
	label.outline_size = 3
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 0.1, -1.0)
	add_child(label)
