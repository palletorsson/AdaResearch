# Rock.gd - Rock shape from vertex/face arrays (fits within 1,1,1)
extends Node3D

var base_color: Color = Color(0.5, 0.5, 0.5)  # Gray

func _ready():
	create_rock()

func create_rock():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertices = create_rock_vertices()
	var faces = create_rock_faces()

	for face in faces:
		add_triangle_with_normal(st, vertices, face)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "RockMesh"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)

	create_collision()

func create_rock_vertices() -> Array:
	# Original vertex array (8 vertices) - pyramid-like rock shape
	var vertices = [
		Vector3(0.0, 0.0, 0.0),      # 0 - apex at origin
		Vector3(0.5, -0.5, -0.5),    # 1
		Vector3(0.5, 0.5, -0.5),     # 2
		Vector3(-0.5, 0.5, -0.5),    # 3
		Vector3(0.5, -0.5, 0.5),     # 4
		Vector3(0.5, 0.5, 0.5),      # 5
		Vector3(-0.5, 0.5, 0.5),     # 6
		Vector3(-0.5, -0.5, 0.5),    # 7
	]

	return vertices

func create_rock_faces() -> Array:
	var faces = []

	# Triangular faces from apex (faces 0-5)
	faces.append([0, 2, 1])
	faces.append([0, 3, 2])
	faces.append([0, 6, 3])
	faces.append([0, 7, 6])
	faces.append([0, 4, 7])
	faces.append([0, 1, 4])

	# Quad faces converted to triangles (faces 6-8)
	# Face 6: [5, 4, 1, 2]
	faces.append([5, 4, 1])
	faces.append([5, 1, 2])

	# Face 7: [5, 2, 3, 6]
	faces.append([5, 2, 3])
	faces.append([5, 3, 6])

	# Face 8: [5, 6, 7, 4]
	faces.append([5, 6, 7])
	faces.append([5, 7, 4])

	return faces

func create_collision():
	var static_body = StaticBody3D.new()
	static_body.name = "RockCollision"
	add_child(static_body)

	# Approximate rock collision with box
	var collision = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.8, 0.8, 0.8)  # Slightly smaller than full extent
	collision.shape = box
	collision.position = Vector3(0.1, 0.0, 0.0)  # Offset slightly toward the bulk
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
