extends Node3D

@export var frequency: float = 1.0
@export var amplitude: float = 1.0
@export var octaves: int = 4
@export var animation_offset: float = 0.0

## DNA axis (see PerlinNoise.gd) — which basis fills the field. "simplex" is what
## the shipped code has always set, so it stays the default.
@export var generator: String = "simplex"
## DNA axis — how the field is read: relief (elevation), plate (flat image),
## column (bars standing on the ground). Same vocabulary as the simplex sibling.
@export var readout: String = "relief"  # relief | plate | column

var noise_field_size = 20
var noise_resolution = 0.5
var noise_cubes: Array[CSGBox3D] = []
var noise_generator: FastNoiseLite

func _ready() -> void:
	# Initialize noise generator
	noise_generator = FastNoiseLite.new()
	noise_generator.seed = randi()
	noise_generator.noise_type = _noise_type_for(generator)
	noise_generator.fractal_octaves = octaves
	noise_generator.frequency = 0.05
	
	# Create the noise field
	create_noise_field()

func create_noise_field() -> void:
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
			_shape_cube(cube, world_y)
			
			# Set color based on height
			var height_ratio = (world_y + amplitude) / (amplitude * 2)
			var color = lerp(Color(0.2, 0.4, 0.8), Color(0.8, 0.6, 0.2), height_ratio)
			
			var material = StandardMaterial3D.new()
			material.albedo_color = color
			material.metallic = 0.1
			material.roughness = 0.8
			cube.material_override = material
			
			add_child(cube)
			noise_cubes.append(cube)

func generate_noise_at(x: float, z: float) -> float:
	return noise_generator.get_noise_2d(x * frequency + animation_offset, z * frequency + animation_offset)

func update_noise_field() -> void:
	for i in range(noise_cubes.size()):
		var cube = noise_cubes[i]
		var x = (i % int(noise_field_size / noise_resolution) - noise_field_size / (2 * noise_resolution)) * noise_resolution
		var z = (i / int(noise_field_size / noise_resolution) - noise_field_size / (2 * noise_resolution)) * noise_resolution
		
		var noise_value = generate_noise_at(x, z)
		var world_y = noise_value * amplitude
		
		cube.position.y = world_y
		_shape_cube(cube, world_y)

		# Update color based on height
		var height_ratio = (world_y + amplitude) / (amplitude * 2)
		var color = lerp(Color(0.2, 0.4, 0.8), Color(0.8, 0.6, 0.2), height_ratio)
		
		if cube.material_override:
			cube.material_override.albedo_color = color

## How one sample is made visible, per the `readout` axis. Deliberately identical
## to SimplexVisualizer._express_sample — the two artifacts ask the same question of
## different generators, so they answer in the same words.
##   relief — the legacy line, cube.position.y = value: the field is TERRAIN
##   plate  — every cube on the floor, value survives only as colour: the field is
##            an IMAGE of a scalar function, and the mountains were our reading
##   column — the cube grows from the floor to its value: each sample is a
##            MEASURED QUANTITY standing in a bar chart, noise before it is scenery
func _shape_cube(cube: CSGBox3D, world_y: float) -> void:
	var res: float = float(noise_resolution)
	match readout:
		"plate":
			_size_to(cube, Vector3(res, res, res))
			cube.position.y = 0.0
		"column":
			var height: float = max(0.02, world_y + amplitude)
			_size_to(cube, Vector3(res, height, res))
			cube.position.y = height * 0.5
		_:
			# relief — the shipped default: a uniform cube lifted to its sample.
			_size_to(cube, Vector3(res, res, res))
			cube.position.y = world_y


func _size_to(cube: CSGBox3D, target: Vector3) -> void:
	# CSG rebuilds on every size assignment, so only write when it differs.
	if cube.size != target:
		cube.size = target


func _noise_type_for(name_in: String) -> int:
	match name_in:
		"perlin":
			return FastNoiseLite.TYPE_PERLIN
		"value":
			return FastNoiseLite.TYPE_VALUE
		"cellular":
			return FastNoiseLite.TYPE_CELLULAR
		_:
			return FastNoiseLite.TYPE_SIMPLEX


## Guarded: rebuild only when a declared axis actually changed and the field has
## already been built once.
func set_dna(new_generator: String, new_readout: String) -> void:
	var changed: bool = false
	if new_generator != generator:
		generator = new_generator
		if noise_generator:
			noise_generator.noise_type = _noise_type_for(generator)
		changed = true
	if new_readout != readout:
		readout = new_readout
		changed = true
	if changed and not noise_cubes.is_empty():
		update_noise_field()


func regenerate_noise() -> void:
	noise_generator.seed = randi()
	update_noise_field()

func on_animation_offset_changed() -> void:
	update_noise_field()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
