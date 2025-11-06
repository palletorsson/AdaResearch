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

@export_group("Kamikaze Drone")
@export var enable_kamikaze: bool = true  # Enable kamikaze behavior
@export var detection_radius: float = 5.0  # Range to detect and chase player
@export var fly_speed: float = 2.0  # Speed when flying towards player
@export var explosion_radius: float = 1.0  # Distance to trigger explosion
@export var min_damage_percent: float = 20.0  # Minimum damage as % of max health
@export var max_damage_percent: float = 40.0  # Maximum damage as % of max health

# Track parts
var parts: Array[RigidBody3D] = []
var destroyed_parts: int = 0

# Kamikaze drone state
var player_target: Node3D = null  # Can be XROrigin3D or PlayerBody
var is_chasing: bool = false
var has_exploded: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_create_parts_based_tetrahedron()
	if enable_kamikaze:
		_find_player_body()

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

func _find_player_body() -> void:
	"""Find the player target in the scene tree"""
	# First try to find XROrigin3D (VR player root)
	var xr_origin = get_tree().get_first_node_in_group("xr_origin")
	if xr_origin:
		player_target = xr_origin
		print("[KamikazeDrone] Found XROrigin3D: ", player_target.name)
		return

	# Try to find PlayerBody directly
	var nodes = get_tree().get_nodes_in_group("player_body")
	if nodes.size() > 0:
		player_target = nodes[0]
		print("[KamikazeDrone] Found player body: ", player_target.name)
		return

	# Fallback: search for PlayerBody by name
	var root = get_tree().root
	player_target = _find_player_recursive(root)
	if player_target:
		print("[KamikazeDrone] Found player: ", player_target.name)
	else:
		print("[KamikazeDrone] WARNING: Could not find player")

func _find_player_recursive(node: Node) -> Node3D:
	"""Recursively search for player"""
	# Check for XROrigin3D
	if node is XROrigin3D:
		return node

	# Check for PlayerBody
	if "PlayerBody" in node.name or "player" in node.name.to_lower():
		if node is Node3D:
			return node

	for child in node.get_children():
		var result = _find_player_recursive(child)
		if result:
			return result

	return null

func _physics_process(delta: float) -> void:
	"""Kamikaze drone behavior - fly towards player and explode"""
	if not enable_kamikaze or not player_target or parts.is_empty() or has_exploded:
		return

	# Calculate distance to player
	var player_pos = player_target.global_position
	var drone_pos = global_position
	var direction = player_pos - drone_pos
	var distance = direction.length()

	# Check if player is in detection range
	if distance <= detection_radius:
		is_chasing = true

	# If chasing, fly towards player
	if is_chasing:
		# Check if close enough to explode
		if distance <= explosion_radius:
			_kamikaze_explode()
			return

		# Move towards player
		direction = direction.normalized()
		var velocity = direction * fly_speed * delta
		global_position += velocity

		# Rotate to face player
		look_at(player_pos, Vector3.UP)

func _kamikaze_explode() -> void:
	"""Explode and damage player"""
	if has_exploded:
		return

	has_exploded = true
	print("[KamikazeDrone] EXPLODING! Dealing damage to player...")

	# Calculate random damage between min and max percent
	var damage_percent = rng.randf_range(min_damage_percent, max_damage_percent)
	var damage_amount = (damage_percent / 100.0) * GameManager.max_player_health

	# Apply damage to player via GameManager
	GameManager.apply_health_damage(damage_amount)
	print("[KamikazeDrone] Dealt %.1f%% damage (%.1f HP)" % [damage_percent, damage_amount])

	# Trigger visual explosion by destroying all parts
	_explode_all_parts()

	# Remove after explosion animation
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _explode_all_parts() -> void:
	"""Explode all parts outward"""
	var explosion_force = 5.0

	for part in parts.duplicate():  # Duplicate to avoid modification during iteration
		if not is_instance_valid(part):
			continue

		# Unfreeze and apply physics
		part.freeze = false
		part.gravity_scale = 1.0

		# Apply outward explosion force
		var explosion_dir = (part.global_position - global_position).normalized()
		part.apply_central_impulse(explosion_dir * explosion_force)

		# Add random rotation
		part.apply_torque_impulse(Vector3(
			rng.randf_range(-2.0, 2.0),
			rng.randf_range(-2.0, 2.0),
			rng.randf_range(-2.0, 2.0)
		))

		# Get mesh for fade animation
		var mesh_instance = part.get_node_or_null("MeshInstance3D")
		if mesh_instance:
			_fade_out_part(part, mesh_instance)

	# Clear parts array
	parts.clear()
	fully_destroyed.emit(self)

func _fade_out_part(part: RigidBody3D, mesh_instance: MeshInstance3D) -> void:
	"""Fade out a part"""
	if not is_instance_valid(part) or not is_instance_valid(mesh_instance):
		return

	var tween = create_tween()
	tween.set_parallel(true)

	if mesh_instance.material_override:
		var material = mesh_instance.material_override
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var fade_tweener = tween.tween_property(material, "albedo_color:a", 0.0, 1.5)
		var emission_up = tween.tween_property(material, "emission_energy", 3.0, 0.3)
		var emission_down = tween.tween_property(material, "emission_energy", 0.0, 1.2)
		if emission_down:
			emission_down.set_delay(0.3)

	# Shrink
	tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 1.5)

	# Switch to sequential for callback
	tween.chain()
	var callback_tweener = tween.tween_callback(func():
		if is_instance_valid(part):
			part.queue_free()
	)
	if callback_tweener:
		callback_tweener.set_delay(1.5)
