# Catenoid - A minimal surface (soap film between two rings)
# The shape that minimizes surface area for its boundary
# Parametric form: rotation of a catenary curve (cosh)
# Connects to: energy minimization, equilibrium, natural forms

extends XRToolsPickable

@export var u_min: float = -1.5
@export var u_max: float = 1.5
@export var u_steps: int = 48
@export var v_min: float = 0.0
@export var v_max: float = 6.28  # 2π
@export var v_steps: int = 48
@export var c: float = 0.5  # Waist radius (minimum radius at center)
@export var scale_factor: float = 0.12
@export var base_color: Color = Color(0.4, 0.8, 0.95)  # Light cyan

var mesh_instance: MeshInstance3D

func _ready():
	super._ready()
	create_parametric_surface()

func create_parametric_surface():
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var u_step_size = (u_max - u_min) / float(u_steps)
	var v_step_size = (v_max - v_min) / float(v_steps)

	var vertices = []
	for i in range(u_steps + 1):
		var row = []
		for j in range(v_steps + 1):
			var u = u_min + i * u_step_size
			var v = v_min + j * v_step_size

			# Catenoid parametric equations
			# The catenoid is a rotated catenary (cosh curve)
			# x = c * cosh(u/c) * cos(v)
			# y = c * cosh(u/c) * sin(v)
			# z = u
			var r = c * cosh(u / c)  # Radius at height u
			var x = r * cos(v)
			var y = r * sin(v)
			var z = u

			row.append(Vector3(x, z, y) * scale_factor)  # Reorder for nice orientation
		vertices.append(row)

	# Create faces
	for i in range(u_steps):
		for j in range(v_steps):
			var v0 = vertices[i][j]
			var v1 = vertices[i + 1][j]
			var v2 = vertices[i + 1][j + 1]
			var v3 = vertices[i][j + 1]

			var edge1 = v1 - v0
			var edge2 = v3 - v0
			var normal = edge1.cross(edge2).normalized()

			surface_tool.set_normal(normal)
			surface_tool.add_vertex(v0)
			surface_tool.set_normal(normal)
			surface_tool.add_vertex(v1)
			surface_tool.set_normal(normal)
			surface_tool.add_vertex(v2)

			surface_tool.set_normal(normal)
			surface_tool.add_vertex(v0)
			surface_tool.set_normal(normal)
			surface_tool.add_vertex(v2)
			surface_tool.set_normal(normal)
			surface_tool.add_vertex(v3)

	surface_tool.generate_normals()
	var generated_mesh = surface_tool.commit()

	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = generated_mesh
	add_child(mesh_instance)

	apply_material()
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
		material.set_shader_parameter("emissionColor", base_color * 1.1)
		material.set_shader_parameter("width", 1.0)
		material.set_shader_parameter("emission_strength", 1.3)
		material.set_shader_parameter("show_interior", true)
		mesh_instance.material_override = material
	else:
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = base_color
		standard_material.metallic = 0.2
		standard_material.roughness = 0.6
		standard_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh_instance.mesh.surface_set_material(0, standard_material)

func create_collision():
	var collision = CollisionShape3D.new()
	var cylinder = CylinderShape3D.new()
	cylinder.radius = c * cosh(u_max / c) * scale_factor
	cylinder.height = (u_max - u_min) * scale_factor
	collision.shape = cylinder
	collision.name = "CollisionShape3D"
	add_child(collision)
	move_child(collision, 0)
