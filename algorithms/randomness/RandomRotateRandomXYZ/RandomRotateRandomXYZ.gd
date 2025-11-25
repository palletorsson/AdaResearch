extends Node3D
## RotateRandomZXY.gd
## Randomly rotates MultiMesh cube instances on X, Y, and Z each frame

@export var multimesh_path: NodePath = "../GridMultiMesh"

# Initial random rotation range (applied once on _ready)
@export var min_degrees: float = -2.01
@export var max_degrees: float =  2.01

# Per-frame random rotation step range
@export var min_step: float = -2.0
@export var max_step: float =  2.0

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

	# If path not set or not found, search for it
	if not multimesh_instance:
		multimesh_instance = _find_multimesh_instance(get_parent())

	if multimesh_instance:
		multimesh = multimesh_instance.multimesh
		if multimesh and multimesh.instance_count > 0:
			print("✅ Found MultiMesh with %d instances" % multimesh.instance_count)
			rotate_random_initial()
		else:
			push_warning("MultiMesh found but has no instances")
	else:
		push_warning("Could not find MultiMeshInstance3D - path: %s" % multimesh_path)

func _find_multimesh_instance(node: Node) -> MultiMeshInstance3D:
	if node is MultiMeshInstance3D:
		return node
	for child in node.get_children():
		var result = _find_multimesh_instance(child)
		if result:
			return result
	return null

func rotate_random_initial() -> void:
	if not multimesh:
		return

	var count = multimesh.instance_count
	for i in range(count):
		var transform = multimesh.get_instance_transform(i)

		# Apply random initial rotation
		var rand_x = deg_to_rad(rng.randf_range(min_degrees, max_degrees))
		var rand_y = deg_to_rad(rng.randf_range(min_degrees, max_degrees))
		var rand_z = deg_to_rad(rng.randf_range(min_degrees, max_degrees))

		# Create rotation basis and apply to transform
		var rotation_basis = Basis()
		rotation_basis = rotation_basis.rotated(Vector3.RIGHT, rand_x)
		rotation_basis = rotation_basis.rotated(Vector3.UP, rand_y)
		rotation_basis = rotation_basis.rotated(Vector3.BACK, rand_z)

		transform.basis = rotation_basis * transform.basis
		multimesh.set_instance_transform(i, transform)

	print("✅ Applied initial rotation to %d MultiMesh instances" % count)

func _process(delta: float) -> void:
	if not multimesh or multimesh.instance_count == 0:
		return

	# Pick a random instance
	var instance_index = rng.randi_range(0, multimesh.instance_count - 1)
	var transform = multimesh.get_instance_transform(instance_index)

	# Generate random rotation steps
	var step_x = deg_to_rad(rng.randf_range(min_step, max_step))
	var step_y = deg_to_rad(rng.randf_range(min_step, max_step))
	var step_z = deg_to_rad(rng.randf_range(min_step, max_step))

	# Apply incremental rotation to the basis
	transform.basis = transform.basis.rotated(Vector3.RIGHT, step_x)
	transform.basis = transform.basis.rotated(Vector3.UP, step_y)
	transform.basis = transform.basis.rotated(Vector3.BACK, step_z)

	# Update the instance transform
	multimesh.set_instance_transform(instance_index, transform)
