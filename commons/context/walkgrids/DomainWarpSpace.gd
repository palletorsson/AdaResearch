# DomainWarpSpace.gd - Warped noise where the input coordinates themselves are distorted
# Feed noise into the coordinates of more noise. The result is organic,
# fluid, lava-lamp terrain — space folding back on itself. Used in
# every AAA terrain generator but rarely explained.
#
# "What if the question was also the answer?"

extends TopologySpace
class_name DomainWarpSpace

@export var noise_scale: float = 3.0
@export var warp_strength: float = 4.0     # How much the domain is distorted
@export var warp_layers: int = 2           # How many times to warp (1=simple, 2=complex, 3=alien)
@export var octaves: int = 4
@export var seed_value: int = 42

# Character
@export var warp_style: WarpStyle = WarpStyle.ORGANIC

enum WarpStyle {
	ORGANIC,       # Smooth flowing distortion
	CRYSTALLINE,   # Sharp angular warping
	TURBULENT,     # High-frequency chaos
	MARBLE,        # Classic marble texture as terrain
	WOOD_GRAIN,    # Concentric ring distortion
}

var noise_x: FastNoiseLite
var noise_z: FastNoiseLite
var noise_value: FastNoiseLite

func _ready():
	_setup_noises()
	super._ready()

func _setup_noises():
	noise_x = FastNoiseLite.new()
	noise_x.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_x.seed = seed_value
	noise_x.frequency = 0.03
	noise_x.fractal_octaves = octaves

	noise_z = FastNoiseLite.new()
	noise_z.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_z.seed = seed_value + 100
	noise_z.frequency = 0.03
	noise_z.fractal_octaves = octaves

	noise_value = FastNoiseLite.new()
	noise_value.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_value.seed = seed_value + 200
	noise_value.frequency = 0.02
	noise_value.fractal_octaves = octaves

func generate_space():
	var heights: Array = []
	var gs = resolution + 1

	for z in range(gs):
		for x in range(gs):
			var wx = (x / float(resolution)) * space_size.x - space_size.x / 2.0
			var wz = (z / float(resolution)) * space_size.y - space_size.y / 2.0
			var h = _sample_warped(wx * noise_scale, wz * noise_scale)
			heights.append(h * height_scale)

	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	_setup_material()

func _sample_warped(x: float, z: float) -> float:
	match warp_style:
		WarpStyle.ORGANIC:
			return _warp_organic(x, z)
		WarpStyle.CRYSTALLINE:
			return _warp_crystalline(x, z)
		WarpStyle.TURBULENT:
			return _warp_turbulent(x, z)
		WarpStyle.MARBLE:
			return _warp_marble(x, z)
		WarpStyle.WOOD_GRAIN:
			return _warp_wood(x, z)
	return _warp_organic(x, z)

func _warp_organic(x: float, z: float) -> float:
	"""Multi-layer domain warping — Inigo Quilez style"""
	var px = x
	var pz = z

	for _layer in range(warp_layers):
		var wx = noise_x.get_noise_2d(px, pz) * warp_strength
		var wz = noise_z.get_noise_2d(px + 5.2, pz + 1.3) * warp_strength
		px = x + wx
		pz = z + wz

	return noise_value.get_noise_2d(px, pz)

func _warp_crystalline(x: float, z: float) -> float:
	"""Angular warping — sharp folds"""
	var px = x
	var pz = z

	for _layer in range(warp_layers):
		var wx = noise_x.get_noise_2d(px, pz) * warp_strength
		var wz = noise_z.get_noise_2d(px + 5.2, pz + 1.3) * warp_strength
		# Quantize the warp to create angular folds
		wx = floor(wx * 3.0) / 3.0
		wz = floor(wz * 3.0) / 3.0
		px = x + wx
		pz = z + wz

	return noise_value.get_noise_2d(px, pz)

func _warp_turbulent(x: float, z: float) -> float:
	"""Turbulent — abs() for sharp creases"""
	var px = x
	var pz = z

	for _layer in range(warp_layers):
		var wx = abs(noise_x.get_noise_2d(px, pz)) * warp_strength
		var wz = abs(noise_z.get_noise_2d(px + 5.2, pz + 1.3)) * warp_strength
		px = x + wx
		pz = z + wz

	return abs(noise_value.get_noise_2d(px, pz))

func _warp_marble(x: float, z: float) -> float:
	"""Classic marble: sin(x + noise)"""
	var n = noise_value.get_noise_2d(x, z) * warp_strength
	return sin(x * 0.5 + n) * 0.5 + 0.5

func _warp_wood(x: float, z: float) -> float:
	"""Concentric rings distorted by noise"""
	var dist = sqrt(x * x + z * z)
	var n = noise_value.get_noise_2d(x, z) * warp_strength
	return sin(dist * 2.0 + n) * 0.5 + 0.5

func _setup_material():
	var material = StandardMaterial3D.new()
	match warp_style:
		WarpStyle.ORGANIC:
			material.albedo_color = Color(0.5, 0.55, 0.45)
		WarpStyle.CRYSTALLINE:
			material.albedo_color = Color(0.6, 0.6, 0.7)
			material.metallic = 0.4
		WarpStyle.TURBULENT:
			material.albedo_color = Color(0.55, 0.4, 0.35)
		WarpStyle.MARBLE:
			material.albedo_color = Color(0.85, 0.82, 0.78)
			material.metallic = 0.3
			material.roughness = 0.3
		WarpStyle.WOOD_GRAIN:
			material.albedo_color = Color(0.55, 0.38, 0.22)
	material.roughness = material.roughness if material.roughness != 0.0 else 0.7
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.15
	mesh_instance.material_override = material

# Public API
func set_style(style: WarpStyle):
	warp_style = style
	generate_space()

func regenerate():
	seed_value = randi()
	_setup_noises()
	generate_space()
