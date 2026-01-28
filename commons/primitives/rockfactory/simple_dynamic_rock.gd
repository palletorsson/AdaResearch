# SimpleDynamicRock.gd - Irregular rock from deformed low-poly sphere
extends RigidBody3D

@export var rock_seed: int = 0
@export var wiggle_amount: float = 0.15
@export var rock_radius: float = 0.25
@export var rings: int = 3
@export var radial_segments: int = 4
@export var rock_color: Color = Color(0.6, 0.6, 0.65)

func _ready():
	generate_rock()
	add_random_rotation()

func add_random_rotation():
	"""Add random rotation to make each rock look different"""
	# Use instance ID as seed for unique rotation per rock
	var rng = RandomNumberGenerator.new()
	rng.seed = get_instance_id() + rock_seed

	rotation = Vector3(
		rng.randf_range(0, TAU),
		rng.randf_range(0, TAU),
		rng.randf_range(0, TAU)
	)

func generate_rock():
	if rock_seed != 0:
		seed(rock_seed)
	else:
		randomize()

	# Create low-poly sphere mesh
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = rock_radius
	sphere_mesh.height = rock_radius * 2.0
	sphere_mesh.rings = rings
	sphere_mesh.radial_segments = radial_segments

	# Get the mesh data so we can modify vertices
	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(sphere_mesh, 0)
	var array_mesh = surface_tool.commit()

	# Get vertex data
	var arrays = array_mesh.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX]

	# Wiggle each vertex deterministically based on position (fixes seam issue)
	for i in range(vertices.size()):
		var vert = vertices[i]

		# Create deterministic random generator based on vertex position
		# Round to avoid floating point issues with duplicate verts
		var pos_hash = int(vert.x * 1000) + int(vert.y * 1000) * 7919 + int(vert.z * 1000) * 7919 * 7919
		var rng = RandomNumberGenerator.new()
		rng.seed = pos_hash + rock_seed

		var wiggle = Vector3(
			rng.randf_range(-wiggle_amount, wiggle_amount),
			rng.randf_range(-wiggle_amount, wiggle_amount),
			rng.randf_range(-wiggle_amount, wiggle_amount)
		)
		vertices[i] = vert + wiggle

	# Update the mesh with wiggled vertices
	arrays[Mesh.ARRAY_VERTEX] = vertices

	# Use SurfaceTool to rebuild with proper normals
	var rebuild_tool = SurfaceTool.new()
	rebuild_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	rebuild_tool.create_from_arrays(arrays)
	rebuild_tool.generate_normals()
	var wiggled_mesh = rebuild_tool.commit()

	# Create mesh instance
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = wiggled_mesh

	# Apply material
	var material = StandardMaterial3D.new()
	material.albedo_color = rock_color
	material.roughness = 0.9
	material.metallic = 0.0
	mesh_inst.material_override = material

	add_child(mesh_inst)

	# Create collision shape that matches the actual mesh
	var collision = CollisionShape3D.new()

	# Use convex hull of the wiggled vertices
	var convex_shape = ConvexPolygonShape3D.new()
	convex_shape.points = vertices
	collision.shape = convex_shape

	add_child(collision)
