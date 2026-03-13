extends Node3D
## RotateRandomY.gd
## Randomly rotates MultiMesh cube instances around Y axis

@export var multimesh_path: NodePath = "../GridMultiMesh"
@export var min_y_degrees: float = -0.01
@export var max_y_degrees: float = 0.01
@export var min_step_y: float = -2.0
@export var max_step_y: float = 2.0

var rng := RandomNumberGenerator.new()
var multimesh_instance: MultiMeshInstance3D = null
var multimesh: MultiMesh = null

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	rng.randomize()

	# Find the MultiMeshInstance3D
	if not multimesh_path.is_empty():
		multimesh_instance = get_node_or_null(multimesh_path)

	if not multimesh_instance:
		multimesh_instance = _find_multimesh_instance(get_parent())

	if multimesh_instance:
		multimesh = multimesh_instance.multimesh
		if multimesh and multimesh.instance_count > 0:
			print("âœ… Found MultiMesh with %d instances" % multimesh.instance_count)
			rotate_random_y_safe()
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

func rotate_random_y_safe() -> void:
	if not multimesh:
		return

	var count = multimesh.instance_count
	for i in range(count):
		var transform = multimesh.get_instance_transform(i)

		# Apply random Y rotation
		var rand_y = deg_to_rad(rng.randf_range(min_y_degrees, max_y_degrees))
		transform.basis = transform.basis.rotated(Vector3.UP, rand_y)

		multimesh.set_instance_transform(i, transform)

	print("âœ… Rotated %d cubes randomly between %.1fÂ° and %.1fÂ° on Y" % [count, min_y_degrees, max_y_degrees])

func _process(_delta: float) -> void:
	if not multimesh or multimesh.instance_count == 0:
		return

	# Pick a random instance
	var instance_index = rng.randi_range(0, multimesh.instance_count - 1)
	var transform = multimesh.get_instance_transform(instance_index)

	# Rotate by a small random amount on Y
	var step_y = deg_to_rad(rng.randf_range(min_step_y, max_step_y))
	transform.basis = transform.basis.rotated(Vector3.UP, step_y)

	multimesh.set_instance_transform(instance_index, transform)
