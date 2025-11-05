# destructible_truncated_tetrahedron.gd
# Test 4: Build truncated tetrahedron from parts that can be destroyed on collision
extends Node3D

signal part_destroyed(part: Node3D, impact_velocity: Vector3)
signal fully_destroyed(target: Node3D)

@export_group("Target Properties")
@export var part_size: float = 0.15
@export var base_color: Color = Color(1.0, 0.5, 0.0, 1.0)
@export var points_per_part: int = 5
@export var enable_physics: bool = true

# Track parts
var parts: Array[RigidBody3D] = []
var destroyed_parts: int = 0

func _ready() -> void:
	_create_parts_based_tetrahedron()

func _create_parts_based_tetrahedron() -> void:
	"""Create a truncated tetrahedron made of individual destructible parts"""

	# Vertices for a truncated tetrahedron (simplified)
	var vertices = [
		Vector3(0.2, 0.2, 0.2),
		Vector3(-0.2, -0.2, 0.2),
		Vector3(-0.2, 0.2, -0.2),
		Vector3(0.2, -0.2, -0.2),
		# Truncated corners
		Vector3(0.1, 0.1, -0.1),
		Vector3(-0.1, -0.1, -0.1),
		Vector3(-0.1, 0.1, 0.1),
		Vector3(0.1, -0.1, 0.1)
	]

	# Create a small cube part at each vertex
	for i in range(vertices.size()):
		var part = _create_part(vertices[i], i)
		parts.append(part)
		add_child(part)

	# Also create parts at face centers
	var face_centers = [
		Vector3(0, 0.15, 0),
		Vector3(0, -0.15, 0),
		Vector3(0.15, 0, 0),
		Vector3(-0.15, 0, 0),
	]

	for i in range(face_centers.size()):
		var part = _create_part(face_centers[i], vertices.size() + i)
		parts.append(part)
		add_child(part)

func _create_part(pos: Vector3, index: int) -> RigidBody3D:
	"""Create an individual destructible part"""
	var part = RigidBody3D.new()
	part.name = "Part_%d" % index
	part.position = pos

	if enable_physics:
		part.mass = 0.1
		part.gravity_scale = 0.0  # No gravity until destroyed
		part.freeze = true  # Start frozen
	else:
		part.freeze = true

	# Create mesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"

	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(part_size, part_size, part_size)
	mesh_instance.mesh = box_mesh

	# Create material with color variation
	var hue_offset = float(index) / 12.0
	var color = base_color
	color.h = fmod(color.h + hue_offset * 0.3, 1.0)

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy = 0.4

	mesh_instance.material_override = material
	part.add_child(mesh_instance)

	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(part_size, part_size, part_size)
	collision_shape.shape = box_shape
	part.add_child(collision_shape)

	# Create hit detection area
	var area = Area3D.new()
	area.name = "HitDetectionArea"
	area.monitoring = true
	area.monitorable = true
	area.collision_layer = 0
	area.collision_mask = 2  # Detect throwable balls

	var area_collision = CollisionShape3D.new()
	var area_box_shape = BoxShape3D.new()
	area_box_shape.size = Vector3(part_size * 1.1, part_size * 1.1, part_size * 1.1)
	area_collision.shape = area_box_shape
	area.add_child(area_collision)

	part.add_child(area)

	# Connect hit detection
	area.body_entered.connect(_on_part_hit.bind(part, mesh_instance))

	return part

func _on_part_hit(body: Node, part: RigidBody3D, mesh_instance: MeshInstance3D) -> void:
	"""Handle when a part is hit"""
	if not body.is_in_group("throwable"):
		return

	if part not in parts:
		return  # Already destroyed

	# Get impact velocity
	var impact_velocity = Vector3.ZERO
	if body is RigidBody3D:
		impact_velocity = body.linear_velocity

	# Remove from tracking
	parts.erase(part)
	destroyed_parts += 1

	# Emit signal
	part_destroyed.emit(part, impact_velocity)

	# Animate destruction
	_destroy_part(part, mesh_instance, impact_velocity)

	# Check if fully destroyed
	if parts.is_empty():
		fully_destroyed.emit(self)
		# Wait a bit before removing parent
		await get_tree().create_timer(2.0).timeout
		queue_free()

func _destroy_part(part: RigidBody3D, mesh_instance: MeshInstance3D, impact_velocity: Vector3) -> void:
	"""Destroy individual part with physics"""

	# Unfreeze and apply physics
	part.freeze = false
	part.gravity_scale = 1.0

	# Apply impact force
	if impact_velocity.length() > 0:
		part.apply_central_impulse(impact_velocity * 0.3)
		# Add some random rotation
		part.apply_torque_impulse(Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5)
		))

	# Animate fade out
	var tween = create_tween()
	tween.set_parallel(true)

	if mesh_instance.material_override:
		var material = mesh_instance.material_override
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tween.tween_property(material, "albedo_color:a", 0.0, 1.0)
		tween.tween_property(material, "emission_energy", 2.0, 0.2)
		tween.tween_property(material, "emission_energy", 0.0, 0.8).set_delay(0.2)

	# Shrink
	tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 1.0)

	# Remove after animation
	tween.tween_callback(part.queue_free).set_delay(1.0)

func get_parts_remaining() -> int:
	return parts.size()

func get_total_destroyed() -> int:
	return destroyed_parts
