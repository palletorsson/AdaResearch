extends Node3D
## RotateRandomY_Safe.gd
## Safely rotates all cubes in the "grid_cubes" group randomly around Y (-10° to 10°)

@export var group_name: String = "grid_cubes"
@export var min_y_degrees: float = -0.01
@export var max_y_degrees: float = 0.01
@export var min_step_y: float = -2.0
@export var max_step_y: float =  2.0
var rng := RandomNumberGenerator.new()

func _ready():
	# Delay a bit so all nodes are loaded in the tree
	await get_tree().process_frame
	await get_tree().process_frame
	rotate_random_y_safe()
	rng.randomize()
func rotate_random_y_safe():
	var cubes = get_tree().get_nodes_in_group(group_name)
	if cubes.is_empty():
		push_warning("No cubes found in group: %s" % group_name)
		return

	
	rng.randomize()

	for cube in cubes:
		if cube == null:
			continue
		if not (cube is Node3D):
			push_warning("Skipping non-Node3D in '%s': %s" % [group_name, str(cube)])
			continue
		# Apply safe rotation
		var random_y = rng.randf_range(min_y_degrees, max_y_degrees)
		cube.rotation_degrees = Vector3(cube.rotation_degrees.x, random_y, cube.rotation_degrees.z)

	print("✅ Rotated %d cubes randomly between %.1f° and %.1f° on Y" % [cubes.size(), min_y_degrees, max_y_degrees])

func _process(delta: float) -> void:
	var cubes = get_tree().get_nodes_in_group(group_name)
	if cubes.is_empty():
		return

	# pick a random cube
	var cube: Node3D = cubes[rng.randi_range(0, cubes.size() - 1)]
	if cube == null or not (cube is Node3D):
		return

	# rotate by a small random amount on Y
	var step_y = rng.randf_range(min_step_y, max_step_y)
	cube.rotate_y(deg_to_rad(step_y))
