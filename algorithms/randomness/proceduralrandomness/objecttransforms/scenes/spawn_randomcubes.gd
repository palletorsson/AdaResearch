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

# Breaking cube settings
@export var fragment_count: int = 8  # Number of fragments when a cube breaks
@export var fragment_lifetime: float = 3.0  # How long fragments exist before disappearing
@export var fragment_scene_path: String = "res://fragments/cube_fragment.tscn"  # Path to fragment scene
@export var explosion_force: float = 10.0  # Force applied to fragments
@export var gravity_scale: float = 1.0  # How strongly gravity affects fragments
# @export var fragment_scene_path: String = "res://adaresearch/Common/Scenes/Player/Weapons/TorusBlaster/cubefragment.tscn"  # Path to fragment scene - COMMENTED OUT: Scene not found

var spawn_timer: float = 0.0
var spawned_cubes: Array = []
var fragment_scene: PackedScene

func _ready():
	if cube_base:
		# Hide the original cube as it's just a template
		cube_base.visible = false
	else:
		push_error("Failed to get cube base node from path: " + str(cube_base))
	
	# Load the fragment scene
	if ResourceLoader.exists(fragment_scene_path):
		fragment_scene = load(fragment_scene_path)
	else:
		push_error("Fragment scene not found at path: " + fragment_scene_path)
		# Create a fallback simple fragment scene if needed
		create_fallback_fragment_scene()

func create_fallback_fragment_scene():
	# Create a simple fragment scene programmatically as fallback
	var fragment = RigidBody3D.new()
	var mesh_instance = MeshInstance3D.new()
	var collision_shape = CollisionShape3D.new()
	
	mesh_instance.mesh = BoxMesh.new()
	mesh_instance.mesh.size = Vector3(0.5, 0.5, 0.5)
	
	collision_shape.shape = BoxShape3D.new()
	collision_shape.shape.size = Vector3(0.5, 0.5, 0.5)
	
	fragment.add_child(mesh_instance)
	fragment.add_child(collision_shape)
	


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
		
		# Make sure Area3D is set up properly for collision detection
		setup_cube_area(new_cube)
		
		# Add the cube to our tracking array
		spawned_cubes.append(new_cube)

func setup_cube_area(cube):
	# Get the Area3D node
	var area = cube.get_node_or_null("Area3D")
	
	# If the Area3D doesn't exist, create it
	if not area:
		area = Area3D.new()
		area.name = "Area3D"
		cube.add_child(area)
		
		# Create a collision shape for the area
		var col_shape = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(1, 1, 1)  # Match cube size
		col_shape.shape = shape
		area.add_child(col_shape)
	
	# Set collision layer and mask
	area.collision_layer = 2  # Layer 2
	area.collision_mask = 4   # Layer 3 (toruses)
	
	# Connect the body_entered signal
	if not area.body_entered.is_connected(_on_cube_hit):
		# We use a custom lambda to pass the cube as an argument
		area.body_entered.connect(
			func(body): _on_cube_hit(body, cube)
		)

func _on_cube_hit(body, cube):
	print("Cube hit by: ", body.name)
	
	# Check if the body is a torus
	if body and ("torus" in body.name.to_lower() or "cube" in body.name.to_lower()):
		# Get collision information
		var hit_pos = body.global_position
		var hit_normal = (cube.global_position - hit_pos).normalized()
		
		# Break the cube
		break_cube(cube, hit_pos, hit_normal)

func break_cube(cube, hit_position, hit_normal):
	"""
	Break a cube into multiple fragments
	"""
	if not is_instance_valid(cube):
		return
	
	if not fragment_scene:
		push_error("Fragment scene not loaded")
		return
	
	var cube_position = cube.global_position
	var cube_scale = cube.scale
	var cube_rotation = cube.global_rotation
	
	# Create multiple fragments
	for i in range(fragment_count):
		var fragment = fragment_scene.instantiate()
		add_child(fragment)  # Add to this node instead of root
		
		# Position fragments inside the original cube with offset
		var offset = Vector3(
			randf_range(-0.4, 0.4),
			randf_range(-0.4, 0.4),
			randf_range(-0.4, 0.4)
		)
		fragment.global_position = cube_position + offset
		
		# Scale the fragment
		var size_variation = randf_range(0.2, 0.5)
		fragment.scale = cube_scale * size_variation
		
		# Set fragment material/color to match the original cube
		copy_material_to_fragment(cube, fragment)
		
		# Apply force in random direction, biased away from hit point
		var explosion_dir = (fragment.global_position - hit_position).normalized()
		explosion_dir += Vector3(randf_range(-0.5, 0.5), randf_range(0, 1), randf_range(-0.5, 0.5))
		explosion_dir = explosion_dir.normalized()
		
		# Make sure the fragment has the proper collision layers
		fragment.collision_layer = 8  # Layer 4
		fragment.collision_mask = 1   # Layer 1 (world)
		
		# Apply physics
		fragment.linear_velocity = explosion_dir * explosion_force * randf_range(0.8, 1.2)
		fragment.angular_velocity = Vector3(
			randf_range(-5, 5),
			randf_range(-5, 5),
			randf_range(-5, 5)
		)
		
		# Set custom lifetime if the fragment has that method
		if fragment.has_method("set_custom_lifetime"):
			fragment.set_custom_lifetime(fragment_lifetime * randf_range(0.8, 1.2))
	
	# Play break sound if available
	if has_node("BreakSound"):
		var sound = get_node("BreakSound")
		sound.global_position = cube_position
		sound.play()
	
	# Remove the original cube
	if cube in spawned_cubes:
		spawned_cubes.erase(cube)
	cube.queue_free()

func copy_material_to_fragment(source_cube, fragment):
	"""
	Copy the material from the source cube to the fragment
	"""
	# Find the MeshInstance3D in both objects
	var source_mesh = find_mesh_instance(source_cube)
	var target_mesh = find_mesh_instance(fragment)
	
	if source_mesh and target_mesh:
		# Get the material from the source
		var material = null
		if source_mesh.get_surface_override_material(0):
			material = source_mesh.get_surface_override_material(0)
		elif source_mesh.mesh and source_mesh.mesh.get_surface_count() > 0:
			material = source_mesh.mesh.surface_get_material(0)
		
		# Apply the material to the target - use duplicate to avoid sharing materials
		if material:
			target_mesh.set_surface_override_material(0, material.duplicate())

func find_mesh_instance(node):
	"""
	Recursively find a MeshInstance3D in the node or its children
	"""
	if node is MeshInstance3D:
		return node
	
	for child in node.get_children():
		var result = find_mesh_instance(child)
		if result:
			return result
	
	return null

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
