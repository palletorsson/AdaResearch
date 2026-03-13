extends Node3D

# Cube Subdivision Fractal - Single Path Recursive
# Starts with one cube, subdivides it into 8, picks ONE of those 8 to subdivide next,
# creating a fractal zoom path through scale. Like diving into one corner repeatedly.

# Reference to the cube scene to instantiate
const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

# Subdivision settings
@export var subdivision_interval: float = 0.8  # Time between subdivisions in seconds
@export var max_subdivisions: int = 10  # Maximum number of subdivision iterations
@export var auto_start: bool = true  # Start subdividing automatically
@export var random_corner: bool = true  # Pick a random cube each iteration
@export var fixed_corner_index: int = 7  # Which corner if not random (0-7)
# Corner indices: 0=front-bottom-left, 1=front-bottom-right, 2=front-top-left, 3=front-top-right
#                 4=back-bottom-left,  5=back-bottom-right,  6=back-top-left,  7=back-top-right

# Internal state
var subdivision_count: int = 0
var subdivision_timer: float = 0.0
var is_subdividing: bool = false
var current_target_cube: Node3D = null  # The cube we'll subdivide next
var all_cubes: Array[Node3D] = []  # Track all cubes for visualization
var cube_depths: Dictionary = {}  # Track each cube's generation depth

# Color palette for iteration levels (10 colors for 10 iterations)
var iteration_colors: Array[Color] = [
	Color(0.9, 0.2, 0.3, 1.0),   # Iteration 0 - Red (initial)
	Color(0.95, 0.5, 0.1, 1.0),  # Iteration 1 - Orange
	Color(0.95, 0.85, 0.2, 1.0), # Iteration 2 - Yellow
	Color(0.3, 0.85, 0.4, 1.0),  # Iteration 3 - Green
	Color(0.2, 0.5, 0.95, 1.0),  # Iteration 4 - Blue
	Color(0.7, 0.3, 0.9, 1.0),   # Iteration 5 - Purple
	Color(0.1, 0.8, 0.8, 1.0),   # Iteration 6 - Cyan
	Color(0.95, 0.4, 0.6, 1.0),  # Iteration 7 - Pink
	Color(0.6, 0.8, 0.2, 1.0),   # Iteration 8 - Lime
	Color(0.4, 0.3, 0.8, 1.0),   # Iteration 9 - Indigo
]


func _ready() -> void:
	print("CubeSubdivision: Ready - Single path recursive mode")

	# Find and color the initial cube
	var initial_cube = _find_initial_cube()
	if initial_cube:
		current_target_cube = initial_cube
		_apply_color_to_cube(initial_cube, iteration_colors[0])
		all_cubes.append(initial_cube)
		cube_depths[initial_cube] = 0  # Initial cube is depth 0
		print("CubeSubdivision: Found initial cube, colored red (depth 0)")
	else:
		push_error("CubeSubdivision: No initial cube found!")
		return

	# Start automatic subdivision if enabled
	if auto_start:
		is_subdividing = true
		print("CubeSubdivision: Auto-subdivision enabled, will run %d iterations" % max_subdivisions)


func _process(delta: float) -> void:
	if not is_subdividing:
		return

	# Update timer
	subdivision_timer += delta

	# Check if it's time to subdivide
	if subdivision_timer >= subdivision_interval:
		subdivision_timer = 0.0
		perform_single_subdivision()


func _find_initial_cube() -> Node3D:
	# Look for the InitialCube node or any cube_scene instance
	for child in get_children():
		if child.name == "InitialCube" or child.name == "CubeScene":
			return child
		if child is Node3D and child.has_node("CubeBaseStaticBody3D"):
			return child
	return null


func perform_single_subdivision() -> void:
	# Check if we've reached the maximum
	if subdivision_count >= max_subdivisions:
		print("CubeSubdivision: Reached maximum subdivisions (%d)" % max_subdivisions)
		is_subdividing = false
		return

	# Pick a random cube from ALL existing cubes
	if all_cubes.is_empty():
		print("CubeSubdivision: No cubes available")
		is_subdividing = false
		return

	# Clean up invalid cubes first
	all_cubes = all_cubes.filter(func(c): return is_instance_valid(c))

	if all_cubes.is_empty():
		print("CubeSubdivision: No valid cubes")
		is_subdividing = false
		return

	# Pick random cube from the entire set
	var target_index = randi() % all_cubes.size()
	current_target_cube = all_cubes[target_index]
	var picked_depth = cube_depths.get(current_target_cube, -1)

	subdivision_count += 1
	print("CubeSubdivision: Iteration %d - picked cube %d of %d (depth %d)" % [subdivision_count, target_index, all_cubes.size(), picked_depth])

	# Subdivide the chosen cube
	var new_cubes = subdivide_cube_return_children(current_target_cube)

	if new_cubes.is_empty():
		print("CubeSubdivision: Failed to create sub-cubes")
		is_subdividing = false
		return

	# Count cubes by depth for debug
	var depth_counts = {}
	for cube in all_cubes:
		var d = cube_depths.get(cube, -1)
		depth_counts[d] = depth_counts.get(d, 0) + 1
	print("CubeSubdivision: Iteration %d complete, now have %d cubes. Depths: %s" % [subdivision_count, all_cubes.size(), depth_counts])


func subdivide_cube_return_children(cube: Node3D) -> Array[Node3D]:
	"""Subdivide a cube into 8 smaller cubes, return the array of new cubes"""
	var new_cubes: Array[Node3D] = []

	if not is_instance_valid(cube):
		return new_cubes

	# Use LOCAL position (relative to this node) for consistent behavior
	# whether running standalone or inside a map
	var cube_position = cube.position
	var cube_scale = cube.scale

	# Calculate the new scale (half size, then shrink by 0.9 for visibility gaps)
	var new_scale = cube_scale * 0.5 * 0.9

	# Calculate offset for positioning the 8 new cubes
	var offset = cube_scale.x * 0.25

	# Create 8 new cubes in a 2x2x2 grid pattern
	var positions = [
		Vector3(-offset, -offset, -offset),  # 0: Bottom-left-front
		Vector3(offset, -offset, -offset),   # 1: Bottom-right-front
		Vector3(-offset, offset, -offset),   # 2: Top-left-front
		Vector3(offset, offset, -offset),    # 3: Top-right-front
		Vector3(-offset, -offset, offset),   # 4: Bottom-left-back
		Vector3(offset, -offset, offset),    # 5: Bottom-right-back
		Vector3(-offset, offset, offset),    # 6: Top-left-back
		Vector3(offset, offset, offset)      # 7: Top-right-back
	]

	# Get parent cube's depth and calculate child depth
	var parent_depth = cube_depths.get(cube, 0)
	var child_depth = parent_depth + 1

	# Get color based on child's depth (generation)
	var color_index = child_depth % iteration_colors.size()
	var color = iteration_colors[color_index]

	# Create the 8 new cubes
	for i in range(8):
		var new_cube = CUBE_SCENE.instantiate()

		# Set LOCAL position (relative to parent node)
		new_cube.position = cube_position + positions[i]
		new_cube.scale = new_scale

		# Apply color based on depth
		_apply_color_to_cube(new_cube, color)

		# Add to the scene
		add_child(new_cube)
		all_cubes.append(new_cube)
		new_cubes.append(new_cube)
		cube_depths[new_cube] = child_depth  # Track this cube's depth

	# Remove the original cube from tracking and scene
	all_cubes.erase(cube)
	cube_depths.erase(cube)
	cube.queue_free()

	return new_cubes


func _apply_color_to_cube(cube: Node3D, color: Color) -> void:
	# Find the mesh instance inside the cube
	var mesh_instance: MeshInstance3D = null
	if cube.has_node("CubeBaseStaticBody3D/CubeBaseMesh"):
		mesh_instance = cube.get_node("CubeBaseStaticBody3D/CubeBaseMesh")

	if mesh_instance:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color * 0.4
		material.emission_energy_multiplier = 0.6
		mesh_instance.material_override = material


func _highlight_target_cube(cube: Node3D) -> void:
	# Make the target cube glow brighter to show it's next
	var mesh_instance: MeshInstance3D = null
	if cube.has_node("CubeBaseStaticBody3D/CubeBaseMesh"):
		mesh_instance = cube.get_node("CubeBaseStaticBody3D/CubeBaseMesh")

	if mesh_instance and mesh_instance.material_override:
		var mat = mesh_instance.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 1.5


# Manual control functions
func start_subdivision() -> void:
	is_subdividing = true
	subdivision_timer = 0.0
	print("CubeSubdivision: Started manually")


func stop_subdivision() -> void:
	is_subdividing = false
	print("CubeSubdivision: Stopped manually")


func reset() -> void:
	# Remove all cubes except initial
	for cube in all_cubes:
		if is_instance_valid(cube):
			cube.queue_free()
	all_cubes.clear()
	cube_depths.clear()

	subdivision_count = 0
	subdivision_timer = 0.0
	is_subdividing = false
	current_target_cube = null
	print("CubeSubdivision: Reset")


func step() -> void:
	"""Perform a single subdivision step"""
	perform_single_subdivision()


func set_corner(index: int) -> void:
	"""Change which corner gets subdivided (0-7), disables random"""
	random_corner = false
	fixed_corner_index = clamp(index, 0, 7)
	print("CubeSubdivision: Now subdividing corner %d (random disabled)" % fixed_corner_index)


func set_random(enabled: bool) -> void:
	"""Enable or disable random corner selection"""
	random_corner = enabled
	print("CubeSubdivision: Random corner selection %s" % ("enabled" if enabled else "disabled"))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

