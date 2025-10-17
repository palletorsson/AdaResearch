extends Node3D

# Cube Subdivision Fractal
# Finds all cube_scene instances in the scene and subdivides them into 8 quarter-sized cubes
# Repeats every second

# Reference to the cube scene to instantiate
const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

# Subdivision settings
@export var subdivision_interval: float = 1.0  # Time between subdivisions in seconds
@export var max_subdivisions: int = 5  # Maximum number of subdivision iterations
@export var auto_start: bool = true  # Start subdividing automatically
@export var cubes_per_iteration: int = 10  # Limit how many cubes to subdivide each iteration

# Internal state
var subdivision_count: int = 0
var subdivision_timer: float = 0.0
var is_subdividing: bool = false

func _ready():
	print("CubeSubdivision: Ready")

	# Start automatic subdivision if enabled
	if auto_start:
		is_subdividing = true
		print("CubeSubdivision: Auto-subdivision enabled")

func _process(delta: float):
	if not is_subdividing:
		return

	# Update timer
	subdivision_timer += delta

	# Check if it's time to subdivide
	if subdivision_timer >= subdivision_interval:
		subdivision_timer = 0.0
		perform_subdivision()

# Perform one subdivision iteration
func perform_subdivision():
	# Check if we've reached the maximum
	if subdivision_count >= max_subdivisions:
		print("CubeSubdivision: Reached maximum subdivisions (%d)" % max_subdivisions)
		is_subdividing = false
		return

	subdivision_count += 1
	print("CubeSubdivision: Starting subdivision iteration %d" % subdivision_count)

	# Find all cube_scene instances in the scene
	var cubes = find_all_cube_scenes()

	if cubes.is_empty():
		print("CubeSubdivision: No cubes found to subdivide")
		is_subdividing = false
		return

	print("CubeSubdivision: Found %d cubes to subdivide" % cubes.size())

	# Subdivide up to the configured number of cubes this iteration
	var to_process = min(cubes_per_iteration, cubes.size())
	for i in range(to_process):
		subdivide_cube(cubes[i])

	print("CubeSubdivision: Subdivision iteration %d complete" % subdivision_count)

# Find all cube_scene instances in the scene tree
func find_all_cube_scenes() -> Array:
	var cubes = []
	_find_cubes_recursive(get_tree().current_scene, cubes)
	return cubes

# Recursive function to find cube scenes
func _find_cubes_recursive(node: Node, cubes: Array):
	# Check if this node is a cube_scene (by checking its name pattern)
	if node.name == "CubeScene" or node.name.begins_with("CubeScene"):
		cubes.append(node)

	# Recurse into children
	for child in node.get_children():
		_find_cubes_recursive(child, cubes)

# Subdivide a single cube into 8 smaller cubes
func subdivide_cube(cube: Node3D):
	if not is_instance_valid(cube):
		return

	# Get the cube's current transform
	var cube_position = cube.global_position
	var cube_scale = cube.scale

	# Calculate the new scale (quarter size = half the scale)
	var new_scale = cube_scale * 0.5

	# Calculate offset for positioning the 8 new cubes
	# The offset is 1/4 of the original size in each direction
	var offset = (cube_scale.x * 0.25)

	# Create 8 new cubes in a 2x2x2 grid pattern
	var positions = [
		Vector3(-offset, -offset, -offset),  # Bottom-left-front
		Vector3(offset, -offset, -offset),   # Bottom-right-front
		Vector3(-offset, offset, -offset),   # Top-left-front
		Vector3(offset, offset, -offset),    # Top-right-front
		Vector3(-offset, -offset, offset),   # Bottom-left-back
		Vector3(offset, -offset, offset),    # Bottom-right-back
		Vector3(-offset, offset, offset),    # Top-left-back
		Vector3(offset, offset, offset)      # Top-right-back
	]

	# Get the parent of the cube (to add new cubes at the same level)
	var parent = cube.get_parent()
	if not parent:
		parent = self

	# Create the 8 new cubes
	for i in range(8):
		var new_cube = CUBE_SCENE.instantiate()

		# Set position and scale
		new_cube.position = cube_position + positions[i]
		new_cube.scale = new_scale

		# Add to the scene
		parent.add_child(new_cube)

		print("CubeSubdivision: Created sub-cube %d at %s with scale %s" % [i + 1, new_cube.global_position, new_scale])

	# Remove the original cube
	print("CubeSubdivision: Removing original cube at %s" % cube_position)
	cube.queue_free()

# Manual control functions
func start_subdivision():
	is_subdividing = true
	subdivision_timer = 0.0
	print("CubeSubdivision: Started manually")

func stop_subdivision():
	is_subdividing = false
	print("CubeSubdivision: Stopped manually")

func reset():
	subdivision_count = 0
	subdivision_timer = 0.0
	is_subdividing = false
	print("CubeSubdivision: Reset")

# Perform a single subdivision step
func step():
	perform_subdivision()
