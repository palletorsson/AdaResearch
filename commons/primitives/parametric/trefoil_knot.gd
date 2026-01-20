# Trefoil Knot - The simplest non-trivial knot
# A curve that cannot be untangled without cutting
# Parametric tube around the trefoil curve
# Demonstrates topology: closed loops that resist simplification

extends XRToolsPickable

@export var t_min: float = 0.0
@export var t_max: float = 6.28  # 2π for one complete loop
@export var t_steps: int = 128  # More steps for smooth curve
@export var tube_steps: int = 16  # Cross-section resolution
@export var tube_radius: float = 0.15  # Tube thickness
@export var knot_scale: float = 0.08  # Overall size
@export var base_color: Color = Color(0.9, 0.3, 0.5)  # Magenta-pink

var mesh_instance: MeshInstance3D

func _ready():
	super._ready()
	create_parametric_surface()

# Trefoil knot parametric curve
func trefoil_point(t: float) -> Vector3:
	# Classic trefoil: winds 2 times around one axis while 3 times around another
	var x = sin(t) + 2.0 * sin(2.0 * t)
	var y = cos(t) - 2.0 * cos(2.0 * t)
	var z = -sin(3.0 * t)
	return Vector3(x, y, z)

# Derivative for tangent calculation
func trefoil_tangent(t: float) -> Vector3:
	var x = cos(t) + 4.0 * cos(2.0 * t)
	var y = -sin(t) + 4.0 * sin(2.0 * t)
	var z = -3.0 * cos(3.0 * t)
	return Vector3(x, y, z).normalized()

func create_parametric_surface():
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var t_step_size = (t_max - t_min) / float(t_steps)
	var angle_step = TAU / float(tube_steps)

	# Generate tube around the trefoil curve
	var vertices = []
	for i in range(t_steps + 1):
		var ring = []
		var t = t_min + i * t_step_size

		# Get point and tangent on the trefoil
		var center = trefoil_point(t)
		var tangent = trefoil_tangent(t)

		# Create perpendicular vectors for the tube cross-section
		# Use Frenet-Serret frame approximation
		var up = Vector3.UP
		if abs(tangent.dot(up)) > 0.9:
			up = Vector3.RIGHT
		var normal = tangent.cross(up).normalized()
		var binormal = tangent.cross(normal).normalized()

		# Generate ring of vertices around this point
		for j in range(tube_steps + 1):
			var angle = j * angle_step
			var offset = normal * cos(angle) + binormal * sin(angle)
			var vertex = (center + offset * tube_radius) * knot_scale
			ring.append(vertex)

		vertices.append(ring)

	# Create faces connecting rings
	for i in range(t_steps):
		for j in range(tube_steps):
			var v0 = vertices[i][j]
			var v1 = vertices[i + 1][j]
			var v2 = vertices[i + 1][j + 1]
			var v3 = vertices[i][j + 1]

			var edge1 = v1 - v0
			var edge2 = v3 - v0
			var normal = edge1.cross(edge2).normalized()

			# First triangle
			surface_tool.set_normal(normal)
			surface_tool.add_vertex(v0)
			surface_tool.set_normal(normal)
			surface_tool.add_vertex(v1)
			surface_tool.set_normal(normal)
			surface_tool.add_vertex(v2)

			# Second triangle
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
	sphere.radius = 0.12
	collision.shape = sphere
	collision.name = "CollisionShape3D"
	add_child(collision)
	move_child(collision, 0)
