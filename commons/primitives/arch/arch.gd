# Arch.gd - Architectural arch shape (fits within 1,1,1)
extends Node3D

var base_color: Color = Color(0.9, 0.5, 0.2)  # Orange
var arch_height: float = 0.9
var arch_width: float = 0.8
var arch_depth: float = 0.2
var pillar_width: float = 0.15
var arch_segments: int = 12

func _ready():
	create_arch()

func create_arch():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertices = create_arch_vertices()
	var faces = create_arch_faces()

	for face in faces:
		add_triangle_with_normal(st, vertices, face)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "ArchMesh"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)

	create_collision()

func create_arch_vertices() -> Array:
	var vertices = []
	var half_width = arch_width * 0.5
	var half_depth = arch_depth * 0.5
	var top_of_pillars = arch_height * 0.6

	# Left pillar
	vertices.append_array([
		# Bottom (0-3)
		Vector3(-half_width, 0, -half_depth),
		Vector3(-half_width + pillar_width, 0, -half_depth),
		Vector3(-half_width + pillar_width, 0, half_depth),
		Vector3(-half_width, 0, half_depth),
		# Top (4-7)
		Vector3(-half_width, top_of_pillars, -half_depth),
		Vector3(-half_width + pillar_width, top_of_pillars, -half_depth),
		Vector3(-half_width + pillar_width, top_of_pillars, half_depth),
		Vector3(-half_width, top_of_pillars, half_depth),
	])

	# Right pillar
	vertices.append_array([
		# Bottom (8-11)
		Vector3(half_width - pillar_width, 0, -half_depth),
		Vector3(half_width, 0, -half_depth),
		Vector3(half_width, 0, half_depth),
		Vector3(half_width - pillar_width, 0, half_depth),
		# Top (12-15)
		Vector3(half_width - pillar_width, top_of_pillars, -half_depth),
		Vector3(half_width, top_of_pillars, -half_depth),
		Vector3(half_width, top_of_pillars, half_depth),
		Vector3(half_width - pillar_width, top_of_pillars, half_depth),
	])

	# Curved top (arch curve) - front face
	var start_idx = vertices.size()
	for i in range(arch_segments + 1):
		var t = float(i) / float(arch_segments)
		var angle = PI * t  # Half circle
		var radius = (arch_width - pillar_width * 2) * 0.5
		var center_height = top_of_pillars
		var x = cos(angle) * radius
		var y = center_height + sin(angle) * radius

		# Front curve
		vertices.append(Vector3(x, y, half_depth))
		# Back curve
		vertices.append(Vector3(x, y, -half_depth))

	return vertices

func create_arch_faces() -> Array:
	var faces = []

	# Left pillar faces
	# Bottom
	faces.append([0, 2, 1])
	faces.append([0, 3, 2])
	# Sides
	faces.append([0, 1, 5])
	faces.append([0, 5, 4])
	faces.append([1, 2, 6])
	faces.append([1, 6, 5])
	faces.append([2, 3, 7])
	faces.append([2, 7, 6])
	faces.append([3, 0, 4])
	faces.append([3, 4, 7])
	# Top
	faces.append([4, 5, 6])
	faces.append([4, 6, 7])

	# Right pillar faces
	# Bottom
	faces.append([8, 10, 9])
	faces.append([8, 11, 10])
	# Sides
	faces.append([8, 9, 13])
	faces.append([8, 13, 12])
	faces.append([9, 10, 14])
	faces.append([9, 14, 13])
	faces.append([10, 11, 15])
	faces.append([10, 15, 14])
	faces.append([11, 8, 12])
	faces.append([11, 12, 15])
	# Top
	faces.append([12, 13, 14])
	faces.append([12, 14, 15])

	# Curved arch
	var start_idx = 16
	for i in range(arch_segments):
		var front1 = start_idx + i * 2
		var back1 = front1 + 1
		var front2 = front1 + 2
		var back2 = front2 + 1

		# Front face
		faces.append([front1, front2, front1 + 2] if i < arch_segments - 1 else [front1, start_idx, front2])
		# Back face
		faces.append([back1, back2, back1 + 2] if i < arch_segments - 1 else [back1, start_idx + 1, back2])
		# Outer surface
		faces.append([front1, back1, front2])
		faces.append([back1, back2, front2])
		# Inner surface
		faces.append([front1, front2, back1])
		faces.append([back1, front2, back2])

	return faces

func create_collision():
	var static_body = StaticBody3D.new()
	static_body.name = "ArchCollision"
	add_child(static_body)

	var half_width = arch_width * 0.5
	var top_of_pillars = arch_height * 0.6

	# Left pillar collider
	var collision1 = CollisionShape3D.new()
	var box1 = BoxShape3D.new()
	box1.size = Vector3(pillar_width, top_of_pillars, arch_depth)
	collision1.shape = box1
	collision1.position = Vector3(-half_width + pillar_width * 0.5, top_of_pillars * 0.5, 0)
	static_body.add_child(collision1)

	# Right pillar collider
	var collision2 = CollisionShape3D.new()
	var box2 = BoxShape3D.new()
	box2.size = Vector3(pillar_width, top_of_pillars, arch_depth)
	collision2.shape = box2
	collision2.position = Vector3(half_width - pillar_width * 0.5, top_of_pillars * 0.5, 0)
	static_body.add_child(collision2)

	# Arch curve collider (approximate with box)
	var collision3 = CollisionShape3D.new()
	var box3 = BoxShape3D.new()
	var radius = (arch_width - pillar_width * 2) * 0.5
	box3.size = Vector3(arch_width - pillar_width * 2, radius * 0.5, arch_depth)
	collision3.shape = box3
	collision3.position = Vector3(0, top_of_pillars + radius * 0.5, 0)
	static_body.add_child(collision3)

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
