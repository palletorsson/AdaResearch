# FractalSpace.gd - Recursive fractal terrain generation
extends TopologySpace
class_name FractalSpace

@export var fractal_depth: int = 5
@export var initial_displacement: float = 2.0
@export var roughness: float = 0.5  # How much displacement decreases per iteration
@export var seed_value: int = 42

# Animation properties
@export var enable_animation: bool = false
@export var animation_speed: float = 0.5
@export var animation_amplitude: float = 0.2

# Fractal algorithm type
@export var algorithm: FractalAlgorithm = FractalAlgorithm.DIAMOND_SQUARE

enum FractalAlgorithm {
	DIAMOND_SQUARE,    # Classic terrain generation
	MIDPOINT_DISPLACEMENT, # Simple recursive midpoint
	RECURSIVE_SUBDIVISION  # Custom recursive subdivision
}

var rng: RandomNumberGenerator
var heights_grid: Array = []
var animation_time: float = 0.0
var base_heights: Array = []

func _ready():
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	super._ready()

func generate_space():
	# Generate fractal terrain using selected algorithm
	match algorithm:
		FractalAlgorithm.DIAMOND_SQUARE:
			_generate_diamond_square()
		FractalAlgorithm.MIDPOINT_DISPLACEMENT:
			_generate_midpoint_displacement()
		FractalAlgorithm.RECURSIVE_SUBDIVISION:
			_generate_recursive_subdivision()

	# Convert to flat array for mesh generation
	var heights = []
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var grid_x = clamp(x * heights_grid.size() / resolution, 0, heights_grid.size() - 1)
			var grid_z = clamp(z * heights_grid[0].size() / resolution, 0, heights_grid[0].size() - 1)
			heights.append(heights_grid[grid_x][grid_z])

	base_heights = heights.duplicate()

	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	_setup_material()

func _generate_diamond_square():
	"""Diamond-square algorithm for realistic terrain"""
	# Size must be power of 2 + 1
	var size = int(pow(2, fractal_depth)) + 1
	heights_grid = []

	# Initialize grid
	for i in range(size):
		heights_grid.append([])
		for j in range(size):
			heights_grid[i].append(0.0)

	# Set corner values
	heights_grid[0][0] = rng.randf_range(-initial_displacement, initial_displacement)
	heights_grid[0][size-1] = rng.randf_range(-initial_displacement, initial_displacement)
	heights_grid[size-1][0] = rng.randf_range(-initial_displacement, initial_displacement)
	heights_grid[size-1][size-1] = rng.randf_range(-initial_displacement, initial_displacement)

	var displacement = initial_displacement
	var step_size = size - 1

	while step_size > 1:
		var half_step = step_size / 2

		# Diamond step
		for z in range(0, size - 1, step_size):
			for x in range(0, size - 1, step_size):
				var avg = (heights_grid[x][z] +
						  heights_grid[x + step_size][z] +
						  heights_grid[x][z + step_size] +
						  heights_grid[x + step_size][z + step_size]) / 4.0
				heights_grid[x + half_step][z + half_step] = avg + rng.randf_range(-displacement, displacement)

		# Square step
		for z in range(0, size, half_step):
			for x in range((z + half_step) % step_size, size, step_size):
				var sum = 0.0
				var count = 0

				if x >= half_step:
					sum += heights_grid[x - half_step][z]
					count += 1
				if x + half_step < size:
					sum += heights_grid[x + half_step][z]
					count += 1
				if z >= half_step:
					sum += heights_grid[x][z - half_step]
					count += 1
				if z + half_step < size:
					sum += heights_grid[x][z + half_step]
					count += 1

				heights_grid[x][z] = (sum / count) + rng.randf_range(-displacement, displacement)

		displacement *= roughness
		step_size = half_step

func _generate_midpoint_displacement():
	"""Simple midpoint displacement for rougher terrain"""
	var size = int(pow(2, fractal_depth)) + 1
	heights_grid = []

	for i in range(size):
		heights_grid.append([])
		for j in range(size):
			heights_grid[i].append(0.0)

	# Recursive subdivision
	_subdivide_midpoint(0, 0, size - 1, size - 1, initial_displacement)

func _subdivide_midpoint(x1: int, z1: int, x2: int, z2: int, displacement: float):
	if x2 - x1 <= 1 and z2 - z1 <= 1:
		return

	var mid_x = (x1 + x2) / 2
	var mid_z = (z1 + z2) / 2

	# Center point
	heights_grid[mid_x][mid_z] = (
		heights_grid[x1][z1] +
		heights_grid[x1][z2] +
		heights_grid[x2][z1] +
		heights_grid[x2][z2]
	) / 4.0 + rng.randf_range(-displacement, displacement)

	# Edge midpoints
	if heights_grid[mid_x][z1] == 0.0:
		heights_grid[mid_x][z1] = (heights_grid[x1][z1] + heights_grid[x2][z1]) / 2.0 + rng.randf_range(-displacement, displacement)
	if heights_grid[mid_x][z2] == 0.0:
		heights_grid[mid_x][z2] = (heights_grid[x1][z2] + heights_grid[x2][z2]) / 2.0 + rng.randf_range(-displacement, displacement)
	if heights_grid[x1][mid_z] == 0.0:
		heights_grid[x1][mid_z] = (heights_grid[x1][z1] + heights_grid[x1][z2]) / 2.0 + rng.randf_range(-displacement, displacement)
	if heights_grid[x2][mid_z] == 0.0:
		heights_grid[x2][mid_z] = (heights_grid[x2][z1] + heights_grid[x2][z2]) / 2.0 + rng.randf_range(-displacement, displacement)

	var new_displacement = displacement * roughness

	# Recurse on quadrants
	_subdivide_midpoint(x1, z1, mid_x, mid_z, new_displacement)
	_subdivide_midpoint(mid_x, z1, x2, mid_z, new_displacement)
	_subdivide_midpoint(x1, mid_z, mid_x, z2, new_displacement)
	_subdivide_midpoint(mid_x, mid_z, x2, z2, new_displacement)

func _generate_recursive_subdivision():
	"""Custom recursive subdivision with fractal patterns"""
	var size = int(pow(2, fractal_depth)) + 1
	heights_grid = []

	for i in range(size):
		heights_grid.append([])
		for j in range(size):
			heights_grid[i].append(rng.randf_range(-initial_displacement * 0.1, initial_displacement * 0.1))

	# Apply recursive fractal perturbations
	_apply_fractal_layer(size, initial_displacement, fractal_depth)

func _apply_fractal_layer(size: int, displacement: float, depth: int):
	if depth <= 0:
		return

	var step = int(pow(2, depth - 1))

	for z in range(0, size, step):
		for x in range(0, size, step):
			if x < size and z < size:
				heights_grid[x][z] += rng.randf_range(-displacement, displacement)

	_apply_fractal_layer(size, displacement * roughness, depth - 1)

func _setup_material():
	var material = StandardMaterial3D.new()

	# Fractal gradient coloring based on height
	material.albedo_color = Color(0.6, 0.4, 0.8)  # Purple base
	material.roughness = 0.7
	material.metallic = 0.3
	material.emission_enabled = true
	material.emission = Color(0.3, 0.2, 0.4) * 0.3

	mesh_instance.material_override = material

func _process(delta):
	if not enable_animation:
		return

	animation_time += delta * animation_speed
	_update_animated_mesh()

func _update_animated_mesh():
	"""Animate the fractal terrain with wave-like motion"""
	if base_heights.is_empty():
		return

	var animated_heights = []
	for i in range(base_heights.size()):
		var x = i % (resolution + 1)
		var z = i / (resolution + 1)
		var wave = sin(animation_time + x * 0.1 + z * 0.1) * animation_amplitude
		animated_heights.append(base_heights[i] + wave)

	var mesh = create_mesh_from_heights(animated_heights)
	mesh_instance.mesh = mesh

# Public API
func regenerate():
	"""Regenerate the fractal with a new random seed"""
	rng.seed = randi()
	generate_space()

func set_algorithm(new_algorithm: FractalAlgorithm):
	algorithm = new_algorithm
	generate_space()

func set_fractal_depth(depth: int):
	fractal_depth = clamp(depth, 2, 8)
	generate_space()

func set_roughness(new_roughness: float):
	roughness = clamp(new_roughness, 0.1, 1.0)
	generate_space()
