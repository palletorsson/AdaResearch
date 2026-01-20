# Breather Surface - A soliton solution to the sine-Gordon equation
# Named for its "breathing" motion when animated
# Shows how nonlinear waves maintain their shape (particle-like behavior)
# Connects to: wave propagation, Fourier, oscillation, edge of chaos

extends XRToolsPickable

@export var u_min: float = -14.0
@export var u_max: float = 14.0
@export var u_steps: int = 80
@export var v_min: float = -37.0
@export var v_max: float = 37.0
@export var v_steps: int = 80
@export var aa: float = 0.4  # Breather parameter (0 < aa < 1)
@export var scale_factor: float = 0.015
@export var base_color: Color = Color(0.95, 0.5, 0.2)  # Orange

var mesh_instance: MeshInstance3D

func _ready():
	super._ready()
	create_parametric_surface()

func create_parametric_surface():
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var u_step_size = (u_max - u_min) / float(u_steps)
	var v_step_size = (v_max - v_min) / float(v_steps)

	# Precompute constants
	var w = sqrt(1.0 - aa * aa)

	var vertices = []
	for i in range(u_steps + 1):
		var row = []
		for j in range(v_steps + 1):
			var u = u_min + i * u_step_size
			var v = v_min + j * v_step_size

			# Breather surface parametric equations
			# These are solutions to the sine-Gordon equation
			var denom = aa * (pow(w * cosh(aa * u), 2) + pow(aa * sin(w * v), 2))

			# Avoid division by zero
			if abs(denom) < 0.0001:
				denom = 0.0001

			var x = -u + (2.0 * (1.0 - aa * aa) * cosh(aa * u) * sinh(aa * u)) / denom
			var y = (2.0 * w * cosh(aa * u) * (-(w * cos(v) * cos(w * v)) - sin(v) * sin(w * v))) / denom
			var z = (2.0 * w * cosh(aa * u) * (-(w * sin(v) * cos(w * v)) + cos(v) * sin(w * v))) / denom

			row.append(Vector3(x, y, z) * scale_factor)
		vertices.append(row)

	# Create faces
	for i in range(u_steps):
		for j in range(v_steps):
			var v0 = vertices[i][j]
			var v1 = vertices[i + 1][j]
			var v2 = vertices[i + 1][j + 1]
			var v3 = vertices[i][j + 1]

			# Skip degenerate triangles
			if v0.distance_to(v1) < 0.0001 or v1.distance_to(v2) < 0.0001:
				continue

			var edge1 = v1 - v0
			var edge2 = v3 - v0
			var normal = edge1.cross(edge2)
			if normal.length() > 0.0001:
				normal = normal.normalized()
			else:
				normal = Vector3.UP

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
		material.set_shader_parameter("emissionColor", base_color * 1.3)
		material.set_shader_parameter("width", 1.0)
		material.set_shader_parameter("emission_strength", 1.6)
		material.set_shader_parameter("show_interior", true)
		mesh_instance.material_override = material
	else:
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = base_color
		standard_material.metallic = 0.4
		standard_material.roughness = 0.3
		standard_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh_instance.mesh.surface_set_material(0, standard_material)

func create_collision():
	var collision = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.2, 0.15, 0.15)
	collision.shape = box
	collision.name = "CollisionShape3D"
	add_child(collision)
	move_child(collision, 0)
