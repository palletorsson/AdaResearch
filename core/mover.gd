class_name Mover
extends VREntity

## Mover class for Nature of Code VR - Chapter 02: Forces
## Object that responds to forces with proper physics (F = ma)
## Can be used standalone or extended for specific behaviors

# Mover-specific properties
var bounce_damping: float = 0.8  # Energy loss on bounce (0-1)

func _init():
	mass = 1.0
	position_v = Vector3.ZERO
	velocity = Vector3.ZERO
	acceleration = Vector3.ZERO

func _ready():
	super()

func check_boundaries():
	"""Bounce off tank boundaries"""
	if not fish_tank:
		return

	var half_size = fish_tank.tank_size / 2.0

	# X boundaries
	if position_v.x > half_size:
		position_v.x = half_size
		velocity.x *= -bounce_damping
	elif position_v.x < -half_size:
		position_v.x = -half_size
		velocity.x *= -bounce_damping

	# Y boundaries
	if position_v.y > half_size:
		position_v.y = half_size
		velocity.y *= -bounce_damping
	elif position_v.y < -half_size:
		position_v.y = -half_size
		velocity.y *= -bounce_damping

	# Z boundaries
	if position_v.z > half_size:
		position_v.z = half_size
		velocity.z *= -bounce_damping
	elif position_v.z < -half_size:
		position_v.z = -half_size
		velocity.z *= -bounce_damping

func setup_mesh():
	"""Create sphere mesh for mover"""
	mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	mesh_instance.mesh = sphere
	add_child(mesh_instance)

func set_size(radius: float):
	"""Set mover size"""
	if mesh_instance and mesh_instance.mesh is SphereMesh:
		mesh_instance.mesh.radius = radius
		mesh_instance.mesh.height = radius * 2
