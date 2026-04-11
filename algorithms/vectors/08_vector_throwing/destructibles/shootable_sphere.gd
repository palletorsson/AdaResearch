# shootable_sphere.gd
# Simple sphere that can be picked up by gravity gun and shot at targets
extends RigidBody3D

@export_group("Sphere Properties")
@export var sphere_radius: float = 0.05
@export var sphere_color: Color = Color(1.0, 0.7, 0.3, 1.0)  # Orange
@export var sphere_mass: float = 0.5

@export_group("Visual Feedback")
@export var show_trail: bool = false
@export var emit_on_high_speed: bool = true
@export var glow_threshold: float = 2.0  # Speed to start glowing

# State
var is_moving_fast: bool = false
var mesh_instance: MeshInstance3D = null
var original_material: StandardMaterial3D = null

func _ready() -> void:
	setup_physics()
	setup_visual()

	# Add to throwable group
	add_to_group("throwable")

func setup_physics() -> void:
	"""Configure physics properties"""
	mass = sphere_mass
	gravity_scale = 1.0
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 4

	# Set collision layers - layer 2 for throwable objects
	collision_layer = 2
	collision_mask = 1 | 4  # Collide with world (1) and targets (4)

func setup_visual() -> void:
	"""Create sphere mesh and material"""
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	add_child(mesh_instance)

	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = sphere_radius
	sphere_mesh.height = sphere_radius * 2
	mesh_instance.mesh = sphere_mesh

	# Create material
	original_material = StandardMaterial3D.new()
	original_material.albedo_color = sphere_color
	original_material.metallic = 0.3
	original_material.roughness = 0.7
	original_material.emission_enabled = true
	original_material.emission = sphere_color * 0.2
	original_material.emission_energy_multiplier = 0.3

	mesh_instance.material_override = original_material

	# Add collision shape
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = sphere_radius
	collision_shape.shape = sphere_shape
	add_child(collision_shape)

func _physics_process(_delta: float) -> void:
	"""Update visual effects based on velocity"""
	if not emit_on_high_speed or not original_material:
		return

	var speed = linear_velocity.length()

	if speed > glow_threshold:
		if not is_moving_fast:
			is_moving_fast = true
			_start_glow()
	else:
		if is_moving_fast:
			is_moving_fast = false
			_stop_glow()

func _start_glow() -> void:
	"""Increase glow when moving fast"""
	if not original_material:
		return

	var tween = create_tween()
	tween.tween_property(original_material, "emission_energy_multiplier", 1.5, 0.3)

func _stop_glow() -> void:
	"""Reduce glow when slowing down"""
	if not original_material:
		return

	var tween = create_tween()
	tween.tween_property(original_material, "emission_energy_multiplier", 0.3, 0.5)

func _on_body_entered(_body: Node) -> void:
	"""Handle collision feedback"""
	# Add impact effects here if desired
	pass

func set_sphere_color(color: Color) -> void:
	"""Change sphere color"""
	sphere_color = color
	if original_material:
		original_material.albedo_color = color
		original_material.emission = color * 0.2

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
