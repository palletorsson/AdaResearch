extends Node3D

@export var interpolation_method: int = 1  # 0=None, 1=Linear, 2=Smoothstep
@export var grid_size: int = 10
@export var amplitude: float = 1.0

var noise_field_size = 20
var noise_resolution = 0.5
var noise_cubes: Array[CSGBox3D] = []
var grid_lines: Array[CSGBox3D] = []
var random_values: Dictionary = {}
var show_grid = true

func _ready():
	# Initialize random values for the grid
	randomize()
	_generate_random_values()
	
	# Create the noise field
	create_noise_field()
	create_grid_lines()

func _generate_random_values():
	random_values.clear()
	for x in range(-grid_size, grid_size + 1):
		for z in range(-grid_size, grid_size + 1):
			var key = Vector2(x, z)
			random_values[key] = randf_range(-1.0, 1.0)

func create_noise_field():
	# Clear existing cubes
	for cube in noise_cubes:
		cube.queue_free()
	noise_cubes.clear()
	
	# Create grid of cubes
	for x in range(-noise_field_size/2, noise_field_size/2):
		for z in range(-noise_field_size/2, noise_field_size/2):
			var cube = CSGBox3D.new()
			cube.size = Vector3(noise_resolution, noise_resolution, noise_resolution)
			
			# Position the cube
			var world_x = x * noise_resolution
			var world_z = z * noise_resolution
			
			# Generate noise value
			var noise_value = generate_value_noise_at(world_x, world_z)
			var world_y = noise_value * amplitude
			
			cube.position = Vector3(world_x, world_y, world_z)
			
			# Set color based on height
			var height_ratio = (world_y + amplitude) / (amplitude * 2)
			var color = lerp(Color(0.4, 0.8, 0.4), Color(0.8, 0.4, 0.8), height_ratio)
			
			var material = StandardMaterial3D.new()
			material.albedo_color = color
			material.metallic = 0.1
			material.roughness = 0.9
			cube.material_override = material
			
			add_child(cube)
			noise_cubes.append(cube)

func create_grid_lines():
	# Clear existing grid lines
	for line in grid_lines:
		line.queue_free()
	grid_lines.clear()
	
	if not show_grid:
		return
	
	# Create vertical grid lines
	for x in range(-grid_size, grid_size + 1):
		var line = CSGBox3D.new()
		line.size = Vector3(0.05, amplitude * 2, noise_field_size * noise_resolution)
		line.position = Vector3(x, 0, 0)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1, 1, 1, 0.3)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		line.material_override = material
		
		add_child(line)
		grid_lines.append(line)
	
	# Create horizontal grid lines
	for z in range(-grid_size, grid_size + 1):
		var line = CSGBox3D.new()
		line.size = Vector3(noise_field_size * noise_resolution, amplitude * 2, 0.05)
		line.position = Vector3(0, 0, z)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1, 1, 1, 0.3)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		line.material_override = material
		
		add_child(line)
		grid_lines.append(line)

func generate_value_noise_at(x: float, z: float) -> float:
	# Convert world coordinates to grid coordinates
	var grid_x = round(x)
	var grid_z = round(z)
	
	# Get the four surrounding grid points
	var x1 = floor(x)
	var x2 = ceil(x)
	var z1 = floor(z)
	var z2 = ceil(z)
	
	# Get random values at grid points
	var v11 = random_values.get(Vector2(x1, z1), 0.0)
	var v12 = random_values.get(Vector2(x1, z2), 0.0)
	var v21 = random_values.get(Vector2(x2, z1), 0.0)
	var v22 = random_values.get(Vector2(x2, z2), 0.0)
	
	# Calculate interpolation factors
	var fx = (x - x1) / (x2 - x1) if x2 != x1 else 0.0
	var fz = (z - z1) / (z2 - z1) if z2 != z1 else 0.0
	
	# Apply interpolation method
	if interpolation_method == 1:  # Linear
		fx = fx
		fz = fz
	elif interpolation_method == 2:  # Smoothstep
		fx = smoothstep(0.0, 1.0, fx)
		fz = smoothstep(0.0, 1.0, fz)
	# interpolation_method == 0 means no interpolation (step function)
	
	# Bilinear interpolation
	var v1 = lerp(v11, v21, fx)
	var v2 = lerp(v12, v22, fx)
	var result = lerp(v1, v2, fz)
	
	return result

func update_noise_field():
	for i in range(noise_cubes.size()):
		var cube = noise_cubes[i]
		var x = (i % int(noise_field_size / noise_resolution) - noise_field_size / (2 * noise_resolution)) * noise_resolution
		var z = (i / int(noise_field_size / noise_resolution) - noise_field_size / (2 * noise_resolution)) * noise_resolution
		
		var noise_value = generate_value_noise_at(x, z)
		var world_y = noise_value * amplitude
		
		cube.position.y = world_y
		
		# Update color based on height
		var height_ratio = (world_y + amplitude) / (amplitude * 2)
		var color = lerp(Color(0.4, 0.8, 0.4), Color(0.8, 0.4, 0.8), height_ratio)
		
		if cube.material_override:
			cube.material_override.albedo_color = color

func regenerate_noise():
	_generate_random_values()
	update_noise_field()

func toggle_grid_lines():
	show_grid = !show_grid
	create_grid_lines()
