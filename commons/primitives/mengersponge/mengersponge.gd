# MengerSponge.gd - Menger Sponge fractal shape
extends Node3D

@export var level: int = 3  # Fractal depth (0-4 recommended, higher is very slow)
@export var size: float = 1.0  # Base size of the sponge
@export var create_on_ready: bool = true
@export var base_color: Color = Color(0.7, 0.7, 0.7)  # Gray

var mesh_instance: MeshInstance3D

func _ready():
	if create_on_ready:
		create_menger_sponge()

func create_menger_sponge():
	# Clear existing mesh if any
	if mesh_instance:
		mesh_instance.queue_free()

	# Create the fractal
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Generate the Menger Sponge recursively
	generate_menger(surface_tool, Vector3.ZERO, size, level)

	# Finalize mesh
	surface_tool.generate_normals()

	# Create new mesh instance
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = surface_tool.commit()
	mesh_instance.name = "MengerSpongeMesh"
	add_child(mesh_instance)

	# Apply material
	apply_queer_material(mesh_instance, base_color)

	# Add collision (approximate with box)
	create_collision()

	print("Menger Sponge generated at level %d" % level)

func generate_menger(surface_tool: SurfaceTool, center: Vector3, cube_size: float, depth: int):
	if depth == 0:
		# Base case: draw a cube
		add_cube(surface_tool, center, cube_size)
		return

	# Recursive case: subdivide into 3x3x3 = 27 sub-cubes
	var new_size = cube_size / 3.0
	var offset = new_size

	for x in range(3):
		for y in range(3):
			for z in range(3):
				# Skip the center cross pattern (7 cubes removed per face)
				# Remove if center of any face or center of cube
				var x_center = (x == 1)
				var y_center = (y == 1)
				var z_center = (z == 1)

				# Count how many axes are centered
				var centered_count = int(x_center) + int(y_center) + int(z_center)

				# Remove cubes where 2 or more axes are centered
				# This creates the characteristic Menger Sponge pattern
				if centered_count >= 2:
					continue

				# Calculate position of this sub-cube
				var pos = center + Vector3(
					(x - 1) * offset,
					(y - 1) * offset,
					(z - 1) * offset
				)

				# Recursively generate this sub-cube
				generate_menger(surface_tool, pos, new_size, depth - 1)

func add_cube(surface_tool: SurfaceTool, center: Vector3, cube_size: float):
	var half_size = cube_size / 2.0

	# Define 8 vertices of the cube
	var vertices = [
		center + Vector3(-half_size, -half_size, -half_size),  # 0
		center + Vector3(half_size, -half_size, -half_size),   # 1
		center + Vector3(half_size, -half_size, half_size),    # 2
		center + Vector3(-half_size, -half_size, half_size),   # 3
		center + Vector3(-half_size, half_size, -half_size),   # 4
		center + Vector3(half_size, half_size, -half_size),    # 5
		center + Vector3(half_size, half_size, half_size),     # 6
		center + Vector3(-half_size, half_size, half_size)     # 7
	]

	# Define the 6 faces (each as 2 triangles)
	var faces = [
		# Bottom face (Y-)
		[0, 2, 1], [0, 3, 2],
		# Top face (Y+)
		[4, 5, 6], [4, 6, 7],
		# Front face (Z+)
		[3, 6, 2], [3, 7, 6],
		# Back face (Z-)
		[0, 1, 5], [0, 5, 4],
		# Right face (X+)
		[1, 2, 6], [1, 6, 5],
		# Left face (X-)
		[0, 4, 7], [0, 7, 3]
	]

	# Add each face
	for face in faces:
		var v0 = vertices[face[0]]
		var v1 = vertices[face[1]]
		var v2 = vertices[face[2]]

		# Calculate normal
		var normal = (v1 - v0).cross(v2 - v0).normalized()

		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v0)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v1)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v2)

func create_collision():
	var static_body = StaticBody3D.new()
	static_body.name = "MengerSpongeCollision"
	add_child(static_body)

	# Approximate collision with box (full outer bounds)
	var collision = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(size, size, size)
	collision.shape = box
	collision.position = Vector3(0, 0, 0)
	static_body.add_child(collision)

func apply_queer_material(mesh_inst: MeshInstance3D, color: Color):
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		material.set_shader_parameter("base_color", color)
		material.set_shader_parameter("edge_color", Color.WHITE)
		material.set_shader_parameter("edge_width", 1.5)
		material.set_shader_parameter("edge_sharpness", 2.0)
		material.set_shader_parameter("emission_strength", 1.0)
		mesh_inst.material_override = material
	else:
		# Fallback to standard material
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = color
		standard_material.metallic = 0.0
		standard_material.roughness = 0.8
		mesh_inst.mesh.surface_set_material(0, standard_material)
