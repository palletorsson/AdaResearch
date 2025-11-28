extends Node3D
## RandomRotateRandomXYZ.gd
## Randomly rotates MultiMesh cube instances on X, Y, and Z each frame
## Supports different selection modes for determining which instances rotate.

enum SelectionMode {
	UNIFORM,
	CENTER_BELL,
	NOISE
}

@export_group("Targeting")
@export var multimesh_path: NodePath = "../GridMultiMesh"
@export var selection_mode: SelectionMode = SelectionMode.UNIFORM

@export_subgroup("Bell Curve Settings")
@export var bell_center: Vector3 = Vector3.ZERO
@export var bell_radius: float = 10.0 ## The standard deviation (sigma) of the bell curve

@export_subgroup("Noise Settings")
@export var noise_source: FastNoiseLite
@export var noise_scale: float = 1.0
@export var noise_threshold: float = 0.0 ## Minimum probability cutoff
@export var noise_scroll_speed: Vector3 = Vector3(0.1, 0.1, 0.1)

@export_group("Rotation Settings")
# Initial random rotation range (applied once on _ready)
@export var min_degrees: float = -2.01
@export var max_degrees: float =  2.01

# Per-frame random rotation step range
@export var min_step: float = -2.0
@export var max_step: float =  2.0

var rng := RandomNumberGenerator.new()
var multimesh_instance: MultiMeshInstance3D = null
var multimesh: MultiMesh = null
var _time: float = 0.0

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	rng.randomize()
	
	if selection_mode == SelectionMode.NOISE and not noise_source:
		# Create default noise if missing
		noise_source = FastNoiseLite.new()
		noise_source.noise_type = FastNoiseLite.TYPE_PERLIN
		noise_source.frequency = 0.1

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
			
			# Auto-detect center if bell center is zero (optional UX convenience)
			if selection_mode == SelectionMode.CENTER_BELL and bell_center == Vector3.ZERO:
				var aabb = multimesh.get_aabb()
				bell_center = aabb.get_center()
				print("Centered bell curve at: ", bell_center)
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
		
	_time += delta

	var chosen_index = -1
	var max_attempts = 20 # Try to find a valid instance up to 20 times per frame
	
	for _attempt in range(max_attempts):
		# Pick a random instance
		var idx = rng.randi_range(0, multimesh.instance_count - 1)
		
		if selection_mode == SelectionMode.UNIFORM:
			chosen_index = idx
			break
		
		var transform = multimesh.get_instance_transform(idx)
		var pos = transform.origin
		var probability = 0.0
		
		if selection_mode == SelectionMode.CENTER_BELL:
			var dist = pos.distance_to(bell_center)
			# Gaussian: e^(-x^2 / 2s^2)
			# Result is 1.0 at center, near 0 at edges
			probability = exp(-(dist * dist) / (2.0 * bell_radius * bell_radius))
			
		elif selection_mode == SelectionMode.NOISE:
			if noise_source:
				var noise_pos = (pos * noise_scale) + (noise_scroll_speed * _time)
				var n = noise_source.get_noise_3dv(noise_pos)
				# Remap -1..1 to 0..1
				probability = (n + 1.0) * 0.5
				if probability < noise_threshold:
					probability = 0.0
		
		# Rejection sampling
		if rng.randf() < probability:
			chosen_index = idx
			break
	
	# If we failed to find a target after max_attempts, we simply skip rotation this frame
	if chosen_index == -1:
		return

	# Perform the rotation on the chosen instance
	var transform = multimesh.get_instance_transform(chosen_index)

	# Generate random rotation steps
	var step_x = deg_to_rad(rng.randf_range(min_step, max_step))
	var step_y = deg_to_rad(rng.randf_range(min_step, max_step))
	var step_z = deg_to_rad(rng.randf_range(min_step, max_step))

	# Apply incremental rotation to the basis
	transform.basis = transform.basis.rotated(Vector3.RIGHT, step_x)
	transform.basis = transform.basis.rotated(Vector3.UP, step_y)
	transform.basis = transform.basis.rotated(Vector3.BACK, step_z)

	# Update the instance transform
	multimesh.set_instance_transform(chosen_index, transform)
