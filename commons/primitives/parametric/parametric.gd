# Parametric.gd - Parametric surface shape
# Parametric equations:
# X: cos(v)*(1+cos(u))*sin(v/8)
# Y: sin(u)*sin(v/8)+cos(v/8)*1.5
# Z: sin(v)*(1+cos(u))*sin(v/8)

extends MeshInstance3D

@export var u_min: float = 0.0
@export var u_max: float = 6.28  # ~2π
@export var u_steps: int = 32
@export var v_min: float = 0.0
@export var v_max: float = 12.57  # ~4π
@export var v_steps: int = 128
@export var base_color: Color = Color(1.0, 0.6, 0.3)  # Orange

func _ready():
	create_parametric_surface()

func create_parametric_surface():
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Calculate step sizes
	var u_step_size = (u_max - u_min) / float(u_steps)
	var v_step_size = (v_max - v_min) / float(v_steps)

	# Generate vertices and store them
	var vertices = []
	for i in range(u_steps + 1):
		var row = []
		for j in range(v_steps + 1):
			var u = u_min + i * u_step_size
			var v = v_min + j * v_step_size

			# Parametric equations
			var x = cos(v) * (1.0 + cos(u)) * sin(v / 8.0)
			var y = sin(u) * sin(v / 8.0) + cos(v / 8.0) * 1.5
			var z = sin(v) * (1.0 + cos(u)) * sin(v / 8.0)

			row.append(Vector3(x, y, z))
		vertices.append(row)

	# Create faces (quads as two triangles)
	for i in range(u_steps):
		for j in range(v_steps):
			# Get the four corners of the quad
			var v0 = vertices[i][j]
			var v1 = vertices[i + 1][j]
			var v2 = vertices[i + 1][j + 1]
			var v3 = vertices[i][j + 1]

			# Calculate normal for the quad (for smooth shading)
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

	# Generate normals and create the mesh
	surface_tool.generate_normals()
	mesh = surface_tool.commit()

	# Create a material with shader support
	apply_queer_material()

	# Add collision
	create_collision()

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

func create_collision():
	# Create parent static body if needed
	var static_body = StaticBody3D.new()
	static_body.name = "ParametricCollision"
	add_child(static_body)

	# Approximate collision with sphere
	var collision = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 1.5
	collision.shape = sphere
	collision.position = Vector3(0, 1.5, 0)
	static_body.add_child(collision)
