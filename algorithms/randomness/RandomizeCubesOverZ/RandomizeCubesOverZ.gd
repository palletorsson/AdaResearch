extends Node3D
## RandomizeCubesOverZ.gd
## Selects all cubes in the "grid_cubes" group and applies increasing randomness over Z

@export var group_name: String = "grid_cubes"
@export var randomness_scale_factor: float = 1.0
@export var max_rotation_deg: float = 10.0
@export var max_position_jitter: float = 0.2
@export var min_scale: float = 0.8
@export var max_scale: float = 1.6

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	await get_tree().process_frame
	randomize_cubes_over_z()

func randomize_cubes_over_z() -> void:
	var cubes = get_tree().get_nodes_in_group(group_name)
	if cubes.is_empty():
		push_warning("No cubes found in group: %s" % group_name)
		return

	rng.randomize()

	# Determine the min and max Z positions to normalize randomness
	var min_z = INF
	var max_z = -INF
	for cube in cubes:
		if cube is Node3D:
			min_z = min(min_z, cube.global_position.z)
			max_z = max(max_z, cube.global_position.z)

	# Avoid division by zero
	var z_range = max(max_z - min_z, 0.001)

	for cube in cubes:
		if cube == null or not (cube is Node3D):
			continue

		# Normalized Z position (0 → front, 1 → back)
		var z_factor = (cube.global_position.z - min_z) / z_range
		var randomness = pow(z_factor, 2.0) * randomness_scale_factor

		# Apply position jitter
		var jitter = Vector3(
			rng.randf_range(-max_position_jitter, max_position_jitter) * randomness,
			rng.randf_range(-max_position_jitter, max_position_jitter) * randomness,
			rng.randf_range(-max_position_jitter, max_position_jitter) * randomness
		)
		cube.position += jitter

		# Apply rotation randomness
		var rot = Vector3(
			rng.randf_range(-max_rotation_deg, max_rotation_deg) * randomness,
			rng.randf_range(-max_rotation_deg, max_rotation_deg) * randomness,
			rng.randf_range(-max_rotation_deg, max_rotation_deg) * randomness
		)
		cube.rotation_degrees += rot

		# Apply scale randomness
		var scale_factor = lerp(min_scale, max_scale, randomness)
		cube.scale = Vector3.ONE * rng.randf_range(min_scale, scale_factor)

		# Optional: Apply color randomness if it has a MeshInstance3D
		var mesh = cube.get_node_or_null("MeshInstance3D")
		if mesh and mesh is MeshInstance3D:
			var mat = mesh.get_active_material(0)
			if mat:
				mat = mat.duplicate()
				mesh.set_surface_override_material(0, mat)
				if mat is StandardMaterial3D:
					var base_col = Color(0.8, 0.8, 0.8)
					var rand_col = Color(rng.randf(), rng.randf(), rng.randf())
					mat.albedo_color = base_col.lerp(rand_col, randomness)

	print("✅ Randomized %d cubes with increasing randomness over Z" % cubes.size())
