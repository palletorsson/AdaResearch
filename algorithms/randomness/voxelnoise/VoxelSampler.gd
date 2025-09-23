# VoxelSampler.gd
extends Node3D

@export var size: Vector3i = Vector3i(64, 64, 64)   # voxel grid resolution (cells)
@export var voxel_size: float = 0.1                 # meters per voxel
@export var iso_level: float = 0.0                  # marching cubes threshold in [-1,1] if using FastNoiseLite
@export var frequency: float = 0.02                 # noise frequency
@export var domain_offset: Vector3 = Vector3.ZERO   # optional world-space shift in the noise domain

var noise := FastNoiseLite.new()

func _ready():
	# Configure noise
	noise.noise_type = FastNoiseLite.TYPE_PERLIN     # or TYPE_SIMPLEX, etc.
	noise.frequency = frequency

	# Build a centered sample volume
	var samples = _sample_centered_volume()
	# -> pass `samples` into your mesher (marching cubes) or ROI logic
	# e.g., MeshFromDensity.build(samples, size, iso_level, voxel_size)
	print("Sample volume ready, centered at local (0,0,0).")

func _sample_centered_volume() -> PackedFloat32Array:
	# Center grid in local space: indices in [-hx .. +hx], [-hy .. +hy], [-hz .. +hz]
	var half = Vector3( float(size.x-1), float(size.y-1), float(size.z-1) ) * 0.5
	var data := PackedFloat32Array()
	data.resize(size.x * size.y * size.z)

	var i := 0
	for z in size.z:
		for y in size.y:
			for x in size.x:
				# local voxel position centered around the node's origin
				var local_pos = (Vector3(x, y, z) - half) * voxel_size

				# noise domain position also centered (domain_offset lets you “move” the pattern)
				var p = local_pos + domain_offset

				# sample noise in [-1,1]
				var d = noise.get_noise_3d(p.x, p.y, p.z)

				# store
				data[i] = d
				i += 1

	return data
