# Figure-Eight Knot (4_1 knot) - Second simplest knot after trefoil
# Also called the Flemish knot or Savoy knot
# Has the same knot group whether tied left or right-handed (amphichiral)
# Connects to: topology, symmetry, oscillation in 3D space

extends XRToolsPickable

@export var t_min: float = 0.0
@export var t_max: float = 6.28  # 2π
@export var t_steps: int = 128
@export var tube_steps: int = 16
@export var tube_radius: float = 0.12
@export var knot_scale: float = 0.1
@export var base_color: Color = Color(0.3, 0.5, 0.9)  # Blue

var mesh_instance: MeshInstance3D

func _ready():
	super._ready()
	create_parametric_surface()

# Figure-eight knot parametric curve
func knot_point(t: float) -> Vector3:
	# Classic figure-eight parameterization
	var x = (2.0 + cos(2.0 * t)) * cos(3.0 * t)
	var y = (2.0 + cos(2.0 * t)) * sin(3.0 * t)
	var z = sin(4.0 * t)
	return Vector3(x, y, z)

func knot_tangent(t: float) -> Vector3:
	# Numerical derivative
	var dt = 0.001
	var p1 = knot_point(t - dt)
	var p2 = knot_point(t + dt)
	return (p2 - p1).normalized()

func create_parametric_surface():
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var t_step_size = (t_max - t_min) / float(t_steps)
	var angle_step = TAU / float(tube_steps)

	# Parallel transport frame to avoid twist artifacts
	var first_tangent = knot_tangent(t_min)
	var up = Vector3.UP
	if abs(first_tangent.dot(up)) > 0.9:
		up = Vector3.RIGHT
	var prev_normal = first_tangent.cross(up).normalized()
	var prev_binormal = first_tangent.cross(prev_normal).normalized()

	var vertices = []
	for i in range(t_steps + 1):
		var ring = []
		var t = t_min + i * t_step_size

		var center = knot_point(t)
		var tangent = knot_tangent(t)

		# Parallel transport: project previous normal onto new perpendicular plane
		var cur_normal: Vector3
		var cur_binormal: Vector3
		if i == 0:
			cur_normal = prev_normal
			cur_binormal = prev_binormal
		else:
			cur_normal = (prev_normal - tangent * prev_normal.dot(tangent)).normalized()
			cur_binormal = tangent.cross(cur_normal).normalized()
		prev_normal = cur_normal
		prev_binormal = cur_binormal

		for j in range(tube_steps + 1):
			var angle = j * angle_step
			var offset = cur_normal * cos(angle) + cur_binormal * sin(angle)
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
		material.set_shader_parameter("emissionColor", base_color * 1.2)
		material.set_shader_parameter("width", 1.0)
		material.set_shader_parameter("emission_strength", 1.4)
		mesh_instance.material_override = material
	else:
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = base_color
		standard_material.metallic = 0.5
		standard_material.roughness = 0.3
		mesh_instance.mesh.surface_set_material(0, standard_material)

func create_collision():
	var collision = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 0.15
	collision.shape = sphere
	collision.name = "CollisionShape3D"
	add_child(collision)
	move_child(collision, 0)
