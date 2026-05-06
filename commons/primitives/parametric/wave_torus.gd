# Wave Torus - Sine wave modulated torus
# A torus with sinusoidal waves on its surface
# Creates interesting wave patterns around the ring

extends XRToolsPickable

@export var u_min: float = 0.0
@export var u_max: float = 6.28  # ~2π
@export var u_steps: int = 64
@export var v_min: float = 0.0
@export var v_max: float = 6.28  # ~2π
@export var v_steps: int = 32
@export var major_radius: float = 0.15  # Hand-sized scale
@export var minor_radius: float = 0.05  # Hand-sized tube radius
@export var wave_amplitude: float = 0.02  # Hand-sized waves
@export var wave_frequency_u: float = 8.0  # Waves along the major circle
@export var wave_frequency_v: float = 5.0  # Waves around the tube
@export var base_color: Color = Color(0.3, 0.9, 0.5)  # Green

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

			# Wave modulation - combines two sine waves
			var wave_u = sin(u * wave_frequency_u) * wave_amplitude
			var wave_v = sin(v * wave_frequency_v) * wave_amplitude * 0.5
			var wave_combined = sin(u * wave_frequency_u + v * wave_frequency_v) * wave_amplitude * 0.3

			# Total wave effect
			var wave_offset = wave_u + wave_v + wave_combined

			# Modified minor radius with wave
			var r_minor = minor_radius + wave_offset

			# Torus parametric equations with wave modulation
			var x = (major_radius + r_minor * cos(v)) * cos(u)
			var y = r_minor * sin(v)
			var z = (major_radius + r_minor * cos(v)) * sin(u)

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
		material.set_shader_parameter("wireframeColor", Color.WHITE)
		material.set_shader_parameter("emissionColor", base_color * 1.5)
		material.set_shader_parameter("width", 1.0)
		material.set_shader_parameter("emission_strength", 2.0)
		mesh_instance.material_override = material
	else:
		# Fallback to standard material
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = base_color
		standard_material.metallic = 0.4
		standard_material.roughness = 0.4
		mesh_instance.mesh.surface_set_material(0, standard_material)

func create_collision():
	# Add collision shape for XRToolsPickable
	var collision = CollisionShape3D.new()
	var cylinder = CylinderShape3D.new()
	cylinder.radius = major_radius + minor_radius
	cylinder.height = minor_radius * 2.5
	collision.shape = cylinder
	collision.name = "CollisionShape3D"
	collision.rotation_degrees = Vector3(90, 0, 0)
	add_child(collision)
	move_child(collision, 0)  # Move to first position for XRTools
