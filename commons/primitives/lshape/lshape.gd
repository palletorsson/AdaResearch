# LShape.gd - Upside down L shape (fits within 1,1,1)
extends Node3D

var base_color: Color = Color(0.2, 0.8, 1.0)  # Cyan
var vertical_height: float = 0.8
var horizontal_length: float = 0.6
var thickness: float = 0.2

func _ready():
	create_lshape()

func create_lshape():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertices = create_lshape_vertices()
	var faces = create_lshape_faces()

	# Add all triangular faces
	for face in faces:
		add_triangle_with_normal(st, vertices, face)

	# Create mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "LShapeMesh"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)

	# Add collision
	create_collision(vertices)

func create_lshape_vertices() -> Array:
	var vertices = []
	var half_thick = thickness * 0.5

	# Upside down L with proper corner joint
	# Vertical bar from bottom to vertical_height, horizontal bar extends from corner

	# Vertical bar vertices (centered on origin in XZ)
	vertices.append_array([
		# Bottom face (y=0)
		Vector3(-half_thick, 0, -half_thick),  # 0
		Vector3(half_thick, 0, -half_thick),   # 1
		Vector3(half_thick, 0, half_thick),    # 2
		Vector3(-half_thick, 0, half_thick),   # 3

		# Top of vertical bar - stopping before the horizontal bar
		Vector3(-half_thick, vertical_height, -half_thick),  # 4
		Vector3(half_thick, vertical_height, -half_thick),   # 5
		Vector3(half_thick, vertical_height, half_thick),    # 6
		Vector3(-half_thick, vertical_height, half_thick),   # 7
	])

	# Horizontal bar with corner integration
	# The horizontal bar shares the corner space with vertical bar
	vertices.append_array([
		# Bottom of horizontal bar (at vertical_height)
		Vector3(-half_thick, vertical_height, -half_thick),  # 8 (same as 4)
		Vector3(horizontal_length, vertical_height, -half_thick),  # 9
		Vector3(horizontal_length, vertical_height, half_thick),   # 10
		Vector3(-half_thick, vertical_height, half_thick),   # 11 (same as 7)

		# Top of horizontal bar
		Vector3(-half_thick, vertical_height + thickness, -half_thick),   # 12
		Vector3(horizontal_length, vertical_height + thickness, -half_thick),  # 13
		Vector3(horizontal_length, vertical_height + thickness, half_thick),   # 14
		Vector3(-half_thick, vertical_height + thickness, half_thick),    # 15
	])

	return vertices

func create_lshape_faces() -> Array:
	var faces = []

	# Vertical bar faces
	# Bottom face
	faces.append([0, 2, 1])
	faces.append([0, 3, 2])

	# Vertical bar sides (only up to where horizontal joins)
	faces.append([0, 1, 5])  # Back
	faces.append([0, 5, 4])
	faces.append([1, 2, 6])  # Right side
	faces.append([1, 6, 5])
	faces.append([2, 3, 7])  # Front
	faces.append([2, 7, 6])
	faces.append([3, 0, 4])  # Left
	faces.append([3, 4, 7])

	# Horizontal bar faces
	# Bottom - skip the corner area shared with vertical
	faces.append([5, 6, 10])  # Right portion of bottom
	faces.append([5, 10, 9])

	# Top face
	faces.append([12, 13, 14])
	faces.append([12, 14, 15])

	# Outer end face
	faces.append([9, 13, 14])
	faces.append([9, 14, 10])

	# Back side
	faces.append([8, 9, 13])
	faces.append([8, 13, 12])

	# Front side
	faces.append([11, 14, 10])
	faces.append([11, 15, 14])

	# Left side exposed area (vertical to horizontal transition)
	faces.append([4, 12, 15])
	faces.append([4, 15, 7])

	return faces

func create_collision(vertices: Array):
	# Create StaticBody3D with box colliders
	var static_body = StaticBody3D.new()
	static_body.name = "LShapeCollision"
	add_child(static_body)

	# Vertical bar collider
	var collision1 = CollisionShape3D.new()
	var box1 = BoxShape3D.new()
	box1.size = Vector3(thickness, vertical_height, thickness)
	collision1.shape = box1
	collision1.position = Vector3(0, vertical_height * 0.5, 0)
	static_body.add_child(collision1)

	# Horizontal bar collider
	var collision2 = CollisionShape3D.new()
	var box2 = BoxShape3D.new()
	box2.size = Vector3((horizontal_length - thickness * 0.5), thickness, thickness)
	collision2.shape = box2
	collision2.position = Vector3((horizontal_length + thickness * 0.5) * 0.5, vertical_height + thickness * 0.5, 0)
	static_body.add_child(collision2)

func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]
	var v2 = vertices[face[2]]

	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var normal = edge1.cross(edge2).normalized()

	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_normal(normal)
	st.add_vertex(v1)
	st.set_normal(normal)
	st.add_vertex(v2)

func apply_queer_material(mesh_instance: MeshInstance3D, color: Color):
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		material.set_shader_parameter("base_color", color)
		material.set_shader_parameter("edge_color", Color.WHITE)
		material.set_shader_parameter("edge_width", 1.5)
		material.set_shader_parameter("edge_sharpness", 2.0)
		material.set_shader_parameter("emission_strength", 1.0)
		mesh_instance.material_override = material
	else:
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = color
		standard_material.emission_enabled = true
		standard_material.emission = color * 0.3
		mesh_instance.material_override = standard_material
