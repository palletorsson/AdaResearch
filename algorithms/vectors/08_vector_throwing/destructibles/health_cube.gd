# health_cube.gd
# Test 2: Static cube with health system - needs 2 hits to destroy
extends StaticBody3D

signal target_hit(target: Node3D, impact_velocity: Vector3, health_remaining: int)
signal target_destroyed(target: Node3D, impact_velocity: Vector3)

@export_group("Target Properties")
@export var cube_size: float = 0.3
@export var target_color: Color = Color(0.3, 0.5, 1.0, 1.0)  # Blue
@export var damaged_color: Color = Color(1.0, 0.5, 0.0, 1.0)  # Orange when damaged
@export var points_value: int = 20
@export var max_health: int = 2

@export_group("Visual Feedback")
@export var show_health_label: bool = true

# State
var current_health: int = 2
var is_destroyed: bool = false

# References
var mesh_instance: MeshInstance3D = null
var collision_shape: CollisionShape3D = null
var area: Area3D = null
var health_label: Label3D = null

func _ready() -> void:
	current_health = max_health
	_setup_visual()
	_setup_collision()
	_setup_hit_detection()
	_setup_health_label()

func _setup_visual() -> void:
	"""Create the cube mesh"""
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	add_child(mesh_instance)

	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(cube_size, cube_size, cube_size)
	mesh_instance.mesh = box_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = target_color
	material.emission_enabled = true
	material.emission = target_color
	material.emission_energy = 0.2
	material.metallic = 0.0
	material.roughness = 1.0

	mesh_instance.material_override = material

func _setup_collision() -> void:
	"""Create collision shape for the cube"""
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(cube_size, cube_size, cube_size)
	collision_shape.shape = box_shape
	add_child(collision_shape)

func _setup_hit_detection() -> void:
	"""Create Area3D for detecting ball impacts"""
	area = Area3D.new()
	area.name = "HitDetectionArea"
	area.monitoring = true
	area.monitorable = true

	# Set collision layers - only detect layer 2 (throwable balls)
	area.collision_layer = 0
	area.collision_mask = 2

	add_child(area)

	var area_collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(cube_size * 1.1, cube_size * 1.1, cube_size * 1.1)
	area_collision.shape = box_shape
	area.add_child(area_collision)

	area.body_entered.connect(_on_body_entered)

func _setup_health_label() -> void:
	"""Create health display label"""
	if not show_health_label:
		return

	health_label = Label3D.new()
	health_label.name = "HealthLabel"
	health_label.text = "HP: %d" % current_health
	health_label.font_size = 24
	health_label.outline_size = 4
	health_label.outline_modulate = Color.BLACK
	health_label.modulate = Color.WHITE
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.position = Vector3(0, cube_size * 0.8, 0)
	add_child(health_label)

func _on_body_entered(body: Node) -> void:
	"""Handle collision - take damage"""
	if body == self or is_destroyed:
		return

	if not body.is_in_group("throwable"):
		return

	# Get impact velocity
	var impact_velocity = Vector3.ZERO
	if body is RigidBody3D:
		impact_velocity = body.linear_velocity

	# Take damage
	_take_damage(impact_velocity)

func _take_damage(impact_velocity: Vector3) -> void:
	"""Reduce health and check for destruction"""
	current_health -= 1

	# Update health label
	if health_label:
		health_label.text = "HP: %d" % current_health

	# Emit hit signal
	target_hit.emit(self, impact_velocity, current_health)

	if current_health <= 0:
		# Destroyed
		is_destroyed = true
		target_destroyed.emit(self, impact_velocity)
		_destroy_with_animation()
	else:
		# Just damaged - show feedback
		_play_damage_animation()

func _play_damage_animation() -> void:
	"""Visual feedback for taking damage"""
	var tween = create_tween()
	tween.set_parallel(true)

	# Change color to show damage
	var current_color = target_color.lerp(damaged_color, 1.0 - float(current_health) / float(max_health))

	if mesh_instance.material_override:
		tween.tween_property(mesh_instance.material_override, "albedo_color", current_color, 0.3)
		tween.tween_property(mesh_instance.material_override, "emission", current_color, 0.3)
		tween.tween_property(mesh_instance.material_override, "emission_energy", 1.0, 0.1)
		tween.tween_property(mesh_instance.material_override, "emission_energy", 0.3, 0.2).set_delay(0.1)

	# Shake
	var original_pos = mesh_instance.position
	tween.tween_property(mesh_instance, "position:x", original_pos.x + 0.05, 0.05)
	tween.tween_property(mesh_instance, "position:x", original_pos.x - 0.05, 0.05).set_delay(0.05)
	tween.tween_property(mesh_instance, "position:x", original_pos.x, 0.05).set_delay(0.1)

func _destroy_with_animation() -> void:
	"""Explode and remove"""
	var tween = create_tween()
	tween.set_parallel(true)

	# Expand and fade
	tween.tween_property(mesh_instance, "scale", Vector3.ONE * 1.5, 0.3)

	if mesh_instance.material_override:
		tween.tween_property(mesh_instance.material_override, "albedo_color:a", 0.0, 0.3)
		tween.tween_property(mesh_instance.material_override, "emission_energy", 2.0, 0.15)

	# Fade health label
	if health_label:
		tween.tween_property(health_label, "modulate:a", 0.0, 0.3)

	# Remove after animation
	tween.tween_callback(queue_free).set_delay(0.3)

func get_points_value() -> int:
	return points_value

func get_current_health() -> int:
	return current_health
