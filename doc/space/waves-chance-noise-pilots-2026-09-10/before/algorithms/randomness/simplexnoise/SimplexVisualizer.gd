extends Node3D

@export var frequency: float = 1.0
@export var amplitude: float = 1.0
@export var persistence: float = 0.5

## DNA axes (stage 2, promoted 2026-07-29). Declared and documented on the scene
## root, SimplexNoise.gd; mirrored here because this is the node that owns the
## geometry. Defaults are the pre-promotion hard-coded values.
@export var readout: String = "relief"  # relief | plate | column
@export var octaves: int = 4

## The height ramp, unchanged by the promotion: low samples read pink, high teal.
const LOW_COLOR := Color(0.8, 0.3, 0.6)
const HIGH_COLOR := Color(0.3, 0.8, 0.6)

var noise_field_size = 20
var noise_resolution = 0.5
var noise_cubes: Array[CSGBox3D] = []
var noise_generator: FastNoiseLite

func _ready() -> void:
	# Initialize noise generator (FastNoiseLite is Godot 4's noise implementation)
	noise_generator = FastNoiseLite.new()
	noise_generator.seed = randi()
	noise_generator.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_generator.fractal_octaves = octaves
	noise_generator.frequency = 0.05  # Equivalent to period = 20.0
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

			# x and z are fixed here and never touched again; only the sample's
			# EXPRESSION (y, size, colour) belongs to the readout axis.
			cube.position = Vector3(world_x, 0.0, world_z)

			var material = StandardMaterial3D.new()
			material.metallic = 0.2
			material.roughness = 0.7
			cube.material_override = material
			_express_sample(cube, world_y)

			add_child(cube)
			noise_cubes.append(cube)

func generate_noise_at(x: float, z: float) -> float:
	return noise_generator.get_noise_2d(x * frequency, z * frequency)

func update_noise_field() -> void:
	noise_generator.fractal_gain = persistence
	noise_generator.fractal_octaves = octaves

	for i in range(noise_cubes.size()):
		var cube = noise_cubes[i]
		var x = (i % int(noise_field_size / noise_resolution) - noise_field_size / (2 * noise_resolution)) * noise_resolution
		var z = (i / int(noise_field_size / noise_resolution) - noise_field_size / (2 * noise_resolution)) * noise_resolution

		var noise_value = generate_noise_at(x, z)
		var world_y = noise_value * amplitude

		_express_sample(cube, world_y)

## How one sample is made visible, per the `readout` axis. This touches y, size and
## colour only — never x or z, which are set once at creation.
##   relief — the legacy line, cube.position.y = value: the field is TERRAIN
##   plate  — every cube on the floor, value survives only as colour: the field is
##            an IMAGE of a scalar function, and the mountains were our reading
##   column — the cube grows from the floor to its value: each sample is a
##            MEASURED QUANTITY standing in a bar chart, noise before it is scenery
func _express_sample(cube: CSGBox3D, world_y: float) -> void:
	var res: float = noise_resolution
	match readout:
		"plate":
			cube.size = Vector3(res, res, res)
			cube.position.y = 0.0
		"column":
			var height: float = max(0.02, world_y + amplitude)
			cube.size = Vector3(res, height, res)
			cube.position.y = height * 0.5
		_:
			cube.size = Vector3(res, res, res)
			cube.position.y = world_y

	var height_ratio = (world_y + amplitude) / (amplitude * 2)
	var color = lerp(LOW_COLOR, HIGH_COLOR, height_ratio)
	if cube.material_override:
		cube.material_override.albedo_color = color

func regenerate_noise() -> void:
	noise_generator.seed = randi()
	update_noise_field()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
