# voxelnoise.gd
# Godot 4.x — Centered, robust noise sampler for voxel workflows
extends Node3D

# ----------------------------
# Noise controls (FastNoiseLite)
# ----------------------------
@export var seed: int = 1337 : set = _set_seed
@export var frequency: float = 0.02 : set = _set_frequency

@export_enum(
	"OpenSimplex2:0",
	"OpenSimplex2S:1",
	"Cellular:2",
	"Perlin:3",
	"ValueCubic:4",
	"Value:5"
)
var noise_type: int = FastNoiseLite.TYPE_PERLIN : set = _set_noise_type

@export_enum(
	"None:0",
	"FBM:1",
	"Ridged:2",
	"PingPong:3",
	"DomainWarpProgressive:4",
	"DomainWarpIndependent:5"
)
var fractal_type: int = FastNoiseLite.FRACTAL_FBM : set = _set_fractal_type

@export_range(1, 12, 1) var octaves: int = 5 : set = _set_octaves
@export var lacunarity: float = 2.0 : set = _set_lacunarity
@export var gain: float = 0.5 : set = _set_gain

# ----------------------------
# Sampling / domain controls
# ----------------------------
@export var domain_offset: Vector3 = Vector3.ZERO	# shifts the NOISE domain (not the mesh)
@export var iso_level: float = 0.0					# marching-cubes threshold if you use one

# Default grid settings for quick tests (you can ignore if sampling manually)
@export var default_size: Vector3i = Vector3i(48, 48, 48)
@export var default_voxel_size: float = 0.1

var _noise := FastNoiseLite.new()

func _ready() -> void:
	_configure_noise()

# =========================================================
# Core API
# =========================================================

# Get density from LOCAL position (centered domain).
func get_density_local(local_pos: Vector3) -> float:
	var p := local_pos + domain_offset
	return _noise.get_noise_3d(p.x, p.y, p.z)

# Get density from WORLD position (auto-converts to local).
func get_density_world(world_pos: Vector3) -> float:
	return get_density_local(to_local(world_pos))

# Sample a centered grid of size `size_vox` with spacing `voxel_size`.
# Order: X changes fastest, then Y, then Z. (i = x + y*X + z*X*Y)
func sample_centered_grid(size_vox: Vector3i, voxel_size: float) -> PackedFloat32Array:
	var half := Vector3(float(size_vox.x - 1), float(size_vox.y - 1), float(size_vox.z - 1)) * 0.5
	var data := PackedFloat32Array()
	data.resize(size_vox.x * size_vox.y * size_vox.z)

	var i := 0
	for z in size_vox.z:
		for y in size_vox.y:
			for x in size_vox.x:
				var local_pos := (Vector3(x, y, z) - half) * voxel_size
				data[i] = get_density_local(local_pos)
				i += 1
	return data

# Sample an ROI by voxel half-extents around a LOCAL-space center.
# Example: half_extents_vox=(8,6,8) returns a (17×13×17) block.
func sample_roi_centered_at_local(center_local: Vector3, half_extents_vox: Vector3i, voxel_size: float) -> PackedFloat32Array:
	var full := (half_extents_vox * 2) + Vector3i.ONE
	var data := PackedFloat32Array()
	data.resize(full.x * full.y * full.z)

	var i := 0
	for z in range(-half_extents_vox.z, half_extents_vox.z + 1):
		for y in range(-half_extents_vox.y, half_extents_vox.y + 1):
			for x in range(-half_extents_vox.x, half_extents_vox.x + 1):
				var lp := center_local + Vector3(x, y, z) * voxel_size
				data[i] = get_density_local(lp)
				i += 1
	return data

# World-space convenience wrapper for the ROI sampler.
func sample_roi_centered_at_world(center_world: Vector3, half_extents_vox: Vector3i, voxel_size: float) -> PackedFloat32Array:
	return sample_roi_centered_at_local(to_local(center_world), half_extents_vox, voxel_size)

# Quick helper: returns a binary mask around `iso_level` with a tolerance band.
func make_isoband_mask(density_field: PackedFloat32Array, iso: float, tolerance: float = 0.05) -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(density_field.size())
	for i in density_field.size():
		var d := density_field[i]
		mask[i] = 1 if abs(d - iso) <= tolerance else 0
	return mask

# =========================================================
# Quick test (optional)
# =========================================================
func build_default() -> PackedFloat32Array:
	return sample_centered_grid(default_size, default_voxel_size)

# =========================================================
# Internals
# =========================================================
func _configure_noise() -> void:
	_noise.seed = seed
	_noise.frequency = frequency
	_noise.noise_type = noise_type
	_noise.fractal_type = fractal_type
	_noise.fractal_octaves = octaves
	_noise.fractal_lacunarity = lacunarity
	_noise.fractal_gain = gain

func _set_seed(v: int) -> void:
	seed = v
	if is_node_ready():
		_noise.seed = seed

func _set_frequency(v: float) -> void:
	frequency = v
	if is_node_ready():
		_noise.frequency = frequency

func _set_noise_type(v: int) -> void:
	noise_type = v
	if is_node_ready():
		_noise.noise_type = noise_type

func _set_fractal_type(v: int) -> void:
	fractal_type = v
	if is_node_ready():
		_noise.fractal_type = fractal_type

func _set_octaves(v: int) -> void:
	octaves = v
	if is_node_ready():
		_noise.fractal_octaves = octaves

func _set_lacunarity(v: float) -> void:
	lacunarity = v
	if is_node_ready():
		_noise.fractal_lacunarity = lacunarity

func _set_gain(v: float) -> void:
	gain = v
	if is_node_ready():
		_noise.fractal_gain = gain
