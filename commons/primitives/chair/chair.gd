# Chair.gd - Profile chair shape (side view of a chair, fits within 1,1,1)
extends Node3D

var base_color: Color = Color(0.6, 0.3, 0.8)  # Purple
var seat_height: float = 0.4
var seat_depth: float = 0.4
var back_height: float = 0.5
var thickness: float = 0.08

func _ready():
	create_chair()

func create_chair():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertices = create_chair_vertices()
	var faces = create_chair_faces()

	for face in faces:
		add_triangle_with_normal(st, vertices, face)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "ChairMesh"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)

	create_collision()

func create_chair_vertices() -> Array:
	var vertices = []
	var half_thick = thickness * 0.5

	# Profile chair viewed from side:
	# - Seat (horizontal) at seat_height
	# - Back rest (vertical) at back of seat
	# - Front leg
	# - Back leg

	# Front leg (0-7)
	vertices.append_array([
		# Bottom
		Vector3(-seat_depth * 0.3, 0, -half_thick),
		Vector3(-seat_depth * 0.3 + thickness, 0, -half_thick),
		Vector3(-seat_depth * 0.3 + thickness, 0, half_thick),
		Vector3(-seat_depth * 0.3, 0, half_thick),
		# Top (at seat height)
		Vector3(-seat_depth * 0.3, seat_height, -half_thick),
		Vector3(-seat_depth * 0.3 + thickness, seat_height, -half_thick),
		Vector3(-seat_depth * 0.3 + thickness, seat_height, half_thick),
		Vector3(-seat_depth * 0.3, seat_height, half_thick),
	])

	# Back leg (8-15)
	vertices.append_array([
		# Bottom
		Vector3(seat_depth * 0.3 - thickness, 0, -half_thick),
		Vector3(seat_depth * 0.3, 0, -half_thick),
		Vector3(seat_depth * 0.3, 0, half_thick),
		Vector3(seat_depth * 0.3 - thickness, 0, half_thick),
		# Top (at seat height)
		Vector3(seat_depth * 0.3 - thickness, seat_height, -half_thick),
		Vector3(seat_depth * 0.3, seat_height, -half_thick),
		Vector3(seat_depth * 0.3, seat_height, half_thick),
		Vector3(seat_depth * 0.3 - thickness, seat_height, half_thick),
	])

	# Seat (horizontal surface) with integrated corners (16-23)
	# Seat connects directly to leg tops and back rest
	vertices.append_array([
		# Bottom - connects to leg tops
		Vector3(-seat_depth * 0.4, seat_height, -half_thick),
		Vector3(seat_depth * 0.35, seat_height, -half_thick),  # Stop at backrest
		Vector3(seat_depth * 0.35, seat_height, half_thick),
		Vector3(-seat_depth * 0.4, seat_height, half_thick),
		# Top
		Vector3(-seat_depth * 0.4, seat_height + thickness, -half_thick),
		Vector3(seat_depth * 0.35, seat_height + thickness, -half_thick),  # Align with backrest
		Vector3(seat_depth * 0.35, seat_height + thickness, half_thick),
		Vector3(-seat_depth * 0.4, seat_height + thickness, half_thick),
	])

	# Back rest (vertical at back of seat) with corner integration (24-31)
	var back_top = seat_height + back_height
	vertices.append_array([
		# Front face (shares edge with seat)
		Vector3(seat_depth * 0.35, seat_height, -half_thick),  # Start at seat level
		Vector3(seat_depth * 0.35 + thickness, seat_height, -half_thick),
		Vector3(seat_depth * 0.35 + thickness, seat_height, half_thick),
		Vector3(seat_depth * 0.35, seat_height, half_thick),
		# Top of back rest
		Vector3(seat_depth * 0.35, back_top, -half_thick),
		Vector3(seat_depth * 0.35 + thickness, back_top, -half_thick),
		Vector3(seat_depth * 0.35 + thickness, back_top, half_thick),
		Vector3(seat_depth * 0.35, back_top, half_thick),
	])

	return vertices

func create_chair_faces() -> Array:
	var faces = []

	# Helper function to add box faces
	var add_box = func(base_idx: int):
		# Bottom
		faces.append([base_idx + 0, base_idx + 2, base_idx + 1])
		faces.append([base_idx + 0, base_idx + 3, base_idx + 2])
		# Top
		faces.append([base_idx + 4, base_idx + 5, base_idx + 6])
		faces.append([base_idx + 4, base_idx + 6, base_idx + 7])
		# Sides
		faces.append([base_idx + 0, base_idx + 1, base_idx + 5])
		faces.append([base_idx + 0, base_idx + 5, base_idx + 4])
		faces.append([base_idx + 1, base_idx + 2, base_idx + 6])
		faces.append([base_idx + 1, base_idx + 6, base_idx + 5])
		faces.append([base_idx + 2, base_idx + 3, base_idx + 7])
		faces.append([base_idx + 2, base_idx + 7, base_idx + 6])
		faces.append([base_idx + 3, base_idx + 0, base_idx + 4])
		faces.append([base_idx + 3, base_idx + 4, base_idx + 7])

	# Front leg (0)
	add_box.call(0)
	# Back leg (8)
	add_box.call(8)
	# Seat (16)
	add_box.call(16)
	# Back rest (24)
	add_box.call(24)

	return faces

func create_collision():
	var static_body = StaticBody3D.new()
	static_body.name = "ChairCollision"
	add_child(static_body)

	# Seat collider
	var collision_seat = CollisionShape3D.new()
	var box_seat = BoxShape3D.new()
	box_seat.size = Vector3(seat_depth * 0.8, thickness, thickness)
	collision_seat.shape = box_seat
	collision_seat.position = Vector3(0, seat_height + thickness * 0.5, 0)
	static_body.add_child(collision_seat)

	# Back rest collider
	var collision_back = CollisionShape3D.new()
	var box_back = BoxShape3D.new()
	box_back.size = Vector3(thickness, back_height, thickness)
	collision_back.shape = box_back
	collision_back.position = Vector3(seat_depth * 0.35 + thickness * 0.5, seat_height + thickness + back_height * 0.5, 0)
	static_body.add_child(collision_back)

	# Front leg collider
	var collision_front = CollisionShape3D.new()
	var box_front = BoxShape3D.new()
	box_front.size = Vector3(thickness, seat_height, thickness)
	collision_front.shape = box_front
	collision_front.position = Vector3(-seat_depth * 0.3 + thickness * 0.5, seat_height * 0.5, 0)
	static_body.add_child(collision_front)

	# Back leg collider
	var collision_back_leg = CollisionShape3D.new()
	var box_back_leg = BoxShape3D.new()
	box_back_leg.size = Vector3(thickness, seat_height, thickness)
	collision_back_leg.shape = box_back_leg
	collision_back_leg.position = Vector3(seat_depth * 0.3 - thickness * 0.5, seat_height * 0.5, 0)
	static_body.add_child(collision_back_leg)

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
