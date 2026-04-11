extends Node3D

## Destructible Marching Cubes Object
## Generates organic geometry using marching cubes, then shatters on impact

@export var terrain_generator_path: NodePath
@export var fragment_count: int = 12
@export var explosion_strength: float = 5.0
@export var health: int = 1

var _terrain_generator: Node
var _base_mesh: ArrayMesh
var _base_mesh_instance: MeshInstance3D
var _collision_body: StaticBody3D
var _hit_area: Area3D
var _is_destroyed: bool = false
var _fragments: Array[RigidBody3D] = []

func _ready() -> void:
	# Find the terrain generator
	if terrain_generator_path:
		_terrain_generator = get_node(terrain_generator_path)

	# Setup the destructible
	call_deferred("_initialize")

func _initialize() -> void:
	# Wait for terrain to generate if needed
	if _terrain_generator and _terrain_generator.has_method("wait_for_generation"):
		await _terrain_generator.wait_for_generation()

	# Get the generated mesh
	_setup_base_mesh()

	# Setup collision and hit detection
	_setup_collision()
	_setup_hit_detection()

	print("DestructibleMarchingCube: Initialized with ", fragment_count, " potential fragments")

func _setup_base_mesh() -> void:
	# Find the MeshInstance3D from terrain generator
	if _terrain_generator:
		var mesh_instance = _terrain_generator.find_child("MeshInstance3D", true, false)
		if mesh_instance and mesh_instance is MeshInstance3D:
			_base_mesh = mesh_instance.mesh

			# Create our own mesh instance
			_base_mesh_instance = MeshInstance3D.new()
			_base_mesh_instance.mesh = _base_mesh
			_base_mesh_instance.name = "BaseMesh"
			add_child(_base_mesh_instance)

			# Copy material if exists
			if mesh_instance.get_surface_override_material_count() > 0:
				_base_mesh_instance.set_surface_override_material(0, mesh_instance.get_surface_override_material(0))

			print("DestructibleMarchingCube: Mesh copied with ", _base_mesh.get_surface_count(), " surfaces")

func _setup_collision() -> void:
	# Create static body for collision
	_collision_body = StaticBody3D.new()
	_collision_body.name = "CollisionBody"
	add_child(_collision_body)

	# Create collision shape from mesh
	if _base_mesh:
		var shape = _base_mesh.create_trimesh_shape()
		if shape:
			var collision_shape = CollisionShape3D.new()
			collision_shape.shape = shape
			_collision_body.add_child(collision_shape)
			print("DestructibleMarchingCube: Collision shape created")

func _setup_hit_detection() -> void:
	# Create area to detect projectile hits
	_hit_area = Area3D.new()
	_hit_area.name = "HitArea"
	_hit_area.collision_layer = 0
	_hit_area.collision_mask = 2  # Layer 2 = throwable projectiles
	_collision_body.add_child(_hit_area)

	# Use same collision shape
	if _collision_body.get_child_count() > 0:
		var original_shape = _collision_body.get_child(0)
		if original_shape is CollisionShape3D:
			var area_shape = CollisionShape3D.new()
			area_shape.shape = original_shape.shape
			_hit_area.add_child(area_shape)

	# Connect signal
	_hit_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if _is_destroyed:
		return

	# Check if it's a throwable projectile
	if not body.is_in_group("throwable"):
		return

	# Get impact data
	var impact_point = global_position
	var impact_velocity = Vector3.ZERO

	if body is RigidBody3D:
		impact_velocity = body.linear_velocity
		# Try to get more accurate impact point
		if body.has_method("get_contact_count"):
			impact_point = body.global_position

	print("DestructibleMarchingCube: Hit by ", body.name, " at ", impact_point)

	# Reduce health
	health -= 1
	if health <= 0:
		_destroy(impact_point, impact_velocity)
	else:
		_hit_feedback()

func _hit_feedback() -> void:
	# Visual feedback for hit but not destroyed
	if _base_mesh_instance:
		var tween = create_tween()
		var material = _base_mesh_instance.get_active_material(0)
		if material and material is StandardMaterial3D:
			var original_emission = material.emission_energy_multiplier
			tween.tween_property(material, "emission_energy_multiplier", 2.0, 0.1)
			tween.tween_property(material, "emission_energy_multiplier", original_emission, 0.2)

func _destroy(impact_point: Vector3, impact_velocity: Vector3) -> void:
	if _is_destroyed:
		return

	_is_destroyed = true
	print("DestructibleMarchingCube: Destroying!")

	# Hide original mesh
	if _base_mesh_instance:
		_base_mesh_instance.visible = false

	# Remove collision
	if _collision_body:
		_collision_body.queue_free()

	# Create fragments
	_create_fragments(impact_point, impact_velocity)

func _create_fragments(_impact_point: Vector3, impact_velocity: Vector3) -> void:
	if not _base_mesh:
		return

	# Get mesh data
	var surface_arrays = _base_mesh.surface_get_arrays(0)
	var vertices = surface_arrays[Mesh.ARRAY_VERTEX]

	if vertices.size() == 0:
		print("DestructibleMarchingCube: No vertices to fragment!")
		return

	# Calculate mesh bounds and center
	var mesh_center = _calculate_mesh_center(vertices)

	# Generate Voronoi seed points around the mesh
	var voronoi_centers = _generate_voronoi_centers(mesh_center, fragment_count)

	# Create a fragment for each voronoi center
	for i in range(voronoi_centers.size()):
		var center = voronoi_centers[i]
		_create_fragment(center, mesh_center, impact_velocity, i)

	# Cleanup after animation
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _calculate_mesh_center(vertices: PackedVector3Array) -> Vector3:
	var center = Vector3.ZERO
	for v in vertices:
		center += v
	return center / vertices.size()

func _generate_voronoi_centers(mesh_center: Vector3, count: int) -> Array[Vector3]:
	var centers: Array[Vector3] = []

	# Generate random points around the mesh center
	for i in range(count):
		var random_dir = Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			randf_range(-1, 1)
		).normalized()

		var distance = randf_range(1.0, 3.0)
		centers.append(mesh_center + random_dir * distance)

	return centers

func _create_fragment(center: Vector3, mesh_center: Vector3, impact_velocity: Vector3, index: int) -> void:
	# Create a simple box fragment at the voronoi center
	var fragment = RigidBody3D.new()
	fragment.name = "Fragment_" + str(index)
	add_child(fragment)

	# Position it
	fragment.global_position = global_position + center

	# Create mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.5, 0.5, 0.5)
	mesh_instance.mesh = box_mesh
	fragment.add_child(mesh_instance)

	# Copy material
	if _base_mesh_instance:
		var material = _base_mesh_instance.get_active_material(0)
		if material:
			mesh_instance.set_surface_override_material(0, material.duplicate())

	# Create collision
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = box_mesh.size
	collision_shape.shape = box_shape
	fragment.add_child(collision_shape)

	# Apply explosion force
	var explosion_dir = (center - mesh_center).normalized()
	if explosion_dir.length_squared() < 0.01:
		explosion_dir = Vector3.UP

	var force = explosion_dir * explosion_strength
	var inherited_velocity = impact_velocity * 0.3

	fragment.linear_velocity = force + inherited_velocity
	fragment.angular_velocity = Vector3(
		randf_range(-5, 5),
		randf_range(-5, 5),
		randf_range(-5, 5)
	)

	# Fade out fragment
	_fade_fragment(mesh_instance)

	_fragments.append(fragment)

func _fade_fragment(mesh_instance: MeshInstance3D) -> void:
	await get_tree().create_timer(3.0).timeout

	if not is_instance_valid(mesh_instance):
		return

	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 1.0)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
