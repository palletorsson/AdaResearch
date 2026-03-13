# voronoi_plane.gd
# Test 7: Plane that cracks using Voronoi at collision point
extends StaticBody3D

signal plane_cracked(plane: Node3D, impact_point: Vector3, impact_velocity: Vector3)

@export_group("Plane Properties")
@export var plane_size: Vector2 = Vector2(2.0, 2.0)
@export var plane_color: Color = Color(0.3, 0.8, 1.0, 1.0)  # Cyan
@export var fragment_count: int = 16  # Number of Voronoi fragments around impact
@export var crack_radius: float = 0.8  # Radius of cracking effect
@export var fragment_impulse_strength: float = 2.0

@export_group("Visual")
@export var show_crack_effect: bool = true
@export var thickness: float = 0.05

# State
var has_cracked: bool = false

# References
var mesh_instance: MeshInstance3D = null
var collision_shape: CollisionShape3D = null
var area: Area3D = null

func _ready() -> void:
	_setup_visual()
	_setup_collision()
	_setup_hit_detection()

func _setup_visual() -> void:
	"""Create the plane mesh"""
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	add_child(mesh_instance)

	var plane_mesh = BoxMesh.new()
	plane_mesh.size = Vector3(plane_size.x, thickness, plane_size.y)
	mesh_instance.mesh = plane_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = plane_color
	material.emission_enabled = true
	material.emission = plane_color
	material.emission_energy = 0.2
	material.metallic = 0.0
	material.roughness = 1.0

	mesh_instance.material_override = material

func _setup_collision() -> void:
	"""Create collision shape"""
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(plane_size.x, thickness, plane_size.y)
	collision_shape.shape = box_shape
	add_child(collision_shape)

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
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(plane_size.x * 1.05, thickness * 2.0, plane_size.y * 1.05)
	area_collision.shape = box_shape
	area.add_child(area_collision)

	area.body_entered.connect(_on_ball_hit)

func _on_ball_hit(body: Node) -> void:
	"""Handle ball impact - crack at impact point"""
	if has_cracked:
		return

	if not body.is_in_group("throwable"):
		return

	# Get impact velocity
	var impact_velocity = Vector3.ZERO
	if body is RigidBody3D:
		impact_velocity = body.linear_velocity

	# Calculate impact point in local coordinates
	var impact_point_global = body.global_position
	var impact_point_local = to_local(impact_point_global)

	# Project onto plane (XZ plane in local space)
	impact_point_local.y = 0

	_crack_plane_at_point(impact_point_local, impact_velocity)

func _crack_plane_at_point(impact_point_local: Vector3, impact_velocity: Vector3) -> void:
	"""Create Voronoi-style crack pattern centered at impact point"""
	if has_cracked:
		return

	has_cracked = true

	# Emit signal
	plane_cracked.emit(self, impact_point_local, impact_velocity)

	# Show crack effect if enabled
	if show_crack_effect:
		_create_crack_visual(impact_point_local)

	# Generate Voronoi cell centers around impact point
	var voronoi_centers: Array[Vector3] = []

	# Central fragment at impact
	voronoi_centers.append(impact_point_local)

	# Radial pattern around impact
	var rings = 2
	var fragments_per_ring = fragment_count / rings

	for ring in range(1, rings + 1):
		var ring_radius = crack_radius * (float(ring) / float(rings))
		var count = int(fragments_per_ring * ring)

		for i in range(count):
			var angle = (TAU * float(i) / float(count)) + randf_range(-0.2, 0.2)
			var offset = Vector3(
				cos(angle) * ring_radius,
				0,
				sin(angle) * ring_radius
			)
			voronoi_centers.append(impact_point_local + offset)

	# Create fragments
	for i in range(voronoi_centers.size()):
		var fragment = _create_fragment(voronoi_centers[i], impact_point_local, impact_velocity, i)
		get_parent().add_child(fragment)

	# Remove original plane
	_fade_out_and_remove()

func _create_crack_visual(impact_point_local: Vector3) -> void:
	"""Create visual crack lines radiating from impact"""
	var crack_lines = Node3D.new()
	crack_lines.name = "CrackLines"
	crack_lines.position = impact_point_local
	add_child(crack_lines)

	# Create radial crack lines
	for i in range(8):
		var angle = TAU * float(i) / 8.0
		var line = _create_crack_line(angle)
		crack_lines.add_child(line)

func _create_crack_line(angle: float) -> MeshInstance3D:
	"""Create a single crack line"""
	var line = MeshInstance3D.new()

	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.01
	cylinder.bottom_radius = 0.01
	cylinder.height = crack_radius

	line.mesh = cylinder

	var material = StandardMaterial3D.new()
	material.albedo_color = Color.BLACK
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	line.material_override = material

	# Position and rotate
	line.position = Vector3(cos(angle) * crack_radius / 2.0, thickness, sin(angle) * crack_radius / 2.0)
	line.rotation = Vector3(0, 0, PI / 2)  # Horizontal
	line.rotate_y(angle)

	return line

func _create_fragment(center_pos: Vector3, impact_point: Vector3, impact_velocity: Vector3, index: int) -> RigidBody3D:
	"""Create a plane fragment"""
	var fragment = RigidBody3D.new()
	fragment.name = "Fragment_%d" % index

	# Position in world space
	fragment.global_position = to_global(center_pos)
	fragment.global_rotation = global_rotation

	# Calculate fragment size (smaller near impact, larger far away)
	var distance_from_impact = center_pos.distance_to(impact_point)
	var size_factor = 0.15 + (distance_from_impact / crack_radius) * 0.15

	var frag_size = Vector3(
		size_factor * randf_range(0.8, 1.2),
		thickness,
		size_factor * randf_range(0.8, 1.2)
	)

	# Create mesh
	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = frag_size
	mesh_inst.mesh = box_mesh

	# Vary color
	var frag_color = plane_color
	frag_color.v = plane_color.v * randf_range(0.7, 1.0)

	var material = StandardMaterial3D.new()
	material.albedo_color = frag_color
	material.emission_enabled = true
	material.emission = frag_color
	material.emission_energy = 0.1

	mesh_inst.material_override = material
	fragment.add_child(mesh_inst)

	# Add collision
	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = frag_size
	collision.shape = box_shape
	fragment.add_child(collision)

	# Physics
	fragment.mass = 0.05
	fragment.gravity_scale = 1.0

	# Apply impulse away from impact point
	var direction = (center_pos - impact_point).normalized()
	if direction.length() < 0.1:
		direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()

	# Stronger impulse for closer fragments
	var impulse_scale = 1.0 / (distance_from_impact + 0.5)
	var explosion_force = direction * fragment_impulse_strength * impulse_scale
	var inherited_velocity = impact_velocity * 0.1

	fragment.linear_velocity = explosion_force + inherited_velocity + Vector3(0, 1.0, 0)  # Add upward component

	# Add rotation
	fragment.angular_velocity = Vector3(
		randf_range(-4, 4),
		randf_range(-2, 2),
		randf_range(-4, 4)
	)

	# Schedule removal
	_schedule_fragment_removal(fragment, mesh_inst)

	return fragment

func _schedule_fragment_removal(fragment: RigidBody3D, mesh_inst: MeshInstance3D) -> void:
	"""Fade out and remove fragment after delay"""
	await get_tree().create_timer(4.0).timeout

	var tween = create_tween()
	tween.set_parallel(true)

	if mesh_inst.material_override:
		var material = mesh_inst.material_override
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tween.tween_property(material, "albedo_color:a", 0.0, 1.0)

	tween.tween_property(mesh_inst, "scale", Vector3.ZERO, 1.0)
	tween.tween_callback(fragment.queue_free).set_delay(1.0)

func _fade_out_and_remove() -> void:
	"""Remove the original plane"""
	collision_layer = 0
	collision_mask = 0

	var tween = create_tween()
	tween.set_parallel(true)

	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tween.tween_property(material, "albedo_color:a", 0.0, 0.5)

	tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 0.5)
	tween.tween_callback(queue_free).set_delay(0.5)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

