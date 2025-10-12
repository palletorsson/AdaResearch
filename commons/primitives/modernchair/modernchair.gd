# ModernChair.gd - Modern chair with configurable dimensions
extends MeshInstance3D

@export_group("Chair Dimensions")
@export var seat_width: float = 0.5     # X dimension
@export var seat_depth: float = 0.5     # Y dimension
@export var seat_thickness: float = 0.1 # Z thickness
@export var leg_height: float = 0.4     # Height of legs below seat
@export var back_height: float = 0.5    # Height of backrest above seat

@export_group("Settings")
@export var create_on_ready: bool = true
@export var base_color: Color = Color(0.7, 0.7, 0.75)  # Light gray

func _ready():
	if create_on_ready:
		create_chair()

func create_chair() -> void:
	# Reset pose before rebuild
	rotation = Vector3.ZERO
	scale = Vector3.ONE
	# Base vertices from Blender (normalized)
	var base_vertices = [
		Vector3(-0.25, -0.25, -0.05),
		Vector3(-0.25, -0.25, 0.05),
		Vector3(-0.25, 0.25, -0.05),
		Vector3(-0.25, 0.25, 0.05),
		Vector3(0.25, -0.25, -0.05),
		Vector3(0.25, -0.25, 0.05),
		Vector3(0.25, 0.25, -0.05),
		Vector3(0.25, 0.25, 0.05),
		Vector3(-0.25, 0.125, -0.05),
		Vector3(-0.25, 0.0, -0.05),
		Vector3(-0.25, -0.125, -0.05),
		Vector3(-0.25, -0.125, 0.05),
		Vector3(-0.25, 0.0, 0.05),
		Vector3(-0.25, 0.125, 0.05),
		Vector3(0.125, 0.25, -0.05),
		Vector3(0.0, 0.25, -0.05),
		Vector3(-0.125, 0.25, -0.05),
		Vector3(-0.125, 0.25, 0.05),
		Vector3(0.0, 0.25, 0.05),
		Vector3(0.125, 0.25, 0.05),
		Vector3(0.25, -0.125, -0.05),
		Vector3(0.25, 0.0, -0.05),
		Vector3(0.25, 0.125, -0.05),
		Vector3(0.25, 0.125, 0.05),
		Vector3(0.25, 0.0, 0.05),
		Vector3(0.25, -0.125, 0.05),
		Vector3(-0.125, -0.25, -0.05),
		Vector3(0.0, -0.25, -0.05),
		Vector3(0.125, -0.25, -0.05),
		Vector3(0.125, -0.25, 0.05),
		Vector3(0.0, -0.25, 0.05),
		Vector3(-0.125, -0.25, 0.05),
		Vector3(0.125, 0.125, 0.05),
		Vector3(0.125, 0.0, 0.05),
		Vector3(0.125, -0.125, 0.05),
		Vector3(0.0, 0.125, 0.05),
		Vector3(0.0, 0.0, 0.05),
		Vector3(0.0, -0.125, 0.05),
		Vector3(-0.125, 0.125, 0.05),
		Vector3(-0.125, 0.0, 0.05),
		Vector3(-0.125, -0.125, 0.05),
		Vector3(-0.125, 0.125, -0.05),
		Vector3(-0.125, 0.0, -0.05),
		Vector3(-0.125, -0.125, -0.05),
		Vector3(0.0, 0.125, -0.05),
		Vector3(0.0, 0.0, -0.05),
		Vector3(0.0, -0.125, -0.05),
		Vector3(0.125, 0.125, -0.05),
		Vector3(0.125, 0.0, -0.05),
		Vector3(0.125, -0.125, -0.05),
		Vector3(0.125, 0.25, 0.45),
		Vector3(0.25, 0.25, 0.45),
		Vector3(0.25, -0.125, 0.45),
		Vector3(0.25, -0.25, 0.45),
		Vector3(0.25, 0.125, 0.45),
		Vector3(0.25, 0.0, 0.45),
		Vector3(0.125, -0.25, 0.45),
		Vector3(0.125, -0.125, 0.45),
		Vector3(0.125, 0.125, 0.45),
		Vector3(0.125, 0.0, 0.45),
		Vector3(-0.25, -0.125, -0.55),
		Vector3(-0.25, -0.25, -0.55),
		Vector3(-0.125, 0.25, -0.55),
		Vector3(-0.25, 0.25, -0.55),
		Vector3(0.25, 0.125, -0.55),
		Vector3(0.25, 0.25, -0.55),
		Vector3(0.125, -0.25, -0.55),
		Vector3(0.25, -0.25, -0.55),
		Vector3(-0.25, 0.125, -0.55),
		Vector3(0.125, 0.25, -0.55),
		Vector3(0.25, -0.125, -0.55),
		Vector3(-0.125, -0.25, -0.55),
		Vector3(-0.125, -0.125, -0.55),
		Vector3(-0.125, 0.125, -0.55),
		Vector3(0.125, -0.125, -0.55),
		Vector3(0.125, 0.125, -0.55)
	]

	# Face definitions from Blender
	var faces = [
		[8, 13, 3, 2], [14, 19, 7, 6], [20, 25, 5, 4], [26, 31, 1, 0],
		[41, 8, 68, 73], [40, 11, 1, 31], [24, 23, 54, 55], [34, 37, 30, 29],
		[37, 40, 31, 30], [32, 33, 59, 58], [23, 7, 51, 54], [19, 32, 58, 50],
		[19, 18, 35, 32], [32, 35, 36, 33], [33, 36, 37, 34], [18, 17, 38, 35],
		[35, 38, 39, 36], [36, 39, 40, 37], [17, 3, 13, 38], [38, 13, 12, 39],
		[39, 12, 11, 40], [8, 2, 63, 68], [43, 46, 27, 26], [46, 49, 28, 27],
		[2, 16, 62, 63], [8, 41, 42, 9], [9, 42, 43, 10], [16, 15, 44, 41],
		[41, 44, 45, 42], [42, 45, 46, 43], [15, 14, 47, 44], [44, 47, 48, 45],
		[45, 48, 49, 46], [14, 6, 65, 69], [47, 22, 21, 48], [48, 21, 20, 49],
		[4, 5, 29, 28], [28, 29, 30, 27], [27, 30, 31, 26], [6, 7, 23, 22],
		[22, 23, 24, 21], [21, 24, 25, 20], [2, 3, 17, 16], [16, 17, 18, 15],
		[15, 18, 19, 14], [0, 1, 11, 10], [10, 11, 12, 9], [9, 12, 13, 8],
		[52, 57, 56, 53], [51, 50, 58, 54], [54, 58, 59, 55], [55, 59, 57, 52],
		[5, 25, 52, 53], [33, 34, 57, 59], [7, 19, 50, 51], [25, 24, 55, 52],
		[34, 29, 56, 57], [29, 5, 53, 56], [74, 70, 67, 66], [60, 72, 71, 61],
		[63, 62, 73, 68], [69, 65, 64, 75], [22, 47, 75, 64], [6, 22, 64, 65],
		[10, 43, 72, 60], [0, 10, 60, 61], [26, 0, 61, 71], [43, 26, 71, 72],
		[28, 49, 74, 66], [49, 20, 70, 74], [20, 4, 67, 70], [16, 41, 73, 62],
		[47, 14, 69, 75], [4, 28, 66, 67]
	]

	# Scale vertices based on parameters
	# Base model: seat is at z=0 (±0.05), legs go down to z=-0.55, backrest up to z=0.45
	# We need to scale: X by seat_width, Y by seat_depth, Z by heights

	var scaled_vertices = []
	for v in base_vertices:
		var scaled_v = Vector3.ZERO

		# Scale X (width)
		scaled_v.x = v.x * seat_width

		# Scale Y (depth)
		scaled_v.y = v.y * seat_depth

		# Scale Z (height) - different scaling for legs, seat, and backrest
		if v.z < -0.05:  # Legs (below seat)
			# Map from -0.55 to -0.05 → -leg_height to 0
			var normalized = (v.z + 0.05) / -0.5  # 0 to 1
			scaled_v.z = -normalized * leg_height
		elif v.z > 0.05:  # Backrest (above seat)
			# Map from 0.05 to 0.45 → 0 to back_height
			var normalized = (v.z - 0.05) / 0.4  # 0 to 1
			scaled_v.z = normalized * back_height
		else:  # Seat
			# Map from -0.05 to 0.05 → -seat_thickness/2 to seat_thickness/2
			scaled_v.z = v.z * seat_thickness

		scaled_vertices.append(scaled_v)

	# Create mesh using SurfaceTool
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Convert quads to triangles
	for face in faces:
		var v0 = scaled_vertices[face[0]]
		var v1 = scaled_vertices[face[1]]
		var v2 = scaled_vertices[face[2]]
		var v3 = scaled_vertices[face[3]]

		# Calculate normal
		var edge1 = v1 - v0
		var edge2 = v3 - v0
		var normal = edge1.cross(edge2).normalized()

		# First triangle (v0, v1, v2)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v0)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v1)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v2)

		# Second triangle (v0, v2, v3)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v0)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v2)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v3)

	# Generate normals and create mesh
	surface_tool.generate_normals()
	mesh = surface_tool.commit()

	# Apply material
	apply_queer_material()

	# Rotate and scale for proper orientation
	rotate_z(deg_to_rad(90.0))
	scale *= 1.3

	# Add collision
	create_collision()

	print("Chair created: Width=%.2f, Depth=%.2f, Seat=%.2f, Legs=%.2f, Back=%.2f" %
		[seat_width, seat_depth, seat_thickness, leg_height, back_height])

func apply_queer_material():
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		material.set_shader_parameter("base_color", base_color)
		material.set_shader_parameter("edge_color", Color.WHITE)
		material.set_shader_parameter("edge_width", 1.5)
		material.set_shader_parameter("edge_sharpness", 2.0)
		material.set_shader_parameter("emission_strength", 1.0)
		material_override = material
	else:
		# Fallback to standard material
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = base_color
		standard_material.metallic = 0.0
		standard_material.roughness = 0.6
		mesh.surface_set_material(0, standard_material)

func create_collision():
	# Create parent static body
	var static_body = StaticBody3D.new()
	static_body.name = "ModernChairCollision"
	add_child(static_body)

	# Seat collision
	var collision_seat = CollisionShape3D.new()
	var box_seat = BoxShape3D.new()
	box_seat.size = Vector3(seat_width, seat_depth, seat_thickness)
	collision_seat.shape = box_seat
	collision_seat.position = Vector3(0, 0, 0)
	static_body.add_child(collision_seat)

	# Backrest collision (approximate)
	var collision_back = CollisionShape3D.new()
	var box_back = BoxShape3D.new()
	box_back.size = Vector3(seat_width * 0.5, seat_depth * 0.2, back_height)
	collision_back.shape = box_back
	collision_back.position = Vector3(0, seat_depth * 0.15, back_height * 0.5)
	static_body.add_child(collision_back)

# Update function for changing parameters
func update_chair():
	create_chair()
