# simple_destroy_cube.gd
# Test 1: Static cube that removes on hit
extends StaticBody3D

signal target_destroyed(target: Node3D, impact_velocity: Vector3)

@export_group("Target Properties")
@export var cube_size: float = 0.3
@export var target_color: Color = Color(1.0, 0.3, 0.3, 1.0)
@export var points_value: int = 10

# References
var mesh_instance: MeshInstance3D = null
var collision_shape: CollisionShape3D = null
var area: Area3D = null

func _ready() -> void:
	_setup_visual()
	_setup_collision()
	_setup_hit_detection()

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

func _on_body_entered(body: Node) -> void:
	"""Handle collision - destroy immediately"""
	print("[SimpleDestroyCube] Body entered: ", body.name, " Groups: ", body.get_groups(), " Layer: ", body.collision_layer if body is CollisionObject3D else "N/A")

	if body == self:
		print("[SimpleDestroyCube] Ignoring self")
		return

	if not body.is_in_group("throwable"):
		print("[SimpleDestroyCube] Not in throwable group, ignoring")
		return

	print("[SimpleDestroyCube] HIT DETECTED!")

	# Get impact velocity
	var impact_velocity = Vector3.ZERO
	if body is RigidBody3D:
		impact_velocity = body.linear_velocity

	# Emit signal
	target_destroyed.emit(self, impact_velocity)

	# Destroy with animation
	_destroy_with_animation()

func _destroy_with_animation() -> void:
	"""Quick shrink and remove"""
	var tween = create_tween()
	tween.set_parallel(true)

	# Shrink to nothing
	tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 0.2)

	# Fade out
	if mesh_instance.material_override:
		tween.tween_property(mesh_instance.material_override, "albedo_color:a", 0.0, 0.2)

	# Remove after animation
	tween.tween_callback(queue_free).set_delay(0.2)

func get_points_value() -> int:
	return points_value

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
