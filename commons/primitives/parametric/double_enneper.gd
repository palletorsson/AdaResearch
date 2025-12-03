# Double Enneper Surface - Minimal surface with self-intersections
# The Enneper surface is a classic minimal surface discovered in 1864
# "Double" version uses extended parameter range for more dramatic form
# Famous for its saddle-like shape with beautiful symmetric curves

extends XRToolsPickable

@export var u_min: float = -2.0
@export var u_max: float = 2.0
@export var u_steps: int = 64
@export var v_min: float = -2.0
@export var v_max: float = 2.0
@export var v_steps: int = 64
@export var scale_factor: float = 0.1  # Hand-sized scale
@export var base_color: Color = Color(0.8, 0.4, 0.9)  # Purple

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

			# Enneper surface parametric equations
			# These are the classic Weierstrass parametrization formulas
			var u2 = u * u
			var u3 = u2 * u
			var v2 = v * v
			var v3 = v2 * v

			var x = u - (u3 / 3.0) + u * v2
			var y = v - (v3 / 3.0) + v * u2
			var z = u2 - v2

			row.append(Vector3(x, y, z) * scale_factor)
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
		material.set_shader_parameter("emissionColor", base_color * 1.2)
		material.set_shader_parameter("width", 1.0)
		material.set_shader_parameter("emission_strength", 1.8)
		material.set_shader_parameter("show_interior", true)
		mesh_instance.material_override = material
	else:
		# Fallback to standard material
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = base_color
		standard_material.metallic = 0.5
		standard_material.roughness = 0.3
		standard_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Show both sides
		mesh_instance.mesh.surface_set_material(0, standard_material)

func create_collision():
	# Add collision shape for XRToolsPickable
	var collision = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(4.0, 2.0, 4.0) * scale_factor
	collision.shape = box
	collision.name = "CollisionShape3D"
	collision.position = Vector3(0, 0, 0)
	add_child(collision)
	move_child(collision, 0)  # Move to first position for XRTools
