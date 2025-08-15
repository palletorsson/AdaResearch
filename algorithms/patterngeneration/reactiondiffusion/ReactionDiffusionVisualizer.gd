extends Node3D

@export var feed_rate: float = 0.055
@export var kill_rate: float = 0.062
@export var diffusion_a: float = 1.0
@export var diffusion_b: float = 0.5
@export var pattern_type: int = 0  # 0=Spots, 1=Stripes, 2=Waves, 3=Mazes

var grid_size = 32
var grid_resolution = 0.5
var grid_cubes: Array[CSGBox3D] = []
var grid_a: Array[Array] = []  # Chemical A concentration
var grid_b: Array[Array] = []  # Chemical B concentration
var is_running = false
var simulation_time = 0.0

func _ready():
	initialize_grid()
	create_visual_grid()
	set_initial_conditions()

func _process(delta):
	if is_running:
		simulation_time += delta
		update_simulation()

func initialize_grid():
	# Initialize 2D arrays for chemical concentrations
	grid_a.clear()
	grid_b.clear()
	
	for x in range(grid_size):
		grid_a.append([])
		grid_b.append([])
		for y in range(grid_size):
			grid_a[x].append(1.0)
			grid_b[x].append(0.0)

func create_visual_grid():
	# Clear existing cubes
	for cube in grid_cubes:
		cube.queue_free()
	grid_cubes.clear()
	
	# Create grid of cubes
	for x in range(grid_size):
		for y in range(grid_size):
			var cube = CSGBox3D.new()
			cube.size = Vector3(grid_resolution, grid_resolution, grid_resolution)
			
			# Position the cube
			var world_x = (x - grid_size/2) * grid_resolution
			var world_z = (y - grid_size/2) * grid_resolution
			cube.position = Vector3(world_x, 0, world_z)
			
			# Set initial material
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.1, 0.8, 0.3)
			material.metallic = 0.0
			material.roughness = 1.0
			cube.material_override = material
			
			add_child(cube)
			grid_cubes.append(cube)

func set_initial_conditions():
	match pattern_type:
		0:  # Spots
			set_random_perturbations(0.1)
		1:  # Stripes
			set_stripe_perturbations()
		2:  # Waves
			set_wave_perturbations()
		3:  # Mazes
			set_maze_perturbations()

func set_random_perturbations(intensity: float):
	for x in range(grid_size):
		for y in range(grid_size):
			if randf() < 0.1:  # 10% chance of perturbation
				grid_a[x][y] += randf_range(-intensity, intensity)
				grid_b[x][y] += randf_range(-intensity, intensity)

func set_stripe_perturbations():
	for x in range(grid_size):
		for y in range(grid_size):
			var stripe_factor = sin(x * PI / 8.0) * 0.1
			grid_a[x][y] += stripe_factor
			grid_b[x][y] += stripe_factor

func set_wave_perturbations():
	for x in range(grid_size):
		for y in range(grid_size):
			var wave_factor = sin(x * PI / 16.0) * cos(y * PI / 16.0) * 0.1
			grid_a[x][y] += wave_factor
			grid_b[x][y] += wave_factor

func set_maze_perturbations():
	for x in range(grid_size):
		for y in range(grid_size):
			var maze_factor = (sin(x * PI / 4.0) + cos(y * PI / 4.0)) * 0.05
			grid_a[x][y] += maze_factor
			grid_b[x][y] += maze_factor

func update_simulation():
	# Create temporary arrays for the new state
	var new_a = grid_a.duplicate(true)
	var new_b = grid_b.duplicate(true)
	
	# Update each grid cell
	for x in range(grid_size):
		for y in range(grid_size):
			var laplacian_a = compute_laplacian(grid_a, x, y)
			var laplacian_b = compute_laplacian(grid_b, x, y)
			
			# Gray-Scott reaction-diffusion equations
			var reaction = grid_a[x][y] * grid_b[x][y] * grid_b[x][y]
			new_a[x][y] = grid_a[x][y] + (diffusion_a * laplacian_a - reaction + feed_rate * (1 - grid_a[x][y])) * 0.1
			new_b[x][y] = grid_b[x][y] + (diffusion_b * laplacian_b + reaction - (kill_rate + feed_rate) * grid_b[x][y]) * 0.1
			
			# Clamp values
			new_a[x][y] = clamp(new_a[x][y], 0.0, 1.0)
			new_b[x][y] = clamp(new_b[x][y], 0.0, 1.0)
	
	# Update the grid
	grid_a = new_a
	grid_b = new_b
	
	# Update visualization
	update_visualization()

func compute_laplacian(grid: Array, x: int, y: int) -> float:
	var sum = 0.0
	var center = grid[x][y]
	
	# 5-point stencil for 2D Laplacian
	if x > 0:
		sum += grid[x-1][y] - center
	if x < grid_size - 1:
		sum += grid[x+1][y] - center
	if y > 0:
		sum += grid[x][y-1] - center
	if y < grid_size - 1:
		sum += grid[x][y+1] - center
	
	return sum

func update_visualization():
	for i in range(grid_cubes.size()):
		var x = i / grid_size
		var y = i % grid_size
		
		if x < grid_size and y < grid_size:
			var cube = grid_cubes[i]
			var concentration_a = grid_a[x][y]
			var concentration_b = grid_b[x][y]
			
			# Set height based on chemical concentration
			var height = (concentration_a + concentration_b) * 0.5
			cube.position.y = height * 2.0
			
			# Set color based on chemical concentrations
			var color = Color(concentration_a, concentration_b, 0.0)
			if cube.material_override:
				cube.material_override.albedo_color = color

func start_simulation():
	is_running = true

func stop_simulation():
	is_running = false

func reset_pattern():
	simulation_time = 0.0
	initialize_grid()
	set_initial_conditions()
	update_visualization()

func update_parameters():
	# This function is called when parameters change
	# The simulation will use the new parameters on the next update
	pass

func export_pattern():
	# This could save the current pattern as an image or 3D model
	print("Export functionality - could save pattern as image or 3D model")

