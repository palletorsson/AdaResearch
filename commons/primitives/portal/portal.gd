# Portal.gd - Portal/doorway frame shape (fits within 1,1,1)
extends Node3D

var base_color: Color = Color(0.3, 0.9, 0.9)  # Cyan
var portal_height: float = 0.9
var portal_width: float = 0.6
var frame_thickness: float = 0.1
var frame_depth: float = 0.15

func _ready():
	create_portal()

func create_portal():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertices = create_portal_vertices()
	var faces = create_portal_faces()

	for face in faces:
		add_triangle_with_normal(st, vertices, face)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "PortalMesh"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)

	create_collision()

func create_portal_vertices() -> Array:
	var vertices = []
	var half_width = portal_width * 0.5
	var half_depth = frame_depth * 0.5
	var inner_half_width = half_width - frame_thickness
	var inner_height = portal_height - frame_thickness

	# Portal frame (rectangular frame with hollow center)
	# Outer bottom left corner
	vertices.append_array([
		# Left post outer vertices (0-7)
		Vector3(-half_width, 0, -half_depth),  # 0
		Vector3(-inner_half_width, 0, -half_depth),  # 1
		Vector3(-inner_half_width, 0, half_depth),  # 2
		Vector3(-half_width, 0, half_depth),  # 3
		Vector3(-half_width, portal_height, -half_depth),  # 4
		Vector3(-inner_half_width, portal_height, -half_depth),  # 5
		Vector3(-inner_half_width, portal_height, half_depth),  # 6
		Vector3(-half_width, portal_height, half_depth),  # 7
	])

	# Right post vertices (8-15)
	vertices.append_array([
		Vector3(inner_half_width, 0, -half_depth),  # 8
		Vector3(half_width, 0, -half_depth),  # 9
		Vector3(half_width, 0, half_depth),  # 10
		Vector3(inner_half_width, 0, half_depth),  # 11
		Vector3(inner_half_width, portal_height, -half_depth),  # 12
		Vector3(half_width, portal_height, -half_depth),  # 13
		Vector3(half_width, portal_height, half_depth),  # 14
		Vector3(inner_half_width, portal_height, half_depth),  # 15
	])

	# Top lintel as three plates with meeting edges
	var corner_plate_width = frame_thickness * 1.5

	# Left corner plate (16-23)
	vertices.append_array([
		# Bottom
		Vector3(-half_width, inner_height, -half_depth),  # 16
		Vector3(-half_width + corner_plate_width, inner_height, -half_depth),  # 17
		Vector3(-half_width + corner_plate_width, inner_height, half_depth),  # 18
		Vector3(-half_width, inner_height, half_depth),  # 19
		# Top
		Vector3(-half_width, portal_height, -half_depth),  # 20
		Vector3(-half_width + corner_plate_width, portal_height, -half_depth),  # 21
		Vector3(-half_width + corner_plate_width, portal_height, half_depth),  # 22
		Vector3(-half_width, portal_height, half_depth),  # 23
	])

	# Center top plate (24-31)
	vertices.append_array([
		# Bottom
		Vector3(-half_width + corner_plate_width, inner_height, -half_depth),  # 24
		Vector3(half_width - corner_plate_width, inner_height, -half_depth),  # 25
		Vector3(half_width - corner_plate_width, inner_height, half_depth),  # 26
		Vector3(-half_width + corner_plate_width, inner_height, half_depth),  # 27
		# Top
		Vector3(-half_width + corner_plate_width, portal_height, -half_depth),  # 28
		Vector3(half_width - corner_plate_width, portal_height, -half_depth),  # 29
		Vector3(half_width - corner_plate_width, portal_height, half_depth),  # 30
		Vector3(-half_width + corner_plate_width, portal_height, half_depth),  # 31
	])

	# Right corner plate (32-39)
	vertices.append_array([
		# Bottom
		Vector3(half_width - corner_plate_width, inner_height, -half_depth),  # 32
		Vector3(half_width, inner_height, -half_depth),  # 33
		Vector3(half_width, inner_height, half_depth),  # 34
		Vector3(half_width - corner_plate_width, inner_height, half_depth),  # 35
		# Top
		Vector3(half_width - corner_plate_width, portal_height, -half_depth),  # 36
		Vector3(half_width, portal_height, -half_depth),  # 37
		Vector3(half_width, portal_height, half_depth),  # 38
		Vector3(half_width - corner_plate_width, portal_height, half_depth),  # 39
	])

	return vertices

func create_portal_faces() -> Array:
	var faces = []

	# Left post faces
	# Outer sides
	faces.append([0, 3, 7])
	faces.append([0, 7, 4])
	faces.append([0, 1, 5])
	faces.append([0, 5, 4])
	faces.append([3, 2, 6])
	faces.append([3, 6, 7])
	# Inner side
	faces.append([1, 2, 6])
	faces.append([1, 6, 5])
	# Bottom
	faces.append([0, 2, 1])
	faces.append([0, 3, 2])
	# Top (covered by lintel)

	# Right post faces
	# Outer sides
	faces.append([9, 13, 14])
	faces.append([9, 14, 10])
	faces.append([9, 8, 12])
	faces.append([9, 12, 13])
	faces.append([10, 14, 15])
	faces.append([10, 15, 11])
	# Inner side
	faces.append([8, 15, 12])
	faces.append([8, 11, 15])
	# Bottom
	faces.append([8, 9, 10])
	faces.append([8, 10, 11])

	# Left corner plate (16-23)
	# Bottom
	faces.append([16, 18, 17])
	faces.append([16, 19, 18])
	# Top
	faces.append([20, 21, 22])
	faces.append([20, 22, 23])
	# Sides
	faces.append([16, 17, 21])
	faces.append([16, 21, 20])
	faces.append([19, 23, 22])
	faces.append([19, 22, 18])
	faces.append([16, 20, 23])
	faces.append([16, 23, 19])

	# Center top plate (24-31)
	# Bottom
	faces.append([24, 26, 25])
	faces.append([24, 27, 26])
	# Top
	faces.append([28, 29, 30])
	faces.append([28, 30, 31])
	# Sides
	faces.append([24, 25, 29])
	faces.append([24, 29, 28])
	faces.append([27, 31, 30])
	faces.append([27, 30, 26])

	# Right corner plate (32-39)
	# Bottom
	faces.append([32, 34, 33])
	faces.append([32, 35, 34])
	# Top
	faces.append([36, 37, 38])
	faces.append([36, 38, 39])
	# Sides
	faces.append([33, 34, 38])
	faces.append([33, 38, 37])
	faces.append([35, 39, 38])
	faces.append([35, 38, 34])
	faces.append([32, 33, 37])
	faces.append([32, 37, 36])

	# Meeting edge faces between plates
	faces.append([17, 18, 27])
	faces.append([17, 27, 24])
	faces.append([21, 28, 31])
	faces.append([21, 31, 22])
	faces.append([25, 26, 35])
	faces.append([25, 35, 32])
	faces.append([29, 36, 39])
	faces.append([29, 39, 30])

	return faces

func create_collision():
	var static_body = StaticBody3D.new()
	static_body.name = "PortalCollision"
	add_child(static_body)

	var half_width = portal_width * 0.5
	var inner_half_width = half_width - frame_thickness
	var inner_height = portal_height - frame_thickness

	# Left post collider
	var collision_left = CollisionShape3D.new()
	var box_left = BoxShape3D.new()
	box_left.size = Vector3(frame_thickness, portal_height, frame_depth)
	collision_left.shape = box_left
	collision_left.position = Vector3(-half_width + frame_thickness * 0.5, portal_height * 0.5, 0)
	static_body.add_child(collision_left)

	# Right post collider
	var collision_right = CollisionShape3D.new()
	var box_right = BoxShape3D.new()
	box_right.size = Vector3(frame_thickness, portal_height, frame_depth)
	collision_right.shape = box_right
	collision_right.position = Vector3(half_width - frame_thickness * 0.5, portal_height * 0.5, 0)
	static_body.add_child(collision_right)

	# Top lintel collider
	var collision_top = CollisionShape3D.new()
	var box_top = BoxShape3D.new()
	box_top.size = Vector3(portal_width, frame_thickness, frame_depth)
	collision_top.shape = box_top
	collision_top.position = Vector3(0, portal_height - frame_thickness * 0.5, 0)
	static_body.add_child(collision_top)

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
