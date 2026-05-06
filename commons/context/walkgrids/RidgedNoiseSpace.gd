# RidgedNoiseSpace.gd - Ridged multifractal terrain
# Takes standard noise and folds it — abs(noise) creates sharp ridges
# that look like mountain ranges, canyon networks, dragon spines.
# Layered octaves of ridged noise create eerily realistic geology.
#
# "Mountains are just noise that refused to be smooth."

extends TopologySpace
class_name RidgedNoiseSpace

@export var noise_scale: float = 3.0
@export var octaves: int = 6
@export var lacunarity: float = 2.0       # Frequency multiplier per octave
@export var gain: float = 0.5             # Amplitude decay per octave
@export var ridge_offset: float = 1.0     # Controls ridge sharpness
@export var ridge_power: float = 2.0      # Exponent for ridge shaping
@export var erosion_strength: float = 0.3 # Simulated hydraulic erosion
@export var terrace_count: int = 0        # 0 = off, >0 = terrace the terrain
@export var seed_value: int = 42

# Terrain character
@export var terrain_type: TerrainType = TerrainType.MOUNTAIN_RANGE

enum TerrainType {
	MOUNTAIN_RANGE,   # Classic ridged mountains
	CANYON_NETWORK,   # Inverted ridges = canyons
	DRAGON_SPINE,     # Sharp ridges with flat valleys
	ERODED_PLATEAU,   # Flat top with eroded edges
	ALIEN_GEOLOGY,    # Multiple noise types combined
}

var noise: FastNoiseLite
var erosion_noise: FastNoiseLite

func _ready():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = seed_value
	noise.frequency = 0.02

	erosion_noise = FastNoiseLite.new()
	erosion_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	erosion_noise.seed = seed_value + 1000
	erosion_noise.frequency = 0.05

	super._ready()

func generate_space():
	var heights: Array = []
	var gs = resolution + 1

	for z in range(gs):
		for x in range(gs):
			var world_x = (x / float(resolution)) * space_size.x - space_size.x / 2.0
			var world_z = (z / float(resolution)) * space_size.y - space_size.y / 2.0
			var h = _sample_ridged(world_x, world_z)
			heights.append(h * height_scale)

	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	_setup_material()

func _sample_ridged(x: float, z: float) -> float:
	match terrain_type:
		TerrainType.MOUNTAIN_RANGE:
			return _ridged_multifractal(x, z)
		TerrainType.CANYON_NETWORK:
			return -_ridged_multifractal(x, z)
		TerrainType.DRAGON_SPINE:
			return _dragon_spine(x, z)
		TerrainType.ERODED_PLATEAU:
			return _eroded_plateau(x, z)
		TerrainType.ALIEN_GEOLOGY:
			return _alien_geology(x, z)
	return _ridged_multifractal(x, z)

func _ridged_multifractal(x: float, z: float) -> float:
	"""Classic ridged multifractal noise"""
	var sum = 0.0
	var frequency = noise_scale
	var amplitude = 1.0
	var weight = 1.0

	for _oct in range(octaves):
		var n = noise.get_noise_2d(x * frequency, z * frequency)

		# Ridge: fold the noise
		n = ridge_offset - abs(n)
		n = pow(n, ridge_power)

		# Weight successive octaves by previous
		n *= weight
		weight = clampf(n * gain, 0.0, 1.0)

		sum += n * amplitude
		frequency *= lacunarity
		amplitude *= gain

	# Apply erosion
	if erosion_strength > 0.0:
		var erosion = erosion_noise.get_noise_2d(x * 2.0, z * 2.0)
		sum *= (1.0 - erosion_strength * abs(erosion))

	# Apply terracing
	if terrace_count > 0:
		sum = _terrace(sum, terrace_count)

	return sum

func _dragon_spine(x: float, z: float) -> float:
	"""Sharp ridges with flat valleys"""
	var ridge = _ridged_multifractal(x, z)
	# Exaggerate peaks, flatten valleys
	return pow(maxf(ridge, 0.0), 0.7)

func _eroded_plateau(x: float, z: float) -> float:
	"""Flat top with eroded edges"""
	var base = noise.get_noise_2d(x * noise_scale * 0.5, z * noise_scale * 0.5)
	base = clampf(base + 0.3, 0.0, 1.0)  # Raise to create plateau

	var erosion = _ridged_multifractal(x, z)
	return base - erosion * 0.3

func _alien_geology(x: float, z: float) -> float:
	"""Multiple noise types combined"""
	var ridged = _ridged_multifractal(x, z)
	var smooth = noise.get_noise_2d(x * noise_scale * 0.3, z * noise_scale * 0.3)
	var cellular = abs(noise.get_noise_2d(x * noise_scale * 2.0, z * noise_scale * 2.0))

	return ridged * 0.5 + smooth * 0.3 + cellular * 0.2

func _terrace(value: float, steps: int) -> float:
	"""Quantize height into terrace steps"""
	var step_size = 1.0 / float(steps)
	return floor(value / step_size) * step_size

func _setup_material():
	var material = StandardMaterial3D.new()
	match terrain_type:
		TerrainType.MOUNTAIN_RANGE:
			material.albedo_color = Color(0.45, 0.42, 0.38)  # Stone grey
		TerrainType.CANYON_NETWORK:
			material.albedo_color = Color(0.6, 0.35, 0.2)  # Red sandstone
		TerrainType.DRAGON_SPINE:
			material.albedo_color = Color(0.3, 0.35, 0.3)  # Dark basalt
		TerrainType.ERODED_PLATEAU:
			material.albedo_color = Color(0.55, 0.5, 0.4)  # Sandstone
		TerrainType.ALIEN_GEOLOGY:
			material.albedo_color = Color(0.4, 0.3, 0.5)  # Alien purple
	material.roughness = 0.85
	material.metallic = 0.1
	mesh_instance.material_override = material

# Public API
func set_terrain(type: TerrainType):
	terrain_type = type
	generate_space()

func regenerate():
	noise.seed = randi()
	erosion_noise.seed = noise.seed + 1000
	generate_space()
