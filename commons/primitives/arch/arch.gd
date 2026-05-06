# Arch.gd - Architectural arch shape (fits within 1,1,1)
extends Node3D

var base_color: Color = Color(0.9, 0.5, 0.2)  # Orange
var arch_height: float = 0.9
var arch_width: float = 0.8
var arch_depth: float = 0.2
var pillar_width: float = 0.15
var arch_thickness: float = 0.08  # Thickness of the arch curve
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

	# Left pillar (indices 0-7)
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

	# Right pillar (indices 8-15)
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

	# Curved arch with thickness (4 vertices per segment point)
	# The arch outer edge aligns with the pillar outer edges
	# Outer edge of pillars: ±half_width
	# Inner edge of pillars: ±(half_width - pillar_width)
	var outer_radius = half_width  # Outer curve aligns with pillar outer edge
	var inner_radius = half_width - pillar_width  # Inner curve aligns with pillar inner edge
	var center_height = top_of_pillars  # Arch center at top of pillars

	# Starting at index 16
	for i in range(arch_segments + 1):
		var t = float(i) / float(arch_segments)
		var angle = PI * (1.0 - t)  # Half circle, right to left (0 = right, PI = left)

		var outer_x = cos(angle) * outer_radius
		var outer_y = center_height + sin(angle) * outer_radius
		var inner_x = cos(angle) * inner_radius
		var inner_y = center_height + sin(angle) * inner_radius

		# Outer front (index: 16 + i*4 + 0)
		vertices.append(Vector3(outer_x, outer_y, half_depth))
		# Outer back (index: 16 + i*4 + 1)
		vertices.append(Vector3(outer_x, outer_y, -half_depth))
		# Inner front (index: 16 + i*4 + 2)
		vertices.append(Vector3(inner_x, inner_y, half_depth))
		# Inner back (index: 16 + i*4 + 3)
		vertices.append(Vector3(inner_x, inner_y, -half_depth))

	return vertices

func create_arch_faces() -> Array:
	var faces = []

	# Left pillar faces
	# Bottom (facing down)
	faces.append([0, 1, 2])
	faces.append([0, 2, 3])
	# Left side (facing -X)
	faces.append([0, 3, 7])
	faces.append([0, 7, 4])
	# Front side (facing +Z)
	faces.append([3, 2, 6])
	faces.append([3, 6, 7])
	# Right side (facing +X, inner)
	faces.append([2, 1, 5])
	faces.append([2, 5, 6])
	# Back side (facing -Z)
	faces.append([1, 0, 4])
	faces.append([1, 4, 5])
	# Top (facing up)
	faces.append([4, 7, 6])
	faces.append([4, 6, 5])

	# Right pillar faces
	# Bottom (facing down)
	faces.append([8, 9, 10])
	faces.append([8, 10, 11])
	# Left side (facing -X, inner)
	faces.append([8, 11, 15])
	faces.append([8, 15, 12])
	# Front side (facing +Z)
	faces.append([11, 10, 14])
	faces.append([11, 14, 15])
	# Right side (facing +X)
	faces.append([10, 9, 13])
	faces.append([10, 13, 14])
	# Back side (facing -Z)
	faces.append([9, 8, 12])
	faces.append([9, 12, 13])
	# Top (facing up)
	faces.append([12, 15, 14])
	faces.append([12, 14, 13])

	# Curved arch faces
	var start_idx = 16
	for i in range(arch_segments):
		# Current segment vertices
		var of1 = start_idx + i * 4 + 0  # outer front 1
		var ob1 = start_idx + i * 4 + 1  # outer back 1
		var if1 = start_idx + i * 4 + 2  # inner front 1
		var ib1 = start_idx + i * 4 + 3  # inner back 1
		# Next segment vertices
		var of2 = start_idx + (i + 1) * 4 + 0  # outer front 2
		var ob2 = start_idx + (i + 1) * 4 + 1  # outer back 2
		var if2 = start_idx + (i + 1) * 4 + 2  # inner front 2
		var ib2 = start_idx + (i + 1) * 4 + 3  # inner back 2

		# Outer surface (facing outward/up)
		faces.append([of1, of2, ob2])
		faces.append([of1, ob2, ob1])

		# Inner surface (facing inward/down)
		faces.append([if1, ib1, ib2])
		faces.append([if1, ib2, if2])

		# Front face (facing +Z)
		faces.append([of1, if1, if2])
		faces.append([of1, if2, of2])

		# Back face (facing -Z)
		faces.append([ob1, ob2, ib2])
		faces.append([ob1, ib2, ib1])

	# End caps for arch curve
	# Left end cap (connects to left pillar top)
	var left_of = start_idx + arch_segments * 4 + 0
	var left_ob = start_idx + arch_segments * 4 + 1
	var left_if = start_idx + arch_segments * 4 + 2
	var left_ib = start_idx + arch_segments * 4 + 3
	faces.append([left_of, left_ob, left_ib])
	faces.append([left_of, left_ib, left_if])

	# Right end cap
	var right_of = start_idx + 0
	var right_ob = start_idx + 1
	var right_if = start_idx + 2
	var right_ib = start_idx + 3
	faces.append([right_of, right_if, right_ib])
	faces.append([right_of, right_ib, right_ob])

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
