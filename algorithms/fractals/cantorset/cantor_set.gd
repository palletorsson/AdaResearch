extends Node3D

# Cantor Set Fractal with Physics
# Creates a vertical Cantor set where each iteration divides bars into thirds,
# removes the middle third, and stacks them using RigidBody3D physics
# Bars fall and stack on top of each other

# Cantor set settings
@export var iteration_interval: float = 2.0  # Time between iterations in seconds
@export var max_iterations: int = 5  # Maximum number of iterations
@export var auto_start: bool = true  # Start generating automatically
@export var initial_bar_length: float = 9.0  # Length of the initial bar
@export var bar_thickness: float = 0.3  # Thickness (height and depth) of bars
@export var vertical_spacing: float = 1.5  # Vertical space between iteration levels

# Internal state
var current_iteration: int = 0
var iteration_timer: float = 0.0
var is_generating: bool = false
var current_bars: Array = []  # Track bars from current iteration

func _ready():
	print("CantorSet: Ready")
	print("CantorSet: Will create %d iterations" % max_iterations)

	# Create the initial bar
	create_initial_bar()

	# Start automatic generation if enabled
	if auto_start:
		is_generating = true
		print("CantorSet: Auto-generation enabled")

func _process(delta: float):
	if not is_generating:
		return

	# Update timer
	iteration_timer += delta

	# Check if it's time for next iteration
	if iteration_timer >= iteration_interval:
		iteration_timer = 0.0
		perform_iteration()

# Create the initial bar at the top
func create_initial_bar():
	var bar = create_bar(Vector3(0, vertical_spacing * max_iterations, 0), initial_bar_length)
	current_bars = [bar]
	print("CantorSet: Created initial bar with length %.2f" % initial_bar_length)

# Create a single bar as a RigidBody3D
func create_bar(position: Vector3, length: float) -> RigidBody3D:
	# Create RigidBody3D
	var rigid_body = RigidBody3D.new()
	rigid_body.position = position

	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(length, bar_thickness, bar_thickness)
	collision_shape.shape = box_shape

	# Create mesh for visualization
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(length, bar_thickness, bar_thickness)
	mesh_instance.mesh = box_mesh

	# Create material with color based on iteration
	var material = StandardMaterial3D.new()
	var hue = current_iteration / float(max_iterations)
	material.albedo_color = Color.from_hsv(hue, 0.8, 0.9)
	material.metallic = 0.3
	material.roughness = 0.7
	mesh_instance.material_override = material

	# Assemble the bar
	rigid_body.add_child(collision_shape)
	rigid_body.add_child(mesh_instance)
	add_child(rigid_body)

	return rigid_body

# Perform one Cantor set iteration
func perform_iteration():
	# Check if we've reached the maximum
	if current_iteration >= max_iterations:
		print("CantorSet: Reached maximum iterations (%d)" % max_iterations)
		is_generating = false
		return

	current_iteration += 1
	print("CantorSet: Starting iteration %d" % current_iteration)

	var new_bars = []

	# For each bar in the current iteration, create two bars (left and right thirds)
	for bar in current_bars:
		if not is_instance_valid(bar):
			continue

		var bar_position = bar.position
		var bar_length = get_bar_length(bar)

		# Calculate new length (1/3 of original)
		var new_length = bar_length / 3.0

		# Calculate y position for new iteration (stacked below)
		var new_y = vertical_spacing * (max_iterations - current_iteration)

		# Calculate x offsets for left and right thirds
		var offset = bar_length / 3.0

		# Create left third bar
		var left_bar = create_bar(
			Vector3(bar_position.x - offset, new_y, bar_position.z),
			new_length
		)
		new_bars.append(left_bar)

		# Create right third bar
		var right_bar = create_bar(
			Vector3(bar_position.x + offset, new_y, bar_position.z),
			new_length
		)
		new_bars.append(right_bar)

	print("CantorSet: Created %d bars for iteration %d" % [new_bars.size(), current_iteration])

	# Update current bars for next iteration
	current_bars = new_bars

# Get the length of a bar by examining its collision shape
func get_bar_length(bar: RigidBody3D) -> float:
	for child in bar.get_children():
		if child is CollisionShape3D:
			var shape = child.shape
			if shape is BoxShape3D:
				return shape.size.x
	return 0.0

# Manual control functions
func start_generation():
	is_generating = true
	iteration_timer = 0.0
	print("CantorSet: Started manually")

func stop_generation():
	is_generating = false
	print("CantorSet: Stopped manually")

func reset():
	# Clear all bars
	for child in get_children():
		if child is RigidBody3D:
			child.queue_free()

	current_iteration = 0
	iteration_timer = 0.0
	is_generating = false
	current_bars.clear()

	# Recreate initial bar
	create_initial_bar()

	print("CantorSet: Reset")

# Perform a single iteration step
func step():
	perform_iteration()
