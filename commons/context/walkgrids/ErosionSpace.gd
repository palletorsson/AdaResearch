# ErosionSpace.gd - Hydraulic erosion simulation on procedural terrain
# Start with noise terrain, then drop thousands of water particles.
# Each particle carries sediment downhill, depositing when it slows.
# The result: river valleys, alluvial fans, canyon networks.
#
# "Water is patient. Given enough time, it undoes mountains."

extends TopologySpace
class_name ErosionSpace

@export var noise_scale: float = 3.0
@export var noise_octaves: int = 5
@export var initial_height_scale: float = 3.0

# Erosion parameters
@export var num_droplets: int = 50000      # Water particles to simulate
@export var droplet_lifetime: int = 80     # Max steps per droplet
@export var erosion_rate: float = 0.3      # How much sediment water picks up
@export var deposition_rate: float = 0.3   # How much sediment water drops
@export var evaporation_rate: float = 0.01 # Water loss per step
@export var gravity: float = 4.0
@export var min_slope: float = 0.01        # Below this, droplet deposits
@export var inertia: float = 0.1           # Momentum vs gradient following
@export var erosion_radius: int = 3        # Radius of erosion brush
@export var seed_value: int = 42

var noise: FastNoiseLite
var rng: RandomNumberGenerator
var heightmap: Array = []  # Float array
var map_size: int = 0

func _ready():
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = seed_value
	noise.frequency = 0.02
	noise.fractal_octaves = noise_octaves
	super._ready()

func generate_space():
	map_size = resolution + 1
	_generate_base_terrain()
	_run_erosion()
	_build_mesh()

func _generate_base_terrain():
	heightmap.clear()
	heightmap.resize(map_size * map_size)
	for z in range(map_size):
		for x in range(map_size):
			var wx = (x / float(resolution)) * space_size.x - space_size.x / 2.0
			var wz = (z / float(resolution)) * space_size.y - space_size.y / 2.0
			heightmap[z * map_size + x] = noise.get_noise_2d(wx * noise_scale, wz * noise_scale) * initial_height_scale

func _run_erosion():
	"""Simulate hydraulic erosion with particle-based model"""
	for _drop in range(num_droplets):
		_simulate_droplet()

func _simulate_droplet():
	# Random start position
	var px = rng.randf() * float(map_size - 2) + 0.5
	var pz = rng.randf() * float(map_size - 2) + 0.5
	var dir_x = 0.0
	var dir_z = 0.0
	var speed = 1.0
	var water = 1.0
	var sediment = 0.0

	for _step in range(droplet_lifetime):
		var ix = int(px)
		var iz = int(pz)

		if ix < 1 or ix >= map_size - 2 or iz < 1 or iz >= map_size - 2:
			break

		# Calculate gradient using bilinear interpolation
		var grad = _calculate_gradient(px, pz)
		var grad_x = grad.x
		var grad_z = grad.y

		# Update direction with inertia
		dir_x = dir_x * inertia - grad_x * (1.0 - inertia)
		dir_z = dir_z * inertia - grad_z * (1.0 - inertia)

		# Normalize direction
		var dir_len = sqrt(dir_x * dir_x + dir_z * dir_z)
		if dir_len < 0.0001:
			# Random direction if flat
			var angle = rng.randf() * TAU
			dir_x = cos(angle)
			dir_z = sin(angle)
		else:
			dir_x /= dir_len
			dir_z /= dir_len

		# Move
		var new_px = px + dir_x
		var new_pz = pz + dir_z

		if new_px < 0 or new_px >= map_size - 1 or new_pz < 0 or new_pz >= map_size - 1:
			break

		var old_height = _sample_height(px, pz)
		var new_height = _sample_height(new_px, new_pz)
		var height_diff = new_height - old_height

		# Calculate sediment capacity
		var capacity = maxf(-height_diff, min_slope) * speed * water * gravity

		if sediment > capacity or height_diff > 0:
			# Deposit sediment
			var deposit_amount = 0.0
			if height_diff > 0:
				deposit_amount = minf(sediment, height_diff)
			else:
				deposit_amount = (sediment - capacity) * deposition_rate
			sediment -= deposit_amount
			_deposit(ix, iz, deposit_amount)
		else:
			# Erode
			var erode_amount = minf((capacity - sediment) * erosion_rate, -height_diff)
			sediment += erode_amount
			_erode(ix, iz, erode_amount)

		# Update speed and water
		speed = sqrt(maxf(0.0, speed * speed + height_diff * gravity))
		water *= (1.0 - evaporation_rate)

		px = new_px
		pz = new_pz

		if water < 0.01:
			break

func _calculate_gradient(px: float, pz: float) -> Vector2:
	var ix = int(px)
	var iz = int(pz)
	var fx = px - ix
	var fz = pz - iz

	var h00 = heightmap[iz * map_size + ix]
	var h10 = heightmap[iz * map_size + ix + 1]
	var h01 = heightmap[(iz + 1) * map_size + ix]
	var h11 = heightmap[(iz + 1) * map_size + ix + 1]

	var grad_x = (h10 - h00) * (1.0 - fz) + (h11 - h01) * fz
	var grad_z = (h01 - h00) * (1.0 - fx) + (h11 - h10) * fx

	return Vector2(grad_x, grad_z)

func _sample_height(px: float, pz: float) -> float:
	var ix = int(px)
	var iz = int(pz)
	ix = clampi(ix, 0, map_size - 2)
	iz = clampi(iz, 0, map_size - 2)
	var fx = px - ix
	var fz = pz - iz

	var h00 = heightmap[iz * map_size + ix]
	var h10 = heightmap[iz * map_size + ix + 1]
	var h01 = heightmap[(iz + 1) * map_size + ix]
	var h11 = heightmap[(iz + 1) * map_size + ix + 1]

	return lerpf(lerpf(h00, h10, fx), lerpf(h01, h11, fx), fz)

func _erode(cx: int, cz: int, amount: float):
	"""Erode terrain in a radius around the point"""
	var total_weight = 0.0
	for dz in range(-erosion_radius, erosion_radius + 1):
		for dx in range(-erosion_radius, erosion_radius + 1):
			var nx = cx + dx
			var nz = cz + dz
			if nx >= 0 and nx < map_size and nz >= 0 and nz < map_size:
				var dist = sqrt(float(dx * dx + dz * dz))
				if dist <= erosion_radius:
					total_weight += maxf(0.0, erosion_radius - dist)

	if total_weight < 0.001:
		return

	for dz in range(-erosion_radius, erosion_radius + 1):
		for dx in range(-erosion_radius, erosion_radius + 1):
			var nx = cx + dx
			var nz = cz + dz
			if nx >= 0 and nx < map_size and nz >= 0 and nz < map_size:
				var dist = sqrt(float(dx * dx + dz * dz))
				if dist <= erosion_radius:
					var weight = maxf(0.0, erosion_radius - dist) / total_weight
					heightmap[nz * map_size + nx] -= amount * weight

func _deposit(cx: int, cz: int, amount: float):
	if cx >= 0 and cx < map_size and cz >= 0 and cz < map_size:
		heightmap[cz * map_size + cx] += amount

func _build_mesh():
	var heights: Array = []
	for i in range(heightmap.size()):
		heights.append(heightmap[i] * height_scale)

	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	_setup_material()

func _setup_material():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.45, 0.35)  # Earthy tan
	material.roughness = 0.85
	material.metallic = 0.05
	mesh_instance.material_override = material

# Public API
func regenerate():
	rng.seed = randi()
	noise.seed = rng.seed
	generate_space()

func set_erosion_intensity(rate: float):
	erosion_rate = clampf(rate, 0.0, 1.0)
	generate_space()
