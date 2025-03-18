extends Node3D

@onready var base_cube = $CubeBaseStaticBody3D

# Configuration parameters for the wall
@export var wall_width: int = 10
@export var wall_height: int = 6
@export var wall_depth: int = 2
@export var random_seed: int = 42
@export var cube_size: float = 1.0
@export var fill_percentage: float = 0.75  # 0.0 to 1.0
@export var random_rotation: bool = true
@export var random_scale: bool = true
@export var min_scale: float = 0.7
@export var max_scale: float = 1.3
@export var position_jitter: float = 0.1  # Adds some random offset to cube positions

# Called when the node enters the scene tree
func _ready():
	# Hide the original cube - we'll use it as a template
	base_cube.visible = false
	
	# Set random seed for reproducible results
	seed(random_seed)
	
	# Generate the cube wall
	generate_wall()

func generate_wall():
	for x in range(wall_width):
		for y in range(wall_height):
			for z in range(wall_depth):
				# Only place a cube based on fill_percentage
				if randf() <= fill_percentage:
					# Create a new instance of the base cube
					var new_cube = base_cube.duplicate()
					add_child(new_cube)
					
					# Make it visible
					new_cube.visible = true
					
					# Set position with a small random offset for more natural look
					var jitter_x = randf_range(-position_jitter, position_jitter)
					var jitter_y = randf_range(-position_jitter, position_jitter)
					var jitter_z = randf_range(-position_jitter, position_jitter)
					new_cube.position = Vector3(
						x * cube_size + jitter_x, 
						y * cube_size + jitter_y, 
						z * cube_size + jitter_z
					)
					
					# Apply random rotation if enabled
					if random_rotation:
						new_cube.rotation = Vector3(
							randf_range(0, PI * 2),
							randf_range(0, PI * 2),
							randf_range(0, PI * 2)
						)
					
					# Apply random scale if enabled
					if random_scale:
						var scale_factor = randf_range(min_scale, max_scale)
						new_cube.scale = Vector3(scale_factor, scale_factor, scale_factor)

# Optional - add a button in the editor to regenerate the wall
func regenerate():
	# Remove all previous cubes except the base one
	for child in get_children():
		if child != base_cube and child.is_in_group("cube_wall"):
			child.queue_free()
	
	# Generate a new wall
	random_seed = randi()  # New random seed
	generate_wall()
