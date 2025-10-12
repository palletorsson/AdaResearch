# ProceduralRock.gd - Procedural rock generator using icosphere + noise
extends MeshInstance3D

@export_group("Rock Generation")
@export var number_of_rocks: int = 1
@export var random_seed: int = 0  # 0 = random seed each time

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

@export_group("Base Shape")
@export var subdivisions: int = 2  # Detail level (0-4 recommended)
@export var base_radius: float = 1.0

@export_group("Settings")
@export var create_on_ready: bool = true
@export var base_color: Color = Color(0.6, 0.6, 0.65)  # Gray stone color

var noise: FastNoiseLite

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
			create_rock()
		else:
			# Additional rocks create new mesh instances
			var new_rock = MeshInstance3D.new()
			add_child(new_rock)
			create_rock_for_instance(new_rock)
			# Offset additional rocks
			new_rock.position = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))

func create_rock():
	create_rock_for_instance(self)

func create_rock_for_instance(mesh_inst: MeshInstance3D):
	# Setup noise for deformation
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi()
	noise.frequency = roughness / 10.0
	noise.fractal_octaves = 4

	# Create base icosphere
	var vertices = []
	var faces = []
	create_icosphere(vertices, faces, subdivisions)

	# Apply deformation using noise
	var deformed_vertices = []
	for vertex in vertices:
		var deform_amount = deformation / 10.0

		# Get noise value for this vertex
		var noise_val = noise.get_noise_3dv(vertex * 5.0)

		# Deform along normal (radial deformation)
		var normal = vertex.normalized()
		var deformed = vertex + normal * noise_val * deform_amount

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

func create_icosphere(vertices: Array, faces: Array, subdivisions_level: int):
	# Create initial icosahedron
	var t = (1.0 + sqrt(5.0)) / 2.0

	# 12 vertices of icosahedron
	vertices.append(Vector3(-1, t, 0).normalized() * base_radius)
	vertices.append(Vector3(1, t, 0).normalized() * base_radius)
	vertices.append(Vector3(-1, -t, 0).normalized() * base_radius)
	vertices.append(Vector3(1, -t, 0).normalized() * base_radius)

	vertices.append(Vector3(0, -1, t).normalized() * base_radius)
	vertices.append(Vector3(0, 1, t).normalized() * base_radius)
	vertices.append(Vector3(0, -1, -t).normalized() * base_radius)
	vertices.append(Vector3(0, 1, -t).normalized() * base_radius)

	vertices.append(Vector3(t, 0, -1).normalized() * base_radius)
	vertices.append(Vector3(t, 0, 1).normalized() * base_radius)
	vertices.append(Vector3(-t, 0, -1).normalized() * base_radius)
	vertices.append(Vector3(-t, 0, 1).normalized() * base_radius)

	# 20 faces of icosahedron
	faces.append([0, 11, 5])
	faces.append([0, 5, 1])
	faces.append([0, 1, 7])
	faces.append([0, 7, 10])
	faces.append([0, 10, 11])

	faces.append([1, 5, 9])
	faces.append([5, 11, 4])
	faces.append([11, 10, 2])
	faces.append([10, 7, 6])
	faces.append([7, 1, 8])

	faces.append([3, 9, 4])
	faces.append([3, 4, 2])
	faces.append([3, 2, 6])
	faces.append([3, 6, 8])
	faces.append([3, 8, 9])

	faces.append([4, 9, 5])
	faces.append([2, 4, 11])
	faces.append([6, 2, 10])
	faces.append([8, 6, 7])
	faces.append([9, 8, 1])

	# Subdivide
	for _i in range(subdivisions_level):
		var new_faces = []
		var midpoint_cache = {}

		for face in faces:
			# Get midpoints of edges
			var a = face[0]
			var b = face[1]
			var c = face[2]

			var ab = get_midpoint(vertices, midpoint_cache, a, b)
			var bc = get_midpoint(vertices, midpoint_cache, b, c)
			var ca = get_midpoint(vertices, midpoint_cache, c, a)

			# Create 4 new triangles
			new_faces.append([a, ab, ca])
			new_faces.append([b, bc, ab])
			new_faces.append([c, ca, bc])
			new_faces.append([ab, bc, ca])

		faces = new_faces

func get_midpoint(vertices: Array, cache: Dictionary, i1: int, i2: int) -> int:
	# Create cache key
	var key = [min(i1, i2), max(i1, i2)]
	var key_str = str(key[0]) + "_" + str(key[1])

	if cache.has(key_str):
		return cache[key_str]

	# Calculate midpoint
	var v1 = vertices[i1]
	var v2 = vertices[i2]
	var mid = ((v1 + v2) / 2.0).normalized() * base_radius

	# Add to vertices and cache
	vertices.append(mid)
	var index = vertices.size() - 1
	cache[key_str] = index

	return index

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
		mesh_inst.mesh.surface_set_material(0, standard_material)

func create_collision():
	# Create parent static body
	var static_body = StaticBody3D.new()
	static_body.name = "ProceduralRockCollision"
	add_child(static_body)

	# Approximate collision with sphere
	var collision = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = base_radius * 1.5  # Account for deformation
	collision.shape = sphere
	collision.position = Vector3(0, 0, 0)
	static_body.add_child(collision)

# Update function for changing parameters
func regenerate():
	generate_rocks()
