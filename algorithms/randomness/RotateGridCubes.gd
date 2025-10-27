extends Node3D

## RotateGridCubes.gd
## Selects all cubes in the 'grid_cubes' group and rotates them
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

# Internal
var target_rotation_degrees: Vector3 = Vector3.ZERO

func _ready():
	# Build target rotation from Z, X, Y components
	target_rotation_degrees = Vector3(rotation_x_degrees, rotation_y_degrees, rotation_z_degrees)

	if rotate_on_ready:
		rotate_all_cubes()

func rotate_all_cubes():
	"""Rotate all cubes in the grid_cubes group"""
	var all_cubes = get_tree().get_nodes_in_group("grid_cubes")

	if all_cubes.size() == 0:
		print("RotateGridCubes: No cubes found in 'grid_cubes' group")
		return

	print("RotateGridCubes: Rotating %d cubes (Z=%s°, X=%s°, Y=%s°)" % [
		all_cubes.size(),
		rotation_z_degrees,
		rotation_x_degrees,
		rotation_y_degrees
	])

	for cube in all_cubes:
		if cube is Node3D:
			if use_animation:
				animate_rotation(cube)
			else:
				apply_instant_rotation(cube)

			# Add continuous rotation if enabled
			if continuous_rotation_z or continuous_rotation_x or continuous_rotation_y:
				add_continuous_rotation(cube)

	print("RotateGridCubes: Rotation complete")

func apply_instant_rotation(cube: Node3D):
	"""Apply rotation instantly"""
	cube.rotation_degrees = target_rotation_degrees

func animate_rotation(cube: Node3D):
	"""Animate rotation with a tween"""
	var tween = create_tween()
	tween.tween_property(cube, "rotation_degrees", target_rotation_degrees, rotation_duration)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

func add_continuous_rotation(cube: Node3D):
	"""Add continuous rotation script to a cube"""
	if not cube:
		return

	# Create a continuous rotation script
	var script_text = """
extends Node3D

var rotation_speed_z: float = %s
var rotation_speed_x: float = %s
var rotation_speed_y: float = %s

func _process(delta: float) -> void:
	if rotation_speed_z != 0.0:
		rotate_object_local(Vector3(0, 0, 1), deg_to_rad(rotation_speed_z * delta))
	if rotation_speed_x != 0.0:
		rotate_object_local(Vector3(1, 0, 0), deg_to_rad(rotation_speed_x * delta))
	if rotation_speed_y != 0.0:
		rotate_object_local(Vector3(0, 1, 0), deg_to_rad(rotation_speed_y * delta))
""" % [
		rotation_speed_z if continuous_rotation_z else 0.0,
		rotation_speed_x if continuous_rotation_x else 0.0,
		rotation_speed_y if continuous_rotation_y else 0.0
	]

	var script = GDScript.new()
	script.source_code = script_text
	script.reload()

	cube.set_script(script)

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
	# Re-apply to all cubes
	rotate_all_cubes()

func reset_rotation():
	"""Reset all cubes to zero rotation"""
	rotation_z_degrees = 0.0
	rotation_x_degrees = 0.0
	rotation_y_degrees = 0.0
	target_rotation_degrees = Vector3.ZERO
	rotate_all_cubes()
