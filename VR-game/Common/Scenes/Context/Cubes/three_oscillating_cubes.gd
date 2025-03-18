extends Node3D

# ThreeOscillatingCubes.gd
# Creates three cubes that oscillate with different phase offsets

@export var oscillation_height: float = 0.5 # Height of oscillation in meters
@export var oscillation_speed: float = 2.0 # Speed in cycles per second

func _ready():
	# Create three oscillating cubes with different phase offsets
	
	# First cube - starts at bottom of oscillation (sine wave at 270 degrees)
	var cube1 = create_oscillating_cube(
		Vector3(-0.5, 1.0, 0),  # Position
		Color(1.0, 0.3, 0.3),   # Red
		0.75                    # Phase (270 degrees / 360 degrees)
	)
	
	# Second cube - starts at middle of oscillation going up (sine wave at 0 degrees)
	var cube2 = create_oscillating_cube(
		Vector3(0, 1.0, 0),     # Position
		Color(0.3, 1.0, 0.3),   # Green
		0.0                     # Phase (0 degrees / 360 degrees)
	)
	
	# Third cube - starts at top of oscillation (sine wave at 90 degrees)
	var cube3 = create_oscillating_cube(
		Vector3(0.5, 1.0, 0),   # Position
		Color(0.3, 0.3, 1.0),   # Blue
		0.25                    # Phase (90 degrees / 360 degrees)
	)

func create_oscillating_cube(position: Vector3, color: Color, phase_offset: float):
	# Create a Node3D to hold our oscillating cube script
	var oscillator = Node3D.new()
	oscillator.name = "Oscillator_" + str(position.x)
	
	# Attach our oscillating cube script
	var script = load("res://adaresearch/Common/Scenes/Context/Cubes/oscillating_cube.gd")
	oscillator.set_script(script)
	
	# Configure the oscillator
	oscillator.oscillation_height = oscillation_height
	oscillator.oscillation_speed = oscillation_speed
	oscillator.cube_size = 0.2
	oscillator.cube_color = color
	oscillator.phase_offset = phase_offset
	
	# Set the initial position
	oscillator.position = position
	
	# Add to scene
	add_child(oscillator)
	
	return oscillator

# Alternative implementation: Create a scene with three instances without using separate scripts

func create_oscillating_cubes_direct():
	# Create the three cubes directly
	var cubes = []
	var start_positions = []
	var colors = [
		Color(1.0, 0.3, 0.3),  # Red
		Color(0.3, 1.0, 0.3),  # Green
		Color(0.3, 0.3, 1.0)   # Blue
	]
	var phase_offsets = [0.75, 0.0, 0.25]  # Different starting phases
	
	for i in range(3):
		# Create a RigidBody3D for each cube
		var rigid_body = RigidBody3D.new()
		rigid_body.name = "OscillatingCube_" + str(i)
		rigid_body.mass = 1.0
		rigid_body.gravity_scale = 0.0
		rigid_body.freeze = true
		
		# Create visual representation
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "CubeMesh"
		
		# Create cube mesh
		var cube_mesh = BoxMesh.new()
		cube_mesh.size = Vector3(0.2, 0.2, 0.2)
		mesh_instance.mesh = cube_mesh
		
		# Create material
		var material = StandardMaterial3D.new()
		material.albedo_color = colors[i]
		mesh_instance.material_override = material
		
		# Create collision shape
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(0.2, 0.2, 0.2)
		collision_shape.shape = box_shape
		
		# Add XRToolsPickable component if using Godot XR Tools
		var pickable = load("res://addons/godot-xr-tools/objects/pickable.tscn").instantiate()
		
		# Setup the hierarchy
		rigid_body.add_child(mesh_instance)
		rigid_body.add_child(collision_shape)
		rigid_body.add_child(pickable)
		
		# Position the cube with different X positions
		rigid_body.position = Vector3(-0.5 + i * 0.5, 1.0, 0)
		
		# Save the start position
		start_positions.append(rigid_body.position)
		
		# Add to scene
		add_child(rigid_body)
		
		# Add to our array
		cubes.append(rigid_body)
	
	# Create a timer to handle the oscillation
	var timer = Timer.new()
	timer.name = "OscillationTimer"
	timer.wait_time = 0.016  # ~60 fps
	timer.autostart = true
	timer.timeout.connect(func():
		var time = Time.get_ticks_msec() / 1000.0
		
		# Update each cube's position
		for i in range(3):
			if cubes[i]:
				var phase = phase_offsets[i] * 2 * PI
				var y_offset = sin(time * oscillation_speed + phase) * oscillation_height
				cubes[i].position.y = start_positions[i].y + y_offset
	)
	
	# Add the timer to the scene
	add_child(timer)
