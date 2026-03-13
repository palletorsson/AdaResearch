extends Node3D

## Destructible Terrain Cube
## Uses actual marching cubes TerrainGenerator, makes it destructible

@export var fragment_count: int = 12
@export var explosion_strength: float = 5.0
@export var health: int = 1

var _terrain_mesh_instance: MeshInstance3D
var _generated_mesh: Mesh
var _is_destroyed: bool = false
var _hit_area: Area3D
var _collision_body: StaticBody3D

func _ready() -> void:
	# Find the terrain generator (should be a child MeshInstance3D)
	_terrain_mesh_instance = find_child("*", true, false) as MeshInstance3D

	if _terrain_mesh_instance:
		print("DestructibleTerrainCube: Found terrain mesh instance")
		# Wait for terrain to generate
		call_deferred("_setup_after_generation")
	else:
		push_error("DestructibleTerrainCube: No MeshInstance3D child found!")

func _setup_after_generation() -> void:
	# Wait a few frames for terrain to generate
	await get_tree().create_timer(2.0).timeout

	if _terrain_mesh_instance and _terrain_mesh_instance.mesh:
		_generated_mesh = _terrain_mesh_instance.mesh
		print("DestructibleTerrainCube: Mesh generated with ", _generated_mesh.get_surface_count(), " surfaces")

		_setup_collision()
		_setup_hit_detection()
	else:
		push_error("DestructibleTerrainCube: Terrain mesh not generated!")

func _setup_collision() -> void:
	# Create static body
	_collision_body = StaticBody3D.new()
	_collision_body.name = "CollisionBody"
	add_child(_collision_body)

	# Create trimesh collision from generated mesh
	var shape = _generated_mesh.create_trimesh_shape()
	if shape:
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = shape
		_collision_body.add_child(collision_shape)
		print("DestructibleTerrainCube: Collision created")

func _setup_hit_detection() -> void:
	# Create hit detection area
	_hit_area = Area3D.new()
	_hit_area.name = "HitArea"
	_hit_area.collision_layer = 0
	_hit_area.collision_mask = 2  # Throwable objects
	_collision_body.add_child(_hit_area)

	# Use same collision shape
	if _collision_body.get_child_count() > 0:
		var original_shape = _collision_body.get_child(0) as CollisionShape3D
		if original_shape:
			var area_shape = CollisionShape3D.new()
			area_shape.shape = original_shape.shape
			_hit_area.add_child(area_shape)

	_hit_area.body_entered.connect(_on_body_entered)
	print("DestructibleTerrainCube: Hit detection ready")

func _on_body_entered(body: Node3D) -> void:
	if _is_destroyed or not body.is_in_group("throwable"):
		return

	var impact_velocity = Vector3.ZERO
	if body is RigidBody3D:
		impact_velocity = body.linear_velocity

	print("DestructibleTerrainCube: Hit by ", body.name)

	health -= 1
	if health <= 0:
		_destroy(impact_velocity)

func _destroy(impact_velocity: Vector3) -> void:
	if _is_destroyed:
		return

	_is_destroyed = true
	print("DestructibleTerrainCube: Destroying!")

	# Hide original mesh
	if _terrain_mesh_instance:
		_terrain_mesh_instance.visible = false

	# Remove collision
	if _collision_body:
		_collision_body.queue_free()

	# Create fragments
	_create_voronoi_fragments(impact_velocity)

func _create_voronoi_fragments(impact_velocity: Vector3) -> void:
	if not _generated_mesh:
		return

	# Get mesh data
	var surface_arrays = _generated_mesh.surface_get_arrays(0)
	var vertices = surface_arrays[Mesh.ARRAY_VERTEX]

	if vertices.size() == 0:
		print("DestructibleTerrainCube: No vertices!")
		return

	# Calculate mesh center
	var center = Vector3.ZERO
	for v in vertices:
		center += v
	center /= vertices.size()

	print("DestructibleTerrainCube: Creating ", fragment_count, " fragments from ", vertices.size(), " vertices")

	# Generate Voronoi seeds
	var seeds = []
	for i in range(fragment_count):
		var random_offset = Vector3(
			randf_range(-2, 2),
			randf_range(-2, 2),
			randf_range(-2, 2)
		)
		seeds.append(center + random_offset)

	# Create simple box fragments at each seed
	for i in range(seeds.size()):
		_create_fragment(seeds[i], center, impact_velocity, i)

	# Cleanup
	await get_tree().create_timer(6.0).timeout
	queue_free()

func _create_fragment(pos: Vector3, mesh_center: Vector3, impact_velocity: Vector3, index: int) -> void:
	var fragment = RigidBody3D.new()
	fragment.name = "Fragment_" + str(index)
	fragment.global_position = global_position + pos
	add_child(fragment)

	# Create simple box mesh
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.5, 0.5, 0.5)
	mesh_instance.mesh = box
	fragment.add_child(mesh_instance)

	# Copy material from terrain
	if _terrain_mesh_instance:
		var material = _terrain_mesh_instance.get_active_material(0)
		if material:
			mesh_instance.set_surface_override_material(0, material.duplicate())

	# Collision
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = box.size
	collision_shape.shape = box_shape
	fragment.add_child(collision_shape)

	# Apply explosion
	var explosion_dir = (pos - mesh_center).normalized()
	if explosion_dir.length_squared() < 0.01:
		explosion_dir = Vector3.UP

	fragment.linear_velocity = explosion_dir * explosion_strength + impact_velocity * 0.3
	fragment.angular_velocity = Vector3(
		randf_range(-5, 5),
		randf_range(-5, 5),
		randf_range(-5, 5)
	)

	# Fade out
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(mesh_instance):
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 1.5)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

