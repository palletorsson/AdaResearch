extends Node3D

## Organic Voronoi Cube
## Generates organic-looking fragments using Voronoi cells

@export var cube_size: float = 2.0
@export var cell_count: int = 12
@export var explosion_strength: float = 5.0
@export var organic_variation: float = 0.3  # How much to randomize vertices
@export var health: int = 1

var _fragments: Array[RigidBody3D] = []
var _is_destroyed: bool = false
var _hit_area: Area3D
var _collision_body: StaticBody3D
var _mesh_instance: MeshInstance3D

func _ready():
	call_deferred("_generate_organic_cube")

func _generate_organic_cube():
	print("OrganicVoronoiCube: Generating ", cell_count, " organic fragments")

	# Generate Voronoi seeds
	var seeds = _generate_voronoi_seeds()

	# Create fragments for each seed
	for i in range(seeds.size()):
		_create_organic_fragment(seeds[i], seeds, i)

	# Create visual representation of whole cube
	_create_combined_visual()

	# Setup collision and hit detection
	_setup_collision()
	_setup_hit_detection()

	print("OrganicVoronoiCube: Generation complete!")

func _generate_voronoi_seeds() -> Array[Vector3]:
	var seeds: Array[Vector3] = []
	var half_size = cube_size * 0.5

	for i in range(cell_count):
		var seed = Vector3(
			randf_range(-half_size * 0.8, half_size * 0.8),
			randf_range(-half_size * 0.8, half_size * 0.8),
			randf_range(-half_size * 0.8, half_size * 0.8)
		)
		seeds.append(seed)

	return seeds

func _create_organic_fragment(seed: Vector3, all_seeds: Array[Vector3], index: int):
	# Create RigidBody for this fragment
	var fragment = RigidBody3D.new()
	fragment.name = "Fragment_" + str(index)
	fragment.position = seed
	fragment.mass = 0.5
	fragment.freeze = true  # Frozen until destroyed
	add_child(fragment)

	# Generate Voronoi cell mesh
	var mesh = _generate_voronoi_cell_mesh(seed, all_seeds)

	if mesh:
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = mesh
		mesh_instance.visible = false  # Hidden until destroyed
		fragment.add_child(mesh_instance)

		# Random organic color
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(
			randf_range(0.4, 0.7),
			randf_range(0.4, 0.7),
			randf_range(0.4, 0.7)
		)
		material.roughness = 0.8
		material.metallic = 0.2
		mesh_instance.set_surface_override_material(0, material)

		# Create collision from mesh
		var collision_shape = CollisionShape3D.new()
		var shape = mesh.create_convex_shape()
		if shape:
			collision_shape.shape = shape
			fragment.add_child(collision_shape)

	_fragments.append(fragment)

func _generate_voronoi_cell_mesh(seed: Vector3, all_seeds: Array[Vector3]) -> ArrayMesh:
	# Generate vertices for this Voronoi cell using sample points
	var sample_points = _sample_voronoi_cell(seed, all_seeds)

	if sample_points.size() < 4:
		return null  # Need at least 4 points for a convex shape

	# Create mesh from points using SurfaceTool
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Create convex hull approximation using the sample points
	_create_convex_hull(surface_tool, sample_points)

	surface_tool.generate_normals()
	return surface_tool.commit()

func _sample_voronoi_cell(seed: Vector3, all_seeds: Array[Vector3]) -> PackedVector3Array:
	# Sample points in a grid and keep those closest to this seed
	var points = PackedVector3Array()
	var half_size = cube_size * 0.5
	var resolution = 12

	for x in range(resolution):
		for y in range(resolution):
			for z in range(resolution):
				var t = Vector3(
					x / float(resolution - 1),
					y / float(resolution - 1),
					z / float(resolution - 1)
				)

				var pos = Vector3(
					lerp(-half_size, half_size, t.x),
					lerp(-half_size, half_size, t.y),
					lerp(-half_size, half_size, t.z)
				)

				# Check if this point belongs to this Voronoi cell
				var closest_seed = _get_closest_seed(pos, all_seeds)
				if closest_seed == seed:
					# Add organic variation
					var variation = Vector3(
						randf_range(-organic_variation, organic_variation),
						randf_range(-organic_variation, organic_variation),
						randf_range(-organic_variation, organic_variation)
					)
					points.append(pos + variation)

	return points

func _get_closest_seed(pos: Vector3, seeds: Array[Vector3]) -> Vector3:
	var closest = seeds[0]
	var min_dist = pos.distance_squared_to(closest)

	for seed in seeds:
		var dist = pos.distance_squared_to(seed)
		if dist < min_dist:
			min_dist = dist
			closest = seed

	return closest

func _create_convex_hull(surface_tool: SurfaceTool, points: PackedVector3Array):
	# Simple convex hull approximation - create triangles from points
	# This is a simplified approach; a proper convex hull would use algorithms like QuickHull

	if points.size() < 4:
		return

	# Find centroid
	var center = Vector3.ZERO
	for p in points:
		center += p
	center /= points.size()

	# Create faces by connecting boundary points
	# Group points by their direction from center
	for i in range(min(points.size(), 20)):  # Limit triangles
		for j in range(i + 1, min(points.size(), 20)):
			for k in range(j + 1, min(points.size(), 20)):
				var p1 = points[i]
				var p2 = points[j]
				var p3 = points[k]

				# Create triangle if it faces outward
				var normal = (p2 - p1).cross(p3 - p1)
				var to_center = center - p1

				if normal.dot(to_center) < 0:  # Facing outward
					surface_tool.add_vertex(p1)
					surface_tool.add_vertex(p2)
					surface_tool.add_vertex(p3)

func _create_combined_visual():
	# Create a simple cube visual that represents the whole object
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "CubeMesh"
	add_child(_mesh_instance)

	# Simple box mesh
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3.ONE * cube_size
	_mesh_instance.mesh = box_mesh

	# Material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.6, 0.7)
	material.roughness = 0.7
	material.metallic = 0.3
	_mesh_instance.set_surface_override_material(0, material)

	print("OrganicVoronoiCube: Visual cube created")

func _setup_collision():
	_collision_body = StaticBody3D.new()
	_collision_body.name = "CollisionBody"
	add_child(_collision_body)

	# Create box collision for whole cube
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3.ONE * cube_size
	collision_shape.shape = box_shape
	_collision_body.add_child(collision_shape)

func _setup_hit_detection():
	_hit_area = Area3D.new()
	_hit_area.name = "HitArea"
	_hit_area.collision_layer = 0
	_hit_area.collision_mask = 2  # Throwable objects
	_collision_body.add_child(_hit_area)

	var area_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3.ONE * cube_size * 1.1
	area_shape.shape = box_shape
	_hit_area.add_child(area_shape)

	_hit_area.body_entered.connect(_on_body_entered)

	print("OrganicVoronoiCube: Hit detection ready - waiting for throwable objects")

func _on_body_entered(body: Node3D):
	if _is_destroyed or not body.is_in_group("throwable"):
		return

	var impact_velocity = Vector3.ZERO
	if body is RigidBody3D:
		impact_velocity = body.linear_velocity

	print("OrganicVoronoiCube: Hit!")

	health -= 1
	if health <= 0:
		_destroy(impact_velocity)

func _destroy(impact_velocity: Vector3):
	if _is_destroyed:
		return

	_is_destroyed = true
	print("OrganicVoronoiCube: Exploding into ", _fragments.size(), " organic pieces!")

	# Hide combined mesh
	if _mesh_instance:
		_mesh_instance.visible = false

	# Remove collision
	if _collision_body:
		_collision_body.queue_free()

	# Activate all fragments
	for fragment in _fragments:
		if not is_instance_valid(fragment):
			continue

		# Show the fragment mesh
		var mesh_instance = fragment.find_child("*", false, false) as MeshInstance3D
		if mesh_instance:
			mesh_instance.visible = true

		# Unfreeze
		fragment.freeze = false

		# Apply explosion force
		var explosion_dir = (fragment.position - global_position).normalized()
		if explosion_dir.length_squared() < 0.01:
			explosion_dir = Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized()

		fragment.linear_velocity = explosion_dir * explosion_strength + impact_velocity * 0.2
		fragment.angular_velocity = Vector3(
			randf_range(-4, 4),
			randf_range(-4, 4),
			randf_range(-4, 4)
		)

		# Fade out
		_fade_fragment(mesh_instance)

	# Cleanup
	await get_tree().create_timer(7.0).timeout
	queue_free()

func _fade_fragment(mesh_instance: MeshInstance3D):
	if not mesh_instance:
		return

	await get_tree().create_timer(4.0).timeout

	if not is_instance_valid(mesh_instance):
		return

	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 2.0)
