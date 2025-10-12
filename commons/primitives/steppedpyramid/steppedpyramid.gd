# SteppedPyramid.gd - Stepped pyramid/ziggurat shape from Blender export
extends MeshInstance3D

@export var number_of_sides: int = 4  # Number of sides (4 = square pyramid)
@export var number_of_steps: int = 10  # Number of steps/levels
@export var initial_width: float = 2.0  # Base width
@export var height: float = 0.10  # Height per step
@export var reduce_step_by: float = 0.20  # How much to reduce width each step
@export var create_on_ready: bool = true
@export var base_color: Color = Color(0.65, 0.65, 0.65)  # Gray

func _ready():
	if create_on_ready:
		create_stepped_pyramid()

func create_stepped_pyramid() -> void:
	rotation = Vector3.ZERO
	scale = Vector3.ONE
	# Vertices from Blender export
	var base_vertices = [
		Vector3(1.0, 0.0, 0.0),
		Vector3(8.94069672e-08, -1.0, 0.0),
		Vector3(-1.0, -8.74227766e-08, 0.0),
		Vector3(8.94069672e-08, 1.0, 0.0),
		Vector3(1.0, 0.0, 0.1),
		Vector3(8.94069672e-08, -1.0, 0.1),
		Vector3(-1.0, -8.74227766e-08, 0.1),
		Vector3(8.94069672e-08, 1.0, 0.1),
		Vector3(0.9, 0.0, 0.1),
		Vector3(8.94069672e-08, -0.9, 0.1),
		Vector3(-0.9, -7.86805003e-08, 0.1),
		Vector3(8.94069672e-08, 0.9, 0.1),
		Vector3(0.9, 0.0, 0.2),
		Vector3(8.94069672e-08, -0.9, 0.2),
		Vector3(-0.9, -7.86805003e-08, 0.2),
		Vector3(8.94069672e-08, 0.9, 0.2),
		Vector3(0.8, 0.0, 0.2),
		Vector3(2.98023224e-08, -0.8, 0.2),
		Vector3(-0.8, -6.99382241e-08, 0.2),
		Vector3(2.98023224e-08, 0.8, 0.2),
		Vector3(0.8, 0.0, 0.3),
		Vector3(2.98023224e-08, -0.8, 0.3),
		Vector3(-0.8, -6.99382241e-08, 0.3),
		Vector3(2.98023224e-08, 0.8, 0.3),
		Vector3(0.7, 0.0, 0.3),
		Vector3(2.98023224e-08, -0.7, 0.3),
		Vector3(-0.7, -6.11959408e-08, 0.3),
		Vector3(2.98023224e-08, 0.7, 0.3),
		Vector3(0.7, 0.0, 0.4),
		Vector3(2.98023224e-08, -0.7, 0.4),
		Vector3(-0.7, -6.11959408e-08, 0.4),
		Vector3(2.98023224e-08, 0.7, 0.4),
		Vector3(0.6, 0.0, 0.4),
		Vector3(2.98023224e-08, -0.6, 0.4),
		Vector3(-0.6, -5.24536681e-08, 0.4),
		Vector3(2.98023224e-08, 0.6, 0.4),
		Vector3(0.6, 0.0, 0.5),
		Vector3(2.98023224e-08, -0.6, 0.5),
		Vector3(-0.6, -5.24536681e-08, 0.5),
		Vector3(2.98023224e-08, 0.6, 0.5),
		Vector3(0.5, 0.0, 0.5),
		Vector3(4.47034836e-08, -0.5, 0.5),
		Vector3(-0.5, -4.37113883e-08, 0.5),
		Vector3(4.47034836e-08, 0.5, 0.5),
		Vector3(0.5, 0.0, 0.6),
		Vector3(4.47034836e-08, -0.5, 0.6),
		Vector3(-0.5, -4.37113883e-08, 0.6),
		Vector3(4.47034836e-08, 0.5, 0.6),
		Vector3(0.4, 0.0, 0.6),
		Vector3(2.98023224e-08, -0.4, 0.6),
		Vector3(-0.4, -3.49691085e-08, 0.6),
		Vector3(2.98023224e-08, 0.4, 0.6),
		Vector3(0.4, 0.0, 0.7),
		Vector3(2.98023224e-08, -0.4, 0.7),
		Vector3(-0.4, -3.49691085e-08, 0.7),
		Vector3(2.98023224e-08, 0.4, 0.7),
		Vector3(0.3, 0.0, 0.7),
		Vector3(1.49011612e-08, -0.3, 0.7),
		Vector3(-0.3, -2.62268323e-08, 0.7),
		Vector3(1.49011612e-08, 0.3, 0.7),
		Vector3(0.3, 0.0, 0.8),
		Vector3(1.49011612e-08, -0.3, 0.8),
		Vector3(-0.3, -2.62268323e-08, 0.8),
		Vector3(1.49011612e-08, 0.3, 0.8),
		Vector3(0.2, 0.0, 0.8),
		Vector3(1.49011612e-08, -0.2, 0.8),
		Vector3(-0.2, -1.74845542e-08, 0.8),
		Vector3(1.49011612e-08, 0.2, 0.8),
		Vector3(0.2, 0.0, 0.9),
		Vector3(1.49011612e-08, -0.2, 0.9),
		Vector3(-0.2, -1.74845542e-08, 0.9),
		Vector3(1.49011612e-08, 0.2, 0.9),
		Vector3(0.1, 0.0, 0.9),
		Vector3(1.11758709e-08, -0.1, 0.9),
		Vector3(-0.1, -8.74227624e-09, 0.9),
		Vector3(1.11758709e-08, 0.1, 0.9),
		Vector3(0.1, 0.0, 1.0),
		Vector3(1.11758709e-08, -0.1, 1.0),
		Vector3(-0.1, -8.74227624e-09, 1.0),
		Vector3(1.11758709e-08, 0.1, 1.0)
	]

	# Face definitions from Blender
	var faces = [
		[0, 1, 2, 3],
		[79, 78, 77, 76],
		[0, 4, 5, 1],
		[1, 5, 6, 2],
		[2, 6, 7, 3],
		[3, 7, 4, 0],
		[8, 12, 13, 9],
		[9, 13, 14, 10],
		[10, 14, 15, 11],
		[11, 15, 12, 8],
		[16, 20, 21, 17],
		[17, 21, 22, 18],
		[18, 22, 23, 19],
		[19, 23, 20, 16],
		[24, 28, 29, 25],
		[25, 29, 30, 26],
		[26, 30, 31, 27],
		[27, 31, 28, 24],
		[32, 36, 37, 33],
		[33, 37, 38, 34],
		[34, 38, 39, 35],
		[35, 39, 36, 32],
		[40, 44, 45, 41],
		[41, 45, 46, 42],
		[42, 46, 47, 43],
		[43, 47, 44, 40],
		[48, 52, 53, 49],
		[49, 53, 54, 50],
		[50, 54, 55, 51],
		[51, 55, 52, 48],
		[56, 60, 61, 57],
		[57, 61, 62, 58],
		[58, 62, 63, 59],
		[59, 63, 60, 56],
		[64, 68, 69, 65],
		[65, 69, 70, 66],
		[66, 70, 71, 67],
		[67, 71, 68, 64],
		[72, 76, 77, 73],
		[73, 77, 78, 74],
		[74, 78, 79, 75],
		[75, 79, 76, 72],
		[4, 8, 9, 5],
		[5, 9, 10, 6],
		[6, 10, 11, 7],
		[7, 11, 8, 4],
		[12, 16, 17, 13],
		[13, 17, 18, 14],
		[14, 18, 19, 15],
		[15, 19, 16, 12],
		[20, 24, 25, 21],
		[21, 25, 26, 22],
		[22, 26, 27, 23],
		[23, 27, 24, 20],
		[28, 32, 33, 29],
		[29, 33, 34, 30],
		[30, 34, 35, 31],
		[31, 35, 32, 28],
		[36, 40, 41, 37],
		[37, 41, 42, 38],
		[38, 42, 43, 39],
		[39, 43, 40, 36],
		[44, 48, 49, 45],
		[45, 49, 50, 46],
		[46, 50, 51, 47],
		[47, 51, 48, 44],
		[52, 56, 57, 53],
		[53, 57, 58, 54],
		[54, 58, 59, 55],
		[55, 59, 56, 52],
		[60, 64, 65, 61],
		[61, 65, 66, 62],
		[62, 66, 67, 63],
		[63, 67, 64, 60],
		[68, 72, 73, 69],
		[69, 73, 74, 70],
		[70, 74, 75, 71],
		[71, 75, 72, 68]
	]

	# Scale vertices
	var scaled_vertices = []
	for v in base_vertices:
		# Scale XY by initial_width, Z by total height
		var total_height = height * number_of_steps
		scaled_vertices.append(Vector3(
			v.x * initial_width,
			v.y * initial_width,
			v.z * total_height
		))

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

		# First triangle
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v0)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v1)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v2)

		# Second triangle
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

	# Rotate and scale to face +Y and shrink
	rotate_z(deg_to_rad(90.0))
	scale *= 0.5

	# Add collision
	var collision_body := create_collision()
	if collision_body:
		collision_body.rotate_z(deg_to_rad(90.0))
		collision_body.scale *= 0.5

	print("Stepped pyramid created with %d vertices and %d faces" % [scaled_vertices.size(), faces.size()])

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
		standard_material.roughness = 0.7
		mesh.surface_set_material(0, standard_material)

func create_collision() -> StaticBody3D:
	# Create parent static body
	var static_body = StaticBody3D.new()
	static_body.name = "SteppedPyramidCollision"
	add_child(static_body)

	# Approximate collision with box (pyramid envelope)
	var collision = CollisionShape3D.new()
	var box = BoxShape3D.new()
	var total_height = height * number_of_steps
	box.size = Vector3(initial_width * 2.0, initial_width * 2.0, total_height)
	collision.shape = box
	collision.position = Vector3(0, 0, total_height * 0.5)
	static_body.add_child(collision)

	return static_body
