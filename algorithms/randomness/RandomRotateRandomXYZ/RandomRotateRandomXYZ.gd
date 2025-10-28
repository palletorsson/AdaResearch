extends Node3D
## RotateRandomZXY.gd
## Randomly rotates cubes in "grid_cubes" group on Z, X, and Y each frame

@export var group_name: String = "grid_cubes"

# Initial random rotation ranges (applied once on _ready)
@export var min_z_degrees: float = -0.01
@export var max_z_degrees: float =  0.01
@export var min_x_degrees: float = -0.01
@export var max_x_degrees: float =  0.01
@export var min_y_degrees: float = -0.01
@export var max_y_degrees: float =  0.01

# Per-frame random rotation step ranges
@export var min_step_z: float = -2.0
@export var max_step_z: float =  2.0
@export var min_step_x: float = -2.0
@export var max_step_x: float =  2.0
@export var min_step_y: float = -2.0
@export var max_step_y: float =  2.0

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	rng.randomize()
	rotate_random_initial()

func rotate_random_initial() -> void:
	var cubes = get_tree().get_nodes_in_group(group_name)
	if cubes.is_empty():
		push_warning("No cubes found in group: %s" % group_name)
		return

	for cube in cubes:
		if cube == null or not (cube is Node3D):
			continue

		var rand_z = rng.randf_range(min_z_degrees, max_z_degrees)
		var rand_x = rng.randf_range(min_x_degrees, max_x_degrees)
		var rand_y = rng.randf_range(min_y_degrees, max_y_degrees)

		cube.rotation_degrees = Vector3(rand_x, rand_y, rand_z)

	print("✅ Rotated %d cubes randomly in Z, X, Y (initial)" % cubes.size())

func _process(delta: float) -> void:
	var cubes = get_tree().get_nodes_in_group(group_name)
	if cubes.is_empty():
		return

	var cube: Node3D = cubes[rng.randi_range(0, cubes.size() - 1)]
	if cube == null or not (cube is Node3D):
		return

	var step_z = rng.randf_range(min_step_z, max_step_z)
	var step_x = rng.randf_range(min_step_x, max_step_x)
	var step_y = rng.randf_range(min_step_y, max_step_y)

	cube.rotate_object_local(Vector3(1, 0, 0), deg_to_rad(step_x))
	cube.rotate_object_local(Vector3(0, 1, 0), deg_to_rad(step_y))
	cube.rotate_object_local(Vector3(0, 0, 1), deg_to_rad(step_z))
