# cantor_recursion_box.gd
# Test 5: Box with 2 stages of Cantor recursion
# - When hit by ball: splits into 4 boxes
# - When those boxes hit ground: each splits into 4 more boxes
extends RigidBody3D

signal box_split(parent_box: Node3D, children: Array)

@export_group("Box Properties")
@export var box_size: float = 0.4
@export var box_color: Color = Color(0.5, 1.0, 0.3, 1.0)  # Green
@export var recursion_level: int = 0  # 0 = original, 1 = first split, 2 = final split
@export var max_recursion: int = 2
@export var split_impulse_strength: float = 2.0

@export_group("Behavior")
@export var split_on_ball_hit: bool = true
@export var split_on_ground_hit: bool = true

# State
var has_split: bool = false
var is_ground_collision_enabled: bool = false

# References
var mesh_instance: MeshInstance3D = null
var collision_shape: CollisionShape3D = null
var area: Area3D = null

func _ready() -> void:
	_setup_visual()
	_setup_collision()
	_setup_physics()

	# Level 1+ boxes should split on ground hit
	if recursion_level > 0:
		is_ground_collision_enabled = true
		body_entered.connect(_on_body_collision)
	else:
		# Level 0 uses area detection for ball hits
		_setup_hit_detection()

func _setup_visual() -> void:
	"""Create the cube mesh"""
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	add_child(mesh_instance)

	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(box_size, box_size, box_size)
	mesh_instance.mesh = box_mesh

	# Color varies by recursion level
	var level_color = box_color
	level_color.h = fmod(box_color.h + (recursion_level * 0.15), 1.0)

	var material = StandardMaterial3D.new()
	material.albedo_color = level_color
	material.emission_enabled = true
	material.emission = level_color
	material.emission_energy = 0.3

	mesh_instance.material_override = material

func _setup_collision() -> void:
	"""Create collision shape"""
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(box_size, box_size, box_size)
	collision_shape.shape = box_shape
	add_child(collision_shape)

func _setup_physics() -> void:
	"""Configure physics properties"""
	mass = 0.5 * pow(0.25, recursion_level)  # Lighter at higher recursion
	contact_monitor = true
	max_contacts_reported = 4

	if recursion_level == 0:
		# Start static (frozen)
		freeze = true
		gravity_scale = 0.0
	else:
		# Split boxes have physics
		freeze = false
		gravity_scale = 1.0

func _setup_hit_detection() -> void:
	"""Create Area3D for detecting ball impacts (level 0 only)"""
	area = Area3D.new()
	area.name = "HitDetectionArea"
	area.monitoring = true
	area.monitorable = true
	area.collision_layer = 0
	area.collision_mask = 2  # Detect throwable balls

	add_child(area)

	var area_collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(box_size * 1.1, box_size * 1.1, box_size * 1.1)
	area_collision.shape = box_shape
	area.add_child(area_collision)

	area.body_entered.connect(_on_ball_hit)

func _on_ball_hit(body: Node) -> void:
	"""Handle ball impact (level 0)"""
	if has_split:
		return

	if not body.is_in_group("throwable"):
		return

	if not split_on_ball_hit:
		return

	# Get impact velocity for impulse
	var impact_velocity = Vector3.ZERO
	if body is RigidBody3D:
		impact_velocity = body.linear_velocity

	_split_into_four(impact_velocity)

func _on_body_collision(body: Node) -> void:
	"""Handle ground collision (level 1+)"""
	if has_split:
		return

	if recursion_level >= max_recursion:
		return

	if not split_on_ground_hit:
		return

	# Check if it's ground (not another box or ball)
	if body.is_in_group("throwable"):
		return

	# Split on ground impact
	_split_into_four(linear_velocity)

func _split_into_four(impact_velocity: Vector3) -> void:
	"""Split this box into 4 smaller boxes (Cantor set style)"""
	if has_split:
		return

	has_split = true

	var children: Array = []

	# Create 4 boxes in Cantor pattern (removing middle third in each dimension)
	# We'll create boxes at the corners of a 2x2 grid
	var child_size = box_size / 3.0  # Each child is 1/3 the size
	var offset = box_size / 3.0  # Distance from center

	var positions = [
		Vector3(-offset, -offset, 0),  # Bottom-left
		Vector3(offset, -offset, 0),   # Bottom-right
		Vector3(-offset, offset, 0),   # Top-left
		Vector3(offset, offset, 0),    # Top-right
	]

	# Create child boxes
	for i in range(4):
		var child = _create_child_box(child_size, positions[i], impact_velocity)
		children.append(child)
		get_parent().add_child(child)

	# Emit signal
	box_split.emit(self, children)

	# Fade out and remove parent
	_fade_out_and_remove()

func _create_child_box(child_size: float, offset: Vector3, impact_velocity: Vector3) -> Node3D:
	"""Create a child box at the next recursion level"""
	var child_scene = load("res://algorithms/vectors/08_vector_throwing/destructibles/cantor_recursion_box.tscn")

	var child: RigidBody3D
	if child_scene:
		child = child_scene.instantiate()
	else:
		# Fallback: create from script
		child = load("res://algorithms/vectors/08_vector_throwing/destructibles/cantor_recursion_box.gd").new()

	child.box_size = child_size
	child.box_color = box_color
	child.recursion_level = recursion_level + 1
	child.max_recursion = max_recursion

	# Position in world space
	child.global_position = global_position + offset.rotated(Vector3.UP, global_rotation.y)

	# Apply impulse in direction of offset + some of the impact
	if child is RigidBody3D:
		child.freeze = false
		child.gravity_scale = 1.0

		# Apply initial velocity
		var split_direction = offset.normalized()
		var split_force = split_direction * split_impulse_strength
		var inherited_velocity = impact_velocity * 0.3

		# Wait one frame before applying impulse
		child.linear_velocity = split_force + inherited_velocity

		# Add some rotation
		child.angular_velocity = Vector3(
			randf_range(-3, 3),
			randf_range(-3, 3),
			randf_range(-3, 3)
		)

	return child

func _fade_out_and_remove() -> void:
	"""Fade out and remove the parent box"""
	# Disable collision
	collision_layer = 0
	collision_mask = 0

	var tween = create_tween()
	tween.set_parallel(true)

	# Fade out
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tween.tween_property(material, "albedo_color:a", 0.0, 0.5)

	# Shrink
	tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 0.5)

	# Remove
	tween.tween_callback(queue_free).set_delay(0.5)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
