extends Node3D
## RandomizeCubesOverZ.gd
## Applies increasing randomness to MultiMesh instances over Z axis

@export var multimesh_path: NodePath = "../GridMultiMesh"
@export var randomness_scale_factor: float = 1.0
@export var max_rotation_deg: float = 10.0
@export var max_position_jitter: float = 0.2
@export var min_scale: float = 0.8
@export var max_scale: float = 1.6
@export var apply_color_randomness: bool = true

var rng := RandomNumberGenerator.new()
var multimesh_instance: MultiMeshInstance3D = null
var multimesh: MultiMesh = null

func _ready() -> void:
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
			print("✅ Found MultiMesh with %d instances" % multimesh.instance_count)
			randomize_cubes_over_z()
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

func randomize_cubes_over_z() -> void:
	if not multimesh:
		return

	# Find min and max Z positions
	var min_z = INF
	var max_z = -INF
	for i in range(multimesh.instance_count):
		var transform = multimesh.get_instance_transform(i)
		var z = transform.origin.z
		min_z = min(min_z, z)
		max_z = max(max_z, z)

	var z_range = max(max_z - min_z, 0.001)

	# Apply randomness to each instance
	for i in range(multimesh.instance_count):
		var transform = multimesh.get_instance_transform(i)

		# Normalized Z position (0 → front, 1 → back)
		var z_factor = (transform.origin.z - min_z) / z_range
		var randomness = pow(z_factor, 2.0) * randomness_scale_factor

		# Apply position jitter
		var jitter = Vector3(
			rng.randf_range(-max_position_jitter, max_position_jitter) * randomness,
			rng.randf_range(-max_position_jitter, max_position_jitter) * randomness,
			rng.randf_range(-max_position_jitter, max_position_jitter) * randomness
		)
		transform.origin += jitter

		# Apply rotation randomness
		var rot_x = deg_to_rad(rng.randf_range(-max_rotation_deg, max_rotation_deg) * randomness)
		var rot_y = deg_to_rad(rng.randf_range(-max_rotation_deg, max_rotation_deg) * randomness)
		var rot_z = deg_to_rad(rng.randf_range(-max_rotation_deg, max_rotation_deg) * randomness)

		transform.basis = transform.basis.rotated(Vector3.RIGHT, rot_x)
		transform.basis = transform.basis.rotated(Vector3.UP, rot_y)
		transform.basis = transform.basis.rotated(Vector3.BACK, rot_z)

		# Apply scale randomness
		var scale_factor = lerp(min_scale, max_scale, randomness)
		var random_scale = rng.randf_range(min_scale, scale_factor)
		transform.basis = transform.basis.scaled(Vector3.ONE * random_scale)

		multimesh.set_instance_transform(i, transform)

		# Apply color randomness if enabled
		if apply_color_randomness and multimesh.use_colors:
			var base_col = Color(0.8, 0.8, 0.8)
			var rand_col = Color(rng.randf(), rng.randf(), rng.randf())
			var final_color = base_col.lerp(rand_col, randomness)
			multimesh.set_instance_color(i, final_color)

	print("✅ Randomized %d instances with increasing randomness over Z" % multimesh.instance_count)
