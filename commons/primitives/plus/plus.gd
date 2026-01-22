# Plus.gd - Plus/cross shape (+) with 4 arms at 90° angles (fits within 1,1,1)
extends Node3D

var base_color: Color = Color(0.2, 0.8, 0.2)  # Green (health pickup color)
var arm_length: float = 0.45  # Length from center to arm tip
var arm_width: float = 0.15   # Width of each arm
var thickness: float = 0.125  # Z thickness

func _ready():
	create_plus()

func create_plus():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertices = create_plus_vertices()
	var faces = create_plus_faces()

	for face in faces:
		add_triangle_with_normal(st, vertices, face)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "PlusMesh"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)

	create_collision()

func create_plus_vertices() -> Array:
	var vertices = []
	var half_w = arm_width / 2.0
	var half_t = thickness / 2.0

	# Plus shape vertices - 12 corners on front, 12 on back
	# Front face (Z+) - going clockwise from top-right of center
	#
	#        8---9
	#        |   |
	#    4---5   10--11
	#    |           |
	#    3---2   13--12
	#        |   |
	#        1---0
	#    (also 7,6,15,14 on inner corners)

	# Front vertices (0-11) - outer corners clockwise from bottom-right
	vertices.append(Vector3(half_w, -arm_length, half_t))   # 0 - bottom arm, right
	vertices.append(Vector3(-half_w, -arm_length, half_t))  # 1 - bottom arm, left
	vertices.append(Vector3(-half_w, -half_w, half_t))      # 2 - inner corner
	vertices.append(Vector3(-arm_length, -half_w, half_t))  # 3 - left arm, bottom
	vertices.append(Vector3(-arm_length, half_w, half_t))   # 4 - left arm, top
	vertices.append(Vector3(-half_w, half_w, half_t))       # 5 - inner corner
	vertices.append(Vector3(-half_w, arm_length, half_t))   # 6 - top arm, left
	vertices.append(Vector3(half_w, arm_length, half_t))    # 7 - top arm, right
	vertices.append(Vector3(half_w, half_w, half_t))        # 8 - inner corner
	vertices.append(Vector3(arm_length, half_w, half_t))    # 9 - right arm, top
	vertices.append(Vector3(arm_length, -half_w, half_t))   # 10 - right arm, bottom
	vertices.append(Vector3(half_w, -half_w, half_t))       # 11 - inner corner

	# Back vertices (12-23) - same pattern at Z-
	vertices.append(Vector3(half_w, -arm_length, -half_t))   # 12
	vertices.append(Vector3(-half_w, -arm_length, -half_t))  # 13
	vertices.append(Vector3(-half_w, -half_w, -half_t))      # 14
	vertices.append(Vector3(-arm_length, -half_w, -half_t))  # 15
	vertices.append(Vector3(-arm_length, half_w, -half_t))   # 16
	vertices.append(Vector3(-half_w, half_w, -half_t))       # 17
	vertices.append(Vector3(-half_w, arm_length, -half_t))   # 18
	vertices.append(Vector3(half_w, arm_length, -half_t))    # 19
	vertices.append(Vector3(half_w, half_w, -half_t))        # 20
	vertices.append(Vector3(arm_length, half_w, -half_t))    # 21
	vertices.append(Vector3(arm_length, -half_w, -half_t))   # 22
	vertices.append(Vector3(half_w, -half_w, -half_t))       # 23

	return vertices

func create_plus_faces() -> Array:
	var faces = []

	# Front face (Z+) - fan from center, but plus is not convex
	# We need to triangulate the plus shape properly
	# Using vertex 2 as a hub for front face triangulation
	faces.append([0, 11, 2])
	faces.append([0, 2, 1])
	faces.append([2, 5, 3])
	faces.append([3, 5, 4])
	faces.append([5, 8, 6])
	faces.append([6, 8, 7])
	faces.append([8, 11, 9])
	faces.append([9, 11, 10])
	# Connect the center
	faces.append([2, 11, 8])
	faces.append([2, 8, 5])

	# Back face (Z-) - reversed winding
	faces.append([14, 23, 12])
	faces.append([14, 12, 13])
	faces.append([17, 14, 15])
	faces.append([17, 15, 16])
	faces.append([20, 17, 18])
	faces.append([20, 18, 19])
	faces.append([23, 20, 21])
	faces.append([23, 21, 22])
	# Connect the center
	faces.append([20, 23, 14])
	faces.append([20, 14, 17])

	# Side faces - connect front to back edges
	# Bottom arm
	faces.append([0, 12, 13])
	faces.append([0, 13, 1])
	# Bottom-left corner to left arm bottom
	faces.append([1, 13, 14])
	faces.append([1, 14, 2])
	faces.append([2, 14, 15])
	faces.append([2, 15, 3])
	# Left arm
	faces.append([3, 15, 16])
	faces.append([3, 16, 4])
	# Left arm top to top-left corner
	faces.append([4, 16, 17])
	faces.append([4, 17, 5])
	faces.append([5, 17, 18])
	faces.append([5, 18, 6])
	# Top arm
	faces.append([6, 18, 19])
	faces.append([6, 19, 7])
	# Top-right corner to right arm top
	faces.append([7, 19, 20])
	faces.append([7, 20, 8])
	faces.append([8, 20, 21])
	faces.append([8, 21, 9])
	# Right arm
	faces.append([9, 21, 22])
	faces.append([9, 22, 10])
	# Right arm bottom to bottom-right corner
	faces.append([10, 22, 23])
	faces.append([10, 23, 11])
	faces.append([11, 23, 12])
	faces.append([11, 12, 0])

	return faces

func create_collision():
	var static_body = StaticBody3D.new()
	static_body.name = "PlusCollision"
	add_child(static_body)

	# Horizontal bar
	var h_collision = CollisionShape3D.new()
	var h_box = BoxShape3D.new()
	h_box.size = Vector3(arm_length * 2, arm_width, thickness)
	h_collision.shape = h_box
	static_body.add_child(h_collision)

	# Vertical bar
	var v_collision = CollisionShape3D.new()
	var v_box = BoxShape3D.new()
	v_box.size = Vector3(arm_width, arm_length * 2, thickness)
	v_collision.shape = v_box
	static_body.add_child(v_collision)

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

func set_base_color(color: Color):
	base_color = color
	var mesh_instance = get_node_or_null("PlusMesh")
	if mesh_instance:
		apply_queer_material(mesh_instance, base_color)
