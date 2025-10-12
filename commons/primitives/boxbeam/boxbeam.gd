# BoxBeam.gd - Hollow rectangular beam/tube
extends MeshInstance3D

@export_group("Box Profile Dimensions")
@export var height: float = 1.0  # Length of the beam (Y axis)
@export var width: float = 0.50  # Width (X axis)
@export var depth: float = 2.0   # Depth (Z axis)
@export var thickness: float = 0.10  # Wall thickness

@export_group("Settings")
@export var create_on_ready: bool = true
@export var base_color: Color = Color(0.7, 0.7, 0.75)  # Light gray-blue

func _ready():
	if create_on_ready:
		create_beam()

func create_beam() -> void:
	rotation = Vector3.ZERO
	scale = Vector3.ONE
	# Base vertices from Blender (normalized to unit dimensions)
	var base_vertices = [
		Vector3(0.25, 1.0, 0.5),
		Vector3(-0.25, 1.0, 0.5),
		Vector3(-0.25, 1.0, -0.5),
		Vector3(0.25, 1.0, -0.5),
		Vector3(0.15, 1.0, 0.4),
		Vector3(-0.15, 1.0, 0.4),
		Vector3(-0.15, 1.0, -0.4),
		Vector3(0.15, 1.0, -0.4),
		Vector3(0.25, -1.0, 0.5),
		Vector3(-0.25, -1.0, 0.5),
		Vector3(-0.25, -1.0, -0.5),
		Vector3(0.25, -1.0, -0.5),
		Vector3(0.15, -1.0, 0.4),
		Vector3(-0.15, -1.0, 0.4),
		Vector3(-0.15, -1.0, -0.4),
		Vector3(0.15, -1.0, -0.4)
	]

	# Face definitions from Blender
	var faces = [
		[0, 1, 5, 4],
		[1, 2, 6, 5],
		[2, 3, 7, 6],
		[3, 0, 4, 7],
		[8, 9, 13, 12],
		[9, 10, 14, 13],
		[10, 11, 15, 14],
		[11, 8, 12, 15],
		[0, 1, 9, 8],
		[1, 2, 10, 9],
		[2, 3, 11, 10],
		[3, 0, 8, 11],
		[4, 5, 13, 12],
		[5, 6, 14, 13],
		[6, 7, 15, 14],
		[7, 4, 12, 15]
	]

	# Scale vertices based on parameters
	# The base model uses: width=0.5, height=2.0, depth=1.0, thickness=0.1
	var base_width = 0.5
	var base_height = 2.0
	var base_depth = 1.0
	var base_thickness = 0.1

	# Calculate inner dimensions based on thickness
	var outer_width = width
	var outer_depth = depth
	var inner_width = max(0.01, outer_width - thickness * 2.0)
	var inner_depth = max(0.01, outer_depth - thickness * 2.0)

	var scaled_vertices = []
	for v in base_vertices:
		var scaled_v = Vector3.ZERO

		# Scale X (width) - outer vs inner
		if abs(v.x) > 0.2:  # Outer wall
			scaled_v.x = sign(v.x) * outer_width / 2.0
		else:  # Inner wall
			scaled_v.x = sign(v.x) * inner_width / 2.0

		# Scale Y (height/length)
		scaled_v.y = v.y * height / 2.0

		# Scale Z (depth) - outer vs inner
		if abs(v.z) > 0.45:  # Outer wall
			scaled_v.z = sign(v.z) * outer_depth / 2.0
		else:  # Inner wall
			scaled_v.z = sign(v.z) * inner_depth / 2.0

		scaled_vertices.append(scaled_v)

	# Create mesh using SurfaceTool
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Convert quads to triangles
	for face in faces:
		var v0 = scaled_vertices[face[0]]
		var v1 = scaled_vertices[face[1]]
		var v2 = scaled_vertices[face[2]]
		var v3 = scaled_vertices[face[3]]

		# Calculate normal
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

	# Generate normals and create mesh
	surface_tool.generate_normals()
	mesh = surface_tool.commit()

	# Apply material
	apply_queer_material()

	# Rotate to align along +X
	rotate_z(deg_to_rad(90.0))

	# Add collision
	var collision_body := create_collision()
	if collision_body:
		collision_body.rotate_z(deg_to_rad(90.0))

	print("Beam created: Height=%.2f, Width=%.2f, Depth=%.2f, Thickness=%.2f" % [height, width, depth, thickness])

func apply_queer_material():
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		material.set_shader_parameter("base_color", base_color)
		material.set_shader_parameter("edge_color", Color.WHITE)
		material.set_shader_parameter("edge_width", 1.5)
		material.set_shader_parameter("edge_sharpness", 2.0)
		material.set_shader_parameter("emission_strength", 1.0)
		material_override = material
	else:
		# Fallback to standard material
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = base_color
		standard_material.metallic = 0.4
		standard_material.roughness = 0.5
		mesh.surface_set_material(0, standard_material)

func create_collision() -> StaticBody3D:
	# Create parent static body
	var static_body = StaticBody3D.new()
	static_body.name = "BoxBeamCollision"
	add_child(static_body)

	# Approximate collision with box (outer dimensions)
	var collision = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(width, height, depth)
	collision.shape = box
	collision.position = Vector3(0, 0, 0)
	static_body.add_child(collision)

	return static_body

# Optional: Update mesh when parameters change in editor
func _process(_delta):
	if Engine.is_editor_hint() and mesh != null:
		# Only recreate if in editor (for live updates)
		pass

# Call this to update the beam with new parameters
func update_beam():
	create_beam()
