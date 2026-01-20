# Torus Knot - Knots that wind around a torus surface
# Parameterized by (p, q) where p = times around torus, q = times through hole
# When p and q are coprime, creates a single connected loop
# Connects to: periodicity, Fourier (p,q as frequency ratios), oscillation

extends XRToolsPickable

@export var t_min: float = 0.0
@export var t_max: float = 6.28  # 2π
@export var t_steps: int = 256  # More steps for complex knots
@export var tube_steps: int = 16
@export var tube_radius: float = 0.08
@export var p: int = 3  # Times around torus (longitudinal winds)
@export var q: int = 7  # Times through hole (meridional winds)
@export var major_radius: float = 1.0  # Distance from center to tube center
@export var minor_radius: float = 0.4  # Tube radius of the torus
@export var knot_scale: float = 0.12
@export var base_color: Color = Color(0.9, 0.7, 0.2)  # Gold

var mesh_instance: MeshInstance3D

func _ready():
	super._ready()
	create_parametric_surface()

# Torus knot parametric curve
func knot_point(t: float) -> Vector3:
	# The curve winds p times around the torus and q times through the hole
	var r = major_radius + minor_radius * cos(q * t)
	var x = r * cos(p * t)
	var y = r * sin(p * t)
	var z = minor_radius * sin(q * t)
	return Vector3(x, y, z)

func knot_tangent(t: float) -> Vector3:
	var dt = 0.001
	var p1 = knot_point(t - dt)
	var p2 = knot_point(t + dt)
	return (p2 - p1).normalized()

func create_parametric_surface():
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var t_step_size = (t_max - t_min) / float(t_steps)
	var angle_step = TAU / float(tube_steps)

	var vertices = []
	for i in range(t_steps + 1):
		var ring = []
		var t = t_min + i * t_step_size

		var center = knot_point(t)
		var tangent = knot_tangent(t)

		# Create perpendicular frame
		var up = Vector3.UP
		if abs(tangent.dot(up)) > 0.9:
			up = Vector3.RIGHT
		var normal = tangent.cross(up).normalized()
		var binormal = tangent.cross(normal).normalized()

		for j in range(tube_steps + 1):
			var angle = j * angle_step
			var offset = normal * cos(angle) + binormal * sin(angle)
			var vertex = (center + offset * tube_radius) * knot_scale
			ring.append(vertex)

		vertices.append(ring)

	# Create faces
	for i in range(t_steps):
		for j in range(tube_steps):
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
		material.set_shader_parameter("emissionColor", base_color * 1.3)
		material.set_shader_parameter("width", 1.0)
		material.set_shader_parameter("emission_strength", 1.5)
		mesh_instance.material_override = material
	else:
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = base_color
		standard_material.metallic = 0.6
		standard_material.roughness = 0.2
		mesh_instance.mesh.surface_set_material(0, standard_material)

func create_collision():
	var collision = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = (major_radius + minor_radius) * knot_scale
	collision.shape = sphere
	collision.name = "CollisionShape3D"
	add_child(collision)
	move_child(collision, 0)
