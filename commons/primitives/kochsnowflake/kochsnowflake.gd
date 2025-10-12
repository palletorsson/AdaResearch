# KochSnowflake.gd - Koch snowflake fractal with configurable depth
extends MeshInstance3D

@export_group("Koch Snowflake Parameters")
@export var depth: int = 3  # Recursion depth
@export var size: float = 1.0  # Base size
@export var line_width: float = 0.02  # Line thickness

@export_group("Settings")
@export var create_on_ready: bool = true
@export var base_color: Color = Color(0.9, 0.9, 1.0)  # Light blue/white

var vertices: Array[Vector3] = []

func _ready():
	if create_on_ready:
		create_snowflake()

func create_snowflake():
	vertices.clear()

	# Create initial equilateral triangle vertices
	var v1 = Vector3(0, 0, 0)
	var v2 = Vector3(size, 0, 0)
	var v3 = Vector3(size * 0.5, size * sqrt(3.0) / 2.0, 0)

	# Generate koch curve for each side of the triangle
	koch_iteration(v1, v2, depth)
	koch_iteration(v2, v3, depth)
	koch_iteration(v3, v1, depth)

	# Create the mesh
	create_line_mesh()
	apply_material()

	print("Koch Snowflake created: depth=%d, size=%.2f, segments=%d" % [depth, size, vertices.size() / 2])

func koch_iteration(v1: Vector3, v2: Vector3, current_depth: int):
	if current_depth == 0:
		# Base case: add the line segment
		vertices.append(v1)
		vertices.append(v2)
	else:
		# Calculate intermediate points
		var delta = v2 - v1

		# Point 1/3 along the line
		var v3 = v1 + delta / 3.0

		# Point 2/3 along the line
		var v5 = v1 + delta * 2.0 / 3.0

		# Point forming the peak of the equilateral triangle
		# Rotate the segment by 60 degrees outward
		var midpoint = v1 + delta / 2.0
		var perpendicular = Vector3(-delta.y, delta.x, 0).normalized()
		var height = delta.length() * sqrt(3.0) / 6.0
		var v4 = v3 + (v5 - v3) / 2.0 + perpendicular * height

		# Recursively subdivide the four segments
		koch_iteration(v1, v3, current_depth - 1)
		koch_iteration(v3, v4, current_depth - 1)
		koch_iteration(v4, v5, current_depth - 1)
		koch_iteration(v5, v2, current_depth - 1)

func create_line_mesh():
	var immediate_mesh = ImmediateMesh.new()

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for i in range(0, vertices.size(), 2):
		if i + 1 < vertices.size():
			immediate_mesh.surface_add_vertex(vertices[i])
			immediate_mesh.surface_add_vertex(vertices[i + 1])

	immediate_mesh.surface_end()

	mesh = immediate_mesh

func apply_material():
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = base_color
	material.emission_enabled = true
	material.emission = base_color
	material.emission_energy_multiplier = 1.5

	# Set line width if supported
	material.render_priority = 1

	set_surface_override_material(0, material)

func update_snowflake():
	create_snowflake()
