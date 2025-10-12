# HollowRock.gd - Hollow rock generator using torus + noise deformation
extends MeshInstance3D

@export_group("Rock Generation")
@export var number_of_rocks: int = 1
@export var random_seed: int = 0  # 0 = random seed each time

@export_group("Torus Shape")
@export var major_radius: float = 1.0  # Main ring radius
@export var minor_radius: float = 0.4  # Tube thickness
@export var major_segments: int = 32   # Segments around the ring
@export var minor_segments: int = 16   # Segments around the tube

@export_group("Scale")
@export var x_scale: Vector2 = Vector2(1.0, 1.0)  # min, max
@export var x_skew: float = 0.0
@export var y_scale: Vector2 = Vector2(1.0, 1.0)
@export var y_skew: float = 0.0
@export var z_scale: Vector2 = Vector2(1.0, 1.0)
@export var z_skew: float = 0.0

@export_group("Deformation")
@export var deformation: float = 5.27  # Amount of random deformation
@export var roughness: float = 2.50   # Surface roughness/detail
@export var hollow_variation: float = 0.3  # How much the hole size varies

@export_group("Settings")
@export var create_on_ready: bool = true
@export var base_color: Color = Color(0.6, 0.55, 0.5)  # Stone color

var noise: FastNoiseLite
var noise2: FastNoiseLite

func _ready():
	if create_on_ready:
		generate_rocks()

func generate_rocks():
	# Set up random seed
	if random_seed != 0:
		seed(random_seed)
	else:
		randomize()

	# Clear existing children
	for child in get_children():
		child.queue_free()

	# Generate multiple rocks if requested
	for i in range(number_of_rocks):
		if i == 0:
			# First rock uses this mesh instance
			create_hollow_rock()
		else:
			# Additional rocks create new mesh instances
			var new_rock = MeshInstance3D.new()
			add_child(new_rock)
			create_hollow_rock_for_instance(new_rock)
			# Offset additional rocks
			new_rock.position = Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))

func create_hollow_rock():
	create_hollow_rock_for_instance(self)

func create_hollow_rock_for_instance(mesh_inst: MeshInstance3D):
	# Setup noise for deformation
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi()
	noise.frequency = roughness / 10.0
	noise.fractal_octaves = 4

	# Second noise for hole variation
	noise2 = FastNoiseLite.new()
	noise2.noise_type = FastNoiseLite.TYPE_PERLIN
	noise2.seed = randi()
	noise2.frequency = 0.5

	# Create base torus
	var vertices = []
	var faces = []
	create_torus(vertices, faces)

	# Apply deformation using noise
	var deformed_vertices = []
	for vertex in vertices:
		var deform_amount = deformation / 10.0

		# Get noise value for this vertex
		var noise_val = noise.get_noise_3dv(vertex * 5.0)

		# Additional noise for varying the hole size
		var hole_noise = noise2.get_noise_3dv(vertex * 2.0) * hollow_variation

		# Calculate direction from torus center
		var xz_pos = Vector2(vertex.x, vertex.z)
		var ring_radius = xz_pos.length()

		# Deform radially and add surface bumps
		var radial_dir = Vector3(vertex.x, 0, vertex.z).normalized()
		var surface_normal = vertex.normalized()

		# Vary the hole size
		var hole_scale = 1.0 + hole_noise

		var deformed = vertex
		deformed += surface_normal * noise_val * deform_amount

		# Apply hole variation
		if ring_radius > 0.01:
			var from_center = vertex - radial_dir * major_radius
			deformed = radial_dir * major_radius + from_center * hole_scale
			deformed += surface_normal * noise_val * deform_amount

		# Apply scaling with random variation
		var scale_x = randf_range(x_scale.x, x_scale.y) + randf_range(-x_skew, x_skew)
		var scale_y = randf_range(y_scale.x, y_scale.y) + randf_range(-y_skew, y_skew)
		var scale_z = randf_range(z_scale.x, z_scale.y) + randf_range(-z_skew, z_skew)

		deformed.x *= scale_x
		deformed.y *= scale_y
		deformed.z *= scale_z

		deformed_vertices.append(deformed)

	# Create mesh
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Add all triangles
	for face in faces:
		var v0 = deformed_vertices[face[0]]
		var v1 = deformed_vertices[face[1]]
		var v2 = deformed_vertices[face[2]]

		# Calculate normal
		var edge1 = v1 - v0
		var edge2 = v2 - v0
		var normal = edge1.cross(edge2).normalized()

		# Add vertices
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v0)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v1)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v2)

	# Generate smooth normals
	surface_tool.generate_normals()
	mesh_inst.mesh = surface_tool.commit()

	# Apply material
	apply_queer_material(mesh_inst)

	# Add collision for first rock only
	if mesh_inst == self:
		create_collision()

func create_torus(vertices: Array, faces: Array):
	# Generate torus vertices
	for i in range(major_segments):
		var u = (float(i) / major_segments) * TAU

		for j in range(minor_segments):
			var v = (float(j) / minor_segments) * TAU

			# Torus parametric equations
			var x = (major_radius + minor_radius * cos(v)) * cos(u)
			var y = minor_radius * sin(v)
			var z = (major_radius + minor_radius * cos(v)) * sin(u)

			vertices.append(Vector3(x, y, z))

	# Generate faces (quads split into triangles)
	for i in range(major_segments):
		for j in range(minor_segments):
			# Calculate vertex indices
			var v0 = i * minor_segments + j
			var v1 = ((i + 1) % major_segments) * minor_segments + j
			var v2 = ((i + 1) % major_segments) * minor_segments + ((j + 1) % minor_segments)
			var v3 = i * minor_segments + ((j + 1) % minor_segments)

			# Two triangles per quad
			faces.append([v0, v1, v2])
			faces.append([v0, v2, v3])

func apply_queer_material(mesh_inst: MeshInstance3D):
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		material.set_shader_parameter("base_color", base_color)
		material.set_shader_parameter("edge_color", Color.WHITE)
		material.set_shader_parameter("edge_width", 1.5)
		material.set_shader_parameter("edge_sharpness", 2.0)
		material.set_shader_parameter("emission_strength", 1.0)
		mesh_inst.material_override = material
	else:
		# Fallback to standard material
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = base_color
		standard_material.roughness = 0.9
		standard_material.metallic = 0.0
		standard_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Show both sides for hollow
		mesh_inst.mesh.surface_set_material(0, standard_material)

func create_collision():
	# Create parent static body
	var static_body = StaticBody3D.new()
	static_body.name = "HollowRockCollision"
	add_child(static_body)

	# Approximate collision with torus-shaped compound
	# Use a cylinder for outer shape
	var collision = CollisionShape3D.new()
	var cylinder = CylinderShape3D.new()
	cylinder.radius = major_radius + minor_radius
	cylinder.height = minor_radius * 2.0
	collision.shape = cylinder
	collision.position = Vector3(0, 0, 0)
	collision.rotation_degrees = Vector3(90, 0, 0)
	static_body.add_child(collision)

# Update function for changing parameters
func regenerate():
	generate_rocks()
