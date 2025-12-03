# Klein Bottle - Non-orientable parametric surface
# A 3D immersion of the Klein bottle (4D surface)
# Parametric equations using the figure-8 immersion

extends XRToolsPickable

@export var u_min: float = 0.0
@export var u_max: float = 6.28  # ~2π
@export var u_steps: int = 48
@export var v_min: float = 0.0
@export var v_max: float = 6.28  # ~2π
@export var v_steps: int = 48
@export var scale_factor: float = 0.15  # Hand-sized scale
@export var base_color: Color = Color(0.2, 0.7, 0.9)  # Light blue

var mesh_instance: MeshInstance3D

func _ready():
	super._ready()
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

			# Klein bottle parametric equations (figure-8 immersion)
			var r = 4.0 * (1.0 - cos(u) / 2.0)
			var x: float
			var y: float
			var z: float

			if u < PI:
				x = 6.0 * cos(u) * (1.0 + sin(u)) + r * cos(u) * cos(v)
				y = 16.0 * sin(u) + r * sin(u) * cos(v)
			else:
				x = 6.0 * cos(u) * (1.0 + sin(u)) + r * cos(v + PI)
				y = 16.0 * sin(u)

			z = r * sin(v)

			row.append(Vector3(x, y, z) * 0.1 * scale_factor)
		vertices.append(row)

	# Create faces (quads as two triangles)
	for i in range(u_steps):
		for j in range(v_steps):
			# Get the four corners of the quad
			var v0 = vertices[i][j]
			var v1 = vertices[i + 1][j]
			var v2 = vertices[i + 1][j + 1]
			var v3 = vertices[i][j + 1]

			# Calculate normal for the quad
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
	var generated_mesh = surface_tool.commit()

	# Create mesh instance as child
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = generated_mesh
	add_child(mesh_instance)

	# Apply material
	apply_material()

	# Add collision shape for pickable
	create_collision()

func apply_material():
	if not mesh_instance:
		return

	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		material.set_shader_parameter("modelColor", base_color)
		material.set_shader_parameter("wireframeColor", Color.WHITE)
		material.set_shader_parameter("emissionColor", base_color)
		material.set_shader_parameter("width", 1.0)
		material.set_shader_parameter("emission_strength", 1.5)
		mesh_instance.material_override = material
	else:
		# Fallback to standard material
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = base_color
		standard_material.metallic = 0.3
		standard_material.roughness = 0.5
		mesh_instance.mesh.surface_set_material(0, standard_material)

func create_collision():
	# Add collision shape for XRToolsPickable
	var collision = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.15, 0.15, 0.1)  # Hand-sized
	collision.shape = box
	collision.name = "CollisionShape3D"
	add_child(collision)
	move_child(collision, 0)  # Move to first position for XRTools
