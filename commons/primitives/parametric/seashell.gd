# Seashell - Conical spiral parametric surface
# A beautiful spiral shell shape using logarithmic spiral
# Based on natural shell growth patterns

extends XRToolsPickable

@export var u_min: float = 0.0
@export var u_max: float = 12.56  # ~4π for multiple turns
@export var u_steps: int = 96
@export var v_min: float = 0.0
@export var v_max: float = 6.28  # ~2π
@export var v_steps: int = 32
@export var spiral_tightness: float = 0.15
@export var shell_opening: float = 0.1  # Hand-sized scale
@export var base_color: Color = Color(0.95, 0.85, 0.7)  # Shell beige

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

			# Seashell parametric equations (conical spiral)
			# Logarithmic spiral with vertical component
			var radius = shell_opening * exp(u * spiral_tightness)

			# Cross-section is circular, modulated by position along spiral
			var x = radius * (1.0 - v / TAU) * cos(v) * cos(u)
			var y = radius * (1.0 - v / TAU) * cos(v) * sin(u)
			var z = radius * (1.0 - v / TAU) * sin(v)

			# Add some sine wave texture to the surface
			var wave = sin(u * 6.0) * 0.05 * radius
			x += wave * cos(u)
			y += wave * sin(u)

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
		material.set_shader_parameter("wireframeColor", Color(0.8, 0.7, 0.6))
		material.set_shader_parameter("emissionColor", base_color * 0.5)
		material.set_shader_parameter("width", 1.0)
		material.set_shader_parameter("emission_strength", 0.8)
		mesh_instance.material_override = material
	else:
		# Fallback to standard material
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = base_color
		standard_material.metallic = 0.2
		standard_material.roughness = 0.7
		mesh_instance.mesh.surface_set_material(0, standard_material)

func create_collision():
	# Add collision shape for XRToolsPickable
	var collision = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 0.08
	collision.shape = sphere
	collision.name = "CollisionShape3D"
	collision.position = Vector3(0, 0, 0)
	add_child(collision)
	move_child(collision, 0)  # Move to first position for XRTools
