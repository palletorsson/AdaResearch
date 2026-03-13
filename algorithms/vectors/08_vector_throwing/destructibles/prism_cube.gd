# prism_cube.gd
# Test 8: Window-sized cube built from individual destructible prisms
# Only the prisms that are hit get destroyed
extends Node3D

signal prism_destroyed(prism: Node3D, impact_velocity: Vector3)
signal cube_fully_destroyed(cube: Node3D)

@export_group("Cube Properties")
@export var cube_size: Vector3 = Vector3(1.0, 1.0, 0.2)  # Window-like dimensions
@export var prisms_per_side: Vector3i = Vector3i(5, 5, 2)  # Grid resolution
@export var prism_gap: float = 0.01  # Small gap between prisms
@export var base_color: Color = Color(0.7, 0.9, 1.0, 0.8)  # Light blue glass-like
@export var enable_transparency: bool = true

@export_group("Destruction")
@export var prism_health: int = 1  # Hits required to destroy each prism
@export var destruction_impulse: float = 2.0
@export var enable_physics_on_destroy: bool = true

# Track prisms
var prisms: Array[Node3D] = []
var prism_data: Dictionary = {}  # prism -> health
var destroyed_count: int = 0

class PrismData:
	var mesh_instance: MeshInstance3D
	var area: Area3D
	var current_health: int
	var grid_position: Vector3i

	func _init(mesh: MeshInstance3D, area_node: Area3D, health: int, grid_pos: Vector3i) -> void:
		mesh_instance = mesh
		area = area_node
		current_health = health
		grid_position = grid_pos

func _ready() -> void:
	_build_prism_cube()

func _build_prism_cube() -> void:
	"""Build a cube from individual prism pieces"""

	# Calculate individual prism size
	var prism_size = Vector3(
		(cube_size.x / prisms_per_side.x) - prism_gap,
		(cube_size.y / prisms_per_side.y) - prism_gap,
		(cube_size.z / prisms_per_side.z) - prism_gap
	)

	# Create container for prisms
	var prisms_container = Node3D.new()
	prisms_container.name = "Prisms"
	add_child(prisms_container)

	# Build grid of prisms
	for x in range(prisms_per_side.x):
		for y in range(prisms_per_side.y):
			for z in range(prisms_per_side.z):
				var grid_pos = Vector3i(x, y, z)
				var prism = _create_prism(prism_size, grid_pos)
				prisms_container.add_child(prism)
				prisms.append(prism)

func _create_prism(prism_size: Vector3, grid_pos: Vector3i) -> Node3D:
	"""Create a single prism piece"""
	var prism_root = Node3D.new()
	prism_root.name = "Prism_%d_%d_%d" % [grid_pos.x, grid_pos.y, grid_pos.z]

	# Calculate position in grid
	var step_size = Vector3(
		cube_size.x / prisms_per_side.x,
		cube_size.y / prisms_per_side.y,
		cube_size.z / prisms_per_side.z
	)

	var local_pos = Vector3(
		(grid_pos.x - prisms_per_side.x / 2.0 + 0.5) * step_size.x,
		(grid_pos.y - prisms_per_side.y / 2.0 + 0.5) * step_size.y,
		(grid_pos.z - prisms_per_side.z / 2.0 + 0.5) * step_size.z
	)

	prism_root.position = local_pos

	# Create mesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Mesh"

	var box_mesh = BoxMesh.new()
	box_mesh.size = prism_size
	mesh_instance.mesh = box_mesh

	# Create material with variation
	var color_variation = randf_range(-0.1, 0.1)
	var prism_color = base_color
	prism_color.v = clamp(base_color.v + color_variation, 0.0, 1.0)

	var material = StandardMaterial3D.new()
	material.albedo_color = prism_color
	material.emission_enabled = true
	material.emission = prism_color * 0.2
	material.emission_energy = 0.2
	material.metallic = 0.0
	material.roughness = 1.0

	# Glass-like transparency
	if enable_transparency:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.6

	mesh_instance.material_override = material
	prism_root.add_child(mesh_instance)

	# Create hit detection area
	var area = Area3D.new()
	area.name = "HitArea"
	area.monitoring = true
	area.monitorable = true
	area.collision_layer = 0
	area.collision_mask = 2  # Detect throwable balls

	var area_collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = prism_size * 1.05  # Slightly larger for detection
	area_collision.shape = box_shape
	area.add_child(area_collision)

	prism_root.add_child(area)

	# Store prism data
	var data = PrismData.new(mesh_instance, area, prism_health, grid_pos)
	prism_data[prism_root] = data

	# Connect hit detection
	area.body_entered.connect(_on_prism_hit.bind(prism_root))

	return prism_root

func _on_prism_hit(body: Node, prism: Node3D) -> void:
	"""Handle when a prism is hit"""
	if not body.is_in_group("throwable"):
		return

	if prism not in prism_data:
		return  # Already destroyed

	var data: PrismData = prism_data[prism]

	# Get impact velocity
	var impact_velocity = Vector3.ZERO
	if body is RigidBody3D:
		impact_velocity = body.linear_velocity

	# Take damage
	data.current_health -= 1

	if data.current_health <= 0:
		# Destroy this prism
		_destroy_prism(prism, data, impact_velocity)
	else:
		# Show damage feedback
		_show_prism_damage(data)

func _show_prism_damage(data: PrismData) -> void:
	"""Visual feedback for damaged but not destroyed prism"""
	var mesh = data.mesh_instance

	# Flash effect
	var tween = create_tween()
	tween.set_parallel(true)

	if mesh.material_override:
		var material = mesh.material_override
		tween.tween_property(material, "emission_energy", 1.0, 0.1)
		tween.tween_property(material, "emission_energy", 0.2, 0.2).set_delay(0.1)

	# Shake
	var original_pos = mesh.position
	tween.tween_property(mesh, "position:x", original_pos.x + 0.01, 0.05)
	tween.tween_property(mesh, "position:x", original_pos.x - 0.01, 0.05).set_delay(0.05)
	tween.tween_property(mesh, "position:x", original_pos.x, 0.05).set_delay(0.1)

func _destroy_prism(prism: Node3D, data: PrismData, impact_velocity: Vector3) -> void:
	"""Destroy individual prism"""

	# Remove from tracking
	prisms.erase(prism)
	prism_data.erase(prism)
	destroyed_count += 1

	# Emit signal
	prism_destroyed.emit(prism, impact_velocity)

	if enable_physics_on_destroy:
		# Convert to physics object and apply force
		_convert_to_rigid_body(prism, data, impact_velocity)
	else:
		# Just fade out and remove
		_fade_out_prism(prism, data.mesh_instance)

	# Check if fully destroyed
	if prisms.is_empty():
		cube_fully_destroyed.emit(self)
		# Remove parent after delay
		await get_tree().create_timer(3.0).timeout
		queue_free()

func _convert_to_rigid_body(prism: Node3D, data: PrismData, impact_velocity: Vector3) -> void:
	"""Convert static prism to physics object"""

	# Get world position before reparenting
	var world_pos = prism.global_position
	var world_rot = prism.global_rotation

	# Create RigidBody3D
	var rigid_body = RigidBody3D.new()
	rigid_body.name = prism.name + "_Physics"
	rigid_body.global_position = world_pos
	rigid_body.global_rotation = world_rot
	rigid_body.mass = 0.1

	# Move mesh to rigid body
	prism.remove_child(data.mesh_instance)
	rigid_body.add_child(data.mesh_instance)
	data.mesh_instance.position = Vector3.ZERO

	# Add collision shape
	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	if data.mesh_instance.mesh is BoxMesh:
		box_shape.size = (data.mesh_instance.mesh as BoxMesh).size
	collision.shape = box_shape
	rigid_body.add_child(collision)

	# Add to scene
	get_parent().add_child(rigid_body)

	# Apply physics
	var impact_direction = impact_velocity.normalized()
	var force = impact_direction * destruction_impulse
	rigid_body.linear_velocity = force + impact_velocity * 0.3
	rigid_body.angular_velocity = Vector3(
		randf_range(-5, 5),
		randf_range(-5, 5),
		randf_range(-5, 5)
	)

	# Remove original prism node
	prism.queue_free()

	# Schedule cleanup
	_schedule_rigid_body_removal(rigid_body, data.mesh_instance)

func _fade_out_prism(prism: Node3D, mesh_instance: MeshInstance3D) -> void:
	"""Fade out and remove prism"""
	var tween = create_tween()
	tween.set_parallel(true)

	if mesh_instance.material_override:
		var material = mesh_instance.material_override
		if not enable_transparency:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tween.tween_property(material, "albedo_color:a", 0.0, 0.5)
		tween.tween_property(material, "emission_energy", 2.0, 0.1)
		tween.tween_property(material, "emission_energy", 0.0, 0.4).set_delay(0.1)

	tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 0.5)
	tween.tween_callback(prism.queue_free).set_delay(0.5)

func _schedule_rigid_body_removal(rigid_body: RigidBody3D, mesh_instance: MeshInstance3D) -> void:
	"""Remove fallen prism after delay"""
	await get_tree().create_timer(4.0).timeout

	var tween = create_tween()
	tween.set_parallel(true)

	if mesh_instance.material_override:
		var material = mesh_instance.material_override
		if not enable_transparency:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tween.tween_property(material, "albedo_color:a", 0.0, 1.0)

	tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 1.0)
	tween.tween_callback(rigid_body.queue_free).set_delay(1.0)

func get_prisms_remaining() -> int:
	return prisms.size()

func get_total_destroyed() -> int:
	return destroyed_count

func get_destruction_percentage() -> float:
	var total = destroyed_count + prisms.size()
	if total == 0:
		return 0.0
	return (float(destroyed_count) / float(total)) * 100.0

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

