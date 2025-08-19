extends Node3D

@onready var base_cube = $CubeBaseStaticBody3D

# Configuration parameters for the wall
@export var wall_width: int = 20
@export var wall_height: int = 8
@export var wall_depth: int = 1
@export var random_seed: int = 42
@export var cube_size: float = 1.0
@export var min_scale: float = 0.7
@export var max_scale: float = 1.3
@export var randomness_scale_factor: float = 1.0
@export_enum("Left to Right", "Right to Left", "Bottom to Top", "Top to Bottom") var randomness_direction: int = 0

# Called when the node enters the scene tree
func _ready():
	# Hide the original cube - we'll use it as a template
	base_cube.visible = false
	
	# Set random seed for reproducible results
	seed(random_seed)
	
	# Generate the wall with increasing randomness
	generate_increasingly_random_wall()

func generate_increasingly_random_wall():
	for x in range(wall_width):
		for y in range(wall_height):
			for z in range(wall_depth):
				# Calculate randomness factor based on direction
				var base_factor: float
				match randomness_direction:
					0: # Left to Right
						base_factor = float(x) / (wall_width - 1)
					1: # Right to Left
						base_factor = float(wall_width - 1 - x) / (wall_width - 1)
					2: # Bottom to Top
						base_factor = float(y) / (wall_height - 1)
					3: # Top to Bottom
						base_factor = float(wall_height - 1 - y) / (wall_height - 1)
				
				# Apply cubic easing for more dramatic effect
				var randomness_factor = pow(base_factor, 3) * randomness_scale_factor
				
				# Create a new instance of the base cube
				var new_cube = base_cube.duplicate()
				add_child(new_cube)
				
				# Make it visible
				new_cube.visible = true
				
				# Base position (perfectly aligned grid)
				var base_pos = Vector3(x * cube_size, y * cube_size, z * cube_size)
				
				# Position jitter increases with randomness_factor
				var max_jitter = cube_size * 0.5 * randomness_factor
				var jitter = Vector3(
					randf_range(-max_jitter, max_jitter),
					randf_range(-max_jitter, max_jitter),
					randf_range(-max_jitter, max_jitter)
				)
				
				# Apply jittered position
				new_cube.position = base_pos + jitter
				
				# Apply rotation with increasing randomness
				var max_rotation = PI * 2 * randomness_factor
				new_cube.rotation = Vector3(
					randf_range(-max_rotation, max_rotation),
					randf_range(-max_rotation, max_rotation),
					randf_range(-max_rotation, max_rotation)
				)
				
				# Apply scaling with increasing randomness
				var scale_variation = lerp(0.0, max_scale - min_scale, randomness_factor)
				var scale_factor = min_scale + randf_range(0, scale_variation)
				new_cube.scale = Vector3(scale_factor, scale_factor, scale_factor)
				
				# Randomly remove cubes with increasing probability
				var removal_chance = randomness_factor * 0.3  # Up to 30% of cubes can be removed
				if randf() < removal_chance:
					new_cube.queue_free()
					continue
				
				# Apply color variation with increasing randomness
				if new_cube.get_child_count() > 0 and new_cube.get_child(0) is MeshInstance3D:
					var mesh_instance = new_cube.get_child(0)
					
					# Create a new material for each cube (don't modify the original)
					var material = mesh_instance.get_active_material(0).duplicate()
					mesh_instance.set_surface_override_material(0, material)
					
					# Apply increasing color randomness
					var base_color = Color(0.8, 0.8, 0.8)  # Light gray as base
					var random_color = Color(randf(), randf(), randf())
					var final_color = base_color.lerp(random_color, randomness_factor)
					
					# Apply the color to the material
					if material is StandardMaterial3D:
						material.albedo_color = final_color

# Regenerate the wall with a new random seed
func regenerate():
	# Remove all previous cubes except the base one
	for child in get_children():
		if child != base_cube:
			child.queue_free()
	
	# Generate a new wall with a new seed
	random_seed = randi()
	seed(random_seed)
	generate_increasingly_random_wall()
