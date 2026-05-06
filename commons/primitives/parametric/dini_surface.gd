# Dini's Surface - Surface of constant negative curvature
# A twisted pseudosphere discovered by Ulisse Dini in 1868
# Created by taking a tractrix and rotating it while moving it along the z-axis
# Has constant negative Gaussian curvature everywhere

extends XRToolsPickable

@export var u_min: float = 0.0
@export var u_max: float = 12.56  # ~4π for multiple helical turns
@export var u_steps: int = 96
@export var v_min: float = 0.1  # Avoid v=0 (singularity in ln(tan(v/2)))
@export var v_max: float = 2.0  # Stay away from π/2 to avoid singularity
@export var v_steps: int = 48
@export var a: float = 1.0  # Radius parameter
@export var b: float = 0.2  # Helical pitch parameter (controls twist rate)
@export var scale_factor: float = 0.1  # Hand-sized scale
@export var base_color: Color = Color(0.9, 0.6, 0.2)  # Orange-gold

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

			# Dini's Surface parametric equations
			# x = a * cos(u) * sin(v)
			# y = a * sin(u) * sin(v)
			# z = a * (cos(v) + ln(tan(v/2))) + b * u

			var x = a * cos(u) * sin(v)
			var y = a * sin(u) * sin(v)

			# Calculate z with the tractrix profile plus helical twist
			# ln(tan(v/2)) is the tractrix function
			var tractrix = log(tan(v / 2.0))
			var z = a * (cos(v) + tractrix) + b * u

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
		material.set_shader_parameter("emissionColor", base_color * 1.3)
		material.set_shader_parameter("width", 1.0)
		material.set_shader_parameter("emission_strength", 1.6)
		material.set_shader_parameter("show_interior", true)
		mesh_instance.material_override = material
	else:
		# Fallback to standard material
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = base_color
		standard_material.metallic = 0.4
		standard_material.roughness = 0.4
		standard_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Show both sides
		mesh_instance.mesh.surface_set_material(0, standard_material)

func create_collision():
	# Add collision shape for XRToolsPickable
	var collision = CollisionShape3D.new()
	var cylinder = CylinderShape3D.new()
	cylinder.radius = a * 1.5 * scale_factor
	cylinder.height = (b * u_max + a * 2.0) * scale_factor
	collision.shape = cylinder
	collision.name = "CollisionShape3D"
	collision.position = Vector3(0, cylinder.height * 0.25, 0)
	add_child(collision)
	move_child(collision, 0)  # Move to first position for XRTools
