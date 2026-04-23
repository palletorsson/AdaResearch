extends Node3D

# Fractal Cloud Generator
# Creates volumetric clouds using fractal noise (fBm - fractional Brownian motion)
# Multiple octaves of noise combined for natural-looking clouds

# @identity
# essence: cloud(point) = Σ(k=0..octaves) persistence^k * simplex(lacunarity^k * freq * point + wind*t), threshold clips to cloud/void
# desire: to fill volume with weather — fBm gives the cloud its turbulent self-similar density, and wind_speed carries it like it has mass and direction
# critical_parameter: density_threshold — too high makes the sky clear, too low makes the world grey fog; at 0.45 you get discrete cloud islands
# triggers: _ready → _generate_cloud → per point in resolution³ → fBm sample → MultiMesh instance if above threshold → _process animates wind_speed*time offset
# emerges: heavy-bottomed thin-topped cloud silhouettes — the noise threshold clips symmetrically but gravity shapes how we read the result as a cloud rather than a blob
# needs: VR wind control [missing], density_threshold slider [missing], turbulence interaction [missing]
# relationships: the 3D application of fBm that noise_mixer shows in 2D; shares the octaves/lacunarity/persistence pattern with perlin_terrain_sculptor; ambient partner to dark_sphere in open maps
# truth: A cloud is not a thing — it is a threshold. The same noise field with different cutoff is sky, cloud, or fog. Only the cutoff decides.

@export_group("Cloud Shape")
@export var cloud_size := Vector3(20.0, 5.0, 20.0)
@export var resolution := 32  # Points per axis
@export var density_threshold := 0.45  # Below this = transparent
@export var density_falloff := 2.0  # Edge softness

@export_group("Fractal Noise")
@export var octaves := 5
@export var lacunarity := 2.0  # Frequency multiplier per octave
@export var persistence := 0.5  # Amplitude multiplier per octave
@export var noise_scale := 0.1
@export var noise_seed := 0

@export_group("Animation")
@export var animate := true
@export var wind_speed := Vector3(0.5, 0.0, 0.2)
@export var turbulence := 0.3

@export_group("Appearance")
@export var cloud_color := Color(1.0, 1.0, 1.0, 0.8)
@export var shadow_color := Color(0.7, 0.75, 0.85, 0.6)
@export var point_size := 0.3
@export var use_multimesh := true

# Internal
var noise: FastNoiseLite
var multimesh_instance: MultiMeshInstance3D
var multimesh: MultiMesh
var cloud_points: Array[Dictionary] = []  # {position, density}
var time := 0.0

func _ready() -> void:
	_setup_noise()
	_generate_cloud()

func _setup_noise() -> void:
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = noise_seed if noise_seed != 0 else randi()
	noise.frequency = noise_scale

func _process(delta: float) -> void:
	if not animate:
		return

	time += delta

	# Animate cloud movement and internal turbulence
	if use_multimesh and multimesh:
		_update_cloud_animation(delta)

func _generate_cloud() -> void:
	"""Generate cloud points using fractal noise"""
	cloud_points.clear()

	var half_size = cloud_size / 2.0
	var step = cloud_size / resolution

	for x in range(resolution):
		for y in range(resolution):
			for z in range(resolution):
				var local_pos = Vector3(
					x * step.x - half_size.x,
					y * step.y - half_size.y,
					z * step.z - half_size.z
				)

				# Calculate density using fractal noise
				var density = _sample_fractal_noise(local_pos)

				# Apply distance falloff from center
				var distance_factor = _calculate_distance_falloff(local_pos, half_size)
				density *= distance_factor

				# Only keep points above threshold
				if density > density_threshold:
					cloud_points.append({
						"position": local_pos,
						"density": density,
						"base_position": local_pos  # For animation
					})

	print("FractalClouds: Generated %d cloud points" % cloud_points.size())

	if use_multimesh:
		_create_multimesh_cloud()
	else:
		_create_mesh_cloud()

func _sample_fractal_noise(pos: Vector3) -> float:
	"""Sample fractal Brownian motion noise at position"""
	var value := 0.0
	var amplitude := 1.0
	var frequency := 1.0
	var max_value := 0.0

	for i in range(octaves):
		var sample_pos = pos * frequency
		value += noise.get_noise_3d(sample_pos.x, sample_pos.y, sample_pos.z) * amplitude

		max_value += amplitude
		amplitude *= persistence
		frequency *= lacunarity

	# Normalize to 0-1 range
	value = (value / max_value + 1.0) / 2.0

	return value

func _calculate_distance_falloff(pos: Vector3, half_size: Vector3) -> float:
	"""Calculate falloff based on distance from cloud center"""
	var normalized = Vector3(
		abs(pos.x) / half_size.x,
		abs(pos.y) / half_size.y,
		abs(pos.z) / half_size.z
	)

	var distance = normalized.length()

	# Smooth falloff
	var falloff = 1.0 - pow(clamp(distance, 0.0, 1.0), density_falloff)
	return falloff

func _create_multimesh_cloud() -> void:
	"""Create cloud using MultiMesh for performance"""
	if cloud_points.size() == 0:
		return

	# Create sphere mesh for cloud particles
	var sphere = SphereMesh.new()
	sphere.radius = point_size * 0.5
	sphere.height = point_size

	# Create multimesh
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = sphere
	multimesh.instance_count = cloud_points.size()

	# Set transforms and colors
	for i in range(cloud_points.size()):
		var point = cloud_points[i]
		var transform = Transform3D(Basis(), point.position)

		# Scale based on density
		var scale_factor = lerp(0.5, 1.5, point.density)
		transform.basis = transform.basis.scaled(Vector3.ONE * scale_factor)

		multimesh.set_instance_transform(i, transform)

		# Color based on density and height
		var color = _calculate_point_color(point)
		multimesh.set_instance_color(i, color)

	# Create instance
	multimesh_instance = MultiMeshInstance3D.new()
	multimesh_instance.multimesh = multimesh
	multimesh_instance.name = "CloudMultiMesh"

	# Material
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	multimesh_instance.material_override = material

	add_child(multimesh_instance)

func _create_mesh_cloud() -> void:
	"""Create cloud using individual meshes (slower, for reference)"""
	for i in range(cloud_points.size()):
		var point = cloud_points[i]

		var mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = point_size * 0.5 * lerp(0.5, 1.5, point.density)
		sphere.height = point_size * lerp(0.5, 1.5, point.density)
		mesh_instance.mesh = sphere
		mesh_instance.position = point.position

		var material = StandardMaterial3D.new()
		material.albedo_color = _calculate_point_color(point)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh_instance.material_override = material

		add_child(mesh_instance)

func _calculate_point_color(point: Dictionary) -> Color:
	"""Calculate color based on density and position"""
	var density = point.density
	var pos = point.position

	# Lighter at top, darker at bottom (self-shadowing effect)
	var height_factor = (pos.y / (cloud_size.y * 0.5) + 1.0) / 2.0

	var color = cloud_color.lerp(shadow_color, 1.0 - height_factor)

	# Alpha based on density
	color.a = lerp(0.3, 0.9, (density - density_threshold) / (1.0 - density_threshold))

	return color

func _update_cloud_animation(_delta: float) -> void:
	"""Animate cloud particles"""
	if not multimesh:
		return

	for i in range(cloud_points.size()):
		var point = cloud_points[i]
		var base_pos = point.base_position

		# Wind movement
		var offset = wind_speed * time

		# Turbulence using noise
		var turb_sample = base_pos + offset
		var turbulence_offset = Vector3(
			noise.get_noise_3d(turb_sample.x, turb_sample.y, turb_sample.z + 100),
			noise.get_noise_3d(turb_sample.x + 100, turb_sample.y, turb_sample.z),
			noise.get_noise_3d(turb_sample.x, turb_sample.y + 100, turb_sample.z)
		) * turbulence

		var new_pos = base_pos + turbulence_offset

		# Update transform
		var current_transform = multimesh.get_instance_transform(i)
		current_transform.origin = new_pos
		multimesh.set_instance_transform(i, current_transform)

# Public API
func regenerate() -> void:
	"""Clear and regenerate cloud"""
	if multimesh_instance:
		multimesh_instance.queue_free()
		multimesh_instance = null
		multimesh = null

	for child in get_children():
		child.queue_free()

	_generate_cloud()

func set_noise_seed(new_seed: int) -> void:
	"""Set noise seed and regenerate"""
	noise_seed = new_seed
	noise.seed = new_seed
	regenerate()

func set_octaves(new_octaves: int) -> void:
	"""Set fractal detail level"""
	octaves = clamp(new_octaves, 1, 8)
	regenerate()

func randomize_cloud() -> void:
	"""Generate new random cloud"""
	noise_seed = randi()
	noise.seed = noise_seed
	regenerate()

# Grid system integration
func configure(data: Dictionary) -> void:
	"""Configure from grid spawn parameters (e.g., fractal_clouds#preset:storm)"""
	print("FractalClouds: Configuring from Grid JSON: ", data)

	if data.has("preset"):
		apply_preset(str(data["preset"]).to_lower())
		return

	if data.has("octaves"):
		octaves = int(data["octaves"])

	if data.has("resolution"):
		resolution = int(data["resolution"])

	if data.has("animate"):
		animate = str(data["animate"]).to_lower() == "true"

	regenerate()

# Presets
func apply_preset(preset_name: String) -> void:
	"""Apply a cloud preset"""
	match preset_name:
		"cumulus":
			cloud_size = Vector3(15.0, 8.0, 15.0)
			octaves = 5
			density_threshold = 0.5
			density_falloff = 2.0
		"stratus":
			cloud_size = Vector3(40.0, 3.0, 40.0)
			octaves = 4
			density_threshold = 0.4
			density_falloff = 1.5
		"cirrus":
			cloud_size = Vector3(30.0, 2.0, 30.0)
			octaves = 6
			persistence = 0.6
			density_threshold = 0.55
		"storm":
			cloud_size = Vector3(25.0, 15.0, 25.0)
			octaves = 6
			density_threshold = 0.35
			cloud_color = Color(0.6, 0.6, 0.65, 0.9)
			shadow_color = Color(0.3, 0.3, 0.35, 0.8)

	regenerate()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
