extends Node3D

@export var frequency: float = 1.0
@export var amplitude: float = 1.0
@export var octaves: int = 4
@export var animation_offset: float = 0.0
## The fractal gain, which the sibling SimplexVisualizer sets from its
## persistence slider and this file never set at all — so it ran on
## FastNoiseLite's default of 0.5, the same number by luck rather than by
## contract. Declared now (2026-09-10) so the two fields share it on purpose.
@export var persistence: float = 0.5

## DNA axis (see PerlinNoise.gd) — which basis fills the field. "simplex" is what
## the shipped code has always set, so it stays the default.
@export var generator: String = "simplex"
## DNA axis — how the field is read: relief (elevation), plate (flat image),
## column (bars standing on the ground). Same vocabulary as the simplex sibling.
@export var readout: String = "relief"  # relief | plate | column

## THE COMPARISON CONTRACT (2026-09-10) — the same three declarations as
## SimplexVisualizer.gd, for the same reason: a seed you can name, a ramp both
## displays share, and a field size set once. Defaults are the shipped behaviour.
@export var seed_value: int = -1
@export var ramp: String = "legacy"  # legacy | shared

## This display's own ramp, unchanged: low blue, high orange.
const LOW_COLOR := Color(0.2, 0.4, 0.8)
const HIGH_COLOR := Color(0.8, 0.6, 0.2)
## Identical constants to SimplexVisualizer.gd, deliberately.
const SHARED_LOW := Color(0.16, 0.22, 0.42)
const SHARED_HIGH := Color(0.96, 0.86, 0.48)

var noise_field_size = 20
var noise_resolution = 0.5
var noise_cubes: Array[CSGBox3D] = []
var noise_generator: FastNoiseLite
var current_seed: int = 0

func _ready() -> void:
	# Initialize noise generator
	noise_generator = FastNoiseLite.new()
	current_seed = seed_value if seed_value >= 0 else randi()
	noise_generator.seed = current_seed
	noise_generator.noise_type = _noise_type_for(generator)
	noise_generator.fractal_octaves = octaves
	noise_generator.frequency = 0.05
	noise_generator.fractal_gain = persistence

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

			var material = StandardMaterial3D.new()
			material.albedo_color = _ramp_color(world_y)
			material.metallic = 0.1
			material.roughness = 0.8
			cube.material_override = material

			add_child(cube)
			noise_cubes.append(cube)

func generate_noise_at(x: float, z: float) -> float:
	return noise_generator.get_noise_2d(x * frequency + animation_offset, z * frequency + animation_offset)

func update_noise_field() -> void:
	noise_generator.fractal_gain = persistence
	noise_generator.fractal_octaves = octaves
	for i in range(noise_cubes.size()):
		var cube = noise_cubes[i]
		# The cube's fixed x/z is its sampling address. Reconstructing it from
		# size/resolution used a different row width and transposed the field.
		var x: float = cube.position.x
		var z: float = cube.position.z

		var noise_value = generate_noise_at(x, z)
		var world_y = noise_value * amplitude

		cube.position.y = world_y
		_shape_cube(cube, world_y)

		if cube.material_override:
			cube.material_override.albedo_color = _ramp_color(world_y)

## Colour from height, through whichever ramp is declared.
func _ramp_color(world_y: float) -> Color:
	var height_ratio = (world_y + amplitude) / (amplitude * 2)
	if ramp == "shared":
		return lerp(SHARED_LOW, SHARED_HIGH, height_ratio)
	return lerp(LOW_COLOR, HIGH_COLOR, height_ratio)

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


## A new seed, recorded — see SimplexVisualizer.regenerate_noise.
func regenerate_noise() -> void:
	current_seed = randi()
	noise_generator.seed = current_seed
	update_noise_field()

func reseed(s: int) -> void:
	current_seed = s
	noise_generator.seed = s
	update_noise_field()

func rebuild_size(cells: int) -> void:
	var n: int = maxi(2, cells)
	if n % 2 == 1:
		n += 1
	if n == noise_field_size:
		return
	noise_field_size = n
	create_noise_field()

func sample_at(x: float, z: float) -> float:
	return generate_noise_at(x, z)

func on_animation_offset_changed() -> void:
	update_noise_field()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
