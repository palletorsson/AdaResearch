extends Node3D

@export var frequency: float = 1.0
@export var amplitude: float = 1.0
@export var persistence: float = 0.5

## DNA axes (stage 2, promoted 2026-07-29). Declared and documented on the scene
## root, SimplexNoise.gd; mirrored here because this is the node that owns the
## geometry. Defaults are the pre-promotion hard-coded values.
@export var readout: String = "relief"  # relief | plate | column
@export var octaves: int = 4

## THE COMPARISON CONTRACT (2026-09-10, the Noise_Perlin_Simplex pilot in
## doc/research/waves-chance-noise). A fair comparison of two noise bases needs
## everything else held equal, and three things here were not: the seed was
## randi() at build, the colour ramp was this display's own, and the field's
## size was a constant. Each is now declared, and each default is the shipped
## behaviour, so the other eight placements are what they were.
##   seed_value  -1 keeps randi(); any other integer makes the field repeatable
##   ramp        "legacy" is pink-to-teal; "shared" is the ramp both displays use
##   field cells set once through rebuild_size()
@export var seed_value: int = -1
@export var ramp: String = "legacy"  # legacy | shared

## The height ramp, unchanged by the promotion: low samples read pink, high teal.
const LOW_COLOR := Color(0.8, 0.3, 0.6)
const HIGH_COLOR := Color(0.3, 0.8, 0.6)
## The one ramp both noise displays can agree on — identical constants in
## NoiseVisualizer.gd, deliberately, so colour cannot be a difference.
const SHARED_LOW := Color(0.16, 0.22, 0.42)
const SHARED_HIGH := Color(0.96, 0.86, 0.48)

var noise_field_size = 20
var noise_resolution = 0.5
var noise_cubes: Array[CSGBox3D] = []
var noise_generator: FastNoiseLite
## The seed the field is actually drawn from — declared or drawn — so a probe and
## the panel can say which.
var current_seed: int = 0

func _ready() -> void:
	# Initialize noise generator (FastNoiseLite is Godot 4's noise implementation)
	noise_generator = FastNoiseLite.new()
	current_seed = seed_value if seed_value >= 0 else randi()
	noise_generator.seed = current_seed
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
		# Read the same address used when the cube was created.
		var x: float = cube.position.x
		var z: float = cube.position.z

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
	var color = lerp(SHARED_LOW, SHARED_HIGH, height_ratio) if ramp == "shared" \
			else lerp(LOW_COLOR, HIGH_COLOR, height_ratio)
	if cube.material_override:
		cube.material_override.albedo_color = color
		# A shared colour comparison also needs the same reflective finish.
		cube.material_override.metallic = 0.1 if ramp == "shared" else 0.2
		cube.material_override.roughness = 0.8 if ramp == "shared" else 0.7

## A new seed, and it is RECORDED: regenerate is not "random", it is "another
## seed we can name", which is what makes a replay per basis possible.
func regenerate_noise() -> void:
	current_seed = randi()
	noise_generator.seed = current_seed
	update_noise_field()

## Back to a named seed. REPLAY on the panel calls this with the declared one.
func reseed(s: int) -> void:
	current_seed = s
	noise_generator.seed = s
	update_noise_field()

## Rebuild with a different number of cells on a side. The resolution stays
## 0.5 m, so a smaller field is fewer cubes, not smaller cubes — legible from
## the aisle, and two of them fit in one hall.
func rebuild_size(cells: int) -> void:
	var n: int = maxi(2, cells)
	if n % 2 == 1:
		n += 1
	if n == noise_field_size:
		return
	noise_field_size = n
	create_noise_field()

## The field's value at a coordinate, as the probe readout and a test read it.
func sample_at(x: float, z: float) -> float:
	return generate_noise_at(x, z)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
