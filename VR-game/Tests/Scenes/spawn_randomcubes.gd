extends Node3D

# Reference to the base cube that will be duplicated
@onready var cube_base = $CubeBaseStaticBody3D
@export var min_cubes: int = 1
@export var max_cubes: int = 9
@export var spawn_interval: float = 2.0  # Time between spawns in seconds
@export var z_min: float = -50.0  # Minimum z position
@export var z_max: float = 50.0   # Maximum z position
@export var x_min: float = -10.0  # Minimum x position
@export var x_max: float = 10.0   # Maximum x position
@export var y_position: float = 4.0  # Fixed y position

# Optional movement settings
@export var move_cubes: bool = true
@export var movement_speed: float = 5.0  # Units per second

var spawn_timer: float = 0.0
var spawned_cubes: Array = []

func _ready():
	if cube_base:
		# Hide the original cube as it's just a template
		cube_base.visible = false
	else:
		push_error("Failed to get cube base node from path: " + str(cube_base))


func _process(delta):
	# Update spawn timer
	spawn_timer -= delta
	
	# Spawn new cubes when timer expires
	if spawn_timer <= 0:
		spawn_random_cubes()
		
		# Reset timer with random variation
		spawn_timer = spawn_interval * randf_range(0.8, 1.2)
	
	# Move existing cubes if enabled
	if move_cubes:
		move_spawned_cubes(delta)
	
	# Clean up cubes that have moved too far
	clean_up_cubes()

func spawn_random_cubes():
	# Only proceed if we have a valid cube base
	if not cube_base:
		return
		
	# Determine how many cubes to spawn this time
	var count = randi_range(min_cubes, max_cubes)
	
	for i in range(count):
		# Create a duplicate of the base cube
		var new_cube = cube_base.duplicate()
		add_child(new_cube)
		
		# Make the duplicate visible
		new_cube.visible = true
		
		# Position the cube randomly along the X and Z axes at fixed Y
		new_cube.position = Vector3(
			randf_range(x_min, x_max),
			y_position,
			randf_range(z_min, z_max)
		)
		
		# Add some random rotation
		new_cube.rotation_degrees = Vector3(
			randf_range(0, 360),
			randf_range(0, 360),
			randf_range(0, 360)
		)
		
		# Add the cube to our tracking array
		spawned_cubes.append(new_cube)

func move_spawned_cubes(delta):
	for cube in spawned_cubes:
		if is_instance_valid(cube):
			# Move cubes along the Z axis
			cube.position.z -= movement_speed * delta

func clean_up_cubes():
	# Remove cubes that have moved too far
	var cubes_to_remove = []
	
	for i in range(spawned_cubes.size() - 1, -1, -1):
		var cube = spawned_cubes[i]
		
		# Check if cube is valid and has moved beyond our bounds
		if not is_instance_valid(cube) or cube.position.z > z_max + 20.0:
			if is_instance_valid(cube):
				cube.queue_free()
			spawned_cubes.remove_at(i)
