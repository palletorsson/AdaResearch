# voronoi_sphere.gd
# Test 6: Sphere that cracks using Voronoi fracture on collision
extends RigidBody3D

signal sphere_cracked(sphere: Node3D, impact_point: Vector3, impact_velocity: Vector3)

@export_group("Sphere Properties")
@export var sphere_radius: float = 0.3
@export var sphere_color: Color = Color(0.8, 0.3, 1.0, 1.0)  # Purple
@export var fragment_count: int = 12  # Number of Voronoi-style fragments
@export var crack_impulse_strength: float = 3.0

@export_group("Behavior")
@export var start_frozen: bool = true

# State
var has_cracked: bool = false

# References
var mesh_instance: MeshInstance3D = null
var collision_shape: CollisionShape3D = null
var area: Area3D = null

func _ready() -> void:
	_setup_visual()
	_setup_collision()
	_setup_physics()
	_setup_hit_detection()

func _setup_visual() -> void:
	"""Create the sphere mesh"""
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	add_child(mesh_instance)

	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = sphere_radius
	sphere_mesh.height = sphere_radius * 2.0
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 8
	mesh_instance.mesh = sphere_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = sphere_color
	material.emission_enabled = true
	material.emission = sphere_color
	material.emission_energy = 0.2
	material.metallic = 0.0
	material.roughness = 1.0

	mesh_instance.material_override = material

func _setup_collision() -> void:
	"""Create collision shape"""
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = sphere_radius
	collision_shape.shape = sphere_shape
	add_child(collision_shape)

func _setup_physics() -> void:
	"""Configure physics properties"""
	mass = 1.0
	contact_monitor = true
	max_contacts_reported = 4

	if start_frozen:
		freeze = true
		gravity_scale = 0.0
	else:
		freeze = false
		gravity_scale = 1.0

func _setup_hit_detection() -> void:
	"""Create Area3D for detecting ball impacts"""
	area = Area3D.new()
	area.name = "HitDetectionArea"
	area.monitoring = true
	area.monitorable = true
	area.collision_layer = 0
	area.collision_mask = 2  # Detect throwable balls

	add_child(area)

	var area_collision = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = sphere_radius * 1.1
	area_collision.shape = sphere_shape
	area.add_child(area_collision)

	area.body_entered.connect(_on_ball_hit)

func _on_ball_hit(body: Node) -> void:
	"""Handle ball impact - crack the sphere"""
	if has_cracked:
		return

	if not body.is_in_group("throwable"):
		return

	# Get impact velocity and position
	var impact_velocity = Vector3.ZERO
	if body is RigidBody3D:
		impact_velocity = body.linear_velocity

	# Calculate impact point (approximate)
	var impact_point = body.global_position - global_position
	impact_point = impact_point.normalized() * sphere_radius

	_crack_sphere(impact_point, impact_velocity)

func _crack_sphere(impact_point_local: Vector3, impact_velocity: Vector3) -> void:
	"""Create Voronoi-style fragments"""
	if has_cracked:
		return

	has_cracked = true

	# Emit signal
	sphere_cracked.emit(self, impact_point_local, impact_velocity)

	# Generate Voronoi cell centers (random points on/in sphere)
	var voronoi_centers: Array[Vector3] = []

	# Place one at impact point
	voronoi_centers.append(impact_point_local.normalized() * sphere_radius * 0.8)

	# Generate random points on sphere surface
	for i in range(fragment_count - 1):
		var random_point = _random_point_on_sphere(sphere_radius * 0.6)
		voronoi_centers.append(random_point)

	# Create fragments
	for i in range(fragment_count):
		var fragment = _create_fragment(voronoi_centers[i], impact_velocity, i)
		get_parent().add_child(fragment)

	# Remove original sphere
	_fade_out_and_remove()

func _create_fragment(center_offset: Vector3, impact_velocity: Vector3, index: int) -> RigidBody3D:
	"""Create a fragment piece"""
	var fragment = RigidBody3D.new()
	fragment.name = "Fragment_%d" % index
	fragment.global_position = global_position + center_offset

	# Create irregular fragment mesh (simplified - using boxes with random sizes)
	var fragment_size = sphere_radius / 3.0
	var mesh_inst = MeshInstance3D.new()

	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(
		fragment_size * randf_range(0.5, 1.5),
		fragment_size * randf_range(0.5, 1.5),
		fragment_size * randf_range(0.5, 1.5)
	)
	mesh_inst.mesh = box_mesh

	# Vary color slightly
	var frag_color = sphere_color
	frag_color.h = fmod(sphere_color.h + randf_range(-0.1, 0.1), 1.0)
	frag_color.v = sphere_color.v * randf_range(0.8, 1.2)

	var material = StandardMaterial3D.new()
	material.albedo_color = frag_color
	material.emission_enabled = true
	material.emission = frag_color
	material.emission_energy = 0.2

	mesh_inst.material_override = material
	fragment.add_child(mesh_inst)

	# Add collision
	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = box_mesh.size
	collision.shape = box_shape
	fragment.add_child(collision)

	# Physics
	fragment.mass = 0.1
	fragment.gravity_scale = 1.0

	# Apply impulse away from center
	var explosion_direction = center_offset.normalized()
	if explosion_direction.length() < 0.1:
		explosion_direction = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()

	var explosion_force = explosion_direction * crack_impulse_strength
	var inherited_velocity = impact_velocity * 0.2

	fragment.linear_velocity = explosion_force + inherited_velocity
	fragment.angular_velocity = Vector3(
		randf_range(-5, 5),
		randf_range(-5, 5),
		randf_range(-5, 5)
	)

	# Fade out fragments after a while
	_schedule_fragment_removal(fragment, mesh_inst)

	return fragment

func _random_point_on_sphere(radius: float) -> Vector3:
	"""Generate random point on sphere surface"""
	var theta = randf() * TAU
	var phi = acos(2.0 * randf() - 1.0)

	return Vector3(
		radius * sin(phi) * cos(theta),
		radius * sin(phi) * sin(theta),
		radius * cos(phi)
	)

func _schedule_fragment_removal(fragment: RigidBody3D, mesh_inst: MeshInstance3D) -> void:
	"""Fade out and remove fragment after delay"""
	await get_tree().create_timer(3.0).timeout

	var tween = create_tween()
	tween.set_parallel(true)

	if mesh_inst.material_override:
		var material = mesh_inst.material_override
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tween.tween_property(material, "albedo_color:a", 0.0, 1.0)

	tween.tween_property(mesh_inst, "scale", Vector3.ZERO, 1.0)
	tween.tween_callback(fragment.queue_free).set_delay(1.0)

func _fade_out_and_remove() -> void:
	"""Remove the original sphere"""
	collision_layer = 0
	collision_mask = 0

	var tween = create_tween()
	tween.set_parallel(true)

	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tween.tween_property(material, "albedo_color:a", 0.0, 0.3)

	tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(queue_free).set_delay(0.3)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
