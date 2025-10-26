# l_shape.gd - L-shaped building block
extends MeshInstance3D

const PrimitiveMeshBuilder = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")
const GridMaterialFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")

@export var width: float = 0.5
@export var height: float = 1.0
@export var depth: float = 0.5
@export var base_color: Color = Color(0.6, 0.7, 0.9)

func _ready():
	build_l_shape()

func build_l_shape():
	# L-shape is like two boxes joined at right angle
	# Vertical part (0.5w x 1.0h x 0.5d)
	# Horizontal part (1.0w x 0.5h x 0.5d) extending from bottom

	var vertices: Array[Vector3] = []
	var faces: Array = []

	# Create vertical part vertices (box 1)
	# Bottom face
	vertices.append(Vector3(-width/2, 0, -depth/2))  # 0
	vertices.append(Vector3(width/2, 0, -depth/2))   # 1
	vertices.append(Vector3(width/2, 0, depth/2))    # 2
	vertices.append(Vector3(-width/2, 0, depth/2))   # 3

	# Top face
	vertices.append(Vector3(-width/2, height, -depth/2))  # 4
	vertices.append(Vector3(width/2, height, -depth/2))   # 5
	vertices.append(Vector3(width/2, height, depth/2))    # 6
	vertices.append(Vector3(-width/2, height, depth/2))   # 7

	# Create horizontal part vertices (extending to the right)
	# Bottom face (same as vertical bottom on right side)
	vertices.append(Vector3(width/2, 0, -depth/2))   # 8 (duplicate of 1)
	vertices.append(Vector3(width*2, 0, -depth/2))   # 9
	vertices.append(Vector3(width*2, 0, depth/2))    # 10
	vertices.append(Vector3(width/2, 0, depth/2))    # 11 (duplicate of 2)

	# Top face of horizontal part
	vertices.append(Vector3(width/2, height/2, -depth/2))   # 12
	vertices.append(Vector3(width*2, height/2, -depth/2))   # 13
	vertices.append(Vector3(width*2, height/2, depth/2))    # 14
	vertices.append(Vector3(width/2, height/2, depth/2))    # 15

	# Build faces for vertical part
	# Bottom
	faces.append([0, 2, 1])
	faces.append([0, 3, 2])
	# Top
	faces.append([4, 5, 6])
	faces.append([4, 6, 7])
	# Front
	faces.append([0, 1, 5])
	faces.append([0, 5, 4])
	# Back
	faces.append([3, 7, 6])
	faces.append([3, 6, 2])
	# Left
	faces.append([0, 4, 7])
	faces.append([0, 7, 3])
	# Right (partial - only top half)
	faces.append([1, 12, 5])
	faces.append([1, 15, 12])
	faces.append([15, 6, 5])
	faces.append([15, 5, 12])

	# Build faces for horizontal part
	# Bottom
	faces.append([8, 9, 10])
	faces.append([8, 10, 11])
	# Top
	faces.append([12, 14, 13])
	faces.append([12, 15, 14])
	# Front
	faces.append([8, 13, 9])
	faces.append([8, 12, 13])
	# Back
	faces.append([11, 10, 14])
	faces.append([11, 14, 15])
	# Right
	faces.append([9, 13, 14])
	faces.append([9, 14, 10])

	var material = GridMaterialFactory.make(base_color, {})

	mesh = PrimitiveMeshBuilder.build_mesh_instance_raw(
		vertices,
		faces,
		{
			"material": material,
			"double_sided": false
		}
	)
