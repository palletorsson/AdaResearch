# RockFactory.gd - Generates collections of irregular rocks to demonstrate gaps
extends Node3D

# @identity
# essence: generates N rocks from a shared SphereMesh base — each rock gets random scale noise (deformation 3–7 iterations), position variation per spawn_mode (box/pile/grid/ring/cluster), and a color close to base_color; all built at _ready()
# desire: to fill a space with irregular mass that reads as geological rather than computational — the learner should feel that rocks have weight and history even though each is a deformed sphere
# critical_parameter: deformation_min/max (3–7 noise iterations) — below 3 the rocks look like potatoes, above 7 they become spiky; this range is the sweet spot between smooth and geological
# triggers: auto_generate calls generate() in _ready(); generate() clears previous rocks, seeds RNG, then calls _create_rock() N times with spawn_mode-dependent position; use_pride_colors cycles through 6 pride flag colors
# emerges: the pride colors mode transforms a geological simulator into a queer presence — the same irregular forms, the same physics, but the colors declare something about who placed them here
# needs: VR grab for individual rocks [has via StaticBody3D or RigidBody3D]; enable_gravity for falling rocks [has]; regenerate button [missing — only at _ready]; apply_grid_config [missing]
# relationships: used in Primitives_Ignorance map to demonstrate procedural generation of irregular forms; contrasts with capsule and combine_sphere (smooth geometry vs deformed); color variation ties to MosaicPalette pattern
# truth: a rock is a sphere that forgot its symmetry — every deformation iteration is a memory of force, and the result looks geological because geology IS iterated deformation applied to an original sphere

class_name RockFactory

@export_group("Rock Generation")
@export var number_of_rocks: int = 20
@export var generation_seed: int = 0  # 0 = random seed each time
@export var auto_generate: bool = true
@export var debug_output: bool = false  # Enable for debugging

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@export_group("Spawn Area")
@export var spawn_mode: SpawnMode = SpawnMode.BOX
@export var spawn_area: Vector3 = Vector3(2.0, 1.0, 2.0)
@export var container_height: float = 0.5  # Starting height for "crate fill" effect

@export_group("Rock Properties")
@export var rock_size_min: float = 0.15
@export var rock_size_max: float = 0.35
@export var deformation_min: float = 3.0
@export var deformation_max: float = 7.0
@export var roughness_min: float = 2.0
@export var roughness_max: float = 4.0
@export var subdivisions: int = 2  # 0-4, higher = smoother

@export_group("Visual Style")
@export var base_color: Color = Color(0.6, 0.6, 0.65)
@export var color_variation: float = 0.1  # How much colors vary between rocks
@export var use_pride_colors: bool = false

@export_group("Physics")
@export var create_collisions: bool = true
@export var make_rocks_static: bool = true
@export var enable_gravity: bool = false  # Set true for "falling rocks"
@export var rock_mass: float = 1.0  # Mass for dynamic rocks
@export var rock_friction: float = 0.8  # Surface friction
@export var rock_bounce: float = 0.1  # Bounciness (0-1)

enum SpawnMode {
	BOX,        # Fill a rectangular volume
	PILE,       # Heap on ground
	GRID,       # Regular grid with slight randomness
	RING,       # Circular arrangement
	CLUSTER     # Tight cluster at center
}

var rocks: Array[Node3D] = []
var rock_scene: PackedScene

# Pride flag colors for variation
const PRIDE_COLORS = [
	Color(0.9, 0.0, 0.0),    # Red
	Color(1.0, 0.5, 0.0),    # Orange
	Color(1.0, 0.9, 0.0),    # Yellow
	Color(0.0, 0.8, 0.0),    # Green
	Color(0.0, 0.4, 0.9),    # Blue
	Color(0.5, 0.0, 0.7)     # Purple
]

func _ready():
	if debug_output:
		print("RockFactory: _ready() called, auto_generate=%s, number_of_rocks=%d" % [auto_generate, number_of_rocks])
	if auto_generate:
		generate_rocks()

func apply_grid_config(config: Dictionary):
	"""Apply configuration from grid system (map_data.json # syntax)"""
	# Clear any existing rocks first to avoid race conditions
	clear_rocks()

	if config.has("number_of_rocks"):
		number_of_rocks = int(config["number_of_rocks"])
		if debug_output:
			print("RockFactory: Config set number_of_rocks = %d" % number_of_rocks)

	if config.has("generation_seed"):
		generation_seed = int(config["generation_seed"])
		if debug_output:
			print("RockFactory: Config set generation_seed = %d" % generation_seed)

	if config.has("spawn_mode"):
		spawn_mode = int(config["spawn_mode"])
		if debug_output:
			print("RockFactory: Config set spawn_mode = %d" % spawn_mode)

	if config.has("container_height"):
		container_height = float(config["container_height"])
		if debug_output:
			print("RockFactory: Config set container_height = %.2f" % container_height)

	if config.has("spawn_area_x"):
		spawn_area.x = float(config["spawn_area_x"])
	if config.has("spawn_area_y"):
		spawn_area.y = float(config["spawn_area_y"])
	if config.has("spawn_area_z"):
		spawn_area.z = float(config["spawn_area_z"])

	if config.has("rock_size_min"):
		rock_size_min = float(config["rock_size_min"])
	if config.has("rock_size_max"):
		rock_size_max = float(config["rock_size_max"])

	if config.has("use_pride_colors"):
		var val = config["use_pride_colors"]
		use_pride_colors = val if val is bool else (val == "true")
		if debug_output:
			print("RockFactory: Config set use_pride_colors = %s" % str(use_pride_colors))

	if config.has("enable_gravity"):
		var val = config["enable_gravity"]
		enable_gravity = val if val is bool else (val == "true")
		make_rocks_static = not enable_gravity
		if debug_output:
			print("RockFactory: Config set enable_gravity = %s" % str(enable_gravity))

	# Generate with new configuration
	if debug_output:
		print("RockFactory: Generating rocks with grid config")
	generate_rocks()

func generate_rocks():
	"""Generate all rocks based on current parameters"""
	# Clear existing rocks
	clear_rocks()

	# Set up random seed using instance-based RNG (avoids affecting global state)
	if generation_seed != 0:
		_rng.seed = generation_seed
	else:
		_rng.randomize()

	# Load rock scene
	rock_scene = preload("res://commons/primitives/proceduralrock/proceduralrock.tscn")

	if debug_output:
		print("RockFactory: Generating %d rocks in %s mode" % [number_of_rocks, SpawnMode.keys()[spawn_mode]])

	# Generate rocks based on spawn mode
	for i in range(number_of_rocks):
		_create_rock(i)

	if debug_output:
		print("RockFactory: Generated %d rocks" % rocks.size())

func _create_rock(index: int):
	"""Create a single rock with randomized properties"""
	var spawn_pos = _get_spawn_position(index)

	# Determine if this should be dynamic or static
	if enable_gravity and not make_rocks_static:
		# Create dynamic rock with RigidBody3D wrapper
		var rigid_body = RigidBody3D.new()
		rigid_body.name = "DynamicRock"
		rigid_body.position = spawn_pos
		rigid_body.mass = rock_mass
		rigid_body.physics_material_override = PhysicsMaterial.new()
		rigid_body.physics_material_override.friction = rock_friction
		rigid_body.physics_material_override.bounce = rock_bounce
		add_child(rigid_body)

		# Create rock as child of RigidBody
		var rock = rock_scene.instantiate()
		rigid_body.add_child(rock)

		# Configure rock properties
		rock.random_seed = _rng.randi()
		rock.base_radius = _rng.randf_range(rock_size_min, rock_size_max)
		rock.deformation = _rng.randf_range(deformation_min, deformation_max)
		rock.roughness = _rng.randf_range(roughness_min, roughness_max)
		rock.subdivisions = subdivisions
		rock.create_on_ready = false

		# Set color
		if use_pride_colors:
			rock.base_color = PRIDE_COLORS[index % PRIDE_COLORS.size()]
		else:
			rock.base_color = _vary_color(base_color, color_variation)

		# Generate mesh and collision
		rock.generate_rocks()

		# Find and move collision from StaticBody3D to RigidBody3D
		var static_body = rock.get_node_or_null("ProceduralRockCollision")
		if static_body and static_body.get_child_count() > 0:
			var collision_shape = static_body.get_child(0)
			static_body.remove_child(collision_shape)
			rigid_body.add_child(collision_shape)
			static_body.queue_free()

		rocks.append(rigid_body)
		if debug_output:
			print("RockFactory: Created dynamic rock %d" % index)
	else:
		# Create static rock (original simple approach)
		var rock = rock_scene.instantiate()
		add_child(rock)

		rock.random_seed = _rng.randi()
		rock.base_radius = _rng.randf_range(rock_size_min, rock_size_max)
		rock.deformation = _rng.randf_range(deformation_min, deformation_max)
		rock.roughness = _rng.randf_range(roughness_min, roughness_max)
		rock.subdivisions = subdivisions
		rock.create_on_ready = false

		if use_pride_colors:
			rock.base_color = PRIDE_COLORS[index % PRIDE_COLORS.size()]
		else:
			rock.base_color = _vary_color(base_color, color_variation)

		rock.position = spawn_pos
		rock.generate_rocks()

		rocks.append(rock)
		if debug_output:
			print("RockFactory: Created static rock %d" % index)

func _get_spawn_position(index: int) -> Vector3:
	"""Calculate spawn position based on spawn mode"""
	match spawn_mode:
		SpawnMode.BOX:
			return _box_position()
		SpawnMode.PILE:
			return _pile_position(index)
		SpawnMode.GRID:
			return _grid_position(index)
		SpawnMode.RING:
			return _ring_position(index)
		SpawnMode.CLUSTER:
			return _cluster_position()
	return Vector3.ZERO

func _box_position() -> Vector3:
	"""Random position within box volume"""
	return Vector3(
		_rng.randf_range(-spawn_area.x / 2, spawn_area.x / 2),
		_rng.randf_range(container_height, container_height + spawn_area.y),
		_rng.randf_range(-spawn_area.z / 2, spawn_area.z / 2)
	)

func _pile_position(index: int) -> Vector3:
	"""Pile rocks on ground with slight height variation"""
	var radius = sqrt(_rng.randf()) * spawn_area.x / 2
	var angle = _rng.randf() * TAU
	var layer = float(index) / number_of_rocks
	return Vector3(
		cos(angle) * radius,
		container_height + layer * spawn_area.y * 0.5,
		sin(angle) * radius
	)

func _grid_position(index: int) -> Vector3:
	"""Grid arrangement with randomness"""
	var grid_size = ceil(sqrt(number_of_rocks))
	var x_idx = index % int(grid_size)
	var z_idx = index / int(grid_size)
	var spacing_x = spawn_area.x / grid_size
	var spacing_z = spawn_area.z / grid_size

	return Vector3(
		-spawn_area.x / 2 + x_idx * spacing_x + _rng.randf_range(-spacing_x * 0.2, spacing_x * 0.2),
		container_height,
		-spawn_area.z / 2 + z_idx * spacing_z + _rng.randf_range(-spacing_z * 0.2, spacing_z * 0.2)
	)

func _ring_position(index: int) -> Vector3:
	"""Circular ring arrangement"""
	var angle = (float(index) / number_of_rocks) * TAU
	var radius = spawn_area.x / 2
	return Vector3(
		cos(angle) * radius,
		container_height,
		sin(angle) * radius
	)

func _cluster_position() -> Vector3:
	"""Tight cluster at center"""
	var offset = Vector3(
		_rng.randf_range(-spawn_area.x * 0.2, spawn_area.x * 0.2),
		_rng.randf_range(0, spawn_area.y * 0.3),
		_rng.randf_range(-spawn_area.z * 0.2, spawn_area.z * 0.2)
	)
	return Vector3(0, container_height, 0) + offset

func _vary_color(base: Color, variation: float) -> Color:
	"""Create slight color variation from base color"""
	return Color(
		clamp(base.r + _rng.randf_range(-variation, variation), 0.0, 1.0),
		clamp(base.g + _rng.randf_range(-variation, variation), 0.0, 1.0),
		clamp(base.b + _rng.randf_range(-variation, variation), 0.0, 1.0),
		base.a
	)

func clear_rocks():
	"""Remove all generated rocks"""
	for rock in rocks:
		if is_instance_valid(rock):
			rock.queue_free()
	rocks.clear()

func regenerate():
	"""Regenerate all rocks with current settings"""
	generate_rocks()

# Public API for runtime control
func set_rock_count(count: int):
	"""Change number of rocks and regenerate"""
	number_of_rocks = count
	regenerate()

func set_spawn_mode(mode: SpawnMode):
	"""Change spawn pattern and regenerate"""
	spawn_mode = mode
	regenerate()

func set_color_scheme(use_pride: bool):
	"""Toggle pride color scheme"""
	use_pride_colors = use_pride
	regenerate()

func get_gap_analysis() -> Dictionary:
	"""Analyze the gaps between rocks (for pedagogy)"""
	var total_volume = spawn_area.x * spawn_area.y * spawn_area.z
	var rock_volume = 0.0

	for rock in rocks:
		# Approximate rock volume as sphere
		if "base_radius" in rock:
			var radius = rock.base_radius * rock.scale.x
			rock_volume += (4.0 / 3.0) * PI * pow(radius, 3)

	var gap_volume = total_volume - rock_volume
	var packing_efficiency = (rock_volume / total_volume) * 100

	return {
		"total_volume": total_volume,
		"rock_volume": rock_volume,
		"gap_volume": gap_volume,
		"packing_efficiency": packing_efficiency,
		"gaps_percentage": (gap_volume / total_volume) * 100
	}
