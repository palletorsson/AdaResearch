# GyroidFieldGenerator.gd
# Generates gyroid triply periodic minimal surface using marching cubes
# Creates actual mesh geometry instead of ray marching

extends RefCounted
class_name GyroidFieldGenerator

# Components
var marching_cubes: MarchingCubesGenerator
var collision_generator: CaveCollisionGenerator

# Gyroid parameters
var frequency: float = 1.2
var threshold: float = 0.0
var noise_amp: float = 0.15
var noise_freq: float = 0.7
var box_size: Vector3 = Vector3(8, 8, 8)
var voxel_resolution: Vector3i = Vector3i(40, 40, 40)  # Resolution of voxel sampling

# Noise for organic variation
var noise: FastNoiseLite

# Generated content
var gyroid_mesh: MeshInstance3D
var collision_body: StaticBody3D

signal generation_complete()

func _init():
	setup_components()

func setup_components():
	"""Initialize marching cubes and noise"""
	marching_cubes = MarchingCubesGenerator.new()
	marching_cubes.threshold = 0.5  # We'll map gyroid to [0,1] range
	# Note: We pre-fill the VoxelChunk, so no terrain_generator_ref needed

	collision_generator = CaveCollisionGenerator.new()

	# Setup noise
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = noise_freq
	noise.seed = randi()

	print("GyroidFieldGenerator: Initialized")

func calculate_gyroid_density(world_pos: Vector3) -> float:
	"""
	Gyroid triply periodic minimal surface:
	f(x,y,z) = sin(kx)cos(ky) + sin(ky)cos(kz) + sin(kz)cos(kx)

	Returns density in [0,1] range for marching cubes.
	"""
	var k: float = frequency

	# Gyroid base equation
	var gx: float = sin(k * world_pos.x) * cos(k * world_pos.y)
	var gy: float = sin(k * world_pos.y) * cos(k * world_pos.z)
	var gz: float = sin(k * world_pos.z) * cos(k * world_pos.x)
	var gyroid: float = gx + gy + gz

	# Add organic noise perturbation
	var n: float = noise.get_noise_3d(
		world_pos.x * noise_freq,
		world_pos.y * noise_freq,
		world_pos.z * noise_freq
	)

	var field: float = gyroid + noise_amp * n

	# Map gyroid field (range roughly [-3, 3]) to density [0, 1]
	# We want field = threshold to correspond to density = 0.5 (marching cubes isosurface)
	var normalized: float = (field - threshold) / 6.0 + 0.5

	return clamp(normalized, 0.0, 1.0)

func generate_gyroid_mesh(parent_node: Node3D) -> MeshInstance3D:
	"""Generate the gyroid mesh using marching cubes"""
	print("GyroidFieldGenerator: Generating gyroid mesh...")
	var start_time := Time.get_ticks_msec()

	# Create voxel chunk for the gyroid volume
	var chunk_scale := box_size.x / float(voxel_resolution.x)
	var chunk_offset := -box_size * 0.5  # Center at origin

	var chunk := VoxelChunk.new(voxel_resolution, chunk_offset, chunk_scale)
	chunk.chunk_name = "gyroid_volume"

	# Fill chunk with gyroid density data
	fill_gyroid_chunk(chunk, chunk_offset, chunk_scale)

	# Generate mesh using marching cubes
	var array_mesh := marching_cubes.generate_mesh_from_chunk(chunk)

	if array_mesh == null:
		print("GyroidFieldGenerator: Failed to generate mesh")
		return null

	# Create mesh instance
	gyroid_mesh = MeshInstance3D.new()
	gyroid_mesh.name = "GyroidMesh"
	gyroid_mesh.mesh = array_mesh

	# Apply shader material
	var shader := Shader.new()
	shader.code = _gyroid_shader_code()

	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("base_color", Color(0.85, 0.93, 1.0))
	material.set_shader_parameter("rim_color", Color(0.2, 0.6, 1.0))
	material.set_shader_parameter("metallic", 0.0)
	material.set_shader_parameter("roughness", 1.0)
	material.set_shader_parameter("rim_strength", 0.4)

	gyroid_mesh.material_override = material

	parent_node.add_child(gyroid_mesh)

	var elapsed := Time.get_ticks_msec() - start_time
	print("GyroidFieldGenerator: Generated mesh in %d ms" % elapsed)
	print("  Vertices: %d" % array_mesh.get_surface_count())

	generation_complete.emit()

	return gyroid_mesh

func fill_gyroid_chunk(chunk: VoxelChunk, offset: Vector3, scale: float) -> void:
	"""Fill voxel chunk with gyroid density values"""
	var count := 0

	for x in range(chunk.chunk_size.x + 1):
		for y in range(chunk.chunk_size.y + 1):
			for z in range(chunk.chunk_size.z + 1):
				# Calculate world position
				var world_x := offset.x + x * scale
				var world_y := offset.y + y * scale
				var world_z := offset.z + z * scale

				var world_pos := Vector3(world_x, world_y, world_z)
				var density := calculate_gyroid_density(world_pos)

				chunk.set_density(Vector3i(x, y, z), density)
				count += 1

	chunk.is_dirty = false
	print("GyroidFieldGenerator: Filled chunk with %d voxels" % count)

func generate_collision(parent_node: Node3D) -> StaticBody3D:
	"""Generate collision from the mesh"""
	if gyroid_mesh == null or gyroid_mesh.mesh == null:
		print("GyroidFieldGenerator: No mesh available for collision")
		return null

	print("GyroidFieldGenerator: Generating collision...")

	collision_body = StaticBody3D.new()
	collision_body.name = "GyroidCollision"

	# Create trimesh collision from the mesh
	var mesh_shape := gyroid_mesh.mesh.create_trimesh_shape()
	var collision_shape := CollisionShape3D.new()
	collision_shape.shape = mesh_shape

	collision_body.add_child(collision_shape)
	parent_node.add_child(collision_body)

	print("GyroidFieldGenerator: Collision generated")

	return collision_body

func update_parameters(params: Dictionary) -> void:
	"""Update gyroid parameters"""
	if params.has("frequency"):
		frequency = params.frequency
	if params.has("threshold"):
		threshold = params.threshold
	if params.has("noise_amp"):
		noise_amp = params.noise_amp
	if params.has("noise_freq"):
		noise_freq = params.noise_freq
		noise.frequency = noise_freq

func regenerate(parent_node: Node3D) -> void:
	"""Regenerate the gyroid mesh with current parameters"""
	# Clean up old mesh and collision
	if gyroid_mesh != null:
		gyroid_mesh.queue_free()
	if collision_body != null:
		collision_body.queue_free()

	# Generate new mesh
	generate_gyroid_mesh(parent_node)
	generate_collision(parent_node)

func _gyroid_shader_code() -> String:
	"""Shader for gyroid mesh - unshaded, no lighting or shadows"""
	return """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_always;

uniform vec3 base_color : source_color = vec3(0.85, 0.93, 1.0);
uniform vec3 rim_color : source_color = vec3(0.2, 0.6, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.4;

void fragment() {
	// Flip normal for backfaces to ensure proper rim calculation
	vec3 normal = FRONT_FACING ? NORMAL : -NORMAL;

	// Base color
	ALBEDO = base_color;

	// Rim effect based on view angle (for depth perception)
	float rim = 1.0 - abs(dot(normal, VIEW));
	rim = pow(rim, 3.0);

	// Mix base color with rim color
	ALBEDO = mix(base_color, rim_color, rim * rim_strength);

	// Force fully opaque
	ALPHA = 1.0;
	ALPHA_SCISSOR_THRESHOLD = 1.0;
}
"""
