extends Node3D
class_name LeniaContinuous

## Lenia — continuous cellular automaton producing smooth lifelike organisms.
## Uses a ring-shaped kernel, bell-curve growth function, and continuous [0,1] states.
## Displayed as an animated floor texture with black→blue→cyan color mapping.

# --- Configuration ---
@export var display_size: float = 0.8
@export var grid_size: int = 64
@export var step_interval: float = 0.05
@export var dt: float = 0.1

# --- Lenia parameters ---
# Kernel: ring at radius R with peak at ring_mu, width ring_sigma
@export var kernel_radius: int = 13
@export var ring_mu: float = 0.5
@export var ring_sigma: float = 0.15

# Growth function: bell curve centered at growth_mu, width growth_sigma
@export var growth_mu: float = 0.135
@export var growth_sigma: float = 0.015

# --- Internal ---
var _grid: PackedFloat32Array
var _grid_next: PackedFloat32Array
var _kernel: PackedFloat32Array  # Precomputed kernel weights
var _kernel_offsets_x: PackedInt32Array  # Relative x offsets for kernel cells
var _kernel_offsets_y: PackedInt32Array  # Relative y offsets for kernel cells
var _kernel_norm: float = 0.0  # Sum of kernel weights for normalization

var _display_mesh: MeshInstance3D
var _image: Image
var _texture: ImageTexture
var _material: StandardMaterial3D
var _time_accum: float = 0.0
var _frame_skip: int = 0

var _rng: RandomNumberGenerator


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = hash("lenia_continuous")

	_grid = PackedFloat32Array()
	_grid.resize(grid_size * grid_size)
	_grid_next = PackedFloat32Array()
	_grid_next.resize(grid_size * grid_size)

	_precompute_kernel()
	_create_display()
	_seed_organisms()
	_update_texture()


func _precompute_kernel() -> void:
	# Build ring-shaped kernel: K(r) = bell(r/R, ring_mu, ring_sigma)
	# Only store nonzero entries with their offsets for sparse convolution.
	var weights: Array[float] = []
	var offsets_x: Array[int] = []
	var offsets_y: Array[int] = []
	var total: float = 0.0
	var kr: float = float(kernel_radius)

	for dy in range(-kernel_radius, kernel_radius + 1):
		for dx in range(-kernel_radius, kernel_radius + 1):
			var dist: float = sqrt(float(dx * dx + dy * dy))
			if dist > kr:
				continue
			# Normalized distance [0, 1]
			var r: float = dist / kr
			# Bell function for ring shape
			var w: float = _bell(r, ring_mu, ring_sigma)
			if w > 1e-6:
				weights.append(w)
				offsets_x.append(dx)
				offsets_y.append(dy)
				total += w

	_kernel = PackedFloat32Array(weights)
	_kernel_offsets_x = PackedInt32Array(offsets_x)
	_kernel_offsets_y = PackedInt32Array(offsets_y)
	_kernel_norm = total


func _bell(x: float, mu: float, sigma: float) -> float:
	# Gaussian bell curve: exp(-((x - mu)^2) / (2 * sigma^2))
	var d: float = (x - mu) / sigma
	return exp(-0.5 * d * d)


func _create_display() -> void:
	_display_mesh = MeshInstance3D.new()
	_display_mesh.name = "LeniaDisplay"

	var quad = QuadMesh.new()
	quad.size = Vector2(display_size, display_size)
	_display_mesh.mesh = quad

	# Floor-lying orientation
	_display_mesh.rotation_degrees.x = -90
	_display_mesh.position.y = 0.005

	_image = Image.create(grid_size, grid_size, false, Image.FORMAT_RGB8)
	_texture = ImageTexture.create_from_image(_image)

	_material = StandardMaterial3D.new()
	_material.albedo_texture = _texture
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_material.emission_enabled = true
	_material.emission_texture = _texture
	_material.emission_energy_multiplier = 0.6
	_material.roughness = 0.9

	_display_mesh.material_override = _material
	add_child(_display_mesh)


func _seed_organisms() -> void:
	# Clear grid
	for i in range(_grid.size()):
		_grid[i] = 0.0

	# Seed several random blobs — circular patches of random values.
	# This gives Lenia initial matter to evolve from.
	var num_blobs: int = 5
	for _b in range(num_blobs):
		var cx: int = _rng.randi_range(grid_size / 4, 3 * grid_size / 4)
		var cy: int = _rng.randi_range(grid_size / 4, 3 * grid_size / 4)
		var blob_r: int = _rng.randi_range(4, 8)
		for dy in range(-blob_r, blob_r + 1):
			for dx in range(-blob_r, blob_r + 1):
				var dist: float = sqrt(float(dx * dx + dy * dy))
				if dist <= float(blob_r):
					var gx: int = (cx + dx + grid_size) % grid_size
					var gy: int = (cy + dy + grid_size) % grid_size
					# Smooth falloff from center
					var falloff: float = 1.0 - (dist / float(blob_r))
					var val: float = falloff * _rng.randf_range(0.5, 1.0)
					_grid[gy * grid_size + gx] = clampf(val, 0.0, 1.0)


func _process(delta: float) -> void:
	_time_accum += delta
	if _time_accum >= step_interval:
		_time_accum -= step_interval
		_simulation_step()
		# Update texture every other simulation step to save performance
		_frame_skip += 1
		if _frame_skip >= 2:
			_frame_skip = 0
			_update_texture()


func _simulation_step() -> void:
	var gs: int = grid_size
	var ksize: int = _kernel.size()
	var norm: float = _kernel_norm

	for y in range(gs):
		for x in range(gs):
			# Convolution: weighted sum of neighbors using ring kernel
			var conv: float = 0.0
			for k in range(ksize):
				var nx: int = (x + _kernel_offsets_x[k] + gs) % gs
				var ny: int = (y + _kernel_offsets_y[k] + gs) % gs
				conv += _grid[ny * gs + nx] * _kernel[k]

			# Normalize convolution
			if norm > 0.0:
				conv /= norm

			# Growth function: bell curve maps convolution to growth rate
			var growth: float = 2.0 * _bell(conv, growth_mu, growth_sigma) - 1.0

			# Update: state += dt * growth
			var idx: int = y * gs + x
			var new_val: float = _grid[idx] + dt * growth
			_grid_next[idx] = clampf(new_val, 0.0, 1.0)

	# Swap buffers
	var temp: PackedFloat32Array = _grid
	_grid = _grid_next
	_grid_next = temp


func _update_texture() -> void:
	for y in range(grid_size):
		for x in range(grid_size):
			var val: float = _grid[y * grid_size + x]
			var color: Color = _state_to_color(val)
			_image.set_pixel(x, y, color)
	_texture.update(_image)


func _state_to_color(val: float) -> Color:
	# Color map: 0=black, 0.5=deep blue, 1.0=bright cyan
	if val < 0.01:
		return Color(0.01, 0.01, 0.02)

	if val < 0.5:
		# Black → deep blue
		var t: float = val / 0.5
		return Color(0.01, 0.01 + t * 0.05, 0.02 + t * 0.45)
	else:
		# Deep blue → bright cyan
		var t: float = (val - 0.5) / 0.5
		return Color(0.01 + t * 0.15, 0.06 + t * 0.85, 0.47 + t * 0.53)


## Grid system integration — accept configuration from map data
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("step_interval"):
		step_interval = float(config_data["step_interval"])
	if config_data.has("dt"):
		dt = float(config_data["dt"])
	if config_data.has("growth_mu"):
		growth_mu = float(config_data["growth_mu"])
	if config_data.has("growth_sigma"):
		growth_sigma = float(config_data["growth_sigma"])
