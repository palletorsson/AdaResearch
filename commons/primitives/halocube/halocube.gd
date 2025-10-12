# HaloCube.gd - Halo cube with four sides (hollow cube frame, open top/bottom)
extends Node3D

var base_color: Color = Color(1.0, 0.4, 0.8)  # Pink
var cube_size: float = 0.8
var wall_thickness: float = 0.1
var height: float = 0.8
const ROTATION_Z_RADIANS := deg_to_rad(90.0)

func _ready():
	create_halocube()

func create_halocube() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertices = create_halocube_vertices()
	var faces = create_halocube_faces()

	for face in faces:
		add_triangle_with_normal(st, vertices, face)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "HaloCubeMesh"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)
	mesh_instance.rotate_z(ROTATION_Z_RADIANS)

	var collision_body := create_collision()
	if collision_body:
		collision_body.rotate_z(ROTATION_Z_RADIANS)

func create_halocube_vertices() -> Array:
	var vertices = []
	var half_size = cube_size * 0.5
	var inner_half = half_size - wall_thickness
	var miter = wall_thickness * 0.5  # 45-degree miter offset

	# Four walls with 45-degree mitered corners
	# Each corner is cut at 45 degrees to meet adjacent walls

	# Back wall (-Z) with mitered corners (0-7)
	vertices.append_array([
		# Outer face (corners cut at 45°)
		Vector3(-half_size + miter, 0, -half_size),       # 0
		Vector3(half_size - miter, 0, -half_size),        # 1
		Vector3(half_size - miter, height, -half_size),   # 2
		Vector3(-half_size + miter, height, -half_size),  # 3
		# Inner face
		Vector3(-inner_half + miter, 0, -inner_half),      # 4
		Vector3(inner_half - miter, 0, -inner_half),       # 5
		Vector3(inner_half - miter, height, -inner_half),  # 6
		Vector3(-inner_half + miter, height, -inner_half), # 7
	])

	# Right wall (+X) with mitered corners (8-15)
	vertices.append_array([
		# Outer face (corners cut at 45°)
		Vector3(half_size, 0, -half_size + miter),        # 8
		Vector3(half_size, 0, half_size - miter),         # 9
		Vector3(half_size, height, half_size - miter),    # 10
		Vector3(half_size, height, -half_size + miter),   # 11
		# Inner face
		Vector3(inner_half, 0, -inner_half + miter),       # 12
		Vector3(inner_half, 0, inner_half - miter),        # 13
		Vector3(inner_half, height, inner_half - miter),   # 14
		Vector3(inner_half, height, -inner_half + miter),  # 15
	])

	# Front wall (+Z) with mitered corners (16-23)
	vertices.append_array([
		# Outer face (corners cut at 45°)
		Vector3(half_size - miter, 0, half_size),         # 16
		Vector3(-half_size + miter, 0, half_size),        # 17
		Vector3(-half_size + miter, height, half_size),   # 18
		Vector3(half_size - miter, height, half_size),    # 19
		# Inner face
		Vector3(inner_half - miter, 0, inner_half),        # 20
		Vector3(-inner_half + miter, 0, inner_half),       # 21
		Vector3(-inner_half + miter, height, inner_half),  # 22
		Vector3(inner_half - miter, height, inner_half),   # 23
	])

	# Left wall (-X) with mitered corners (24-31)
	vertices.append_array([
		# Outer face (corners cut at 45°)
		Vector3(-half_size, 0, half_size - miter),        # 24
		Vector3(-half_size, 0, -half_size + miter),       # 25
		Vector3(-half_size, height, -half_size + miter),  # 26
		Vector3(-half_size, height, half_size - miter),   # 27
		# Inner face
		Vector3(-inner_half, 0, inner_half - miter),       # 28
		Vector3(-inner_half, 0, -inner_half + miter),      # 29
		Vector3(-inner_half, height, -inner_half + miter), # 30
		Vector3(-inner_half, height, inner_half - miter),  # 31
	])

	# Add 45-degree corner connecting vertices
	# Back-right corner
	vertices.append_array([
		Vector3(half_size - miter, 0, -half_size),        # 32
		Vector3(half_size, 0, -half_size + miter),        # 33
		Vector3(half_size, height, -half_size + miter),   # 34
		Vector3(half_size - miter, height, -half_size),   # 35
	])

	# Front-right corner
	vertices.append_array([
		Vector3(half_size, 0, half_size - miter),         # 36
		Vector3(half_size - miter, 0, half_size),         # 37
		Vector3(half_size - miter, height, half_size),    # 38
		Vector3(half_size, height, half_size - miter),    # 39
	])

	# Front-left corner
	vertices.append_array([
		Vector3(-half_size + miter, 0, half_size),        # 40
		Vector3(-half_size, 0, half_size - miter),        # 41
		Vector3(-half_size, height, half_size - miter),   # 42
		Vector3(-half_size + miter, height, half_size),   # 43
	])

	# Back-left corner
	vertices.append_array([
		Vector3(-half_size, 0, -half_size + miter),       # 44
		Vector3(-half_size + miter, 0, -half_size),       # 45
		Vector3(-half_size + miter, height, -half_size),  # 46
		Vector3(-half_size, height, -half_size + miter),  # 47
	])

	return vertices

func create_halocube_faces() -> Array:
	var faces = []

	# Helper function to add wall faces
	var add_wall = func(base_idx: int):
		# Outer face
		faces.append([base_idx + 0, base_idx + 1, base_idx + 2])
		faces.append([base_idx + 0, base_idx + 2, base_idx + 3])
		# Inner face (reversed winding)
		faces.append([base_idx + 4, base_idx + 6, base_idx + 5])
		faces.append([base_idx + 4, base_idx + 7, base_idx + 6])
		# Top edge
		faces.append([base_idx + 3, base_idx + 2, base_idx + 6])
		faces.append([base_idx + 3, base_idx + 6, base_idx + 7])
		# Bottom edge
		faces.append([base_idx + 0, base_idx + 5, base_idx + 1])
		faces.append([base_idx + 0, base_idx + 4, base_idx + 5])

	# Add all four walls
	add_wall.call(0)   # Back wall
	add_wall.call(8)   # Right wall
	add_wall.call(16)  # Front wall
	add_wall.call(24)  # Left wall

	# Add 45-degree mitered corner faces
	# Back-right corner (32-35)
	faces.append([32, 33, 34])
	faces.append([32, 34, 35])

	# Front-right corner (36-39)
	faces.append([36, 37, 38])
	faces.append([36, 38, 39])

	# Front-left corner (40-43)
	faces.append([40, 41, 42])
	faces.append([40, 42, 43])

	# Back-left corner (44-47)
	faces.append([44, 45, 46])
	faces.append([44, 46, 47])

	return faces

func create_collision() -> StaticBody3D:
	var static_body := StaticBody3D.new()
	static_body.name = "HaloCubeCollision"
	add_child(static_body)

	var half_size = cube_size * 0.5

	# Back wall collider
	var collision_back = CollisionShape3D.new()
	var box_back = BoxShape3D.new()
	box_back.size = Vector3(cube_size, height, wall_thickness)
	collision_back.shape = box_back
	collision_back.position = Vector3(0, height * 0.5, -half_size + wall_thickness * 0.5)
	static_body.add_child(collision_back)

	# Right wall collider
	var collision_right = CollisionShape3D.new()
	var box_right = BoxShape3D.new()
	box_right.size = Vector3(wall_thickness, height, cube_size)
	collision_right.shape = box_right
	collision_right.position = Vector3(half_size - wall_thickness * 0.5, height * 0.5, 0)
	static_body.add_child(collision_right)

	# Front wall collider
	var collision_front = CollisionShape3D.new()
	var box_front = BoxShape3D.new()
	box_front.size = Vector3(cube_size, height, wall_thickness)
	collision_front.shape = box_front
	collision_front.position = Vector3(0, height * 0.5, half_size - wall_thickness * 0.5)
	static_body.add_child(collision_front)

	# Left wall collider
	var collision_left = CollisionShape3D.new()
	var box_left = BoxShape3D.new()
	box_left.size = Vector3(wall_thickness, height, cube_size)
	collision_left.shape = box_left
	collision_left.position = Vector3(-half_size + wall_thickness * 0.5, height * 0.5, 0)
	static_body.add_child(collision_left)

	return static_body

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
