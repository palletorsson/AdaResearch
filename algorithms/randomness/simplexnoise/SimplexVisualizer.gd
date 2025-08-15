extends Node3D

@export var frequency: float = 1.0
@export var amplitude: float = 1.0
@export var persistence: float = 0.5

var noise_field_size = 20
var noise_resolution = 0.5
var noise_cubes: Array[CSGBox3D] = []
var noise_generator: FastNoiseLite

func _ready():
	# Initialize noise generator (FastNoiseLite is Godot 4's noise implementation)
	noise_generator = FastNoiseLite.new()
	noise_generator.seed = randi()
	noise_generator.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_generator.fractal_octaves = 4
	noise_generator.frequency = 0.05  # Equivalent to period = 20.0
	noise_generator.fractal_gain = persistence
	
	# Create the noise field
	create_noise_field()

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
			var noise_value = generate_noise_at(world_x, world_z)
			var world_y = noise_value * amplitude
			
			cube.position = Vector3(world_x, world_y, world_z)
			
			# Set color based on height
			var height_ratio = (world_y + amplitude) / (amplitude * 2)
			var color = lerp(Color(0.8, 0.3, 0.6), Color(0.3, 0.8, 0.6), height_ratio)
			
			var material = StandardMaterial3D.new()
			material.albedo_color = color
			material.metallic = 0.2
			material.roughness = 0.7
			cube.material_override = material
			
			add_child(cube)
			noise_cubes.append(cube)

func generate_noise_at(x: float, z: float) -> float:
	return noise_generator.get_noise_2d(x * frequency, z * frequency)

func update_noise_field():
	noise_generator.fractal_gain = persistence
	
	for i in range(noise_cubes.size()):
		var cube = noise_cubes[i]
		var x = (i % int(noise_field_size / noise_resolution) - noise_field_size / (2 * noise_resolution)) * noise_resolution
		var z = (i / int(noise_field_size / noise_resolution) - noise_field_size / (2 * noise_resolution)) * noise_resolution
		
		var noise_value = generate_noise_at(x, z)
		var world_y = noise_value * amplitude
		
		cube.position.y = world_y
		
		# Update color based on height
		var height_ratio = (world_y + amplitude) / (amplitude * 2)
		var color = lerp(Color(0.8, 0.3, 0.6), Color(0.3, 0.8, 0.6), height_ratio)
		
		if cube.material_override:
			cube.material_override.albedo_color = color

func regenerate_noise():
	noise_generator.seed = randi()
	update_noise_field()
