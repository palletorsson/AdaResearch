# Star.gd - 5-pointed star shape from vertex/face arrays (fits within 1,1,1)
extends Node3D

var base_color: Color = Color(1.0, 0.9, 0.2)  # Golden yellow

func _ready():
	create_star()

func create_star():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertices = create_star_vertices()
	var faces = create_star_faces()

	for face in faces:
		add_triangle_with_normal(st, vertices, face)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "StarMesh"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)

	create_collision()

func create_star_vertices() -> Array:
	# Original vertex array (22 vertices) - 5-pointed star with thickness
	var vertices = [
		Vector3(0.00000000e+00, 0.00000000e+00, 1.25000000e-01),      # 0 - center top
		Vector3(0.00000000e+00, 0.00000000e+00, -1.25000000e-01),     # 1 - center bottom
		Vector3(2.50000000e-01, 0.00000000e+00, 1.25000000e-01),      # 2
		Vector3(2.50000000e-01, 0.00000000e+00, -1.25000000e-01),     # 3
		Vector3(4.04508501e-01, 2.93892652e-01, 1.25000000e-01),      # 4
		Vector3(4.04508501e-01, 2.93892652e-01, -1.25000000e-01),     # 5
		Vector3(7.72542953e-02, 2.37764120e-01, 1.25000000e-01),      # 6
		Vector3(7.72542953e-02, 2.37764120e-01, -1.25000000e-01),     # 7
		Vector3(-1.54508516e-01, 4.75528270e-01, 1.25000000e-01),     # 8
		Vector3(-1.54508516e-01, 4.75528270e-01, -1.25000000e-01),    # 9
		Vector3(-2.02254280e-01, 1.46946251e-01, 1.24999993e-01),     # 10
		Vector3(-2.02254280e-01, 1.46946251e-01, -1.24999993e-01),    # 11
		Vector3(-5.00000000e-01, 4.37113883e-08, 1.25000000e-01),     # 12
		Vector3(-5.00000000e-01, 4.37113883e-08, -1.25000000e-01),    # 13
		Vector3(-2.02254280e-01, -1.46946251e-01, 1.24999993e-01),    # 14
		Vector3(-2.02254280e-01, -1.46946251e-01, -1.24999993e-01),   # 15
		Vector3(-1.54508516e-01, -4.75528270e-01, 1.25000000e-01),    # 16
		Vector3(-1.54508516e-01, -4.75528270e-01, -1.25000000e-01),   # 17
		Vector3(7.72542953e-02, -2.37764120e-01, 1.25000000e-01),     # 18
		Vector3(7.72542953e-02, -2.37764120e-01, -1.25000000e-01),    # 19
		Vector3(4.04508322e-01, -2.93892831e-01, 1.24999993e-01),     # 20
		Vector3(4.04508322e-01, -2.93892831e-01, -1.24999993e-01),    # 21
	]

	return vertices

func create_star_faces() -> Array:
	var faces = []

	# Top face triangles (faces 0-9)
	faces.append([2, 0, 20])
	faces.append([0, 2, 4])
	faces.append([0, 4, 6])
	faces.append([0, 6, 8])
	faces.append([0, 8, 10])
	faces.append([0, 10, 12])
	faces.append([0, 12, 14])
	faces.append([0, 14, 16])
	faces.append([0, 16, 18])
	faces.append([0, 18, 20])

	# Side quad faces converted to triangles (faces 10-19)
	# Face 10: [3, 2, 20, 21]
	faces.append([3, 2, 20])
	faces.append([3, 20, 21])

	# Face 11: [2, 3, 5, 4]
	faces.append([2, 3, 5])
	faces.append([2, 5, 4])

	# Face 12: [4, 5, 7, 6]
	faces.append([4, 5, 7])
	faces.append([4, 7, 6])

	# Face 13: [6, 7, 9, 8]
	faces.append([6, 7, 9])
	faces.append([6, 9, 8])

	# Face 14: [8, 9, 11, 10]
	faces.append([8, 9, 11])
	faces.append([8, 11, 10])

	# Face 15: [10, 11, 13, 12]
	faces.append([10, 11, 13])
	faces.append([10, 13, 12])

	# Face 16: [12, 13, 15, 14]
	faces.append([12, 13, 15])
	faces.append([12, 15, 14])

	# Face 17: [14, 15, 17, 16]
	faces.append([14, 15, 17])
	faces.append([14, 17, 16])

	# Face 18: [16, 17, 19, 18]
	faces.append([16, 17, 19])
	faces.append([16, 19, 18])

	# Face 19: [18, 19, 21, 20]
	faces.append([18, 19, 21])
	faces.append([18, 21, 20])

	# Bottom face triangles (faces 20-29)
	faces.append([1, 3, 21])
	faces.append([3, 1, 5])
	faces.append([5, 1, 7])
	faces.append([7, 1, 9])
	faces.append([9, 1, 11])
	faces.append([11, 1, 13])
	faces.append([13, 1, 15])
	faces.append([15, 1, 17])
	faces.append([17, 1, 19])
	faces.append([19, 1, 21])

	return faces

func create_collision():
	var static_body = StaticBody3D.new()
	static_body.name = "StarCollision"
	add_child(static_body)

	# Approximate star collision with cylinder
	var collision = CollisionShape3D.new()
	var cylinder = CylinderShape3D.new()
	cylinder.radius = 0.4
	cylinder.height = 0.25
	collision.shape = cylinder
	collision.position = Vector3(0, 0, 0)
	collision.rotation_degrees = Vector3(90, 0, 0)  # Rotate to align with Z thickness
	static_body.add_child(collision)

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
