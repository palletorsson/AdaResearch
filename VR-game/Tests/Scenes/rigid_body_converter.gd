extends Node3D

# Percentage of cubes to convert to rigidbodies (0.0 - 1.0)
@export_range(0.0, 1.0) var conversion_percentage: float = 0.1

# Physics properties for the rigidbodies
@export var min_mass: float = 0.5
@export var max_mass: float = 3.0
@export var min_bounce: float = 0.2
@export var max_bounce: float = 0.8
@export var apply_random_impulse: bool = true
@export var impulse_strength: float = 0.5
@export var delay_between_conversions: float = 0.2  # Seconds between each conversion
@export var stabilize_time: float = 1.0  # Seconds to wait before applying impulses

# Timer for staggered conversion
var conversion_timer: float = 0.0
var cubes_to_convert = []
var conversion_index = 0

func _ready():
	# Perform the initial search for all static cubes
	var static_cubes = find_all_static_cubes()
	
	# Randomly select a subset to convert
	var num_to_convert = int(static_cubes.size() * conversion_percentage)
	
	# Shuffle the array and take the first N elements
	static_cubes.shuffle()
	cubes_to_convert = static_cubes.slice(0, num_to_convert)
	
	print("Found ", static_cubes.size(), " static cubes. Will convert ", 
		cubes_to_convert.size(), " to rigidbodies.")

func _process(delta):
	# If we still have cubes to convert, process them with a delay
	if conversion_index < cubes_to_convert.size():
		conversion_timer += delta
		
		if conversion_timer >= delay_between_conversions:
			conversion_timer = 0.0
			convert_to_rigidbody(cubes_to_convert[conversion_index])
			conversion_index += 1

func find_all_static_cubes():
	var static_cubes = []
	
	# Recursively search the scene for nodes named "CubeBaseStaticBody3D"
	var search_stack = [self]
	
	while search_stack.size() > 0:
		var current = search_stack.pop_back()
		
		# Check if this is a StaticBody3D with the target name
		if current is StaticBody3D and current.name.contains("CubeBaseStaticBody3D"):
			static_cubes.append(current)
		
		# Add all children to the search stack
		for child in current.get_children():
			search_stack.append(child)
	
	return static_cubes

func convert_to_rigidbody(static_body):
	# Create a new RigidBody3D
	var rigid_body = RigidBody3D.new()
	
	# Set properties
	rigid_body.name = static_body.name.replace("Static", "Rigid")
	rigid_body.global_transform = static_body.global_transform
	
	# Set random physics properties
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	rigid_body.mass = rng.randf_range(min_mass, max_mass)
	rigid_body.bounce = rng.randf_range(min_bounce, max_bounce)
	rigid_body.friction = rng.randf_range(0.3, 0.9)
	rigid_body.continuous_cd = true  # Enable continuous collision detection
	rigid_body.contact_monitor = true
	rigid_body.max_contacts_reported = 4
	rigid_body.linear_damp = rng.randf_range(0.1, 0.5)
	rigid_body.angular_damp = rng.randf_range(0.1, 0.5)
	
	# Copy all child nodes (meshes, collision shapes, etc.)
	while static_body.get_child_count() > 0:
		var child = static_body.get_child(0)
		static_body.remove_child(child)
		rigid_body.add_child(child)
		
	# Replace the static body with the rigid body
	var parent = static_body.get_parent()
	var pos_in_parent = static_body.get_index()
	
	parent.remove_child(static_body)
	parent.add_child(rigid_body)
	parent.move_child(rigid_body, pos_in_parent)
	
	# Apply random impulse if enabled
	if apply_random_impulse:
		# Create a timer to wait 1 second before applying impulse
		var impulse_timer = Timer.new()
		add_child(impulse_timer)
		impulse_timer.one_shot = true
		impulse_timer.wait_time = 1.0
		
		# Connect the timer to a callback function
		impulse_timer.timeout.connect(func():
			var impulse = Vector3(
				rng.randf_range(-1.0, 1.0),
				rng.randf_range(0.5, 2.0),  # Mostly upward
				rng.randf_range(-1.0, 1.0)
			).normalized() * impulse_strength * rigid_body.mass
			
			var position = Vector3(
				rng.randf_range(-0.5, 0.5),
				rng.randf_range(-0.5, 0.5),
				rng.randf_range(-0.5, 0.5)
			)
			
			# Apply the impulse if the rigid body still exists
			if is_instance_valid(rigid_body):
				rigid_body.apply_impulse(impulse, position)
				
			# Clean up the timer
			impulse_timer.queue_free()
		)
		
		# Start the timer
		impulse_timer.start()
	
	# Clean up the old static body
	static_body.queue_free()
	
	print("Converted ", rigid_body.name, " to rigidbody")
