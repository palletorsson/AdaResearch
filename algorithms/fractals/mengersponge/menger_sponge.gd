extends Node3D

# Menger Sponge Fractal Generator
# Creates a Menger sponge by subdividing cubes into 27 parts (3x3x3)
# and removing the center cube and the 6 face-centered cubes
# Each iteration subdivides all existing cubes

# Reference to the cube scene to instantiate
const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

# Menger sponge settings
@export var subdivision_interval: float = 1.0  # Time between subdivisions in seconds
@export var max_iterations: int = 4  # Maximum number of iterations (4 is visually impressive)
@export var auto_start: bool = true  # Start subdividing automatically

# Internal state
var current_iteration: int = 0
var subdivision_timer: float = 0.0
var is_subdividing: bool = false

# Menger sponge pattern: which of the 27 positions to KEEP (not remove)
# We remove 7 cubes: center (1) + 6 face centers
# Positions are indexed 0-26 in a 3x3x3 grid (x + y*3 + z*9)
var keep_positions = [
	# Bottom layer (y=0)
	0, 1, 2,      # Front row
	3, 5,         # Middle row (skip 4 - face center)
	6, 7, 8,      # Back row

	# Middle layer (y=1)
	9, 11,        # Front row (skip 10 - face center)
	15, 17,       # Back row (skip 16 - face center)
	# Skip 12, 13, 14 (middle row contains center 13 and two face centers 12, 14)

	# Top layer (y=2)
	18, 19, 20,   # Front row
	21, 23,       # Middle row (skip 22 - face center)
	24, 25, 26    # Back row
]

func _ready():
	print("MengerSponge: Ready")
	print("MengerSponge: Will create %d iterations" % max_iterations)

	# Start automatic subdivision if enabled
	if auto_start:
		is_subdividing = true
		print("MengerSponge: Auto-subdivision enabled")

func _process(delta: float):
	if not is_subdividing:
		return

	# Update timer
	subdivision_timer += delta

	# Check if it's time to subdivide
	if subdivision_timer >= subdivision_interval:
		subdivision_timer = 0.0
		perform_iteration()

# Perform one Menger sponge iteration
func perform_iteration():
	# Check if we've reached the maximum
	if current_iteration >= max_iterations:
		print("MengerSponge: Reached maximum iterations (%d)" % max_iterations)
		is_subdividing = false
		return

	current_iteration += 1
	print("MengerSponge: Starting iteration %d" % current_iteration)

	# Find all cube_scene instances in the scene
	var cubes = find_all_cube_scenes()

	if cubes.is_empty():
		print("MengerSponge: No cubes found to subdivide")
		is_subdividing = false
		return

	print("MengerSponge: Found %d cubes to subdivide" % cubes.size())

	# Subdivide each cube into a Menger pattern
	for cube in cubes:
		subdivide_cube_menger(cube)

	print("MengerSponge: Iteration %d complete" % current_iteration)

# Find all cube_scene instances in the scene tree
func find_all_cube_scenes() -> Array:
	var cubes = []
	_find_cubes_recursive(get_tree().current_scene, cubes)
	return cubes

# Recursive function to find cube scenes
func _find_cubes_recursive(node: Node, cubes: Array):
	# Check if this node is a cube_scene
	if node.name == "CubeScene" or node.name.begins_with("CubeScene"):
		cubes.append(node)

	# Recurse into children
	for child in node.get_children():
		_find_cubes_recursive(child, cubes)

# Subdivide a single cube into Menger sponge pattern
func subdivide_cube_menger(cube: Node3D):
	if not is_instance_valid(cube):
		return

	# Get the cube's current transform
	var cube_position = cube.global_position
	var cube_scale = cube.scale

	# Calculate the new scale (1/3 of original)
	var new_scale = cube_scale / 3.0

	# Calculate offset for positioning (1/3 of original size)
	var offset = cube_scale.x / 3.0

	# Get the parent of the cube
	var parent = cube.get_parent()
	if not parent:
		parent = self

	# Create cubes in a 3x3x3 grid, but only at the positions we want to keep
	var cubes_created = 0

	for i in range(27):
		# Check if this position should be kept
		if i not in keep_positions:
			continue

		# Calculate 3D position from 1D index
		var x = i % 3
		var y = (i / 3) % 3
		var z = i / 9

		# Calculate offset from center (-1, 0, or 1 in each dimension)
		var pos_offset = Vector3(
			(x - 1) * offset,
			(y - 1) * offset,
			(z - 1) * offset
		)

		# Create new cube
		var new_cube = CUBE_SCENE.instantiate()
		new_cube.global_position = cube_position + pos_offset
		new_cube.scale = new_scale

		# Add to the scene
		parent.add_child(new_cube)
		cubes_created += 1

	print("MengerSponge: Created %d sub-cubes, removed original at %s" % [cubes_created, cube_position])

	# Remove the original cube
	cube.queue_free()

# Manual control functions
func start_subdivision():
	is_subdividing = true
	subdivision_timer = 0.0
	print("MengerSponge: Started manually")

func stop_subdivision():
	is_subdividing = false
	print("MengerSponge: Stopped manually")

func reset():
	current_iteration = 0
	subdivision_timer = 0.0
	is_subdividing = false
	print("MengerSponge: Reset")

# Perform a single iteration step
func step():
	perform_iteration()
