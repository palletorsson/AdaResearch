extends Node3D

## Voronoi-Divided Marching Cube
## A 1x1x1 cube of marching cubes geometry, pre-divided into Voronoi fragments

@export var cell_count: int = 8  # Number of Voronoi cells
@export var explosion_strength: float = 3.0
@export var cube_size: float = 1.0
@export var noise_scale: float = 5.0
@export var iso_level: float = 0.5

var _fragments: Array[RigidBody3D] = []
var _is_destroyed: bool = false
var _hit_area: Area3D

func _ready() -> void:
	call_deferred("_generate_voronoi_cube")

func _generate_voronoi_cube() -> void:
	print("VoronoiMarchingCube: Generating cube with ", cell_count, " cells")

	# Generate Voronoi seed points within the cube
	var voronoi_seeds = _generate_voronoi_seeds()

	# For each Voronoi cell, create a marching cubes fragment
	for i in range(voronoi_seeds.size()):
		_create_voronoi_fragment(voronoi_seeds[i], voronoi_seeds, i)

	# Setup hit detection on the whole structure
	_setup_hit_detection()

	print("VoronoiMarchingCube: Generated ", _fragments.size(), " fragments")

func _generate_voronoi_seeds() -> Array[Vector3]:
	var seeds: Array[Vector3] = []

	# Generate random points within the cube bounds
	for i in range(cell_count):
		var seed = Vector3(
			randf_range(-cube_size * 0.4, cube_size * 0.4),
			randf_range(-cube_size * 0.4, cube_size * 0.4),
			randf_range(-cube_size * 0.4, cube_size * 0.4)
		)
		seeds.append(seed)

	return seeds

func _create_voronoi_fragment(seed: Vector3, all_seeds: Array[Vector3], index: int) -> void:
	# Create a fragment using marching cubes
	var fragment = RigidBody3D.new()
	fragment.name = "Fragment_" + str(index)
	fragment.mass = 0.5
	fragment.freeze = true  # Start frozen, will unfreeze on hit
	fragment.position = seed  # Position at the seed
	add_child(fragment)

	# Create mesh for this Voronoi cell
	var mesh = _generate_voronoi_cell_mesh(seed, all_seeds)

	if mesh:
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = mesh
		fragment.add_child(mesh_instance)

		# Add material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(
			randf_range(0.3, 0.8),
			randf_range(0.3, 0.8),
			randf_range(0.3, 0.8)
		)
		material.metallic = 0.3
		material.roughness = 0.7
		mesh_instance.set_surface_override_material(0, material)

		# Create collision from mesh
		var collision_shape = CollisionShape3D.new()
		var shape = mesh.create_convex_shape()
		if shape:
			collision_shape.shape = shape
			fragment.add_child(collision_shape)

		print("  Fragment ", index, " created at ", seed, " with mesh")
	else:
		print("  Fragment ", index, " - NO MESH GENERATED")
		fragment.queue_free()
		return

	_fragments.append(fragment)

func _generate_voronoi_cell_mesh(seed: Vector3, all_seeds: Array[Vector3]) -> ArrayMesh:
	# Generate a mesh for this Voronoi cell using marching cubes
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Resolution for marching cubes
	var resolution = 8
	var cell_size = cube_size / resolution
	var vertex_count = 0

	# March through a grid around the seed
	for x in range(resolution):
		for y in range(resolution):
			for z in range(resolution):
				var pos = Vector3(
					-cube_size * 0.5 + x * cell_size,
					-cube_size * 0.5 + y * cell_size,
					-cube_size * 0.5 + z * cell_size
				)

				# Check if this voxel belongs to this Voronoi cell
				if _get_closest_seed(pos, all_seeds) != seed:
					continue

				# Generate marching cube for this voxel
				var added = _march_cube(surface_tool, pos, cell_size)
				if added:
					vertex_count += 36  # 12 triangles * 3 vertices per box

	if vertex_count > 0:
		surface_tool.generate_normals()
		print("    Generated mesh with ~", vertex_count, " vertices")
		return surface_tool.commit()

	print("    No vertices generated for this cell")
	return null

func _get_closest_seed(pos: Vector3, seeds: Array[Vector3]) -> Vector3:
	var closest = seeds[0]
	var min_dist = pos.distance_squared_to(closest)

	for seed in seeds:
		var dist = pos.distance_squared_to(seed)
		if dist < min_dist:
			min_dist = dist
			closest = seed

	return closest

func _march_cube(surface_tool: SurfaceTool, corner: Vector3, size: float) -> bool:
	# Simple marching cube implementation
	# Sample 8 corners of the cube
	var corners = [
		corner,
		corner + Vector3(size, 0, 0),
		corner + Vector3(size, 0, size),
		corner + Vector3(0, 0, size),
		corner + Vector3(0, size, 0),
		corner + Vector3(size, size, 0),
		corner + Vector3(size, size, size),
		corner + Vector3(0, size, size)
	]

	var densities = []
	for c in corners:
		densities.append(_density_function(c))

	# Create cube index
	var cube_index = 0
	for i in range(8):
		if densities[i] < iso_level:
			cube_index |= (1 << i)

	# For now, always create geometry to ensure visibility
	# A full marching cubes implementation would only create geometry at the surface
	# Skip only if completely outside
	if cube_index == 255:
		return false

	# Create a box at this position
	var center = corner + Vector3.ONE * size * 0.5
	_add_box_to_surface(surface_tool, center, size * 0.8)
	return true

func _density_function(pos: Vector3) -> float:
	# Combine noise with distance from cube bounds
	var noise_val = _simplex_noise_3d(pos * noise_scale)

	# Distance to cube boundary (negative inside, positive outside)
	var half_size = cube_size * 0.5
	var dist_x = abs(pos.x) - half_size
	var dist_y = abs(pos.y) - half_size
	var dist_z = abs(pos.z) - half_size
	var boundary_dist = max(dist_x, max(dist_y, dist_z))

	# Combine: inside cube = negative, with noise variation
	return boundary_dist + noise_val * 0.2

func _simplex_noise_3d(p: Vector3) -> float:
	# Simplified 3D noise - just use sin waves for now
	return sin(p.x * 2.0) * 0.5 + sin(p.y * 3.0) * 0.3 + sin(p.z * 2.5) * 0.4

func _add_box_to_surface(surface_tool: SurfaceTool, center: Vector3, size: float) -> void:
	# Add a small box as a stand-in for proper marching cubes geometry
	var hs = size * 0.5  # half size

	# Define 8 corners of the box
	var v = [
		center + Vector3(-hs, -hs, -hs),
		center + Vector3(hs, -hs, -hs),
		center + Vector3(hs, -hs, hs),
		center + Vector3(-hs, -hs, hs),
		center + Vector3(-hs, hs, -hs),
		center + Vector3(hs, hs, -hs),
		center + Vector3(hs, hs, hs),
		center + Vector3(-hs, hs, hs),
	]

	# Add triangles for each face (12 triangles total)
	var faces = [
		# Bottom
		[0, 1, 2], [0, 2, 3],
		# Top
		[4, 6, 5], [4, 7, 6],
		# Front
		[0, 3, 7], [0, 7, 4],
		# Back
		[1, 5, 6], [1, 6, 2],
		# Left
		[0, 4, 5], [0, 5, 1],
		# Right
		[3, 2, 6], [3, 6, 7]
	]

	for face in faces:
		for idx in face:
			surface_tool.add_vertex(v[idx])

func _setup_hit_detection() -> void:
	# Create an area that covers all fragments
	_hit_area = Area3D.new()
	_hit_area.name = "HitArea"
	_hit_area.collision_layer = 0
	_hit_area.collision_mask = 2  # Detect throwable projectiles
	add_child(_hit_area)

	# Create a box collision shape
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3.ONE * cube_size * 1.2
	collision_shape.shape = box_shape
	_hit_area.add_child(collision_shape)

	_hit_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if _is_destroyed:
		return

	if not body.is_in_group("throwable"):
		return

	print("VoronoiMarchingCube: Hit by ", body.name)

	var impact_velocity = Vector3.ZERO
	if body is RigidBody3D:
		impact_velocity = body.linear_velocity

	_destroy(impact_velocity)

func _destroy(impact_velocity: Vector3) -> void:
	if _is_destroyed:
		return

	_is_destroyed = true
	print("VoronoiMarchingCube: Exploding into ", _fragments.size(), " pieces!")

	# Remove hit area
	if _hit_area:
		_hit_area.queue_free()

	# Unfreeze and apply forces to all fragments
	for fragment in _fragments:
		if not is_instance_valid(fragment):
			continue

		fragment.freeze = false

		# Calculate explosion direction from center
		var explosion_dir = (fragment.global_position - global_position).normalized()
		if explosion_dir.length_squared() < 0.01:
			explosion_dir = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()

		# Apply forces
		var force = explosion_dir * explosion_strength
		fragment.linear_velocity = force + impact_velocity * 0.2
		fragment.angular_velocity = Vector3(
			randf_range(-3, 3),
			randf_range(-3, 3),
			randf_range(-3, 3)
		)

		# Fade out
		_fade_fragment(fragment)

	# Cleanup
	await get_tree().create_timer(6.0).timeout
	queue_free()

func _fade_fragment(fragment: RigidBody3D) -> void:
	await get_tree().create_timer(4.0).timeout

	if not is_instance_valid(fragment):
		return

	var mesh_instance = fragment.find_child("MeshInstance3D", false, false)
	if mesh_instance:
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 1.5)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

