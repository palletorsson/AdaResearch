extends Node3D

## RotateGridCubes.gd
## Rotates all MultiMesh instances
## Syntax: Z, X, Y rotation in degrees, then Z, X, Y continuous rotation flags

# Initial rotation configuration (Z, X, Y order)
@export_group("Initial Rotation")
@export var rotation_z_degrees: float = 0.0  # Rotation around Z axis (roll)
@export var rotation_x_degrees: float = 45.0  # Rotation around X axis (pitch)
@export var rotation_y_degrees: float = 0.0  # Rotation around Y axis (yaw)

# Continuous rotation configuration
@export_group("Continuous Rotation")
@export var continuous_rotation_z: bool = false  # Spin on Z axis
@export var continuous_rotation_x: bool = false  # Spin on X axis
@export var continuous_rotation_y: bool = false  # Spin on Y axis
@export var rotation_speed_z: float = 30.0  # Degrees per second
@export var rotation_speed_x: float = 30.0  # Degrees per second
@export var rotation_speed_y: float = 30.0  # Degrees per second

# Animation settings
@export_group("Animation")
@export var rotate_on_ready: bool = true
@export var rotation_duration: float = 1.0  # Animation duration in seconds
@export var use_animation: bool = true

@export_group("MultiMesh")
@export var multimesh_path: NodePath = "../GridMultiMesh"

# Internal
var target_rotation_degrees: Vector3 = Vector3.ZERO
var multimesh_instance: MultiMeshInstance3D = null
var multimesh: MultiMesh = null
var animation_tween: Tween = null
var initial_transforms: Array[Transform3D] = []

func _ready():
	# Build target rotation from Z, X, Y components
	target_rotation_degrees = Vector3(rotation_x_degrees, rotation_y_degrees, rotation_z_degrees)

	# Find MultiMesh
	if not multimesh_path.is_empty():
		multimesh_instance = get_node_or_null(multimesh_path)

	if not multimesh_instance:
		multimesh_instance = _find_multimesh_instance(get_parent())

	if multimesh_instance:
		multimesh = multimesh_instance.multimesh
		if multimesh and multimesh.instance_count > 0:
			print("✅ Found MultiMesh with %d instances" % multimesh.instance_count)

			# Store initial transforms
			for i in range(multimesh.instance_count):
				initial_transforms.append(multimesh.get_instance_transform(i))

			if rotate_on_ready:
				rotate_all_cubes()
		else:
			push_warning("MultiMesh found but has no instances")
	else:
		push_warning("Could not find MultiMeshInstance3D")

func _find_multimesh_instance(node: Node) -> MultiMeshInstance3D:
	if node is MultiMeshInstance3D:
		return node
	for child in node.get_children():
		var result = _find_multimesh_instance(child)
		if result:
			return result
	return null

func rotate_all_cubes():
	"""Rotate all cubes in the MultiMesh"""
	if not multimesh:
		print("RotateGridCubes: No MultiMesh found")
		return

	print("RotateGridCubes: Rotating %d instances (Z=%s°, X=%s°, Y=%s°)" % [
		multimesh.instance_count,
		rotation_z_degrees,
		rotation_x_degrees,
		rotation_y_degrees
	])

	if use_animation:
		animate_rotation()
	else:
		apply_instant_rotation()

	print("RotateGridCubes: Rotation complete")

func apply_instant_rotation():
	"""Apply rotation instantly to all instances"""
	if not multimesh:
		return

	var rot_basis = Basis()
	rot_basis = rot_basis.rotated(Vector3.BACK, deg_to_rad(rotation_z_degrees))
	rot_basis = rot_basis.rotated(Vector3.RIGHT, deg_to_rad(rotation_x_degrees))
	rot_basis = rot_basis.rotated(Vector3.UP, deg_to_rad(rotation_y_degrees))

	for i in range(multimesh.instance_count):
		var transform = initial_transforms[i] if i < initial_transforms.size() else multimesh.get_instance_transform(i)
		transform.basis = rot_basis * Basis()
		multimesh.set_instance_transform(i, transform)

func animate_rotation():
	"""Animate rotation with interpolation"""
	if not multimesh or animation_tween:
		return

	animation_tween = create_tween()
	var start_rot = Vector3.ZERO
	var target_rot = target_rotation_degrees

	animation_tween.tween_method(func(progress: float):
		var current_rot = start_rot.lerp(target_rot, progress)

		var rot_basis = Basis()
		rot_basis = rot_basis.rotated(Vector3.BACK, deg_to_rad(current_rot.z))
		rot_basis = rot_basis.rotated(Vector3.RIGHT, deg_to_rad(current_rot.x))
		rot_basis = rot_basis.rotated(Vector3.UP, deg_to_rad(current_rot.y))

		for i in range(multimesh.instance_count):
			var transform = initial_transforms[i] if i < initial_transforms.size() else Transform3D()
			transform.basis = rot_basis * Basis()
			multimesh.set_instance_transform(i, transform)
	, 0.0, 1.0, rotation_duration)

	animation_tween.set_ease(Tween.EASE_IN_OUT)
	animation_tween.set_trans(Tween.TRANS_CUBIC)
	animation_tween.finished.connect(func(): animation_tween = null)

func _process(delta: float) -> void:
	if not multimesh:
		return

	# Handle continuous rotation
	if continuous_rotation_z or continuous_rotation_x or continuous_rotation_y:
		for i in range(multimesh.instance_count):
			var transform = multimesh.get_instance_transform(i)

			if continuous_rotation_z:
				transform.basis = transform.basis.rotated(Vector3.BACK, deg_to_rad(rotation_speed_z * delta))
			if continuous_rotation_x:
				transform.basis = transform.basis.rotated(Vector3.RIGHT, deg_to_rad(rotation_speed_x * delta))
			if continuous_rotation_y:
				transform.basis = transform.basis.rotated(Vector3.UP, deg_to_rad(rotation_speed_y * delta))

			multimesh.set_instance_transform(i, transform)

# Public API for manual control

func rotate_cubes_instant_zxy(z: float, x: float, y: float):
	"""Rotate all cubes instantly to specified degrees (Z, X, Y order)"""
	rotation_z_degrees = z
	rotation_x_degrees = x
	rotation_y_degrees = y
	target_rotation_degrees = Vector3(x, y, z)
	use_animation = false
	rotate_all_cubes()

func rotate_cubes_animated_zxy(z: float, x: float, y: float, duration: float = 1.0):
	"""Rotate all cubes with animation to specified degrees (Z, X, Y order)"""
	rotation_z_degrees = z
	rotation_x_degrees = x
	rotation_y_degrees = y
	target_rotation_degrees = Vector3(x, y, z)
	rotation_duration = duration
	use_animation = true
	rotate_all_cubes()

func set_continuous_rotation(cont_z: bool, cont_x: bool, cont_y: bool):
	"""Enable/disable continuous rotation on specified axes"""
	continuous_rotation_z = cont_z
	continuous_rotation_x = cont_x
	continuous_rotation_y = cont_y

func reset_rotation():
	"""Reset all cubes to zero rotation"""
	rotation_z_degrees = 0.0
	rotation_x_degrees = 0.0
	rotation_y_degrees = 0.0
	target_rotation_degrees = Vector3.ZERO
	rotate_all_cubes()
